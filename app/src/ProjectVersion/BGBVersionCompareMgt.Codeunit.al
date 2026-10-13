namespace FlemmingBakkensen.BCGrokBot.ProjectVersion;

using FlemmingBakkensen.BCGrokBot.ProjectAnalysis;
using FlemmingBakkensen.BCGrokBot.ProjectHierarchy;
using Microsoft.Projects.Project.Archive;
using Microsoft.Projects.Project.Job;

/// <summary>
/// Compares two archived project versions, or a version and the current figures, and builds the version trend.
/// Current is everything posted up to now, with no date filter. Percentage change is zero when the base amount is zero.
/// </summary>
codeunit 50111 "BGB Version Compare Mgt."
{
    Access = Public;
    Permissions = tabledata Job = r,
                  tabledata "Job Archive" = r,
                  tabledata "Job Task" = r,
                  tabledata "Job Task Archive" = r,
                  tabledata "BGB Project Snapshot" = r,
                  tabledata "BGB Project Task Snapshot" = r;

    var
        VersionNotFoundErr: Label 'Project %1 does not have archive version %2.', Comment = '%1 = project number, %2 = version number';
        TotalLbl: Label 'Total';
        CurrentLbl: Label 'Current';
        VersionAtLbl: Label 'Version %1 (%2)', Comment = '%1 = version number, %2 = archive date-time';
        VersionLbl: Label 'Version %1', Comment = '%1 = version number';

    /// <summary>
    /// Returns the difference NewAmount minus BaseAmount.
    /// </summary>
    /// <param name="BaseAmount">The base amount (side A).</param>
    /// <param name="NewAmount">The new amount (side B, or current).</param>
    /// <returns>The difference.</returns>
    procedure CalcDifference(BaseAmount: Decimal; NewAmount: Decimal): Decimal
    begin
        exit(NewAmount - BaseAmount);
    end;

    /// <summary>
    /// Returns the percentage change from BaseAmount to NewAmount, rounded to 0.01. Zero when BaseAmount is zero.
    /// </summary>
    /// <param name="BaseAmount">The base amount.</param>
    /// <param name="NewAmount">The new amount.</param>
    /// <returns>The percentage change.</returns>
    procedure CalcChangePct(BaseAmount: Decimal; NewAmount: Decimal): Decimal
    begin
        if BaseAmount = 0 then
            exit(0);
        exit(Round((NewAmount - BaseAmount) / BaseAmount * 100, 0.01));
    end;

    /// <summary>
    /// Returns Part as a percentage of Whole, rounded to 0.01. Zero when Whole is zero.
    /// </summary>
    /// <param name="PartAmount">The part.</param>
    /// <param name="WholeAmount">The whole.</param>
    /// <returns>The percentage.</returns>
    procedure CalcRatioPct(PartAmount: Decimal; WholeAmount: Decimal): Decimal
    begin
        if WholeAmount = 0 then
            exit(0);
        exit(Round(PartAmount / WholeAmount * 100, 0.01));
    end;

    /// <summary>
    /// Returns a caption for an archive version or for current.
    /// </summary>
    /// <param name="ProjectNo">The project number.</param>
    /// <param name="VersionNo">The archive version. Ignored when IsCurrent is true.</param>
    /// <param name="IsCurrent">Whether the side is the current figures.</param>
    /// <returns>The caption.</returns>
    procedure VersionDescription(ProjectNo: Code[20]; VersionNo: Integer; IsCurrent: Boolean): Text
    var
        Snapshot: Record "BGB Project Snapshot";
        JobArchive: Record "Job Archive";
    begin
        if IsCurrent then
            exit(CurrentLbl);
        if Snapshot.Get(ProjectNo, VersionNo) then
            exit(StrSubstNo(VersionAtLbl, VersionNo, Snapshot."Run At"));
        if JobArchive.Get(ProjectNo, VersionNo) then
            exit(StrSubstNo(VersionAtLbl, VersionNo, CreateDateTime(JobArchive."Date Archived", JobArchive."Time Archived")));
        exit(StrSubstNo(VersionLbl, VersionNo));
    end;

    /// <summary>
    /// Returns the highest archive version of the project, preferring a snapshot and otherwise the project archive.
    /// </summary>
    /// <param name="ProjectNo">The project number.</param>
    /// <returns>The version number, or zero when the project has no archive.</returns>
    procedure LatestVersionNo(ProjectNo: Code[20]): Integer
    var
        Snapshot: Record "BGB Project Snapshot";
        JobArchive: Record "Job Archive";
    begin
        Snapshot.SetRange("Job No.", ProjectNo);
        if Snapshot.FindLast() then
            exit(Snapshot."Version No.");
        JobArchive.SetRange("No.", ProjectNo);
        if JobArchive.FindLast() then
            exit(JobArchive."Version No.");
        exit(0);
    end;

    /// <summary>
    /// Fills the compare buffer for one project. Side B is the current figures when CompareToCurrent is true.
    /// Projects mode lists the selected project and its archived and current descendants. Tasks mode lists the tasks of the selected project.
    /// A version without a snapshot falls back to the project task archive totals and is marked no breakdown.
    /// </summary>
    /// <param name="ProjectNo">The project, or the top project in projects mode.</param>
    /// <param name="VersionA">Archive version A.</param>
    /// <param name="VersionB">Archive version B. Ignored when CompareToCurrent is true.</param>
    /// <param name="CompareToCurrent">True to compare version A with the current figures.</param>
    /// <param name="RowMode">Tasks or projects.</param>
    /// <param name="AmountView">Total, or one of Resource, Item and G/L Account.</param>
    /// <param name="CompareBuffer">Returns the rows, including a total.</param>
    procedure BuildCompare(ProjectNo: Code[20]; VersionA: Integer; VersionB: Integer; CompareToCurrent: Boolean; RowMode: Enum "BGB Version Row Mode"; AmountView: Enum "BGB Version Amount View"; var CompareBuffer: Record "BGB Version Compare Buffer" temporary)
    var
        TempAnalysis: Record "BGB Project Analysis Buffer" temporary;
        RunA: Guid;
        RunB: Guid;
        HasRunA: Boolean;
        HasRunB: Boolean;
    begin
        if not VersionExists(ProjectNo, VersionA) then
            Error(VersionNotFoundErr, ProjectNo, VersionA);
        if not CompareToCurrent then
            if not VersionExists(ProjectNo, VersionB) then
                Error(VersionNotFoundErr, ProjectNo, VersionB);
        HasRunA := TryGetRun(ProjectNo, VersionA, RunA);
        if not CompareToCurrent then
            HasRunB := TryGetRun(ProjectNo, VersionB, RunB);
        LoadCurrentAnalysis(ProjectNo, TempAnalysis);

        CompareBuffer.Reset();
        CompareBuffer.DeleteAll(false);
        if RowMode = RowMode::Tasks then
            BuildTaskRows(CompareBuffer, ProjectNo, VersionA, VersionB, CompareToCurrent, HasRunA, RunA, HasRunB, RunB, AmountView)
        else
            BuildProjectRows(CompareBuffer, TempAnalysis, ProjectNo, VersionA, VersionB, CompareToCurrent, HasRunA, RunA, HasRunB, RunB, AmountView);
        AddTotalRow(CompareBuffer);
        CompareBuffer.Reset();
    end;

    /// <summary>
    /// Fills one row per archive run or legacy version of the project, oldest first, and a current row last.
    /// Each row has the key totals, the change since the previous row, usage cost as a percentage of budget cost
    /// and invoiced price as a percentage of billable price.
    /// </summary>
    /// <param name="ProjectNo">The project.</param>
    /// <param name="UseHierarchyTotals">True to use the rolled-up hierarchy totals; false to use the project's own totals.</param>
    /// <param name="TrendBuffer">Returns the rows.</param>
    procedure BuildTrend(ProjectNo: Code[20]; UseHierarchyTotals: Boolean; var TrendBuffer: Record "BGB Version Trend Buffer" temporary)
    var
        TempAnalysis: Record "BGB Project Analysis Buffer" temporary;
        Previous: array[8] of Decimal;
        HasPrevious: Boolean;
        SortOrder: Integer;
    begin
        TrendBuffer.Reset();
        TrendBuffer.DeleteAll(false);
        InsertSnapshotTrendRows(TrendBuffer, ProjectNo, UseHierarchyTotals);
        InsertLegacyTrendRows(TrendBuffer, ProjectNo);
        ApplyTrendOrder(TrendBuffer, Previous, HasPrevious, SortOrder);
        AppendCurrentTrendRow(TrendBuffer, ProjectNo, UseHierarchyTotals, TempAnalysis, Previous, HasPrevious, SortOrder);
        TrendBuffer.Reset();
        TrendBuffer.SetCurrentKey("Sort Order");
    end;

    /// <summary>
    /// Fills one row per project task, archive version and the current figures for the projects in the filter.
    /// Without a project filter, every top-level project is included with its subprojects.
    /// </summary>
    /// <param name="JobFilter">The project filter. Date filters are ignored; current is everything posted up to now.</param>
    /// <param name="ReportBuffer">Returns the rows.</param>
    procedure BuildVersionReport(var JobFilter: Record Job; var ReportBuffer: Record "BGB Version Report Buffer" temporary)
    var
        ProjectNo: Code[20];
        NextEntry: Integer;
    begin
        ReportBuffer.Reset();
        ReportBuffer.DeleteAll(false);
        foreach ProjectNo in CollectReportProjects(JobFilter) do
            EmitProject(ReportBuffer, ProjectNo, NextEntry);
        ReportBuffer.Reset();
    end;

    local procedure BuildTaskRows(var CompareBuffer: Record "BGB Version Compare Buffer" temporary; ProjectNo: Code[20]; VersionA: Integer; VersionB: Integer; CompareToCurrent: Boolean; HasRunA: Boolean; RunA: Guid; HasRunB: Boolean; RunB: Guid; AmountView: Enum "BGB Version Amount View")
    var
        TempTask: Record "BGB Project Task Snapshot" temporary;
        NextEntry: Integer;
    begin
        CollectTasks(TempTask, ProjectNo, VersionA, VersionB, CompareToCurrent, HasRunA, RunA, HasRunB, RunB);
        if TempTask.FindSet() then
            repeat
                AddTaskRow(CompareBuffer, TempTask."Job Task No.", ProjectNo, VersionA, VersionB, CompareToCurrent, HasRunA, RunA, HasRunB, RunB, AmountView, NextEntry);
            until TempTask.Next() = 0;
    end;

    local procedure BuildProjectRows(var CompareBuffer: Record "BGB Version Compare Buffer" temporary; var TempAnalysis: Record "BGB Project Analysis Buffer" temporary; RootNo: Code[20]; VersionA: Integer; VersionB: Integer; CompareToCurrent: Boolean; HasRunA: Boolean; RunA: Guid; HasRunB: Boolean; RunB: Guid; AmountView: Enum "BGB Version Amount View")
    var
        TempOrder: Record "BGB Project Snapshot" temporary;
        NextEntry: Integer;
    begin
        CollectProjects(TempOrder, RootNo, HasRunA, RunA, HasRunB, RunB);
        TempOrder.SetCurrentKey(Level, "Job No.");
        if TempOrder.FindSet() then
            repeat
                AddProjectRow(CompareBuffer, TempAnalysis, TempOrder."Job No.", TempOrder.Level, VersionA, VersionB, CompareToCurrent, HasRunA, RunA, HasRunB, RunB, AmountView, NextEntry);
            until TempOrder.Next() = 0;
    end;

    local procedure AddTaskRow(var CompareBuffer: Record "BGB Version Compare Buffer" temporary; TaskNo: Code[20]; ProjectNo: Code[20]; VersionA: Integer; VersionB: Integer; CompareToCurrent: Boolean; HasRunA: Boolean; RunA: Guid; HasRunB: Boolean; RunB: Guid; AmountView: Enum "BGB Version Amount View"; var NextEntry: Integer)
    var
        AmountsA: array[8] of Decimal;
        AmountsB: array[8] of Decimal;
        Description: Text[100];
        TaskType: Enum "Job Task Type";
        VersionNoA: Integer;
        VersionNoB: Integer;
        NoBreakdown: Boolean;
        DuringDelete: Boolean;
        SideBreakdown: Boolean;
        SideDelete: Boolean;
    begin
        LoadTaskSide(ProjectNo, TaskNo, false, HasRunA, RunA, VersionA, AmountView, AmountsA, Description, TaskType, VersionNoA, SideBreakdown, SideDelete);
        NoBreakdown := SideBreakdown;
        DuringDelete := SideDelete;
        if CompareToCurrent then
            LoadTaskSide(ProjectNo, TaskNo, true, false, RunB, 0, AmountView, AmountsB, Description, TaskType, VersionNoB, SideBreakdown, SideDelete)
        else
            LoadTaskSide(ProjectNo, TaskNo, false, HasRunB, RunB, VersionB, AmountView, AmountsB, Description, TaskType, VersionNoB, SideBreakdown, SideDelete);
        NoBreakdown := NoBreakdown or SideBreakdown;
        DuringDelete := DuringDelete or SideDelete;
        NextEntry += 1;
        InsertCompareRow(CompareBuffer, NextEntry, "BGB Version Row Kind"::Task, ProjectNo, TaskNo, Description, 0, TaskType, TaskType = TaskType::Posting, NoBreakdown, DuringDelete, VersionNoA, VersionNoB, AmountsA, AmountsB);
    end;

    local procedure AddProjectRow(var CompareBuffer: Record "BGB Version Compare Buffer" temporary; var TempAnalysis: Record "BGB Project Analysis Buffer" temporary; ProjectNo: Code[20]; Level: Integer; VersionA: Integer; VersionB: Integer; CompareToCurrent: Boolean; HasRunA: Boolean; RunA: Guid; HasRunB: Boolean; RunB: Guid; AmountView: Enum "BGB Version Amount View"; var NextEntry: Integer)
    var
        AmountsA: array[8] of Decimal;
        AmountsB: array[8] of Decimal;
        Description: Text[100];
        VersionNoA: Integer;
        VersionNoB: Integer;
        NoBreakdown: Boolean;
        DuringDelete: Boolean;
        SideBreakdown: Boolean;
        SideDelete: Boolean;
    begin
        LoadProjectSide(TempAnalysis, ProjectNo, false, HasRunA, RunA, VersionA, AmountView, AmountsA, Description, VersionNoA, SideBreakdown, SideDelete);
        NoBreakdown := SideBreakdown;
        DuringDelete := SideDelete;
        if CompareToCurrent then
            LoadProjectSide(TempAnalysis, ProjectNo, true, false, RunB, 0, AmountView, AmountsB, Description, VersionNoB, SideBreakdown, SideDelete)
        else
            LoadProjectSide(TempAnalysis, ProjectNo, false, HasRunB, RunB, VersionB, AmountView, AmountsB, Description, VersionNoB, SideBreakdown, SideDelete);
        NoBreakdown := NoBreakdown or SideBreakdown;
        DuringDelete := DuringDelete or SideDelete;
        NextEntry += 1;
        InsertCompareRow(CompareBuffer, NextEntry, "BGB Version Row Kind"::Project, ProjectNo, '', Description, Level, "Job Task Type"::Posting, true, NoBreakdown, DuringDelete, VersionNoA, VersionNoB, AmountsA, AmountsB);
    end;

    local procedure LoadTaskSide(ProjectNo: Code[20]; TaskNo: Code[20]; IsCurrent: Boolean; HasRun: Boolean; RunId: Guid; LegacyVersion: Integer; AmountView: Enum "BGB Version Amount View"; var Amounts: array[8] of Decimal; var Description: Text[100]; var TaskType: Enum "Job Task Type"; var VersionNo: Integer; var NoBreakdown: Boolean; var DuringDelete: Boolean)
    var
        TaskSnapshot: Record "BGB Project Task Snapshot";
        ProjectSnapshot: Record "BGB Project Snapshot";
        JobTaskArchive: Record "Job Task Archive";
        JobTask: Record "Job Task";
        ProjectArchiveMgt: Codeunit "BGB Project Archive Mgt.";
        RecRef: RecordRef;
    begin
        Clear(Amounts);
        NoBreakdown := false;
        DuringDelete := false;
        VersionNo := 0;
        if IsCurrent then begin
            if JobTask.Get(ProjectNo, TaskNo) then begin
                Description := JobTask.Description;
                TaskType := JobTask."Job Task Type";
            end;
            ProjectArchiveMgt.CalculateTaskAmounts(ProjectNo, TaskNo, 0, false, TaskSnapshot);
            RecRef.GetTable(TaskSnapshot);
            ReadOwnMeasures(RecRef, AmountView, Amounts);
            exit;
        end;
        if HasRun then begin
            TaskSnapshot.SetRange("Run ID", RunId);
            TaskSnapshot.SetRange("Job No.", ProjectNo);
            TaskSnapshot.SetRange("Job Task No.", TaskNo);
            if TaskSnapshot.FindFirst() then begin
                Description := TaskSnapshot.Description;
                TaskType := TaskSnapshot."Job Task Type";
                VersionNo := TaskSnapshot."Version No.";
                RecRef.GetTable(TaskSnapshot);
                ReadOwnMeasures(RecRef, AmountView, Amounts);
            end;
            ProjectSnapshot.SetRange("Run ID", RunId);
            ProjectSnapshot.SetRange("Job No.", ProjectNo);
            if ProjectSnapshot.FindFirst() then
                DuringDelete := ProjectSnapshot."During Project Delete";
            exit;
        end;
        NoBreakdown := true;
        VersionNo := LegacyVersion;
        if not JobTaskArchive.Get(ProjectNo, TaskNo, LegacyVersion) then
            exit;
        ProjectArchiveMgt.FillFallbackTask(JobTaskArchive, TaskSnapshot);
        Description := TaskSnapshot.Description;
        TaskType := TaskSnapshot."Job Task Type";
        RecRef.GetTable(TaskSnapshot);
        ReadOwnMeasures(RecRef, AmountView, Amounts);
    end;

    local procedure LoadProjectSide(var TempAnalysis: Record "BGB Project Analysis Buffer" temporary; ProjectNo: Code[20]; IsCurrent: Boolean; HasRun: Boolean; RunId: Guid; LegacyVersion: Integer; AmountView: Enum "BGB Version Amount View"; var Amounts: array[8] of Decimal; var Description: Text[100]; var VersionNo: Integer; var NoBreakdown: Boolean; var DuringDelete: Boolean)
    var
        Snapshot: Record "BGB Project Snapshot";
        RecRef: RecordRef;
    begin
        Clear(Amounts);
        NoBreakdown := false;
        DuringDelete := false;
        VersionNo := 0;
        if IsCurrent then begin
            TempAnalysis.SetRange("Project No.", ProjectNo);
            if TempAnalysis.FindFirst() then begin
                Description := TempAnalysis.Description;
                RecRef.GetTable(TempAnalysis);
                ReadOwnMeasures(RecRef, AmountView, Amounts);
            end;
            TempAnalysis.SetRange("Project No.");
            exit;
        end;
        if HasRun then begin
            Snapshot.SetRange("Run ID", RunId);
            Snapshot.SetRange("Job No.", ProjectNo);
            if Snapshot.FindFirst() then begin
                Description := Snapshot.Description;
                VersionNo := Snapshot."Version No.";
                DuringDelete := Snapshot."During Project Delete";
                RecRef.GetTable(Snapshot);
                ReadOwnMeasures(RecRef, AmountView, Amounts);
            end;
            exit;
        end;
        NoBreakdown := true;
        VersionNo := LegacyVersion;
        LoadLegacyProjectAmounts(ProjectNo, LegacyVersion, AmountView, Amounts, Description);
    end;

    local procedure LoadLegacyProjectAmounts(ProjectNo: Code[20]; VersionNo: Integer; AmountView: Enum "BGB Version Amount View"; var Amounts: array[8] of Decimal; var Description: Text[100])
    var
        JobArchive: Record "Job Archive";
        JobTaskArchive: Record "Job Task Archive";
        TaskSnapshot: Record "BGB Project Task Snapshot";
        ProjectArchiveMgt: Codeunit "BGB Project Archive Mgt.";
        RecRef: RecordRef;
        Part: array[8] of Decimal;
    begin
        if JobArchive.Get(ProjectNo, VersionNo) then
            Description := JobArchive.Description;
        JobTaskArchive.SetRange("Job No.", ProjectNo);
        JobTaskArchive.SetRange("Version No.", VersionNo);
        JobTaskArchive.SetRange("Job Task Type", JobTaskArchive."Job Task Type"::Posting);
        if JobTaskArchive.FindSet() then
            repeat
                ProjectArchiveMgt.FillFallbackTask(JobTaskArchive, TaskSnapshot);
                RecRef.GetTable(TaskSnapshot);
                ReadOwnMeasures(RecRef, AmountView, Part);
                AddArrays(Amounts, Part);
            until JobTaskArchive.Next() = 0;
    end;

    local procedure CollectTasks(var TempTask: Record "BGB Project Task Snapshot" temporary; ProjectNo: Code[20]; VersionA: Integer; VersionB: Integer; CompareToCurrent: Boolean; HasRunA: Boolean; RunA: Guid; HasRunB: Boolean; RunB: Guid)
    begin
        if HasRunA then
            AddTasksFromSnapshot(TempTask, ProjectNo, RunA)
        else
            AddTasksFromArchive(TempTask, ProjectNo, VersionA);
        if CompareToCurrent then
            AddTasksFromJob(TempTask, ProjectNo)
        else
            if HasRunB then
                AddTasksFromSnapshot(TempTask, ProjectNo, RunB)
            else
                AddTasksFromArchive(TempTask, ProjectNo, VersionB);
    end;

    local procedure AddTasksFromSnapshot(var TempTask: Record "BGB Project Task Snapshot" temporary; ProjectNo: Code[20]; RunId: Guid)
    var
        TaskSnapshot: Record "BGB Project Task Snapshot";
    begin
        TaskSnapshot.SetRange("Run ID", RunId);
        TaskSnapshot.SetRange("Job No.", ProjectNo);
        if TaskSnapshot.FindSet() then
            repeat
                RememberTask(TempTask, ProjectNo, TaskSnapshot."Job Task No.");
            until TaskSnapshot.Next() = 0;
    end;

    local procedure AddTasksFromArchive(var TempTask: Record "BGB Project Task Snapshot" temporary; ProjectNo: Code[20]; VersionNo: Integer)
    var
        JobTaskArchive: Record "Job Task Archive";
    begin
        JobTaskArchive.SetRange("Job No.", ProjectNo);
        JobTaskArchive.SetRange("Version No.", VersionNo);
        if JobTaskArchive.FindSet() then
            repeat
                RememberTask(TempTask, ProjectNo, JobTaskArchive."Job Task No.");
            until JobTaskArchive.Next() = 0;
    end;

    local procedure AddTasksFromJob(var TempTask: Record "BGB Project Task Snapshot" temporary; ProjectNo: Code[20])
    var
        JobTask: Record "Job Task";
    begin
        JobTask.SetRange("Job No.", ProjectNo);
        if JobTask.FindSet() then
            repeat
                RememberTask(TempTask, ProjectNo, JobTask."Job Task No.");
            until JobTask.Next() = 0;
    end;

    local procedure RememberTask(var TempTask: Record "BGB Project Task Snapshot" temporary; ProjectNo: Code[20]; TaskNo: Code[20])
    begin
        if TempTask.Get(ProjectNo, 0, TaskNo) then
            exit;
        TempTask.Init();
        TempTask."Job No." := ProjectNo;
        TempTask."Version No." := 0;
        TempTask."Job Task No." := TaskNo;
        TempTask.Insert(false);
    end;

    local procedure CollectProjects(var TempOrder: Record "BGB Project Snapshot" temporary; RootNo: Code[20]; HasRunA: Boolean; RunA: Guid; HasRunB: Boolean; RunB: Guid)
    var
        ProjectHierarchyMgt: Codeunit "BGB Project Hierarchy Mgt.";
        ProjectNo: Code[20];
    begin
        foreach ProjectNo in ProjectHierarchyMgt.GetProjectAndDescendants(RootNo) do
            RememberProject(TempOrder, ProjectNo, ProjectLevel(ProjectNo, HasRunA, RunA, HasRunB, RunB));
        if HasRunA then
            AddArchivedTree(TempOrder, RootNo, RunA);
        if HasRunB then
            AddArchivedTree(TempOrder, RootNo, RunB);
    end;

    local procedure AddArchivedTree(var TempOrder: Record "BGB Project Snapshot" temporary; RootNo: Code[20]; RunId: Guid)
    var
        Snapshot: Record "BGB Project Snapshot";
    begin
        Snapshot.SetRange("Run ID", RunId);
        if Snapshot.FindSet() then
            repeat
                if InArchivedTree(RunId, RootNo, Snapshot."Job No.") then
                    RememberProject(TempOrder, Snapshot."Job No.", Snapshot.Level);
            until Snapshot.Next() = 0;
    end;

    local procedure InArchivedTree(RunId: Guid; RootNo: Code[20]; ProjectNo: Code[20]): Boolean
    var
        Snapshot: Record "BGB Project Snapshot";
        CurrentNo: Code[20];
        Steps: Integer;
    begin
        CurrentNo := ProjectNo;
        while CurrentNo <> '' do begin
            if CurrentNo = RootNo then
                exit(true);
            Steps += 1;
            if Steps > 10000 then
                exit(false);
            Snapshot.SetRange("Run ID", RunId);
            Snapshot.SetRange("Job No.", CurrentNo);
            if not Snapshot.FindFirst() then
                exit(false);
            CurrentNo := Snapshot."Parent Project No.";
        end;
        exit(false);
    end;

    local procedure RememberProject(var TempOrder: Record "BGB Project Snapshot" temporary; ProjectNo: Code[20]; Level: Integer)
    begin
        if TempOrder.Get(ProjectNo, 0) then
            exit;
        TempOrder.Init();
        TempOrder."Job No." := ProjectNo;
        TempOrder."Version No." := 0;
        TempOrder.Level := Level;
        TempOrder.Insert(false);
    end;

    local procedure ProjectLevel(ProjectNo: Code[20]; HasRunA: Boolean; RunA: Guid; HasRunB: Boolean; RunB: Guid): Integer
    var
        Job: Record Job;
        Snapshot: Record "BGB Project Snapshot";
        ProjectAnalysisMgt: Codeunit "BGB Project Analysis Mgt.";
    begin
        if HasRunA then
            if SnapshotInRun(Snapshot, RunA, ProjectNo) then
                exit(Snapshot.Level);
        if HasRunB then
            if SnapshotInRun(Snapshot, RunB, ProjectNo) then
                exit(Snapshot.Level);
        if Job.Get(ProjectNo) then
            exit(ProjectAnalysisMgt.GetLevel(ProjectNo));
        exit(0);
    end;

    local procedure SnapshotInRun(var Snapshot: Record "BGB Project Snapshot"; RunId: Guid; ProjectNo: Code[20]): Boolean
    begin
        Snapshot.SetRange("Run ID", RunId);
        Snapshot.SetRange("Job No.", ProjectNo);
        exit(Snapshot.FindFirst());
    end;

    local procedure InsertCompareRow(var CompareBuffer: Record "BGB Version Compare Buffer" temporary; EntryNo: Integer; RowKind: Enum "BGB Version Row Kind"; ProjectNo: Code[20]; TaskNo: Code[20]; Description: Text[100]; Level: Integer; TaskType: Enum "Job Task Type"; IncludeInTotal: Boolean; NoBreakdown: Boolean; DuringDelete: Boolean; VersionNoA: Integer; VersionNoB: Integer; AmountsA: array[8] of Decimal; AmountsB: array[8] of Decimal)
    begin
        CompareBuffer.Init();
        CompareBuffer."Entry No." := EntryNo;
        CompareBuffer."Row Kind" := RowKind;
        CompareBuffer."Project No." := ProjectNo;
        CompareBuffer."Job Task No." := TaskNo;
        CompareBuffer.Description := Description;
        CompareBuffer.Level := Level;
        CompareBuffer."Job Task Type" := TaskType;
        CompareBuffer."Include in Total" := IncludeInTotal;
        CompareBuffer."No Breakdown" := NoBreakdown;
        CompareBuffer."During Project Delete" := DuringDelete;
        CompareBuffer."Version No. A" := VersionNoA;
        CompareBuffer."Version No. B" := VersionNoB;
        WriteCompareAmounts(CompareBuffer, AmountsA, AmountsB);
        CompareBuffer.Insert(false);
    end;

    local procedure WriteCompareAmounts(var CompareBuffer: Record "BGB Version Compare Buffer" temporary; AmountsA: array[8] of Decimal; AmountsB: array[8] of Decimal)
    var
        RecRef: RecordRef;
        i: Integer;
    begin
        RecRef.GetTable(CompareBuffer);
        for i := 1 to 8 do begin
            RecRef.Field(19 + i).Value(AmountsA[i]);
            RecRef.Field(29 + i).Value(AmountsB[i]);
            RecRef.Field(39 + i).Value(CalcDifference(AmountsA[i], AmountsB[i]));
            RecRef.Field(49 + i).Value(CalcChangePct(AmountsA[i], AmountsB[i]));
        end;
        RecRef.SetTable(CompareBuffer);
    end;

    local procedure AddTotalRow(var CompareBuffer: Record "BGB Version Compare Buffer" temporary)
    var
        AmountsA: array[8] of Decimal;
        AmountsB: array[8] of Decimal;
        DuringDelete: Boolean;
        NoBreakdown: Boolean;
        NextEntry: Integer;
    begin
        CompareBuffer.Reset();
        if CompareBuffer.FindLast() then
            NextEntry := CompareBuffer."Entry No.";
        SumIncludedRows(CompareBuffer, AmountsA, AmountsB, NoBreakdown, DuringDelete);
        NextEntry += 1;
        InsertCompareRow(CompareBuffer, NextEntry, "BGB Version Row Kind"::Total, '', '', TotalLbl, 0, "Job Task Type"::Posting, false, NoBreakdown, DuringDelete, 0, 0, AmountsA, AmountsB);
    end;

    local procedure SumIncludedRows(var CompareBuffer: Record "BGB Version Compare Buffer" temporary; var AmountsA: array[8] of Decimal; var AmountsB: array[8] of Decimal; var NoBreakdown: Boolean; var DuringDelete: Boolean)
    var
        RecRef: RecordRef;
        PartA: array[8] of Decimal;
        PartB: array[8] of Decimal;
        i: Integer;
    begin
        if CompareBuffer.FindSet() then
            repeat
                SumOneIncludedRow(CompareBuffer, RecRef, PartA, PartB, AmountsA, AmountsB, NoBreakdown, DuringDelete, i);
            until CompareBuffer.Next() = 0;
    end;

    local procedure SumOneIncludedRow(CompareBuffer: Record "BGB Version Compare Buffer" temporary; var RecRef: RecordRef; var PartA: array[8] of Decimal; var PartB: array[8] of Decimal; var AmountsA: array[8] of Decimal; var AmountsB: array[8] of Decimal; var NoBreakdown: Boolean; var DuringDelete: Boolean; var i: Integer)
    begin
        if not CompareBuffer."Include in Total" then
            exit;
        RecRef.GetTable(CompareBuffer);
        for i := 1 to 8 do begin
            PartA[i] := RecRef.Field(19 + i).Value();
            PartB[i] := RecRef.Field(29 + i).Value();
        end;
        AddArrays(AmountsA, PartA);
        AddArrays(AmountsB, PartB);
        NoBreakdown := NoBreakdown or CompareBuffer."No Breakdown";
        DuringDelete := DuringDelete or CompareBuffer."During Project Delete";
    end;

    local procedure InsertSnapshotTrendRows(var TrendBuffer: Record "BGB Version Trend Buffer" temporary; ProjectNo: Code[20]; UseHierarchyTotals: Boolean)
    var
        Snapshot: Record "BGB Project Snapshot";
        RecRef: RecordRef;
        Amounts: array[8] of Decimal;
        NextEntry: Integer;
    begin
        if TrendBuffer.FindLast() then
            NextEntry := TrendBuffer."Entry No.";
        Snapshot.SetCurrentKey("Job No.", "Run At");
        Snapshot.SetRange("Job No.", ProjectNo);
        if Snapshot.FindSet() then
            repeat
                RecRef.GetTable(Snapshot);
                if UseHierarchyTotals then
                    ReadHierarchyMeasures(RecRef, Amounts)
                else
                    ReadOwnMeasures(RecRef, "BGB Version Amount View"::Total, Amounts);
                NextEntry += 1;
                InsertTrendRow(TrendBuffer, NextEntry, Snapshot."Run ID", Snapshot."Run At", Snapshot."Version No.", false, false, Snapshot."During Project Delete", StrSubstNo(VersionLbl, Snapshot."Version No."), Amounts);
            until Snapshot.Next() = 0;
    end;

    local procedure InsertLegacyTrendRows(var TrendBuffer: Record "BGB Version Trend Buffer" temporary; ProjectNo: Code[20])
    var
        JobArchive: Record "Job Archive";
        Snapshot: Record "BGB Project Snapshot";
        Amounts: array[8] of Decimal;
        Description: Text[100];
        NextEntry: Integer;
    begin
        if TrendBuffer.FindLast() then
            NextEntry := TrendBuffer."Entry No.";
        JobArchive.SetRange("No.", ProjectNo);
        if JobArchive.FindSet() then
            repeat
                if not Snapshot.Get(JobArchive."No.", JobArchive."Version No.") then begin
                    Clear(Amounts);
                    Clear(Description);
                    LoadLegacyProjectAmounts(ProjectNo, JobArchive."Version No.", "BGB Version Amount View"::Total, Amounts, Description);
                    NextEntry += 1;
                    InsertTrendRow(TrendBuffer, NextEntry, Snapshot."Run ID", CreateDateTime(JobArchive."Date Archived", JobArchive."Time Archived"), JobArchive."Version No.", false, true, false, StrSubstNo(VersionLbl, JobArchive."Version No."), Amounts);
                end;
            until JobArchive.Next() = 0;
    end;

    local procedure ApplyTrendOrder(var TrendBuffer: Record "BGB Version Trend Buffer" temporary; var Previous: array[8] of Decimal; var HasPrevious: Boolean; var SortOrder: Integer)
    var
        Amounts: array[8] of Decimal;
    begin
        HasPrevious := false;
        Clear(Previous);
        SortOrder := 0;
        TrendBuffer.Reset();
        TrendBuffer.SetCurrentKey("Run At", "Version No.");
        if TrendBuffer.FindSet(true) then
            repeat
                SortOrder += 1;
                TrendBuffer."Sort Order" := SortOrder;
                ReadTrendAmounts(TrendBuffer, Amounts);
                ApplyTrendDeltas(TrendBuffer, Previous, not HasPrevious);
                TrendBuffer.Modify(false);
                CopyAmounts(Amounts, Previous);
                HasPrevious := true;
            until TrendBuffer.Next() = 0;
    end;

    local procedure AppendCurrentTrendRow(var TrendBuffer: Record "BGB Version Trend Buffer" temporary; ProjectNo: Code[20]; UseHierarchyTotals: Boolean; var TempAnalysis: Record "BGB Project Analysis Buffer" temporary; Previous: array[8] of Decimal; HasPrevious: Boolean; SortOrder: Integer)
    var
        RecRef: RecordRef;
        Amounts: array[8] of Decimal;
        EmptyRunId: Guid;
        NextEntry: Integer;
    begin
        LoadCurrentAnalysis(ProjectNo, TempAnalysis);
        TempAnalysis.SetRange("Project No.", ProjectNo);
        if TempAnalysis.FindFirst() then begin
            RecRef.GetTable(TempAnalysis);
            if UseHierarchyTotals then
                ReadHierarchyMeasures(RecRef, Amounts)
            else
                ReadOwnMeasures(RecRef, "BGB Version Amount View"::Total, Amounts);
        end;
        TrendBuffer.Reset();
        if TrendBuffer.FindLast() then
            NextEntry := TrendBuffer."Entry No.";
        NextEntry += 1;
        InsertTrendRow(TrendBuffer, NextEntry, EmptyRunId, CurrentDateTime(), 0, true, false, false, CurrentLbl, Amounts);
        TrendBuffer.Get(NextEntry);
        TrendBuffer."Sort Order" := SortOrder + 1;
        ApplyTrendDeltas(TrendBuffer, Previous, not HasPrevious);
        TrendBuffer.Modify(false);
    end;

    local procedure InsertTrendRow(var TrendBuffer: Record "BGB Version Trend Buffer" temporary; EntryNo: Integer; RunId: Guid; RunAt: DateTime; VersionNo: Integer; IsCurrent: Boolean; NoBreakdown: Boolean; DuringDelete: Boolean; Description: Text[100]; Amounts: array[8] of Decimal)
    begin
        TrendBuffer.Init();
        TrendBuffer."Entry No." := EntryNo;
        TrendBuffer."Run ID" := RunId;
        TrendBuffer."Run At" := RunAt;
        TrendBuffer."Version No." := VersionNo;
        TrendBuffer."Is Current" := IsCurrent;
        TrendBuffer."No Breakdown" := NoBreakdown;
        TrendBuffer."During Project Delete" := DuringDelete;
        TrendBuffer.Description := Description;
        ApplyTrendAmounts(TrendBuffer, Amounts);
        TrendBuffer.Insert(false);
    end;

    local procedure ApplyTrendAmounts(var TrendBuffer: Record "BGB Version Trend Buffer" temporary; Amounts: array[8] of Decimal)
    begin
        TrendBuffer."Budget Cost" := Amounts[1];
        TrendBuffer."Budget Price" := Amounts[2];
        TrendBuffer."Usage Cost" := Amounts[3];
        TrendBuffer."Usage Price" := Amounts[4];
        TrendBuffer."Billable Cost" := Amounts[5];
        TrendBuffer."Billable Price" := Amounts[6];
        TrendBuffer."Invoiced Cost" := Amounts[7];
        TrendBuffer."Invoiced Price" := Amounts[8];
        TrendBuffer."Usage % of Budget" := CalcRatioPct(Amounts[3], Amounts[1]);
        TrendBuffer."Invoiced % of Billable" := CalcRatioPct(Amounts[8], Amounts[6]);
    end;

    local procedure ApplyTrendDeltas(var TrendBuffer: Record "BGB Version Trend Buffer" temporary; Previous: array[8] of Decimal; First: Boolean)
    begin
        if First then begin
            TrendBuffer."Budget Cost Delta" := 0;
            TrendBuffer."Budget Price Delta" := 0;
            TrendBuffer."Usage Cost Delta" := 0;
            TrendBuffer."Usage Price Delta" := 0;
            TrendBuffer."Billable Cost Delta" := 0;
            TrendBuffer."Billable Price Delta" := 0;
            TrendBuffer."Invoiced Cost Delta" := 0;
            TrendBuffer."Invoiced Price Delta" := 0;
            exit;
        end;
        TrendBuffer."Budget Cost Delta" := CalcDifference(Previous[1], TrendBuffer."Budget Cost");
        TrendBuffer."Budget Price Delta" := CalcDifference(Previous[2], TrendBuffer."Budget Price");
        TrendBuffer."Usage Cost Delta" := CalcDifference(Previous[3], TrendBuffer."Usage Cost");
        TrendBuffer."Usage Price Delta" := CalcDifference(Previous[4], TrendBuffer."Usage Price");
        TrendBuffer."Billable Cost Delta" := CalcDifference(Previous[5], TrendBuffer."Billable Cost");
        TrendBuffer."Billable Price Delta" := CalcDifference(Previous[6], TrendBuffer."Billable Price");
        TrendBuffer."Invoiced Cost Delta" := CalcDifference(Previous[7], TrendBuffer."Invoiced Cost");
        TrendBuffer."Invoiced Price Delta" := CalcDifference(Previous[8], TrendBuffer."Invoiced Price");
    end;

    local procedure ReadTrendAmounts(TrendBuffer: Record "BGB Version Trend Buffer"; var Amounts: array[8] of Decimal)
    begin
        Amounts[1] := TrendBuffer."Budget Cost";
        Amounts[2] := TrendBuffer."Budget Price";
        Amounts[3] := TrendBuffer."Usage Cost";
        Amounts[4] := TrendBuffer."Usage Price";
        Amounts[5] := TrendBuffer."Billable Cost";
        Amounts[6] := TrendBuffer."Billable Price";
        Amounts[7] := TrendBuffer."Invoiced Cost";
        Amounts[8] := TrendBuffer."Invoiced Price";
    end;

    local procedure EmitProject(var ReportBuffer: Record "BGB Version Report Buffer" temporary; ProjectNo: Code[20]; var NextEntry: Integer)
    var
        Snapshot: Record "BGB Project Snapshot";
        JobArchive: Record "Job Archive";
    begin
        Snapshot.SetCurrentKey("Job No.", "Run At");
        Snapshot.SetRange("Job No.", ProjectNo);
        if Snapshot.FindSet() then
            repeat
                EmitSnapshotVersion(ReportBuffer, Snapshot, NextEntry);
            until Snapshot.Next() = 0;
        JobArchive.SetRange("No.", ProjectNo);
        if JobArchive.FindSet() then
            repeat
                if not Snapshot.Get(JobArchive."No.", JobArchive."Version No.") then
                    EmitLegacyVersion(ReportBuffer, JobArchive, NextEntry);
            until JobArchive.Next() = 0;
        EmitCurrentVersion(ReportBuffer, ProjectNo, NextEntry);
    end;

    local procedure EmitSnapshotVersion(var ReportBuffer: Record "BGB Version Report Buffer" temporary; Snapshot: Record "BGB Project Snapshot"; var NextEntry: Integer)
    var
        TaskSnapshot: Record "BGB Project Task Snapshot";
        Emitted: Boolean;
    begin
        TaskSnapshot.SetRange("Job No.", Snapshot."Job No.");
        TaskSnapshot.SetRange("Version No.", Snapshot."Version No.");
        if TaskSnapshot.FindSet() then
            repeat
                Emitted := true;
                EmitTaskSnapshot(ReportBuffer, Snapshot, TaskSnapshot, NextEntry);
            until TaskSnapshot.Next() = 0;
        if not Emitted then
            EmitProjectOnly(ReportBuffer, Snapshot, NextEntry);
    end;

    local procedure EmitTaskSnapshot(var ReportBuffer: Record "BGB Version Report Buffer" temporary; Snapshot: Record "BGB Project Snapshot"; TaskSnapshot: Record "BGB Project Task Snapshot"; var NextEntry: Integer)
    var
        ReportRef: RecordRef;
        TaskRef: RecordRef;
    begin
        NextEntry += 1;
        ReportBuffer.Init();
        ReportBuffer."Entry No." := NextEntry;
        ReportBuffer."Project No." := Snapshot."Job No.";
        ReportBuffer."Job Task No." := TaskSnapshot."Job Task No.";
        ReportBuffer.Description := TaskSnapshot.Description;
        ReportBuffer."Parent Project No." := Snapshot."Parent Project No.";
        ReportBuffer.Level := Snapshot.Level;
        ReportBuffer."Run At" := Snapshot."Run At";
        ReportBuffer."Version No." := Snapshot."Version No.";
        ReportBuffer."During Project Delete" := Snapshot."During Project Delete";
        ReportBuffer."Run ID Text" := CopyStr(DelChr(Format(Snapshot."Run ID"), '=', '{}'), 1, MaxStrLen(ReportBuffer."Run ID Text"));
        ReportRef.GetTable(ReportBuffer);
        TaskRef.GetTable(TaskSnapshot);
        CopyFieldRange(ReportRef, TaskRef, 100, 131);
        ReportRef.SetTable(ReportBuffer);
        ReportBuffer.Insert(false);
    end;

    local procedure EmitProjectOnly(var ReportBuffer: Record "BGB Version Report Buffer" temporary; Snapshot: Record "BGB Project Snapshot"; var NextEntry: Integer)
    var
        ReportRef: RecordRef;
        SnapshotRef: RecordRef;
    begin
        NextEntry += 1;
        ReportBuffer.Init();
        ReportBuffer."Entry No." := NextEntry;
        ReportBuffer."Project No." := Snapshot."Job No.";
        ReportBuffer.Description := Snapshot.Description;
        ReportBuffer."Parent Project No." := Snapshot."Parent Project No.";
        ReportBuffer.Level := Snapshot.Level;
        ReportBuffer."Run At" := Snapshot."Run At";
        ReportBuffer."Version No." := Snapshot."Version No.";
        ReportBuffer."During Project Delete" := Snapshot."During Project Delete";
        ReportBuffer."Run ID Text" := CopyStr(DelChr(Format(Snapshot."Run ID"), '=', '{}'), 1, MaxStrLen(ReportBuffer."Run ID Text"));
        ReportRef.GetTable(ReportBuffer);
        SnapshotRef.GetTable(Snapshot);
        CopyFieldRange(ReportRef, SnapshotRef, 100, 131);
        ReportRef.SetTable(ReportBuffer);
        ReportBuffer.Insert(false);
    end;

    local procedure EmitLegacyVersion(var ReportBuffer: Record "BGB Version Report Buffer" temporary; JobArchive: Record "Job Archive"; var NextEntry: Integer)
    var
        JobTaskArchive: Record "Job Task Archive";
        TaskSnapshot: Record "BGB Project Task Snapshot";
        ProjectArchiveMgt: Codeunit "BGB Project Archive Mgt.";
        ReportRef: RecordRef;
        TaskRef: RecordRef;
        Emitted: Boolean;
    begin
        JobTaskArchive.SetRange("Job No.", JobArchive."No.");
        JobTaskArchive.SetRange("Version No.", JobArchive."Version No.");
        if JobTaskArchive.FindSet() then
            repeat
                Emitted := true;
                ProjectArchiveMgt.FillFallbackTask(JobTaskArchive, TaskSnapshot);
                NextEntry += 1;
                ReportBuffer.Init();
                ReportBuffer."Entry No." := NextEntry;
                ReportBuffer."Project No." := JobArchive."No.";
                ReportBuffer."Job Task No." := JobTaskArchive."Job Task No.";
                ReportBuffer.Description := JobTaskArchive.Description;
                ReportBuffer."Run At" := CreateDateTime(JobArchive."Date Archived", JobArchive."Time Archived");
                ReportBuffer."Version No." := JobArchive."Version No.";
                ReportBuffer."No Breakdown" := true;
                ReportRef.GetTable(ReportBuffer);
                TaskRef.GetTable(TaskSnapshot);
                CopyFieldRange(ReportRef, TaskRef, 100, 131);
                ReportRef.SetTable(ReportBuffer);
                ReportBuffer.Insert(false);
            until JobTaskArchive.Next() = 0;
        if Emitted then
            exit;
        NextEntry += 1;
        ReportBuffer.Init();
        ReportBuffer."Entry No." := NextEntry;
        ReportBuffer."Project No." := JobArchive."No.";
        ReportBuffer.Description := JobArchive.Description;
        ReportBuffer."Run At" := CreateDateTime(JobArchive."Date Archived", JobArchive."Time Archived");
        ReportBuffer."Version No." := JobArchive."Version No.";
        ReportBuffer."No Breakdown" := true;
        ReportBuffer.Insert(false);
    end;

    local procedure EmitCurrentVersion(var ReportBuffer: Record "BGB Version Report Buffer" temporary; ProjectNo: Code[20]; var NextEntry: Integer)
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        TaskSnapshot: Record "BGB Project Task Snapshot";
        TempAnalysis: Record "BGB Project Analysis Buffer" temporary;
        ProjectArchiveMgt: Codeunit "BGB Project Archive Mgt.";
        ProjectAnalysisMgt: Codeunit "BGB Project Analysis Mgt.";
        ReportRef: RecordRef;
        TaskRef: RecordRef;
        AnalysisRef: RecordRef;
        Emitted: Boolean;
    begin
        if not Job.Get(ProjectNo) then
            exit;
        JobTask.SetRange("Job No.", ProjectNo);
        if JobTask.FindSet() then
            repeat
                Emitted := true;
                ProjectArchiveMgt.CalculateTaskAmounts(ProjectNo, JobTask."Job Task No.", 0, false, TaskSnapshot);
                NextEntry += 1;
                ReportBuffer.Init();
                ReportBuffer."Entry No." := NextEntry;
                ReportBuffer."Project No." := ProjectNo;
                ReportBuffer."Job Task No." := JobTask."Job Task No.";
                ReportBuffer.Description := JobTask.Description;
                ReportBuffer."Parent Project No." := Job."BGB Parent Project No.";
                ReportBuffer.Level := ProjectAnalysisMgt.GetLevel(ProjectNo);
                ReportBuffer."Run At" := CurrentDateTime();
                ReportBuffer."Is Current" := true;
                ReportRef.GetTable(ReportBuffer);
                TaskRef.GetTable(TaskSnapshot);
                CopyFieldRange(ReportRef, TaskRef, 100, 131);
                ReportRef.SetTable(ReportBuffer);
                ReportBuffer.Insert(false);
            until JobTask.Next() = 0;
        if Emitted then
            exit;
        LoadCurrentAnalysis(ProjectNo, TempAnalysis);
        TempAnalysis.SetRange("Project No.", ProjectNo);
        if not TempAnalysis.FindFirst() then
            exit;
        NextEntry += 1;
        ReportBuffer.Init();
        ReportBuffer."Entry No." := NextEntry;
        ReportBuffer."Project No." := ProjectNo;
        ReportBuffer.Description := Job.Description;
        ReportBuffer."Parent Project No." := Job."BGB Parent Project No.";
        ReportBuffer.Level := TempAnalysis.Level;
        ReportBuffer."Run At" := CurrentDateTime();
        ReportBuffer."Is Current" := true;
        ReportRef.GetTable(ReportBuffer);
        AnalysisRef.GetTable(TempAnalysis);
        CopyFieldRange(ReportRef, AnalysisRef, 100, 131);
        ReportRef.SetTable(ReportBuffer);
        ReportBuffer.Insert(false);
    end;

    local procedure CollectReportProjects(var JobFilter: Record Job) ProjectNos: List of [Code[20]]
    var
        RootJob: Record Job;
        ProjectHierarchyMgt: Codeunit "BGB Project Hierarchy Mgt.";
        ProjectNo: Code[20];
    begin
        RootJob.CopyFilters(JobFilter);
        if (RootJob.GetFilter("No.") = '') and (RootJob.GetFilter("BGB Parent Project No.") = '') then
            RootJob.SetRange("BGB Parent Project No.", '');
        RootJob.SetLoadFields("No.");
        if RootJob.FindSet() then
            repeat
                foreach ProjectNo in ProjectHierarchyMgt.GetProjectAndDescendants(RootJob."No.") do
                    if not ProjectNos.Contains(ProjectNo) then
                        ProjectNos.Add(ProjectNo);
            until RootJob.Next() = 0;
        exit(ProjectNos);
    end;

    local procedure LoadCurrentAnalysis(ProjectNo: Code[20]; var TempAnalysis: Record "BGB Project Analysis Buffer" temporary)
    var
        JobFilter: Record Job;
        ProjectAnalysisMgt: Codeunit "BGB Project Analysis Mgt.";
    begin
        if ProjectNo = '' then
            exit;
        if not JobFilter.Get(ProjectNo) then
            exit;
        JobFilter.SetRange("No.", ProjectNo);
        ProjectAnalysisMgt.BuildAnalysis(JobFilter, TempAnalysis, true);
    end;

    local procedure VersionExists(ProjectNo: Code[20]; VersionNo: Integer): Boolean
    var
        Snapshot: Record "BGB Project Snapshot";
        JobArchive: Record "Job Archive";
        JobTaskArchive: Record "Job Task Archive";
    begin
        if Snapshot.Get(ProjectNo, VersionNo) then
            exit(true);
        if JobArchive.Get(ProjectNo, VersionNo) then
            exit(true);
        JobTaskArchive.SetRange("Job No.", ProjectNo);
        JobTaskArchive.SetRange("Version No.", VersionNo);
        exit(not JobTaskArchive.IsEmpty());
    end;

    local procedure TryGetRun(ProjectNo: Code[20]; VersionNo: Integer; var RunId: Guid): Boolean
    var
        Snapshot: Record "BGB Project Snapshot";
    begin
        if not Snapshot.Get(ProjectNo, VersionNo) then
            exit(false);
        RunId := Snapshot."Run ID";
        exit(not IsNullGuid(RunId));
    end;

    local procedure ReadOwnMeasures(RecRef: RecordRef; AmountView: Enum "BGB Version Amount View"; var Amounts: array[8] of Decimal)
    var
        Offset: Integer;
    begin
        Offset := ViewOffset(AmountView);
        Amounts[1] := RecRef.Field(100 + Offset).Value();
        Amounts[2] := RecRef.Field(116 + Offset).Value();
        Amounts[3] := RecRef.Field(104 + Offset).Value();
        Amounts[4] := RecRef.Field(120 + Offset).Value();
        Amounts[5] := RecRef.Field(108 + Offset).Value();
        Amounts[6] := RecRef.Field(124 + Offset).Value();
        Amounts[7] := RecRef.Field(112 + Offset).Value();
        Amounts[8] := RecRef.Field(128 + Offset).Value();
    end;

    local procedure ReadHierarchyMeasures(RecRef: RecordRef; var Amounts: array[8] of Decimal)
    begin
        Amounts[1] := RecRef.Field(300).Value();
        Amounts[2] := RecRef.Field(304).Value();
        Amounts[3] := RecRef.Field(301).Value();
        Amounts[4] := RecRef.Field(305).Value();
        Amounts[5] := RecRef.Field(302).Value();
        Amounts[6] := RecRef.Field(306).Value();
        Amounts[7] := RecRef.Field(303).Value();
        Amounts[8] := RecRef.Field(307).Value();
    end;

    local procedure ViewOffset(AmountView: Enum "BGB Version Amount View"): Integer
    begin
        case AmountView of
            AmountView::Resource:
                exit(0);
            AmountView::Item:
                exit(1);
            AmountView::"G/L Account":
                exit(2);
        end;
        exit(3);
    end;

    local procedure CopyAmounts(Source: array[8] of Decimal; var Target: array[8] of Decimal)
    var
        i: Integer;
    begin
        for i := 1 to 8 do
            Target[i] := Source[i];
    end;

    local procedure AddArrays(var Target: array[8] of Decimal; Source: array[8] of Decimal)
    var
        i: Integer;
    begin
        for i := 1 to 8 do
            Target[i] += Source[i];
    end;

    local procedure CopyFieldRange(var ToRef: RecordRef; var FromRef: RecordRef; FromFieldNo: Integer; ToFieldNo: Integer)
    var
        FieldNo: Integer;
    begin
        for FieldNo := FromFieldNo to ToFieldNo do
            ToRef.Field(FieldNo).Value(FromRef.Field(FieldNo).Value());
    end;
}
