#!/bin/sh
# Tests for hooks/approve-skills.sh. Run: sh hooks/test-approve-skills.sh
set -u
root="$(cd "$(dirname "$0")/.." && pwd)"
hook="$root/hooks/approve-skills.sh"
pass=0; fail=0

run() { # run <json> -> prints the hook's stdout
  printf '%s' "$1" | CLAUDE_PLUGIN_ROOT="$root" sh "$hook" 2> /dev/null
}
expect_allow() {
  case "$(run "$1")" in
    *'"permissionDecision":"allow"'*) pass=$((pass + 1)) ;;
    *) fail=$((fail + 1)); printf 'FAIL expected allow: %s\n' "$1" ;;
  esac
}
expect_prompt() {
  if [ -z "$(run "$1")" ]; then pass=$((pass + 1)); else fail=$((fail + 1)); printf 'FAIL expected prompt: %s\n' "$1"; fi
}
fetch() { printf '{"tool_name":"WebFetch","tool_input":{"url":"%s"}}' "$1"; }
skill() { printf '{"tool_name":"Skill","tool_input":{"skill":"%s"}}' "$1"; }

# Skills bundled in this plugin.
expect_allow "$(skill discolike)"
expect_allow "$(skill discolike:setup)"
expect_allow "$(skill feedback)"
expect_prompt "$(skill commit)"
expect_prompt "$(skill '../hooks')"
expect_prompt "$(skill '')"

# WebFetch: DiscoLike-owned hosts only.
expect_allow "$(fetch https://docs.discolike.com)"
expect_allow "$(fetch https://docs.discolike.com/guides/agent-signup/)"
expect_allow "$(fetch https://api.discolike.com/v1/mcp)"
expect_allow "$(fetch https://github.com/Discolike/discolike-skills/issues)"
expect_allow "$(fetch https://github.com/discolike/discolike-python)"
expect_allow "$(fetch https://raw.githubusercontent.com/discolike/discolike-skills/main/skills/discolike/SKILL.md)"
expect_prompt "$(fetch http://docs.discolike.com/)"
expect_prompt "$(fetch https://docs.discolike.com.evil.example/)"
expect_prompt "$(fetch https://docs.discolike.com@evil.example/)"
expect_prompt "$(fetch https://evil.example/?u=https://docs.discolike.com/)"
expect_prompt "$(fetch https://docs.discolike.com:8443/)"
expect_prompt "$(fetch https://github.com/someone-else/discolike)"
expect_prompt "$(fetch https://github.com/)"
expect_prompt "$(fetch https://raw.githubusercontent.com/other/repo/main/x)"
expect_prompt '{"tool_name":"WebFetch","tool_input":{}}'

# Other tools and malformed input never approve.
expect_prompt '{"tool_name":"WebSearch","tool_input":{"query":"discolike"}}'
expect_prompt '{"tool_name":"Bash","tool_input":{"command":"discolike count"}}'
expect_prompt '{}'
expect_prompt 'not json'

printf '%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
