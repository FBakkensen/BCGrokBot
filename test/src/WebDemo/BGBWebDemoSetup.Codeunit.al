namespace FlemmingBakkensen.BCGrokBot.Test.WebDemo;

using Microsoft.CRM.Team;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using System.Security.User;

/// <summary>
/// Dev/verification only (lives in the test app, never shipped): idempotent demo data for web client verification
/// of the salesperson assignment feature. Exposed as OData web service BGBWebDemo, called by scripts/setup-web-demo.sh.
/// </summary>
codeunit 50153 "BGB Web Demo Setup"
{
    Access = Public;
    Permissions = tabledata Customer = rim,
                  tabledata "Sales Header" = rim,
                  tabledata "Salesperson/Purchaser" = rim,
                  tabledata "User Setup" = rim;

    var
        SalesUserTok: Label 'SALESUSER1', Locked = true;
        OwnSalespersonTok: Label 'BGB-SP1', Locked = true;
        OtherSalespersonTok: Label 'BGB-SP2', Locked = true;
        OwnCustomerTok: Label 'BGB-C-OWN', Locked = true;
        OtherCustomerTok: Label 'BGB-C-OTHER', Locked = true;
        NoSalespersonCustomerTok: Label 'BGB-C-NOSP', Locked = true;
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
}
