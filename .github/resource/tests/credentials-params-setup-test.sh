#!/usr/bin/env bash
# Copyright (c) IBM Corporation.
#
# Regression checks for param_file resolution in credentials-params-setup.sh.
# Uses synthetic values and stub yq/jq-compatible/gh commands; no secrets are
# written anywhere and no network access is used.
#
# Usage: .github/resource/tests/credentials-params-setup-test.sh

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESOURCE_DIR="$(cd "$HERE/.." && pwd)"
SCRIPT="$RESOURCE_DIR/credentials-params-setup.sh"
PASS=0
FAIL=0

ok()  { PASS=$((PASS + 1)); echo "  PASS: $1"; }
bad() { FAIL=$((FAIL + 1)); echo "  FAIL: $1"; }

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$WORK/bin" "$WORK/elsewhere" "$WORK/workflows"

# Stub gh: records the secret NAME only (never the value read from stdin).
cat > "$WORK/bin/gh" <<'EOF'
#!/usr/bin/env bash
cat > /dev/null
echo "$*" >> "$STUB_LOG"
EOF
# Stub yq: emits the synthetic parameters as JSON lines regardless of file
# contents, but fails like the real tool would if the file is not readable.
cat > "$WORK/bin/yq" <<'EOF'
#!/usr/bin/env bash
file="${@: -1}"
if [ "$1" = "eval" ] && [ -r "$file" ]; then
  echo '{"name":"SYNTHETIC_ONE","value":"v1"}'
  echo '{"name":"SYNTHETIC_TWO","value":"v2"}'
  echo "$file" >> "$STUB_YQ_FILES"
  exit 0
fi
if [ "$1" = "-r" ]; then jq -r "$2"; exit 0; fi
exit 1
EOF
chmod +x "$WORK/bin/gh" "$WORK/bin/yq"
export STUB_LOG="$WORK/gh.log" STUB_YQ_FILES="$WORK/yq-files.log"

reset() { : > "$STUB_LOG"; : > "$STUB_YQ_FILES"; }

# Default file (next to the script) and an alternate file with distinct names
DEFAULT_FILE="$RESOURCE_DIR/credentials-params.yaml"
ALT_FILE="$WORK/alt-params.yaml"
echo "- name: SYNTHETIC_ONE" > "$ALT_FILE"

echo "documented sourced invocation (cwd=.github/workflows, relative param_file)"
reset
( cd "$RESOURCE_DIR/../workflows" && PATH="$WORK/bin:$PATH" bash -c '
    set -Eeuo pipefail
    export param_file="../resource/credentials-params.yaml"
    source ../resource/credentials-params-setup.sh' ) > "$WORK/out.log" 2>&1
rc=$?
[ $rc -eq 0 ] && ok "exit 0" || bad "exit $rc"
grep -q -x '\.\./resource/credentials-params.yaml' "$STUB_YQ_FILES" && ok "uses caller's ../resource/credentials-params.yaml" || bad "did not use caller's param_file"
grep -q 'workflows/credentials-params.yaml' "$STUB_YQ_FILES" && bad "resolved .github/workflows/credentials-params.yaml" || ok "does not resolve under .github/workflows"
[ "$(wc -l < "$STUB_LOG" | tr -d ' ')" = "2" ] && ok "two secrets set" || bad "unexpected secret writes"

echo "direct execution from another directory"
reset
( cd "$WORK/elsewhere" && PATH="$WORK/bin:$PATH" bash "$SCRIPT" ) > "$WORK/out.log" 2>&1
rc=$?
[ $rc -eq 0 ] && ok "exit 0" || bad "exit $rc"
grep -q -x "$DEFAULT_FILE" "$STUB_YQ_FILES" && ok "defaults to credentials-params.yaml next to the script" || bad "default path wrong: $(cat "$STUB_YQ_FILES")"

echo "sourced without param_file defaults next to the script (not \$0)"
reset
( cd "$WORK/elsewhere" && PATH="$WORK/bin:$PATH" bash -c "source '$SCRIPT'" ) > "$WORK/out.log" 2>&1
rc=$?
[ $rc -eq 0 ] && ok "exit 0" || bad "exit $rc"
grep -q -x "$DEFAULT_FILE" "$STUB_YQ_FILES" && ok "defaults to credentials-params.yaml next to the script" || bad "default path wrong: $(cat "$STUB_YQ_FILES")"

echo "explicit alternate param_file is preserved"
reset
( cd "$WORK/elsewhere" && param_file="$ALT_FILE" PATH="$WORK/bin:$PATH" bash "$SCRIPT" ) > "$WORK/out.log" 2>&1
rc=$?
[ $rc -eq 0 ] && ok "exit 0" || bad "exit $rc"
grep -q -x "$ALT_FILE" "$STUB_YQ_FILES" && ok "uses the alternate file" || bad "alternate file not used"
grep -q -x "$DEFAULT_FILE" "$STUB_YQ_FILES" && bad "also read the default file" || ok "default file not read"

echo "missing file fails before validation and secret writes"
reset
( cd "$WORK/elsewhere" && param_file="$WORK/does-not-exist.yaml" PATH="$WORK/bin:$PATH" bash "$SCRIPT" ) > "$WORK/out.log" 2>&1
rc=$?
[ $rc -ne 0 ] && ok "nonzero exit" || bad "exited 0"
grep -q "$WORK/does-not-exist.yaml" "$WORK/out.log" && ok "reports the path" || bad "path not reported"
[ ! -s "$STUB_YQ_FILES" ] && ok "no validation attempted" || bad "validation attempted"
[ ! -s "$STUB_LOG" ] && ok "no secret writes" || bad "secrets were written"
grep -q -E 'v1|v2' "$WORK/out.log" && bad "output contains parameter values" || ok "no parameter values printed"

echo "directory / unreadable path fails the same way"
reset
( cd "$WORK/elsewhere" && param_file="$WORK" PATH="$WORK/bin:$PATH" bash "$SCRIPT" ) > "$WORK/out.log" 2>&1
rc=$?
[ $rc -ne 0 ] && [ ! -s "$STUB_LOG" ] && ok "directory rejected, no secret writes" || bad "directory accepted"

echo
echo "Passed: $PASS  Failed: $FAIL"
[ "$FAIL" -eq 0 ]
