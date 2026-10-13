namespace FlemmingBakkensen.BCGrokBot.ProjectVersion;

using Microsoft.Projects.Project.Job;

/// <summary>
/// Project Version Trend: one row per project task and archive version, plus the current figures.
/// Default layout is Excel (Data sheet, pivot tables and a chart).
/// </summary>
report 50102 "BGB Project Version Trend"
{
    Caption = 'Project Version Trend';
    ApplicationArea = Jobs;
    UsageCategory = ReportsAndAnalysis;
    DefaultRenderingLayout = ExcelLayout;
    MaximumDatasetSize = 1000000;
    Permissions = tabledata Job = r;

    dataset
    {
        dataitem(ProjectFilter; Job)
        {
            RequestFilterFields = "No.", "BGB Parent Project No.";
            RequestFilterHeading = 'Projects';

            trigger OnPreDataItem()
            begin
                CurrReport.Break();
            end;
        }
        dataitem(Row; "BGB Version Report Buffer")
        {
            UseTemporary = true;
            DataItemTableView = sorting("Entry No.");

                column(ProjectNo; "Project No.") { IncludeCaption = true; }
                column(JobTaskNo; "Job Task No.") { IncludeCaption = true; }
                column(Description; Description) { IncludeCaption = true; }
                column(ParentProjectNo; "Parent Project No.") { IncludeCaption = true; }
                column(Level; Level) { IncludeCaption = true; }
                column(RunAt; "Run At") { IncludeCaption = true; }
                column(VersionNo; "Version No.") { IncludeCaption = true; }
                column(IsCurrent; "Is Current") { IncludeCaption = true; }
                column(NoBreakdown; "No Breakdown") { IncludeCaption = true; }
                column(DuringProjectDelete; "During Project Delete") { IncludeCaption = true; }
                column(RunId; "Run ID Text") { IncludeCaption = true; }
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

            trigger OnPreDataItem()
            var
                VersionCompareMgt: Codeunit "BGB Version Compare Mgt.";
            begin
                VersionCompareMgt.BuildVersionReport(ProjectFilter, Row);
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'Project Version Trend';
        AboutText = 'Select projects, or leave the filter blank to include every top-level project and its subprojects. Each row is a project task in one archive version, or the current figures. Current is everything posted up to now.';
    }

    rendering
    {
        layout(ExcelLayout)
        {
            Type = Excel;
            LayoutFile = './src/ProjectVersion/ProjectVersionTrend.xlsx';
            Caption = 'Project Version Trend (Excel)';
            Summary = 'Data sheet with one row per project task and version, pivot tables and a chart.';
        }
    }
}
