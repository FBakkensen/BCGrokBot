namespace FlemmingBakkensen.BCGrokBot.ProjectAnalysis;

using FlemmingBakkensen.BCGrokBot.ProjectHierarchy;
using Microsoft.Projects.Project.Job;

/// <summary>
/// Builds the rows of the Project Hierarchy Analysis report: one row per project in tree order (depth first),
/// with level, sort key, master data, the project's own statistics and the rolled-up hierarchy totals.
/// </summary>
codeunit 50108 "BGB Project Analysis Mgt."
{
    Access = Public;
    Permissions = tabledata Job = r;

    var
        SortKeyPartTok: Label '%1', Locked = true;

    /// <summary>
    /// Fills the buffer for the projects in the filter. Without a project number (or parent) filter, all
    /// top-level projects are used. Every selected project is included with its whole subtree; projects already
    /// included through a selected ancestor are not repeated.
    /// </summary>
    /// <param name="JobFilter">The project filter; its Posting Date Filter and Planning Date Filter are applied to the statistics.</param>
    /// <param name="ProjectAnalysisBuffer">Returns the rows (temporary).</param>
    /// <param name="IncludeAmounts">Whether to calculate the statistics (false: tree and master data only).</param>
    procedure BuildAnalysis(var JobFilter: Record Job; var ProjectAnalysisBuffer: Record "BGB Project Analysis Buffer" temporary; IncludeAmounts: Boolean)
    var
        RootJob: Record Job;
        ProjectHierarchyMgt: Codeunit "BGB Project Hierarchy Mgt.";
        RootNo: Integer;
    begin
        ProjectAnalysisBuffer.Reset();
        ProjectAnalysisBuffer.DeleteAll(false);
        RootJob.CopyFilters(JobFilter);
        if (RootJob.GetFilter("No.") = '') and (RootJob.GetFilter("BGB Parent Project No.") = '') then
            RootJob.SetRange("BGB Parent Project No.", '');
        RootJob.SetLoadFields("No.");
        if RootJob.FindSet() then
            repeat
                if not IsIncluded(ProjectAnalysisBuffer, RootJob."No.") then begin
                    RootNo += 1;
                    AddSubtree(ProjectAnalysisBuffer, RootJob."No.", ProjectHierarchyMgt.GetTopLevelProjectNo(RootJob."No."),
                      GetLevel(RootJob."No."), StrSubstNo(SortKeyPartTok, FormatPosition(RootNo)), JobFilter, IncludeAmounts);
                end;
            until RootJob.Next() = 0;
        if IncludeAmounts then
            CalcHierarchyTotals(ProjectAnalysisBuffer);
        ProjectAnalysisBuffer.Reset();
        ProjectAnalysisBuffer.SetCurrentKey("Entry No.");
    end;

    /// <summary>
    /// Returns the depth of the project: 0 for a top-level project, 1 for its subprojects, and so on.
    /// </summary>
    /// <param name="ProjectNo">The project number.</param>
    /// <returns>The level.</returns>
    procedure GetLevel(ProjectNo: Code[20]): Integer
    var
        Job: Record Job;
        CurrentNo: Code[20];
        Level: Integer;
    begin
        Level := 0;
        Job.SetLoadFields("BGB Parent Project No.");
        CurrentNo := ProjectNo;
        while Job.Get(CurrentNo) and (Job."BGB Parent Project No." <> '') and (Level < 10000) do begin
            Level += 1;
            CurrentNo := Job."BGB Parent Project No.";
        end;
        exit(Level);
    end;

    local procedure AddSubtree(var ProjectAnalysisBuffer: Record "BGB Project Analysis Buffer" temporary; ProjectNo: Code[20]; TopLevelProjectNo: Code[20]; Level: Integer; SortKey: Text; var JobFilter: Record Job; IncludeAmounts: Boolean)
    var
        ChildJob: Record Job;
        Position: Integer;
    begin
        if IsIncluded(ProjectAnalysisBuffer, ProjectNo) then
            exit;
        AddRow(ProjectAnalysisBuffer, ProjectNo, TopLevelProjectNo, Level, SortKey, JobFilter, IncludeAmounts);
        ChildJob.SetCurrentKey("BGB Parent Project No.");
        ChildJob.SetRange("BGB Parent Project No.", ProjectNo);
        ChildJob.SetLoadFields("No.");
        if ChildJob.FindSet() then
            repeat
                Position += 1;
                AddSubtree(ProjectAnalysisBuffer, ChildJob."No.", TopLevelProjectNo, Level + 1, SortKey + '.' + FormatPosition(Position), JobFilter, IncludeAmounts);
            until ChildJob.Next() = 0;
    end;

    local procedure AddRow(var ProjectAnalysisBuffer: Record "BGB Project Analysis Buffer" temporary; ProjectNo: Code[20]; TopLevelProjectNo: Code[20]; Level: Integer; SortKey: Text; var JobFilter: Record Job; IncludeAmounts: Boolean)
    var
        Job: Record Job;
        ProjectHierarchyMgt: Codeunit "BGB Project Hierarchy Mgt.";
        EntryNo: Integer;
    begin
        if not Job.Get(ProjectNo) then
            exit;
        ProjectAnalysisBuffer.Reset();
        if ProjectAnalysisBuffer.FindLast() then
            EntryNo := ProjectAnalysisBuffer."Entry No.";
        ProjectAnalysisBuffer.Init();
        ProjectAnalysisBuffer."Entry No." := EntryNo + 1;
        ProjectAnalysisBuffer."Top-Level Project No." := TopLevelProjectNo;
        ProjectAnalysisBuffer."Project No." := Job."No.";
        ProjectAnalysisBuffer.Description := Job.Description;
        ProjectAnalysisBuffer."Indented Description" := CopyStr(PadStr('', 2 * Level, ' ') + Job.Description, 1, MaxStrLen(ProjectAnalysisBuffer."Indented Description"));
        ProjectAnalysisBuffer."Parent Project No." := Job."BGB Parent Project No.";
        ProjectAnalysisBuffer.Level := Level;
        ProjectAnalysisBuffer."Sort Key" := CopyStr(SortKey, 1, MaxStrLen(ProjectAnalysisBuffer."Sort Key"));
        ProjectAnalysisBuffer."Bill-to Customer No." := Job."Bill-to Customer No.";
        ProjectAnalysisBuffer."Bill-to Name" := Job."Bill-to Name";
        ProjectAnalysisBuffer."Sell-to Customer No." := Job."Sell-to Customer No.";
        ProjectAnalysisBuffer."Sell-to Name" := Job."Sell-to Customer Name";
        ProjectAnalysisBuffer."Currency Code" := Job."Currency Code";
        ProjectAnalysisBuffer."Invoice Currency Code" := Job."Invoice Currency Code";
        ProjectAnalysisBuffer.Status := Job.Status;
        ProjectAnalysisBuffer."Person Responsible" := Job."Person Responsible";
        ProjectAnalysisBuffer."Subproject Count" := ProjectHierarchyMgt.CountDescendants(Job."No.");
        if IncludeAmounts then begin
            Job.SetFilter("Posting Date Filter", JobFilter.GetFilter("Posting Date Filter"));
            Job.SetFilter("Planning Date Filter", JobFilter.GetFilter("Planning Date Filter"));
            SetOwnAmounts(ProjectAnalysisBuffer, Job);
        end;
        ProjectAnalysisBuffer.Insert(false);
    end;

    local procedure SetOwnAmounts(var ProjectAnalysisBuffer: Record "BGB Project Analysis Buffer" temporary; var Job: Record Job)
    var
        JobCalculateStatistics: Codeunit "Job Calculate Statistics";
        RecRef: RecordRef;
        CostAmounts: array[16] of Decimal;
        PriceAmounts: array[16] of Decimal;
        i: Integer;
    begin
        JobCalculateStatistics.JobCalculateCommonFilters(Job);
        JobCalculateStatistics.CalculateAmounts();
        JobCalculateStatistics.GetLCYCostAmounts(CostAmounts);
        JobCalculateStatistics.GetLCYPriceAmounts(PriceAmounts);
        RecRef.GetTable(ProjectAnalysisBuffer);
        for i := 1 to 16 do begin
            RecRef.Field(GetFirstOwnAmountFieldNo() + i - 1).Value(CostAmounts[i]);
            RecRef.Field(GetFirstOwnAmountFieldNo() + 16 + i - 1).Value(PriceAmounts[i]);
        end;
        // Profit and margin per kind (budget, usage, billable, invoiced): totals are elements 4, 8, 12, 16
        for i := 1 to 4 do begin
            RecRef.Field(GetFirstProfitFieldNo() + 2 * (i - 1)).Value(PriceAmounts[4 * i] - CostAmounts[4 * i]);
            RecRef.Field(GetFirstProfitFieldNo() + 2 * (i - 1) + 1).Value(CalcMarginPct(PriceAmounts[4 * i], CostAmounts[4 * i]));
            RecRef.Field(GetFirstHierarchyFieldNo() + i - 1).Value(CostAmounts[4 * i]);
            RecRef.Field(GetFirstHierarchyFieldNo() + 4 + i - 1).Value(PriceAmounts[4 * i]);
        end;
        RecRef.SetTable(ProjectAnalysisBuffer);
    end;

    /// <summary>
    /// Returns the profit margin in percent of the price (0 when the price is 0).
    /// </summary>
    /// <param name="Price">The price amount.</param>
    /// <param name="Cost">The cost amount.</param>
    /// <returns>(Price - Cost) / Price * 100, rounded to 0.01.</returns>
    procedure CalcMarginPct(Price: Decimal; Cost: Decimal): Decimal
    begin
        if Price = 0 then
            exit(0);
        exit(Round((Price - Cost) / Price * 100, 0.01));
    end;

    local procedure CalcHierarchyTotals(var ProjectAnalysisBuffer: Record "BGB Project Analysis Buffer" temporary)
    var
        TempParentBuffer: Record "BGB Project Analysis Buffer" temporary;
        RecRef: RecordRef;
        ParentRecRef: RecordRef;
        ParentAmount: Decimal;
        ChildAmount: Decimal;
        FieldNo: Integer;
    begin
        // Depth-first order: every subproject has a higher entry number than its parent, so walking backwards
        // finishes a project's total before it is added to its parent.
        TempParentBuffer.Copy(ProjectAnalysisBuffer, true);
        TempParentBuffer.SetCurrentKey("Project No.");
        ProjectAnalysisBuffer.Reset();
        if not ProjectAnalysisBuffer.FindLast() then
            exit;
        repeat
            if ProjectAnalysisBuffer."Parent Project No." <> '' then begin
                TempParentBuffer.SetRange("Project No.", ProjectAnalysisBuffer."Parent Project No.");
                if TempParentBuffer.FindFirst() then begin
                    RecRef.GetTable(ProjectAnalysisBuffer);
                    ParentRecRef.GetTable(TempParentBuffer);
                    for FieldNo := GetFirstHierarchyFieldNo() to GetFirstHierarchyFieldNo() + 7 do begin
                        ParentAmount := ParentRecRef.Field(FieldNo).Value();
                        ChildAmount := RecRef.Field(FieldNo).Value();
                        ParentRecRef.Field(FieldNo).Value(ParentAmount + ChildAmount);
                    end;
                    ParentRecRef.Modify(false);
                end;
            end;
        until ProjectAnalysisBuffer.Next(-1) = 0;
    end;

    local procedure IsIncluded(var ProjectAnalysisBuffer: Record "BGB Project Analysis Buffer" temporary; ProjectNo: Code[20]): Boolean
    var
        Found: Boolean;
    begin
        ProjectAnalysisBuffer.Reset();
        ProjectAnalysisBuffer.SetCurrentKey("Project No.");
        ProjectAnalysisBuffer.SetRange("Project No.", ProjectNo);
        Found := not ProjectAnalysisBuffer.IsEmpty();
        ProjectAnalysisBuffer.Reset();
        exit(Found);
    end;

    local procedure FormatPosition(Position: Integer): Text
    begin
        exit(PadStr('', 4 - StrLen(Format(Position)), '0') + Format(Position));
    end;

    local procedure GetFirstOwnAmountFieldNo(): Integer
    begin
        exit(100);
    end;

    local procedure GetFirstProfitFieldNo(): Integer
    begin
        exit(200);
    end;

    local procedure GetFirstHierarchyFieldNo(): Integer
    begin
        exit(300);
    end;
}
