# Hello World greeting

Codeunit 50100 "Hello World" returns `Hello, World!` from `GetGreeting()`. It has no UI of its own; behaviour is proved by test codeunit 50150 "Hello World Test" in three places: al-runner, the container test runner, and the AL Test Tool page in the web client.

## Sub-features

- `hello-unit`: al-runner passes `GreetingIsHelloWorld`.
- `hello-container`: the BC test runner passes codeunit 50150 in the real service tier.
- `hello-ui`: the AL Test Tool page shows 50150 / `GreetingIsHelloWorld` with Result = Success.

## How to get to it (user POV)

- Web client: search "AL Test Tool", or open `http://localhost:8080/?page=130451` (Test Runner app, Worksheet page).

## Driving it with verify.sh and the web client

Preconditions:

- Baseline preconditions from the README.
- `scripts/verify.sh integration` has run at least once since the last DB reset. That publishes "BCGrokBot.Test".

- **Unit.** Run `RUN_ID=<id> scripts/verify.sh unit`. `unit.txt` shows `Tests: 1 passed 1 failed 0` and `Result: PASSED`.
- **Container.** Run `RUN_ID=<id> scripts/verify.sh integration`. `integration.txt` ends with `1 total, 1 passed, 0 failed`, and `junit.xml` contains `GreetingIsHelloWorld`.
- **Web, open tool.** Open `http://localhost:8080/?page=130451`. The page caption is "AL Test Tool". Screenshot `web-hello-world-before.png`.
- **Web, load tests.** If codeunit 50150 isn't listed, choose the action **Get Test Codeunits**, then **Select Test Codeunits**, and pick `50150 Hello World Test`. The lines show codeunit 50150 and function `GreetingIsHelloWorld`.
- **Web, run.** Choose **Run Tests** (or **Run All**). Afterwards the line for `GreetingIsHelloWorld` shows Result `Success`. Screenshot `web-hello-world-after.png` with the caption, the codeunit line and the Result column visible.

## Gotchas

- `run-tests.sh` uses its own test suite. In the AL Test Tool, the **Suite Name** field picks which suite is shown; use `DEFAULT` or whichever suite lists 50150.
- Action names can sit under the **Actions** / **Home** menu groups or the "…" overflow. Search by caption.
- A DB reset removes the test app. Re-run `scripts/verify.sh integration` before the web steps.
