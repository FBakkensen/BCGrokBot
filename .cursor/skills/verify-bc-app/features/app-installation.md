# App installation

After a publish, "My BC App" (publisher Flemming Bakkensen, 1.0.0.0) is installed in the CRONUS tenant and listed in Extension Management. The test app "My BC App Tests" is installed after an integration run.

## Sub-features

- `install-api`: the automation API lists the extension as installed.
- `install-ui`: Extension Management shows the extension as installed.

## How to get to it (user POV)

- Web client: search "Extension Management", or open `http://localhost:8080/?page=2500`.

## Driving it with verify.sh and the web client

Preconditions:

- Baseline preconditions from the README.

- **Publish.** Run `scripts/publish.sh`. Output ends with `OK published (HTTP 200)`.
- **API check.** Run `RUN_ID=<id> scripts/verify.sh installed`. It prints `My BC App 1.0 installed=True`, and `output/verify/<id>/extensions.json` contains it.
- **Web check.** Open `http://localhost:8080/?page=2500`. The page caption is "Extension Management". In the list, the row Name = `My BC App`, Publisher = `Flemming Bakkensen`, Version `v. 1.0.0.0`, Is Installed checked (or "Installed" status). Screenshot `web-app-installation-list.png`.

## Gotchas

- A plain `docker compose down`/`up` can leave the test toolkit broken. `bc-up.sh` then resets the DB, so the extension disappears until you run `publish.sh` again.
- Extension Management may filter to installed extensions by default. If the row isn't visible, clear the filter and search for "My BC App".
