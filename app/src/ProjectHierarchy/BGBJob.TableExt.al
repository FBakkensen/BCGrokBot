namespace FlemmingBakkensen.BCGrokBot.ProjectHierarchy;

using Microsoft.Projects.Project.Job;

tableextension 50100 "BGB Job" extends Job
{
    fields
    {
        field(50100; "BGB Parent Project No."; Code[20])
        {
            Caption = 'Parent Project No.';
            ToolTip = 'Specifies the project that this project is a subproject of. Leave it blank for a top-level project.';
            DataClassification = CustomerContent;
            AllowInCustomizations = AsReadWrite;
            TableRelation = Job;

            trigger OnValidate()
            var
                ProjectHierarchyMgt: Codeunit "BGB Project Hierarchy Mgt.";
            begin
                ProjectHierarchyMgt.CheckParent(Rec."No.", Rec."BGB Parent Project No.");
            end;
        }
    }

    keys
    {
        key(BGBParentProject; "BGB Parent Project No.") { }
    }
}
