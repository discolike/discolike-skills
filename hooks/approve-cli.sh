#!/bin/sh
# Auto-approve plain `discolike` CLI calls so the agent stops prompting on every
# invocation. Shared by Claude Code, Cursor, and Codex; the first argument picks
# the verdict shape:
#
#   claude -> PreToolUse           (input .tool_name, .tool_input.command)
#   codex  -> PermissionRequest    (input .tool_name, .tool_input.command)
#   cursor -> beforeShellExecution (input .command)
#
# "allow" only skips the prompt. Deny rules and managed policies still win, so
# this can never punch through an admin block. Anything the script does not
# recognise falls through to the normal prompt (exit 0, no output).
#
# Policy, conservative by design:
#   * The whole command is refused if it contains `&`, `<`, `>`, a backtick,
#     `$`, or a backslash (after stripping `2>&1` and `>/dev/null`), is
#     multi-line, or is longer than 4000 characters. No redirection, command
#     substitution, environment expansion, or backgrounding ever auto-approves.
#   * Unquoted `;` splits clauses; unquoted `|` splits pipeline segments.
#     Quoted `;` and `|` are data.
#   * At least one segment must be the DiscoLike CLI: bare `discolike`, or
#     `uvx --from discolike-cli[==<version>] discolike`.
#   * A `discolike` segment never auto-approves when its first subcommand is in
#     GATED (credential and provider-key management), when any word starts
#     with `/` or `~` or contains `..` (no writes or reads outside the working
#     tree), or when a word has an unquoted glob, brace, or paren character.
#   * Other segments in a pipeline that contains `discolike` must be one of
#     the read-only HELPERS, must not reference a path, and must not carry an
#     output or input file flag. `echo` and `printf` are exempt from the path
#     rule (a `/` in their argument is data).
#   * A `;` clause with no `discolike` may only be `echo` or `printf`.
#   * A leading `NAME=value` on any segment is refused.

agent="${1:-claude}"

HELPERS="jq cat head tail wc grep sort uniq column tr cut echo printf"
GATED="auth signup llm-providers search-providers"
MAX_LEN=4000

set -fu

command -v jq > /dev/null 2>&1 || exit 0
command -v awk > /dev/null 2>&1 || exit 0

input="$(cat)"

case "$agent" in
  cursor)
    cmd="$(printf '%s' "$input" | jq -r '.command // empty' 2> /dev/null)"
    ;;
  *)
    cmd="$(printf '%s' "$input" | jq -r 'if .tool_name == "Bash" then .tool_input.command // empty else empty end' 2> /dev/null)"
    ;;
esac

[ -n "$cmd" ] || exit 0

# Strip the two harmless redirect shapes agents add reflexively. Everything else
# that redirects stays in the string and is refused below.
stripped="$(printf '%s' "$cmd" | sed -E '
  s#[0-9]?>>?[[:space:]]*/dev/null([[:space:]]|$)#\1#g
  s#[0-9]>&[0-9]##g
')"

case "$stripped" in
  *'&'* | *'<'* | *'>'* | *'`'* | *'$'* | *'\'*) exit 0 ;;
esac

[ "$(printf '%s' "$stripped" | wc -l | tr -d ' ')" = "0" ] || exit 0
[ "${#stripped}" -le "$MAX_LEN" ] || exit 0

