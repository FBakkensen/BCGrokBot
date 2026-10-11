---
name: bc-review
description: "Review BCGrokBot AL code (whole app, a diff, a branch, or one file) against Microsoft BCQuality knowledge, with AppSource, breaking-change and agent reviews disabled because BCGrokBot is a per-tenant extension. Use for /bc-review, 'review this AL', or before /interrogate on any AL change."
---

# bc-review

A thin wrapper around BCQuality's `al-code-review` adapter, configured for this repo. It does not change source files. Its output is BCQuality's findings report.

## Setup (idempotent, run first)

```bash
scripts/bcq-sync.sh
```

This script:
- checks out BCQuality at the commit pinned in `quality/BCQUALITY_PIN`, in `/workspace/ref/BCQuality`;
- copies our rules from `quality/bcquality-custom/` into its `custom/` layer;
- rebuilds `knowledge-index.json` with `pwsh` (installed as a dotnet global tool).

Edit custom rules only in `quality/bcquality-custom/`. Never edit them in `/workspace/ref/BCQuality`.

## Configuration for BCGrokBot

| Setting | Value | Why |
|---|---|---|
| `PLUGIN_ROOT` | `/workspace/ref/BCQuality` | pinned clone |
| `enabled-layers` | `microsoft,custom` | the `community` layer only holds `agents` and `appsource` content, which don't apply here |
| `disabled-skills` | `microsoft/skills/review/al-appsource-review.md,microsoft/skills/review/al-breaking-changes-review.md,community/skills/review/al-agents-review.md` | this is a PTE, not an AppSource app; it publishes no events or APIs that others depend on; it contains no Copilot agents |
| `bc-version` | `29` | `app.json` platform/application 29.0 |
| `countries` | `[w1]` | W1 only |
| `technologies` | `[al]` | |

If BCGrokBot later exposes events or APIs that other extensions consume, re-enable `al-breaking-changes-review`.

## Execute

1. Run setup.
2. Read `/workspace/ref/BCQuality/skills/al-code-review/SKILL.md` and follow it exactly, with `PLUGIN_ROOT=/workspace/ref/BCQuality` and the configuration above as the task context. Pass `enabled-layers` and `disabled-skills` explicitly, the same way the adapter would read them from `BCQUALITY_ENABLED_LAYERS` / `BCQUALITY_DISABLED_SKILLS`.
3. Choose the input:
   - whole app: `folder-path` = `/workspace/BCGrokBot/app` (and/or `/workspace/BCGrokBot/test`);
   - a change: `pr-diff` = `git -C /workspace/BCGrokBot diff main...HEAD -- '*.al' app.json`;
   - one file: `file-path`.
4. Copy the user's request verbatim into `goal`.
5. Save the returned findings report unchanged to `output/review/<date>-<scope>.json` (or `.md`), then summarise it for the user.

## Reading results

- `completed` with no findings is clean only for the reviews that were dispatched.
- `partial` or `failed` is NOT clean. Say so explicitly.
- Findings are advice from an LLM applying curated rules, not analyzer output. Fix the real ones, explain any you dismiss, and when a finding keeps coming back, encode it via `/correct`: a ruleset entry, a test, or a custom rule in `quality/bcquality-custom/knowledge/<domain>/`.
- The build (`scripts/build.sh`, analyzers) and tests stay the hard gates. This review never replaces them.
