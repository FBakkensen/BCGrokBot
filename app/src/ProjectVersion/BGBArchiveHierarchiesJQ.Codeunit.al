namespace FlemmingBakkensen.BCGrokBot.ProjectVersion;

using System.Threading;

/// <summary>
/// Job queue codeunit. Archives every open top-level project and its subprojects, one archive run per top-level project.
/// Parameter String is an optional filter on the project number (for example BGB-V-*). The app does not create a job queue entry.
/// </summary>
codeunit 50112 "BGB Archive Hierarchies JQ"
{
    Access = Public;
    TableNo = "Job Queue Entry";

    trigger OnRun()
    var
        ProjectArchiveMgt: Codeunit "BGB Project Archive Mgt.";
    begin
        ProjectArchiveMgt.ArchiveOpenTopLevelHierarchies(Rec."Parameter String");
    end;
}
