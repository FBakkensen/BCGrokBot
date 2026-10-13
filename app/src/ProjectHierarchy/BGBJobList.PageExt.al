namespace FlemmingBakkensen.BCGrokBot.ProjectHierarchy;

using FlemmingBakkensen.BCGrokBot.ProjectAnalysis;
using FlemmingBakkensen.BCGrokBot.ProjectVersion;
using Microsoft.Projects.Project.Job;

pageextension 50101 "BGB Job List" extends "Job List"
{
    layout
    {
        addafter(Description)
        {
            field("BGB Parent Project No."; Rec."BGB Parent Project No.")
            {
                ApplicationArea = Jobs;
            }
        }
        addfirst(factboxes)
        {
            part(BGBHierarchyTotals; "BGB Hierarchy Totals FactBox")
            {
                ApplicationArea = Jobs;
                SubPageLink = "No." = field("No."), "Posting Date Filter" = field("Posting Date Filter"), "Planning Date Filter" = field("Planning Date Filter");
            }
        }
    }

    actions
    {
        addlast(reporting)
        {
            action(BGBProjectHierarchyAnalysis)
            {
                ApplicationArea = Jobs;
                Caption = 'Project Hierarchy Analysis';
                Image = AnalysisView;
                ToolTip = 'Analyze the selected projects and all their subprojects in Excel: statistics per project with pivot tables.';

                trigger OnAction()
                var
                    Job: Record Job;
                begin
                    CurrPage.SetSelectionFilter(Job);
                    Report.Run(Report::"BGB Project Hierarchy Analysis", true, false, Job);
                end;
            }
            action(BGBProjectVersionTrendReport)
            {
                ApplicationArea = Jobs;
                Caption = 'Project Version Trend (Excel)';
                Image = Timeline;
                ToolTip = 'Open an Excel workbook of the selected projects and their subprojects, with one row per task and archive version.';

                trigger OnAction()
                var
                    Job: Record Job;
                begin
                    CurrPage.SetSelectionFilter(Job);
                    Report.Run(Report::"BGB Project Version Trend", true, false, Job);
                end;
            }
        }
        addlast(Category_Report)
        {
            actionref(BGBProjectHierarchyAnalysis_Promoted; BGBProjectHierarchyAnalysis) { }
            actionref(BGBProjectVersionTrendReport_Promoted; BGBProjectVersionTrendReport) { }
        }
        addafter("Create Job &Sales Invoice")
        {
            action(BGBCreateHierarchyInvoices)
            {
                ApplicationArea = Jobs;
                Caption = 'Create Hierarchy Sales Invoices';
                Image = JobSalesInvoice;
                ToolTip = 'Create one sales invoice per bill-to customer and currency for the selected top-level project and all its subprojects.';
                Enabled = IsTopLevel;

                trigger OnAction()
                var
                    CreateHierarchyInvoices: Report "BGB Create Hierarchy Invoices";
                    ProjectHierarchyMgt: Codeunit "BGB Project Hierarchy Mgt.";
                begin
                    ProjectHierarchyMgt.CheckTopLevel(Rec);
                    CreateHierarchyInvoices.SetTopProject(Rec."No.");
                    CreateHierarchyInvoices.RunModal();
                end;
            }
        }
        addafter("Create Job &Sales Invoice_Promoted")
        {
            actionref(BGBCreateHierarchyInvoices_Promoted; BGBCreateHierarchyInvoices) { }
        }
        addlast(processing)
        {
            action(BGBArchiveHierarchy)
            {
                ApplicationArea = Jobs;
                Caption = 'Archive Hierarchy';
                Image = Archive;
                ToolTip = 'Archive the selected top-level project and all its subprojects as one archive run.';
                Enabled = IsTopLevel;

                trigger OnAction()
                var
                    ProjectArchiveMgt: Codeunit "BGB Project Archive Mgt.";
                begin
                    ProjectArchiveMgt.ArchiveHierarchy(Rec);
                    Message(HierarchyArchivedMsg, Rec."No.");
                end;
            }
            action(BGBProjectVersionCompare)
            {
                ApplicationArea = Jobs;
                Caption = 'Project Version Compare';
                Image = CompareCOA;
                ToolTip = 'Compare two archive versions of the selected project, or one version and the current figures.';

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
                ToolTip = 'Show the archived versions of the selected project and the current figures, with the change since the previous version.';

                trigger OnAction()
                var
                    ProjectVersionTrend: Page "BGB Project Version Trend";
                begin
                    ProjectVersionTrend.SetProject(Rec."No.");
                    ProjectVersionTrend.Run();
                end;
            }
        }
        addlast(Category_Process)
        {
            actionref(BGBArchiveHierarchy_Promoted; BGBArchiveHierarchy) { }
            actionref(BGBProjectVersionCompare_Promoted; BGBProjectVersionCompare) { }
            actionref(BGBProjectVersionTrend_Promoted; BGBProjectVersionTrend) { }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        IsTopLevel := Rec."BGB Parent Project No." = '';
    end;

    var
        HierarchyArchivedMsg: Label 'Project %1 and its subprojects were archived as one run.', Comment = '%1 = project number';
        IsTopLevel: Boolean;
}
