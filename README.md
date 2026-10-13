# BCGrokBot

Business Central extension (`app/`, IDs 50100-50149) and its test app (`test/`, IDs 50150-50199).
Target: BC 29 (platform/application 29.0, runtime 18.0).

## Prerequisites
- .NET 8 SDK
- AL compiler: `dotnet tool install -g Microsoft.Dynamics.BusinessCentral.Development.Tools`

## Get symbols
    ./get-symbols.sh

## Build
    al compile /project:app /packagecachepath:app/.alpackages /out:app/output/app.app
    cp app/output/app.app "test/.alpackages/Flemming Bakkensen_BCGrokBot_1.0.0.0.app"
    al compile /project:test /packagecachepath:test/.alpackages /out:test/output/test.app

Tests run on a BC sandbox/container (Test Runner); they are only compiled locally.

## Dev scripts (`scripts/`)
All scripts are idempotent, set up `DOTNET_ROOT`/`PATH`, and stop on the first error.

| Script | What it does |
|---|---|
| `scripts/build.sh` | Fetches symbols and ALCops if missing, compiles `app`, copies it into `test/.alpackages`, compiles `test`. Code analysis is on; any warning fails the build (`STRICT=0` to allow warnings). |
| `scripts/test-dev.sh` | Fast unit tests with al-runner (`/workspace/alrunner-bc29`), no container. Exits nonzero on failure. |
| `scripts/bc-up.sh` | Starts dockerd if needed, then the BC 29 container (`/workspace/MsDyn365Bc.On.Linux`) with the web client. Waits for healthy. If the test toolkit is broken, it recovers with `down -v` + `up`, which resets the database. |
| `scripts/bc-down.sh` | Stops the containers and keeps the data. |
| `scripts/bc-reset.sh` | Wipes the database (`down -v`) and starts fresh. |
| `scripts/publish.sh` | Builds, then publishes the main app to the dev endpoint (forcesync). |
| `scripts/test-integration.sh` | Builds, publishes, and runs test codeunits 50150..50199 in the container. JUnit output goes to `output/junit.xml`. |
| `scripts/setup-web-demo.sh` | Dev container only. Creates the non-SUPER web user SALESUSER1 / Sales123! and the salesperson-assignment demo data. |
| `scripts/setup-project-demo.sh` | Dev container only. Recreates the BGB-P-* project hierarchy demo. |
| `scripts/setup-project-version-demo.sh` | Dev container only. Ensures the BGB-V-* hierarchy has two archive runs, with project usage posted between them. |

Web client: http://localhost:8080/ (BCRUNNER / Admin123!). Dev endpoint: http://localhost:7049/BC/dev.

## Project version compare

Flemming archives projects about once a month. **Archive Hierarchy** (Project Card and Project List, top-level projects only) runs the standard project archive for the top project and every subproject under one archive run. A normal single-project archive still works and gets its own run. Each archive also stores a snapshot: the 32 LCY figures from project statistics, profit and margin, parent project, level and hierarchy totals, plus per-task usage and invoiced cost and price split by Resource, Item and G/L Account. Budget and billable per type come from the archived planning lines. Archives taken before this extension have no snapshot; compare falls back to the project task archive totals and shows **No breakdown**.

**Project Version Compare** sets version A against version B, or against **Current** (everything posted up to now, no date filter). Rows are tasks or the projects in the tree, plus a total. **Project Version Trend** is one row per run or version, oldest first, then current. The Excel report **Project Version Trend** is the same story as a workbook with pivot tables.

### Recurring archive (job queue)

The app does not create a job queue entry or a schedule. In the job queue, create an entry that runs codeunit **50112 "BGB Archive Hierarchies JQ"** (`BGB Archive Hierarchies JQ`). It archives every open top-level project and that project's subprojects, one archive run per top-level project. **Parameter String** is an optional filter on the project number, for example `BGB-V-*` or `BGB-V-TOP|BGB-V-OTHER`. Leave it blank to include every open top-level project. The job queue user needs permission set BCGrokBot and permission to archive projects.