verdict="$(printf '%s' "$stripped" | awk -v helpers="$HELPERS" -v gated="$GATED" '
  BEGIN {
    n = split(helpers, a, " "); for (i = 1; i <= n; i++) HELPER[a[i]] = 1
    n = split(gated, a, " ");   for (i = 1; i <= n; i++) GATE[a[i]] = 1
    SQ = sprintf("%c", 39); DQ = "\""
  }

  # Split s on an unquoted delimiter character. Fills out[1..k], returns k.
  function split_unquoted(s, delim, out,    i, c, q, cur, k) {
    q = ""; cur = ""; k = 0
    for (i = 1; i <= length(s); i++) {
      c = substr(s, i, 1)
      if (q != "") { cur = cur c; if (c == q) q = ""; continue }
      if (c == SQ || c == DQ) { q = c; cur = cur c; continue }
      if (c == delim) { out[++k] = cur; cur = ""; continue }
      cur = cur c
    }
    out[++k] = cur
    return k
  }

  # Tokenise a segment on unquoted whitespace, stripping the quotes. Fills
  # tok[1..k] with dequoted words and raw[1..k] with the original spelling.
  function tokenize(s, tok, raw,    i, c, q, cur, cur_raw, k, inword) {
    q = ""; cur = ""; cur_raw = ""; k = 0; inword = 0
    for (i = 1; i <= length(s); i++) {
      c = substr(s, i, 1)
      if (q != "") { cur_raw = cur_raw c; if (c == q) q = ""; else cur = cur c; continue }
      if (c == SQ || c == DQ) { q = c; cur_raw = cur_raw c; inword = 1; continue }
      if (c == " " || c == "\t") {
        if (inword) { tok[++k] = cur; raw[k] = cur_raw; cur = ""; cur_raw = ""; inword = 0 }
        continue
      }
      cur = cur c; cur_raw = cur_raw c; inword = 1
    }
    if (inword) { tok[++k] = cur; raw[k] = cur_raw }
    return k
  }

  # True when the raw spelling of a word carries a shell metacharacter outside
  # quotes: glob, brace, tilde, parens, or a leading `=`.
  function unquoted_meta(r,    i, c, q) {
    q = ""
    for (i = 1; i <= length(r); i++) {
      c = substr(r, i, 1)
      if (q != "") { if (c == q) q = ""; continue }
      if (c == SQ || c == DQ) { q = c; continue }
      if (c == "*" || c == "?" || c == "[" || c == "]" || c == "{" || c == "}" || c == "(" || c == ")" || c == "~") return 1
      if (c == "=" && i == 1) return 1
    }
    return 0
  }

  # Returns the index of the `discolike` word if this segment invokes the CLI,
  # else 0. Accepts `discolike ...` and `uvx --from discolike-cli[==ver] discolike ...`.
  function cli_index(tok, n) {
    if (n >= 1 && tok[1] == "discolike") return 1
    if (n >= 4 && tok[1] == "uvx" && tok[2] == "--from" && tok[4] == "discolike" \
        && (tok[3] == "discolike-cli" || tok[3] ~ /^discolike-cli==[0-9]+\.[0-9]+\.[0-9]+([A-Za-z0-9.-]*)?$/)) return 4
    return 0
  }

  function check_cli(tok, raw, n, start,    j, sub_seen) {
    sub_seen = 0
    for (j = start + 1; j <= n; j++) {
      if (unquoted_meta(raw[j])) return 0
      if (tok[j] ~ /^[\/~]/ || index(tok[j], "..") > 0) return 0
      # --base-url would send the credential to another host: never auto-approve.
      if (tok[j] == "--base-url" || tok[j] ~ /^--base-url=/) return 0
      if (tok[j] == "--api-key") { j++; continue }
      if (substr(tok[j], 1, 1) == "-") continue
      if (!sub_seen) { sub_seen = 1; if (tok[j] in GATE) return 0 }
    }
    return 1
  }

  function check_helper(tok, raw, n, in_pipe,    j) {
    if (n < 1) return 0
    if (in_pipe) { if (!(tok[1] in HELPER)) return 0 }
    else if (tok[1] != "echo" && tok[1] != "printf") return 0
    for (j = 1; j <= n; j++) if (unquoted_meta(raw[j])) return 0
    if (tok[1] == "echo" || tok[1] == "printf") return 1
    positional = 0
    for (j = 2; j <= n; j++) {
      if (index(tok[j], "/") > 0 || index(tok[j], "~") > 0) return 0
      if (tok[j] ~ /^--(output|file|input|rawfile|slurpfile|argfile|from-file)(=|$)/) return 0
      if (tok[j] ~ /^-[A-Za-z]*[ofi]/) return 0
      if (substr(tok[j], 1, 1) != "-") {
        positional++
        # jq: one positional (the filter); a second is a file to read.
        if (tok[1] == "jq" && positional > 1) return 0
        # other helpers: a dotfile positional is a cwd read (.env).
        if (tok[1] != "jq" && substr(tok[j], 1, 1) == ".") return 0
      }
    }
    return 1
  }

  {
    nclause = split_unquoted($0, ";", clause)
    saw_cli = 0
    for (ci = 1; ci <= nclause; ci++) {
      nseg = split_unquoted(clause[ci], "|", seg)
      clause_has_cli = 0
      for (si = 1; si <= nseg; si++) {
        delete tok; delete raw
        n = tokenize(seg[si], tok, raw)
        if (n == 0) exit
        if (raw[1] ~ /^[A-Za-z_][A-Za-z0-9_]*=/) exit
        if (cli_index(tok, n)) clause_has_cli = 1
      }
      for (si = 1; si <= nseg; si++) {
        delete tok; delete raw
        n = tokenize(seg[si], tok, raw)
        start = cli_index(tok, n)
        if (start) { if (!check_cli(tok, raw, n, start)) exit; saw_cli = 1 }
        else if (!check_helper(tok, raw, n, clause_has_cli)) exit
      }
    }
    if (saw_cli) print "allow"
  }
')"

[ "$verdict" = "allow" ] || exit 0

reason="discolike CLI is allowlisted by the DiscoLike plugin"
case "$agent" in
  cursor)
    printf '%s\n' '{"continue":true,"permission":"allow"}'
    ;;
  codex)
    printf '%s\n' '{"hookSpecificOutput":{"hookEventName":"PermissionRequest","decision":{"behavior":"allow"}}}'
    ;;
  *)
    printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow","permissionDecisionReason":"%s"}}\n' "$reason"
    ;;
esac
