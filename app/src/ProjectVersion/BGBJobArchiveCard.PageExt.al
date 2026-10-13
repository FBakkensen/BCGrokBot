namespace FlemmingBakkensen.BCGrokBot.ProjectVersion;

using Microsoft.Projects.Project.Archive;
using Microsoft.Projects.Project.Job;

pageextension 50103 "BGB Job Archive Card" extends "Job Archive Card"
{
    actions
    {
        addlast(processing)
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
            action(BGBProjectVersionTrendReport)
            {
                ApplicationArea = Jobs;
                Caption = 'Project Version Trend (Excel)';
                Image = Timeline;
                ToolTip = 'Open an Excel workbook of this project and its subprojects, with one row per task and archive version.';

                trigger OnAction()
                var
                    Job: Record Job;
                begin
                    Job.SetRange("No.", Rec."No.");
                    Report.Run(Report::"BGB Project Version Trend", true, false, Job);
                end;
            }
        }
    }
}
