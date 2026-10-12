# Salesperson assignment

Only the user linked to the bill-to customer's salesperson (User Setup."Salespers./Purch. Code" = Customer."Salesperson Code") may create or release Quotes, Orders, Invoices and Blanket Orders. Customers without a salesperson can't be used on these documents at all. Credit Memos and Return Orders are exempt. Changing Customer."Salesperson Code" (including on new customers) or the User Setup link requires permission set BGB SALESP ADMIN. BGB SALES BYPASS (integration/job queue users) and SUPER skip the document rule. Page 50100 "Salesperson Assignment Go-Live Check" lists customers without a salesperson, salespersons not linked to a user, and open in-scope documents that would fail.

## Sub-features

- `sa-unit`: al-runner codeunit 50151 (rule logic, scope, go-live list).
- `sa-container`: codeunit 50152 runs in the container with Permissions Mock (D365 BUS FULL ACCESS + BCGrokBot, optionally + admin/bypass): validate, insert, modify, release, credit memo exemption, bypass, admin checks.
- `sa-web-deny-other`: SALESUSER1 can't create an order for BGB-C-OTHER.
- `sa-web-deny-nosp`: SALESUSER1 can't create an order for BGB-C-NOSP.
- `sa-web-allow-own`: SALESUSER1 creates and releases an order for BGB-C-OWN.
- `sa-web-admin`: SALESUSER1 can't change the salesperson on a customer.
- `sa-web-golive`: page 50100 lists BGB-C-NOSP and its open order.

## How to get to it (user POV)

- Sales Orders: `http://localhost:8080/?page=9305`, then **New**.
- Customers: `http://localhost:8080/?page=22`.
- Go-live check: search "Salesperson Assignment Go-Live Check", or `http://localhost:8080/?page=50100`.

## Driving it with verify.sh and the web client

Preconditions:

- Baseline preconditions from the README.
- `scripts/test-integration.sh` has published the main and test apps. Then run `scripts/setup-web-demo.sh`. It's idempotent. It creates:
  - user `SALESUSER1` / `Sales123!`, with D365 BASIC, D365 BUS FULL ACCESS and BCGrokBot only (no SUPER, no admin, no bypass);
  - salesperson BGB-SP1, linked to SALESUSER1, and salesperson BGB-SP2, not linked;
  - customers BGB-C-OWN (BGB-SP1), BGB-C-OTHER (BGB-SP2) and BGB-C-NOSP (no salesperson);
  - one open order for BGB-C-NOSP. Its number is printed by the script.

Steps:

- **Unit / container.** Run `scripts/verify.sh unit` and `scripts/verify.sh integration`. Both report 0 failed.
- **Sign in as SALESUSER1.** Use a private window, or sign out of BCRUNNER first.
- **sa-web-deny-other.** Open `?page=9305`, choose **New**, and set Customer Name/No. to `BGB-C-OTHER`. Expected error: "Only the user assigned to salesperson BGB-SP2 can create or release sales documents for bill-to customer BGB-C-OTHER. You are linked to BGB-SP1." Screenshot `web-salesperson-assignment-deny-other.png`.
- **sa-web-deny-nosp.** Do the same with `BGB-C-NOSP`. Expected error: "You cannot create or release a sales document for bill-to customer BGB-C-NOSP because the customer has no salesperson. ..." Screenshot `...-deny-nosp.png`. Discard the empty order the client may leave behind.
- **sa-web-allow-own.** Do the same with `BGB-C-OWN`. It's accepted. Add a line: Type Item, No. `1896-S`, Quantity 1. Choose **Release**. Status becomes Released. Screenshot `...-allow-own.png`.
- **sa-web-admin.** Open `?page=22`, then customer BGB-C-OWN, and change Salesperson Code to `BGB-SP2`. Expected error: "You do not have permission to change the salesperson assignment. The BGB SALESP ADMIN permission set is required." Screenshot `...-admin.png`.
- **sa-web-golive.** Open `?page=50100` (as SALESUSER1 or BCRUNNER). There are rows "Customer without salesperson" for BGB-C-NOSP and "Open document would fail" for the BGB-C-NOSP order. Many CRONUS customers show up too, because CRONUS salespersons aren't linked to users. Screenshot `...-golive.png`.

## Gotchas

- BCRUNNER is SUPER, so it bypasses every check. Always verify the deny paths as SALESUSER1.
- A user inserted by SQL can take a few seconds to be accepted by the service tier. The script waits for this.
- The test app registers OData web service `BGBWebDemo` (install/upgrade codeunit). If the setup script reports a 404, re-run `scripts/test-integration.sh`.
