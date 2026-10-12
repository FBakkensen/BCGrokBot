namespace FlemmingBakkensen.BCGrokBot.ProjectHierarchy;

using Microsoft.Projects.Project.Job;

/// <summary>
/// Project (Job) hierarchy: parent validation, descendant lookup and hierarchy totals.
/// A project is top-level when its Parent Project No. is blank. Depth is unlimited.
/// </summary>
codeunit 50104 "BGB Project Hierarchy Mgt."
{
    Access = Public;
    Permissions = tabledata Job = r;

    var
        SelfParentErr: Label 'Project %1 cannot be its own parent project.', Comment = '%1 = project number';
        CycleErr: Label 'Project %1 cannot have parent project %2, because %2 is already a subproject of %1.', Comment = '%1 = project number, %2 = parent project number';
        InHierarchyErr: Label 'Project %1 is part of a project hierarchy. Use the Create Hierarchy Sales Invoices action on top-level project %2 instead.', Comment = '%1 = project number, %2 = top-level project number';
        HasSubprojectsErr: Label 'You cannot delete project %1, because it has subprojects. Remove or move its subprojects first.', Comment = '%1 = project number';
        NotTopLevelErr: Label 'Project %1 has parent project %2. Hierarchy invoicing can only be run on a top-level project.', Comment = '%1 = project number, %2 = parent project number';
        CorruptHierarchyErr: Label 'The project hierarchy above project %1 is too deep or contains a loop.', Comment = '%1 = project number';
        MaxDepth: Integer;

    /// <summary>
    /// Checks that ParentProjectNo can be the parent of ProjectNo: not the project itself and not one of its descendants.
    /// </summary>
    /// <param name="ProjectNo">The project that gets the parent.</param>
    /// <param name="ParentProjectNo">The proposed parent. Blank is always allowed.</param>
    procedure CheckParent(ProjectNo: Code[20]; ParentProjectNo: Code[20])
    var
        Job: Record Job;
        CurrentNo: Code[20];
        Steps: Integer;
    begin
        if ParentProjectNo = '' then
            exit;
        if ParentProjectNo = ProjectNo then
            Error(SelfParentErr, ProjectNo);
        Job.SetLoadFields("BGB Parent Project No.");
        CurrentNo := ParentProjectNo;
        while CurrentNo <> '' do begin
            if CurrentNo = ProjectNo then
                Error(CycleErr, ProjectNo, ParentProjectNo);
            Steps += 1;
            if Steps > GetMaxDepth() then
                Error(CorruptHierarchyErr, ParentProjectNo);
            if not Job.Get(CurrentNo) then
                exit;
            CurrentNo := Job."BGB Parent Project No.";
        end;
    end;

    /// <summary>
    /// Returns whether the project has at least one subproject.
    /// </summary>
    /// <param name="ProjectNo">The project number.</param>
    /// <returns>True if another project has this project as parent.</returns>
    procedure HasSubprojects(ProjectNo: Code[20]): Boolean
    var
        Job: Record Job;
    begin
        if ProjectNo = '' then
            exit(false);
        Job.SetRange("BGB Parent Project No.", ProjectNo);
        exit(not Job.IsEmpty());
    end;

    /// <summary>
    /// Returns whether the project belongs to a hierarchy (has a parent or has subprojects).
    /// </summary>
    /// <param name="ProjectNo">The project number.</param>
    /// <returns>True if the project has a parent or subprojects.</returns>
    procedure IsInHierarchy(ProjectNo: Code[20]): Boolean
    var
        Job: Record Job;
    begin
        Job.SetLoadFields("BGB Parent Project No.");
        if not Job.Get(ProjectNo) then
            exit(false);
        exit((Job."BGB Parent Project No." <> '') or HasSubprojects(ProjectNo));
    end;

    /// <summary>
    /// Returns the top-level project above the project (the project itself when it has no parent).
    /// </summary>
    /// <param name="ProjectNo">The project number.</param>
    /// <returns>The top-level project number.</returns>
    procedure GetTopLevelProjectNo(ProjectNo: Code[20]): Code[20]
    var
        Job: Record Job;
        CurrentNo: Code[20];
        Steps: Integer;
    begin
        Job.SetLoadFields("BGB Parent Project No.");
        CurrentNo := ProjectNo;
        while Job.Get(CurrentNo) and (Job."BGB Parent Project No." <> '') do begin
            Steps += 1;
            if Steps > GetMaxDepth() then
                Error(CorruptHierarchyErr, ProjectNo);
            CurrentNo := Job."BGB Parent Project No.";
        end;
        exit(CurrentNo);
    end;

    /// <summary>
    /// Returns the project and all its descendants, breadth first: the project itself first, then its
    /// subprojects, then theirs. Within a level, subprojects come in project number order.
    /// </summary>
    /// <param name="ProjectNo">The project number.</param>
    /// <returns>The project numbers in breadth-first order.</returns>
    procedure GetProjectAndDescendants(ProjectNo: Code[20]) ProjectNos: List of [Code[20]]
    var
        Job: Record Job;
        Index: Integer;
    begin
        ProjectNos.Add(ProjectNo);
        Job.SetCurrentKey("BGB Parent Project No.");
        Job.SetLoadFields("No.");
        Index := 1;
        while Index <= ProjectNos.Count() do begin
            Job.SetRange("BGB Parent Project No.", ProjectNos.Get(Index));
            if Job.FindSet() then
                repeat
                    if ProjectNos.Contains(Job."No.") then
                        Error(CorruptHierarchyErr, Job."No.");
                    ProjectNos.Add(Job."No.");
                until Job.Next() = 0;
            Index += 1;
        end;
    end;

    /// <summary>
    /// Returns the number of descendants (all levels) of the project.
    /// </summary>
    /// <param name="ProjectNo">The project number.</param>
    /// <returns>The number of subprojects at any depth.</returns>
    procedure CountDescendants(ProjectNo: Code[20]): Integer
    begin
        exit(GetProjectAndDescendants(ProjectNo).Count() - 1);
    end;

    /// <summary>
    /// Raises an error when standard project invoicing is used on a project that belongs to a hierarchy.
    /// </summary>
    /// <param name="ProjectNo">The project number.</param>
    procedure CheckStandardInvoicingAllowed(ProjectNo: Code[20])
    begin
        if IsInHierarchy(ProjectNo) then
            Error(InHierarchyErr, ProjectNo, GetTopLevelProjectNo(ProjectNo));
    end;

    /// <summary>
    /// Raises an error when the project has subprojects (used before deleting a project).
    /// </summary>
    /// <param name="ProjectNo">The project number.</param>
    procedure CheckCanDelete(ProjectNo: Code[20])
    begin
        if HasSubprojects(ProjectNo) then
            Error(HasSubprojectsErr, ProjectNo);
    end;

    /// <summary>
    /// Raises an error when the project is not top-level.
    /// </summary>
    /// <param name="Job">The project.</param>
    procedure CheckTopLevel(Job: Record Job)
    begin
        if Job."BGB Parent Project No." <> '' then
            Error(NotTopLevelErr, Job."No.", Job."BGB Parent Project No.");
    end;

    /// <summary>
    /// Calculates the standard project statistics (same figures as the Project Details FactBox, in LCY)
    /// summed over the project and all its descendants. The posting and planning date filters of the
    /// given project record are applied to every project.
    /// </summary>
    /// <param name="Job">The project; its Posting Date Filter and Planning Date Filter are used.</param>
    /// <param name="CostAmounts">Returns the summed LCY cost amounts (same layout as Job Calculate Statistics).</param>
    /// <param name="PriceAmounts">Returns the summed LCY price amounts (same layout as Job Calculate Statistics).</param>
    procedure CalcHierarchyAmounts(var Job: Record Job; var CostAmounts: array[16] of Decimal; var PriceAmounts: array[16] of Decimal)
    var
        ProjectJob: Record Job;
        JobCalculateStatistics: Codeunit "Job Calculate Statistics";
        ProjectCostAmounts: array[16] of Decimal;
        ProjectPriceAmounts: array[16] of Decimal;
        ProjectNo: Code[20];
        i: Integer;
    begin
        Clear(CostAmounts);
        Clear(PriceAmounts);
        foreach ProjectNo in GetProjectAndDescendants(Job."No.") do
            if ProjectJob.Get(ProjectNo) then begin
                ProjectJob.SetFilter("Posting Date Filter", Job.GetFilter("Posting Date Filter"));
                ProjectJob.SetFilter("Planning Date Filter", Job.GetFilter("Planning Date Filter"));
                Clear(JobCalculateStatistics);
                JobCalculateStatistics.JobCalculateCommonFilters(ProjectJob);
                JobCalculateStatistics.CalculateAmounts();
                JobCalculateStatistics.GetLCYCostAmounts(ProjectCostAmounts);
                JobCalculateStatistics.GetLCYPriceAmounts(ProjectPriceAmounts);
                for i := 1 to ArrayLen(CostAmounts) do begin
                    CostAmounts[i] += ProjectCostAmounts[i];
                    PriceAmounts[i] += ProjectPriceAmounts[i];
                end;
            end;
    end;

    local procedure GetMaxDepth(): Integer
    begin
        if MaxDepth = 0 then
            MaxDepth := 10000;
        exit(MaxDepth);
    end;
}
