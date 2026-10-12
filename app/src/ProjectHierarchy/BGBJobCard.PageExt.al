namespace FlemmingBakkensen.BCGrokBot.ProjectHierarchy;

using Microsoft.Projects.Project.Job;

pageextension 50100 "BGB Job Card" extends "Job Card"
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
        addafter("Job Details")
        {
            part(BGBHierarchyTotals; "BGB Hierarchy Totals FactBox")
            {
                ApplicationArea = Jobs;
                SubPageLink = "No." = field("No."), "Posting Date Filter" = field("Posting Date Filter"), "Planning Date Filter" = field("Planning Date Filter");
            }
            part(BGBSubprojects; "BGB Subprojects")
            {
                ApplicationArea = Jobs;
                SubPageLink = "BGB Parent Project No." = field("No.");
            }
        }
    }

    actions
    {
        addafter("Create Job &Sales Invoice")
        {
            action(BGBCreateHierarchyInvoices)
            {
                ApplicationArea = Jobs;
                Caption = 'Create Hierarchy Sales Invoices';
                Image = JobSalesInvoice;
                ToolTip = 'Create one sales invoice per bill-to customer and currency for this top-level project and all its subprojects.';
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
        addlast(Category_Process)
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
