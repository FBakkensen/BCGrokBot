namespace FlemmingBakkensen.BCGrokBot.Test.SalesAssignment;

using Microsoft.CRM.Team;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using System.Security.User;
using System.TestLibraries.Security.AccessControl;
using System.TestLibraries.Utilities;

/// <summary>
/// Container-only tests: they need real permission enforcement (Permissions Mock) and CRONUS setup data.
/// Excluded from al-runner by scripts/test-dev.sh.
/// </summary>
#pragma warning disable AC0031 // Deliberately no Permissions property: it would grant inherent permissions and defeat the Permissions Mock lowering.
codeunit 50152 "BGB Sales Assign. Perm. Tests"
{
    Subtype = Test;
    Access = Internal;
    // Permissions are lowered explicitly per test with Permissions Mock
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        PermissionsMock: Codeunit "Permissions Mock";
        NoSalespersonErrTok: Label 'has no salesperson', Locked = true;
        NotYourCustomerErrTok: Label 'Only the user assigned to salesperson', Locked = true;
        NoAdminPermErrTok: Label 'You do not have permission to change the salesperson assignment', Locked = true;
        SalesUserRoleTok: Label 'D365 BUS FULL ACCESS', Locked = true;
        AppRoleTok: Label 'BCGrokBot', Locked = true;
        AdminRoleTok: Label 'BGB SALESP ADMIN', Locked = true;
        BypassRoleTok: Label 'BGB SALES BYPASS', Locked = true;

    [Test]
    procedure LinkedUserCreatesOrderForOwnCustomer()
    var
        SalesHeader: Record "Sales Header";
        SalespersonCode: Code[20];
        CustomerNo: Code[20];
    begin
        // [SCENARIO] The user linked to the customer's salesperson creates an order via the UI path (validate sell-to)
        // [GIVEN] current user linked to salesperson S, customer C with salesperson S
        SalespersonCode := CreateSalesperson();
        LinkCurrentUserTo(SalespersonCode);
        CustomerNo := CreateCustomer(SalespersonCode);
        // [WHEN] a normal sales user (no bypass) creates an order for C
        StartSalesUser();
        CreateOrderFor(SalesHeader, CustomerNo);
        // [THEN] the order has C as bill-to customer
        Assert.AreEqual(CustomerNo, SalesHeader."Bill-to Customer No.", 'Bill-to customer');
        PermissionsMock.Stop();
    end;

    [Test]
    procedure OrderForOtherSalespersonsCustomerFails()
    var
        SalesHeader: Record "Sales Header";
        CustomerNo: Code[20];
    begin
        // [SCENARIO] Validating sell-to (and so bill-to) to another salesperson's customer fails immediately
        LinkCurrentUserTo(CreateSalesperson());
        CustomerNo := CreateCustomer(CreateSalesperson());
        StartSalesUser();
        asserterror CreateOrderFor(SalesHeader, CustomerNo);
        Assert.ExpectedError(NotYourCustomerErrTok);
        Assert.ExpectedErrorCode('Dialog');
        PermissionsMock.Stop();
    end;

    [Test]
    procedure OrderForCustomerWithoutSalespersonFails()
    var
        SalesHeader: Record "Sales Header";
        CustomerNo: Code[20];
    begin
        // [SCENARIO] A sales document for a bill-to customer without salesperson is impossible
        LinkCurrentUserTo(CreateSalesperson());
        CustomerNo := CreateCustomer('');
        StartSalesUser();
        asserterror CreateOrderFor(SalesHeader, CustomerNo);
        Assert.ExpectedError(NoSalespersonErrTok);
        Assert.ExpectedErrorCode('Dialog');
        PermissionsMock.Stop();
    end;

    [Test]
    procedure DirectBillToAssignmentIsCaughtOnModify()
    var
        SalesHeader: Record "Sales Header";
        SalespersonCode: Code[20];
        OtherCustomerNo: Code[20];
    begin
        // [SCENARIO] Copy Document / TransferFields style changes (no validate) are caught when the record is modified
        // [GIVEN] an order for the user's own customer, and another salesperson's customer
        SalespersonCode := CreateSalesperson();
        LinkCurrentUserTo(SalespersonCode);
        CreateDocumentAsAdmin(SalesHeader, Enum::"Sales Document Type"::Order, CreateCustomer(SalespersonCode));
        OtherCustomerNo := CreateCustomer(CreateSalesperson());
        // [WHEN] the sales user assigns the other customer as bill-to without validation and modifies
        StartSalesUser();
        SalesHeader."Bill-to Customer No." := OtherCustomerNo;
        asserterror SalesHeader.Modify(false);
        // [THEN] the modify is rejected
        Assert.ExpectedError(NotYourCustomerErrTok);
        Assert.ExpectedErrorCode('Dialog');
        PermissionsMock.Stop();
    end;

    [Test]
    procedure ConversionStyleInsertIsCaught()
    var
        SalesHeader: Record "Sales Header";
        OrderHeader: Record "Sales Header";
    begin
        // [SCENARIO] Quote->order and blanket->order copy the header and Insert(true); that insert is checked
        // [GIVEN] a quote for another salesperson's customer (created by an administrator)
        LinkCurrentUserTo(CreateSalesperson());
        CreateDocumentAsAdmin(SalesHeader, Enum::"Sales Document Type"::Quote, CreateCustomer(CreateSalesperson()));
        // [WHEN] the sales user inserts an order copied from it
        StartSalesUser();
        OrderHeader := SalesHeader;
        OrderHeader."Document Type" := OrderHeader."Document Type"::Order;
        OrderHeader."No." := '';
        asserterror OrderHeader.Insert(true);
        // [THEN] the insert is rejected
        Assert.ExpectedError(NotYourCustomerErrTok);
        Assert.ExpectedErrorCode('Dialog');
        PermissionsMock.Stop();
    end;

    [Test]
    procedure ReleaseIsRejectedWhenCustomerLostSalesperson()
    var
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        ReleaseSalesDocument: Codeunit "Release Sales Document";
        SalespersonCode: Code[20];
    begin
        // [SCENARIO] Release is the final gate: data changed after creation is caught on release
        SalespersonCode := CreateSalesperson();
        LinkCurrentUserTo(SalespersonCode);
        CreateDocumentAsAdmin(SalesHeader, Enum::"Sales Document Type"::Order, CreateCustomer(SalespersonCode));
        Customer.Get(SalesHeader."Bill-to Customer No.");
        Customer."Salesperson Code" := '';
        Customer.Modify(false);
        StartSalesUser();
        asserterror ReleaseSalesDocument.PerformManualRelease(SalesHeader);
        Assert.ExpectedError(NoSalespersonErrTok);
        Assert.ExpectedErrorCode('Dialog');
        PermissionsMock.Stop();
    end;

    [Test]
    procedure CreditMemoIsExempt()
    var
        SalesHeader: Record "Sales Header";
    begin
        // [SCENARIO] Credit memos are out of scope, even for a customer without salesperson
        LinkCurrentUserTo(CreateSalesperson());
        StartSalesUser();
        SalesHeader.Init();
        SalesHeader."Document Type" := SalesHeader."Document Type"::"Credit Memo";
        SalesHeader.Insert(true);
        SalesHeader.Validate("Sell-to Customer No.", CreateCustomer(''));
        SalesHeader.Modify(true);
        PermissionsMock.Stop();
    end;

    [Test]
    procedure BypassPermissionSetAllowsIntegrationUser()
    var
        SalesHeader: Record "Sales Header";
        CustomerNo: Code[20];
    begin
        // [SCENARIO] An integration user with BGB SALES BYPASS creates orders for any customer
        CustomerNo := CreateCustomer(CreateSalesperson());
        UnlinkCurrentUser();
        StartSalesUser();
        PermissionsMock.Assign(BypassRoleTok);
        CreateOrderFor(SalesHeader, CustomerNo);
        Assert.AreEqual(CustomerNo, SalesHeader."Bill-to Customer No.", 'Bill-to customer');
        PermissionsMock.Stop();
    end;

    [Test]
    procedure ChangingCustomerSalespersonRequiresAdmin()
    var
        Customer: Record Customer;
        NewSalespersonCode: Code[20];
    begin
        // [SCENARIO] Changing Customer."Salesperson Code" requires BGB SALESP ADMIN
        Customer.Get(CreateCustomer(CreateSalesperson()));
        NewSalespersonCode := CreateSalesperson();
        StartSalesUser();
        asserterror Customer.Validate("Salesperson Code", NewSalespersonCode);
        Assert.ExpectedError(NoAdminPermErrTok);
        Assert.ExpectedErrorCode('Dialog');
        PermissionsMock.Stop();
    end;

    [Test]
    procedure ChangingCustomerSalespersonWithAdminSucceeds()
    var
        Customer: Record Customer;
        NewSalespersonCode: Code[20];
    begin
        // [SCENARIO] With BGB SALESP ADMIN the salesperson can be changed and saved
        Customer.Get(CreateCustomer(CreateSalesperson()));
        NewSalespersonCode := CreateSalesperson();
        StartSalesUser();
        PermissionsMock.Assign(AdminRoleTok);
        Customer.Validate("Salesperson Code", NewSalespersonCode);
        Customer.Modify(true);
        PermissionsMock.Stop();
        Customer.Get(Customer."No.");
        Assert.AreEqual(NewSalespersonCode, Customer."Salesperson Code", 'Salesperson Code');
    end;

    [Test]
    procedure NewCustomerWithSalespersonRequiresAdmin()
    var
        Customer: Record Customer;
    begin
        // [SCENARIO] Setting a salesperson on a new customer also requires BGB SALESP ADMIN (direct insert, e.g. API)
        Customer.Init();
        Customer."No." := NewCode();
        Customer."Salesperson Code" := CreateSalesperson();
        StartSalesUser();
        asserterror Customer.Insert(false);
        Assert.ExpectedError(NoAdminPermErrTok);
        Assert.ExpectedErrorCode('Dialog');
        PermissionsMock.Stop();
    end;

    [Test]
    procedure ChangingUserLinkRequiresAdmin()
    var
        UserSetup: Record "User Setup";
    begin
        // [SCENARIO] Changing User Setup."Salespers./Purch. Code" requires BGB SALESP ADMIN
        UserSetup.Init();
        UserSetup."User ID" := NewCode();
        UserSetup.Insert(false);
        UserSetup."Salespers./Purch. Code" := CreateSalesperson();
        StartSalesUser();
        asserterror UserSetup.Modify(false);
        Assert.ExpectedError(NoAdminPermErrTok);
        Assert.ExpectedErrorCode('Dialog');
        PermissionsMock.Stop();
    end;

    local procedure StartSalesUser()
    begin
        // Lower the execution context: a normal sales user with our app's base permission set, no admin, no bypass
        PermissionsMock.Set(SalesUserRoleTok);
        PermissionsMock.Assign(AppRoleTok);
    end;

    local procedure CreateOrderFor(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20])
    begin
        SalesHeader.Init();
        SalesHeader."Document Type" := SalesHeader."Document Type"::Order;
        SalesHeader.Insert(true);
        SalesHeader.Validate("Sell-to Customer No.", CustomerNo);
        SalesHeader.Modify(true);
    end;

    local procedure CreateDocumentAsAdmin(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20])
    begin
        // Runs with the test runner's own (SUPER) permissions, which pass the bypass check
        SalesHeader.Init();
        SalesHeader."Document Type" := DocumentType;
        SalesHeader.Insert(true);
        SalesHeader.Validate("Sell-to Customer No.", CustomerNo);
        SalesHeader.Modify(true);
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

    local procedure LinkCurrentUserTo(SalespersonCode: Code[20])
    var
        UserSetup: Record "User Setup";
    begin
        if not UserSetup.Get(UserId()) then begin
            UserSetup.Init();
            UserSetup."User ID" := CopyStr(UserId(), 1, MaxStrLen(UserSetup."User ID"));
            UserSetup.Insert(false);
        end;
        UserSetup."Salespers./Purch. Code" := SalespersonCode;
        UserSetup.Modify(false);
    end;

    local procedure UnlinkCurrentUser()
    begin
        LinkCurrentUserTo('');
    end;

    local procedure CreateCustomer(SalespersonCode: Code[20]): Code[20]
    var
        SourceCustomer: Record Customer;
        Customer: Record Customer;
    begin
        // Copy posting setup from an existing CRONUS customer so bill-to validation passes
        SourceCustomer.SetFilter("Customer Posting Group", '<>%1', '');
        SourceCustomer.FindFirst();
        Customer.Init();
        Customer."No." := NewCode();
        Customer.Name := NewCode();
        Customer."Customer Posting Group" := SourceCustomer."Customer Posting Group";
        Customer."Gen. Bus. Posting Group" := SourceCustomer."Gen. Bus. Posting Group";
        Customer."VAT Bus. Posting Group" := SourceCustomer."VAT Bus. Posting Group";
        Customer."Payment Terms Code" := SourceCustomer."Payment Terms Code";
        Customer."Salesperson Code" := SalespersonCode;
        Customer.Insert(false);
        exit(Customer."No.");
    end;

    local procedure NewCode(): Code[20]
    begin
        // Unique per call; the Any library repeats values across tests with codeunit isolation
        exit(CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 20));
    end;
}
#pragma warning restore AC0031
