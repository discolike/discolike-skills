#!/bin/sh
# Auto-approve this plugin's own skills and WebFetch of DiscoLike-owned hosts
# in Claude Code (PreToolUse, matcher "Skill|WebFetch").
# Cursor and Codex expose no permission event for these, so only Claude is wired.
# Anything not recognised falls through to the normal prompt (exit 0, no output).

set -fu

command -v jq > /dev/null 2>&1 || exit 0

input="$(cat)"
tool="$(printf '%s' "$input" | jq -r '.tool_name // empty' 2> /dev/null)"
[ -n "$tool" ] || exit 0

approve=0
case "$tool" in
  WebFetch)
    url="$(printf '%s' "$input" | jq -r '.tool_input.url // empty' 2> /dev/null)"
    # Scheme and host are matched literally, so userinfo, ports, and
    # look-alike hosts (docs.discolike.com.evil.example) fall through.
    case "$url" in
      https://docs.discolike.com | https://docs.discolike.com/* \
        | https://api.discolike.com | https://api.discolike.com/* \
        | https://github.com/[Dd]iscolike/* \
        | https://raw.githubusercontent.com/[Dd]iscolike/*) approve=1 ;;
    esac
    ;;
  Skill)
    skill="$(printf '%s' "$input" | jq -r '.tool_input.skill // empty' 2> /dev/null)"
    skill="${skill#discolike:}"
    case "$skill" in
      '' | *[!A-Za-z0-9_-]*) skill="" ;;
    esac
    if [ -n "$skill" ]; then
      root="${CLAUDE_PLUGIN_ROOT:-}"
      [ -n "$root" ] || root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
      # A skill directory under this plugin is exactly a real DiscoLike skill.
      [ -f "$root/skills/$skill/SKILL.md" ] && approve=1
    fi
    ;;
esac

[ "$approve" -eq 1 ] || exit 0

printf '%s\n' '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow","permissionDecisionReason":"DiscoLike skills and DiscoLike-owned web pages are allowlisted by the DiscoLike plugin"}}'
