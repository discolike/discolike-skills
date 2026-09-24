#!/bin/sh
# Tests for bin/discolike, the pinned CLI launcher. Run: sh hooks/test-launcher.sh
# Uses a scratch copy of bin/ and stub uvx/uv binaries on a controlled PATH, so
# no network and no real CLI are involved.
set -u
root="$(cd "$(dirname "$0")/.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
pass=0; fail=0
ok() { pass=$((pass + 1)); }
ko() { fail=$((fail + 1)); printf 'FAIL %s\n' "$1"; }

fresh() { # fresh <version-file-content or "-" for none>
  rm -rf "$tmp/bin" "$tmp/stubs" "$tmp"/*.args; mkdir -p "$tmp/bin" "$tmp/stubs"
  cp "$root/bin/discolike" "$tmp/bin/discolike"; chmod +x "$tmp/bin/discolike"
  [ "$1" = "-" ] || printf '%s' "$1" > "$tmp/bin/cli-version"
}
stub() { # stub <name>: records argv to $tmp/<name>.args and exits 0
  printf '#!/bin/sh\nprintf "%%s\\n" "$@" > "%s/%s.args"\nexit 0\n' "$tmp" "$1" > "$tmp/stubs/$1"; chmod +x "$tmp/stubs/$1"
}
base_path="/usr/bin:/bin"

# 1. uvx present: runs the pinned version with the user's args passed through.
fresh "1.2.3"; stub uvx
PATH="$tmp/stubs:$base_path" "$tmp/bin/discolike" count --country US > /dev/null 2>&1; code=$?
[ "$code" -eq 0 ] && ok || ko "uvx run exit=$code"
[ "$(tr '\n' ' ' < "$tmp/uvx.args")" = "--quiet --from discolike-cli==1.2.3 discolike count --country US " ] && ok || ko "uvx argv: $(cat "$tmp/uvx.args" | tr '\n' ' ')"

# 2. Version file with surrounding whitespace is trimmed.
fresh "  1.2.3
"; stub uvx
PATH="$tmp/stubs:$base_path" "$tmp/bin/discolike" --version > /dev/null 2>&1
grep -q 'discolike-cli==1.2.3' "$tmp/uvx.args" && ok || ko "whitespace trim"

# 3. No uvx, uv present: falls back to `uv tool run`.
fresh "1.2.3"; stub uv
PATH="$tmp/stubs:$base_path" "$tmp/bin/discolike" --version > /dev/null 2>&1; code=$?
[ "$code" -eq 0 ] && [ "$(head -3 "$tmp/uv.args" | tr '\n' ' ')" = "tool run --quiet " ] && grep -q 'discolike-cli==1.2.3' "$tmp/uv.args" && ok || ko "uv fallback"

# 4. Neither runtime: JSON envelope on stderr, nothing on stdout, exit 5.
fresh "1.2.3"
out="$(PATH="$base_path" "$tmp/bin/discolike" --version 2> "$tmp/err")"; code=$?
[ "$code" -eq 5 ] && ok || ko "missing uv exit=$code"
[ -z "$out" ] && ok || ko "missing uv wrote to stdout"
jq -e '.code == "network_error" and .exit_code == 5 and (.message | test("uv is not installed"))' < "$tmp/err" > /dev/null && ok || ko "missing uv envelope: $(cat "$tmp/err")"

# 5. Missing version file: exit 1 with internal_error envelope.
fresh "-"; stub uvx
PATH="$tmp/stubs:$base_path" "$tmp/bin/discolike" --version 2> "$tmp/err"; code=$?
[ "$code" -eq 1 ] && jq -e '.code == "internal_error"' < "$tmp/err" > /dev/null && ok || ko "missing version file exit=$code"
[ ! -e "$tmp/uvx.args" ] && ok || ko "ran uvx without a version"

# 6. Empty version file: exit 1.
fresh ""; stub uvx
PATH="$tmp/stubs:$base_path" "$tmp/bin/discolike" --version 2> "$tmp/err"; code=$?
[ "$code" -eq 1 ] && jq -e '.code == "internal_error"' < "$tmp/err" > /dev/null && ok || ko "empty version file exit=$code"

# 7. Invoked as a bare command through PATH resolves its own directory.
fresh "1.2.3"; stub uvx
( cd "$tmp" && PATH="$tmp/bin:$tmp/stubs:$base_path" discolike --version > /dev/null 2>&1 ); code=$?
[ "$code" -eq 0 ] && grep -q 'discolike-cli==1.2.3' "$tmp/uvx.args" && ok || ko "bare-name resolution exit=$code"

# 8. Envelope stays valid JSON when the message carries quotes (path with a quote).
q="$tmp/we\"ird"; mkdir -p "$q/bin"; cp "$root/bin/discolike" "$q/bin/discolike"; chmod +x "$q/bin/discolike"
PATH="$base_path" "$q/bin/discolike" --version 2> "$tmp/err"; code=$?
[ "$code" -eq 1 ] && jq -e '.code == "internal_error"' < "$tmp/err" > /dev/null && ok || ko "quote escaping: $(cat "$tmp/err")"

printf '%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
