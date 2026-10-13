namespace FlemmingBakkensen.BCGrokBot.ProjectVersion;

using Microsoft.Projects.Project.Archive;
using Microsoft.Projects.Project.Job;

/// <summary>
/// Compares two archived versions of a project, or one version and the current figures.
/// Rows are project tasks or the projects in the tree, plus a total. Columns are budget, usage, billable and invoiced cost and price.
/// </summary>
page 50103 "BGB Project Version Compare"
{
    Caption = 'Project Version Compare';
    PageType = Worksheet;
    ApplicationArea = Jobs;
    UsageCategory = ReportsAndAnalysis;
    SourceTable = "BGB Version Compare Buffer";
    SourceTableTemporary = true;
    SourceTableView = sorting("Entry No.");
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
                    ToolTip = 'Specifies the project to compare. In projects view this is the top of the tree.';
                    TableRelation = Job;

                    trigger OnValidate()
                    begin
                        SuggestVersion();
                        RefreshBuffer();
                    end;
                }
                field(VersionA; VersionA)
                {
                    Caption = 'Version A';
                    ToolTip = 'Specifies the archive version on side A. Choose the assist button to pick a project archive version.';
                    BlankZero = true;

                    trigger OnValidate()
                    begin
                        RefreshBuffer();
                    end;

                    trigger OnAssistEdit()
                    begin
                        LookupVersion(VersionA);
                    end;
                }
                field(CompareTo; CompareTo)
                {
                    Caption = 'Compare To';
                    ToolTip = 'Specifies whether side B is another archive version or everything posted up to now.';

                    trigger OnValidate()
                    begin
                        RefreshBuffer();
                    end;
                }
                field(VersionB; VersionB)
                {
                    Caption = 'Version B';
                    ToolTip = 'Specifies the archive version on side B.';
                    BlankZero = true;

                    trigger OnValidate()
                    begin
                        RefreshBuffer();
                    end;

                    trigger OnAssistEdit()
                    begin
                        LookupVersion(VersionB);
                    end;
                }
                field(RowMode; RowMode)
                {
                    Caption = 'Rows';
                    ToolTip = 'Specifies whether rows are the tasks of the project or the projects in the tree.';

                    trigger OnValidate()
                    begin
                        RefreshBuffer();
                    end;
                }
                field(AmountView; AmountView)
                {
                    Caption = 'Amount View';
                    ToolTip = 'Specifies whether amounts are the total or only Resource, Item or G/L Account. Archives without a snapshot have no breakdown, so a type view is zero.';

                    trigger OnValidate()
                    begin
                        RefreshBuffer();
                    end;
                }
                field(SideA; SideAText)
                {
                    Caption = 'Side A';
                    ToolTip = 'Specifies the archive run of version A.';
                    Editable = false;
                }
                field(SideB; SideBText)
                {
                    Caption = 'Side B';
                    ToolTip = 'Specifies version B, or Current when comparing with everything posted up to now.';
                    Editable = false;
                }
            }
            repeater(Lines)
            {
                    field(RowKind; Rec."Row Kind")
                    {
                    }
                    field(ProjectNoLine; Rec."Project No.")
                    {
                    }
                    field(JobTaskNo; Rec."Job Task No.")
                    {
                        ToolTip = 'Specifies the project task.';
                    }
                    field(Description; Rec.Description)
                    {
                    }
                    field(Level; Rec.Level)
                    {
                    }
                    field(NoBreakdown; Rec."No Breakdown")
                    {
                        ToolTip = 'Specifies that a side has no Resource, Item or G/L split.';
                    }
                    field(DuringProjectDelete; Rec."During Project Delete")
                    {
                        ToolTip = 'Specifies that a snapshot was taken while the project was being deleted. Usage may be incomplete.';
                    }
                    field(VersionNoA; Rec."Version No. A")
                    {
                        ToolTip = 'Specifies archive version A of this project.';
                    }
                    field(VersionNoB; Rec."Version No. B")
                    {
                        ToolTip = 'Specifies archive version B. Zero when side B is current.';
                    }
                    field(BudgetCostA; Rec."Budget Cost A")
                    {
                        ToolTip = 'Specifies budget cost (LCY), side A.';
                    }
                    field(BudgetPriceA; Rec."Budget Price A")
                    {
                        ToolTip = 'Specifies budget price (LCY), side A.';
                    }
                    field(UsageCostA; Rec."Usage Cost A")
                    {
                        ToolTip = 'Specifies usage cost (LCY), side A.';
                    }
                    field(UsagePriceA; Rec."Usage Price A")
                    {
                        ToolTip = 'Specifies usage price (LCY), side A.';
                    }
                    field(BillableCostA; Rec."Billable Cost A")
                    {
                        ToolTip = 'Specifies billable cost (LCY), side A.';
                    }
                    field(BillablePriceA; Rec."Billable Price A")
                    {
                        ToolTip = 'Specifies billable price (LCY), side A.';
                    }
                    field(InvoicedCostA; Rec."Invoiced Cost A")
                    {
                        ToolTip = 'Specifies invoiced cost (LCY), side A.';
                    }
                    field(InvoicedPriceA; Rec."Invoiced Price A")
                    {
                        ToolTip = 'Specifies invoiced price (LCY), side A.';
                    }
                    field(BudgetCostB; Rec."Budget Cost B")
                    {
                        ToolTip = 'Specifies budget cost (LCY), side B.';
                    }
                    field(BudgetPriceB; Rec."Budget Price B")
                    {
                        ToolTip = 'Specifies budget price (LCY), side B.';
                    }
                    field(UsageCostB; Rec."Usage Cost B")
                    {
                        ToolTip = 'Specifies usage cost (LCY), side B.';
                    }
                    field(UsagePriceB; Rec."Usage Price B")
                    {
                        ToolTip = 'Specifies usage price (LCY), side B.';
                    }
                    field(BillableCostB; Rec."Billable Cost B")
                    {
                        ToolTip = 'Specifies billable cost (LCY), side B.';
                    }
                    field(BillablePriceB; Rec."Billable Price B")
                    {
                        ToolTip = 'Specifies billable price (LCY), side B.';
                    }
                    field(InvoicedCostB; Rec."Invoiced Cost B")
                    {
                        ToolTip = 'Specifies invoiced cost (LCY), side B.';
                    }
                    field(InvoicedPriceB; Rec."Invoiced Price B")
                    {
                        ToolTip = 'Specifies invoiced price (LCY), side B.';
                    }
                    field(BudgetCostDifference; Rec."Budget Cost Difference")
                    {
                        ToolTip = 'Specifies budget cost (LCY), the difference, side B minus side A.';
                    }
                    field(BudgetPriceDifference; Rec."Budget Price Difference")
                    {
                        ToolTip = 'Specifies budget price (LCY), the difference, side B minus side A.';
                    }
                    field(UsageCostDifference; Rec."Usage Cost Difference")
                    {
                        ToolTip = 'Specifies usage cost (LCY), the difference, side B minus side A.';
                    }
                    field(UsagePriceDifference; Rec."Usage Price Difference")
                    {
                        ToolTip = 'Specifies usage price (LCY), the difference, side B minus side A.';
                    }
                    field(BillableCostDifference; Rec."Billable Cost Difference")
                    {
                        ToolTip = 'Specifies billable cost (LCY), the difference, side B minus side A.';
                    }
                    field(BillablePriceDifference; Rec."Billable Price Difference")
                    {
                        ToolTip = 'Specifies billable price (LCY), the difference, side B minus side A.';
                    }
                    field(InvoicedCostDifference; Rec."Invoiced Cost Difference")
                    {
                        ToolTip = 'Specifies invoiced cost (LCY), the difference, side B minus side A.';
                    }
                    field(InvoicedPriceDifference; Rec."Invoiced Price Difference")
                    {
                        ToolTip = 'Specifies invoiced price (LCY), the difference, side B minus side A.';
                    }
                    field(BudgetCostChangePct; Rec."Budget Cost Change %")
                    {
                        ToolTip = 'Specifies budget cost (LCY), the percentage change from side A. Zero when side A is zero.';
                    }
                    field(BudgetPriceChangePct; Rec."Budget Price Change %")
                    {
                        ToolTip = 'Specifies budget price (LCY), the percentage change from side A. Zero when side A is zero.';
                    }
                    field(UsageCostChangePct; Rec."Usage Cost Change %")
                    {
                        ToolTip = 'Specifies usage cost (LCY), the percentage change from side A. Zero when side A is zero.';
                    }
                    field(UsagePriceChangePct; Rec."Usage Price Change %")
                    {
                        ToolTip = 'Specifies usage price (LCY), the percentage change from side A. Zero when side A is zero.';
                    }
                    field(BillableCostChangePct; Rec."Billable Cost Change %")
                    {
                        ToolTip = 'Specifies billable cost (LCY), the percentage change from side A. Zero when side A is zero.';
                    }
                    field(BillablePriceChangePct; Rec."Billable Price Change %")
                    {
                        ToolTip = 'Specifies billable price (LCY), the percentage change from side A. Zero when side A is zero.';
                    }
                    field(InvoicedCostChangePct; Rec."Invoiced Cost Change %")
                    {
                        ToolTip = 'Specifies invoiced cost (LCY), the percentage change from side A. Zero when side A is zero.';
                    }
                    field(InvoicedPriceChangePct; Rec."Invoiced Price Change %")
                    {
                        ToolTip = 'Specifies invoiced price (LCY), the percentage change from side A. Zero when side A is zero.';
                    }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Refresh)
            {
                Caption = 'Refresh';
                Image = Refresh;
                ToolTip = 'Recalculate the comparison.';

                trigger OnAction()
                begin
                    RefreshBuffer();
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        if ProjectNo <> '' then
            RefreshBuffer();
    end;

    /// <summary>
    /// Opens the compare page for a project, with the latest archive version against the current figures.
    /// </summary>
    /// <param name="NewProjectNo">The project number.</param>
    procedure SetProject(NewProjectNo: Code[20])
    begin
        ProjectNo := NewProjectNo;
        SuggestVersion();
    end;

    local procedure SuggestVersion()
    var
        VersionCompareMgt: Codeunit "BGB Version Compare Mgt.";
    begin
        if VersionA = 0 then
            VersionA := VersionCompareMgt.LatestVersionNo(ProjectNo);
        if CompareTo = CompareTo::Version then
            exit;
        CompareTo := CompareTo::Current;
    end;

    local procedure LookupVersion(var VersionNo: Integer)
    var
        JobArchive: Record "Job Archive";
        ArchiveList: Page "Job Archive List";
    begin
        if ProjectNo = '' then
            exit;
        JobArchive.SetRange("No.", ProjectNo);
        ArchiveList.SetTableView(JobArchive);
        ArchiveList.LookupMode(true);
        if ArchiveList.RunModal() <> Action::LookupOK then
            exit;
        ArchiveList.GetRecord(JobArchive);
        VersionNo := JobArchive."Version No.";
        RefreshBuffer();
    end;

    local procedure NormalizeSelection()
    begin
        if RowMode = RowMode::" " then
            RowMode := RowMode::Tasks;
        if AmountView = AmountView::" " then
            AmountView := AmountView::Total;
        if CompareTo = CompareTo::" " then
            CompareTo := CompareTo::Current;
    end;

    local procedure RefreshBuffer()
    var
        VersionCompareMgt: Codeunit "BGB Version Compare Mgt.";
    begin
        NormalizeSelection();
        CompareToVersion := CompareTo = CompareTo::Version;
        SideAText := '';
        SideBText := '';
        Rec.Reset();
        Rec.DeleteAll(false);
        if (ProjectNo = '') or (VersionA = 0) then
            exit;
        if CompareToVersion and (VersionB = 0) then
            exit;
        VersionCompareMgt.BuildCompare(ProjectNo, VersionA, VersionB, not CompareToVersion, RowMode, AmountView, Rec);
        SideAText := CopyStr(VersionCompareMgt.VersionDescription(ProjectNo, VersionA, false), 1, MaxStrLen(SideAText));
        SideBText := CopyStr(VersionCompareMgt.VersionDescription(ProjectNo, VersionB, not CompareToVersion), 1, MaxStrLen(SideBText));
        if Rec.FindFirst() then;
        CurrPage.Update(false);
    end;

    var
        ProjectNo: Code[20];
        VersionA: Integer;
        VersionB: Integer;
        CompareTo: Enum "BGB Version Compare To";
        RowMode: Enum "BGB Version Row Mode";
        AmountView: Enum "BGB Version Amount View";
        SideAText: Text[100];
        SideBText: Text[100];
        CompareToVersion: Boolean;
}
