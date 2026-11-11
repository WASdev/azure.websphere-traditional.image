#!/usr/bin/env bash
# Copyright (c) IBM Corporation.
#
# Fixture tests for .github/resource/publish-vm-image.sh.
# Uses a stub curl (tests/bin/curl); never touches the network or Partner Center.
#
# Usage: .github/resource/tests/publish-vm-image-test.sh

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$HERE/../publish-vm-image.sh"
SCHEMA="$HERE/fixtures/vm-technical-config-schema.json"
PASS=0
FAIL=0

P=product/11111111-1111-1111-1111-111111111111
GEN1=plan/11111111-1111-1111-1111-111111111111/aaaaaaaa-0000-0000-0000-000000000001
GEN2=plan/11111111-1111-1111-1111-111111111111/bbbbbbbb-0000-0000-0000-000000000002
OTHER=plan/22222222-2222-2222-2222-222222222222/cccccccc-0000-0000-0000-000000000003

ok()   { PASS=$((PASS + 1)); echo "  PASS: $1"; }
bad()  { FAIL=$((FAIL + 1)); echo "  FAIL: $1"; }
check() { # check DESC COMMAND...
  local d="$1"; shift
  if "$@" >/dev/null 2>&1; then ok "$d"; else bad "$d"; fi
}

new_case() { # sets STUB_DIR with defaults for a healthy flow
  STUB_DIR=$(mktemp -d)
  export STUB_DIR
  echo '{"access_token":"t"}' > "$STUB_DIR/POST_token.json"
  echo "{\"value\":[{\"id\":\"$P\",\"identity\":{\"externalId\":\"my-offer\"}}]}" > "$STUB_DIR/GET_product.json"
  plans "$GEN1:my-offer-gen1" "$GEN2:my-offer-gen2"
  echo '{"vmImageVersions":[],"skus":[]}' > "$STUB_DIR/GET_techconfig.json"
  echo '{"jobId":"job-1","jobStatus":"notStarted","jobResult":"pending"}' > "$STUB_DIR/POST_configure.json"
  echo '{"jobStatus":"completed","jobResult":"succeeded"}' > "$STUB_DIR/GET_status.json"
}

plans() { # plans "id:externalId" ... -> GET_plan.json
  local arr="[]" spec id ext
  for spec in "$@"; do
    id="${spec%%:*}"; ext="${spec#*:}"
    arr=$(jq -c --arg id "$id" --arg ext "$ext" --arg p "$P" '. + [{id:$id, product:$p, identity:{externalId:$ext}}]' <<<"$arr")
  done
  echo "{\"value\":$arr}" > "$STUB_DIR/GET_plan.json"
}

run_publish() { # run_publish PLAN_ID ; output in $STUB_DIR/out.log, status in $RC
  PATH="$HERE/bin:$PATH" \
  offerId=my-offer planId="$1" clientId=c tenantId=t secretValue=s \
  imageType=x64Gen2 imageVersionNumber=9.0.20260101 \
  operatingSystemFamily=linux operatingSystemType=redHat \
  osDiskSasUrl=https://example.invalid/os dataDiskSasUrl=https://example.invalid/data \
  PC_POLL_INTERVAL=0 bash "$SCRIPT" > "$STUB_DIR/out.log" 2>&1
  RC=$?
}

no_post() { [ ! -s "$STUB_DIR/posts.log" ]; }
posted()  { grep -q 'POST .*configure' "$STUB_DIR/posts.log" 2>/dev/null; }
all_have_version() { ! grep -v 'login.microsoftonline.com' "$STUB_DIR/requests.log" | grep -v -F '$version=' | grep -q .; }

# ---------------------------------------------------------------- plan lookup
echo "plan resolution"

echo "- Gen1 listed before requested Gen2 selects Gen2 and submits"
new_case; run_publish my-offer-gen2
check "exit 0" test $RC -eq 0
check "POST submitted" posted
check "payload targets the Gen2 durable id" grep -q "\"plan\": \"$GEN2\"" "$STUB_DIR/out.log"
check "Gen1 plan not used" bash -c "! grep -q 'techconfig.*aaaaaaaa' '$STUB_DIR/requests.log'"
check "tech config URL uses Gen2 UUID" grep -q 'technical-configuration/11111111-1111-1111-1111-111111111111/bbbbbbbb-0000-0000-0000-000000000002' "$STUB_DIR/requests.log"
check "every request carries \$version" all_have_version

echo "- no match fails before any POST and lists available plans"
new_case; run_publish nonexistent-plan
check "nonzero exit" test $RC -ne 0
check "no POST" no_post
check "reports available durable IDs" grep -q "$GEN1" "$STUB_DIR/out.log"
check "reports available externalIds" grep -q 'my-offer-gen2' "$STUB_DIR/out.log"
check "reports requested plan" grep -q 'nonexistent-plan' "$STUB_DIR/out.log"

echo "- duplicate matches fail before any POST"
new_case; plans "$GEN1:dup" "$GEN2:dup"; run_publish dup
check "nonzero exit" test $RC -ne 0
check "no POST" no_post

