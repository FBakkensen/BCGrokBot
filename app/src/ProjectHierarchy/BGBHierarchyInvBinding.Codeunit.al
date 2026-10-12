namespace FlemmingBakkensen.BCGrokBot.ProjectHierarchy;

using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Planning;
using Microsoft.Sales.Document;

/// <summary>
/// Manually bound subscribers, active only while "BGB Hierarchy Invoicing" runs (bound with BindSubscription,
/// released automatically if the run fails). Captures the created invoice number and replaces the standard
/// header check so that projects with a different sell-to customer can share one invoice.
/// </summary>
codeunit 50107 "BGB Hierarchy Inv. Binding"
{
    Access = Internal;
    EventSubscriberInstance = Manual;
    Permissions = tabledata Job = r,
                  tabledata "Job Task" = r;

    var
        LastSalesInvoiceNo: Code[20];

    /// <summary>
    /// Returns the number of the last sales document created or extended by "Job Create-Invoice" while bound.
    /// </summary>
    /// <returns>The sales invoice number.</returns>
    procedure GetLastSalesInvoiceNo(): Code[20]
    begin
        exit(LastSalesInvoiceNo);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Job Create-Invoice", OnAfterCreateSalesInvoiceLines, '', false, false)]
    local procedure JobCreateInvoiceOnAfterCreateSalesInvoiceLines(var SalesHeader: Record "Sales Header"; NewInvoice: Boolean)
    begin
        LastSalesInvoiceNo := SalesHeader."No.";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Job Create-Invoice", OnBeforeTestSalesHeader, '', false, false)]
    local procedure JobCreateInvoiceOnBeforeTestSalesHeader(var SalesHeader: Record "Sales Header"; Job: Record Job; var IsHandled: Boolean; var JobPlanningLine: Record "Job Planning Line")
    var
        LineJob: Record Job;
        JobTask: Record "Job Task";
        HierarchyInvoicing: Codeunit "BGB Hierarchy Invoicing";
        BillToCustomerNo: Code[20];
        CurrencyCode: Code[10];
    begin
        // Standard TestSalesHeader requires the same bill-to AND sell-to customer and currency.
        // A hierarchy invoice groups by bill-to customer and currency only, so sell-to may differ.
        if not LineJob.Get(JobPlanningLine."Job No.") then
            exit;
        if not JobTask.Get(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.") then
            exit;
        HierarchyInvoicing.GetBillingKey(LineJob, JobTask, BillToCustomerNo, CurrencyCode);
        SalesHeader.TestField("Bill-to Customer No.", BillToCustomerNo);
        SalesHeader.TestField("Currency Code", CurrencyCode);
        IsHandled := true;
    end;
}
