#!/usr/bin/env bash
# Copyright (c) IBM Corporation.
#
# Add an image version to a Partner Center virtual machine plan through the
# Product Ingestion API (read-modify-submit).
#
# Safeguards:
#   - every request carries the required $version query parameter
#   - the plan is selected by exact match of the configured planId against
#     .identity.externalId; zero or multiple matches stop the job before any
#     configuration is submitted (no first-plan fallback)
#   - the selected plan must belong to the resolved product
#   - an existing technical configuration is read before it is rewritten; any
#     unexpected read failure aborts instead of being treated as "no configuration"
#   - newly generated SKU IDs are lowercase (schema: ^[a-z0-9-_]+$) while
#     imageType keeps its enum spelling (x64Gen2); existing mappings are preserved
#
# Required environment:
#   offerId planId clientId tenantId secretValue imageType imageVersionNumber
#   operatingSystemFamily operatingSystemType osDiskSasUrl dataDiskSasUrl
# Optional environment:
#   PC_BASE_URL       default https://graph.microsoft.com/rp/product-ingestion
#   PC_API_VERSION    default 2022-03-01-preview3 (schema version the payload targets;
#                     $version acts as a maximum, so newer resource versions are not returned)
#   PC_POLL_INTERVAL  seconds between job status checks, default 30
#   PC_MAX_PAGES      maximum plan list pages to follow, default 50

PC_BASE_URL="${PC_BASE_URL:-https://graph.microsoft.com/rp/product-ingestion}"
PC_API_VERSION="${PC_API_VERSION:-2022-03-01-preview3}"
PC_POLL_INTERVAL="${PC_POLL_INTERVAL:-30}"
PC_MAX_PAGES="${PC_MAX_PAGES:-50}"

pc_error() { echo "ERROR: $*" >&2; }

pc_show_body() {
  [ -s "$PC_BODY" ] && head -c 2000 "$PC_BODY" >&2 && echo >&2
}

# pc_call METHOD URL [JSON_BODY]
# Sets PC_HTTP_CODE; the response body is left in $PC_BODY.
# Returns nonzero only when the request itself could not be completed.
pc_call() {
  local method="$1" url="$2" data="${3-}" rc
  local args=(-sS -o "$PC_BODY" -w '%{http_code}' -X "$method" -H "Authorization: Bearer ${token}")
  if [ -n "$data" ]; then
    args+=(-H "Content-Type: application/json" -H "accept: application/json" -d "$data")
  fi
  PC_HTTP_CODE=$(curl "${args[@]}" "$url")
  rc=$?
  if [ $rc -ne 0 ]; then
    pc_error "$method $url could not be completed (curl exit $rc)"
    return 1
  fi
  return 0
}

# pc_get_ok URL WHAT : GET that must return HTTP 200 and a JSON object.
pc_get_ok() {
  pc_call GET "$1" || return 1
  if [ "$PC_HTTP_CODE" != "200" ]; then
    pc_error "$2 returned HTTP ${PC_HTTP_CODE}"
    pc_show_body
    return 1
  fi
  if ! jq -e 'type == "object"' "$PC_BODY" >/dev/null 2>&1; then
    pc_error "$2 returned a malformed (non-JSON-object) response"
    pc_show_body
    return 1
  fi
}

pc_obtain_token() {
  local rc
  PC_HTTP_CODE=$(curl -sS -o "$PC_BODY" -w '%{http_code}' -X POST \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "grant_type=client_credentials&client_id=${clientId}&client_secret=${secretValue}&resource=https://graph.microsoft.com" \
    "https://login.microsoftonline.com/${tenantId}/oauth2/token")
  rc=$?
  if [ $rc -ne 0 ] || [ "$PC_HTTP_CODE" != "200" ]; then
    pc_error "Could not obtain a Partner Center token (curl exit ${rc}, HTTP ${PC_HTTP_CODE:-none})"
    return 1
  fi
  token=$(jq -r '.access_token // empty' "$PC_BODY" 2>/dev/null)
  if [ -z "$token" ]; then
    pc_error "Token response did not contain an access_token"
    return 1
  fi
}

