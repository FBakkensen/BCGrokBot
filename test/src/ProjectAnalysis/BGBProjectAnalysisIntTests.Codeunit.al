namespace FlemmingBakkensen.BCGrokBot.Test.ProjectAnalysis;

using FlemmingBakkensen.BCGrokBot.ProjectAnalysis;
using FlemmingBakkensen.BCGrokBot.Test.ProjectHierarchy;
using Microsoft.Projects.Project.Job;
using System.TestLibraries.Utilities;
using System.Utilities;

/// <summary>
/// Container-only: Project Hierarchy Analysis on CRONUS data (statistics, hierarchy totals, Excel and XML output).
/// </summary>
codeunit 50161 "BGB Project Analysis Int Tests"
{
    Subtype = Test;
    Access = Internal;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        ProjectTestData: Codeunit "BGB Project Test Data";
        ProjectAnalysisMgt: Codeunit "BGB Project Analysis Mgt.";
        TopNo, ChildNo, GrandChildNo : Code[20];

    [Test]
    procedure OwnAmountsAndHierarchyTotals()
    var
        JobFilter: Record Job;
        TempProjectAnalysisBuffer: Record "BGB Project Analysis Buffer" temporary;
    begin
        // [SCENARIO] Each row has the project's own statistics; hierarchy totals add all subprojects
        // [GIVEN] TOP (billable 100) <- CHILD (200) <- GRANDCHILD (300)
        CreateTree();
        // [WHEN] the analysis is built for TOP with amounts
        JobFilter.SetRange("No.", TopNo);
        ProjectAnalysisMgt.BuildAnalysis(JobFilter, TempProjectAnalysisBuffer, true);
        // [THEN]
        Assert.RecordCount(TempProjectAnalysisBuffer, 3);
        VerifyAmounts(TempProjectAnalysisBuffer, TopNo, 100, 600);
        VerifyAmounts(TempProjectAnalysisBuffer, ChildNo, 200, 500);
        VerifyAmounts(TempProjectAnalysisBuffer, GrandChildNo, 300, 300);
    end;

    [Test]
    procedure ReportRendersExcelAndDataset()
    var
        Job: Record Job;
        TempBlob: Codeunit "Temp Blob";
        RecRef: RecordRef;
        OutStr: OutStream;
        InStr: InStream;
        DatasetXml: Text;
        Line: Text;
    begin
        // [SCENARIO] The report runs for a project tree and produces an Excel file and a dataset with every project
        CreateTree();
        Job.SetRange("No.", TopNo);
        RecRef.GetTable(Job);
        // [WHEN] the report is saved as Excel
        TempBlob.CreateOutStream(OutStr);
        Report.SaveAs(Report::"BGB Project Hierarchy Analysis", '', ReportFormat::Excel, OutStr, RecRef);
        // [THEN] an xlsx (zip) is produced
        Assert.IsTrue(TempBlob.Length() > 1000, 'Excel output');
        // [WHEN] the dataset is saved as XML
        Clear(TempBlob);
        TempBlob.CreateOutStream(OutStr);
        Report.SaveAs(Report::"BGB Project Hierarchy Analysis", '', ReportFormat::Xml, OutStr, RecRef);
        TempBlob.CreateInStream(InStr);
        while not InStr.EOS() do begin
            InStr.ReadText(Line);
            DatasetXml += Line;
        end;
        // [THEN] all three projects are in the dataset
        Assert.IsTrue(DatasetXml.Contains(TopNo), 'TOP in dataset');
        Assert.IsTrue(DatasetXml.Contains(ChildNo), 'CHILD in dataset');
        Assert.IsTrue(DatasetXml.Contains(GrandChildNo), 'GRANDCHILD in dataset');
        Assert.IsTrue(DatasetXml.Contains('HierarchyBillablePriceTotal'), 'hierarchy total column');
    end;

    local procedure CreateTree()
    var
        Job: Record Job;
        CustomerNo: Code[20];
        Prefix: Text;
    begin
        Prefix := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 12);
        CustomerNo := ProjectTestData.UpsertCustomer(CopyStr(Prefix + '-A', 1, 20), 'Analysis test customer');
        TopNo := CopyStr(Prefix + '-T', 1, 20);
        ChildNo := CopyStr(Prefix + '-C', 1, 20);
        GrandChildNo := CopyStr(Prefix + '-G', 1, 20);
        ProjectTestData.CreateProject(Job, TopNo, 'Top', '', CustomerNo, '', '');
        ProjectTestData.CreateTaskWithBillableLine(Job, '100', 1, 100);
        ProjectTestData.CreateProject(Job, ChildNo, 'Child', TopNo, CustomerNo, '', '');
        ProjectTestData.CreateTaskWithBillableLine(Job, '100', 2, 100);
        ProjectTestData.CreateProject(Job, GrandChildNo, 'Grandchild', ChildNo, CustomerNo, '', '');
        ProjectTestData.CreateTaskWithBillableLine(Job, '100', 3, 100);
    end;

    local procedure VerifyAmounts(var TempProjectAnalysisBuffer: Record "BGB Project Analysis Buffer" temporary; ProjectNo: Code[20]; OwnBillable: Decimal; HierarchyBillable: Decimal)
    begin
        TempProjectAnalysisBuffer.SetRange("Project No.", ProjectNo);
        TempProjectAnalysisBuffer.FindFirst();
        Assert.AreEqual(OwnBillable, TempProjectAnalysisBuffer."Billable Price Resource", 'own billable resource ' + ProjectNo);
        Assert.AreEqual(OwnBillable, TempProjectAnalysisBuffer."Billable Price Total", 'own billable total ' + ProjectNo);
        Assert.AreEqual(HierarchyBillable, TempProjectAnalysisBuffer."Hier. Billable Price", 'hierarchy billable ' + ProjectNo);
        TempProjectAnalysisBuffer.SetRange("Project No.");
    end;
}
