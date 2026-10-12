# AGENTS.md: BCGrokBot

Business Central 29 **per-tenant extension** (PTE), W1. You are one of many agents. You see only the files you open, so follow this file and the enforced checks; don't copy whatever happens to be nearby.

## Layout and conventions

| Item | Main app `app/` | Test app `test/` |
|---|---|---|
| Name / publisher | BCGrokBot / Flemming Bakkensen | BCGrokBot.Test / Flemming Bakkensen |
| Object IDs | 50100–50149 | 50150–50199 |
| Namespace | `FlemmingBakkensen.BCGrokBot[.<Area>]` | `FlemmingBakkensen.BCGrokBot.Test[.<Area>]` |
| Target | platform/application 29.0.0.0, runtime 18.0 | same, depends on main + Library Assert + Test Runner |

- **File names:** `<ObjectName>.<ObjectType>.al` (e.g. `HelloWorld.Codeunit.al`), under `src/` (sub-folders per area).
- **Permissions:** every object goes into the app's permission set (`BCGrokBot`, 50100 / `BCGrokBot.Test`, 50150).
- **Docs and captions:** public objects/procedures get `///` XML doc comments. Captions that can be translated get `MaxLength` where a limit applies.
- **Tests:** `Subtype = Test` codeunits with `// [SCENARIO]`, `// [GIVEN]`, `// [WHEN]`, `// [THEN]` comments. Use `Codeunit "Library Assert"` (namespace `System.TestLibraries.Utilities`). Test data is random and complete (BCQuality testing rules). For an `asserterror`, check the expected error text and code.
- **Never edit:** `.alpackages/`, `output/`, `.analyzers/` (all generated), or anything under `/workspace/ref/` (read-only mirrors).

## Scripts (`scripts/`, idempotent, settings in `scripts/common.sh`)

| Need | Run |
|---|---|
| Compile both apps, analyzers on, warnings fail | `scripts/build.sh` (`STRICT=0` only for local exploration) |
| Fast unit tests (no BC) | `scripts/test-dev.sh` |
| Start / stop / wipe the BC container | `scripts/bc-up.sh` / `scripts/bc-down.sh` / `scripts/bc-reset.sh` |
| Publish main app to the container | `scripts/publish.sh` |
| Remove our apps from the container | `scripts/unpublish.sh ["Name" ...]` |
| Run tests inside real BC | `scripts/test-integration.sh` |
| Web verification user + demo data | `scripts/setup-web-demo.sh` (SALESUSER1 / Sales123!) |
| Proof with evidence (`output/verify/<RUN_ID>/`) | `scripts/verify.sh doctor\|unit\|integration\|installed\|all` |
| Update the BCApps reference | `scripts/ref-sync.sh` |
| Update BCQuality and our custom rules | `scripts/bcq-sync.sh` |

CI (`.github/workflows/ci.yml`, check **Build and unit test**) runs `build.sh` (STRICT) and al-runner tests on every PR and push to main. Container integration tests (`test-integration.sh`, `verify.sh integration`) are **not** in CI: run them locally before merging behaviour changes.

There is one shared BC container (web client `http://localhost:8080/`, `BCRUNNER` / `Admin123!`). Don't reset it while another agent is using it.

## Looking up Microsoft code (BCApps, `releases/29.x`, W1)

Read-only sparse checkout at `/workspace/ref/BCApps` (refresh with `scripts/ref-sync.sh`):

- Base App: `src/Layers/W1/BaseApp/`
- Microsoft tests (best test-pattern examples): `src/Layers/W1/Tests/`
- System App: `src/System Application/{App,Test,Test Library}/`
- Business Foundation: `src/Business Foundation/`
- Microsoft rulesets: `src/rulesets/`

```bash
R=/workspace/ref/BCApps/src
rg -n 'procedure OnBeforePostSalesDoc\(' "$R/Layers/W1/BaseApp"                 # event signature
rg -n -A3 '\[IntegrationEvent' "$R/Layers/W1/BaseApp/Sales/Posting/SalesPost.Codeunit.al" | head
rg -l '^table 18 ' "$R/Layers/W1/BaseApp"                                          # object by ID
rg -l 'codeunit 1 ' "$R/System Application/App" ; rg -n 'LibrarySales\.' "$R/Layers/W1/Tests" | head
```

