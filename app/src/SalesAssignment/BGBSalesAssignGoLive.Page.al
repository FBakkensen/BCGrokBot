namespace FlemmingBakkensen.BCGrokBot.SalesAssignment;

using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Utilities;

/// <summary>
/// Go-live list for the salesperson assignment rule (see codeunit "BGB Sales Assign. Go-Live").
/// </summary>
page 50100 "BGB Sales Assign. Go-Live"
{
    Caption = 'Salesperson Assignment Go-Live Check';
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "BGB Sales Assign. Issue";
    SourceTableTemporary = true;
    Editable = false;
    Extensible = false;
    Permissions = tabledata "Sales Header" = r;
    AboutTitle = 'About the salesperson assignment go-live check';
    AboutText = 'Lists customers that have no salesperson, or whose salesperson is not linked to a user, and open sales documents that cannot be released until that is fixed.';

    layout
    {
        area(Content)
        {
            repeater(Issues)
            {
                field("Issue Type"; Rec."Issue Type") { }
                field("Customer No."; Rec."Customer No.") { }
                field("Customer Name"; Rec."Customer Name") { }
                field("Salesperson Code"; Rec."Salesperson Code") { }
                field("Document Type"; Rec."Document Type") { }
                field("Document No."; Rec."Document No.") { }
                field(Description; Rec.Description) { }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Refresh)
            {
                Caption = 'Refresh';
                Image = Refresh;
                ToolTip = 'Run the go-live check again.';

                trigger OnAction()
                begin
                    LoadIssues();
                end;
            }
        }
        area(Navigation)
        {
            action(OpenCustomer)
            {
                Caption = 'Customer';
                Image = Customer;
                ToolTip = 'Open the customer card.';
                RunObject = page "Customer Card";
                RunPageLink = "No." = field("Customer No.");
            }
            action(OpenDocument)
            {
                Caption = 'Document';
                Image = Document;
                ToolTip = 'Open the sales document.';

                trigger OnAction()
                var
                    SalesHeader: Record "Sales Header";
                    PageManagement: Codeunit "Page Management";
                begin
                    if SalesHeader.Get(Rec."Document Type", Rec."Document No.") then
                        PageManagement.PageRun(SalesHeader);
                end;
            }
        }
        area(Promoted)
        {
            actionref(Refresh_Promoted; Refresh) { }
            actionref(OpenCustomer_Promoted; OpenCustomer) { }
            actionref(OpenDocument_Promoted; OpenDocument) { }
        }
    }

    trigger OnOpenPage()
    begin
        LoadIssues();
    end;

    local procedure LoadIssues()
    var
        GoLiveCheck: Codeunit "BGB Sales Assign. Go-Live";
    begin
        GoLiveCheck.Build(Rec);
        CurrPage.Update(false);
    end;
}
