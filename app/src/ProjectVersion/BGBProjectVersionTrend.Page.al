namespace FlemmingBakkensen.BCGrokBot.ProjectVersion;

using FlemmingBakkensen.BCGrokBot.ProjectHierarchy;
using Microsoft.Projects.Project.Job;

/// <summary>
/// Shows one row per archive run or version of a project, oldest first, and a current row.
/// Each row has the key totals, the change since the previous row, usage as a percentage of budget and invoiced as a percentage of billable.
/// </summary>
page 50104 "BGB Project Version Trend"
{
    Caption = 'Project Version Trend';
    PageType = List;
    ApplicationArea = Jobs;
    UsageCategory = ReportsAndAnalysis;
    SourceTable = "BGB Version Trend Buffer";
    SourceTableTemporary = true;
    SourceTableView = sorting("Sort Order");
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    Editable = true;

    layout
    {
        area(Content)
        {
            group(Selection)
            {
                Caption = 'Selection';
                field(ProjectNo; ProjectNo)
                {
                    Caption = 'Project No.';
                    ToolTip = 'Specifies the project.';
                    TableRelation = Job;

                    trigger OnValidate()
                    begin
                        RefreshBuffer();
                    end;
                }
                field(UseHierarchyTotals; UseHierarchyTotals)
                {
                    Caption = 'Hierarchy Totals';
                    ToolTip = 'Specifies that the amounts include this project and all its subprojects. Turn it off to see this project only.';

                    trigger OnValidate()
                    begin
                        RefreshBuffer();
                    end;
                }
            }
            repeater(Lines)
            {
                    field(RunAt; Rec."Run At")
                    {
                        ToolTip = 'Specifies when this version was archived.';
                    }
                    field(VersionNo; Rec."Version No.")
                    {
                        ToolTip = 'Specifies the archive version. Zero for current.';
                    }
                    field(IsCurrent; Rec."Is Current")
                    {
                        ToolTip = 'Specifies that the row is everything posted up to now.';
                    }
                    field(Description; Rec.Description)
                    {
                        ToolTip = 'Specifies the version.';
                    }
                    field(NoBreakdown; Rec."No Breakdown")
                    {
                        ToolTip = 'Specifies that this version has no snapshot. Only task archive totals are available.';
                    }
                    field(DuringProjectDelete; Rec."During Project Delete")
                    {
                    }
                    field(BudgetCost; Rec."Budget Cost")
                    {
                        ToolTip = 'Specifies the budget cost (LCY).';
                    }
                    field(BudgetPrice; Rec."Budget Price")
                    {
                        ToolTip = 'Specifies the budget price (LCY).';
                    }
                    field(UsageCost; Rec."Usage Cost")
                    {
                        ToolTip = 'Specifies the usage cost (LCY).';
                    }
                    field(UsageCostDelta; Rec."Usage Cost Delta")
                    {
                        ToolTip = 'Specifies the change in usage cost since the previous version.';
                    }
                    field(UsagePctOfBudget; Rec."Usage % of Budget")
                    {
                        ToolTip = 'Specifies usage cost as a percentage of budget cost. Zero when the budget is zero.';
                    }
                    field(BillablePrice; Rec."Billable Price")
                    {
                        ToolTip = 'Specifies the billable price (LCY).';
                    }
                    field(InvoicedPrice; Rec."Invoiced Price")
                    {
                        ToolTip = 'Specifies the invoiced price (LCY).';
                    }
                    field(InvoicedPriceDelta; Rec."Invoiced Price Delta")
                    {
                        ToolTip = 'Specifies the change in invoiced price since the previous version.';
                    }
                    field(InvoicedPctOfBillable; Rec."Invoiced % of Billable")
                    {
                    }
                    field(UsagePrice; Rec."Usage Price")
                    {
                        ToolTip = 'Specifies the usage price (LCY).';
                    }
                    field(BillableCost; Rec."Billable Cost")
                    {
                        ToolTip = 'Specifies the billable cost (LCY).';
                    }
                    field(InvoicedCost; Rec."Invoiced Cost")
                    {
                        ToolTip = 'Specifies the invoiced cost (LCY).';
                    }
            }
        }
    }

    trigger OnOpenPage()
    begin
        if ProjectNo <> '' then
            RefreshBuffer();
    end;

    /// <summary>
    /// Opens the trend for a project. Hierarchy totals are used when the project has subprojects.
    /// </summary>
    /// <param name="NewProjectNo">The project number.</param>
    procedure SetProject(NewProjectNo: Code[20])
    var
        ProjectHierarchyMgt: Codeunit "BGB Project Hierarchy Mgt.";
    begin
        ProjectNo := NewProjectNo;
        UseHierarchyTotals := ProjectHierarchyMgt.HasSubprojects(NewProjectNo);
    end;

    local procedure RefreshBuffer()
    var
        VersionCompareMgt: Codeunit "BGB Version Compare Mgt.";
    begin
        Rec.Reset();
        Rec.DeleteAll(false);
        if ProjectNo = '' then
            exit;
        VersionCompareMgt.BuildTrend(ProjectNo, UseHierarchyTotals, Rec);
        if Rec.FindFirst() then;
        CurrPage.Update(false);
    end;

    var
        ProjectNo: Code[20];
        UseHierarchyTotals: Boolean;
}
