---
name: verify-bcgrokbot
description: "Verify BCGrokBot (Business Central 29 per-tenant extension) end to end on this Linux box: al-runner unit tests, the BC Linux container (dev endpoint, test runner, APIs) and the BC web client at http://localhost:8080. Use when you need proof that a change works in a real BC: after publishing, before committing a feature, or when asked to verify/screenshot BCGrokBot."
---

# verify-bcgrokbot

BCGrokBot is an AL extension. Users reach it through the **BC web client**. Agents reach it through the **dev endpoint, APIs and test runner** of a local BC 29 container. Feature map: [`features/README.md`](features/README.md).

## Launch

```bash
scripts/bc-up.sh       # starts dockerd if needed, then the container (BC 29.0.54011.56009, web client on)
scripts/publish.sh     # build + publish "BCGrokBot" (forcesync)
```

- **Ready when** `bc-up.sh` prints `OK web client: http://localhost:8080/`. That takes about 1 min warm and about 2.5 min after a reset.
- **Broken test toolkit:** if it is detected, `bc-up.sh` auto-recovers with `down -v`, which wipes the DB. Then run `scripts/publish.sh` and the test app gets republished by `verify.sh integration`.
- **Teardown:** `scripts/bc-down.sh` (stop, keep data). Full reset: `scripts/bc-reset.sh`.

## Doctor

```bash
scripts/verify.sh doctor
```

Read-only. It requires all of the following:
- docker up;
- `bc` container healthy;
- BC version `29.0.54011.56009`;
- test runner API `200`;
- web client `200`;
- dev endpoint `200`.

Run it before the first drive, after anything surprising, and after every failed drive. If it fails: `scripts/bc-up.sh`, then doctor again.

## Drive

| What | Command | Proof |
|---|---|---|
| Unit tests (no container) | `scripts/verify.sh unit` | `unit.txt` has `Result: PASSED` |
| Integration tests in BC | `scripts/verify.sh integration` | `integration.txt` + `junit.xml`, `N total, N passed, 0 failed` |
| App installed in tenant | `scripts/verify.sh installed` | `extensions.json` has `BCGrokBot` with `isInstalled: true` |
| Everything | `scripts/verify.sh all` | all of the above |

### Web client (driven by the browser agent, not the shell)

- **URL:** `http://localhost:8080/`. It redirects to `/SignIn?ReturnUrl=%2F`. There is no `/BC/` path.
- **Sign in:** User name `BCRUNNER`, Password `Admin123!`, then choose **Sign In**. Expect the CRONUS International Ltd. role center.
- **Open a page directly:** `http://localhost:8080/?page=<id>`, e.g. `http://localhost:8080/?page=2500`. This needs a signed-in session; if you aren't signed in, the sign-in page appears first and continues to the page afterwards.
- Read the page ID and titles from [`features/`](features/README.md). Prefer page captions and action names over screen coordinates.
- **Screenshot standard:**
  - the browser address bar or the page title is visible;
  - the BC page caption is visible;
  - the row or result being proved is visible;
  - take one screenshot before the action and one after it.

## Evidence

- Shell evidence goes to `output/verify/<RUN_ID>/`: `doctor.txt`, `unit.txt`, `integration.txt`, `junit.xml`, `extensions.json`. `RUN_ID` defaults to a timestamp and can be set via `RUN_ID=...`.
- Browser screenshots go in the same run directory: `output/verify/<RUN_ID>/web-<feature>-<step>.png`.
- Proof standard:
  - exercise the real path: the dev endpoint publish, the BC test runner, the web client pages;
  - capture the action and the resulting state;
  - confirm side effects through a second view (e.g. the API listing after a publish);
  - mocks only through al-runner, which is unit level by design.
- `output/` is gitignored and cleanup never deletes it.

## Cleanup

- Shell drives start nothing long-lived except the container. Leave the container running: it is a shared instance and other agents use it.
- Remove test data you created in CRONUS, but keep the evidence.
- Never run `bc-reset.sh` / `down -v` while another agent may be driving.

## Isolation

There is **one** BC container (fixed ports 7045–7085, 8080, SQL 11433). Runs cannot be parallel. Do not drive while another run is publishing or testing. Check with `scripts/verify.sh doctor` and `sudo docker compose -f /workspace/MsDyn365Bc.On.Linux/docker-compose.yml ps`.

## Helpers

All in `scripts/` and executable:
- `verify.sh doctor|unit|integration|installed|all`
- `bc-up.sh`, `bc-down.sh`, `bc-reset.sh`
- `build.sh`, `publish.sh`, `test-dev.sh`, `test-integration.sh`

Settings (URLs, credentials, versions) are in `scripts/common.sh`.

## Maintenance

Keep the feature map honest with `/maintain-verification-skill` after features change.
