namespace FlemmingBakkensen.BCGrokBot.ProjectHierarchy;

using Microsoft.Projects.Project.Job;
using Microsoft.Sales.Setup;

/// <summary>
/// Creates one sales invoice per bill-to customer and currency for a whole project hierarchy. Run it on a top-level project.
/// </summary>
report 50100 "BGB Create Hierarchy Invoices"
{
    Caption = 'Create Hierarchy Sales Invoices';
    ApplicationArea = Jobs;
    ProcessingOnly = true;
    UsageCategory = None;

    requestpage
    {
        layout
        {
            area(Content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(TopProjectNoField; TopProjectNo)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Top-Level Project No.';
                        ToolTip = 'Specifies the top-level project. Invoices are created for this project and all its subprojects.';
                        TableRelation = Job where("BGB Parent Project No." = const(''));
                    }
                    field(PostingDateField; PostingDate)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Posting Date';
                        ToolTip = 'Specifies the posting date for the invoices.';

                        trigger OnValidate()
                        var
                            SalesReceivablesSetup: Record "Sales & Receivables Setup";
                        begin
                            SalesReceivablesSetup.SetLoadFields("Link Doc. Date To Posting Date");
                            SalesReceivablesSetup.GetRecordOnce();
                            if SalesReceivablesSetup."Link Doc. Date To Posting Date" then
                                DocumentDate := PostingDate;
                        end;
                    }
                    field(DocumentDateField; DocumentDate)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Document Date';
                        ToolTip = 'Specifies the document date for the invoices.';
                    }
                    field(PlanningDateFilterField; PlanningDateFilter)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Planning Date Filter';
                        ToolTip = 'Specifies an optional filter on the planning date of the project planning lines to invoice.';
                    }
                }
            }
        }

        trigger OnOpenPage()
        begin
            if PostingDate = 0D then
                PostingDate := WorkDate();
            if DocumentDate = 0D then
                DocumentDate := WorkDate();
        end;
    }

    trigger OnPreReport()
    var
        HierarchyInvoicing: Codeunit "BGB Hierarchy Invoicing";
    begin
        if TopProjectNo = '' then
            Error(ProjectRequiredErr);
        NoOfInvoices := HierarchyInvoicing.CreateInvoices(TopProjectNo, PostingDate, DocumentDate, PlanningDateFilter).Count();
    end;

    trigger OnPostReport()
    begin
        if GuiAllowed() then
            Message(InvoicesCreatedMsg, NoOfInvoices);
    end;

    var
        TopProjectNo: Code[20];
        PostingDate: Date;
        DocumentDate: Date;
        PlanningDateFilter: Text;
        NoOfInvoices: Integer;
        ProjectRequiredErr: Label 'You must specify a top-level project.';
        InvoicesCreatedMsg: Label '%1 sales invoice(s) were created.', Comment = '%1 = number of invoices';

    /// <summary>
    /// Sets the top-level project shown on the request page.
    /// </summary>
    /// <param name="NewTopProjectNo">The top-level project number.</param>
    procedure SetTopProject(NewTopProjectNo: Code[20])
    begin
        TopProjectNo := NewTopProjectNo;
    end;
}
