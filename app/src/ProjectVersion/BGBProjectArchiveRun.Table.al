namespace FlemmingBakkensen.BCGrokBot.ProjectVersion;

using Microsoft.Projects.Project.Job;

/// <summary>
/// One archive run. A hierarchy archive stores the top project and every descendant under the same run.
/// A single-project archive has its own run.
/// </summary>
table 50105 "BGB Project Archive Run"
{
    Caption = 'Project Archive Run';
    Access = Public;
    DataClassification = CustomerContent;
    AllowInCustomizations = Never;
    InherentEntitlements = RIMD;
    InherentPermissions = RIMD;

    fields
    {
        field(1; "Run ID"; Guid)
        {
            Caption = 'Archive Run ID';
            ToolTip = 'Specifies the id of the archive run.';
        }
        field(2; "Run At"; DateTime)
        {
            Caption = 'Run At';
            ToolTip = 'Specifies the date and time the run archived the projects.';
        }
        field(3; "User ID"; Code[50])
        {
            Caption = 'User ID';
            ToolTip = 'Specifies the user who started the archive run.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(4; "Top Project No."; Code[20])
        {
            Caption = 'Top Project No.';
            ToolTip = 'Specifies the top-level project of a hierarchy run, or the project of a single-project run.';
            TableRelation = Job;
        }
        field(5; Hierarchy; Boolean)
        {
            Caption = 'Hierarchy';
            ToolTip = 'Specifies that the run archived a top-level project and all of its subprojects.';
        }
    }

    keys
    {
        key(PK; "Run ID")
        {
            Clustered = true;
        }
        key(RunAt; "Run At")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Top Project No.", "Run At") { }
        fieldgroup(Brick; "Top Project No.", "Run At", Hierarchy) { }
    }
}
