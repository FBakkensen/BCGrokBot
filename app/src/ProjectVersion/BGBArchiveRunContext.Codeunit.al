namespace FlemmingBakkensen.BCGrokBot.ProjectVersion;

using FlemmingBakkensen.BCGrokBot.ProjectAnalysis;
using Microsoft.Projects.Project.Archive;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Ledger;

/// <summary>
/// In-memory state for one archive run, a project delete, or a project rename.
/// Hierarchy archiving sets the run before StoreJob; a single-project archive starts its own run.
/// The state is not rolled back with the database, so it is checked against the database before use.
/// </summary>
codeunit 50110 "BGB Archive Run Context"
{
    Access = Internal;
    SingleInstance = true;
    Permissions = tabledata Job = r,
                  tabledata "Job Archive" = r,
                  tabledata "BGB Project Archive Run" = r,
                  tabledata "Job Ledger Entry" = r;

    var
        StoredProjects: JsonObject;
        ActiveRunId: Guid;
        ActiveRunAt: DateTime;
        ActiveTopProjectNo: Code[20];
        ActiveHierarchy: Boolean;
        DeletingJobNo: Code[20];
        RenameFromNo: Code[20];
        RenameToNo: Code[20];
        RenameActive: Boolean;
        InsideHierarchy: Boolean;
        AnalysisReady: Boolean;
        AnalysisBuilds: Integer;

    /// <summary>
    /// Starts an archive run. Later StoreJob calls reuse it until EndRun.
    /// </summary>
    /// <param name="NewRunId">The archive run id.</param>
    /// <param name="NewRunAt">The date and time of the run.</param>
    /// <param name="NewTopProjectNo">The top project of a hierarchy run, or the project of a single-project run.</param>
    /// <param name="Hierarchy">Whether the run archives a top-level project and its descendants.</param>
    procedure BeginRun(NewRunId: Guid; NewRunAt: DateTime; NewTopProjectNo: Code[20]; Hierarchy: Boolean)
    begin
        ActiveRunId := NewRunId;
        ActiveRunAt := NewRunAt;
        ActiveTopProjectNo := NewTopProjectNo;
        ActiveHierarchy := Hierarchy;
    end;

    /// <summary>
    /// Clears a run left active by a failed archive, including the hierarchy flag and the cached analysis.
    /// </summary>
    procedure Reset()
    begin
        ClearRunState();
        ClearAnalysis();
    end;

    /// <summary>
    /// Clears the in-memory run and hierarchy flag without touching cached rows.
    /// Use this after a failed Codeunit.Run, where a temporary-record write can hide the original error.
    /// </summary>
    procedure ClearRunState()
    begin
        EndRun();
        InsideHierarchy := false;
    end;

    /// <summary>
    /// Clears the active archive run.
    /// </summary>
    procedure EndRun()
    begin
        Clear(ActiveRunId);
        Clear(ActiveRunAt);
        Clear(ActiveTopProjectNo);
        ActiveHierarchy := false;
    end;

    /// <summary>
    /// Returns the active run id.
    /// </summary>
    /// <returns>The run id.</returns>
    procedure RunId(): Guid
    begin
        exit(ActiveRunId);
    end;

    /// <summary>
    /// Returns the active run date and time.
    /// </summary>
    /// <returns>The run timestamp.</returns>
    procedure RunAt(): DateTime
    begin
        exit(ActiveRunAt);
    end;

    /// <summary>
    /// Returns the top project number stored for the active run.
    /// </summary>
    /// <returns>The project number.</returns>
    procedure TopProjectNo(): Code[20]
    begin
        exit(ActiveTopProjectNo);
    end;

    /// <summary>
    /// Returns whether the active run is a hierarchy archive.
    /// </summary>
    /// <returns>True for a hierarchy run.</returns>
    procedure IsHierarchy(): Boolean
    begin
        exit(ActiveHierarchy);
    end;

    /// <summary>
    /// Marks that StoreJob calls are part of the hierarchy archive currently in progress.
    /// </summary>
    /// <param name="Inside">True while the hierarchy archive is storing projects.</param>
    procedure SetInsideHierarchy(Inside: Boolean)
    begin
        InsideHierarchy := Inside;
    end;

    /// <summary>
    /// Returns whether the current StoreJob is part of a hierarchy archive whose run header is still in the database.
    /// A flag left behind by a rolled-back archive is cleared.
    /// </summary>
    /// <returns>True while a hierarchy archive is storing projects.</returns>
    procedure InsideHierarchyStore(): Boolean
    var
        ArchiveRun: Record "BGB Project Archive Run";
    begin
        if (not InsideHierarchy) or IsNullGuid(ActiveRunId) then begin
            InsideHierarchy := false;
            exit(false);
        end;
        if ArchiveRun.Get(ActiveRunId) then
            exit(true);
        // The header is inserted in the same transaction as the archives. A missing header means that transaction was rolled back.
        InsideHierarchy := false;
        EndRun();
        ClearAnalysis();
        exit(false);
    end;

    /// <summary>
    /// Marks a project as being deleted, so the snapshot taken by the delete archive can be flagged.
    /// </summary>
    /// <param name="JobNo">The project number.</param>
    procedure SetDeletingJob(JobNo: Code[20])
    begin
        DeletingJobNo := JobNo;
    end;

    /// <summary>
    /// Clears the project-delete mark.
    /// </summary>
    procedure ClearDeletingJob()
    begin
        Clear(DeletingJobNo);
    end;

    /// <summary>
    /// Returns whether the project is the one currently being deleted.
    /// A delete that reaches the archive has no project ledger entries, because MoveEntries stops it when entries exist.
    /// A remembered flag for a project that still has entries is from a failed delete and is cleared.
    /// </summary>
    /// <param name="JobNo">The project number.</param>
    /// <returns>True when the delete mark matches the project and the delete can still be in progress.</returns>
    procedure IsDeletingJob(JobNo: Code[20]): Boolean
    var
        JobLedgerEntry: Record "Job Ledger Entry";
    begin
        if (DeletingJobNo = '') or (DeletingJobNo <> JobNo) then
            exit(false);
        JobLedgerEntry.SetCurrentKey("Job No.", "Posting Date");
        JobLedgerEntry.SetRange("Job No.", JobNo);
        if not JobLedgerEntry.IsEmpty() then begin
            ClearDeletingJob();
            exit(false);
        end;
        exit(true);
    end;

    /// <summary>
    /// Marks a project rename so archive deletes during RenameJobArchieve move snapshots instead of removing them.
    /// </summary>
    /// <param name="FromNo">The current project number.</param>
    /// <param name="ToNo">The new project number.</param>
    procedure SetRename(FromNo: Code[20]; ToNo: Code[20])
    begin
        RenameFromNo := FromNo;
        RenameToNo := ToNo;
        RenameActive := true;
    end;

    /// <summary>
    /// Clears the project-rename mark.
    /// </summary>
    procedure ClearRename()
    begin
        Clear(RenameFromNo);
        Clear(RenameToNo);
        RenameActive := false;
    end;

    /// <summary>
    /// Returns the new project number when an archive of FromNo is being removed as part of a rename.
    /// The new project archives must already exist, which is true only while RenameJobArchieve is deleting the old number.
    /// A flag left after a rolled-back rename is cleared.
    /// </summary>
    /// <param name="FromNo">The archived project number being deleted.</param>
    /// <param name="ToNo">Returns the new project number.</param>
    /// <returns>True when the delete is part of a rename of this project.</returns>
    procedure RenameTarget(FromNo: Code[20]; var ToNo: Code[20]): Boolean
    begin
        if (not RenameActive) or (FromNo = '') or (FromNo <> RenameFromNo) or (RenameToNo = '') then
            exit(false);
        // RenameJobArchieve copies the archives to the new number before it deletes the old ones.
        // After a rolled-back rename those new archives are gone. Both project numbers existing means this is not that rename.
        if not RenameMatchesDatabase(FromNo) then begin
            ClearRename();
            exit(false);
        end;
        ToNo := RenameToNo;
        exit(true);
    end;

    local procedure RenameMatchesDatabase(FromNo: Code[20]): Boolean
    var
        Job: Record Job;
        JobArchive: Record "Job Archive";
        NewArchiveExists: Boolean;
        NewJobExists: Boolean;
        OldJobExists: Boolean;
    begin
        JobArchive.SetLoadFields("No.");
        JobArchive.SetRange("No.", RenameToNo);
        NewArchiveExists := not JobArchive.IsEmpty();
        Job.SetLoadFields("No.");
        OldJobExists := Job.Get(FromNo);
        NewJobExists := Job.Get(RenameToNo);
        exit(NewArchiveExists and not (OldJobExists and NewJobExists));
    end;

    /// <summary>
    /// Stores the tree analysis for the active hierarchy run so each project snapshot can reuse it.
    /// The rows are kept in memory, not in a temporary record, so finishing Codeunit.Run does not stop the transaction.
    /// </summary>
    /// <param name="TempProjectAnalysisBuffer">The rows for the top project and its descendants.</param>
    procedure StoreAnalysis(var TempProjectAnalysisBuffer: Record "BGB Project Analysis Buffer" temporary)
    var
        Row: JsonObject;
    begin
        Clear(StoredProjects);
        TempProjectAnalysisBuffer.Reset();
        if TempProjectAnalysisBuffer.FindSet() then
            repeat
                Clear(Row);
                Row.Add('description', TempProjectAnalysisBuffer.Description);
                Row.Add('parent', TempProjectAnalysisBuffer."Parent Project No.");
                Row.Add('level', TempProjectAnalysisBuffer.Level);
                Row.Add('amounts', AmountsOf(TempProjectAnalysisBuffer));
                StoredProjects.Add(TempProjectAnalysisBuffer."Project No.", Row);
            until TempProjectAnalysisBuffer.Next() = 0;
        AnalysisReady := true;
    end;

    /// <summary>
    /// Returns whether the active run already has a stored tree analysis.
    /// </summary>
    /// <returns>True when StoreAnalysis has been called since the last clear.</returns>
    procedure HasAnalysis(): Boolean
    begin
        exit(AnalysisReady);
    end;

    /// <summary>
    /// Copies the stored analysis row for one project.
    /// </summary>
    /// <param name="ProjectNo">The project number.</param>
    /// <param name="TempProjectAnalysisBuffer">Returns the row.</param>
    /// <returns>True when the row is in the stored analysis.</returns>
    procedure CopyAnalysis(ProjectNo: Code[20]; var TempProjectAnalysisBuffer: Record "BGB Project Analysis Buffer" temporary): Boolean
    var
        RecRef: RecordRef;
        Amounts: JsonArray;
        Row: JsonObject;
        AmountsToken: JsonToken;
        RowToken: JsonToken;
    begin
        if not AnalysisReady then
            exit(false);
        if not StoredProjects.Get(ProjectNo, RowToken) then
            exit(false);
        Row := RowToken.AsObject();
        TempProjectAnalysisBuffer.Init();
        TempProjectAnalysisBuffer."Project No." := ProjectNo;
        TempProjectAnalysisBuffer.Description := CopyStr(JsonText(Row, 'description'), 1, MaxStrLen(TempProjectAnalysisBuffer.Description));
        TempProjectAnalysisBuffer."Parent Project No." := CopyStr(JsonText(Row, 'parent'), 1, MaxStrLen(TempProjectAnalysisBuffer."Parent Project No."));
        TempProjectAnalysisBuffer.Level := JsonInteger(Row, 'level');
        if not Row.Get('amounts', AmountsToken) then
            exit(false);
        Amounts := AmountsToken.AsArray();
        RecRef.GetTable(TempProjectAnalysisBuffer);
        ReadAmountRange(Amounts, RecRef, 100, 131, 0);
        ReadAmountRange(Amounts, RecRef, 200, 207, 32);
        ReadAmountRange(Amounts, RecRef, 300, 307, 40);
        RecRef.SetTable(TempProjectAnalysisBuffer);
        exit(true);
    end;

    /// <summary>
    /// Counts one build of the tree analysis in this session.
    /// </summary>
    procedure NoteAnalysisBuild()
    begin
        AnalysisBuilds += 1;
    end;

    /// <summary>
    /// Returns how many times this session has built the tree analysis for a snapshot.
    /// </summary>
    /// <returns>The number of builds since the last reset of the count.</returns>
    procedure AnalysisBuildCount(): Integer
    begin
        exit(AnalysisBuilds);
    end;

    /// <summary>
    /// Sets the session analysis-build count back to zero.
    /// </summary>
    procedure ResetAnalysisBuildCount()
    begin
        AnalysisBuilds := 0;
    end;

    /// <summary>
    /// Drops the cached tree analysis for the active run.
    /// </summary>
    procedure ClearAnalysis()
    begin
        Clear(StoredProjects);
        AnalysisReady := false;
    end;

    local procedure AmountsOf(var TempProjectAnalysisBuffer: Record "BGB Project Analysis Buffer" temporary) Amounts: JsonArray
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(TempProjectAnalysisBuffer);
        AppendAmountRange(Amounts, RecRef, 100, 131);
        AppendAmountRange(Amounts, RecRef, 200, 207);
        AppendAmountRange(Amounts, RecRef, 300, 307);
    end;

    local procedure AppendAmountRange(var Amounts: JsonArray; var RecRef: RecordRef; FromFieldNo: Integer; ToFieldNo: Integer)
    var
        Amount: Decimal;
        FieldNo: Integer;
    begin
        for FieldNo := FromFieldNo to ToFieldNo do begin
            Amount := RecRef.Field(FieldNo).Value();
            Amounts.Add(Amount);
        end;
    end;

    local procedure ReadAmountRange(Amounts: JsonArray; var RecRef: RecordRef; FromFieldNo: Integer; ToFieldNo: Integer; StartIndex: Integer)
    var
        FieldNo: Integer;
        Index: Integer;
        AmountToken: JsonToken;
    begin
        Index := StartIndex;
        for FieldNo := FromFieldNo to ToFieldNo do begin
            Amounts.Get(Index, AmountToken);
            RecRef.Field(FieldNo).Value(AmountToken.AsValue().AsDecimal());
            Index += 1;
        end;
    end;

    local procedure JsonText(Row: JsonObject; Name: Text): Text
    var
        Token: JsonToken;
    begin
        if not Row.Get(Name, Token) then
            exit('');
        exit(Token.AsValue().AsText());
    end;

    local procedure JsonInteger(Row: JsonObject; Name: Text): Integer
    var
        Token: JsonToken;
    begin
        if not Row.Get(Name, Token) then
            exit(0);
        exit(Token.AsValue().AsInteger());
    end;
}
