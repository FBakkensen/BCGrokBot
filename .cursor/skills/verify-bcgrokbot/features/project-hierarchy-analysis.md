# Project Hierarchy Analysis (report 50101, Excel layout)

Setup: `scripts/setup-project-demo.sh` (demo tree BGB-P-TOP <- C1, C2 <- G1, G2; budget-and-billable lines 100..500).
Headless check: `scripts/run-project-analysis.sh` saves the xlsx for BGB-P-TOP to `output/verify/`; convert with
`soffice --headless --calc --convert-to xlsx` and read the pivot sheets (LibreOffice recalculates the pivots on load).

Web:
1. Projects list (page 89) -> Report / Project Hierarchy Analysis (runs for the selected projects; blank filter = all top-level projects).
2. Project Card (page 88) for BGB-P-TOP -> Report / Project Hierarchy Analysis -> request page shows Project No., Posting Date Filter, Planning Date Filter.
3. Download the Excel file: sheets Summary / By Customer / By Project (pivots), Data (64 columns, 5 rows), Chart.

Layout source: `scripts/layouts/make-project-hierarchy-analysis.py` regenerates `app/src/ProjectAnalysis/ProjectHierarchyAnalysis.xlsx`
(column list in `scripts/layouts/project-hierarchy-analysis.columns.json` must match the report columns).
