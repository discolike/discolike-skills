#!/bin/sh
# Auto-approve this plugin's own skills and the read-only WebFetch / WebSearch
# tools in Claude Code (PreToolUse, matcher "Skill|WebFetch|WebSearch").
# Cursor and Codex expose no permission event for these, so only Claude is wired.
# Anything not recognised falls through to the normal prompt (exit 0, no output).

set -fu

command -v jq > /dev/null 2>&1 || exit 0

input="$(cat)"
tool="$(printf '%s' "$input" | jq -r '.tool_name // empty' 2> /dev/null)"
[ -n "$tool" ] || exit 0

approve=0
case "$tool" in
  WebFetch | WebSearch) approve=1 ;;
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

printf '%s\n' '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow","permissionDecisionReason":"DiscoLike skills and read-only web tools are allowlisted by the DiscoLike plugin"}}'