echo "- legacy top-level .externalId is not matched; missing identity fails (no first-plan fallback)"
new_case
echo "{\"value\":[{\"id\":\"$GEN1\",\"externalId\":\"my-offer-gen2\"},{\"id\":\"$GEN2\"}]}" > "$STUB_DIR/GET_plan.json"
run_publish my-offer-gen2
check "nonzero exit" test $RC -ne 0
check "no POST" no_post
check "tech config never read" bash -c "! grep -q technical-configuration '$STUB_DIR/requests.log'"

echo "- malformed plan response fails"
new_case; echo '{"unexpected":true}' > "$STUB_DIR/GET_plan.json"; run_publish my-offer-gen2
check "nonzero exit" test $RC -ne 0
check "no POST" no_post
new_case; echo 'not json' > "$STUB_DIR/GET_plan.json"; run_publish my-offer-gen2
check "non-JSON: nonzero exit" test $RC -ne 0
check "non-JSON: no POST" no_post

echo "- HTTP failures fail before any POST"
new_case; echo 500 > "$STUB_DIR/GET_plan.code"; echo '{}' > "$STUB_DIR/GET_plan.json"; run_publish my-offer-gen2
check "plan list 500: nonzero exit" test $RC -ne 0
check "plan list 500: no POST" no_post
new_case; echo 401 > "$STUB_DIR/GET_product.code"; echo '{}' > "$STUB_DIR/GET_product.json"; run_publish my-offer-gen2
check "product 401: nonzero exit" test $RC -ne 0
check "product 401: no POST" no_post
new_case; echo 403 > "$STUB_DIR/POST_token.code"; run_publish my-offer-gen2
check "token 403: nonzero exit" test $RC -ne 0
check "token 403: no POST" no_post

echo "- plan from another product is rejected"
new_case; plans "$OTHER:my-offer-gen2"; run_publish my-offer-gen2
check "nonzero exit" test $RC -ne 0
check "no POST" no_post

echo "- pagination: match on second page is found"
new_case
jq -c '. + {"continuationToken":"abc 123"}' "$STUB_DIR/GET_plan.json" > "$STUB_DIR/tmp" && mv "$STUB_DIR/tmp" "$STUB_DIR/GET_plan.json"
plans "$GEN1:my-offer-gen1" >/dev/null; jq -c '. + {"continuationToken":"abc 123"}' "$STUB_DIR/GET_plan.json" > "$STUB_DIR/tmp" && mv "$STUB_DIR/tmp" "$STUB_DIR/GET_plan.json"
echo "{\"value\":[{\"id\":\"$GEN2\",\"product\":\"$P\",\"identity\":{\"externalId\":\"my-offer-gen2\"}}]}" > "$STUB_DIR/GET_plan_page2.json"
run_publish my-offer-gen2
check "exit 0" test $RC -eq 0
check "second page requested with encoded token" grep -q 'continuationToken=abc%20123' "$STUB_DIR/requests.log"
check "all requests carry \$version" all_have_version

echo "- duplicate across pages is detected"
new_case
plans "$GEN1:dup"; jq -c '. + {"continuationToken":"t2"}' "$STUB_DIR/GET_plan.json" > "$STUB_DIR/tmp" && mv "$STUB_DIR/tmp" "$STUB_DIR/GET_plan.json"
echo "{\"value\":[{\"id\":\"$GEN2\",\"product\":\"$P\",\"identity\":{\"externalId\":\"dup\"}}]}" > "$STUB_DIR/GET_plan_page2.json"
run_publish dup
check "nonzero exit" test $RC -ne 0
check "no POST" no_post

# ----------------------------------------------------------- technical config
echo "technical configuration read"

echo "- unexpected read failures abort without POST"
for code in 401 403 500 503; do
  new_case; echo "$code" > "$STUB_DIR/GET_techconfig.code"; echo '{"error":{"code":"x"}}' > "$STUB_DIR/GET_techconfig.json"
  run_publish my-offer-gen2
  check "HTTP $code: nonzero exit" test $RC -ne 0
  check "HTTP $code: no POST" no_post
done
new_case; echo 404 > "$STUB_DIR/GET_techconfig.code"; echo '{"error":{"code":"somethingElse"}}' > "$STUB_DIR/GET_techconfig.json"
run_publish my-offer-gen2
check "404 without resourceNotFound: nonzero exit" test $RC -ne 0
check "404 without resourceNotFound: no POST" no_post
new_case; echo '[1,2]' > "$STUB_DIR/GET_techconfig.json"; run_publish my-offer-gen2
check "malformed 200 body: nonzero exit" test $RC -ne 0
check "malformed 200 body: no POST" no_post

echo "- conclusive absence (404 resourceNotFound) initializes"
new_case; echo 404 > "$STUB_DIR/GET_techconfig.code"; echo '{"error":{"code":"resourceNotFound"}}' > "$STUB_DIR/GET_techconfig.json"
run_publish my-offer-gen2
check "exit 0" test $RC -eq 0
check "submitted" posted
check "skus = lowercase x64gen2" bash -c "jq -e '.resources[0].skus == [{\"imageType\":\"x64Gen2\",\"skuId\":\"x64gen2\"}]' '$STUB_DIR/last_post_body.json'"

