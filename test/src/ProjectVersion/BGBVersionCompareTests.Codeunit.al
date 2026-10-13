namespace FlemmingBakkensen.BCGrokBot.Test.ProjectVersion;

using FlemmingBakkensen.BCGrokBot.ProjectVersion;
using Microsoft.Projects.Project.Archive;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Journal;
using Microsoft.Projects.Project.Ledger;
using Microsoft.Projects.Project.Planning;
using System.TestLibraries.Utilities;

codeunit 50162 "BGB Version Compare Tests"
{
    Subtype = Test;
    Access = Internal;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        VersionCompareMgt: Codeunit "BGB Version Compare Mgt.";
        ProjectArchiveMgt: Codeunit "BGB Project Archive Mgt.";
        NotTopLevelErrTok: Label 'Archive Hierarchy can only be run on a top-level project', Locked = true;

    [Test]
    procedure DifferenceAndChangePctIncludingZeroBase()
    begin
        // [SCENARIO] Difference is side B minus side A. Percentage change is zero when side A is zero.
        Assert.AreEqual(15, VersionCompareMgt.CalcDifference(10, 25), 'difference');
        Assert.AreEqual(-4, VersionCompareMgt.CalcDifference(4, 0), 'negative difference');
        Assert.AreEqual(150, VersionCompareMgt.CalcChangePct(10, 25), 'increase');
        Assert.AreEqual(-100, VersionCompareMgt.CalcChangePct(4, 0), 'decrease to zero');
        Assert.AreEqual(0, VersionCompareMgt.CalcChangePct(0, 50), 'zero base');
        Assert.AreEqual(0, VersionCompareMgt.CalcChangePct(0, 0), 'zero to zero');
        Assert.AreEqual(0, VersionCompareMgt.CalcRatioPct(10, 0), 'ratio with zero whole');
        Assert.AreEqual(40, VersionCompareMgt.CalcRatioPct(40, 100), 'ratio');
    end;

    [Test]
    procedure ZeroBaseChangeOnACompareRowIsZero()
    var
        TempCompareBuffer: Record "BGB Version Compare Buffer" temporary;
        ProjectNo: Code[20];
    begin
        // [SCENARIO] A compare row reports difference and a zero percentage when version A is zero
        // [GIVEN] version 1 has no usage and version 2 has usage 50
        ProjectNo := NewProjectNo();
        InsertProjectSnapshot(ProjectNo, 1, CreateGuid(), 0DT, 0, 0);
        InsertProjectSnapshot(ProjectNo, 2, CreateGuid(), 0DT, 50, 0);
        // [WHEN] the versions are compared
        VersionCompareMgt.BuildCompare(ProjectNo, 1, 2, false, "BGB Version Row Mode"::Projects, "BGB Version Amount View"::Total, TempCompareBuffer);
        // [THEN] the total row has difference 50 and change 0
        TempCompareBuffer.SetRange("Row Kind", TempCompareBuffer."Row Kind"::Total);
        TempCompareBuffer.FindFirst();
        Assert.AreEqual(0, TempCompareBuffer."Usage Cost A", 'usage A');
        Assert.AreEqual(50, TempCompareBuffer."Usage Cost B", 'usage B');
        Assert.AreEqual(50, TempCompareBuffer."Usage Cost Difference", 'difference');
        Assert.AreEqual(0, TempCompareBuffer."Usage Cost Change %", 'change from zero');
    end;

    [Test]
    procedure RunGroupsProjectsFromTheSameArchive()
    var
        TempCompareBuffer: Record "BGB Version Compare Buffer" temporary;
        TopNo: Code[20];
        ChildNo: Code[20];
        RunA: Guid;
        RunB: Guid;
    begin
        // [SCENARIO] Projects archived together share a run, and a later run of the top project does not invent amounts for a child that was not in it
        // [GIVEN] TOP and CHILD in run A, and only TOP in run B
        TopNo := NewProjectNo();
        ChildNo := NewProjectNo();
        RunA := CreateGuid();
        RunB := CreateGuid();
        InsertProjectSnapshot(TopNo, 1, RunA, 0DT, 10, 0);
        InsertChildSnapshot(ChildNo, TopNo, 1, RunA, 4);
        InsertProjectSnapshot(TopNo, 2, RunB, 0DT, 25, 0);
        // [WHEN] the top project is compared, projects view, version 1 against version 2
        VersionCompareMgt.BuildCompare(TopNo, 1, 2, false, "BGB Version Row Mode"::Projects, "BGB Version Amount View"::Total, TempCompareBuffer);
        // [THEN] both projects are rows, and the child has no amount on side B
        AssertProjectRow(TempCompareBuffer, TopNo, 10, 25, 15, 150);
        AssertProjectRow(TempCompareBuffer, ChildNo, 4, 0, -4, -100);
        TempCompareBuffer.SetRange("Row Kind", TempCompareBuffer."Row Kind"::Total);
        TempCompareBuffer.FindFirst();
        Assert.AreEqual(14, TempCompareBuffer."Usage Cost A", 'total A');
        Assert.AreEqual(25, TempCompareBuffer."Usage Cost B", 'total B');
        Assert.AreEqual(11, TempCompareBuffer."Usage Cost Difference", 'total difference');
    end;

    [Test]
    procedure ArchiveWithoutSnapshotFallsBackToTaskTotals()
    var
        TempCompareBuffer: Record "BGB Version Compare Buffer" temporary;
        ProjectNo: Code[20];
    begin
        // [SCENARIO] A project archive that has no snapshot uses the task archive totals and is marked no breakdown
        // [GIVEN] an archived posting task with usage and a budget planning line, and no snapshot
        ProjectNo := NewProjectNo();
        InsertTaskArchive(ProjectNo, '100', 1, 40, 60, 10, 20);
        InsertPlanningArchive(ProjectNo, '100', 1, 10000, true, false, "Job Planning Line Type"::Resource, 100, 150);
        // [WHEN] version 1 is compared with current, total view
        VersionCompareMgt.BuildCompare(ProjectNo, 1, 0, true, "BGB Version Row Mode"::Tasks, "BGB Version Amount View"::Total, TempCompareBuffer);
        // [THEN] the task row has the archive totals, no type split is claimed, and current is zero
        TempCompareBuffer.SetRange("Job Task No.", '100');
        TempCompareBuffer.FindFirst();
        Assert.IsTrue(TempCompareBuffer."No Breakdown", 'no breakdown');
        Assert.AreEqual(40, TempCompareBuffer."Usage Cost A", 'usage cost');
        Assert.AreEqual(60, TempCompareBuffer."Usage Price A", 'usage price');
        Assert.AreEqual(10, TempCompareBuffer."Invoiced Cost A", 'invoiced cost');
        Assert.AreEqual(20, TempCompareBuffer."Invoiced Price A", 'invoiced price');
        Assert.AreEqual(100, TempCompareBuffer."Budget Cost A", 'budget cost');
        Assert.AreEqual(150, TempCompareBuffer."Budget Price A", 'budget price');
        Assert.AreEqual(0, TempCompareBuffer."Usage Cost B", 'current usage');
        // [WHEN] the same compare is shown for resources only
        Clear(TempCompareBuffer);
        VersionCompareMgt.BuildCompare(ProjectNo, 1, 0, true, "BGB Version Row Mode"::Tasks, "BGB Version Amount View"::Resource, TempCompareBuffer);
        // [THEN] the type view is zero because there is no breakdown
        TempCompareBuffer.SetRange("Job Task No.", '100');
        TempCompareBuffer.FindFirst();
        Assert.AreEqual(0, TempCompareBuffer."Usage Cost A", 'resource usage without breakdown');
        Assert.AreEqual(0, TempCompareBuffer."Budget Cost A", 'resource budget without breakdown');
    end;

    [Test]
    procedure TrendIsOrderedByRunWithCurrentLast()
    var
        Job: Record Job;
        TempTrendBuffer: Record "BGB Version Trend Buffer" temporary;
        ProjectNo: Code[20];
    begin
        // [SCENARIO] Trend rows follow the archive time, and current is last, with the change since the previous row
        // [GIVEN] a later run inserted first, then an earlier run, and a project with no posted usage
        ProjectNo := NewProjectNo();
        InsertJob(Job, ProjectNo);
        InsertProjectSnapshot(ProjectNo, 2, CreateGuid(), CreateDateTime(DMY2Date(2, 1, 2026), 120000T), 40, 100);
        InsertProjectSnapshot(ProjectNo, 1, CreateGuid(), CreateDateTime(DMY2Date(1, 1, 2026), 080000T), 10, 100);
        // [WHEN] the trend is built for the project's own totals
        VersionCompareMgt.BuildTrend(ProjectNo, false, TempTrendBuffer);
        // [THEN] version 1, version 2, current
        TempTrendBuffer.SetCurrentKey("Sort Order");
        Assert.IsTrue(TempTrendBuffer.FindFirst(), 'first row');
        AssertTrendRow(TempTrendBuffer, 1, 10, 0, 10, false);
        Assert.AreEqual(1, TempTrendBuffer.Next(), 'second');
        AssertTrendRow(TempTrendBuffer, 2, 40, 30, 40, false);
        Assert.AreEqual(1, TempTrendBuffer.Next(), 'current');
        AssertTrendRow(TempTrendBuffer, 0, 0, -40, 0, true);
        Assert.AreEqual(0, TempTrendBuffer.Next(), 'no more rows');
    end;

    [Test]
    procedure TaskAmountsSplitLedgerAndPlanningLinesByType()
    var
        TaskSnapshot: Record "BGB Project Task Snapshot";
        ProjectNo: Code[20];
    begin
        // [SCENARIO] Usage and invoiced amounts are split from ledger entries, and budget and billable amounts from archived planning lines
        // [GIVEN] resource, item and G/L usage and sale entries, and planning lines of each kind
        ProjectNo := NewProjectNo();
        InsertLedger(ProjectNo, '100', "Job Journal Line Entry Type"::Usage, "Job Journal Line Type"::Resource, 10, 20);
        InsertLedger(ProjectNo, '100', "Job Journal Line Entry Type"::Usage, "Job Journal Line Type"::Item, 3, 4);
        InsertLedger(ProjectNo, '100', "Job Journal Line Entry Type"::Usage, "Job Journal Line Type"::"G/L Account", 5, 6);
        InsertLedger(ProjectNo, '100', "Job Journal Line Entry Type"::Sale, "Job Journal Line Type"::Resource, -7, -8);
        InsertLedger(ProjectNo, '100', "Job Journal Line Entry Type"::Sale, "Job Journal Line Type"::Item, -1, -2);
        InsertPlanningArchive(ProjectNo, '100', 1, 10000, true, false, "Job Planning Line Type"::Resource, 100, 200);
        InsertPlanningArchive(ProjectNo, '100', 1, 20000, false, true, "Job Planning Line Type"::Item, 9, 11);
        InsertPlanningArchive(ProjectNo, '100', 1, 30000, true, true, "Job Planning Line Type"::"G/L Account", 4, 5);
        // [WHEN] the task amounts are calculated from the archive
        ProjectArchiveMgt.CalculateTaskAmounts(ProjectNo, '100', 1, true, TaskSnapshot);
        // [THEN] the split matches Job Calculate Statistics' sign rules, and a both-budget-and-billable line counts in both
        Assert.AreEqual(10, TaskSnapshot."Usage Cost Resource", 'usage cost resource');
        Assert.AreEqual(3, TaskSnapshot."Usage Cost Item", 'usage cost item');
        Assert.AreEqual(5, TaskSnapshot."Usage Cost G/L Acc.", 'usage cost g/l');
        Assert.AreEqual(18, TaskSnapshot."Usage Cost Total", 'usage cost total');
        Assert.AreEqual(20, TaskSnapshot."Usage Price Resource", 'usage price resource');
        Assert.AreEqual(7, TaskSnapshot."Invoiced Cost Resource", 'invoiced cost resource');
        Assert.AreEqual(1, TaskSnapshot."Invoiced Cost Item", 'invoiced cost item');
        Assert.AreEqual(0, TaskSnapshot."Invoiced Cost G/L Acc.", 'invoiced cost g/l');
        Assert.AreEqual(8, TaskSnapshot."Invoiced Cost Total", 'invoiced cost total');
        Assert.AreEqual(8, TaskSnapshot."Invoiced Price Resource", 'invoiced price resource');
        Assert.AreEqual(2, TaskSnapshot."Invoiced Price Item", 'invoiced price item');
        Assert.AreEqual(100, TaskSnapshot."Budget Cost Resource", 'budget cost resource');
        Assert.AreEqual(4, TaskSnapshot."Budget Cost G/L Acc.", 'budget cost g/l');
        Assert.AreEqual(104, TaskSnapshot."Budget Cost Total", 'budget cost total');
        Assert.AreEqual(9, TaskSnapshot."Billable Cost Item", 'billable cost item');
        Assert.AreEqual(4, TaskSnapshot."Billable Cost G/L Acc.", 'billable cost g/l');
        Assert.AreEqual(13, TaskSnapshot."Billable Cost Total", 'billable cost total');
        Assert.AreEqual(205, TaskSnapshot."Budget Price Total", 'budget price total');
        Assert.AreEqual(16, TaskSnapshot."Billable Price Total", 'billable price total');
    end;

    [Test]
    procedure ArchiveHierarchyRejectsASubproject()
    var
        Job: Record Job;
    begin
        // [SCENARIO] Archive Hierarchy runs only on a top-level project
        Job.Init();
        Job."No." := NewProjectNo();
        Job."BGB Parent Project No." := NewProjectNo();
        asserterror ProjectArchiveMgt.ArchiveHierarchy(Job);
        Assert.ExpectedError(NotTopLevelErrTok);
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    procedure OpenTopLevelSelectionSkipsChildrenAndCompleted()
    var
        OpenTop: Code[20];
        ChildNo: Code[20];
        CompletedNo: Code[20];
        OtherTop: Code[20];
        Prefix: Code[10];
        ProjectNos: List of [Code[20]];
    begin
        // [SCENARIO] The job queue selection is every open top-level project matching the project number filter
        Prefix := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 8);
        OpenTop := CopyStr(Prefix + '-A', 1, 20);
        ChildNo := CopyStr(Prefix + '-B', 1, 20);
        CompletedNo := CopyStr(Prefix + '-C', 1, 20);
        OtherTop := CopyStr(Prefix + '-D', 1, 20);
        InsertOpenJob(OpenTop, '', "Job Status"::Open);
        InsertOpenJob(ChildNo, OpenTop, "Job Status"::Open);
        InsertOpenJob(CompletedNo, '', "Job Status"::Completed);
        InsertOpenJob(OtherTop, '', "Job Status"::Open);
        // [WHEN] the filter matches the prefix
        ProjectNos := ProjectArchiveMgt.GetOpenTopLevelProjectNos(Prefix + '-*');
        // [THEN] the open top-level projects are returned, not the child or the completed project
        Assert.AreEqual(2, ProjectNos.Count(), 'count');
        Assert.IsTrue(ProjectNos.Contains(OpenTop), 'open top');
        Assert.IsTrue(ProjectNos.Contains(OtherTop), 'other top');
        Assert.IsFalse(ProjectNos.Contains(ChildNo), 'child');
        Assert.IsFalse(ProjectNos.Contains(CompletedNo), 'completed');
    end;

    [Test]
    procedure MoveAndDeleteKeepSnapshotKeysInStep()
    var
        Snapshot: Record "BGB Project Snapshot";
        TaskSnapshot: Record "BGB Project Task Snapshot";
        ArchiveRun: Record "BGB Project Archive Run";
        OldNo: Code[20];
        NewNo: Code[20];
        OtherNo: Code[20];
        RunId: Guid;
    begin
        // [SCENARIO] Moving a snapshot follows a project rename, and deleting one version removes only that version
        OldNo := NewProjectNo();
        NewNo := NewProjectNo();
        OtherNo := NewProjectNo();
        RunId := CreateGuid();
        InsertRun(RunId, OldNo);
        InsertProjectSnapshot(OldNo, 1, RunId, 0DT, 5, 0);
        InsertTaskSnapshot(OldNo, '100', 1, RunId, 5);
        InsertProjectSnapshot(OtherNo, 1, RunId, 0DT, 1, 0);
        Snapshot.Get(OtherNo, 1);
        Snapshot."Parent Project No." := OldNo;
        Snapshot.Modify(false);
        // [WHEN] the version is moved to the new project number
        ProjectArchiveMgt.MoveSnapshots(OldNo, NewNo, 1);
        // [THEN] the snapshot, the task and the run header follow, and a child snapshot points at the new parent
        Assert.IsFalse(Snapshot.Get(OldNo, 1), 'old snapshot');
        Snapshot.Get(NewNo, 1);
        Assert.AreEqual(5, Snapshot."Usage Cost Total", 'moved usage');
        TaskSnapshot.Get(NewNo, 1, '100');
        ArchiveRun.Get(RunId);
        Assert.AreEqual(NewNo, ArchiveRun."Top Project No.", 'run header');
        Snapshot.Get(OtherNo, 1);
        Assert.AreEqual(NewNo, Snapshot."Parent Project No.", 'parent reference');
        // [WHEN] the moved version is deleted
        ProjectArchiveMgt.DeleteSnapshots(NewNo, 1);
        // [THEN] that version is gone and the other project in the run keeps the run
        Assert.IsFalse(Snapshot.Get(NewNo, 1), 'deleted snapshot');
        Assert.IsFalse(TaskSnapshot.Get(NewNo, 1, '100'), 'deleted task');
        Assert.IsTrue(ArchiveRun.Get(RunId), 'run remains');
        // [WHEN] the last snapshot in the run is deleted
        ProjectArchiveMgt.DeleteSnapshots(OtherNo, 1);
        // [THEN] the run is removed
        Assert.IsFalse(ArchiveRun.Get(RunId), 'empty run');
    end;

    local procedure AssertProjectRow(var TempCompareBuffer: Record "BGB Version Compare Buffer" temporary; ProjectNo: Code[20]; UsageA: Decimal; UsageB: Decimal; Difference: Decimal; ChangePct: Decimal)
    begin
        TempCompareBuffer.SetRange("Project No.", ProjectNo);
        TempCompareBuffer.SetRange("Row Kind", TempCompareBuffer."Row Kind"::Project);
        TempCompareBuffer.FindFirst();
        Assert.AreEqual(UsageA, TempCompareBuffer."Usage Cost A", 'usage A ' + ProjectNo);
        Assert.AreEqual(UsageB, TempCompareBuffer."Usage Cost B", 'usage B ' + ProjectNo);
        Assert.AreEqual(Difference, TempCompareBuffer."Usage Cost Difference", 'difference ' + ProjectNo);
        Assert.AreEqual(ChangePct, TempCompareBuffer."Usage Cost Change %", 'change ' + ProjectNo);
        TempCompareBuffer.SetRange("Project No.");
        TempCompareBuffer.SetRange("Row Kind");
    end;

    local procedure AssertTrendRow(var TempTrendBuffer: Record "BGB Version Trend Buffer"; VersionNo: Integer; UsageCost: Decimal; UsageDelta: Decimal; UsagePct: Decimal; IsCurrent: Boolean)
    begin
        Assert.AreEqual(VersionNo, TempTrendBuffer."Version No.", 'version');
        Assert.AreEqual(UsageCost, TempTrendBuffer."Usage Cost", 'usage');
        Assert.AreEqual(UsageDelta, TempTrendBuffer."Usage Cost Delta", 'delta');
        Assert.AreEqual(UsagePct, TempTrendBuffer."Usage % of Budget", 'usage pct');
        Assert.AreEqual(IsCurrent, TempTrendBuffer."Is Current", 'current');
    end;

    local procedure InsertJob(var Job: Record Job; ProjectNo: Code[20])
    begin
        Job.Init();
        Job."No." := ProjectNo;
        Job.Description := ProjectNo;
        Job.Insert(false);
    end;

    local procedure InsertOpenJob(ProjectNo: Code[20]; ParentNo: Code[20]; Status: Enum "Job Status")
    var
        Job: Record Job;
    begin
        Job.Init();
        Job."No." := ProjectNo;
        Job."BGB Parent Project No." := ParentNo;
        Job.Status := Status;
        Job.Insert(false);
    end;

    local procedure InsertRun(RunId: Guid; TopProjectNo: Code[20])
    var
        ArchiveRun: Record "BGB Project Archive Run";
    begin
        ArchiveRun.Init();
        ArchiveRun."Run ID" := RunId;
        ArchiveRun."Run At" := CurrentDateTime();
        ArchiveRun."Top Project No." := TopProjectNo;
        ArchiveRun.Hierarchy := true;
        ArchiveRun.Insert(false);
    end;

    local procedure InsertProjectSnapshot(ProjectNo: Code[20]; VersionNo: Integer; RunId: Guid; RunAt: DateTime; UsageCost: Decimal; BudgetCost: Decimal)
    var
        Snapshot: Record "BGB Project Snapshot";
    begin
        Snapshot.Init();
        Snapshot."Job No." := ProjectNo;
        Snapshot."Version No." := VersionNo;
        Snapshot."Run ID" := RunId;
        Snapshot."Run At" := RunAt;
        Snapshot.Description := ProjectNo;
        Snapshot."Usage Cost Total" := UsageCost;
        Snapshot."Budget Cost Total" := BudgetCost;
        Snapshot.Insert(false);
    end;

    local procedure InsertChildSnapshot(ProjectNo: Code[20]; ParentNo: Code[20]; VersionNo: Integer; RunId: Guid; UsageCost: Decimal)
    var
        Snapshot: Record "BGB Project Snapshot";
    begin
        InsertProjectSnapshot(ProjectNo, VersionNo, RunId, 0DT, UsageCost, 0);
        Snapshot.Get(ProjectNo, VersionNo);
        Snapshot."Parent Project No." := ParentNo;
        Snapshot.Level := 1;
        Snapshot.Modify(false);
    end;

    local procedure InsertTaskSnapshot(ProjectNo: Code[20]; TaskNo: Code[20]; VersionNo: Integer; RunId: Guid; UsageCost: Decimal)
    var
        TaskSnapshot: Record "BGB Project Task Snapshot";
    begin
        TaskSnapshot.Init();
        TaskSnapshot."Job No." := ProjectNo;
        TaskSnapshot."Version No." := VersionNo;
        TaskSnapshot."Job Task No." := TaskNo;
        TaskSnapshot."Run ID" := RunId;
        TaskSnapshot."Job Task Type" := TaskSnapshot."Job Task Type"::Posting;
        TaskSnapshot."Usage Cost Total" := UsageCost;
        TaskSnapshot.Insert(false);
    end;

    local procedure InsertTaskArchive(ProjectNo: Code[20]; TaskNo: Code[20]; VersionNo: Integer; UsageCost: Decimal; UsagePrice: Decimal; InvoicedCost: Decimal; InvoicedPrice: Decimal)
    var
        JobTaskArchive: Record "Job Task Archive";
    begin
        JobTaskArchive.Init();
        JobTaskArchive."Job No." := ProjectNo;
        JobTaskArchive."Job Task No." := TaskNo;
        JobTaskArchive."Version No." := VersionNo;
        JobTaskArchive."Job Task Type" := JobTaskArchive."Job Task Type"::Posting;
        JobTaskArchive.Description := TaskNo;
        JobTaskArchive."Usage (Total Cost)" := UsageCost;
        JobTaskArchive."Usage (Total Price)" := UsagePrice;
        JobTaskArchive."Contract (Invoiced Cost)" := InvoicedCost;
        JobTaskArchive."Contract (Invoiced Price)" := InvoicedPrice;
        JobTaskArchive.Insert(false);
    end;

    local procedure InsertPlanningArchive(ProjectNo: Code[20]; TaskNo: Code[20]; VersionNo: Integer; LineNo: Integer; Schedule: Boolean; Contract: Boolean; LineType: Enum "Job Planning Line Type"; Cost: Decimal; Price: Decimal)
    var
        Line: Record "Job Planning Line Archive";
    begin
        Line.Init();
        Line."Job No." := ProjectNo;
        Line."Job Task No." := TaskNo;
        Line."Version No." := VersionNo;
        Line."Line No." := LineNo;
        Line."Schedule Line" := Schedule;
        Line."Contract Line" := Contract;
        Line.Type := LineType;
        Line."Total Cost (LCY)" := Cost;
        Line."Line Amount (LCY)" := Price;
        Line.Insert(false);
    end;

    local procedure InsertLedger(ProjectNo: Code[20]; TaskNo: Code[20]; EntryType: Enum "Job Journal Line Entry Type"; LineType: Enum "Job Journal Line Type"; Cost: Decimal; Price: Decimal)
    var
        JobLedgerEntry: Record "Job Ledger Entry";
    begin
        JobLedgerEntry.Init();
        JobLedgerEntry."Entry No." := NextEntryNo();
        JobLedgerEntry."Job No." := ProjectNo;
        JobLedgerEntry."Job Task No." := TaskNo;
        JobLedgerEntry."Entry Type" := EntryType;
        JobLedgerEntry.Type := LineType;
        JobLedgerEntry."Total Cost (LCY)" := Cost;
        JobLedgerEntry."Line Amount (LCY)" := Price;
        JobLedgerEntry.Insert(false);
    end;

    local procedure NextEntryNo(): Integer
    var
        JobLedgerEntry: Record "Job Ledger Entry";
    begin
        if JobLedgerEntry.FindLast() then
            exit(JobLedgerEntry."Entry No." + 1);
        exit(1);
    end;

    local procedure NewProjectNo(): Code[20]
    begin
        exit(CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 20));
    end;
}
