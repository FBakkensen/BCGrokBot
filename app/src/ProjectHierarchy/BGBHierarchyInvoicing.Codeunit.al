namespace FlemmingBakkensen.BCGrokBot.ProjectHierarchy;

using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Planning;
using Microsoft.Sales.Document;

/// <summary>
/// Creates sales invoices for a whole project hierarchy: one invoice per bill-to customer and currency
/// across the top-level project and all its descendants. Lines are created by the standard
/// "Job Create-Invoice" codeunit, so planning line links, dimensions and currency handling stay standard.
/// Header terms (payment terms and method, Your Reference, External Document No.) come from the top-level project.
/// </summary>
codeunit 50106 "BGB Hierarchy Invoicing"
{
    Access = Public;
    Permissions = tabledata Job = r,
                  tabledata "Job Task" = r,
                  tabledata "Job Planning Line" = r,
                  tabledata "Sales Header" = rm;

    var
        PostingDateErr: Label 'You must specify a posting date.';
        NothingToInvoiceErr: Label 'There is nothing to invoice in project hierarchy %1.', Comment = '%1 = top-level project number';
        GroupKeyTok: Label '%1|%2', Locked = true;

    /// <summary>
    /// Creates one sales invoice per bill-to customer and currency for all invoiceable planning lines in the hierarchy below (and including) the top-level project.
    /// </summary>
    /// <param name="TopProjectNo">The top-level project. Must not have a parent project.</param>
    /// <param name="PostingDate">The posting date of the invoices.</param>
    /// <param name="DocumentDate">The document date of the invoices.</param>
    /// <param name="PlanningDateFilter">Optional filter on the planning date of the planning lines.</param>
    /// <returns>The numbers of the created sales invoices.</returns>
    procedure CreateInvoices(TopProjectNo: Code[20]; PostingDate: Date; DocumentDate: Date; PlanningDateFilter: Text): List of [Code[20]]
    var
        TopJob: Record Job;
        TempInvoiceUnit: Record "Job Task" temporary;
        ProjectHierarchyMgt: Codeunit "BGB Project Hierarchy Mgt.";
        HierarchyInvBinding: Codeunit "BGB Hierarchy Inv. Binding";
        InvoiceNos: List of [Code[20]];
        ProjectNos: List of [Code[20]];
        GroupKeys: List of [Text];
        GroupKey: Text;
    begin
        if PostingDate = 0D then
            Error(PostingDateErr);
        if DocumentDate = 0D then
            DocumentDate := PostingDate;
        if not TopJob.Get(TopProjectNo) then
            Error(NothingToInvoiceErr, TopProjectNo);
        ProjectHierarchyMgt.CheckTopLevel(TopJob);

        ProjectNos := ProjectHierarchyMgt.GetProjectAndDescendants(TopJob."No.");
        CollectInvoiceUnits(ProjectNos, PlanningDateFilter, TempInvoiceUnit, GroupKeys);
        if GroupKeys.Count() = 0 then
            Error(NothingToInvoiceErr, TopJob."No.");

        BindSubscription(HierarchyInvBinding);
        foreach GroupKey in GroupKeys do
            InvoiceNos.Add(CreateGroupInvoice(TopJob, ProjectNos, GroupKey, TempInvoiceUnit, PostingDate, DocumentDate, PlanningDateFilter, HierarchyInvBinding));
        UnbindSubscription(HierarchyInvBinding);
        exit(InvoiceNos);
    end;

    /// <summary>
    /// Returns the bill-to customer and effective invoice currency of a project task, following the project's Task Billing Method
    /// in the same way as the standard "Job Create-Invoice" codeunit.
    /// </summary>
    /// <param name="Job">The project.</param>
    /// <param name="JobTask">The project task.</param>
    /// <param name="BillToCustomerNo">Returns the bill-to customer number.</param>
    /// <param name="CurrencyCode">Returns the invoice currency code (blank = LCY).</param>
    procedure GetBillingKey(Job: Record Job; JobTask: Record "Job Task"; var BillToCustomerNo: Code[20]; var CurrencyCode: Code[10])
    begin
        if Job."Task Billing Method" = Job."Task Billing Method"::"One customer" then begin
            BillToCustomerNo := Job."Bill-to Customer No.";
            CurrencyCode := Job."Invoice Currency Code";
        end else begin
            BillToCustomerNo := JobTask."Bill-to Customer No.";
            CurrencyCode := JobTask."Invoice Currency Code";
        end;
        if Job."Currency Code" <> '' then
            CurrencyCode := Job."Currency Code";
    end;

    local procedure CollectInvoiceUnits(ProjectNos: List of [Code[20]]; PlanningDateFilter: Text; var TempInvoiceUnit: Record "Job Task" temporary; var GroupKeys: List of [Text])
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        ProjectNo: Code[20];
    begin
        foreach ProjectNo in ProjectNos do begin
            Job.Get(ProjectNo);
            JobTask.SetRange("Job No.", ProjectNo);
            JobTask.SetRange("Job Task Type", JobTask."Job Task Type"::Posting);
            if JobTask.FindSet() then
                repeat
                    if HasInvoiceableLines(JobTask, PlanningDateFilter) then
                        AddInvoiceUnit(Job, JobTask, TempInvoiceUnit, GroupKeys);
                until JobTask.Next() = 0;
        end;
    end;

    local procedure AddInvoiceUnit(Job: Record Job; JobTask: Record "Job Task"; var TempInvoiceUnit: Record "Job Task" temporary; var GroupKeys: List of [Text])
    var
        BillToCustomerNo: Code[20];
        CurrencyCode: Code[10];
        GroupKey: Text;
    begin
        GetBillingKey(Job, JobTask, BillToCustomerNo, CurrencyCode);
        TempInvoiceUnit := JobTask;
        TempInvoiceUnit."Bill-to Customer No." := BillToCustomerNo;
        TempInvoiceUnit."Invoice Currency Code" := CurrencyCode;
        TempInvoiceUnit.Insert(false);
        GroupKey := StrSubstNo(GroupKeyTok, BillToCustomerNo, CurrencyCode);
        if not GroupKeys.Contains(GroupKey) then
            GroupKeys.Add(GroupKey);
    end;

    local procedure HasInvoiceableLines(JobTask: Record "Job Task"; PlanningDateFilter: Text): Boolean
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        SetPlanningLineFilters(JobPlanningLine, JobTask."Job No.", JobTask."Job Task No.", PlanningDateFilter);
        JobPlanningLine.SetRange("Contract Line", true);
        JobPlanningLine.SetFilter("Qty. to Transfer to Invoice", '<>0');
        exit(not JobPlanningLine.IsEmpty());
    end;

    local procedure SetPlanningLineFilters(var JobPlanningLine: Record "Job Planning Line"; JobNo: Code[20]; JobTaskNo: Code[20]; PlanningDateFilter: Text)
    begin
        JobPlanningLine.SetCurrentKey("Job No.", "Job Task No.", "Line No.");
        JobPlanningLine.SetRange("Job No.", JobNo);
        JobPlanningLine.SetRange("Job Task No.", JobTaskNo);
        if PlanningDateFilter <> '' then
            JobPlanningLine.SetFilter("Planning Date", PlanningDateFilter);
    end;

    local procedure CreateGroupInvoice(TopJob: Record Job; ProjectNos: List of [Code[20]]; GroupKey: Text; var TempInvoiceUnit: Record "Job Task" temporary; PostingDate: Date; DocumentDate: Date; PlanningDateFilter: Text; var HierarchyInvBinding: Codeunit "BGB Hierarchy Inv. Binding"): Code[20]
    var
        InvoiceNo: Code[20];
        ProjectNo: Code[20];
    begin
        // Breadth-first order: the first unit belongs to the top-level project if it bills this customer,
        // otherwise to the highest project in the hierarchy that does. Its project fills the new header.
        foreach ProjectNo in ProjectNos do begin
            TempInvoiceUnit.Reset();
            TempInvoiceUnit.SetRange("Job No.", ProjectNo);
            if TempInvoiceUnit.FindSet() then
                repeat
                    if StrSubstNo(GroupKeyTok, TempInvoiceUnit."Bill-to Customer No.", TempInvoiceUnit."Invoice Currency Code") = GroupKey then
                        InvoiceNo := TransferUnit(TopJob, TempInvoiceUnit, InvoiceNo, PostingDate, DocumentDate, PlanningDateFilter, HierarchyInvBinding);
                until TempInvoiceUnit.Next() = 0;
        end;
        exit(InvoiceNo);
    end;

    local procedure TransferUnit(TopJob: Record Job; InvoiceUnit: Record "Job Task"; InvoiceNo: Code[20]; PostingDate: Date; DocumentDate: Date; PlanningDateFilter: Text; var HierarchyInvBinding: Codeunit "BGB Hierarchy Inv. Binding"): Code[20]
    var
        JobPlanningLine: Record "Job Planning Line";
        JobCreateInvoice: Codeunit "Job Create-Invoice";
        NewInvoice: Boolean;
    begin
        NewInvoice := InvoiceNo = '';
        SetPlanningLineFilters(JobPlanningLine, InvoiceUnit."Job No.", InvoiceUnit."Job Task No.", PlanningDateFilter);
        if not JobPlanningLine.FindFirst() then
            exit(InvoiceNo);
        JobCreateInvoice.CreateSalesInvoiceLines(InvoiceUnit."Job No.", JobPlanningLine, InvoiceNo, NewInvoice, PostingDate, DocumentDate, false);
        if not NewInvoice then
            exit(InvoiceNo);
        InvoiceNo := HierarchyInvBinding.GetLastSalesInvoiceNo();
        ApplyTopProjectTerms(InvoiceNo, TopJob);
        exit(InvoiceNo);
    end;

    local procedure ApplyTopProjectTerms(InvoiceNo: Code[20]; TopJob: Record Job)
    var
        SalesHeader: Record "Sales Header";
    begin
        if not SalesHeader.Get(SalesHeader."Document Type"::Invoice, InvoiceNo) then
            exit;
        SalesHeader.SetHideValidationDialog(true);
        if TopJob."Payment Terms Code" <> '' then
            SalesHeader.Validate("Payment Terms Code", TopJob."Payment Terms Code");
        if TopJob."Payment Method Code" <> '' then
            SalesHeader.Validate("Payment Method Code", TopJob."Payment Method Code");
        SalesHeader.Validate("External Document No.", TopJob."External Document No.");
        SalesHeader."Your Reference" := TopJob."Your Reference";
        SalesHeader.Modify(true);
    end;
}
