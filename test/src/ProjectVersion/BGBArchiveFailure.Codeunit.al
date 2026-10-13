namespace FlemmingBakkensen.BCGrokBot.Test.ProjectVersion;

using Microsoft.Projects.Project.Archive;
using Microsoft.Projects.Project.Job;

/// <summary>
/// Manual subscriber that fails one archive store or one project rename, so tests can prove rolled-back state is not reused.
/// </summary>
codeunit 50164 "BGB Archive Failure"
{
    Access = Internal;
    EventSubscriberInstance = Manual;

    var
        FailStoreProjectNo: Code[20];
        FailRenameFromNo: Code[20];
        FailRenameErr: Label 'Rename failed for project %1.', Comment = '%1 = project number';
        FailStoreErr: Label 'Archive failed for project %1.', Comment = '%1 = project number';

    /// <summary>
    /// Fails the next project archive store for this project, once.
    /// </summary>
    /// <param name="ProjectNo">The project number.</param>
    procedure FailNextStore(ProjectNo: Code[20])
    begin
        FailStoreProjectNo := ProjectNo;
    end;

    /// <summary>
    /// Fails the next project rename of this project when its archive is deleted, once.
    /// </summary>
    /// <param name="ProjectNo">The current project number.</param>
    procedure FailNextRename(ProjectNo: Code[20])
    begin
        FailRenameFromNo := ProjectNo;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Job Archive Management", OnAfterStoreJob, '', false, false)]
    local procedure FailStore(Job: Record Job; var JobArchive: Record "Job Archive")
    var
        ProjectNo: Code[20];
    begin
        if Job.IsTemporary() or (FailStoreProjectNo = '') or (Job."No." <> FailStoreProjectNo) then
            exit;
        ProjectNo := FailStoreProjectNo;
        Clear(FailStoreProjectNo);
        Error(FailStoreErr, ProjectNo);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Job Archive", OnBeforeDeleteEvent, '', false, false)]
    local procedure FailRename(var Rec: Record "Job Archive"; RunTrigger: Boolean)
    var
        ProjectNo: Code[20];
    begin
        if Rec.IsTemporary() or (FailRenameFromNo = '') or (Rec."No." <> FailRenameFromNo) then
            exit;
        ProjectNo := FailRenameFromNo;
        Clear(FailRenameFromNo);
        Error(FailRenameErr, ProjectNo);
    end;
}
