# Project hierarchy

Projects (Job) get a "Parent Project No." (unlimited depth; self-parent and cycles are rejected; a project with subprojects can't be deleted). The Project Card and Project List show a "Hierarchy Totals" FactBox: the standard Project Details figures (LCY) summed over the project and all its descendants. The Project Card also shows a "Subprojects" FactBox. "Create Hierarchy Sales Invoices" (report 50100), available only on top-level projects, creates one sales invoice per bill-to customer and currency across the whole hierarchy; sell-to may differ inside one invoice. Header sell-to comes from the top project when it's in the group, else from the highest project billing that customer; payment terms/method, External Document No. and Your Reference always come from the top project. Standard "Create Project Sales Invoice" (report 1093) and Create Sales Invoice from planning lines are blocked on any project in a hierarchy.

## Sub-features

- `ph-unit`: al-runner codeunit 50157 (parent validation, cycles, BFS descendants, membership, billing key).
- `ph-container`: codeunit 50158 (invoicing on CRONUS data, header rules, standard invoicing blocks, delete guard, totals).
- `ph-web-tree`: BGB-P-TOP card shows Subprojects BGB-P-C1, BGB-P-C2 and Hierarchy Totals Billable Price Total 1,500.
- `ph-web-cycle`: setting Parent Project No. of BGB-P-TOP to BGB-P-G1 fails with the cycle error.
- `ph-web-block-std`: "Create Project Sales Invoice" on BGB-P-C2 fails pointing to the hierarchy action on BGB-P-TOP.
- `ph-web-child-disabled`: "Create Hierarchy Sales Invoices" is disabled on BGB-P-C2.
- `ph-web-invoice`: running it on BGB-P-TOP creates 3 invoices: BGB-PC-A/LCY (TOP + C2, sell-to BGB-PC-A), BGB-PC-B/LCY (C1 + G2, sell-to BGB-PC-B), BGB-PC-A/EUR (G1). Payment terms and External Document No. PO-TOP-4711 on all three.

## How to get to it (user POV)

- Projects list: `http://localhost:8080/?page=89`; card for BGB-P-TOP: `http://localhost:8080/?page=88&filter=%27No.%27%20IS%20%27BGB-P-TOP%27`.
- Sales Invoices: `http://localhost:8080/?page=9301`, filter Bill-to/Sell-to on `BGB-PC-*`.

## Driving it with verify.sh and the web client

Preconditions:

- Baseline preconditions from the README.
- `scripts/test-integration.sh` has published both apps. Then run `scripts/setup-project-demo.sh` (idempotent: deletes open BGB-PC-A/B invoices and the BGB-P-* tree, then recreates it). Each project has task 100 with one billable resource line: TOP 1×100, C1 2×100, C2 3×100, G1 4×100 (invoice currency EUR), G2 5×100.

Steps:

- **Unit / container.** `scripts/verify.sh unit` and `scripts/verify.sh integration`, both 0 failed.
- **ph-web-tree.** Open project BGB-P-TOP. Screenshot the Parent Project No. field (blank), Subprojects FactBox and Hierarchy Totals (Billable Price Total 1,500.00). Open BGB-P-C2: Hierarchy Totals Billable Total 1,200.00.
- **ph-web-cycle.** On BGB-P-TOP set Parent Project No. = BGB-P-G1 → error "...because BGB-P-G1 is already a subproject of BGB-P-TOP." Screenshot, then Esc/undo.
- **ph-web-block-std / ph-web-child-disabled.** On BGB-P-C2: "Create Hierarchy Sales Invoices" is greyed out; "Create Project Sales Invoice" → OK on the request page → error "Project BGB-P-C2 is part of a project hierarchy. Use the Create Hierarchy Sales Invoices action on top-level project BGB-P-TOP instead."
- **ph-web-invoice.** On BGB-P-TOP choose "Create Hierarchy Sales Invoices", OK → "3 sales invoice(s) were created." Open `?page=9301` and screenshot the three invoices, then each card's lines (Project No. per line) and Payment Terms / External Document No.

## Gotchas

- Re-running invoicing finds nothing ("There is nothing to invoice...") until `setup-project-demo.sh` is run again.
- The FactBoxes are below the standard ones; scroll the FactBox pane.
- EUR must have an exchange rate on the work date (CRONUS has one).
