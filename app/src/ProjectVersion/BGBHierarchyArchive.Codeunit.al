namespace FlemmingBakkensen.BCGrokBot.ProjectVersion;

using Microsoft.Projects.Project.Job;

/// <summary>
/// Stores the active hierarchy archive for one project record.
/// Run with Codeunit.Run so a failure rolls back only that hierarchy.
/// </summary>
codeunit 50114 "BGB Hierarchy Archive"
{
    Access = Internal;
    TableNo = Job;

    trigger OnRun()
    var
        ProjectArchiveMgt: Codeunit "BGB Project Archive Mgt.";
    begin
        ProjectArchiveMgt.StoreActiveHierarchy();
    end;
}
