namespace FlemmingBakkensen.BCGrokBot.ProjectHierarchy;

using FlemmingBakkensen.BCGrokBot.ProjectAnalysis;
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
        }
        addlast(Category_Report)
        {
            actionref(BGBProjectHierarchyAnalysis_Promoted; BGBProjectHierarchyAnalysis) { }
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
    }

    trigger OnAfterGetCurrRecord()
    begin
        IsTopLevel := Rec."BGB Parent Project No." = '';
    end;

    var
        IsTopLevel: Boolean;
}
