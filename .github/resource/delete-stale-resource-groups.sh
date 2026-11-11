#!/usr/bin/env bash
# Copyright (c) IBM Corporation.
#
# Delete test resource groups left behind by *completed* workflow runs.
#
# Group names have the form:
#   IMAGETEST-WASDEV-<owner>-<run_id>-<run_number>-<suffix>
#
# A group is deleted only when ALL of the following hold:
#   - the name matches this repository owner and the given suffix exactly
#   - it does not belong to the current run
#   - the embedded run ID resolves to a run in this repository and that run's
#     status is "completed"
# Anything else (in-progress, queued, unknown run, API failure) is left alone.
#
# Usage: delete-stale-resource-groups.sh <suffix>
# Environment: GITHUB_REPOSITORY, GITHUB_REPOSITORY_OWNER, GITHUB_RUN_ID, GH_TOKEN
# Requires: az, gh

set -u

suffix="${1:-}"
if [[ -z "$suffix" ]]; then
  echo "Usage: $0 <suffix>" >&2
  exit 2
fi
for v in GITHUB_REPOSITORY GITHUB_REPOSITORY_OWNER GITHUB_RUN_ID; do
  if [[ -z "${!v:-}" ]]; then
    echo "Required environment variable $v is not set" >&2
    exit 2
  fi
done

owner=$(printf %s "$GITHUB_REPOSITORY_OWNER" | tr "[:upper:]" "[:lower:]")
suffix=$(printf %s "$suffix" | tr "[:upper:]" "[:lower:]")
prefix="imagetest-wasdev-${owner}-"

if ! groups=$(az group list --query "[?starts_with(name,'IMAGETEST-WASDEV-')].name" -o tsv); then
  echo "Unable to list resource groups; nothing deleted" >&2
  exit 1
fi

for rgName in $groups; do
  lower=$(printf %s "$rgName" | tr "[:upper:]" "[:lower:]")
  # Must be <prefix><run_id>-<run_number>-<suffix>
  if [[ "$lower" != "$prefix"* ]]; then
    echo "Skipping $rgName: different owner or naming pattern"
    continue
  fi
  rest="${lower#"$prefix"}"
  if [[ ! "$rest" =~ ^([0-9]+)-([0-9]+)-${suffix}$ ]]; then
    echo "Skipping $rgName: does not match this workflow's naming pattern"
    continue
  fi
  runId="${BASH_REMATCH[1]}"

  if [[ "$runId" == "$GITHUB_RUN_ID" ]]; then
    echo "Skipping $rgName: belongs to the current run"
    continue
  fi

  if ! status=$(gh api "repos/${GITHUB_REPOSITORY}/actions/runs/${runId}" --jq .status 2>/dev/null) \
     || [[ -z "$status" ]]; then
    echo "Skipping $rgName: could not determine status of run $runId"
    continue
  fi
  if [[ "$status" != "completed" ]]; then
    echo "Skipping $rgName: run $runId is $status"
    continue
  fi

  echo "Deleting resource group $rgName left by completed run $runId"
  az group delete --name "$rgName" --yes --no-wait || echo "Failed to delete $rgName; continuing"
done
