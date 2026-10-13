namespace FlemmingBakkensen.BCGrokBot.ProjectVersion;

using FlemmingBakkensen.BCGrokBot.ProjectAnalysis;
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
                  tabledata "BGB Project Archive Run" = r,
                  tabledata "Job Ledger Entry" = r;

    var
        TempStoredAnalysis: Record "BGB Project Analysis Buffer" temporary;
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
        EndRun();
        InsideHierarchy := false;
        ClearAnalysis();
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
    /// OnRename has already renamed the project when the archives are deleted. If the old number still exists,
    /// or the new number does not, the rename was rolled back and the flag is cleared.
    /// </summary>
    /// <param name="FromNo">The archived project number being deleted.</param>
    /// <param name="ToNo">Returns the new project number.</param>
    /// <returns>True when the delete is part of a rename of this project.</returns>
    procedure RenameTarget(FromNo: Code[20]; var ToNo: Code[20]): Boolean
    var
        Job: Record Job;
    begin
        if (not RenameActive) or (FromNo = '') or (FromNo <> RenameFromNo) or (RenameToNo = '') then
            exit(false);
        Job.SetLoadFields("No.");
        if Job.Get(FromNo) or (not Job.Get(RenameToNo)) then begin
            ClearRename();
            exit(false);
        end;
        ToNo := RenameToNo;
        exit(true);
    end;

    /// <summary>
    /// Stores the tree analysis for the active hierarchy run so each project snapshot can reuse it.
    /// </summary>
    /// <param name="TempProjectAnalysisBuffer">The rows for the top project and its descendants.</param>
    procedure StoreAnalysis(var TempProjectAnalysisBuffer: Record "BGB Project Analysis Buffer" temporary)
    begin
        TempStoredAnalysis.Reset();
        TempStoredAnalysis.DeleteAll(false);
        TempProjectAnalysisBuffer.Reset();
        if TempProjectAnalysisBuffer.FindSet() then
            repeat
                TempStoredAnalysis := TempProjectAnalysisBuffer;
                TempStoredAnalysis.Insert(false);
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
    begin
        if not AnalysisReady then
            exit(false);
        TempStoredAnalysis.Reset();
        TempStoredAnalysis.SetRange("Project No.", ProjectNo);
        if not TempStoredAnalysis.FindFirst() then
            exit(false);
        TempProjectAnalysisBuffer.Init();
        TempProjectAnalysisBuffer := TempStoredAnalysis;
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

    local procedure ClearAnalysis()
    begin
        TempStoredAnalysis.Reset();
        TempStoredAnalysis.DeleteAll(false);
        AnalysisReady := false;
    end;
}
