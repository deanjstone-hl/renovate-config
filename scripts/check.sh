#!/usr/bin/env bash
# The repo's local check, run by CI on every push to main: asserts the shared preset says what
# the owner decided (dashboard-only, no PRs unless a box is ticked), then validates it with
# Renovate's own validator. Run it before every push: bash scripts/check.sh
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
preset="$root/default.json"
renovate_version="44.224.2"

failures=0

# assert <description> <jq filter that must print true>
assert() {
  local description="$1" filter="$2" result
  result=$(jq -r "$filter" "$preset" 2>/dev/null || echo "jq-error")
  if [ "$result" = "true" ]; then
    echo "ok   $description"
  else
    echo "FAIL $description"
    failures=$((failures + 1))
  fi
}

if [ ! -f "$preset" ]; then
  echo "FAIL default.json is missing" >&2
  exit 1
fi

assert "the file is valid JSON with no comments" '. | type == "object"'
assert "the dashboard is enabled" '.dependencyDashboard == true'
assert "no branch or PR until a box is ticked (dependencyDashboardApproval)" '.dependencyDashboardApproval == true'
assert "prCreation is not approval (the docs forbid it beside dependencyDashboardApproval)" '(.prCreation // "immediate") != "approval"'
assert "a vulnerability fix also waits for a ticked box" '.vulnerabilityAlerts.dependencyDashboardApproval == true'
assert "OSV vulnerability alerts are on" '.osvVulnerabilityAlerts == true'
assert "OSV findings are listed on the dashboard" '.dependencyDashboardOSVVulnerabilitySummary == "unresolved"'
assert "the timezone is Australia/Sydney" '.timezone == "Australia/Sydney"'
assert "the dashboard carries type:chore, mode:afk and wave:later" '(.dependencyDashboardLabels // []) | sort == ["mode:afk", "type:chore", "wave:later"]'
assert "only npm, Python and GitHub Actions managers run" '(.enabledManagers // []) | sort == ["github-actions", "npm", "pep621", "pip_requirements", "pip_setup"]'
assert "npm minor and patch updates are grouped" 'any(.packageRules[]?; .matchManagers == ["npm"] and (.matchUpdateTypes | sort) == ["minor", "patch"] and (.groupName | type) == "string")'
assert "Python minor and patch updates are grouped" 'any(.packageRules[]?; (.matchManagers | sort) == ["pep621", "pip_requirements", "pip_setup"] and (.matchUpdateTypes | sort) == ["minor", "patch"] and (.groupName | type) == "string")'
assert "GitHub Actions minor and patch updates are grouped" 'any(.packageRules[]?; .matchManagers == ["github-actions"] and (.matchUpdateTypes | sort) == ["minor", "patch"] and (.groupName | type) == "string")'
assert "commits are chore(deps) so no update triggers a release" '.semanticCommits == "enabled" and .semanticCommitType == "chore" and .semanticCommitScope == "deps"'

if [ "$failures" -ne 0 ]; then
  echo "check: $failures assertion(s) failed" >&2
  exit 1
fi

# The validator treats any file not named like a repo config as global config, so it checks a
# copy named renovate.json: a preset has the shape of a repo config.
scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT
cp "$preset" "$scratch/renovate.json"
echo "validating default.json with renovate@$renovate_version"
npx --yes --package "renovate@$renovate_version" -- renovate-config-validator --strict "$scratch/renovate.json"

echo "check: pass"
