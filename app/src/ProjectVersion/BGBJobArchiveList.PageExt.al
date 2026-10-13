namespace FlemmingBakkensen.BCGrokBot.ProjectVersion;

using Microsoft.Projects.Project.Archive;
using Microsoft.Projects.Project.Job;

pageextension 50102 "BGB Job Archive List" extends "Job Archive List"
{
    actions
    {
        addlast(navigation)
        {
            action(BGBProjectVersionCompare)
            {
                ApplicationArea = Jobs;
                Caption = 'Project Version Compare';
                Image = CompareCOA;
                ToolTip = 'Compare this archive version with another version or with the current figures.';

                trigger OnAction()
                var
                    ProjectVersionCompare: Page "BGB Project Version Compare";
                begin
                    ProjectVersionCompare.SetProject(Rec."No.");
                    ProjectVersionCompare.Run();
                end;
            }
            action(BGBProjectVersionTrend)
            {
                ApplicationArea = Jobs;
                Caption = 'Project Version Trend';
                Image = Trendscape;
                ToolTip = 'Show the archived versions of this project and the current figures.';

                trigger OnAction()
                var
                    ProjectVersionTrend: Page "BGB Project Version Trend";
                begin
                    ProjectVersionTrend.SetProject(Rec."No.");
                    ProjectVersionTrend.Run();
                end;
            }
        }
    }
}