- Subscribe to events with signatures copied from this checkout, never from memory.
- Main is BC 30. Only this branch matches our BC 29 symbols.

## Code guidelines (from Microsoft's BCApps `code-guidelines.md`)

- **Smallest diff that does the job:** add rather than change, keep changes local, stay compatible.
- **Don't** reformat, reorder, rename, move files, or refactor unrelated code. Don't change line endings, encodings, or whitespace style.
- Match the existing style, and explain non-obvious decisions in the commit or PR text.
- Extend Microsoft code through events, table/page extensions and interfaces. Prefer existing events (BCQuality `events/prefer-reusing-or-extending-existing-events`).

## Rules and what enforces them (`/correct` table)

| Rule | Enforced by |
|---|---|
| No compiler/analyzer warnings | `scripts/build.sh` (STRICT=1) |
| Microsoft CodeCop rules (ruleset adapted from BCApps) | `rulesets/CodeCop.ruleset.json` via `BCGrokBot.ruleset.json`, errors fail the build |
| PTE rules incl. ID range, no reserved namespaces, no test assertions in app | `rulesets/PTECop.ruleset.json` (Microsoft ruleset with first-party exemptions re-enabled) |
| Every object has a namespace | CodeCop AA0247 (error) |
| Namespace is `FlemmingBakkensen.BCGrokBot*` | BCQuality custom rule `quality/bcquality-custom/knowledge/style/use-the-bcgrokbot-namespace.md` (review only; PTE0021 blocks Microsoft/System namespaces) |
| Every object in a permission set | ALCops AC0010 |
| Caption length limits | ALCops AC0009 |
| Public API documented | ALCops DC0004/DC0007/DC0009 (Warning → fails STRICT build) |
| Every object sets `Access` explicitly (default to Internal) | ALCops PC0006 (opt-in, Warning) |
| ALCops severities for a PTE (126 rules, each justified) | `rulesets/ALCops.ruleset.json` via `BCGrokBot.ruleset.json` |
| Behaviour proven by tests | `scripts/test-dev.sh` + `scripts/verify.sh integration` |
| AL review against Microsoft guidance | `/bc-review` (BCQuality; advisory, not a gate) |

When the operator corrects you: fix the mistake, add or adjust a row here, and enforce it at the highest level that works (structure → analyzer/ruleset → test → BCQuality custom rule → this file).

## Per-feature workflow

1. **Design:** `/architect` for anything non-trivial. Ground it in BCApps sources first (events, tables you touch).
2. **Test first:** write the test codeunit in `test/`, then iterate with `scripts/test-dev.sh`.
3. **Build:** `scripts/build.sh`, which must be clean.
4. **Review:** `/bc-review` on the diff. Fix real findings and justify the dismissed ones.
5. **Blast radius:** `/blast-radius` when touching posting, events, schema or permissions. Prove the key fact with al-runner or the container.
6. **Verify:** `/verify-bcgrokbot` (`scripts/verify.sh all`, plus web client screenshots via the browser agent). Add or update the feature file in `.cursor/skills/verify-bcgrokbot/features/`.
7. **Adversarial review:** `/interrogate` on the branch.
8. **Commit:** one logical change per commit. After repeated corrections, `/correct`.

## Test conventions

- Container-only test codeunits (Permissions Mock, CRONUS data) are listed in `CONTAINER_ONLY_CODEUNITS` in `scripts/test-dev.sh`, so al-runner skips them. al-runner does no permission enforcement.
- Permission tests set `TestPermissions = Disabled` and lower the context explicitly with `Permissions Mock` (`Set('D365 BUS FULL ACCESS')` + `Assign(...)`). Do all setup before the first `Set`. Don't toggle Stop/Set inside a test.
- Unique fixture keys use `CreateGuid()`, not `Any`. `Any` repeats values across tests under codeunit isolation.
