namespace FlemmingBakkensen.BCGrokBot.Test.ProjectHierarchy;

using Microsoft.Finance.Currency;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Planning;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Sales.Customer;

/// <summary>
/// Test/demo data for project hierarchies on top of CRONUS (container only): customers, projects,
/// posting tasks and billable resource planning lines. Used by the integration tests and the web demo.
/// </summary>
codeunit 50159 "BGB Project Test Data"
{
    Access = Public;
    Permissions = tabledata "Currency Exchange Rate" = r,
                  tabledata Customer = rim,
                  tabledata Job = im,
                  tabledata "Job Planning Line" = im,
                  tabledata "Job Posting Group" = r,
                  tabledata "Job Task" = im,
                  tabledata "Payment Terms" = r,
                  tabledata Resource = r;

    var
        NoTemplateCustomerErr: Label 'No CRONUS customer with posting groups found.';
        NoResourceErr: Label 'No resource with a general product posting group found.';
        NoJobPostingGroupErr: Label 'No project posting group found.';
        NoCurrencyErr: Label 'No currency with an exchange rate found.';

    /// <summary>
    /// Creates or updates a customer with posting groups copied from an existing CRONUS customer.
    /// </summary>
    /// <param name="CustomerNo">The customer number.</param>
    /// <param name="CustomerName">The customer name.</param>
    /// <returns>The customer number.</returns>
    procedure UpsertCustomer(CustomerNo: Code[20]; CustomerName: Text[100]): Code[20]
    var
        SourceCustomer: Record Customer;
        Customer: Record Customer;
    begin
        SourceCustomer.SetFilter("Customer Posting Group", '<>%1', '');
        SourceCustomer.SetFilter("Gen. Bus. Posting Group", '<>%1', '');
        SourceCustomer.SetFilter("No.", '<>BGB-*');
        SourceCustomer.SetRange("Currency Code", '');
        if not SourceCustomer.FindFirst() then
            Error(NoTemplateCustomerErr);
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
        Customer."Salesperson Code" := '';
        Customer.Modify(false);
        exit(CustomerNo);
    end;

    /// <summary>
    /// Creates a project (deleting an existing one with the same number and no subprojects first is the caller's job).
    /// </summary>
    /// <param name="Job">Returns the project.</param>
    /// <param name="ProjectNo">The project number.</param>
    /// <param name="ProjectDescription">The description.</param>
    /// <param name="ParentProjectNo">The parent project, or blank.</param>
    /// <param name="SellToCustomerNo">The sell-to customer.</param>
    /// <param name="BillToCustomerNo">The bill-to customer (blank = same as sell-to).</param>
    /// <param name="InvoiceCurrencyCode">The invoice currency (blank = LCY).</param>
    procedure CreateProject(var Job: Record Job; ProjectNo: Code[20]; ProjectDescription: Text[100]; ParentProjectNo: Code[20]; SellToCustomerNo: Code[20]; BillToCustomerNo: Code[20]; InvoiceCurrencyCode: Code[10])
    begin
        Job.Init();
        Job."No." := ProjectNo;
        Job.Insert(true);
        Job.SetHideValidationDialog(true);
        Job.Validate(Description, ProjectDescription);
        Job.Validate("Sell-to Customer No.", SellToCustomerNo);
        if (BillToCustomerNo <> '') and (BillToCustomerNo <> SellToCustomerNo) then
            Job.Validate("Bill-to Customer No.", BillToCustomerNo);
        Job.Validate("Job Posting Group", GetJobPostingGroup());
        if InvoiceCurrencyCode <> '' then
            Job.Validate("Invoice Currency Code", InvoiceCurrencyCode);
        Job.Validate("BGB Parent Project No.", ParentProjectNo);
        Job.Modify(true);
    end;

    /// <summary>
    /// Creates a posting task with one budget-and-billable resource planning line on the work date.
    /// </summary>
    /// <param name="Job">The project.</param>
    /// <param name="JobTaskNo">The task number.</param>
    /// <param name="Quantity">The quantity.</param>
    /// <param name="UnitPrice">The unit price.</param>
    procedure CreateTaskWithBillableLine(Job: Record Job; JobTaskNo: Code[20]; Quantity: Decimal; UnitPrice: Decimal)
    var
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
    begin
        JobTask.Init();
        JobTask.Validate("Job No.", Job."No.");
        JobTask.Validate("Job Task No.", JobTaskNo);
        JobTask.Insert(true);
        JobTask.Validate("Job Task Type", JobTask."Job Task Type"::Posting);
        JobTask.Validate(Description, Job.Description);
        JobTask.Modify(true);

        JobPlanningLine.Init();
        JobPlanningLine.Validate("Job No.", JobTask."Job No.");
        JobPlanningLine.Validate("Job Task No.", JobTask."Job Task No.");
        JobPlanningLine.Validate("Line No.", 10000);
        JobPlanningLine.Insert(true);
        JobPlanningLine.Validate("Planning Date", WorkDate());
        JobPlanningLine.Validate("Line Type", JobPlanningLine."Line Type"::"Both Budget and Billable");
        JobPlanningLine.Validate(Type, JobPlanningLine.Type::Resource);
        JobPlanningLine.Validate("No.", GetResourceNo());
        JobPlanningLine.Validate(Quantity, Quantity);
        JobPlanningLine.Validate("Unit Price", UnitPrice);
        JobPlanningLine.Modify(true);
    end;

    /// <summary>
    /// Returns a payment terms code different from the given one.
    /// </summary>
    /// <param name="ExcludedCode">The code to avoid.</param>
    /// <returns>A payment terms code.</returns>
    procedure GetOtherPaymentTerms(ExcludedCode: Code[10]): Code[10]
    var
        PaymentTerms: Record "Payment Terms";
    begin
        PaymentTerms.SetFilter(Code, '<>%1', ExcludedCode);
        PaymentTerms.FindFirst();
        exit(PaymentTerms.Code);
    end;

    /// <summary>
    /// Returns a foreign currency that has an exchange rate.
    /// </summary>
    /// <returns>The currency code.</returns>
    procedure GetForeignCurrency(): Code[10]
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        CurrencyExchangeRate.SetFilter("Starting Date", '..%1', WorkDate());
        CurrencyExchangeRate.SetFilter("Currency Code", 'EUR');
        if CurrencyExchangeRate.FindLast() then
            exit(CurrencyExchangeRate."Currency Code");
        CurrencyExchangeRate.SetRange("Currency Code");
        if not CurrencyExchangeRate.FindFirst() then
            Error(NoCurrencyErr);
        exit(CurrencyExchangeRate."Currency Code");
    end;

    local procedure GetResourceNo(): Code[20]
    var
        Resource: Record Resource;
    begin
        Resource.SetFilter("Gen. Prod. Posting Group", '<>%1', '');
        Resource.SetRange(Blocked, false);
        Resource.SetRange(Type, Resource.Type::Person);
        if not Resource.FindFirst() then
            Error(NoResourceErr);
        exit(Resource."No.");
    end;

    local procedure GetJobPostingGroup(): Code[20]
    var
        JobPostingGroup: Record "Job Posting Group";
    begin
        if not JobPostingGroup.FindFirst() then
            Error(NoJobPostingGroupErr);
        exit(JobPostingGroup.Code);
    end;
}
