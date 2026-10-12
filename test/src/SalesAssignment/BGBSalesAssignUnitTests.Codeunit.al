namespace FlemmingBakkensen.BCGrokBot.Test.SalesAssignment;

using FlemmingBakkensen.BCGrokBot.SalesAssignment;
using Microsoft.CRM.Team;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using System.Security.User;
using System.TestLibraries.Utilities;

codeunit 50151 "BGB Sales Assign. Unit Tests"
{
    Subtype = Test;
    Access = Internal;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        SalesAssignmentMgt: Codeunit "BGB Sales Assignment Mgt.";
        NoSalespersonErrTok: Label 'has no salesperson', Locked = true;
        NotYourCustomerErrTok: Label 'Only the user assigned to salesperson', Locked = true;

    [Test]
    procedure InScopeDocumentTypes()
    begin
        // [SCENARIO] Quote, Order, Invoice and Blanket Order are in scope; Credit Memo and Return Order are exempt
        Assert.IsTrue(SalesAssignmentMgt.IsInScope(Enum::"Sales Document Type"::Quote), 'Quote');
        Assert.IsTrue(SalesAssignmentMgt.IsInScope(Enum::"Sales Document Type"::Order), 'Order');
        Assert.IsTrue(SalesAssignmentMgt.IsInScope(Enum::"Sales Document Type"::Invoice), 'Invoice');
        Assert.IsTrue(SalesAssignmentMgt.IsInScope(Enum::"Sales Document Type"::"Blanket Order"), 'Blanket Order');
        Assert.IsFalse(SalesAssignmentMgt.IsInScope(Enum::"Sales Document Type"::"Credit Memo"), 'Credit Memo');
        Assert.IsFalse(SalesAssignmentMgt.IsInScope(Enum::"Sales Document Type"::"Return Order"), 'Return Order');
    end;

    [Test]
    procedure CustomerWithoutSalespersonIsRejected()
    var
        CustomerNo: Code[20];
    begin
        // [SCENARIO] An in-scope document for a bill-to customer without salesperson is impossible
        // [GIVEN] a customer without salesperson and a user linked to a salesperson
        CustomerNo := CreateCustomer('');
        // [WHEN] the bill-to customer is checked for an order
        asserterror SalesAssignmentMgt.CheckBillToAllowedForUser(Enum::"Sales Document Type"::Order, CustomerNo, CreateUserLinkedTo(CreateSalesperson()));
        // [THEN] the no-salesperson error is raised
        Assert.ExpectedError(NoSalespersonErrTok);
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    procedure LinkedUserIsAllowed()
    var
        SalespersonCode: Code[20];
        CustomerNo: Code[20];
    begin
        // [SCENARIO] The user linked to the customer's salesperson may create documents
        SalespersonCode := CreateSalesperson();
        CustomerNo := CreateCustomer(SalespersonCode);
        // [WHEN] the linked user is checked for each in-scope type
        // [THEN] no error
        SalesAssignmentMgt.CheckBillToAllowedForUser(Enum::"Sales Document Type"::Quote, CustomerNo, CreateUserLinkedTo(SalespersonCode));
    end;

    [Test]
    procedure UserOfOtherSalespersonIsRejected()
    var
        CustomerNo: Code[20];
    begin
        // [SCENARIO] A user linked to a different salesperson is rejected
        CustomerNo := CreateCustomer(CreateSalesperson());
        asserterror SalesAssignmentMgt.CheckBillToAllowedForUser(Enum::"Sales Document Type"::Invoice, CustomerNo, CreateUserLinkedTo(CreateSalesperson()));
        Assert.ExpectedError(NotYourCustomerErrTok);
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    procedure UnlinkedUserIsRejected()
    var
        CustomerNo: Code[20];
    begin
        // [SCENARIO] A user without salesperson link is rejected for a customer with salesperson
        CustomerNo := CreateCustomer(CreateSalesperson());
        asserterror SalesAssignmentMgt.CheckBillToAllowedForUser(Enum::"Sales Document Type"::"Blanket Order", CustomerNo, NewCode());
        Assert.ExpectedError(NotYourCustomerErrTok);
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    procedure ExemptTypesAreNotChecked()
    var
        CustomerNo: Code[20];
    begin
        // [SCENARIO] Credit memos and return orders are exempt even without salesperson
        CustomerNo := CreateCustomer('');
        SalesAssignmentMgt.CheckBillToAllowedForUser(Enum::"Sales Document Type"::"Credit Memo", CustomerNo, NewCode());
        SalesAssignmentMgt.CheckBillToAllowedForUser(Enum::"Sales Document Type"::"Return Order", CustomerNo, NewCode());
    end;

    [Test]
    procedure BlankBillToIsNotChecked()
    begin
        // [SCENARIO] A document without bill-to customer yet (new document) is not checked
        SalesAssignmentMgt.CheckBillToAllowedForUser(Enum::"Sales Document Type"::Order, '', NewCode());
    end;

    [Test]
    procedure GoLiveListsCustomersAndOpenDocuments()
    var
        TempIssue: Record "BGB Sales Assign. Issue" temporary;
        GoLiveCheck: Codeunit "BGB Sales Assign. Go-Live";
        NoSalespersonCustNo: Code[20];
        UnlinkedCustNo: Code[20];
        OkCustNo: Code[20];
        OrderNo: Code[20];
        CreditMemoNo: Code[20];
        ReleasedOrderNo: Code[20];
    begin
        // [SCENARIO] The go-live check lists customers without (linked) salesperson and open in-scope documents that would fail
        // [GIVEN] a customer without salesperson, one with an unlinked salesperson, one with a linked salesperson
        NoSalespersonCustNo := CreateCustomer('');
        UnlinkedCustNo := CreateCustomer(CreateSalesperson());
        OkCustNo := CreateCustomer(CreateSalespersonWithUser());
        // [GIVEN] an open order and a credit memo for the customer without salesperson, a released order, and an order for the OK customer
        OrderNo := CreateSalesDocument(Enum::"Sales Document Type"::Order, NoSalespersonCustNo, Enum::"Sales Document Status"::Open);
        CreditMemoNo := CreateSalesDocument(Enum::"Sales Document Type"::"Credit Memo", NoSalespersonCustNo, Enum::"Sales Document Status"::Open);
        ReleasedOrderNo := CreateSalesDocument(Enum::"Sales Document Type"::Order, NoSalespersonCustNo, Enum::"Sales Document Status"::Released);
        CreateSalesDocument(Enum::"Sales Document Type"::Order, OkCustNo, Enum::"Sales Document Status"::Open);

        // [WHEN] the go-live check is built
        GoLiveCheck.Build(TempIssue);

        // [THEN] customer issues are listed
        Assert.IsTrue(HasIssue(TempIssue, Enum::"BGB Sales Assign. Issue Type"::"Customer Without Salesperson", NoSalespersonCustNo, ''), 'customer without salesperson');
        Assert.IsTrue(HasIssue(TempIssue, Enum::"BGB Sales Assign. Issue Type"::"Salesperson Not Linked", UnlinkedCustNo, ''), 'unlinked salesperson');
        Assert.IsFalse(HasIssue(TempIssue, Enum::"BGB Sales Assign. Issue Type"::"Customer Without Salesperson", OkCustNo, ''), 'OK customer listed');
        Assert.IsFalse(HasIssue(TempIssue, Enum::"BGB Sales Assign. Issue Type"::"Salesperson Not Linked", OkCustNo, ''), 'OK customer listed as unlinked');
        // [THEN] only the open in-scope document is listed
        Assert.IsTrue(HasIssue(TempIssue, Enum::"BGB Sales Assign. Issue Type"::"Open Document Would Fail", NoSalespersonCustNo, OrderNo), 'open order');
        Assert.IsFalse(HasIssue(TempIssue, Enum::"BGB Sales Assign. Issue Type"::"Open Document Would Fail", NoSalespersonCustNo, CreditMemoNo), 'credit memo listed');
        Assert.IsFalse(HasIssue(TempIssue, Enum::"BGB Sales Assign. Issue Type"::"Open Document Would Fail", NoSalespersonCustNo, ReleasedOrderNo), 'released order listed');
        Assert.IsFalse(HasIssue(TempIssue, Enum::"BGB Sales Assign. Issue Type"::"Open Document Would Fail", OkCustNo, ''), 'OK customer document listed');
    end;

    local procedure HasIssue(var TempIssue: Record "BGB Sales Assign. Issue" temporary; IssueType: Enum "BGB Sales Assign. Issue Type"; CustomerNo: Code[20]; DocumentNo: Code[20]): Boolean
    begin
        TempIssue.Reset();
        TempIssue.SetRange("Issue Type", IssueType);
        TempIssue.SetRange("Customer No.", CustomerNo);
        if DocumentNo <> '' then
            TempIssue.SetRange("Document No.", DocumentNo);
        exit(not TempIssue.IsEmpty());
    end;

    local procedure CreateSalesperson(): Code[20]
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
    begin
        SalespersonPurchaser.Init();
        SalespersonPurchaser.Code := NewCode();
        SalespersonPurchaser.Name := NewCode();
        SalespersonPurchaser.Insert(false);
        exit(SalespersonPurchaser.Code);
    end;

    local procedure CreateSalespersonWithUser(): Code[20]
    var
        SalespersonCode: Code[20];
    begin
        SalespersonCode := CreateSalesperson();
        CreateUserLinkedTo(SalespersonCode);
        exit(SalespersonCode);
    end;

    local procedure CreateUserLinkedTo(SalespersonCode: Code[20]): Code[50]
    var
        UserSetup: Record "User Setup";
    begin
        UserSetup.Init();
        UserSetup."User ID" := NewCode();
        UserSetup."Salespers./Purch. Code" := SalespersonCode;
        UserSetup.Insert(false);
        exit(UserSetup."User ID");
    end;

    local procedure CreateCustomer(SalespersonCode: Code[20]): Code[20]
    var
        Customer: Record Customer;
    begin
        Customer.Init();
        Customer."No." := NewCode();
        Customer.Name := NewCode();
        Customer."Salesperson Code" := SalespersonCode;
        Customer.Insert(false);
        exit(Customer."No.");
    end;

    local procedure CreateSalesDocument(DocumentType: Enum "Sales Document Type"; BillToCustomerNo: Code[20]; Status: Enum "Sales Document Status"): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.Init();
        SalesHeader."Document Type" := DocumentType;
        SalesHeader."No." := NewCode();
        SalesHeader."Sell-to Customer No." := BillToCustomerNo;
        SalesHeader."Bill-to Customer No." := BillToCustomerNo;
        SalesHeader.Status := Status;
        SalesHeader.Insert(false);
        exit(SalesHeader."No.");
    end;

    local procedure NewCode(): Code[20]
    begin
        // Unique per call; the Any library repeats values across tests with codeunit isolation
        exit(CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 20));
    end;
}
