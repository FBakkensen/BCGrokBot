namespace FlemmingBakkensen.BCGrokBot.ProjectHierarchy;

using Microsoft.Projects.Project.Job;

/// <summary>
/// The direct subprojects of a project.
/// </summary>
page 50102 "BGB Subprojects"
{
    Caption = 'Subprojects';
    Editable = false;
    PageType = ListPart;
    SourceTable = Job;
    ApplicationArea = Jobs;
    CardPageId = "Job Card";

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("No."; Rec."No.") { }
                field(Description; Rec.Description) { }
                field("Bill-to Customer No."; Rec."Bill-to Customer No.") { }
                field(Status; Rec.Status) { }
            }
        }
    }
}
