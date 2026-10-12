namespace FlemmingBakkensen.BCGrokBot.ProjectAnalysis;

using Microsoft.Projects.Project.Job;

/// <summary>
/// Project Hierarchy Analysis: one row per project of each selected hierarchy with the project's own statistics
/// (standard Job Calculate Statistics, LCY), profit and margin, and the rolled-up hierarchy totals.
/// Default layout is Excel (Data sheet plus pivot tables that refresh when the workbook is opened).
/// </summary>
report 50101 "BGB Project Hierarchy Analysis"
{
    Caption = 'Project Hierarchy Analysis';
    ApplicationArea = Jobs;
    UsageCategory = ReportsAndAnalysis;
    DefaultRenderingLayout = ExcelLayout;
    MaximumDatasetSize = 1000000;
    Permissions = tabledata Job = r;

    dataset
    {
        dataitem(ProjectFilter; Job)
        {
            RequestFilterFields = "No.", "Posting Date Filter", "Planning Date Filter";
            RequestFilterHeading = 'Projects';

            trigger OnPreDataItem()
            begin
                CurrReport.Break();
            end;
        }
        dataitem(Row; "BGB Project Analysis Buffer")
        {
            UseTemporary = true;
            DataItemTableView = sorting("Entry No.");

                column(TopLevelProjectNo; "Top-Level Project No.") { IncludeCaption = true; }
                column(ProjectNo; "Project No.") { IncludeCaption = true; }
                column(Description; Description) { IncludeCaption = true; }
                column(IndentedDescription; "Indented Description") { IncludeCaption = true; }
                column(ParentProjectNo; "Parent Project No.") { IncludeCaption = true; }
                column(Level; Level) { IncludeCaption = true; }
                column(SortKey; "Sort Key") { IncludeCaption = true; }
                column(BillToCustomerNo; "Bill-to Customer No.") { IncludeCaption = true; }
                column(BillToName; "Bill-to Name") { IncludeCaption = true; }
                column(SellToCustomerNo; "Sell-to Customer No.") { IncludeCaption = true; }
                column(SellToName; "Sell-to Name") { IncludeCaption = true; }
                column(CurrencyCode; "Currency Code") { IncludeCaption = true; }
                column(InvoiceCurrencyCode; "Invoice Currency Code") { IncludeCaption = true; }
                column(Status; Status) { IncludeCaption = true; }
                column(PersonResponsible; "Person Responsible") { IncludeCaption = true; }
                column(SubprojectCount; "Subproject Count") { IncludeCaption = true; }
                column(BudgetCostResource; "Budget Cost Resource") { IncludeCaption = true; }
                column(BudgetCostItem; "Budget Cost Item") { IncludeCaption = true; }
                column(BudgetCostGLAccount; "Budget Cost G/L Acc.") { IncludeCaption = true; }
                column(BudgetCostTotal; "Budget Cost Total") { IncludeCaption = true; }
                column(UsageCostResource; "Usage Cost Resource") { IncludeCaption = true; }
                column(UsageCostItem; "Usage Cost Item") { IncludeCaption = true; }
                column(UsageCostGLAccount; "Usage Cost G/L Acc.") { IncludeCaption = true; }
                column(UsageCostTotal; "Usage Cost Total") { IncludeCaption = true; }
                column(BillableCostResource; "Billable Cost Resource") { IncludeCaption = true; }
                column(BillableCostItem; "Billable Cost Item") { IncludeCaption = true; }
                column(BillableCostGLAccount; "Billable Cost G/L Acc.") { IncludeCaption = true; }
                column(BillableCostTotal; "Billable Cost Total") { IncludeCaption = true; }
                column(InvoicedCostResource; "Invoiced Cost Resource") { IncludeCaption = true; }
                column(InvoicedCostItem; "Invoiced Cost Item") { IncludeCaption = true; }
                column(InvoicedCostGLAccount; "Invoiced Cost G/L Acc.") { IncludeCaption = true; }
                column(InvoicedCostTotal; "Invoiced Cost Total") { IncludeCaption = true; }
                column(BudgetPriceResource; "Budget Price Resource") { IncludeCaption = true; }
                column(BudgetPriceItem; "Budget Price Item") { IncludeCaption = true; }
                column(BudgetPriceGLAccount; "Budget Price G/L Acc.") { IncludeCaption = true; }
                column(BudgetPriceTotal; "Budget Price Total") { IncludeCaption = true; }
                column(UsagePriceResource; "Usage Price Resource") { IncludeCaption = true; }
                column(UsagePriceItem; "Usage Price Item") { IncludeCaption = true; }
                column(UsagePriceGLAccount; "Usage Price G/L Acc.") { IncludeCaption = true; }
                column(UsagePriceTotal; "Usage Price Total") { IncludeCaption = true; }
                column(BillablePriceResource; "Billable Price Resource") { IncludeCaption = true; }
                column(BillablePriceItem; "Billable Price Item") { IncludeCaption = true; }
                column(BillablePriceGLAccount; "Billable Price G/L Acc.") { IncludeCaption = true; }
                column(BillablePriceTotal; "Billable Price Total") { IncludeCaption = true; }
                column(InvoicedPriceResource; "Invoiced Price Resource") { IncludeCaption = true; }
                column(InvoicedPriceItem; "Invoiced Price Item") { IncludeCaption = true; }
                column(InvoicedPriceGLAccount; "Invoiced Price G/L Acc.") { IncludeCaption = true; }
                column(InvoicedPriceTotal; "Invoiced Price Total") { IncludeCaption = true; }
                column(BudgetProfit; "Budget Profit") { IncludeCaption = true; }
                column(BudgetMarginPct; "Budget Margin %") { IncludeCaption = true; }
                column(UsageProfit; "Usage Profit") { IncludeCaption = true; }
                column(UsageMarginPct; "Usage Margin %") { IncludeCaption = true; }
                column(BillableProfit; "Billable Profit") { IncludeCaption = true; }
                column(BillableMarginPct; "Billable Margin %") { IncludeCaption = true; }
                column(InvoicedProfit; "Invoiced Profit") { IncludeCaption = true; }
                column(InvoicedMarginPct; "Invoiced Margin %") { IncludeCaption = true; }
                column(HierarchyBudgetCostTotal; "Hier. Budget Cost") { IncludeCaption = true; }
                column(HierarchyUsageCostTotal; "Hier. Usage Cost") { IncludeCaption = true; }
                column(HierarchyBillableCostTotal; "Hier. Billable Cost") { IncludeCaption = true; }
                column(HierarchyInvoicedCostTotal; "Hier. Invoiced Cost") { IncludeCaption = true; }
                column(HierarchyBudgetPriceTotal; "Hier. Budget Price") { IncludeCaption = true; }
                column(HierarchyUsagePriceTotal; "Hier. Usage Price") { IncludeCaption = true; }
                column(HierarchyBillablePriceTotal; "Hier. Billable Price") { IncludeCaption = true; }
                column(HierarchyInvoicedPriceTotal; "Hier. Invoiced Price") { IncludeCaption = true; }

            trigger OnPreDataItem()
            var
                ProjectAnalysisMgt: Codeunit "BGB Project Analysis Mgt.";
            begin
                ProjectAnalysisMgt.BuildAnalysis(ProjectFilter, Row, true);
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'Project Hierarchy Analysis';
        AboutText = 'Select projects, or leave the project filter blank to include all top-level projects. Each selected project is included with all its subprojects. The date filters limit the statistics as on the project statistics.';
    }

    rendering
    {
        layout(ExcelLayout)
        {
            Type = Excel;
            LayoutFile = './src/ProjectAnalysis/ProjectHierarchyAnalysis.xlsx';
            Caption = 'Project Hierarchy Analysis (Excel)';
            Summary = 'Data sheet with one row per project and pivot tables by top-level project, level and bill-to customer.';
        }
    }
}
