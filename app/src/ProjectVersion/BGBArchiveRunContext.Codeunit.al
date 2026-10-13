namespace FlemmingBakkensen.BCGrokBot.ProjectVersion;

/// <summary>
/// In-memory state for one archive run, a project delete, or a project rename.
/// Hierarchy archiving sets the run before StoreJob; a single-project archive starts its own run.
/// </summary>
codeunit 50110 "BGB Archive Run Context"
{
    Access = Internal;
    SingleInstance = true;

    var
        ActiveRunId: Guid;
        ActiveRunAt: DateTime;
        ActiveTopProjectNo: Code[20];
        ActiveHierarchy: Boolean;
        RunActive: Boolean;
        DeletingJobNo: Code[20];
        RenameFromNo: Code[20];
        RenameToNo: Code[20];
        RenameActive: Boolean;

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
        RunActive := true;
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
        RunActive := false;
    end;

    /// <summary>
    /// Returns whether an archive run is active.
    /// </summary>
    /// <returns>True when BeginRun was called and EndRun has not.</returns>
    procedure HasActiveRun(): Boolean
    begin
        exit(RunActive);
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
    /// </summary>
    /// <param name="JobNo">The project number.</param>
    /// <returns>True when the delete mark matches the project.</returns>
    procedure IsDeletingJob(JobNo: Code[20]): Boolean
    begin
        exit((DeletingJobNo <> '') and (DeletingJobNo = JobNo));
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
    /// </summary>
    /// <param name="FromNo">The archived project number being deleted.</param>
    /// <param name="ToNo">Returns the new project number.</param>
    /// <returns>True when the delete is part of a rename of this project.</returns>
    procedure RenameTarget(FromNo: Code[20]; var ToNo: Code[20]): Boolean
    begin
        if (not RenameActive) or (FromNo = '') or (FromNo <> RenameFromNo) then
            exit(false);
        ToNo := RenameToNo;
        exit(ToNo <> '');
    end;
}
