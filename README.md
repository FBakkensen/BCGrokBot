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

Web client: http://localhost:8080/ (BCRUNNER / Admin123!). Dev endpoint: http://localhost:7049/BC/dev.

## Code analysis
- Microsoft: CodeCop, UICop, PerTenantExtensionCop. AppSourceCop is off because this is a PTE, not an AppSource app.
- Community: [ALCops](https://www.nuget.org/packages/ALCops.Analyzers) 1.3.1 (ApplicationCop, DocumentationCop, FormattingCop, LinterCop, PlatformCop, TestAutomationCop). `build.sh` downloads the net8.0 DLLs into `.analyzers/`, which is gitignored.
- Rule severities go in `BCGrokBot.ruleset.json`, which includes `rulesets/CodeCop.ruleset.json` and `rulesets/PTECop.ruleset.json` (copied from microsoft/BCApps `releases/29.x`, with first-party exemptions re-enabled for a PTE). VS Code uses the same analyzers through `app|test/.vscode/settings.json`. In VS Code, `${analyzerFolder}` must contain the ALCops DLLs; alternatively, install the ALCops VS Code extension.

## Agents, references and verification
- `AGENTS.md`: conventions, script guide, BCApps lookup recipe, the rule-to-enforcement table, the per-feature workflow.
- `scripts/ref-sync.sh`: read-only BCApps `releases/29.x` W1 reference at `/workspace/ref/BCApps`.
- `scripts/bcq-sync.sh`: pinned BCQuality (`quality/BCQUALITY_PIN`) at `/workspace/ref/BCQuality`, plus our custom rules from `quality/bcquality-custom/`.
- `.cursor/skills/bc-review/`: BCQuality review (AppSource, breaking-change and agent reviews disabled).
- `.cursor/skills/verify-bcgrokbot/`: verification skill and feature map. `scripts/verify.sh all` writes evidence to `output/verify/<RUN_ID>/`.
