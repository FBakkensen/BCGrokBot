namespace FlemmingBakkensen.BCGrokBot.ProjectVersion;

using Microsoft.Projects.Project.Job;

/// <summary>
/// One archived project: the 32 LCY figures from Job Calculate Statistics, profit and margin,
/// parent project, level and hierarchy rollup totals, tied to an archive run and a project archive version.
/// </summary>
table 50106 "BGB Project Snapshot"
{
    Caption = 'Project Snapshot';
    Access = Public;
    DataClassification = CustomerContent;
    AllowInCustomizations = Never;
    InherentEntitlements = RIMD;
    InherentPermissions = RIMD;

    fields
    {
        field(1; "Job No."; Code[20])
        {
            Caption = 'Project No.';
            ToolTip = 'Specifies the project this snapshot was taken for.';
            TableRelation = Job;
        }
        field(2; "Version No."; Integer)
        {
            Caption = 'Version No.';
            ToolTip = 'Specifies the project archive version this snapshot belongs to.';
        }
        field(3; "Run ID"; Guid)
        {
            Caption = 'Archive Run ID';
            ToolTip = 'Specifies the archive run. A hierarchy archive shares one run across the top project and its subprojects.';
        }
        field(4; "Run At"; DateTime)
        {
            Caption = 'Run At';
            ToolTip = 'Specifies the date and time of the archive run.';
        }
        field(5; "User ID"; Code[50])
        {
            Caption = 'User ID';
            ToolTip = 'Specifies the user who archived the project.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(6; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies the project description at the time of the archive.';
        }
        field(7; "Parent Project No."; Code[20])
        {
            Caption = 'Parent Project No.';
            ToolTip = 'Specifies the parent project at the time of the archive. Standard project archive does not store this.';
        }
        field(8; Level; Integer)
        {
            Caption = 'Level';
            ToolTip = 'Specifies the depth in the hierarchy at the time of the archive. A top-level project is level 0.';
        }
        field(9; "During Project Delete"; Boolean)
        {
            Caption = 'During Project Delete';
            ToolTip = 'Specifies that the snapshot was taken while the project was being deleted. Usage may be incomplete because project ledger entries can already have been moved.';
        }
        field(100; "Budget Cost Resource"; Decimal)
        {
            Caption = 'Budget Cost Resource';
            ToolTip = 'Specifies the cost (LCY) of budget (schedule) planning lines for resources on this project only, at the time of the archive.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(101; "Budget Cost Item"; Decimal)
        {
            Caption = 'Budget Cost Item';
            ToolTip = 'Specifies the cost (LCY) of budget (schedule) planning lines for items on this project only, at the time of the archive.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(102; "Budget Cost G/L Acc."; Decimal)
        {
            Caption = 'Budget Cost G/L Acc.';
            ToolTip = 'Specifies the cost (LCY) of budget (schedule) planning lines for G/L accounts on this project only, at the time of the archive.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(103; "Budget Cost Total"; Decimal)
        {
            Caption = 'Budget Cost Total';
            ToolTip = 'Specifies the cost (LCY) of budget (schedule) planning lines for all types on this project only, at the time of the archive.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(104; "Usage Cost Resource"; Decimal)
        {
            Caption = 'Usage Cost Resource';
            ToolTip = 'Specifies the cost (LCY) of posted usage for resources on this project only, at the time of the archive.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(105; "Usage Cost Item"; Decimal)
        {
            Caption = 'Usage Cost Item';
            ToolTip = 'Specifies the cost (LCY) of posted usage for items on this project only, at the time of the archive.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(106; "Usage Cost G/L Acc."; Decimal)
        {
            Caption = 'Usage Cost G/L Acc.';
            ToolTip = 'Specifies the cost (LCY) of posted usage for G/L accounts on this project only, at the time of the archive.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(107; "Usage Cost Total"; Decimal)
        {
            Caption = 'Usage Cost Total';
            ToolTip = 'Specifies the cost (LCY) of posted usage for all types on this project only, at the time of the archive.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(108; "Billable Cost Resource"; Decimal)
        {
            Caption = 'Billable Cost Resource';
            ToolTip = 'Specifies the cost (LCY) of billable (contract) planning lines for resources on this project only, at the time of the archive.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(109; "Billable Cost Item"; Decimal)
        {
            Caption = 'Billable Cost Item';
            ToolTip = 'Specifies the cost (LCY) of billable (contract) planning lines for items on this project only, at the time of the archive.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(110; "Billable Cost G/L Acc."; Decimal)
        {
            Caption = 'Billable Cost G/L Acc.';
            ToolTip = 'Specifies the cost (LCY) of billable (contract) planning lines for G/L accounts on this project only, at the time of the archive.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(111; "Billable Cost Total"; Decimal)
        {
            Caption = 'Billable Cost Total';
            ToolTip = 'Specifies the cost (LCY) of billable (contract) planning lines for all types on this project only, at the time of the archive.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(112; "Invoiced Cost Resource"; Decimal)
        {
            Caption = 'Invoiced Cost Resource';
            ToolTip = 'Specifies the cost (LCY) of invoiced sales for resources on this project only, at the time of the archive.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(113; "Invoiced Cost Item"; Decimal)
        {
            Caption = 'Invoiced Cost Item';
            ToolTip = 'Specifies the cost (LCY) of invoiced sales for items on this project only, at the time of the archive.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(114; "Invoiced Cost G/L Acc."; Decimal)
        {
            Caption = 'Invoiced Cost G/L Acc.';
            ToolTip = 'Specifies the cost (LCY) of invoiced sales for G/L accounts on this project only, at the time of the archive.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(115; "Invoiced Cost Total"; Decimal)
        {
            Caption = 'Invoiced Cost Total';
            ToolTip = 'Specifies the cost (LCY) of invoiced sales for all types on this project only, at the time of the archive.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(116; "Budget Price Resource"; Decimal)
        {
            Caption = 'Budget Price Resource';
            ToolTip = 'Specifies the price (LCY) of budget (schedule) planning lines for resources on this project only, at the time of the archive.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(117; "Budget Price Item"; Decimal)
        {
            Caption = 'Budget Price Item';
            ToolTip = 'Specifies the price (LCY) of budget (schedule) planning lines for items on this project only, at the time of the archive.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(118; "Budget Price G/L Acc."; Decimal)
        {
            Caption = 'Budget Price G/L Acc.';
            ToolTip = 'Specifies the price (LCY) of budget (schedule) planning lines for G/L accounts on this project only, at the time of the archive.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(119; "Budget Price Total"; Decimal)
        {
            Caption = 'Budget Price Total';
            ToolTip = 'Specifies the price (LCY) of budget (schedule) planning lines for all types on this project only, at the time of the archive.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(120; "Usage Price Resource"; Decimal)
        {
            Caption = 'Usage Price Resource';
            ToolTip = 'Specifies the price (LCY) of posted usage for resources on this project only, at the time of the archive.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(121; "Usage Price Item"; Decimal)
        {
            Caption = 'Usage Price Item';
            ToolTip = 'Specifies the price (LCY) of posted usage for items on this project only, at the time of the archive.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(122; "Usage Price G/L Acc."; Decimal)
        {
            Caption = 'Usage Price G/L Acc.';
            ToolTip = 'Specifies the price (LCY) of posted usage for G/L accounts on this project only, at the time of the archive.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(123; "Usage Price Total"; Decimal)
        {
            Caption = 'Usage Price Total';
            ToolTip = 'Specifies the price (LCY) of posted usage for all types on this project only, at the time of the archive.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(124; "Billable Price Resource"; Decimal)
        {
            Caption = 'Billable Price Resource';
            ToolTip = 'Specifies the price (LCY) of billable (contract) planning lines for resources on this project only, at the time of the archive.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(125; "Billable Price Item"; Decimal)
        {
            Caption = 'Billable Price Item';
            ToolTip = 'Specifies the price (LCY) of billable (contract) planning lines for items on this project only, at the time of the archive.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(126; "Billable Price G/L Acc."; Decimal)
        {
            Caption = 'Billable Price G/L Acc.';
            ToolTip = 'Specifies the price (LCY) of billable (contract) planning lines for G/L accounts on this project only, at the time of the archive.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(127; "Billable Price Total"; Decimal)
        {
            Caption = 'Billable Price Total';
            ToolTip = 'Specifies the price (LCY) of billable (contract) planning lines for all types on this project only, at the time of the archive.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(128; "Invoiced Price Resource"; Decimal)
        {
            Caption = 'Invoiced Price Resource';
            ToolTip = 'Specifies the price (LCY) of invoiced sales for resources on this project only, at the time of the archive.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(129; "Invoiced Price Item"; Decimal)
        {
            Caption = 'Invoiced Price Item';
            ToolTip = 'Specifies the price (LCY) of invoiced sales for items on this project only, at the time of the archive.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(130; "Invoiced Price G/L Acc."; Decimal)
        {
            Caption = 'Invoiced Price G/L Acc.';
            ToolTip = 'Specifies the price (LCY) of invoiced sales for G/L accounts on this project only, at the time of the archive.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(131; "Invoiced Price Total"; Decimal)
        {
            Caption = 'Invoiced Price Total';
            ToolTip = 'Specifies the price (LCY) of invoiced sales for all types on this project only, at the time of the archive.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }

        field(200; "Budget Profit"; Decimal)
        {
            Caption = 'Budget Profit';
            ToolTip = 'Specifies the budget price minus the budget cost (LCY) on this project at the time of the archive.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(201; "Budget Margin %"; Decimal)
        {
            Caption = 'Budget Margin %';
            ToolTip = 'Specifies the budget profit as a percentage of the budget price at the time of the archive.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(202; "Usage Profit"; Decimal)
        {
            Caption = 'Usage Profit';
            ToolTip = 'Specifies the usage price minus the usage cost (LCY) on this project at the time of the archive.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(203; "Usage Margin %"; Decimal)
        {
            Caption = 'Usage Margin %';
            ToolTip = 'Specifies the usage profit as a percentage of the usage price at the time of the archive.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(204; "Billable Profit"; Decimal)
        {
            Caption = 'Billable Profit';
            ToolTip = 'Specifies the billable price minus the billable cost (LCY) on this project at the time of the archive.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(205; "Billable Margin %"; Decimal)
        {
            Caption = 'Billable Margin %';
            ToolTip = 'Specifies the billable profit as a percentage of the billable price at the time of the archive.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(206; "Invoiced Profit"; Decimal)
        {
            Caption = 'Invoiced Profit';
            ToolTip = 'Specifies the invoiced price minus the invoiced cost (LCY) on this project at the time of the archive.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(207; "Invoiced Margin %"; Decimal)
        {
            Caption = 'Invoiced Margin %';
            ToolTip = 'Specifies the invoiced profit as a percentage of the invoiced price at the time of the archive.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }

        field(300; "Hier. Budget Cost"; Decimal)
        {
            Caption = 'Hier. Budget Cost';
            ToolTip = 'Specifies the budget cost (LCY) of this project and its subprojects at the time of the archive.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(301; "Hier. Usage Cost"; Decimal)
        {
            Caption = 'Hier. Usage Cost';
            ToolTip = 'Specifies the usage cost (LCY) of this project and its subprojects at the time of the archive.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(302; "Hier. Billable Cost"; Decimal)
        {
            Caption = 'Hier. Billable Cost';
            ToolTip = 'Specifies the billable cost (LCY) of this project and its subprojects at the time of the archive.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(303; "Hier. Invoiced Cost"; Decimal)
        {
            Caption = 'Hier. Invoiced Cost';
            ToolTip = 'Specifies the invoiced cost (LCY) of this project and its subprojects at the time of the archive.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(304; "Hier. Budget Price"; Decimal)
        {
            Caption = 'Hier. Budget Price';
            ToolTip = 'Specifies the budget price (LCY) of this project and its subprojects at the time of the archive.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(305; "Hier. Usage Price"; Decimal)
        {
            Caption = 'Hier. Usage Price';
            ToolTip = 'Specifies the usage price (LCY) of this project and its subprojects at the time of the archive.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(306; "Hier. Billable Price"; Decimal)
        {
            Caption = 'Hier. Billable Price';
            ToolTip = 'Specifies the billable price (LCY) of this project and its subprojects at the time of the archive.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(307; "Hier. Invoiced Price"; Decimal)
        {
            Caption = 'Hier. Invoiced Price';
            ToolTip = 'Specifies the invoiced price (LCY) of this project and its subprojects at the time of the archive.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }

    }

    keys
    {
        key(PK; "Job No.", "Version No.")
        {
            Clustered = true;
        }
        key(Run; "Run ID", "Job No.")
        {
        }
        key(JobRunAt; "Job No.", "Run At")
        {
        }
        key(LevelJob; Level, "Job No.")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Job No.", "Version No.", Description) { }
        fieldgroup(Brick; "Job No.", Description, "Version No.") { }
    }
}
