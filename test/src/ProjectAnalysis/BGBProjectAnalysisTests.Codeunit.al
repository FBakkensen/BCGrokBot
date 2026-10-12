namespace FlemmingBakkensen.BCGrokBot.Test.ProjectAnalysis;

using FlemmingBakkensen.BCGrokBot.ProjectAnalysis;
using Microsoft.Projects.Project.Job;
using System.TestLibraries.Utilities;

codeunit 50160 "BGB Project Analysis Tests"
{
    Subtype = Test;
    Access = Internal;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        ProjectAnalysisMgt: Codeunit "BGB Project Analysis Mgt.";

    [Test]
    procedure RowsAreInTreeOrderWithLevelAndSortKey()
    var
        Top, ChildA, ChildB, GrandChild : Record Job;
        JobFilter: Record Job;
        TempProjectAnalysisBuffer: Record "BGB Project Analysis Buffer" temporary;
    begin
        // [SCENARIO] One row per project, depth first, with level, sort key and top-level project
        // [GIVEN] TOP <- A <- G and TOP <- B (A sorts before B)
        CreateProject(Top, '', '');
        CreateProject(ChildA, Top."No.", 'A');
        CreateProject(GrandChild, ChildA."No.", 'G');
        CreateProject(ChildB, Top."No.", 'B');
        // [WHEN] the analysis is built for TOP
        JobFilter.SetRange("No.", Top."No.");
        ProjectAnalysisMgt.BuildAnalysis(JobFilter, TempProjectAnalysisBuffer, false);
        // [THEN] TOP, A, G, B
        Assert.RecordCount(TempProjectAnalysisBuffer, 4);
        VerifyRow(TempProjectAnalysisBuffer, 1, Top."No.", Top."No.", '', 0, '0001');
        VerifyRow(TempProjectAnalysisBuffer, 2, ChildA."No.", Top."No.", Top."No.", 1, '0001.0001');
        VerifyRow(TempProjectAnalysisBuffer, 3, GrandChild."No.", Top."No.", ChildA."No.", 2, '0001.0001.0001');
        VerifyRow(TempProjectAnalysisBuffer, 4, ChildB."No.", Top."No.", Top."No.", 1, '0001.0002');
        TempProjectAnalysisBuffer.Get(1);
        Assert.AreEqual(3, TempProjectAnalysisBuffer."Subproject Count", 'subproject count of TOP');
    end;

    [Test]
    procedure SubprojectSelectionIncludesItsSubtreeOnly()
    var
        Top, ChildA, ChildB, GrandChild : Record Job;
        JobFilter: Record Job;
        TempProjectAnalysisBuffer: Record "BGB Project Analysis Buffer" temporary;
    begin
        // [SCENARIO] Selecting a subproject includes it and its subprojects, with levels relative to the real top
        CreateProject(Top, '', '');
        CreateProject(ChildA, Top."No.", 'A');
        CreateProject(GrandChild, ChildA."No.", 'G');
        CreateProject(ChildB, Top."No.", 'B');
        JobFilter.SetRange("No.", ChildA."No.");
        ProjectAnalysisMgt.BuildAnalysis(JobFilter, TempProjectAnalysisBuffer, false);
        Assert.RecordCount(TempProjectAnalysisBuffer, 2);
        VerifyRow(TempProjectAnalysisBuffer, 1, ChildA."No.", Top."No.", Top."No.", 1, '0001');
        VerifyRow(TempProjectAnalysisBuffer, 2, GrandChild."No.", Top."No.", ChildA."No.", 2, '0001.0001');
    end;

    [Test]
    procedure ProjectsInSelectedTreesAreNotRepeated()
    var
        Top, ChildA : Record Job;
        JobFilter: Record Job;
        TempProjectAnalysisBuffer: Record "BGB Project Analysis Buffer" temporary;
    begin
        // [SCENARIO] Selecting a parent and its child lists the child once
        CreateProject(Top, '', '');
        CreateProject(ChildA, Top."No.", 'A');
        JobFilter.SetFilter("No.", '%1|%2', Top."No.", ChildA."No.");
        ProjectAnalysisMgt.BuildAnalysis(JobFilter, TempProjectAnalysisBuffer, false);
        Assert.RecordCount(TempProjectAnalysisBuffer, 2);
    end;

    [Test]
    procedure DefaultSelectionIsTopLevelProjects()
    var
        Top, ChildA : Record Job;
        JobFilter: Record Job;
        TempProjectAnalysisBuffer: Record "BGB Project Analysis Buffer" temporary;
    begin
        // [SCENARIO] Without a project filter every top-level project is a root; subprojects appear under their root only
        CreateProject(Top, '', '');
        CreateProject(ChildA, Top."No.", 'A');
        ProjectAnalysisMgt.BuildAnalysis(JobFilter, TempProjectAnalysisBuffer, false);
        TempProjectAnalysisBuffer.SetRange("Project No.", ChildA."No.");
        Assert.RecordCount(TempProjectAnalysisBuffer, 1);
        TempProjectAnalysisBuffer.FindFirst();
        Assert.AreEqual(1, TempProjectAnalysisBuffer.Level, 'child level');
        Assert.AreEqual(Top."No.", TempProjectAnalysisBuffer."Top-Level Project No.", 'child top-level project');
    end;

    [Test]
    procedure MarginPercent()
    begin
        // [SCENARIO] Margin is profit in percent of price, 0 without price
        Assert.AreEqual(25, ProjectAnalysisMgt.CalcMarginPct(200, 150), 'margin');
        Assert.AreEqual(0, ProjectAnalysisMgt.CalcMarginPct(0, 150), 'no price');
        Assert.AreEqual(-50, ProjectAnalysisMgt.CalcMarginPct(100, 150), 'loss');
    end;

    local procedure VerifyRow(var TempProjectAnalysisBuffer: Record "BGB Project Analysis Buffer" temporary; EntryNo: Integer; ProjectNo: Code[20]; TopNo: Code[20]; ParentNo: Code[20]; Level: Integer; SortKey: Text)
    begin
        TempProjectAnalysisBuffer.Get(EntryNo);
        Assert.AreEqual(ProjectNo, TempProjectAnalysisBuffer."Project No.", 'project no. of row ' + Format(EntryNo));
        Assert.AreEqual(TopNo, TempProjectAnalysisBuffer."Top-Level Project No.", 'top-level project of row ' + Format(EntryNo));
        Assert.AreEqual(ParentNo, TempProjectAnalysisBuffer."Parent Project No.", 'parent of row ' + Format(EntryNo));
        Assert.AreEqual(Level, TempProjectAnalysisBuffer.Level, 'level of row ' + Format(EntryNo));
        Assert.AreEqual(SortKey, TempProjectAnalysisBuffer."Sort Key", 'sort key of row ' + Format(EntryNo));
    end;

    local procedure CreateProject(var Job: Record Job; ParentProjectNo: Code[20]; Suffix: Text)
    begin
        // Children of one parent sort by project no.: same prefix as the parent plus a suffix keeps the order deterministic
        Job.Init();
        if ParentProjectNo = '' then
            Job."No." := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 12)
        else
            Job."No." := CopyStr(ParentProjectNo + Suffix, 1, MaxStrLen(Job."No."));
        Job.Description := Job."No.";
        Job."BGB Parent Project No." := ParentProjectNo;
        Job.Insert(false);
    end;
}
