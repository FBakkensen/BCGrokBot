namespace FlemmingBakkensen.BCGrokBot.ProjectVersion;

using FlemmingBakkensen.BCGrokBot.ProjectAnalysis;
using FlemmingBakkensen.BCGrokBot.ProjectHierarchy;
using Microsoft.Projects.Project.Archive;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Journal;
using Microsoft.Projects.Project.Ledger;
using Microsoft.Projects.Project.Planning;

/// <summary>
/// Archives a project hierarchy as one run and stores project and task snapshots for every archive,
/// including the standard single-project archive. Snapshots follow project archive delete and rename.
/// </summary>
codeunit 50109 "BGB Project Archive Mgt."
{
    Access = Public;
    Permissions = tabledata Job = r,
                  tabledata "Job Ledger Entry" = r,
                  tabledata "Job Planning Line" = r,
                  tabledata "Job Planning Line Archive" = r,
                  tabledata "Job Task" = r,
                  tabledata "BGB Project Archive Run" = rimd,
                  tabledata "BGB Project Snapshot" = rimd,
                  tabledata "BGB Project Task Snapshot" = rid;

    var
        NotTopLevelErr: Label 'Project %1 has parent project %2. Archive Hierarchy can only be run on a top-level project.', Comment = '%1 = project number, %2 = parent project number';

    /// <summary>
    /// Archives the top-level project and all its descendants with StoreJob, under one archive run.
    /// </summary>
    /// <param name="Job">The top-level project. Its parent project number must be blank.</param>
    procedure ArchiveHierarchy(var Job: Record Job)
    var
        ArchiveRunContext: Codeunit "BGB Archive Run Context";
    begin
        if Job."BGB Parent Project No." <> '' then
            Error(NotTopLevelErr, Job."No.", Job."BGB Parent Project No.");
        ArchiveRunContext.Reset();
        ArchiveRunContext.BeginRun(CreateGuid(), CurrentDateTime(), Job."No.", true);
        ArchiveRunContext.SetInsideHierarchy(true);
        StoreActiveHierarchy();
        ArchiveRunContext.Reset();
    end;

    /// <summary>
    /// Archives every open top-level project (and its descendants) as its own run.
    /// </summary>
    /// <param name="ProjectNoFilter">Optional filter on the project number, for example 'BGB-V-*'. Blank includes every open top-level project.</param>
    procedure ArchiveOpenTopLevelHierarchies(ProjectNoFilter: Text)
    var
        Job: Record Job;
        ProjectNo: Code[20];
    begin
        foreach ProjectNo in GetOpenTopLevelProjectNos(ProjectNoFilter) do begin
            Job.Get(ProjectNo);
            ArchiveHierarchy(Job);
        end;
    end;

    /// <summary>
    /// Returns the open top-level projects matching the filter, in project number order.
    /// </summary>
    /// <param name="ProjectNoFilter">Optional filter on the project number. Blank includes every open top-level project.</param>
    /// <returns>The project numbers.</returns>
    procedure GetOpenTopLevelProjectNos(ProjectNoFilter: Text) ProjectNos: List of [Code[20]]
    var
        Job: Record Job;
    begin
        Job.SetCurrentKey("BGB Parent Project No.");
        Job.SetRange("BGB Parent Project No.", '');
        Job.SetRange(Status, Job.Status::Open);
        if ProjectNoFilter <> '' then
            Job.SetFilter("No.", ProjectNoFilter);
        Job.SetLoadFields("No.");
        if Job.FindSet() then
            repeat
                ProjectNos.Add(Job."No.");
            until Job.Next() = 0;
        exit(ProjectNos);
    end;

    /// <summary>
    /// Stores every project in the active hierarchy run.
    /// </summary>
    procedure StoreActiveHierarchy()
    var
        Job: Record Job;
        ArchiveRunContext: Codeunit "BGB Archive Run Context";
        ProjectHierarchyMgt: Codeunit "BGB Project Hierarchy Mgt.";
        JobArchiveManagement: Codeunit "Job Archive Management";
        ProjectNo: Code[20];
    begin
        foreach ProjectNo in ProjectHierarchyMgt.GetProjectAndDescendants(ArchiveRunContext.TopProjectNo()) do begin
            Job.Get(ProjectNo);
            JobArchiveManagement.StoreJob(Job, false);
        end;
    end;

    /// <summary>
    /// Writes the project and task snapshots for an archive version. Called from OnAfterStoreJob for every archive path.
    /// A snapshot taken outside an active hierarchy run starts its own run.
    /// </summary>
    /// <param name="Job">The project being archived.</param>
    /// <param name="JobArchive">The project archive version just stored.</param>
    procedure CaptureSnapshot(Job: Record Job; JobArchive: Record "Job Archive")
    var
        ArchiveRunContext: Codeunit "BGB Archive Run Context";
    begin
        if ArchiveRunContext.InsideHierarchyStore() then begin
            DoCapture(Job, JobArchive);
            exit;
        end;
        ArchiveRunContext.Reset();
        ArchiveRunContext.BeginRun(CreateGuid(), CurrentDateTime(), Job."No.", false);
        DoCapture(Job, JobArchive);
        ArchiveRunContext.EndRun();
    end;

    /// <summary>
    /// Fills usage, invoiced, budget and billable amounts on a task snapshot.
    /// Usage and invoiced are split from project ledger entries (sale amounts are sign-reversed, as in Job Calculate Statistics).
    /// Budget and billable are split from archived planning lines when UsePlanningArchive is true, otherwise from the current planning lines.
    /// </summary>
    /// <param name="JobNo">The project number.</param>
    /// <param name="JobTaskNo">The task number.</param>
    /// <param name="VersionNo">The archive version, used when UsePlanningArchive is true.</param>
    /// <param name="UsePlanningArchive">True to read budget and billable amounts from archived planning lines.</param>
    /// <param name="TaskSnapshot">Returns the amounts. Identity fields are left unchanged.</param>
    procedure CalculateTaskAmounts(JobNo: Code[20]; JobTaskNo: Code[20]; VersionNo: Integer; UsePlanningArchive: Boolean; var TaskSnapshot: Record "BGB Project Task Snapshot")
    begin
        ClearAmounts(TaskSnapshot);
        AddLedgerAmounts(JobNo, JobTaskNo, TaskSnapshot);
        if UsePlanningArchive then
            AddPlanningArchiveAmounts(JobNo, JobTaskNo, VersionNo, TaskSnapshot)
        else
            AddPlanningLineAmounts(JobNo, JobTaskNo, TaskSnapshot);
    end;

    /// <summary>
    /// Fills a task snapshot from a project task archive that has no snapshot.
    /// Totals are copied from the task archive (usage and invoiced) and from its archived planning lines (budget and billable).
    /// The Resource, Item and G/L amounts stay zero: there is no breakdown.
    /// </summary>
    /// <param name="JobTaskArchive">The archived task.</param>
    /// <param name="TaskSnapshot">Returns the totals and the task identity.</param>
    procedure FillFallbackTask(JobTaskArchive: Record "Job Task Archive"; var TaskSnapshot: Record "BGB Project Task Snapshot")
    begin
        Clear(TaskSnapshot);
        ClearAmounts(TaskSnapshot);
        TaskSnapshot."Job No." := JobTaskArchive."Job No.";
        TaskSnapshot."Version No." := JobTaskArchive."Version No.";
        TaskSnapshot."Job Task No." := JobTaskArchive."Job Task No.";
        TaskSnapshot.Description := JobTaskArchive.Description;
        TaskSnapshot."Job Task Type" := JobTaskArchive."Job Task Type";
        TaskSnapshot.Indentation := JobTaskArchive.Indentation;
        AddAmount(TaskSnapshot, 107, JobTaskArchive."Usage (Total Cost)");
        AddAmount(TaskSnapshot, 123, JobTaskArchive."Usage (Total Price)");
        AddAmount(TaskSnapshot, 115, JobTaskArchive."Contract (Invoiced Cost)");
        AddAmount(TaskSnapshot, 131, JobTaskArchive."Contract (Invoiced Price)");
        AddPlanningTotalsOnly(JobTaskArchive."Job No.", JobTaskArchive."Job Task No.", JobTaskArchive."Version No.", TaskSnapshot);
    end;

    /// <summary>
    /// Moves the snapshots of one archive version to a new project number, and repoints parent references and the run header.
    /// </summary>
    /// <param name="OldJobNo">The project number stored on the snapshots.</param>
    /// <param name="NewJobNo">The new project number.</param>
    /// <param name="VersionNo">The archive version.</param>
    procedure MoveSnapshots(OldJobNo: Code[20]; NewJobNo: Code[20]; VersionNo: Integer)
    begin
        if OldJobNo = NewJobNo then
            exit;
        MoveProjectSnapshot(OldJobNo, NewJobNo, VersionNo);
        MoveTaskSnapshots(OldJobNo, NewJobNo, VersionNo);
        RepointSnapshotParents(OldJobNo, NewJobNo);
    end;

    local procedure MoveProjectSnapshot(OldJobNo: Code[20]; NewJobNo: Code[20]; VersionNo: Integer)
    var
        Snapshot: Record "BGB Project Snapshot";
        NewSnapshot: Record "BGB Project Snapshot";
        ArchiveRun: Record "BGB Project Archive Run";
    begin
        if not Snapshot.Get(OldJobNo, VersionNo) then
            exit;
        NewSnapshot := Snapshot;
        Snapshot.Delete(false);
        NewSnapshot."Job No." := NewJobNo;
        NewSnapshot.Insert(false);
        if not ArchiveRun.Get(NewSnapshot."Run ID") then
            exit;
        if ArchiveRun."Top Project No." <> OldJobNo then
            exit;
        ArchiveRun."Top Project No." := NewJobNo;
        ArchiveRun.Modify(false);
    end;

    local procedure MoveTaskSnapshots(OldJobNo: Code[20]; NewJobNo: Code[20]; VersionNo: Integer)
    var
        TaskSnapshot: Record "BGB Project Task Snapshot";
        TempTaskSnapshot: Record "BGB Project Task Snapshot" temporary;
        NewTaskSnapshot: Record "BGB Project Task Snapshot";
    begin
        TaskSnapshot.SetRange("Job No.", OldJobNo);
        TaskSnapshot.SetRange("Version No.", VersionNo);
        if TaskSnapshot.FindSet() then
            repeat
                TempTaskSnapshot := TaskSnapshot;
                TempTaskSnapshot.Insert(false);
            until TaskSnapshot.Next() = 0;
        if TempTaskSnapshot.FindSet() then
            repeat
                DeleteTaskSnapshot(OldJobNo, VersionNo, TempTaskSnapshot."Job Task No.");
                NewTaskSnapshot := TempTaskSnapshot;
                NewTaskSnapshot."Job No." := NewJobNo;
                NewTaskSnapshot.Insert(false);
            until TempTaskSnapshot.Next() = 0;
    end;

    local procedure DeleteTaskSnapshot(JobNo: Code[20]; VersionNo: Integer; TaskNo: Code[20])
    var
        TaskSnapshot: Record "BGB Project Task Snapshot";
    begin
        if TaskSnapshot.Get(JobNo, VersionNo, TaskNo) then
            TaskSnapshot.Delete(false);
    end;

    local procedure RepointSnapshotParents(OldJobNo: Code[20]; NewJobNo: Code[20])
    var
        Snapshot: Record "BGB Project Snapshot";
    begin
        Snapshot.SetRange("Parent Project No.", OldJobNo);
        if Snapshot.FindSet(true) then
            repeat
                Snapshot."Parent Project No." := NewJobNo;
                Snapshot.Modify(false);
            until Snapshot.Next() = 0;
    end;

    /// <summary>
    /// Deletes the project and task snapshots of one archive version, and the run when it has no snapshots left.
    /// </summary>
    /// <param name="JobNo">The project number.</param>
    /// <param name="VersionNo">The archive version.</param>
    procedure DeleteSnapshots(JobNo: Code[20]; VersionNo: Integer)
    var
        Snapshot: Record "BGB Project Snapshot";
        TaskSnapshot: Record "BGB Project Task Snapshot";
        RunId: Guid;
    begin
        TaskSnapshot.SetRange("Job No.", JobNo);
        TaskSnapshot.SetRange("Version No.", VersionNo);
        if not TaskSnapshot.IsEmpty() then
            TaskSnapshot.DeleteAll(false);
        if not Snapshot.Get(JobNo, VersionNo) then
            exit;
        RunId := Snapshot."Run ID";
        Snapshot.Delete(false);
        DeleteRunIfEmpty(RunId);
    end;

    local procedure DeleteRunIfEmpty(RunId: Guid)
    var
        Snapshot: Record "BGB Project Snapshot";
        ArchiveRun: Record "BGB Project Archive Run";
    begin
        if IsNullGuid(RunId) then
            exit;
        Snapshot.SetRange("Run ID", RunId);
        if not Snapshot.IsEmpty() then
            exit;
        if ArchiveRun.Get(RunId) then
            ArchiveRun.Delete(false);
    end;

    local procedure DoCapture(Job: Record Job; JobArchive: Record "Job Archive")
    begin
        EnsureRun();
        WriteProjectSnapshot(Job, JobArchive);
        WriteTaskSnapshots(Job, JobArchive);
    end;

    local procedure EnsureRun()
    var
        ArchiveRun: Record "BGB Project Archive Run";
        ArchiveRunContext: Codeunit "BGB Archive Run Context";
    begin
        if ArchiveRun.Get(ArchiveRunContext.RunId()) then
            exit;
        ArchiveRun.Init();
        ArchiveRun."Run ID" := ArchiveRunContext.RunId();
        ArchiveRun."Run At" := ArchiveRunContext.RunAt();
        ArchiveRun."User ID" := CopyStr(UserId(), 1, MaxStrLen(ArchiveRun."User ID"));
        ArchiveRun."Top Project No." := ArchiveRunContext.TopProjectNo();
        ArchiveRun.Hierarchy := ArchiveRunContext.IsHierarchy();
        ArchiveRun.Insert(false);
    end;

    local procedure WriteProjectSnapshot(Job: Record Job; JobArchive: Record "Job Archive")
    var
        Snapshot: Record "BGB Project Snapshot";
        JobFilter: Record Job;
        TempProjectAnalysisBuffer: Record "BGB Project Analysis Buffer" temporary;
        ProjectAnalysisMgt: Codeunit "BGB Project Analysis Mgt.";
        ArchiveRunContext: Codeunit "BGB Archive Run Context";
        Exists: Boolean;
    begin
        JobFilter.SetRange("No.", Job."No.");
        ProjectAnalysisMgt.BuildAnalysis(JobFilter, TempProjectAnalysisBuffer, true);
        TempProjectAnalysisBuffer.SetRange("Project No.", Job."No.");
        if not TempProjectAnalysisBuffer.FindFirst() then
            exit;
        Exists := Snapshot.Get(Job."No.", JobArchive."Version No.");
        if not Exists then
            Snapshot.Init();
        Snapshot."Job No." := Job."No.";
        Snapshot."Version No." := JobArchive."Version No.";
        Snapshot."Run ID" := ArchiveRunContext.RunId();
        Snapshot."Run At" := ArchiveRunContext.RunAt();
        Snapshot."User ID" := CopyStr(UserId(), 1, MaxStrLen(Snapshot."User ID"));
        Snapshot.Description := TempProjectAnalysisBuffer.Description;
        Snapshot."Parent Project No." := TempProjectAnalysisBuffer."Parent Project No.";
        Snapshot.Level := TempProjectAnalysisBuffer.Level;
        Snapshot."During Project Delete" := ArchiveRunContext.IsDeletingJob(Job."No.");
        CopyStatistics(Snapshot, TempProjectAnalysisBuffer);
        if Exists then
            Snapshot.Modify(false)
        else
            Snapshot.Insert(false);
    end;

    local procedure WriteTaskSnapshots(Job: Record Job; JobArchive: Record "Job Archive")
    var
        JobTask: Record "Job Task";
        TaskSnapshot: Record "BGB Project Task Snapshot";
        ArchiveRunContext: Codeunit "BGB Archive Run Context";
    begin
        TaskSnapshot.SetRange("Job No.", Job."No.");
        TaskSnapshot.SetRange("Version No.", JobArchive."Version No.");
        if not TaskSnapshot.IsEmpty() then
            TaskSnapshot.DeleteAll(false);
        JobTask.SetRange("Job No.", Job."No.");
        if JobTask.FindSet() then
            repeat
                TaskSnapshot.Init();
                TaskSnapshot."Job No." := Job."No.";
                TaskSnapshot."Version No." := JobArchive."Version No.";
                TaskSnapshot."Job Task No." := JobTask."Job Task No.";
                TaskSnapshot."Run ID" := ArchiveRunContext.RunId();
                TaskSnapshot.Description := JobTask.Description;
                TaskSnapshot."Job Task Type" := JobTask."Job Task Type";
                TaskSnapshot.Indentation := JobTask.Indentation;
                CalculateTaskAmounts(Job."No.", JobTask."Job Task No.", JobArchive."Version No.", true, TaskSnapshot);
                TaskSnapshot.Insert(false);
            until JobTask.Next() = 0;
    end;

    local procedure CopyStatistics(var Snapshot: Record "BGB Project Snapshot"; var TempProjectAnalysisBuffer: Record "BGB Project Analysis Buffer" temporary)
    var
        SnapshotRef: RecordRef;
        AnalysisRef: RecordRef;
    begin
        SnapshotRef.GetTable(Snapshot);
        AnalysisRef.GetTable(TempProjectAnalysisBuffer);
        CopyFieldRange(SnapshotRef, AnalysisRef, 100, 131);
        CopyFieldRange(SnapshotRef, AnalysisRef, 200, 207);
        CopyFieldRange(SnapshotRef, AnalysisRef, 300, 307);
        SnapshotRef.SetTable(Snapshot);
    end;

    local procedure CopyFieldRange(var ToRef: RecordRef; var FromRef: RecordRef; FromFieldNo: Integer; ToFieldNo: Integer)
    var
        FieldNo: Integer;
    begin
        for FieldNo := FromFieldNo to ToFieldNo do
            ToRef.Field(FieldNo).Value(FromRef.Field(FieldNo).Value());
    end;

    local procedure AddLedgerAmounts(JobNo: Code[20]; JobTaskNo: Code[20]; var TaskSnapshot: Record "BGB Project Task Snapshot")
    var
        EntryType: Enum "Job Journal Line Entry Type";
        LineType: Enum "Job Journal Line Type";
    begin
        AddLedgerType(JobNo, JobTaskNo, EntryType::Usage, LineType::Resource, 104, 120, 1, TaskSnapshot);
        AddLedgerType(JobNo, JobTaskNo, EntryType::Usage, LineType::Item, 104, 120, 1, TaskSnapshot);
        AddLedgerType(JobNo, JobTaskNo, EntryType::Usage, LineType::"G/L Account", 104, 120, 1, TaskSnapshot);
        AddLedgerType(JobNo, JobTaskNo, EntryType::Sale, LineType::Resource, 112, 128, -1, TaskSnapshot);
        AddLedgerType(JobNo, JobTaskNo, EntryType::Sale, LineType::Item, 112, 128, -1, TaskSnapshot);
        AddLedgerType(JobNo, JobTaskNo, EntryType::Sale, LineType::"G/L Account", 112, 128, -1, TaskSnapshot);
    end;

    local procedure AddLedgerType(JobNo: Code[20]; JobTaskNo: Code[20]; EntryType: Enum "Job Journal Line Entry Type"; LineType: Enum "Job Journal Line Type"; CostBase: Integer; PriceBase: Integer; Sign: Decimal; var TaskSnapshot: Record "BGB Project Task Snapshot")
    var
        JobLedgerEntry: Record "Job Ledger Entry";
        Cost: Decimal;
        Price: Decimal;
    begin
        JobLedgerEntry.SetRange("Job No.", JobNo);
        JobLedgerEntry.SetRange("Job Task No.", JobTaskNo);
        JobLedgerEntry.SetRange("Entry Type", EntryType);
        JobLedgerEntry.SetRange(Type, LineType);
        SumLedger(JobLedgerEntry, Cost, Price);
        AddSplit(TaskSnapshot, CostBase, LineType.AsInteger(), Sign * Cost);
        AddSplit(TaskSnapshot, PriceBase, LineType.AsInteger(), Sign * Price);
    end;

    local procedure SumLedger(var JobLedgerEntry: Record "Job Ledger Entry"; var Cost: Decimal; var Price: Decimal)
    begin
        Cost := 0;
        Price := 0;
        if JobLedgerEntry.FindSet() then
            repeat
                Cost += JobLedgerEntry."Total Cost (LCY)";
                Price += JobLedgerEntry."Line Amount (LCY)";
            until JobLedgerEntry.Next() = 0;
    end;

    local procedure AddPlanningArchiveAmounts(JobNo: Code[20]; JobTaskNo: Code[20]; VersionNo: Integer; var TaskSnapshot: Record "BGB Project Task Snapshot")
    var
        Line: Record "Job Planning Line Archive";
    begin
        SetPlanningArchiveFilters(Line, JobNo, JobTaskNo, VersionNo, true);
        AddPlanningArchiveTypes(Line, 100, 116, TaskSnapshot);
        SetPlanningArchiveFilters(Line, JobNo, JobTaskNo, VersionNo, false);
        AddPlanningArchiveTypes(Line, 108, 124, TaskSnapshot);
    end;

    local procedure SetPlanningArchiveFilters(var Line: Record "Job Planning Line Archive"; JobNo: Code[20]; JobTaskNo: Code[20]; VersionNo: Integer; Schedule: Boolean)
    begin
        Line.Reset();
        Line.SetRange("Job No.", JobNo);
        Line.SetRange("Job Task No.", JobTaskNo);
        Line.SetRange("Version No.", VersionNo);
        if Schedule then
            Line.SetRange("Schedule Line", true)
        else
            Line.SetRange("Contract Line", true);
    end;

    local procedure AddPlanningArchiveTypes(var Line: Record "Job Planning Line Archive"; CostBase: Integer; PriceBase: Integer; var TaskSnapshot: Record "BGB Project Task Snapshot")
    begin
        AddOnePlanningArchive(Line, "Job Planning Line Type"::Resource, CostBase, PriceBase, TaskSnapshot);
        AddOnePlanningArchive(Line, "Job Planning Line Type"::Item, CostBase, PriceBase, TaskSnapshot);
        AddOnePlanningArchive(Line, "Job Planning Line Type"::"G/L Account", CostBase, PriceBase, TaskSnapshot);
    end;

    local procedure AddOnePlanningArchive(var Line: Record "Job Planning Line Archive"; LineType: Enum "Job Planning Line Type"; CostBase: Integer; PriceBase: Integer; var TaskSnapshot: Record "BGB Project Task Snapshot")
    var
        Cost: Decimal;
        Price: Decimal;
    begin
        Line.SetRange(Type, LineType);
        SumPlanningArchive(Line, Cost, Price);
        AddSplit(TaskSnapshot, CostBase, LineType.AsInteger(), Cost);
        AddSplit(TaskSnapshot, PriceBase, LineType.AsInteger(), Price);
    end;

    local procedure SumPlanningArchive(var Line: Record "Job Planning Line Archive"; var Cost: Decimal; var Price: Decimal)
    begin
        Cost := 0;
        Price := 0;
        if Line.FindSet() then
            repeat
                Cost += Line."Total Cost (LCY)";
                Price += Line."Line Amount (LCY)";
            until Line.Next() = 0;
    end;

    local procedure AddPlanningLineAmounts(JobNo: Code[20]; JobTaskNo: Code[20]; var TaskSnapshot: Record "BGB Project Task Snapshot")
    var
        Line: Record "Job Planning Line";
    begin
        SetPlanningLineFilters(Line, JobNo, JobTaskNo, true);
        AddPlanningLineTypes(Line, 100, 116, TaskSnapshot);
        SetPlanningLineFilters(Line, JobNo, JobTaskNo, false);
        AddPlanningLineTypes(Line, 108, 124, TaskSnapshot);
    end;

    local procedure SetPlanningLineFilters(var Line: Record "Job Planning Line"; JobNo: Code[20]; JobTaskNo: Code[20]; Schedule: Boolean)
    begin
        Line.Reset();
        Line.SetRange("Job No.", JobNo);
        Line.SetRange("Job Task No.", JobTaskNo);
        if Schedule then
            Line.SetRange("Schedule Line", true)
        else
            Line.SetRange("Contract Line", true);
    end;

    local procedure AddPlanningLineTypes(var Line: Record "Job Planning Line"; CostBase: Integer; PriceBase: Integer; var TaskSnapshot: Record "BGB Project Task Snapshot")
    begin
        AddOnePlanningLine(Line, "Job Planning Line Type"::Resource, CostBase, PriceBase, TaskSnapshot);
        AddOnePlanningLine(Line, "Job Planning Line Type"::Item, CostBase, PriceBase, TaskSnapshot);
        AddOnePlanningLine(Line, "Job Planning Line Type"::"G/L Account", CostBase, PriceBase, TaskSnapshot);
    end;

    local procedure AddOnePlanningLine(var Line: Record "Job Planning Line"; LineType: Enum "Job Planning Line Type"; CostBase: Integer; PriceBase: Integer; var TaskSnapshot: Record "BGB Project Task Snapshot")
    var
        Cost: Decimal;
        Price: Decimal;
    begin
        Line.SetRange(Type, LineType);
        SumPlanningLine(Line, Cost, Price);
        AddSplit(TaskSnapshot, CostBase, LineType.AsInteger(), Cost);
        AddSplit(TaskSnapshot, PriceBase, LineType.AsInteger(), Price);
    end;

    local procedure SumPlanningLine(var Line: Record "Job Planning Line"; var Cost: Decimal; var Price: Decimal)
    begin
        Cost := 0;
        Price := 0;
        if Line.FindSet() then
            repeat
                Cost += Line."Total Cost (LCY)";
                Price += Line."Line Amount (LCY)";
            until Line.Next() = 0;
    end;

    local procedure AddPlanningTotalsOnly(JobNo: Code[20]; JobTaskNo: Code[20]; VersionNo: Integer; var TaskSnapshot: Record "BGB Project Task Snapshot")
    var
        Line: Record "Job Planning Line Archive";
        Cost: Decimal;
        Price: Decimal;
    begin
        Line.SetRange("Job No.", JobNo);
        Line.SetRange("Job Task No.", JobTaskNo);
        Line.SetRange("Version No.", VersionNo);
        Line.SetRange("Schedule Line", true);
        SumPlanningArchive(Line, Cost, Price);
        AddAmount(TaskSnapshot, 103, Cost);
        AddAmount(TaskSnapshot, 119, Price);
        Line.SetRange("Schedule Line");
        Line.SetRange("Contract Line", true);
        SumPlanningArchive(Line, Cost, Price);
        AddAmount(TaskSnapshot, 111, Cost);
        AddAmount(TaskSnapshot, 127, Price);
    end;

    local procedure AddSplit(var TaskSnapshot: Record "BGB Project Task Snapshot"; BaseFieldNo: Integer; TypeOrdinal: Integer; Amount: Decimal)
    begin
        if Amount = 0 then
            exit;
        if (TypeOrdinal < 0) or (TypeOrdinal > 2) then
            exit;
        AddAmount(TaskSnapshot, BaseFieldNo + TypeOrdinal, Amount);
        AddAmount(TaskSnapshot, BaseFieldNo + 3, Amount);
    end;

    local procedure AddAmount(var TaskSnapshot: Record "BGB Project Task Snapshot"; FieldNo: Integer; Amount: Decimal)
    var
        RecRef: RecordRef;
        Value: Decimal;
    begin
        if Amount = 0 then
            exit;
        RecRef.GetTable(TaskSnapshot);
        Value := RecRef.Field(FieldNo).Value();
        RecRef.Field(FieldNo).Value(Value + Amount);
        RecRef.SetTable(TaskSnapshot);
    end;

    local procedure ClearAmounts(var TaskSnapshot: Record "BGB Project Task Snapshot")
    var
        RecRef: RecordRef;
        FieldNo: Integer;
    begin
        RecRef.GetTable(TaskSnapshot);
        for FieldNo := 100 to 131 do
            RecRef.Field(FieldNo).Value(0);
        RecRef.SetTable(TaskSnapshot);
    end;
}
