namespace FlemmingBakkensen.BCGrokBot.ProjectVersion;

/// <summary>
/// Stores the active hierarchy archive. Run with Codeunit.Run so a failure rolls back only that hierarchy.
/// </summary>
codeunit 50114 "BGB Hierarchy Archive"
{
    Access = Internal;

    trigger OnRun()
    var
        ProjectArchiveMgt: Codeunit "BGB Project Archive Mgt.";
    begin
        ProjectArchiveMgt.StoreActiveHierarchy();
    end;
}
