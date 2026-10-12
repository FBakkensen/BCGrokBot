namespace FlemmingBakkensen.BCGrokBot.Test.ProjectHierarchy;

using FlemmingBakkensen.BCGrokBot.ProjectHierarchy;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Planning;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using System.TestLibraries.Utilities;

/// <summary>
/// Container-only: hierarchy invoicing, standard invoicing block, delete guard and hierarchy totals on CRONUS data.
/// </summary>
codeunit 50158 "BGB Hierarchy Invoicing Tests"
{
    Subtype = Test;
    Access = Internal;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        ProjectTestData: Codeunit "BGB Project Test Data";
        HierarchyInvoicing: Codeunit "BGB Hierarchy Invoicing";
        ProjectHierarchyMgt: Codeunit "BGB Project Hierarchy Mgt.";
        TopNo, Child1No, Child2No, GrandChild1No, GrandChild2No : Code[20];
        CustomerANo, CustomerBNo, SellToSNo : Code[20];
        ForeignCurrencyCode: Code[10];
        NotTopLevelErrTok: Label 'Hierarchy invoicing can only be run on a top-level project', Locked = true;
        InHierarchyErrTok: Label 'is part of a project hierarchy', Locked = true;
        HasSubprojectsErrTok: Label 'because it has subprojects', Locked = true;

    [Test]
    procedure OneInvoicePerBillToAndCurrency()
    var
        InvoiceNos: List of [Code[20]];
        InvoiceNo: Code[20];
        LCYInvoiceA, LCYInvoiceB, FCYInvoiceA : Code[20];
    begin
        // [SCENARIO] One invoice per bill-to customer and currency across the whole hierarchy
        // [GIVEN] TOP(A) <- CHILD1(B), CHILD2(sell-to S, bill-to A) <- GRANDCHILD1(A, foreign currency), GRANDCHILD2(B)
        CreateTree();
        // [WHEN] hierarchy invoicing runs on TOP
        InvoiceNos := HierarchyInvoicing.CreateInvoices(TopNo, WorkDate(), WorkDate(), '');
        // [THEN] three invoices: A/LCY (TOP + CHILD2), B/LCY (CHILD1 + GRANDCHILD2), A/foreign (GRANDCHILD1)
        Assert.AreEqual(3, InvoiceNos.Count(), 'number of invoices');
        foreach InvoiceNo in InvoiceNos do
            case true of
                IsInvoiceFor(InvoiceNo, CustomerANo, ''):
                    LCYInvoiceA := InvoiceNo;
                IsInvoiceFor(InvoiceNo, CustomerBNo, ''):
                    LCYInvoiceB := InvoiceNo;
                IsInvoiceFor(InvoiceNo, CustomerANo, ForeignCurrencyCode):
                    FCYInvoiceA := InvoiceNo;
            end;
        Assert.AreNotEqual('', LCYInvoiceA, 'A/LCY invoice');
        Assert.AreNotEqual('', LCYInvoiceB, 'B/LCY invoice');
        Assert.AreNotEqual('', FCYInvoiceA, 'A/foreign invoice');
        VerifyInvoiceLines(LCYInvoiceA, TopNo, Child2No);
        VerifyInvoiceLines(LCYInvoiceB, Child1No, GrandChild2No);
        VerifyInvoiceLines(FCYInvoiceA, GrandChild1No, '');
        // [THEN] every planning line is fully transferred and linked
        VerifyAllTransferred();
    end;

    [Test]
    procedure HeaderSellToAndTermsFromTopProject()
    var
        TopJob: Record Job;
        Child1Job: Record Job;
        SalesHeader: Record "Sales Header";
        InvoiceNos: List of [Code[20]];
        InvoiceNo: Code[20];
    begin
        // [SCENARIO] Sell-to comes from TOP when TOP is in the group, else from the highest project of the group;
        // payment terms and references always come from TOP
        CreateTree();
        TopJob.Get(TopNo);
        Child1Job.Get(Child1No);
        // [WHEN] hierarchy invoicing runs
        InvoiceNos := HierarchyInvoicing.CreateInvoices(TopNo, WorkDate(), WorkDate(), '');
        // [THEN]
        foreach InvoiceNo in InvoiceNos do begin
            SalesHeader.Get(SalesHeader."Document Type"::Invoice, InvoiceNo);
            Assert.AreEqual(TopJob."Payment Terms Code", SalesHeader."Payment Terms Code", 'payment terms from TOP');
            Assert.AreEqual(TopJob."External Document No.", SalesHeader."External Document No.", 'external document no. from TOP');
            Assert.AreEqual(TopJob."Your Reference", SalesHeader."Your Reference", 'your reference from TOP');
            if SalesHeader."Bill-to Customer No." = CustomerBNo then
                Assert.AreEqual(Child1Job."Sell-to Customer No.", SalesHeader."Sell-to Customer No.", 'sell-to from CHILD1 (highest project billing B)')
            else
                Assert.AreEqual(TopJob."Sell-to Customer No.", SalesHeader."Sell-to Customer No.", 'sell-to from TOP');
        end;
    end;

    [Test]
    procedure SubprojectCannotRunHierarchyInvoicing()
    begin
        // [SCENARIO] Hierarchy invoicing is only possible on a top-level project
        CreateTree();
        asserterror HierarchyInvoicing.CreateInvoices(Child2No, WorkDate(), WorkDate(), '');
        Assert.ExpectedError(NotTopLevelErrTok);
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    [HandlerFunctions('StandardCreateInvoiceRequestPageHandler')]
    procedure StandardReportBlockedInHierarchy()
    var
        JobTask: Record "Job Task";
    begin
        // [SCENARIO] Standard Project Create Sales Invoice (report 1093) is blocked for hierarchy projects
        CreateTree();
        JobTask.SetRange("Job No.", GrandChild2No);
        Commit(); // a report cannot be run modally inside an open write transaction; test isolation rolls it back
        asserterror Report.RunModal(Report::"Job Create Sales Invoice", true, false, JobTask);
        Assert.ExpectedError(InHierarchyErrTok);
        Assert.ExpectedError(TopNo);
    end;

    [Test]
    procedure StandardCreateInvoiceFromPlanningLinesBlocked()
    var
        JobPlanningLine: Record "Job Planning Line";
        JobCreateInvoice: Codeunit "Job Create-Invoice";
    begin
        // [SCENARIO] Create Sales Invoice from planning lines is blocked for hierarchy projects
        CreateTree();
        JobPlanningLine.SetRange("Job No.", TopNo);
        JobPlanningLine.FindFirst();
        asserterror JobCreateInvoice.CreateSalesInvoice(JobPlanningLine, false);
        Assert.ExpectedError(InHierarchyErrTok);
    end;

    [Test]
    procedure ParentCannotBeDeleted()
    var
        Job: Record Job;
    begin
        // [SCENARIO] A project with subprojects cannot be deleted
        CreateTree();
        Job.Get(Child2No);
        asserterror Job.Delete(true);
        Assert.ExpectedError(HasSubprojectsErrTok);
    end;

    [Test]
    procedure HierarchyTotalsSumAllDescendants()
    var
        Job: Record Job;
        CostAmounts: array[16] of Decimal;
        PriceAmounts: array[16] of Decimal;
    begin
        // [SCENARIO] Hierarchy totals equal the sum of the standard statistics of all projects in the tree
        CreateTree();
        Job.Get(TopNo);
        ProjectHierarchyMgt.CalcHierarchyAmounts(Job, CostAmounts, PriceAmounts);
        // Billable price total (LCY): 100 + 200 + 300 + 400 + 500 (grandchild 1 is LCY-priced, invoiced in foreign currency)
        Assert.AreEqual(1500, PriceAmounts[12], 'billable price total');
        Job.Get(Child2No);
        ProjectHierarchyMgt.CalcHierarchyAmounts(Job, CostAmounts, PriceAmounts);
        Assert.AreEqual(300 + 400 + 500, PriceAmounts[12], 'subtree of CHILD2');
    end;

    [Test]
    procedure ParentProjectEditableOnCardAndList()
    var
        Job: Record Job;
        JobCard: TestPage "Job Card";
    begin
        // [SCENARIO] Parent Project No. can be edited on the Project Card
        // [GIVEN] the demo tree
        CreateTree();
        // [WHEN] the card of a subproject is opened in edit mode
        Job.Get(GrandChild2No);
        JobCard.OpenEdit();
        JobCard.GoToRecord(Job);
        // [THEN] the field is editable and can be changed to another project
        Assert.IsTrue(JobCard."BGB Parent Project No.".Editable(), 'Parent Project No. editable on card');
        JobCard."BGB Parent Project No.".SetValue(Child1No);
        JobCard.Close();
        Job.Get(GrandChild2No);
        Assert.AreEqual(Child1No, Job."BGB Parent Project No.", 'parent changed from the card');
    end;

    [RequestPageHandler]
    procedure StandardCreateInvoiceRequestPageHandler(var JobCreateSalesInvoice: TestRequestPage "Job Create Sales Invoice")
    begin
        JobCreateSalesInvoice.PostingDate.SetValue(WorkDate());
        JobCreateSalesInvoice.OK().Invoke();
    end;

    local procedure CreateTree()
    var
        TopJob: Record Job;
        Job: Record Job;
        Customer: Record Customer;
        Prefix: Text;
    begin
        Prefix := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 12);
        CustomerANo := ProjectTestData.UpsertCustomer(CopyStr(Prefix + '-A', 1, 20), 'Hierarchy test customer A');
        CustomerBNo := ProjectTestData.UpsertCustomer(CopyStr(Prefix + '-B', 1, 20), 'Hierarchy test customer B');
        SellToSNo := ProjectTestData.UpsertCustomer(CopyStr(Prefix + '-S', 1, 20), 'Hierarchy test sell-to S');
        ForeignCurrencyCode := ProjectTestData.GetForeignCurrency();
        TopNo := CopyStr(Prefix + '-T', 1, 20);
        Child1No := CopyStr(Prefix + '-C1', 1, 20);
        Child2No := CopyStr(Prefix + '-C2', 1, 20);
        GrandChild1No := CopyStr(Prefix + '-G1', 1, 20);
        GrandChild2No := CopyStr(Prefix + '-G2', 1, 20);

        ProjectTestData.CreateProject(TopJob, TopNo, 'Top', '', CustomerANo, '', '');
        Customer.Get(CustomerANo);
        TopJob.Validate("Payment Terms Code", ProjectTestData.GetOtherPaymentTerms(Customer."Payment Terms Code"));
        TopJob.Validate("External Document No.", CopyStr(Prefix, 1, 20));
        TopJob."Your Reference" := 'TOP-REF';
        TopJob.Modify(true);
        ProjectTestData.CreateTaskWithBillableLine(TopJob, '100', 1, 100);
        ProjectTestData.CreateProject(Job, Child1No, 'Child 1', TopNo, CustomerBNo, '', '');
        ProjectTestData.CreateTaskWithBillableLine(Job, '100', 2, 100);
        ProjectTestData.CreateProject(Job, Child2No, 'Child 2', TopNo, SellToSNo, CustomerANo, '');
        ProjectTestData.CreateTaskWithBillableLine(Job, '100', 3, 100);
        ProjectTestData.CreateProject(Job, GrandChild1No, 'Grandchild 1', Child2No, CustomerANo, '', ForeignCurrencyCode);
        ProjectTestData.CreateTaskWithBillableLine(Job, '100', 4, 100);
        ProjectTestData.CreateProject(Job, GrandChild2No, 'Grandchild 2', Child2No, CustomerBNo, '', '');
        ProjectTestData.CreateTaskWithBillableLine(Job, '100', 5, 100);
    end;

    local procedure IsInvoiceFor(InvoiceNo: Code[20]; BillToCustomerNo: Code[20]; CurrencyCode: Code[10]): Boolean
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.Get(SalesHeader."Document Type"::Invoice, InvoiceNo);
        exit((SalesHeader."Bill-to Customer No." = BillToCustomerNo) and (SalesHeader."Currency Code" = CurrencyCode));
    end;

    local procedure VerifyInvoiceLines(InvoiceNo: Code[20]; FirstProjectNo: Code[20]; SecondProjectNo: Code[20])
    var
        SalesLine: Record "Sales Line";
        ExpectedLines: Integer;
    begin
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Invoice);
        SalesLine.SetRange("Document No.", InvoiceNo);
        SalesLine.SetRange(Type, SalesLine.Type::Resource);
        ExpectedLines := 1;
        if SecondProjectNo <> '' then
            ExpectedLines := 2;
        Assert.RecordCount(SalesLine, ExpectedLines);
        SalesLine.SetRange("Job No.", FirstProjectNo);
        Assert.RecordCount(SalesLine, 1);
        if SecondProjectNo <> '' then begin
            SalesLine.SetRange("Job No.", SecondProjectNo);
            Assert.RecordCount(SalesLine, 1);
        end;
    end;

    local procedure VerifyAllTransferred()
    var
        JobPlanningLine: Record "Job Planning Line";
        JobPlanningLineInvoice: Record "Job Planning Line Invoice";
        ProjectNo: Code[20];
    begin
        foreach ProjectNo in ProjectHierarchyMgt.GetProjectAndDescendants(TopNo) do begin
            JobPlanningLine.SetRange("Job No.", ProjectNo);
            JobPlanningLine.FindFirst();
            Assert.AreEqual(0, JobPlanningLine."Qty. to Transfer to Invoice", 'qty. to transfer ' + ProjectNo);
            JobPlanningLineInvoice.SetRange("Job No.", ProjectNo);
            JobPlanningLineInvoice.SetRange("Document Type", JobPlanningLineInvoice."Document Type"::Invoice);
            Assert.RecordCount(JobPlanningLineInvoice, 1);
        end;
    end;
}
