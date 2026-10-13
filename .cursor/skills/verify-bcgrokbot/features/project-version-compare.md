# Project version compare

Archive Hierarchy, on a top-level project, stores the project and every subproject with the standard project archive under one archive run. A single-project archive still gets its own run. OnAfterStoreJob writes a project snapshot (32 LCY statistics figures, profit and margin, parent, level, hierarchy totals, run id, user, time) and a task snapshot with usage and invoiced cost and price split by Resource, Item and G/L, plus budget and billable per type from the archived planning lines. Snapshots follow project archive delete and rename. A snapshot taken while the project is being deleted is marked, because usage may already be incomplete. Archives without a snapshot compare from the project task archive totals and are flagged no breakdown. Current means everything posted up to now, with no date filter.

Codeunit 50112 "BGB Archive Hierarchies JQ" is for the job queue. Parameter String is an optional project-number filter. It does not create a job queue entry.

## Sub-features

- `pv-unit`: al-runner codeunit 50162 (difference and percent including a zero base, run grouping, fallback, trend order, per-type split, top-level selection, snapshot move and delete).
- `pv-container`: codeunit 50163 (archive, post usage and invoice, archive again and match statistics; one hierarchy run over five projects; auto-archive when Jobs Setup is Always; delete and rename; compare page; xlsx report; job queue).
- `pv-web`: after `scripts/setup-project-version-demo.sh`, project BGB-V-TOP has two archive runs and posted usage between them. Project Version Compare and Project Version Trend show the two versions and current.

## How to get to it (user POV)

- Projects: `http://localhost:8080/?page=89`. Card for BGB-V-TOP: `http://localhost:8080/?page=88&filter=%27No.%27%20IS%20%27BGB-V-TOP%27`.
- Project Version Compare: search, or the action on the project card.
- Project Version Trend: search, or the action on the project card. Project Version Trend (Excel) is the report.

## Driving it with verify.sh and the web client

Preconditions:

- Baseline preconditions from the README.
- `scripts/test-integration.sh` has published both apps. Then `scripts/setup-project-version-demo.sh`.

Steps:

- **Unit / container.** `scripts/verify.sh unit` and `scripts/verify.sh integration`, both 0 failed.
- **pv-web.** Open BGB-V-TOP. Project Version Compare, version 1 against version 2: usage on version 2 is higher. Project Version Trend lists two versions and Current. No breakdown is false on these rows.

## Gotchas

- Archive Hierarchy is disabled on a project that has a parent.
- Re-running the demo does not delete posted usage. It only adds another archive run when fewer than two exist.
- A snapshot marked During Project Delete can show usage that is short of the ledger, because standard delete moves or blocks ledger entries before the archive.
