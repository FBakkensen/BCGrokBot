namespace FlemmingBakkensen.BCGrokBot.SalesAssignment;

using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using System.Security.User;

/// <summary>
/// Rules for the salesperson assignment feature: only the user linked to the bill-to
/// customer's salesperson (User Setup."Salespers./Purch. Code") may create or release
/// in-scope sales documents, and only BGB SALESP ADMIN may change the assignment.
/// </summary>
codeunit 50101 "BGB Sales Assignment Mgt."
{
    Access = Public;
    Permissions = tabledata Customer = r,
                  tabledata "User Setup" = r;

    var
        NoSalespersonErr: Label 'You cannot create or release a sales document for bill-to customer %1 because the customer has no salesperson. Ask an administrator to assign a salesperson to the customer.', Comment = '%1 = customer number';
        NotYourCustomerErr: Label 'Only the user assigned to salesperson %1 can create or release sales documents for bill-to customer %2. You are linked to %3.', Comment = '%1 = salesperson code, %2 = customer number, %3 = salesperson code of the current user, or the text "no salesperson"';
        NoSalespersonLinkedTxt: Label 'no salesperson';
        NoAdminPermErr: Label 'You do not have permission to change the salesperson assignment. The %1 permission set is required.', Comment = '%1 = permission set name';
        AdminPermissionSetTok: Label 'BGB SALESP ADMIN', Locked = true;

    /// <summary>
    /// Returns whether the document type is restricted by the salesperson assignment rule.
    /// </summary>
    /// <param name="DocumentType">The sales document type.</param>
    /// <returns>True for Quote, Order, Invoice and Blanket Order.</returns>
    procedure IsInScope(DocumentType: Enum "Sales Document Type"): Boolean
    begin
        exit(DocumentType in [DocumentType::Quote, DocumentType::Order, DocumentType::Invoice, DocumentType::"Blanket Order"]);
    end;

    /// <summary>
    /// Checks the sales header for the current user. Users with the bypass permission set are not checked.
    /// </summary>
    /// <param name="SalesHeader">The sales header to check.</param>
    procedure CheckSalesHeader(SalesHeader: Record "Sales Header")
    begin
        if not NeedsCheck(SalesHeader) then
            exit;
        CheckBillToAllowedForUser(SalesHeader."Document Type", SalesHeader."Bill-to Customer No.", CopyStr(UserId(), 1, 50));
    end;

    /// <summary>
    /// Checks whether the given user may have the given bill-to customer on a sales document of the given type.
    /// Does not consider the bypass permission set.
    /// </summary>
    /// <param name="DocumentType">The sales document type.</param>
    /// <param name="BillToCustomerNo">The bill-to customer number. Blank is allowed (document not yet assigned).</param>
    /// <param name="UserName">The user ID to check.</param>
    procedure CheckBillToAllowedForUser(DocumentType: Enum "Sales Document Type"; BillToCustomerNo: Code[20]; UserName: Code[50])
    var
        Customer: Record Customer;
        UserSalespersonCode: Code[20];
        UserSalespersonText: Text;
    begin
        if BillToCustomerNo = '' then
            exit;
        if not IsInScope(DocumentType) then
            exit;
        Customer.SetLoadFields("Salesperson Code");
        if not Customer.Get(BillToCustomerNo) then
            exit; // the standard table relation reports unknown customers
        if Customer."Salesperson Code" = '' then
            Error(NoSalespersonErr, BillToCustomerNo);

        UserSalespersonCode := GetUserSalespersonCode(UserName);
        if UserSalespersonCode = Customer."Salesperson Code" then
            exit;

        UserSalespersonText := UserSalespersonCode;
        if UserSalespersonText = '' then
            UserSalespersonText := NoSalespersonLinkedTxt;
        Error(NotYourCustomerErr, Customer."Salesperson Code", BillToCustomerNo, UserSalespersonText);
    end;

    /// <summary>
    /// Returns the salesperson code linked to the user in User Setup, or blank.
    /// </summary>
    /// <param name="UserName">The user ID.</param>
    /// <returns>The linked salesperson code.</returns>
    procedure GetUserSalespersonCode(UserName: Code[50]): Code[20]
    var
        UserSetup: Record "User Setup";
    begin
        UserSetup.SetLoadFields("Salespers./Purch. Code");
        if UserSetup.Get(UserName) then
            exit(UserSetup."Salespers./Purch. Code");
        exit('');
    end;

    /// <summary>
    /// Returns whether the salesperson is linked to any user in User Setup.
    /// </summary>
    /// <param name="SalespersonCode">The salesperson code.</param>
    /// <returns>True if a user is linked.</returns>
    procedure IsSalespersonLinked(SalespersonCode: Code[20]): Boolean
    var
        UserSetup: Record "User Setup";
    begin
        UserSetup.SetCurrentKey("Salespers./Purch. Code");
        UserSetup.SetRange("Salespers./Purch. Code", SalespersonCode);
        exit(not UserSetup.IsEmpty());
    end;

    /// <summary>
    /// Returns whether the sales header must be checked for the current user: a real (non-temporary) in-scope
    /// document with a bill-to customer, and the user does not have the bypass permission set. Does not read the database.
    /// </summary>
    /// <param name="SalesHeader">The sales header.</param>
    /// <returns>True if CheckSalesHeader would evaluate the rule.</returns>
    procedure NeedsCheck(SalesHeader: Record "Sales Header"): Boolean
    begin
        if SalesHeader.IsTemporary() or (SalesHeader."Bill-to Customer No." = '') then
            exit(false);
        if not IsInScope(SalesHeader."Document Type") then
            exit(false);
        exit(not HasBypass());
    end;

    /// <summary>
    /// Returns whether the current user may change salesperson assignments (BGB SALESP ADMIN or SUPER).
    /// </summary>
    /// <returns>True if the user has write permission on the admin permission marker.</returns>
    procedure CanEditAssignment(): Boolean
    var
        AssignAdmin: Record "BGB Salesp. Assign. Admin";
    begin
        exit(AssignAdmin.WritePermission());
    end;

    /// <summary>
    /// Raises an error unless the current user may change salesperson assignments (BGB SALESP ADMIN).
    /// </summary>
    procedure CheckCanEditAssignment()
    begin
        if not CanEditAssignment() then
            Error(NoAdminPermErr, AdminPermissionSetTok);
    end;

    local procedure HasBypass(): Boolean
    var
        AssignBypass: Record "BGB Sales Assign. Bypass";
    begin
        exit(AssignBypass.WritePermission());
    end;
}
