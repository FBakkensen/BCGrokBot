namespace FlemmingBakkensen.BCGrokBot.ProjectHierarchy;

using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Planning;

codeunit 50105 "BGB Project Hierarchy Subs."
{
    Access = Internal;

    var
        ProjectHierarchyMgt: Codeunit "BGB Project Hierarchy Mgt.";

    [EventSubscriber(ObjectType::Table, Database::Job, OnBeforeDeleteEvent, '', false, false)]
    local procedure JobOnBeforeDelete(var Rec: Record Job; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() then
            exit;
        ProjectHierarchyMgt.CheckCanDelete(Rec."No.");
    end;

    [EventSubscriber(ObjectType::Report, Report::"Job Create Sales Invoice", OnBeforeJobTaskOnAfterGetRecord, '', false, false)]
    local procedure JobCreateSalesInvoiceOnBeforeJobTaskOnAfterGetRecord(JobTask: Record "Job Task"; var IsHandled: Boolean)
    begin
        ProjectHierarchyMgt.CheckStandardInvoicingAllowed(JobTask."Job No.");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Job Create-Invoice", OnCreateSalesInvoiceOnBeforeRunReport, '', false, false)]
    local procedure JobCreateInvoiceOnCreateSalesInvoiceOnBeforeRunReport(var JobPlanningLine: Record "Job Planning Line"; var Done: Boolean; var NewInvoice: Boolean; var PostingDate: Date; var InvoiceNo: Code[20]; var IsHandled: Boolean; CrMemo: Boolean)
    begin
        // Create Sales Invoice from planning lines; credit memos stay standard
        if not CrMemo then
            ProjectHierarchyMgt.CheckStandardInvoicingAllowed(JobPlanningLine."Job No.");
    end;
}
