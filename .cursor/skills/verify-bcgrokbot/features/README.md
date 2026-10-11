# BCGrokBot verification map

The maintained source for verifying user-visible behaviour of BCGrokBot. Read this first, then use the matching feature file as the recipe.

## Baseline preconditions

- `scripts/verify.sh doctor` passes (container healthy, BC 29.0.54011.56009, test runner API and web client 200).
- `scripts/publish.sh` has published the current build. `scripts/verify.sh installed` shows `BCGrokBot` installed.
- The web client is signed in as `BCRUNNER` / `Admin123!` at `http://localhost:8080/`, company CRONUS International Ltd.
- Nobody else is driving the container.

## Driving conventions

- Shell steps go through `scripts/verify.sh`. Web steps are done by the browser agent.
- Open pages by URL `http://localhost:8080/?page=<id>`. Locate controls by caption and action name.
- Start every recipe from the baseline state.

## Proof and skip reporting

- Shell proof is the `output/verify/<RUN_ID>/` file named in the recipe.
- Web proof is a screenshot before and after the action, showing the page caption and the proving row, saved as `output/verify/<RUN_ID>/web-<feature>-<step>.png`.
- Report unreachable paths with the attempted step and the unmet precondition. Never count a different path as verified.

## Feature entry contract

Each feature file has an H1 title and a one-paragraph description, then exactly these H2 sections: `Sub-features`, `How to get to it (user POV)`, `Driving it with verify.sh and the web client`, `Gotchas`.

## Features

- [App installation](./app-installation.md): BCGrokBot and its tests are installed in the tenant (Extension Management).
- [Hello World greeting](./hello-world.md): codeunit 50100 returns `Hello, World!`, proved by al-runner, the container test runner, and the AL Test Tool page.