## Code analysis
- Microsoft: CodeCop, UICop, PerTenantExtensionCop. AppSourceCop is off because this is a PTE, not an AppSource app.
- Community: [ALCops](https://www.nuget.org/packages/ALCops.Analyzers) 1.3.1 (ApplicationCop, DocumentationCop, FormattingCop, LinterCop, PlatformCop, TestAutomationCop). `build.sh` downloads the net8.0 DLLs into `.analyzers/`, which is gitignored.
- Rule severities go in `BCGrokBot.ruleset.json`, which includes `rulesets/CodeCop.ruleset.json` and `rulesets/PTECop.ruleset.json` and `rulesets/ALCops.ruleset.json` (CodeCop/PTECop copied from microsoft/BCApps `releases/29.x`, with first-party exemptions re-enabled for a PTE). VS Code uses the same analyzers through `app|test/.vscode/settings.json`. In VS Code, `${analyzerFolder}` must contain the ALCops DLLs; alternatively, install the ALCops VS Code extension.

## Agents, references and verification
- `AGENTS.md`: conventions, script guide, BCApps lookup recipe, the rule-to-enforcement table, the per-feature workflow.
- `scripts/ref-sync.sh`: read-only BCApps `releases/29.x` W1 reference at `/workspace/ref/BCApps`.
- `scripts/bcq-sync.sh`: pinned BCQuality (`quality/BCQUALITY_PIN`) at `/workspace/ref/BCQuality`, plus our custom rules from `quality/bcquality-custom/`.
- `.cursor/skills/bc-review/`: BCQuality review (AppSource, breaking-change and agent reviews disabled).
- `.cursor/skills/verify-bcgrokbot/`: verification skill and feature map. `scripts/verify.sh all` writes evidence to `output/verify/<RUN_ID>/`.

## Continuous deployment (sandbox)

On every push to `main`, after **Build and unit test** passes, the `deploy-sandbox` job (GitHub Environment `sandbox`) publishes the **main app only** to a BC SaaS sandbox. It uses the Automation API via `scripts/deploy-saas.sh`. CI sets the version to `1.0.<run number>.<run attempt>` (`scripts/set-version.sh`), so each deploy is newer than the last. Locally the version stays `1.0.0.0`. The deploy job is skipped on pull requests.

Local use: `scripts/deploy-saas.sh --dry-run` checks the package and needs no secrets. A real deploy needs `BC_TENANT_ID`, `BC_ENVIRONMENT`, `BC_CLIENT_ID` and `BC_CLIENT_SECRET` in the environment.

### One-time setup (Entra + BC + GitHub)

1. **Entra app registration** in tenant `2988834f-4330-4795-9445-5a155672e1a7`. Create it single-tenant and add a client secret.
   - Under API permissions, add **Dynamics 365 Business Central → Application permissions → `API.ReadWrite.All` and `Automation.ReadWrite.All`**.
   - Then choose **Grant admin consent**.
   - Under Authentication → Web, add the redirect URI **`https://businesscentral.dynamics.com/OAuthLanding.htm`**. Without it, **Grant Consent** on BC page 9860 fails.
2. **In the BC sandbox**, open page *Microsoft Entra Applications* (`?page=9860`) and create a new entry with the app's Client ID.
   - Set State = Enabled.
   - Add permission sets **`EXTEN. MGT. - ADMIN`** and **`D365 AUTOMATION`**.
   - Choose **Grant Consent**.
3. **GitHub, environment `sandbox`** (Settings → Environments; it's auto-created on the first deploy if missing):
   - secrets `BC_CLIENT_ID` and `BC_CLIENT_SECRET`;
   - variables `BC_TENANT_ID` (`2988834f-4330-4795-9445-5a155672e1a7`) and `BC_ENVIRONMENT` (the sandbox name, currently `UAT`).
   - Repository-level secrets and variables also work. Optionally add required reviewers or a branch restriction (`main`) on the environment.

The job fails when the token, upload or deployment fails, or after 30 min without a final status. On failure, check *Extension Deployment Status* in the sandbox.
