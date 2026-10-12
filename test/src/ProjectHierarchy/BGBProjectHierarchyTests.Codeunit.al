namespace FlemmingBakkensen.BCGrokBot.Test.ProjectHierarchy;

using FlemmingBakkensen.BCGrokBot.ProjectHierarchy;
using Microsoft.Projects.Project.Job;
using System.TestLibraries.Utilities;

codeunit 50157 "BGB Project Hierarchy Tests"
{
    Subtype = Test;
    Access = Internal;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        ProjectHierarchyMgt: Codeunit "BGB Project Hierarchy Mgt.";
        HierarchyInvoicing: Codeunit "BGB Hierarchy Invoicing";
        SelfParentErrTok: Label 'cannot be its own parent project', Locked = true;
        CycleErrTok: Label 'is already a subproject of', Locked = true;
        NotTopLevelErrTok: Label 'Hierarchy invoicing can only be run on a top-level project', Locked = true;
        InHierarchyErrTok: Label 'is part of a project hierarchy', Locked = true;
        HasSubprojectsErrTok: Label 'because it has subprojects', Locked = true;

    [Test]
    procedure ProjectCannotBeItsOwnParent()
    var
        Job: Record Job;
    begin
        // [SCENARIO] A project cannot be its own parent
        // [GIVEN] a project
        CreateProject(Job, '');
        // [WHEN] its parent is set to itself
        asserterror Job.Validate("BGB Parent Project No.", Job."No.");
        // [THEN] the self-parent error is raised
        Assert.ExpectedError(SelfParentErrTok);
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    procedure CycleIsRejectedAtAnyDepth()
    var
        Top: Record Job;
        Child: Record Job;
        GrandChild: Record Job;
    begin
        // [SCENARIO] A project cannot get one of its descendants as parent
        // [GIVEN] TOP <- CHILD <- GRANDCHILD
        CreateProject(Top, '');
        CreateProject(Child, Top."No.");
        CreateProject(GrandChild, Child."No.");
        // [WHEN] TOP gets GRANDCHILD as parent
        asserterror Top.Validate("BGB Parent Project No.", GrandChild."No.");
        // [THEN] the cycle error is raised
        Assert.ExpectedError(CycleErrTok);
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    procedure ValidParentIsAccepted()
    var
        Top: Record Job;
        Other: Record Job;
        Child: Record Job;
    begin
        // [SCENARIO] Moving a subproject under another hierarchy is allowed
        // [GIVEN] TOP <- CHILD and a separate project OTHER
        CreateProject(Top, '');
        CreateProject(Child, Top."No.");
        CreateProject(Other, '');
        // [WHEN] OTHER becomes a subproject of CHILD
        Other.Validate("BGB Parent Project No.", Child."No.");
        Other.Modify(false);
        // [THEN] OTHER's top-level project is TOP
        Assert.AreEqual(Top."No.", ProjectHierarchyMgt.GetTopLevelProjectNo(Other."No."), 'top-level project');
    end;

    [Test]
    procedure DescendantsAreBreadthFirst()
    var
        Top: Record Job;
        ChildA: Record Job;
        ChildB: Record Job;
        GrandChild: Record Job;
        ProjectNos: List of [Code[20]];
    begin
        // [SCENARIO] Descendants come breadth first, project itself first
        // [GIVEN] TOP <- CHILD A <- GRANDCHILD, TOP <- CHILD B
        CreateProject(Top, '');
        CreateProject(ChildA, Top."No.");
        CreateProject(GrandChild, ChildA."No.");
        CreateProject(ChildB, Top."No.");
        // [WHEN] the descendants of TOP are read
        ProjectNos := ProjectHierarchyMgt.GetProjectAndDescendants(Top."No.");
        // [THEN] TOP, then both children, then the grandchild
        Assert.AreEqual(4, ProjectNos.Count(), 'count');
        Assert.AreEqual(Top."No.", ProjectNos.Get(1), 'self first');
        Assert.IsTrue(ProjectNos.IndexOf(ChildA."No.") in [2, 3], 'child A on level 1');
        Assert.IsTrue(ProjectNos.IndexOf(ChildB."No.") in [2, 3], 'child B on level 1');
        Assert.AreEqual(GrandChild."No.", ProjectNos.Get(4), 'grandchild last');
        Assert.AreEqual(3, ProjectHierarchyMgt.CountDescendants(Top."No."), 'descendant count');
        Assert.AreEqual(0, ProjectHierarchyMgt.CountDescendants(GrandChild."No."), 'leaf');
    end;

    [Test]
    procedure HierarchyMembership()
    var
        Top: Record Job;
        Child: Record Job;
        Single: Record Job;
    begin
        // [SCENARIO] Parent or children make a project part of a hierarchy
        CreateProject(Top, '');
        CreateProject(Child, Top."No.");
        CreateProject(Single, '');
        Assert.IsTrue(ProjectHierarchyMgt.IsInHierarchy(Top."No."), 'top has children');
        Assert.IsTrue(ProjectHierarchyMgt.IsInHierarchy(Child."No."), 'child has parent');
        Assert.IsFalse(ProjectHierarchyMgt.IsInHierarchy(Single."No."), 'single project');
        ProjectHierarchyMgt.CheckStandardInvoicingAllowed(Single."No.");
    end;

    [Test]
    procedure StandardInvoicingBlockedInHierarchy()
    var
        Top: Record Job;
        Child: Record Job;
    begin
        // [SCENARIO] Standard invoicing on a hierarchy project points to the hierarchy action
        CreateProject(Top, '');
        CreateProject(Child, Top."No.");
        asserterror ProjectHierarchyMgt.CheckStandardInvoicingAllowed(Child."No.");
        Assert.ExpectedError(InHierarchyErrTok);
        Assert.ExpectedError(Top."No.");
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    procedure HierarchyInvoicingOnlyOnTopLevel()
    var
        Top: Record Job;
        Child: Record Job;
    begin
        // [SCENARIO] Hierarchy invoicing on a subproject is rejected
        CreateProject(Top, '');
        CreateProject(Child, Top."No.");
        asserterror ProjectHierarchyMgt.CheckTopLevel(Child);
        Assert.ExpectedError(NotTopLevelErrTok);
        Assert.ExpectedErrorCode('Dialog');
        ProjectHierarchyMgt.CheckTopLevel(Top);
    end;

    [Test]
    procedure ParentWithSubprojectsCannotBeDeleted()
    var
        Top: Record Job;
        Child: Record Job;
    begin
        // [SCENARIO] A project with subprojects cannot be deleted; a leaf can
        CreateProject(Top, '');
        CreateProject(Child, Top."No.");
        asserterror ProjectHierarchyMgt.CheckCanDelete(Top."No.");
        Assert.ExpectedError(HasSubprojectsErrTok);
        Assert.ExpectedErrorCode('Dialog');
        ProjectHierarchyMgt.CheckCanDelete(Child."No.");
    end;

    [Test]
    procedure BillingKeyFollowsTaskBillingMethod()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        BillToCustomerNo: Code[20];
        CurrencyCode: Code[10];
    begin
        // [SCENARIO] The billing key uses the project or the task depending on Task Billing Method; Currency Code wins
        // [GIVEN] a one-customer project with invoice currency EUR and a task with other values
        CreateProject(Job, '');
        Job."Bill-to Customer No." := 'C-PROJECT';
        Job."Invoice Currency Code" := 'EUR';
        JobTask."Bill-to Customer No." := 'C-TASK';
        JobTask."Invoice Currency Code" := 'USD';
        // [WHEN/THEN] One customer: project values
        HierarchyInvoicing.GetBillingKey(Job, JobTask, BillToCustomerNo, CurrencyCode);
        Assert.AreEqual('C-PROJECT', BillToCustomerNo, 'one customer bill-to');
        Assert.AreEqual('EUR', CurrencyCode, 'one customer currency');
        // [WHEN/THEN] Multiple customers: task values
        Job."Task Billing Method" := Job."Task Billing Method"::"Multiple customers";
        HierarchyInvoicing.GetBillingKey(Job, JobTask, BillToCustomerNo, CurrencyCode);
        Assert.AreEqual('C-TASK', BillToCustomerNo, 'multiple customers bill-to');
        Assert.AreEqual('USD', CurrencyCode, 'multiple customers currency');
        // [WHEN/THEN] Project Currency Code overrides the invoice currency
        Job."Currency Code" := 'GBP';
        HierarchyInvoicing.GetBillingKey(Job, JobTask, BillToCustomerNo, CurrencyCode);
        Assert.AreEqual('GBP', CurrencyCode, 'project currency');
    end;

    local procedure CreateProject(var Job: Record Job; ParentProjectNo: Code[20])
    begin
        Job.Init();
        Job."No." := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, MaxStrLen(Job."No."));
        Job."BGB Parent Project No." := ParentProjectNo;
        Job.Insert(false);
    end;
}
