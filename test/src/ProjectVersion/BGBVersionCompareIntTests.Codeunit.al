namespace FlemmingBakkensen.BCGrokBot.Test.ProjectVersion;

using FlemmingBakkensen.BCGrokBot.ProjectVersion;
using FlemmingBakkensen.BCGrokBot.Test.ProjectHierarchy;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Foundation.NoSeries;
using Microsoft.Projects.Project.Archive;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Journal;
using Microsoft.Projects.Project.Ledger;
using Microsoft.Projects.Project.Planning;
using Microsoft.Projects.Project.Setup;
using Microsoft.Projects.Resources.Resource;
using System.TestLibraries.Utilities;
using System.Threading;
using System.Utilities;

/// <summary>
/// Container-only: archive snapshots, hierarchy runs, auto-archive, delete and rename, compare page, Excel report and the job queue codeunit.
/// </summary>
codeunit 50163 "BGB Version Compare Int Tests"
{
    Subtype = Test;
    Access = Internal;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        ProjectTestData: Codeunit "BGB Project Test Data";
        ProjectArchiveMgt: Codeunit "BGB Project Archive Mgt.";
        NothingFoundErr: Label 'No %1 is available for the version compare test.', Comment = '%1 = table caption';

    [Test]
    procedure SnapshotDeltasAndPerTypeMatchStatistics()
    var
        Job: Record Job;
        Snapshot1: Record "BGB Project Snapshot";
        Snapshot2: Record "BGB Project Snapshot";
        TaskSnapshot: Record "BGB Project Task Snapshot";
        ArchiveRun: Record "BGB Project Archive Run";
        JobCalculateStatistics: Codeunit "Job Calculate Statistics";
        Cost: array[16] of Decimal;
        Price: array[16] of Decimal;
        ProjectNo: Code[20];
        CustomerNo: Code[20];
    begin
        // [SCENARIO] Archive, record usage and sale, archive again: the snapshot delta and the per-type split match Job Calculate Statistics
        // [GIVEN] a project with resource, item and G/L budget-and-billable lines
        CustomerNo := ProjectTestData.UpsertCustomer(CopyStr(NewNo() + 'C', 1, 20), 'Version compare customer');
        ProjectNo := CopyStr(NewNo(), 1, 20);
        ProjectTestData.CreateProject(Job, ProjectNo, 'Version compare', '', CustomerNo, '', '');
        Job.Validate("Apply Usage Link", false);
        Job.Modify(true);
        CreateTypedLine(Job, '100', "Job Planning Line Type"::Resource, FindResourceNo(), 2, 40, 80);
        CreateTypedLine(Job, '100', "Job Planning Line Type"::"G/L Account", FindGLAccountNo(), 1, 6, 9);
        // [WHEN] the project is archived, usage and sale entries are recorded, and it is archived again
        StoreProject(Job);
        Snapshot1.SetRange("Job No.", ProjectNo);
        Snapshot1.FindFirst();
        ArchiveRun.Get(Snapshot1."Run ID");
        Assert.IsFalse(ArchiveRun.Hierarchy, 'single project run');
        InsertUsageAndSale(ProjectNo, '100');
        Job.Get(ProjectNo);
        StoreProject(Job);
        Snapshot2.SetRange("Job No.", ProjectNo);
        Snapshot2.FindLast();
        JobCalculateStatistics.JobCalculateCommonFilters(Job);
        JobCalculateStatistics.CalculateAmounts();
        JobCalculateStatistics.GetLCYCostAmounts(Cost);
        JobCalculateStatistics.GetLCYPriceAmounts(Price);
        // [THEN] version 2 matches statistics, the delta from version 1 equals the posted usage and invoicing, and the task split matches
        AssertAmounts(Snapshot2, Cost, Price);
        Assert.AreEqual(Cost[5] - Snapshot1."Usage Cost Resource", Snapshot2."Usage Cost Resource" - Snapshot1."Usage Cost Resource", 'usage resource delta');
        Assert.AreEqual(Cost[8], Snapshot2."Usage Cost Total" - Snapshot1."Usage Cost Total", 'usage total delta');
        Assert.AreEqual(Price[8], Snapshot2."Usage Price Total" - Snapshot1."Usage Price Total", 'usage price delta');
        Assert.AreEqual(Cost[16], Snapshot2."Invoiced Cost Total" - Snapshot1."Invoiced Cost Total", 'invoiced cost delta');
        Assert.AreEqual(Price[16], Snapshot2."Invoiced Price Total" - Snapshot1."Invoiced Price Total", 'invoiced price delta');
        Assert.AreEqual(0, Snapshot1."Usage Cost Total", 'version 1 had no usage');
        Assert.AreEqual(0, Snapshot1."Invoiced Price Total", 'version 1 had no invoice');
        TaskSnapshot.SetRange("Job No.", ProjectNo);
        TaskSnapshot.SetRange("Version No.", Snapshot2."Version No.");
        TaskSnapshot.SetRange("Job Task No.", '100');
        TaskSnapshot.FindFirst();
        Assert.AreEqual(Cost[5], TaskSnapshot."Usage Cost Resource", 'task usage resource');
        Assert.AreEqual(Cost[6], TaskSnapshot."Usage Cost Item", 'task usage item');
        Assert.AreEqual(Cost[7], TaskSnapshot."Usage Cost G/L Acc.", 'task usage g/l');
        Assert.AreEqual(Cost[8], TaskSnapshot."Usage Cost Total", 'task usage total');
        Assert.AreEqual(Price[5], TaskSnapshot."Usage Price Resource", 'task usage price resource');
        Assert.AreEqual(Price[6], TaskSnapshot."Usage Price Item", 'task usage price item');
        Assert.AreEqual(Price[7], TaskSnapshot."Usage Price G/L Acc.", 'task usage price g/l');
        Assert.AreEqual(Cost[13], TaskSnapshot."Invoiced Cost Resource", 'task invoiced resource');
        Assert.AreEqual(Cost[14], TaskSnapshot."Invoiced Cost Item", 'task invoiced item');
        Assert.AreEqual(Cost[15], TaskSnapshot."Invoiced Cost G/L Acc.", 'task invoiced g/l');
        Assert.AreEqual(Cost[16], TaskSnapshot."Invoiced Cost Total", 'task invoiced total');
        Assert.AreEqual(Price[13], TaskSnapshot."Invoiced Price Resource", 'task invoiced price resource');
        Assert.AreEqual(Price[16], TaskSnapshot."Invoiced Price Total", 'task invoiced price total');
        Assert.AreEqual(Cost[1], TaskSnapshot."Budget Cost Resource", 'task budget resource');
        Assert.AreEqual(Cost[4], TaskSnapshot."Budget Cost Total", 'task budget total');
    end;

    [Test]
    procedure ArchiveHierarchyIsOneRunOverTheTree()
    var
        TopJob: Record Job;
        Job: Record Job;
        Snapshot: Record "BGB Project Snapshot";
        ArchiveRun: Record "BGB Project Archive Run";
        CustomerNo: Code[20];
        Prefix: Code[12];
        TopNo: Code[20];
        Child1No: Code[20];
        Child2No: Code[20];
        Grand1No: Code[20];
        Grand2No: Code[20];
        RunId: Guid;
    begin
        // [SCENARIO] Archive Hierarchy stores the top project and four descendants under one run
        Prefix := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 12);
        CustomerNo := ProjectTestData.UpsertCustomer(CopyStr(Prefix + 'C', 1, 20), 'Hierarchy archive customer');
        TopNo := CopyStr(Prefix + 'T', 1, 20);
        Child1No := CopyStr(Prefix + '1', 1, 20);
        Child2No := CopyStr(Prefix + '2', 1, 20);
        Grand1No := CopyStr(Prefix + 'G', 1, 20);
        Grand2No := CopyStr(Prefix + 'H', 1, 20);
        ProjectTestData.CreateProject(TopJob, TopNo, 'Top', '', CustomerNo, '', '');
        ProjectTestData.CreateTaskWithBillableLine(TopJob, '100', 1, 100);
        ProjectTestData.CreateProject(Job, Child1No, 'Child 1', TopNo, CustomerNo, '', '');
        ProjectTestData.CreateTaskWithBillableLine(Job, '100', 1, 100);
        ProjectTestData.CreateProject(Job, Child2No, 'Child 2', TopNo, CustomerNo, '', '');
        ProjectTestData.CreateTaskWithBillableLine(Job, '100', 1, 100);
        ProjectTestData.CreateProject(Job, Grand1No, 'Grand 1', Child2No, CustomerNo, '', '');
        ProjectTestData.CreateTaskWithBillableLine(Job, '100', 1, 100);
        ProjectTestData.CreateProject(Job, Grand2No, 'Grand 2', Child2No, CustomerNo, '', '');
        ProjectTestData.CreateTaskWithBillableLine(Job, '100', 1, 100);
        // [WHEN] the hierarchy is archived
        ProjectArchiveMgt.ResetAnalysisBuildCount();
        ProjectArchiveMgt.ArchiveHierarchy(TopJob);
        // [THEN] five snapshots share one hierarchy run, and a child keeps its parent
        Snapshot.SetRange("Job No.", TopNo);
        Snapshot.FindFirst();
        RunId := Snapshot."Run ID";
        ArchiveRun.Get(RunId);
        Assert.IsTrue(ArchiveRun.Hierarchy, 'hierarchy run');
        Assert.AreEqual(TopNo, ArchiveRun."Top Project No.", 'top project');
        AssertSameRun(Child1No, RunId);
        AssertSameRun(Child2No, RunId);
        AssertSameRun(Grand1No, RunId);
        AssertSameRun(Grand2No, RunId);
        Snapshot.SetRange("Job No.");
        Snapshot.SetRange("Run ID", RunId);
        Assert.AreEqual(5, Snapshot.Count(), 'snapshots in the run');
        Snapshot.SetRange("Job No.", Grand1No);
        Snapshot.FindFirst();
        Assert.AreEqual(Child2No, Snapshot."Parent Project No.", 'parent');
        Assert.AreEqual(2, Snapshot.Level, 'level');
        Assert.AreEqual(1, ProjectArchiveMgt.AnalysisBuildCount(), 'tree analysis once');
        Snapshot.SetRange("Job No.", TopNo);
        Snapshot.FindFirst();
        Assert.AreEqual(SumBillablePrice(RunId), Snapshot."Hier. Billable Price", 'hierarchy billable from the one analysis');
    end;

    [Test]
    procedure AutoArchiveOnStatusChangeCreatesSnapshot()
    var
        Job: Record Job;
        JobsSetup: Record "Jobs Setup";
        Snapshot: Record "BGB Project Snapshot";
        PreviousOption: Enum "Job Archive Option";
        CustomerNo: Code[20];
        ProjectNo: Code[20];
    begin
        // [SCENARIO] With Archive Projects set to Always, changing the project status archives it and stores a snapshot
        JobsSetup.Get();
        PreviousOption := JobsSetup."Archive Jobs";
        JobsSetup."Archive Jobs" := JobsSetup."Archive Jobs"::Always;
        JobsSetup.Modify(false);
        CustomerNo := ProjectTestData.UpsertCustomer(CopyStr(NewNo() + 'C', 1, 20), 'Auto archive customer');
        ProjectNo := CopyStr(NewNo(), 1, 20);
        ProjectTestData.CreateProject(Job, ProjectNo, 'Auto archive', '', CustomerNo, '', '');
        ProjectTestData.CreateTaskWithBillableLine(Job, '100', 1, 50);
        // [WHEN] the status changes
        Job.Validate(Status, Job.Status::Planning);
        Job.Modify(true);
        // [THEN] a snapshot exists and it was not taken during project delete
        Snapshot.SetRange("Job No.", ProjectNo);
        Assert.IsTrue(Snapshot.FindFirst(), 'snapshot');
        Assert.IsFalse(Snapshot."During Project Delete", 'not during delete');
        Assert.AreNotEqual(0, Snapshot."Budget Price Total", 'budget was snapshotted');
        JobsSetup.Get();
        JobsSetup."Archive Jobs" := PreviousOption;
        JobsSetup.Modify(false);
    end;

    [Test]
    procedure DeleteAndRenameKeepSnapshotsInStep()
    var
        Job: Record Job;
        JobArchive: Record "Job Archive";
        Snapshot: Record "BGB Project Snapshot";
        CustomerNo: Code[20];
        ProjectNo: Code[20];
        NewProjectNo: Code[20];
    begin
        // [SCENARIO] Deleting a project archive deletes its snapshots, and renaming the project moves them
        CustomerNo := ProjectTestData.UpsertCustomer(CopyStr(NewNo() + 'C', 1, 20), 'Rename customer');
        ProjectNo := CopyStr(NewNo(), 1, 20);
        NewProjectNo := CopyStr(NewNo(), 1, 20);
        ProjectTestData.CreateProject(Job, ProjectNo, 'Rename me', '', CustomerNo, '', '');
        ProjectTestData.CreateTaskWithBillableLine(Job, '100', 1, 10);
        StoreProject(Job);
        JobArchive.SetRange("No.", ProjectNo);
        JobArchive.FindFirst();
        // [WHEN] the archive version is deleted
        JobArchive.Delete(true);
        // [THEN] the snapshot is gone
        Snapshot.SetRange("Job No.", ProjectNo);
        Assert.IsTrue(Snapshot.IsEmpty(), 'snapshot deleted with the archive');
        // [WHEN] the project is archived again and renamed
        StoreProject(Job);
        Job.Rename(NewProjectNo);
        // [THEN] the archive and the snapshot use the new number
        JobArchive.SetRange("No.", NewProjectNo);
        Assert.IsFalse(JobArchive.IsEmpty(), 'archive renamed');
        Snapshot.SetRange("Job No.", NewProjectNo);
        Assert.IsTrue(Snapshot.FindFirst(), 'snapshot renamed');
        Snapshot.SetRange("Job No.", ProjectNo);
        Assert.IsTrue(Snapshot.IsEmpty(), 'old snapshot number');
    end;

    [Test]
    procedure ComparePageShowsTheVersionDifference()
    var
        Job: Record Job;
        TempCompareBuffer: Record "BGB Version Compare Buffer" temporary;
        VersionCompareMgt: Codeunit "BGB Version Compare Mgt.";
        ComparePage: TestPage "BGB Project Version Compare";
        CustomerNo: Code[20];
        ProjectNo: Code[20];
    begin
        // [SCENARIO] The compare page shows the difference between two archive versions
        CustomerNo := ProjectTestData.UpsertCustomer(CopyStr(NewNo() + 'C', 1, 20), 'Page customer');
        ProjectNo := CopyStr(NewNo(), 1, 20);
        ProjectTestData.CreateProject(Job, ProjectNo, 'Page compare', '', CustomerNo, '', '');
        ProjectTestData.CreateTaskWithBillableLine(Job, '100', 1, 100);
        StoreProject(Job);
        InsertLedger(ProjectNo, '100', "Job Journal Line Entry Type"::Usage, "Job Journal Line Type"::Resource, 80, 100);
        StoreProject(Job);
        VersionCompareMgt.BuildCompare(ProjectNo, 1, 2, false, "BGB Version Row Mode"::Tasks, "BGB Version Amount View"::Total, TempCompareBuffer);
        TempCompareBuffer.SetRange("Row Kind", TempCompareBuffer."Row Kind"::Total);
        TempCompareBuffer.FindFirst();
        Assert.AreEqual(80, TempCompareBuffer."Usage Cost Difference", 'buffer difference');
        // [WHEN] the page compares version 1 with version 2
        ComparePage.OpenEdit();
        ComparePage.ProjectNo.SetValue(ProjectNo);
        ComparePage.VersionB.SetValue(2);
        ComparePage.VersionA.SetValue(1);
        ComparePage.CompareTo.SetValue('Version');
        // [THEN] the total row shows the budget price difference of the extra quantity
        ComparePage.Last();
        ComparePage.UsageCostDifference.AssertEquals(80);
    end;

    [Test]
    procedure VersionTrendReportIsAnExcelWorkbook()
    var
        Job: Record Job;
        TempBlob: Codeunit "Temp Blob";
        RecRef: RecordRef;
        OutStr: OutStream;
        InStr: InStream;
        Header: Text;
    begin
        // [SCENARIO] The Project Version Trend report produces an xlsx workbook
        Job.SetRange("No.", CreateReportedProject());
        RecRef.GetTable(Job);
        TempBlob.CreateOutStream(OutStr);
        Report.SaveAs(Report::"BGB Project Version Trend", '', ReportFormat::Excel, OutStr, RecRef);
        Assert.IsTrue(TempBlob.Length() > 1000, 'Excel output');
        TempBlob.CreateInStream(InStr);
        InStr.ReadText(Header);
        Assert.IsTrue(Header.StartsWith('PK'), 'xlsx zip header');
    end;

    [Test]
    procedure FailedHierarchyArchiveThenNormalArchiveHasItsOwnRun()
    var
        TopJob: Record Job;
        ChildJob: Record Job;
        Snapshot: Record "BGB Project Snapshot";
        ArchiveRun: Record "BGB Project Archive Run";
        ArchiveFailure: Codeunit "BGB Archive Failure";
        CustomerNo: Code[20];
        Prefix: Code[12];
        TopNo: Code[20];
        ChildNo: Code[20];
        ErrorText: Text;
    begin
        // [SCENARIO] A failed Archive Hierarchy does not attach a later normal archive to the rolled-back run
        Prefix := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 12);
        CustomerNo := ProjectTestData.UpsertCustomer(CopyStr(Prefix + 'C', 1, 20), 'Failed hierarchy customer');
        TopNo := CopyStr(Prefix + 'T', 1, 20);
        ChildNo := CopyStr(Prefix + '1', 1, 20);
        ProjectTestData.CreateProject(TopJob, TopNo, 'Failed top', '', CustomerNo, '', '');
        ProjectTestData.CreateTaskWithBillableLine(TopJob, '100', 1, 10);
        ProjectTestData.CreateProject(ChildJob, ChildNo, 'Failed child', TopNo, CustomerNo, '', '');
        ProjectTestData.CreateTaskWithBillableLine(ChildJob, '100', 1, 10);
        ArchiveFailure.FailNextStore(ChildNo);
        BindSubscription(ArchiveFailure);
        // The failed archive rolls the write transaction back to the last commit. Keep the projects.
        Commit();
        // [WHEN] the hierarchy archive fails on the child, and the top project is then archived on its own
        asserterror ProjectArchiveMgt.ArchiveHierarchy(TopJob);
        ErrorText := GetLastErrorText();
        UnbindSubscription(ArchiveFailure);
        Assert.IsTrue(StrPos(ErrorText, ChildNo) > 0, ErrorText);
        StoreProject(TopJob);
        // [THEN] the top project has its own non-hierarchy run, and the child was not archived
        Snapshot.SetRange("Job No.", TopNo);
        Assert.AreEqual(1, Snapshot.Count(), 'one snapshot');
        Snapshot.FindFirst();
        ArchiveRun.Get(Snapshot."Run ID");
        Assert.IsFalse(ArchiveRun.Hierarchy, 'normal archive run');
        Assert.AreEqual(TopNo, ArchiveRun."Top Project No.", 'run project');
        Snapshot.SetRange("Run ID", Snapshot."Run ID");
        Assert.AreEqual(1, Snapshot.Count(), 'only the top project');
        Snapshot.SetRange("Run ID");
        Snapshot.SetRange("Job No.", ChildNo);
        Assert.IsTrue(Snapshot.IsEmpty(), 'child rolled back');
    end;

    [Test]
    procedure FailedRenameDoesNotMoveSnapshotsWhenTheArchiveIsDeleted()
    var
        Job: Record Job;
        LookupJob: Record Job;
        JobArchive: Record "Job Archive";
        Snapshot: Record "BGB Project Snapshot";
        ArchiveFailure: Codeunit "BGB Archive Failure";
        CustomerNo: Code[20];
        ProjectNo: Code[20];
        NewProjectNo: Code[20];
        ErrorText: Text;
    begin
        // [SCENARIO] A failed rename does not make a later archive delete move the snapshots
        CustomerNo := ProjectTestData.UpsertCustomer(CopyStr(NewNo() + 'C', 1, 20), 'Failed rename customer');
        ProjectNo := CopyStr(NewNo(), 1, 20);
        NewProjectNo := CopyStr(NewNo(), 1, 20);
        ProjectTestData.CreateProject(Job, ProjectNo, 'Fail rename', '', CustomerNo, '', '');
        ProjectTestData.CreateTaskWithBillableLine(Job, '100', 1, 10);
        StoreProject(Job);
        ArchiveFailure.FailNextRename(ProjectNo);
        BindSubscription(ArchiveFailure);
        // The failed rename rolls the write transaction back to the last commit. Keep the archived project.
        Commit();
        // [WHEN] the rename fails after the rename flag is set, and the archive is then deleted
        asserterror Job.Rename(NewProjectNo);
        ErrorText := GetLastErrorText();
        UnbindSubscription(ArchiveFailure);
        Assert.IsTrue(StrPos(ErrorText, ProjectNo) > 0, ErrorText);
        Assert.IsTrue(LookupJob.Get(ProjectNo), ErrorText);
        JobArchive.SetRange("No.", ProjectNo);
        JobArchive.FindFirst();
        JobArchive.Delete(true);
        // [THEN] the snapshot is deleted with the archive and was not moved to the failed target
        Snapshot.SetRange("Job No.", ProjectNo);
        Assert.IsTrue(Snapshot.IsEmpty(), 'snapshot deleted');
        Snapshot.SetRange("Job No.", NewProjectNo);
        Assert.IsTrue(Snapshot.IsEmpty(), 'not moved');
        JobArchive.SetRange("No.", NewProjectNo);
        Assert.IsTrue(JobArchive.IsEmpty(), 'archive not renamed');
    end;

    [Test]
    procedure FailedDeleteDoesNotMarkTheNextArchive()
    var
        Job: Record Job;
        LookupJob: Record Job;
        JobsSetup: Record "Jobs Setup";
        Snapshot: Record "BGB Project Snapshot";
        PreviousOption: Enum "Job Archive Option";
        CustomerNo: Code[20];
        ProjectNo: Code[20];
        ErrorText: Text;
    begin
        // [SCENARIO] A delete that fails because ledger entries exist does not mark a later archive as during project delete
        JobsSetup.Get();
        PreviousOption := JobsSetup."Archive Jobs";
        CustomerNo := ProjectTestData.UpsertCustomer(CopyStr(NewNo() + 'C', 1, 20), 'Failed delete customer');
        ProjectNo := CopyStr(NewNo(), 1, 20);
        ProjectTestData.CreateProject(Job, ProjectNo, 'Fail delete', '', CustomerNo, '', '');
        ProjectTestData.CreateTaskWithBillableLine(Job, '100', 1, 10);
        InsertLedger(ProjectNo, '100', "Job Journal Line Entry Type"::Usage, "Job Journal Line Type"::Resource, 5, 8);
        Job.SetHideValidationDialog(true);
        // The failed delete rolls the write transaction back to the last commit. Keep the project and its ledger entries.
        Commit();
        // [WHEN] the delete fails, and a status change then archives the project
        asserterror Job.Delete(true);
        ErrorText := GetLastErrorText();
        Assert.IsTrue(StrPos(ErrorText, 'ledger') > 0, ErrorText);
        Assert.IsTrue(LookupJob.Get(ProjectNo), ErrorText);
        Job.Get(ProjectNo);
        JobsSetup.Get();
        JobsSetup."Archive Jobs" := JobsSetup."Archive Jobs"::Always;
        JobsSetup.Modify(false);
        Job.SetHideValidationDialog(true);
        Job.Validate(Status, Job.Status::Planning);
        Job.Modify(true);
        // [THEN] the snapshot exists and is not marked as taken during project delete
        Snapshot.SetRange("Job No.", ProjectNo);
        Assert.IsTrue(Snapshot.FindFirst(), 'snapshot');
        Assert.IsFalse(Snapshot."During Project Delete", 'not during delete');
        JobsSetup.Get();
        JobsSetup."Archive Jobs" := PreviousOption;
        JobsSetup.Modify(false);
    end;

    [Test]
    procedure JobQueueArchivesEachOpenTopLevelHierarchy()
    var
        Job: Record Job;
        JobsSetup: Record "Jobs Setup";
        Snapshot: Record "BGB Project Snapshot";
        JobQueueEntry: Record "Job Queue Entry";
        PreviousOption: Enum "Job Archive Option";
        CustomerNo: Code[20];
        Prefix: Code[8];
        Top1: Code[20];
        ChildNo: Code[20];
        Top2: Code[20];
        CompletedNo: Code[20];
        OutsideNo: Code[20];
        EntriesBefore: Integer;
    begin
        // [SCENARIO] The job queue codeunit archives each open top-level hierarchy in the filter as one run and does not create a schedule
        JobsSetup.Get();
        PreviousOption := JobsSetup."Archive Jobs";
        SetArchiveOption("Job Archive Option"::Never);
        Prefix := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 8);
        CustomerNo := ProjectTestData.UpsertCustomer(CopyStr(Prefix + 'C', 1, 20), 'Job queue customer');
        Top1 := CopyStr(Prefix + 'A', 1, 20);
        ChildNo := CopyStr(Prefix + 'B', 1, 20);
        Top2 := CopyStr(Prefix + 'D', 1, 20);
        CompletedNo := CopyStr(Prefix + 'E', 1, 20);
        OutsideNo := CopyStr('Z' + Prefix, 1, 20);
        ProjectTestData.CreateProject(Job, Top1, 'Queue top 1', '', CustomerNo, '', '');
        ProjectTestData.CreateTaskWithBillableLine(Job, '100', 1, 10);
        ProjectTestData.CreateProject(Job, ChildNo, 'Queue child', Top1, CustomerNo, '', '');
        ProjectTestData.CreateTaskWithBillableLine(Job, '100', 1, 10);
        ProjectTestData.CreateProject(Job, Top2, 'Queue top 2', '', CustomerNo, '', '');
        ProjectTestData.CreateTaskWithBillableLine(Job, '100', 1, 10);
        ProjectTestData.CreateProject(Job, CompletedNo, 'Queue completed', '', CustomerNo, '', '');
        Job.Status := Job.Status::Quote;
        Job.Modify(false);
        ProjectTestData.CreateProject(Job, OutsideNo, 'Outside the filter', '', CustomerNo, '', '');
        JobQueueEntry.Init();
        JobQueueEntry."Parameter String" := Prefix + '*';
        EntriesBefore := JobQueueEntry.Count();
        // [WHEN] the codeunit runs for the prefix
        Codeunit.Run(Codeunit::"BGB Archive Hierarchies JQ", JobQueueEntry);
        // [THEN] each open top-level project has its own run, the child shares the first run, and no job queue entry was created
        Assert.AreEqual(EntriesBefore, JobQueueEntry.Count(), 'job queue entries');
        JobQueueEntry.SetRange("Object ID to Run", Codeunit::"BGB Archive Hierarchies JQ");
        Assert.IsTrue(JobQueueEntry.IsEmpty(), 'no schedule for this codeunit');
        Assert.AreEqual(1, CountRuns(Top1), 'top 1 runs');
        AssertSameRun(ChildNo, RunIdOf(Top1));
        Assert.AreEqual(1, CountRuns(Top2), 'top 2 runs');
        Assert.AreNotEqual(RunIdOf(Top1), RunIdOf(Top2), 'separate runs');
        Snapshot.SetRange("Job No.", CompletedNo);
        Assert.IsTrue(Snapshot.IsEmpty(), 'completed project');
        Snapshot.SetRange("Job No.", OutsideNo);
        Assert.IsTrue(Snapshot.IsEmpty(), 'outside the filter');
        SetArchiveOption(PreviousOption);
        // The job queue commits each hierarchy, which also commits the Jobs Setup change above.
        Commit();
    end;

    [Test]
    procedure JobQueueKeepsEarlierHierarchyWhenALaterOneFails()
    var
        Job: Record Job;
        Snapshot: Record "BGB Project Snapshot";
        JobQueueEntry: Record "Job Queue Entry";
        ArchiveFailure: Codeunit "BGB Archive Failure";
        CustomerNo: Code[20];
        Prefix: Code[8];
        Top1: Code[20];
        Top2: Code[20];
        FailureText: Text;
        EntriesBefore: Integer;
    begin
        // [SCENARIO] The job queue commits each hierarchy, logs a failure, and still fails the entry
        Prefix := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 8);
        CustomerNo := ProjectTestData.UpsertCustomer(CopyStr(Prefix + 'C', 1, 20), 'Queue failure customer');
        Top1 := CopyStr(Prefix + 'A', 1, 20);
        Top2 := CopyStr(Prefix + 'B', 1, 20);
        ProjectTestData.CreateProject(Job, Top1, 'Queue kept', '', CustomerNo, '', '');
        ProjectTestData.CreateTaskWithBillableLine(Job, '100', 1, 10);
        ProjectTestData.CreateProject(Job, Top2, 'Queue failed', '', CustomerNo, '', '');
        ProjectTestData.CreateTaskWithBillableLine(Job, '100', 1, 10);
        ArchiveFailure.FailNextStore(Top2);
        BindSubscription(ArchiveFailure);
        JobQueueEntry.Init();
        EntriesBefore := JobQueueEntry.Count();
        // [WHEN] the second hierarchy fails
        asserterror ProjectArchiveMgt.ArchiveOpenTopLevelHierarchies(Prefix + '*');
        FailureText := GetLastErrorText();
        UnbindSubscription(ArchiveFailure);
        // [THEN] the first hierarchy stays archived, the second does not, and the error names the failed project
        Assert.IsTrue(StrPos(FailureText, Top2) > 0, FailureText);
        Assert.AreEqual(EntriesBefore, JobQueueEntry.Count(), 'job queue entries');
        Assert.AreEqual(1, CountRuns(Top1), 'first hierarchy committed');
        Snapshot.SetRange("Job No.", Top2);
        Assert.IsTrue(Snapshot.IsEmpty(), 'second hierarchy rolled back');
    end;

    local procedure SetArchiveOption(ArchiveOption: Enum "Job Archive Option")
    var
        JobsSetup: Record "Jobs Setup";
    begin
        JobsSetup.Get();
        JobsSetup."Archive Jobs" := ArchiveOption;
        JobsSetup.Modify(false);
    end;

    local procedure AssertAmounts(Snapshot: Record "BGB Project Snapshot"; Cost: array[16] of Decimal; Price: array[16] of Decimal)
    begin
        Assert.AreEqual(Cost[1], Snapshot."Budget Cost Resource", 'budget cost resource');
        Assert.AreEqual(Cost[2], Snapshot."Budget Cost Item", 'budget cost item');
        Assert.AreEqual(Cost[3], Snapshot."Budget Cost G/L Acc.", 'budget cost g/l');
        Assert.AreEqual(Cost[4], Snapshot."Budget Cost Total", 'budget cost total');
        Assert.AreEqual(Cost[5], Snapshot."Usage Cost Resource", 'usage cost resource');
        Assert.AreEqual(Cost[6], Snapshot."Usage Cost Item", 'usage cost item');
        Assert.AreEqual(Cost[7], Snapshot."Usage Cost G/L Acc.", 'usage cost g/l');
        Assert.AreEqual(Cost[8], Snapshot."Usage Cost Total", 'usage cost total');
        Assert.AreEqual(Cost[13], Snapshot."Invoiced Cost Resource", 'invoiced cost resource');
        Assert.AreEqual(Cost[14], Snapshot."Invoiced Cost Item", 'invoiced cost item');
        Assert.AreEqual(Cost[15], Snapshot."Invoiced Cost G/L Acc.", 'invoiced cost g/l');
        Assert.AreEqual(Cost[16], Snapshot."Invoiced Cost Total", 'invoiced cost total');
        Assert.AreEqual(Price[5], Snapshot."Usage Price Resource", 'usage price resource');
        Assert.AreEqual(Price[8], Snapshot."Usage Price Total", 'usage price total');
        Assert.AreEqual(Price[16], Snapshot."Invoiced Price Total", 'invoiced price total');
    end;

    local procedure AssertSameRun(ProjectNo: Code[20]; RunId: Guid)
    var
        Snapshot: Record "BGB Project Snapshot";
    begin
        Snapshot.SetRange("Job No.", ProjectNo);
        Snapshot.FindFirst();
        Assert.AreEqual(RunId, Snapshot."Run ID", 'run of ' + ProjectNo);
    end;

    local procedure RunIdOf(ProjectNo: Code[20]): Guid
    var
        Snapshot: Record "BGB Project Snapshot";
    begin
        Snapshot.SetRange("Job No.", ProjectNo);
        Snapshot.FindFirst();
        exit(Snapshot."Run ID");
    end;

    local procedure CountRuns(ProjectNo: Code[20]): Integer
    var
        Snapshot: Record "BGB Project Snapshot";
    begin
        Snapshot.SetRange("Job No.", ProjectNo);
        exit(Snapshot.Count());
    end;

    local procedure SumBillablePrice(RunId: Guid): Decimal
    var
        Snapshot: Record "BGB Project Snapshot";
        Total: Decimal;
    begin
        Snapshot.SetRange("Run ID", RunId);
        if Snapshot.FindSet() then
            repeat
                Total += Snapshot."Billable Price Total";
            until Snapshot.Next() = 0;
        exit(Total);
    end;

    local procedure StoreProject(var Job: Record Job)
    var
        JobArchiveManagement: Codeunit "Job Archive Management";
    begin
        JobArchiveManagement.StoreJob(Job, false);
    end;

    local procedure CreateTypedLine(Job: Record Job; JobTaskNo: Code[20]; LineType: Enum "Job Planning Line Type"; No: Code[20]; Quantity: Decimal; UnitCost: Decimal; UnitPrice: Decimal)
    var
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        LineNo: Integer;
    begin
        if not JobTask.Get(Job."No.", JobTaskNo) then begin
            JobTask.Init();
            JobTask.Validate("Job No.", Job."No.");
            JobTask.Validate("Job Task No.", JobTaskNo);
            JobTask.Insert(true);
            JobTask.Validate("Job Task Type", JobTask."Job Task Type"::Posting);
            JobTask.Validate(Description, Job.Description);
            JobTask.Modify(true);
        end;
        JobPlanningLine.SetRange("Job No.", Job."No.");
        JobPlanningLine.SetRange("Job Task No.", JobTaskNo);
        if JobPlanningLine.FindLast() then
            LineNo := JobPlanningLine."Line No." + 10000
        else
            LineNo := 10000;
        JobPlanningLine.Init();
        JobPlanningLine.Validate("Job No.", Job."No.");
        JobPlanningLine.Validate("Job Task No.", JobTaskNo);
        JobPlanningLine.Validate("Line No.", LineNo);
        JobPlanningLine.Insert(true);
        JobPlanningLine.Validate("Planning Date", WorkDate());
        JobPlanningLine.Validate("Line Type", JobPlanningLine."Line Type"::"Both Budget and Billable");
        JobPlanningLine.Validate(Type, LineType);
        JobPlanningLine.Validate("No.", No);
        JobPlanningLine.Validate(Quantity, Quantity);
        if LineType = LineType::"G/L Account" then
            JobPlanningLine.Validate("Unit Cost", UnitCost);
        JobPlanningLine.Validate("Unit Price", UnitPrice);
        JobPlanningLine.Modify(true);
    end;

    local procedure InsertUsageAndSale(ProjectNo: Code[20]; JobTaskNo: Code[20])
    begin
        // Same figures Job Calculate Statistics reads: usage as stored, sale sign-reversed into invoiced.
        InsertLedger(ProjectNo, JobTaskNo, "Job Journal Line Entry Type"::Usage, "Job Journal Line Type"::Resource, 30, 50);
        InsertLedger(ProjectNo, JobTaskNo, "Job Journal Line Entry Type"::Usage, "Job Journal Line Type"::"G/L Account", 6, 9);
        InsertLedger(ProjectNo, JobTaskNo, "Job Journal Line Entry Type"::Sale, "Job Journal Line Type"::Resource, -12, -40);
        InsertLedger(ProjectNo, JobTaskNo, "Job Journal Line Entry Type"::Sale, "Job Journal Line Type"::"G/L Account", -4, -7);
    end;

    local procedure InsertLedger(ProjectNo: Code[20]; JobTaskNo: Code[20]; EntryType: Enum "Job Journal Line Entry Type"; LineType: Enum "Job Journal Line Type"; Cost: Decimal; Price: Decimal)
    var
        JobLedgerEntry: Record "Job Ledger Entry";
    begin
        JobLedgerEntry.LockTable();
        if JobLedgerEntry.FindLast() then
            JobLedgerEntry."Entry No." += 1
        else
            JobLedgerEntry."Entry No." := 1;
        JobLedgerEntry."Job No." := ProjectNo;
        JobLedgerEntry."Job Task No." := JobTaskNo;
        JobLedgerEntry."Entry Type" := EntryType;
        JobLedgerEntry.Type := LineType;
        JobLedgerEntry."Total Cost (LCY)" := Cost;
        JobLedgerEntry."Line Amount (LCY)" := Price;
        JobLedgerEntry.Insert(false);
    end;

    local procedure CreateReportedProject(): Code[20]
    var
        Job: Record Job;
        CustomerNo: Code[20];
        ProjectNo: Code[20];
    begin
        CustomerNo := ProjectTestData.UpsertCustomer(CopyStr(NewNo() + 'C', 1, 20), 'Report customer');
        ProjectNo := CopyStr(NewNo(), 1, 20);
        ProjectTestData.CreateProject(Job, ProjectNo, 'Report project', '', CustomerNo, '', '');
        ProjectTestData.CreateTaskWithBillableLine(Job, '100', 1, 20);
        StoreProject(Job);
        exit(ProjectNo);
    end;

    local procedure FindResourceNo(): Code[20]
    var
        Resource: Record Resource;
    begin
        Resource.SetRange(Type, Resource.Type::Person);
        Resource.SetFilter("Gen. Prod. Posting Group", '<>%1', '');
        Resource.FindSet();
        repeat
            if not Resource.Blocked then
                exit(Resource."No.");
        until Resource.Next() = 0;
        Error(NothingFoundErr, Resource.TableCaption());
    end;

    local procedure FindGLAccountNo(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.SetRange("Account Type", GLAccount."Account Type"::Posting);
        GLAccount.SetFilter("Gen. Prod. Posting Group", '<>%1', '');
        GLAccount.FindSet();
        repeat
            if GLAccount."Direct Posting" and (not GLAccount.Blocked) then
                exit(GLAccount."No.");
        until GLAccount.Next() = 0;
        Error(NothingFoundErr, GLAccount.TableCaption());
    end;

    local procedure NewNo(): Code[20]
    begin
        exit(CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 12));
    end;
}
