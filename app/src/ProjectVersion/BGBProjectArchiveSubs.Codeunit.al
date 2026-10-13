namespace FlemmingBakkensen.BCGrokBot.ProjectVersion;

using FlemmingBakkensen.BCGrokBot.ProjectHierarchy;
using Microsoft.Projects.Project.Archive;
using Microsoft.Projects.Project.Job;

/// <summary>
/// Keeps project version snapshots in step with project archiving, deletion and rename.
/// </summary>
codeunit 50113 "BGB Project Archive Subs."
{
    Access = Internal;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Job Archive Management", OnAfterStoreJob, '', false, false)]
    local procedure JobArchiveManagementOnAfterStoreJob(Job: Record Job; var JobArchive: Record "Job Archive")
    var
        ProjectArchiveMgt: Codeunit "BGB Project Archive Mgt.";
    begin
        if Job.IsTemporary() then
            exit;
        ProjectArchiveMgt.CaptureSnapshot(Job, JobArchive);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Job Archive", OnBeforeDeleteEvent, '', false, false)]
    local procedure JobArchiveOnBeforeDelete(var Rec: Record "Job Archive"; RunTrigger: Boolean)
    var
        ProjectArchiveMgt: Codeunit "BGB Project Archive Mgt.";
        ArchiveRunContext: Codeunit "BGB Archive Run Context";
        NewJobNo: Code[20];
    begin
        if Rec.IsTemporary() then
            exit;
        if ArchiveRunContext.RenameTarget(Rec."No.", NewJobNo) then
            ProjectArchiveMgt.MoveSnapshots(Rec."No.", NewJobNo, Rec."Version No.")
        else
            ProjectArchiveMgt.DeleteSnapshots(Rec."No.", Rec."Version No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::Job, OnBeforeDeleteEvent, '', false, false)]
    local procedure JobOnBeforeDelete(var Rec: Record Job; RunTrigger: Boolean)
    var
        ProjectHierarchyMgt: Codeunit "BGB Project Hierarchy Mgt.";
        ArchiveRunContext: Codeunit "BGB Archive Run Context";
    begin
        if Rec.IsTemporary() then
            exit;
        ProjectHierarchyMgt.CheckCanDelete(Rec."No.");
        ArchiveRunContext.SetDeletingJob(Rec."No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::Job, OnAfterDeleteEvent, '', false, false)]
    local procedure JobOnAfterDelete(var Rec: Record Job; RunTrigger: Boolean)
    var
        ArchiveRunContext: Codeunit "BGB Archive Run Context";
    begin
        if Rec.IsTemporary() then
            exit;
        ArchiveRunContext.ClearDeletingJob();
    end;

    [EventSubscriber(ObjectType::Table, Database::Job, OnBeforeRenameEvent, '', false, false)]
    local procedure JobOnBeforeRename(var Rec: Record Job; var xRec: Record Job; RunTrigger: Boolean)
    var
        ArchiveRunContext: Codeunit "BGB Archive Run Context";
    begin
        if Rec.IsTemporary() then
            exit;
        ArchiveRunContext.SetRename(xRec."No.", Rec."No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::Job, OnAfterRenameEvent, '', false, false)]
    local procedure JobOnAfterRename(var Rec: Record Job; var xRec: Record Job; RunTrigger: Boolean)
    var
        ArchiveRunContext: Codeunit "BGB Archive Run Context";
    begin
        if Rec.IsTemporary() then
            exit;
        ArchiveRunContext.ClearRename();
    end;
}
