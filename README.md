# renovate-config

The shared [Renovate](https://docs.renovatebot.com/) preset for every repo of `deanjstone` and `deanjstone-hl`. It runs Renovate in **dashboard-only** mode: each repo gets one *Dependency Dashboard* issue listing every update, and no branch or pull request opens until someone ticks its box.

## Use it

Put this `renovate.json` at the root of a repo:

```json
{
  "extends": ["github>deanjstone-hl/renovate-config"]
}
```

The preset is `default.json` in this repo. It lives in a public repo because the Mend Renovate app reads a preset with the token of the account that owns the repo being scanned, and a private preset repo is not reliably readable from the other account.

## What it does

- **Dashboard only.** `dependencyDashboard` and `dependencyDashboardApproval` are on, so a pending update waits as an unticked box. A vulnerability fix waits too (`vulnerabilityAlerts.dependencyDashboardApproval`).
- **`prCreation` is left at its default on purpose.** Renovate's docs forbid `prCreation: "approval"` beside `dependencyDashboardApproval: true`. The approval option alone already stops every branch and PR.
- **Managers.** npm (including pnpm), Python (`pip_requirements`, `pip_setup`, `pep621` for `pyproject.toml` and uv) and GitHub Actions. Nothing else runs.
- **Grouping.** Minor and patch updates are one group per ecosystem. A major update is its own box.
- **Vulnerabilities.** `osvVulnerabilityAlerts` is on and unresolved findings are listed on the dashboard.
- **Dashboard labels.** `type:chore`, `mode:afk`, `wave:later`.
- **Commits.** `chore(deps): ...`, so a ticked update never triggers a release.
- **Timezone.** `Australia/Sydney`.

## Check

```bash
bash scripts/check.sh
```

It asserts each decision above with `jq`, then validates the file with `renovate-config-validator --strict` from a pinned `renovate` release. CI runs it on every push to `main`.

## Install (owner step)

The preset does nothing until the Mend Renovate GitHub app is installed on each account. See the Resolution on [argus-config#1660](https://github.com/deanjstone-hl/argus-config/issues/1660) for the clicks.
