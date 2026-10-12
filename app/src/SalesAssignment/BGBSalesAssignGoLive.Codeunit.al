namespace FlemmingBakkensen.BCGrokBot.SalesAssignment;

using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;

/// <summary>
/// Builds the go-live list: customers without (linked) salesperson and open in-scope
/// sales documents that would be blocked by the salesperson assignment rule for every user.
/// </summary>
codeunit 50103 "BGB Sales Assign. Go-Live"
{
    Access = Public;
    Permissions = tabledata Customer = r,
                  tabledata "Sales Header" = r;

    var
        SalesAssignmentMgt: Codeunit "BGB Sales Assignment Mgt.";
        AssignSalespersonTxt: Label 'Assign a salesperson to the customer.';
        LinkSalespersonTxt: Label 'Link salesperson %1 to a user in User Setup.', Comment = '%1 = salesperson code';
        DocumentWouldFailTxt: Label 'The bill-to customer has no salesperson linked to a user; the document cannot be released.';

    /// <summary>
    /// Fills the buffer with all go-live issues.
    /// </summary>
    /// <param name="TempIssue">The temporary buffer to fill. Existing entries are deleted.</param>
    procedure Build(var TempIssue: Record "BGB Sales Assign. Issue" temporary)
    var
        TempBlockedCustomer: Record Customer temporary;
        EntryNo: Integer;
    begin
        TempIssue.Reset();
        TempIssue.DeleteAll(false);
        AddCustomerIssues(TempIssue, EntryNo, TempBlockedCustomer);
        AddDocumentIssues(TempIssue, EntryNo, TempBlockedCustomer);
        TempIssue.Reset();
    end;

    local procedure AddCustomerIssues(var TempIssue: Record "BGB Sales Assign. Issue" temporary; var EntryNo: Integer; var TempBlockedCustomer: Record Customer temporary)
    var
        Customer: Record Customer;
        SalespersonLinked: Dictionary of [Code[20], Boolean];
    begin
        Customer.SetLoadFields("No.", Name, "Salesperson Code");
        if not Customer.FindSet() then
            exit;
        repeat
            if Customer."Salesperson Code" = '' then begin
                AddIssue(TempIssue, EntryNo, Enum::"BGB Sales Assign. Issue Type"::"Customer Without Salesperson", Customer, AssignSalespersonTxt);
                AddBlocked(TempBlockedCustomer, Customer);
            end else
                if not IsLinkedCached(SalespersonLinked, Customer."Salesperson Code") then begin
                    AddIssue(TempIssue, EntryNo, Enum::"BGB Sales Assign. Issue Type"::"Salesperson Not Linked", Customer, StrSubstNo(LinkSalespersonTxt, Customer."Salesperson Code"));
                    AddBlocked(TempBlockedCustomer, Customer);
                end;
        until Customer.Next() = 0;
    end;

    local procedure AddDocumentIssues(var TempIssue: Record "BGB Sales Assign. Issue" temporary; var EntryNo: Integer; var TempBlockedCustomer: Record Customer temporary)
    var
        SalesHeader: Record "Sales Header";
    begin
        if TempBlockedCustomer.IsEmpty() then
            exit;
        SalesHeader.SetLoadFields("Document Type", "No.", "Bill-to Customer No.", Status);
        SalesHeader.SetRange(Status, SalesHeader.Status::Open);
        SalesHeader.SetFilter("Document Type", '%1|%2|%3|%4', SalesHeader."Document Type"::Quote, SalesHeader."Document Type"::Order, SalesHeader."Document Type"::Invoice, SalesHeader."Document Type"::"Blanket Order");
        SalesHeader.SetFilter("Bill-to Customer No.", '<>%1', '');
        if not SalesHeader.FindSet() then
            exit;
        repeat
            if TempBlockedCustomer.Get(SalesHeader."Bill-to Customer No.") then begin
                AddIssue(TempIssue, EntryNo, Enum::"BGB Sales Assign. Issue Type"::"Open Document Would Fail", TempBlockedCustomer, DocumentWouldFailTxt);
                TempIssue."Document Type" := SalesHeader."Document Type";
                TempIssue."Document No." := SalesHeader."No.";
                TempIssue.Modify(false);
            end;
        until SalesHeader.Next() = 0;
    end;

    local procedure IsLinkedCached(var SalespersonLinked: Dictionary of [Code[20], Boolean]; SalespersonCode: Code[20]): Boolean
    var
        Linked: Boolean;
    begin
        // Many customers share a salesperson: look each salesperson up once
        if not SalespersonLinked.Get(SalespersonCode, Linked) then begin
            Linked := SalesAssignmentMgt.IsSalespersonLinked(SalespersonCode);
            SalespersonLinked.Add(SalespersonCode, Linked);
        end;
        exit(Linked);
    end;

    local procedure AddIssue(var TempIssue: Record "BGB Sales Assign. Issue" temporary; var EntryNo: Integer; IssueType: Enum "BGB Sales Assign. Issue Type"; Customer: Record Customer; Description: Text)
    begin
        EntryNo += 1;
        TempIssue.Init();
        TempIssue."Entry No." := EntryNo;
        TempIssue."Issue Type" := IssueType;
        TempIssue."Customer No." := Customer."No.";
        TempIssue."Customer Name" := Customer.Name;
        TempIssue."Salesperson Code" := Customer."Salesperson Code";
        TempIssue.Description := CopyStr(Description, 1, MaxStrLen(TempIssue.Description));
        TempIssue.Insert(false);
    end;

    local procedure AddBlocked(var TempBlockedCustomer: Record Customer temporary; Customer: Record Customer)
    begin
        TempBlockedCustomer := Customer;
        TempBlockedCustomer.Insert(false);
    end;
}