# Sets productDurableId (e.g. product/<uuid>).
pc_resolve_product() {
  pc_get_ok "${PC_BASE_URL}/product?externalId=${offerId}&\$version=${PC_API_VERSION}" "Product lookup" || return 1
  if ! jq -e '(.value | type) == "array"' "$PC_BODY" >/dev/null 2>&1; then
    pc_error "Product lookup response has no .value array"
    return 1
  fi
  local count
  count=$(jq '.value | length' "$PC_BODY")
  if [ "$count" != "1" ]; then
    pc_error "Expected exactly one product with externalId '${offerId}', found ${count}"
    return 1
  fi
  productDurableId=$(jq -r '.value[0].id // empty' "$PC_BODY")
  if ! echo "$productDurableId" | grep -Eq '^product/[^/]+$'; then
    pc_error "Product lookup returned an unexpected id: '${productDurableId}'"
    return 1
  fi
  echo "productDurableId: ${productDurableId}"
}

# Collects every page of the product's plans into $allPlans (JSON array).
pc_list_plans() {
  local url="${PC_BASE_URL}/plan?product=${productDurableId}&\$version=${PC_API_VERSION}"
  local page=0 next token_next
  allPlans="[]"
  while :; do
    page=$((page + 1))
    if [ "$page" -gt "$PC_MAX_PAGES" ]; then
      pc_error "Plan list exceeded ${PC_MAX_PAGES} pages"
      return 1
    fi
    pc_get_ok "$url" "Plan list (page ${page})" || return 1
    if ! jq -e '(.value | type) == "array"' "$PC_BODY" >/dev/null 2>&1; then
      pc_error "Plan list response (page ${page}) has no .value array"
      pc_show_body
      return 1
    fi
    allPlans=$(jq -c --slurpfile p "$PC_BODY" '. + $p[0].value' <<<"$allPlans") || return 1

    next=$(jq -r '.["@nextLink"] // .nextLink // empty' "$PC_BODY")
    token_next=$(jq -r '.continuationToken // empty' "$PC_BODY")
    if [ -n "$next" ]; then
      case "$next" in
        "${PC_BASE_URL}/"*) ;;
        *) pc_error "Refusing to follow plan list nextLink outside ${PC_BASE_URL}"; return 1 ;;
      esac
      case "$next" in
        *'$version='*) url="$next" ;;
        *) url="${next}&\$version=${PC_API_VERSION}" ;;
      esac
    elif [ -n "$token_next" ]; then
      url="${PC_BASE_URL}/plan?product=${productDurableId}&continuationToken=$(jq -rn --arg t "$token_next" '$t|@uri')&\$version=${PC_API_VERSION}"
    else
      return 0
    fi
  done
}

# Sets planDurableId. Exact, fail-closed selection by .identity.externalId.
pc_resolve_plan() {
  pc_list_plans || return 1

  local matches
  matches=$(jq -c --arg pid "$planId" '[.[] | select(type == "object" and .identity.externalId? == $pid)]' <<<"$allPlans") || return 1
  local count
  count=$(jq 'length' <<<"$matches")

  if [ "$count" != "1" ]; then
    pc_error "Expected exactly one plan with .identity.externalId '${planId}' in product '${offerId}' (${productDurableId}); found ${count}."
    echo "Available plans (durable id / .identity.externalId):" >&2
    jq -r '.[] | "  \(.id // "<no id>") / \(.identity.externalId? // "<no identity.externalId>")"' <<<"$allPlans" >&2
    echo "Correct the configured planId or the plan's external ID; no configuration was submitted." >&2
    return 1
  fi

  planDurableId=$(jq -r '.[0].id // empty' <<<"$matches")
  local planProduct productUuid
  productUuid="${productDurableId#product/}"
  planProduct=$(jq -r '.[0].product // empty | if type == "string" then . else "" end' <<<"$matches")
  if ! echo "$planDurableId" | grep -Eq "^plan/${productUuid}/[^/]+$"; then
    pc_error "Selected plan id '${planDurableId}' does not belong to product '${productDurableId}'"
    return 1
  fi
  if [ -n "$planProduct" ] && [ "$planProduct" != "$productDurableId" ]; then
    pc_error "Selected plan reports product '${planProduct}', expected '${productDurableId}'"
    return 1
  fi
  echo "planDurableId: ${planDurableId}"
}

