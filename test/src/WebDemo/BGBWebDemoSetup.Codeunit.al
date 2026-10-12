namespace FlemmingBakkensen.BCGrokBot.Test.WebDemo;

using FlemmingBakkensen.BCGrokBot.ProjectAnalysis;
using FlemmingBakkensen.BCGrokBot.ProjectHierarchy;
using FlemmingBakkensen.BCGrokBot.Test.ProjectHierarchy;
using Microsoft.CRM.Team;
using Microsoft.Projects.Project.Job;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using System.Security.User;
using System.Text;
using System.Utilities;

/// <summary>
/// Dev/verification only (lives in the test app, never shipped): idempotent demo data for web client verification
/// of the salesperson assignment feature. Exposed as OData web service BGBWebDemo, called by scripts/setup-web-demo.sh.
/// </summary>
codeunit 50153 "BGB Web Demo Setup"
{
    Access = Public;
    Permissions = tabledata Customer = rim,
                  tabledata Job = rmd,
                  tabledata "Sales Header" = rimd,
                  tabledata "Salesperson/Purchaser" = rim,
                  tabledata "User Setup" = rim;

    var
        SalesUserTok: Label 'SALESUSER1', Locked = true;
        OwnSalespersonTok: Label 'BGB-SP1', Locked = true;
        OtherSalespersonTok: Label 'BGB-SP2', Locked = true;
        OwnCustomerTok: Label 'BGB-C-OWN', Locked = true;
        OtherCustomerTok: Label 'BGB-C-OTHER', Locked = true;
        NoSalespersonCustomerTok: Label 'BGB-C-NOSP', Locked = true;
        ProjCustomerATok: Label 'BGB-PC-A', Locked = true;
        ProjCustomerBTok: Label 'BGB-PC-B', Locked = true;
        ProjSellToTok: Label 'BGB-PC-S', Locked = true;
        ProjTopTok: Label 'BGB-P-TOP', Locked = true;
        ProjChild1Tok: Label 'BGB-P-C1', Locked = true;
        ProjChild2Tok: Label 'BGB-P-C2', Locked = true;
        ProjGrandChild1Tok: Label 'BGB-P-G1', Locked = true;
        ProjGrandChild2Tok: Label 'BGB-P-G2', Locked = true;
        ProjDoneTok: Label 'OK: %1 <- %2, %3; %3 <- %4 (%6), %5', Locked = true;
        DoneTok: Label 'OK: %1 -> %2; customers %3 (%2), %4 (%5), %6 (no salesperson); go-live order %7', Locked = true;

    /// <summary>
    /// Creates or resets the demo salespersons, the SALESUSER1 user setup link, the three demo customers
    /// and one open order for the customer without salesperson.
    /// </summary>
    /// <returns>A summary of the demo data.</returns>
    procedure SetupDemo(): Text
    var
        OrderNo: Code[20];
    begin
        UpsertSalesperson(OwnSalespersonTok, 'Sally Sales (SALESUSER1)');
        UpsertSalesperson(OtherSalespersonTok, 'Oscar Other');
        UpsertUserSetup(SalesUserTok, OwnSalespersonTok);
        UpsertCustomer(OwnCustomerTok, 'BGB Own Customer (SALESUSER1)', OwnSalespersonTok);
        UpsertCustomer(OtherCustomerTok, 'BGB Other Salesperson Customer', OtherSalespersonTok);
        UpsertCustomer(NoSalespersonCustomerTok, 'BGB Customer Without Salesperson', '');
        OrderNo := EnsureGoLiveOrder(NoSalespersonCustomerTok);
        exit(StrSubstNo(DoneTok, SalesUserTok, OwnSalespersonTok, OwnCustomerTok, OtherCustomerTok, OtherSalespersonTok, NoSalespersonCustomerTok, OrderNo));
    end;

    local procedure UpsertSalesperson(SalespersonCode: Code[20]; SalespersonName: Text[50])
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
    begin
        if not SalespersonPurchaser.Get(SalespersonCode) then begin
            SalespersonPurchaser.Init();
            SalespersonPurchaser.Code := SalespersonCode;
            SalespersonPurchaser.Insert(true);
        end;
        SalespersonPurchaser.Name := SalespersonName;
        SalespersonPurchaser.Modify(true);
    end;

    local procedure UpsertUserSetup(UserName: Code[50]; SalespersonCode: Code[20])
    var
        UserSetup: Record "User Setup";
    begin
        if not UserSetup.Get(UserName) then begin
            UserSetup.Init();
            UserSetup."User ID" := UserName;
            UserSetup.Insert(false);
        end;
        UserSetup."Salespers./Purch. Code" := SalespersonCode;
        UserSetup.Modify(false);
    end;

    local procedure UpsertCustomer(CustomerNo: Code[20]; CustomerName: Text[100]; SalespersonCode: Code[20])
    var
        SourceCustomer: Record Customer;
        Customer: Record Customer;
    begin
        SourceCustomer.SetFilter("Customer Posting Group", '<>%1', '');
        SourceCustomer.SetFilter("No.", '<>BGB-*');
        if not SourceCustomer.FindFirst() then
            exit;
        if not Customer.Get(CustomerNo) then begin
            Customer.Init();
            Customer."No." := CustomerNo;
            Customer.Insert(false);
        end;
        Customer.Name := CustomerName;
        Customer."Customer Posting Group" := SourceCustomer."Customer Posting Group";
        Customer."Gen. Bus. Posting Group" := SourceCustomer."Gen. Bus. Posting Group";
        Customer."VAT Bus. Posting Group" := SourceCustomer."VAT Bus. Posting Group";
        Customer."Payment Terms Code" := SourceCustomer."Payment Terms Code";
        Customer."Country/Region Code" := SourceCustomer."Country/Region Code";
        Customer."Salesperson Code" := SalespersonCode;
        Customer.Modify(false);
    end;

    local procedure EnsureGoLiveOrder(CustomerNo: Code[20]): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
        SalesHeader.SetRange("Bill-to Customer No.", CustomerNo);
        if SalesHeader.FindFirst() then
            exit(SalesHeader."No.");
        SalesHeader.Init();
        SalesHeader."Document Type" := SalesHeader."Document Type"::Order;
        SalesHeader.Insert(true);
        SalesHeader.Validate("Sell-to Customer No.", CustomerNo);
        SalesHeader.Modify(true);
        exit(SalesHeader."No.");
    end;

    /// <summary>
    /// Creates (or recreates) the project hierarchy demo: TOP (customer A) with CHILD 1 (B) and CHILD 2 (sell-to S,
    /// bill-to A), CHILD 2 with GRANDCHILD 1 (A, foreign invoice currency) and GRANDCHILD 2 (B). Each project has one
    /// task with one billable resource line. Open demo invoices are deleted first, which releases their planning lines.
    /// </summary>
    /// <returns>A summary of the demo data.</returns>
    procedure SetupProjectHierarchyDemo(): Text
    var
        TopJob: Record Job;
        Job: Record Job;
        Customer: Record Customer;
        ProjectTestData: Codeunit "BGB Project Test Data";
        CurrencyCode: Code[10];
    begin
        DeleteProjectDemo();
        ProjectTestData.UpsertCustomer(ProjCustomerATok, 'BGB Project Customer A');
        ProjectTestData.UpsertCustomer(ProjCustomerBTok, 'BGB Project Customer B');
        ProjectTestData.UpsertCustomer(ProjSellToTok, 'BGB Project Sell-to S (billed to A)');
        CurrencyCode := ProjectTestData.GetForeignCurrency();

        ProjectTestData.CreateProject(TopJob, ProjTopTok, 'Hierarchy demo: top', '', ProjCustomerATok, '', '');
        Customer.Get(ProjCustomerATok);
        TopJob.Validate("Payment Terms Code", ProjectTestData.GetOtherPaymentTerms(Customer."Payment Terms Code"));
        TopJob.Validate("External Document No.", 'PO-TOP-4711');
        TopJob."Your Reference" := 'Top project ref';
        TopJob.Modify(true);
        ProjectTestData.CreateTaskWithBillableLine(TopJob, '100', 1, 100);
        ProjectTestData.CreateProject(Job, ProjChild1Tok, 'Hierarchy demo: child 1 (B)', ProjTopTok, ProjCustomerBTok, '', '');
        ProjectTestData.CreateTaskWithBillableLine(Job, '100', 2, 100);
        ProjectTestData.CreateProject(Job, ProjChild2Tok, 'Hierarchy demo: child 2 (S, bill A)', ProjTopTok, ProjSellToTok, ProjCustomerATok, '');
        ProjectTestData.CreateTaskWithBillableLine(Job, '100', 3, 100);
        ProjectTestData.CreateProject(Job, ProjGrandChild1Tok, 'Hierarchy demo: grandchild 1 (A, ' + CurrencyCode + ')', ProjChild2Tok, ProjCustomerATok, '', CurrencyCode);
        ProjectTestData.CreateTaskWithBillableLine(Job, '100', 4, 100);
        ProjectTestData.CreateProject(Job, ProjGrandChild2Tok, 'Hierarchy demo: grandchild 2 (B)', ProjChild2Tok, ProjCustomerBTok, '', '');
        ProjectTestData.CreateTaskWithBillableLine(Job, '100', 5, 100);
        exit(StrSubstNo(ProjDoneTok, ProjTopTok, ProjChild1Tok, ProjChild2Tok, ProjGrandChild1Tok, ProjGrandChild2Tok, CurrencyCode));
    end;

    local procedure DeleteProjectDemo()
    var
        SalesHeader: Record "Sales Header";
        Job: Record Job;
        ProjectHierarchyMgt: Codeunit "BGB Project Hierarchy Mgt.";
        ProjectNos: List of [Code[20]];
        i: Integer;
    begin
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Invoice);
        SalesHeader.SetFilter("Bill-to Customer No.", '%1|%2', ProjCustomerATok, ProjCustomerBTok);
        if SalesHeader.FindSet() then
            repeat
                SalesHeader.Delete(true);
            until SalesHeader.Next() = 0;
        if not Job.Get(ProjTopTok) then
            exit;
        ProjectNos := ProjectHierarchyMgt.GetProjectAndDescendants(ProjTopTok);
        for i := ProjectNos.Count() downto 1 do
            if Job.Get(ProjectNos.Get(i)) then
                Job.Delete(true);
    end;

    /// <summary>
    /// Runs report "BGB Project Hierarchy Analysis" (Excel layout) for the demo top project and returns the xlsx as Base64.
    /// </summary>
    /// <returns>The Excel file, Base64 encoded.</returns>
    procedure RunProjectAnalysis(): Text
    var
        Job: Record Job;
        TempBlob: Codeunit "Temp Blob";
        Base64Convert: Codeunit "Base64 Convert";
        RecRef: RecordRef;
        OutStr: OutStream;
        InStr: InStream;
    begin
        Job.SetRange("No.", ProjTopTok);
        RecRef.GetTable(Job);
        TempBlob.CreateOutStream(OutStr);
        Report.SaveAs(Report::"BGB Project Hierarchy Analysis", '', ReportFormat::Excel, OutStr, RecRef);
        TempBlob.CreateInStream(InStr);
        exit(Base64Convert.ToBase64(InStr));
    end;
}
