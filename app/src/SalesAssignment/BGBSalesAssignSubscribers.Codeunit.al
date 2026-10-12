namespace FlemmingBakkensen.BCGrokBot.SalesAssignment;

using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using System.Security.User;

codeunit 50102 "BGB Sales Assign. Subscribers"
{
    Access = Internal;
    Permissions = tabledata Customer = r,
                  tabledata "Sales Header" = r,
                  tabledata "User Setup" = r;

    var
        SalesAssignmentMgt: Codeunit "BGB Sales Assignment Mgt.";

    // ---- Sales documents: creation ----

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", OnAfterCheckBillToCust, '', false, false)]
    local procedure SalesHeaderOnAfterCheckBillToCust(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header"; Customer: Record Customer)
    begin
        // Immediate feedback when bill-to (or sell-to, which sets bill-to) is validated
        SalesAssignmentMgt.CheckSalesHeader(SalesHeader);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", OnBeforeInsertEvent, '', false, false)]
    local procedure SalesHeaderOnBeforeInsert(var Rec: Record "Sales Header"; RunTrigger: Boolean)
    begin
        // Inserts that carry a bill-to customer without validation: quote/blanket to order, API, data import
        if Rec.IsTemporary() then
            exit;
        SalesAssignmentMgt.CheckSalesHeader(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", OnBeforeModifyEvent, '', false, false)]
    local procedure SalesHeaderOnBeforeModify(var Rec: Record "Sales Header"; var xRec: Record "Sales Header"; RunTrigger: Boolean)
    var
        StoredSalesHeader: Record "Sales Header";
    begin
        // Direct assignments without validation (Copy Document, TransferFields + Modify)
        // Cheap in-memory guards first: this fires on every sales header modify
        if not SalesAssignmentMgt.NeedsCheck(Rec) then
            exit;
        StoredSalesHeader.SetLoadFields("Bill-to Customer No.");
        if StoredSalesHeader.Get(Rec."Document Type", Rec."No.") then
            if StoredSalesHeader."Bill-to Customer No." = Rec."Bill-to Customer No." then
                exit;
        SalesAssignmentMgt.CheckSalesHeader(Rec);
    end;

    // ---- Sales documents: release (also runs when an open document is posted) ----

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Release Sales Document", OnBeforeReleaseSalesDoc, '', false, false)]
    local procedure ReleaseOnBeforeReleaseSalesDoc(var SalesHeader: Record "Sales Header"; PreviewMode: Boolean; var IsHandled: Boolean; var SkipCheckReleaseRestrictions: Boolean; SkipWhseRequestOperations: Boolean)
    begin
        SalesAssignmentMgt.CheckSalesHeader(SalesHeader);
    end;

    // ---- Customer."Salesperson Code" ----

    [EventSubscriber(ObjectType::Table, Database::Customer, OnBeforeValidateEvent, "Salesperson Code", false, false)]
    local procedure CustomerOnBeforeValidateSalespersonCode(var Rec: Record Customer; var xRec: Record Customer; CurrFieldNo: Integer)
    begin
        if Rec.IsTemporary() or (Rec."Salesperson Code" = xRec."Salesperson Code") then
            exit;
        SalesAssignmentMgt.CheckCanEditAssignment();
    end;

    [EventSubscriber(ObjectType::Table, Database::Customer, OnBeforeInsertEvent, '', false, false)]
    local procedure CustomerOnBeforeInsert(var Rec: Record Customer; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() or (Rec."Salesperson Code" = '') then
            exit;
        SalesAssignmentMgt.CheckCanEditAssignment();
    end;

    [EventSubscriber(ObjectType::Table, Database::Customer, OnBeforeModifyEvent, '', false, false)]
    local procedure CustomerOnBeforeModify(var Rec: Record Customer; var xRec: Record Customer; RunTrigger: Boolean)
    var
        StoredCustomer: Record Customer;
    begin
        // Cheap in-memory guards first: this fires on every customer modify
        if Rec.IsTemporary() or SalesAssignmentMgt.CanEditAssignment() then
            exit;
        StoredCustomer.SetLoadFields("Salesperson Code");
        if not StoredCustomer.Get(Rec."No.") then
            exit;
        if StoredCustomer."Salesperson Code" <> Rec."Salesperson Code" then
            SalesAssignmentMgt.CheckCanEditAssignment();
    end;

    // ---- User Setup."Salespers./Purch. Code" (the salesperson-user link) ----

    [EventSubscriber(ObjectType::Table, Database::"User Setup", OnBeforeValidateEvent, "Salespers./Purch. Code", false, false)]
    local procedure UserSetupOnBeforeValidateSalespersonCode(var Rec: Record "User Setup"; var xRec: Record "User Setup"; CurrFieldNo: Integer)
    begin
        if Rec.IsTemporary() or (Rec."Salespers./Purch. Code" = xRec."Salespers./Purch. Code") then
            exit;
        SalesAssignmentMgt.CheckCanEditAssignment();
    end;

    [EventSubscriber(ObjectType::Table, Database::"User Setup", OnBeforeInsertEvent, '', false, false)]
    local procedure UserSetupOnBeforeInsert(var Rec: Record "User Setup"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() or (Rec."Salespers./Purch. Code" = '') then
            exit;
        SalesAssignmentMgt.CheckCanEditAssignment();
    end;

    [EventSubscriber(ObjectType::Table, Database::"User Setup", OnBeforeModifyEvent, '', false, false)]
    local procedure UserSetupOnBeforeModify(var Rec: Record "User Setup"; var xRec: Record "User Setup"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() or SalesAssignmentMgt.CanEditAssignment() then
            exit;
        if GetStoredUserSalesperson(Rec."User ID") <> Rec."Salespers./Purch. Code" then
            SalesAssignmentMgt.CheckCanEditAssignment();
    end;

    [EventSubscriber(ObjectType::Table, Database::"User Setup", OnBeforeDeleteEvent, '', false, false)]
    local procedure UserSetupOnBeforeDelete(var Rec: Record "User Setup"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() or SalesAssignmentMgt.CanEditAssignment() then
            exit;
        if GetStoredUserSalesperson(Rec."User ID") <> '' then
            SalesAssignmentMgt.CheckCanEditAssignment();
    end;

    [EventSubscriber(ObjectType::Table, Database::"User Setup", OnBeforeRenameEvent, '', false, false)]
    local procedure UserSetupOnBeforeRename(var Rec: Record "User Setup"; var xRec: Record "User Setup"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() or SalesAssignmentMgt.CanEditAssignment() then
            exit;
        if GetStoredUserSalesperson(xRec."User ID") <> '' then
            SalesAssignmentMgt.CheckCanEditAssignment();
    end;

    local procedure GetStoredUserSalesperson(UserName: Code[50]): Code[20]
    var
        StoredUserSetup: Record "User Setup";
    begin
        StoredUserSetup.SetLoadFields("Salespers./Purch. Code");
        if StoredUserSetup.Get(UserName) then
            exit(StoredUserSetup."Salespers./Purch. Code");
        exit('');
    end;
}