# build_skus EXISTING_SKUS_JSON IMAGE_TYPE
# Prints the SKU list to submit. imageType is never modified; only a newly
# generated skuId is lowercased. Existing mappings are preserved. Duplicate or
# conflicting mappings fail.
build_skus() {
  local newSku
  newSku=$(printf %s "$2" | tr '[:upper:]' '[:lower:]')
  jq -e -c --arg type "$2" --arg newSku "$newSku" '
    if type != "array" then error("skus is not an array") else . end
    | if any(.[]; (type != "object") or ((.imageType | type) != "string") or ((.skuId | type) != "string"))
        then error("malformed sku entry") else . end
    | if ([.[].imageType] | group_by(.) | any(length > 1)) then error("duplicate imageType mappings") else . end
    | if ([.[].skuId] | group_by(.) | any(length > 1)) then error("duplicate skuId mappings") else . end
    | if any(.[]; .imageType == $type) then .
      elif any(.[]; .skuId == $newSku) then error("skuId \($newSku) is already mapped to another imageType")
      else . + [{imageType: $type, skuId: $newSku}] end
    | if length > 2 then error("more than 2 skus") else . end
  ' <<<"$1"
}

# Sets imageVersions and skus from the existing technical configuration.
pc_read_technical_config() {
  local url="${PC_BASE_URL}/virtual-machine-plan-technical-configuration/${productIdWithoutPrefix}/${planIdWithoutPrefix}?\$version=${PC_API_VERSION}"
  echo "techConfig URL: ${url}"
  pc_call GET "$url" || return 1
  echo "Tech config GET response: ${PC_HTTP_CODE}"

  case "$PC_HTTP_CODE" in
    200)
      if ! jq -e 'type == "object"
                  and ((.vmImageVersions // []) | type) == "array"
                  and ((.skus // []) | type) == "array"' "$PC_BODY" >/dev/null 2>&1; then
        pc_error "Existing technical configuration is malformed"
        pc_show_body
        return 1
      fi
      imageVersions=$(jq -c '.vmImageVersions // []' "$PC_BODY")
      skus=$(build_skus "$(jq -c '[(.skus // [])[] | {imageType, skuId}]' "$PC_BODY")" "$imageType") || {
        pc_error "Existing SKU mappings are not usable for imageType '${imageType}'"
        return 1
      }
      ;;
    404)
      # Initialize only when the API conclusively reports the configuration is absent.
      if jq -e '(.error.code // "") | ascii_downcase == "resourcenotfound"' "$PC_BODY" >/dev/null 2>&1; then
        echo "No technical configuration exists for this plan; initializing."
        imageVersions="[]"
        skus=$(build_skus "[]" "$imageType") || return 1
      else
        pc_error "Technical configuration GET returned 404 without a resourceNotFound error; not initializing"
        pc_show_body
        return 1
      fi
      ;;
    *)
      pc_error "Technical configuration GET returned HTTP ${PC_HTTP_CODE}; refusing to overwrite unknown state"
      pc_show_body
      return 1
      ;;
  esac
}

pc_publish_main() {
  local v
  for v in offerId planId clientId tenantId secretValue imageType imageVersionNumber \
           operatingSystemFamily operatingSystemType osDiskSasUrl dataDiskSasUrl; do
    if [ -z "${!v:-}" ]; then
      pc_error "Required environment variable $v is not set"
      return 1
    fi
  done

  PC_BODY=$(mktemp) || return 1
  trap 'rm -f "$PC_BODY"' EXIT

  pc_obtain_token || return 1
  pc_resolve_product || return 1
  pc_resolve_plan || return 1

  productIdWithoutPrefix=$(echo "$productDurableId" | cut -d'/' -f2)
  # plan/PRODUCT-UUID/PLAN-UUID -> field 3
  planIdWithoutPrefix=$(echo "$planDurableId" | cut -d'/' -f3)

  pc_read_technical_config || return 1

  local imageVersionsAppended requestData
  imageVersionsAppended=$(echo "$imageVersions" | jq -c \
    --arg vNum  "$imageVersionNumber" \
    --arg type  "$imageType" \
    --arg osUrl "$osDiskSasUrl" \
    --arg dataUrl "$dataDiskSasUrl" \
    '[.[] | select(.versionNumber != $vNum)] + [{"versionNumber":$vNum,"vmImages":[{"imageType":$type,"source":{"sourceType":"sasUri","osDisk":{"uri":$osUrl},"dataDisks":[{"lunNumber":0,"uri":$dataUrl}]}}]}]') || return 1

  # skus must declare all image types present in vmImageVersions
  requestData=$(jq -n \
    --arg schema      "https://schema.mp.microsoft.com/schema/configure/2022-03-01-preview2" \
    --arg tcSchema    "https://schema.mp.microsoft.com/schema/virtual-machine-plan-technical-configuration/2022-03-01-preview3" \
    --arg offerId     "$offerId" \
    --arg planDurable "$planDurableId" \
    --arg osFamily    "$operatingSystemFamily" \
    --arg osType      "$operatingSystemType" \
    --argjson skus "$skus" \
    --argjson imageVersions "$imageVersionsAppended" \
    '{
      "$schema": $schema,
      "resources": [{
        "$schema": $tcSchema,
        "product": {"externalId": $offerId},
        "plan":    $planDurable,
        "operatingSystem": {"family": $osFamily, "type": $osType},
        "skus": $skus,
        "vmImageVersions": $imageVersions
      }]
    }') || return 1

  echo "Request payload:"
  echo "$requestData" | jq .
  pc_call POST "${PC_BASE_URL}/configure?\$version=${PC_API_VERSION}" "$requestData" || return 1
  echo "Configure response (HTTP ${PC_HTTP_CODE}):"
  jq . "$PC_BODY" 2>/dev/null || cat "$PC_BODY"
  case "$PC_HTTP_CODE" in
    2??) ;;
    *) pc_error "Configure POST returned HTTP ${PC_HTTP_CODE}"; return 1 ;;
  esac
  local jobId
  jobId=$(jq -r '.jobId // .jobID // empty' "$PC_BODY")
  if [ -z "$jobId" ]; then
    pc_error "No jobId returned from configure POST."
    return 1
  fi
  echo "Submitted configuration job: ${jobId}"

  # Poll until complete (up to 11 attempts)
  local attempt=0 result="pending" jobStatusJson=""
  while [ "$result" = "pending" ] && [ $attempt -le 10 ]; do
    sleep "$PC_POLL_INTERVAL"
    pc_get_ok "${PC_BASE_URL}/configure/${jobId}/status?\$version=${PC_API_VERSION}" "Job status" || return 1
    jobStatusJson=$(cat "$PC_BODY")
    result=$(jq -r '.jobResult // "pending"' "$PC_BODY")
    echo "Job ${jobId} status: $(jq -r '.jobStatus' "$PC_BODY") / result: ${result}"
    attempt=$((attempt + 1))
  done

  if [ "$result" != "succeeded" ]; then
    echo "Partner Center job failed or timed out. Final status:"
    echo "$jobStatusJson" | jq .
    return 1
  fi
  echo "Partner Center image version ${imageVersionNumber} submitted successfully."
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  set -u
  pc_publish_main
  exit $?
fi