echo "- existing image versions are preserved on submit"
new_case
echo '{"skus":[{"imageType":"x64Gen2","skuId":"x64gen2"}],"vmImageVersions":[{"versionNumber":"9.0.1","vmImages":[{"imageType":"x64Gen2","source":{"sourceType":"sasUri","osDisk":{"uri":"https://example.invalid/old"}}}]}]}' > "$STUB_DIR/GET_techconfig.json"
run_publish my-offer-gen2
check "exit 0" test $RC -eq 0
check "old version kept, new appended" bash -c "jq -e '[.resources[0].vmImageVersions[].versionNumber] == [\"9.0.1\",\"9.0.20260101\"]' '$STUB_DIR/last_post_body.json'"

# --------------------------------------------------------------------- SKUs
echo "SKU mapping"

sku_case() { # sku_case DESC EXISTING_SKUS_JSON EXPECT(ok|fail) [EXPECTED_SKUS_JSON]
  new_case
  jq -nc --argjson s "$2" '{vmImageVersions:[], skus:$s}' > "$STUB_DIR/GET_techconfig.json"
  run_publish my-offer-gen2
  if [ "$3" = ok ]; then
    check "$1: exit 0" test $RC -eq 0
    check "$1: skus as expected" bash -c "jq -e --argjson e '$4' '.resources[0].skus == \$e' '$STUB_DIR/last_post_body.json'"
    validate_skus "$1: generated payload matches declared schema" "$STUB_DIR/last_post_body.json"
  else
    check "$1: nonzero exit" test $RC -ne 0
    check "$1: no POST" no_post
  fi
}

validate_skus() { # validate_skus DESC PAYLOAD_FILE
  python3 - "$SCHEMA" "$2" <<'EOF' >/dev/null 2>&1
import json, sys
from jsonschema import Draft202012Validator
schema = json.load(open(sys.argv[1]))
body = json.load(open(sys.argv[2]))
root = {"$defs": schema["$defs"], "type": "array", "items": {"$ref": "#/$defs/sku"}, "minItems": 1, "maxItems": 2}
Draft202012Validator(root).validate(body["resources"][0]["skus"])
vroot = {"$defs": schema["$defs"], "type": "array", "items": {"$ref": "#/$defs/vmImageVersion"}}
Draft202012Validator(vroot).validate(body["resources"][0]["vmImageVersions"])
EOF
  if [ $? -eq 0 ]; then ok "$1"; else bad "$1"; fi
}

sku_case "empty SKU list"          '[]' ok '[{"imageType":"x64Gen2","skuId":"x64gen2"}]'
sku_case "Gen1-only list gets Gen2" '[{"imageType":"x64Gen1","skuId":"x64gen1"}]' ok '[{"imageType":"x64Gen1","skuId":"x64gen1"},{"imageType":"x64Gen2","skuId":"x64gen2"}]'
sku_case "existing Gen2 unchanged"  '[{"imageType":"x64Gen2","skuId":"custom-gen2"}]' ok '[{"imageType":"x64Gen2","skuId":"custom-gen2"}]'
sku_case "Gen1 keeps its existing id untouched" '[{"imageType":"x64Gen1","skuId":"legacy_id"},{"imageType":"x64Gen2","skuId":"gen2"}]' ok '[{"imageType":"x64Gen1","skuId":"legacy_id"},{"imageType":"x64Gen2","skuId":"gen2"}]'
sku_case "conflicting: new skuId already used by Gen1" '[{"imageType":"x64Gen1","skuId":"x64gen2"}]' fail
sku_case "duplicate imageType"     '[{"imageType":"x64Gen2","skuId":"a"},{"imageType":"x64Gen2","skuId":"b"}]' fail
sku_case "duplicate skuId"         '[{"imageType":"x64Gen1","skuId":"a"},{"imageType":"x64Gen2","skuId":"a"}]' fail
sku_case "malformed sku entry"     '[{"imageType":"x64Gen2"}]' fail

echo "- regression: the old uppercase skuId fails the declared schema"
old=$(mktemp)
echo '{"resources":[{"skus":[{"imageType":"x64Gen2","skuId":"x64Gen2"}],"vmImageVersions":[]}]}' > "$old"
python3 - "$SCHEMA" "$old" <<'EOF' >/dev/null 2>&1
import json, sys
from jsonschema import Draft202012Validator
schema = json.load(open(sys.argv[1])); body = json.load(open(sys.argv[2]))
root = {"$defs": schema["$defs"], "type": "array", "items": {"$ref": "#/$defs/sku"}}
Draft202012Validator(root).validate(body["resources"][0]["skus"])
EOF
if [ $? -ne 0 ]; then ok "uppercase skuId x64Gen2 is rejected by the schema"; else bad "uppercase skuId was unexpectedly accepted"; fi
rm -f "$old"

echo
echo "Passed: $PASS  Failed: $FAIL"
[ "$FAIL" -eq 0 ]
