namespace FlemmingBakkensen.BCGrokBot.ProjectVersion;

using Microsoft.Projects.Project.Job;

/// <summary>
/// One archived project task. Usage and invoiced cost and price are split by Resource, Item and G/L Account
/// from project ledger entries. Budget and billable amounts per type come from the archived planning lines.
/// </summary>
table 50107 "BGB Project Task Snapshot"
{
    Caption = 'Project Task Snapshot';
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
            ToolTip = 'Specifies the project.';
            TableRelation = Job;
        }
        field(2; "Version No."; Integer)
        {
            Caption = 'Version No.';
            ToolTip = 'Specifies the project archive version.';
        }
        field(3; "Job Task No."; Code[20])
        {
            Caption = 'Project Task No.';
            ToolTip = 'Specifies the project task.';
        }
        field(4; "Run ID"; Guid)
        {
            Caption = 'Archive Run ID';
            ToolTip = 'Specifies the archive run this task snapshot belongs to.';
        }
        field(5; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies the task description at the time of the archive.';
        }
        field(6; "Job Task Type"; Enum "Job Task Type")
        {
            Caption = 'Project Task Type';
            ToolTip = 'Specifies the task type at the time of the archive. Only posting tasks are included in the compare total.';
        }
        field(7; Indentation; Integer)
        {
            Caption = 'Indentation';
            ToolTip = 'Specifies the indentation of the task at the time of the archive.';
        }
        field(100; "Budget Cost Resource"; Decimal)
        {
            Caption = 'Budget Cost Resource';
            ToolTip = 'Specifies the cost (LCY) of budget (schedule) planning lines for resources on this project task, at the time of the archive.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(101; "Budget Cost Item"; Decimal)
        {
            Caption = 'Budget Cost Item';
            ToolTip = 'Specifies the cost (LCY) of budget (schedule) planning lines for items on this project task, at the time of the archive.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(102; "Budget Cost G/L Acc."; Decimal)
        {
            Caption = 'Budget Cost G/L Acc.';
            ToolTip = 'Specifies the cost (LCY) of budget (schedule) planning lines for G/L accounts on this project task, at the time of the archive.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(103; "Budget Cost Total"; Decimal)
        {
            Caption = 'Budget Cost Total';
            ToolTip = 'Specifies the cost (LCY) of budget (schedule) planning lines for all types on this project task, at the time of the archive.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(104; "Usage Cost Resource"; Decimal)
        {
            Caption = 'Usage Cost Resource';
            ToolTip = 'Specifies the cost (LCY) of posted usage for resources on this project task, at the time of the archive.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(105; "Usage Cost Item"; Decimal)
        {
            Caption = 'Usage Cost Item';
            ToolTip = 'Specifies the cost (LCY) of posted usage for items on this project task, at the time of the archive.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(106; "Usage Cost G/L Acc."; Decimal)
        {
            Caption = 'Usage Cost G/L Acc.';
            ToolTip = 'Specifies the cost (LCY) of posted usage for G/L accounts on this project task, at the time of the archive.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(107; "Usage Cost Total"; Decimal)
        {
            Caption = 'Usage Cost Total';
            ToolTip = 'Specifies the cost (LCY) of posted usage for all types on this project task, at the time of the archive.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(108; "Billable Cost Resource"; Decimal)
        {
            Caption = 'Billable Cost Resource';
            ToolTip = 'Specifies the cost (LCY) of billable (contract) planning lines for resources on this project task, at the time of the archive.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(109; "Billable Cost Item"; Decimal)
        {
            Caption = 'Billable Cost Item';
            ToolTip = 'Specifies the cost (LCY) of billable (contract) planning lines for items on this project task, at the time of the archive.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(110; "Billable Cost G/L Acc."; Decimal)
        {
            Caption = 'Billable Cost G/L Acc.';
            ToolTip = 'Specifies the cost (LCY) of billable (contract) planning lines for G/L accounts on this project task, at the time of the archive.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(111; "Billable Cost Total"; Decimal)
        {
            Caption = 'Billable Cost Total';
            ToolTip = 'Specifies the cost (LCY) of billable (contract) planning lines for all types on this project task, at the time of the archive.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(112; "Invoiced Cost Resource"; Decimal)
        {
            Caption = 'Invoiced Cost Resource';
            ToolTip = 'Specifies the cost (LCY) of invoiced sales for resources on this project task, at the time of the archive.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(113; "Invoiced Cost Item"; Decimal)
        {
            Caption = 'Invoiced Cost Item';
            ToolTip = 'Specifies the cost (LCY) of invoiced sales for items on this project task, at the time of the archive.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(114; "Invoiced Cost G/L Acc."; Decimal)
        {
            Caption = 'Invoiced Cost G/L Acc.';
            ToolTip = 'Specifies the cost (LCY) of invoiced sales for G/L accounts on this project task, at the time of the archive.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(115; "Invoiced Cost Total"; Decimal)
        {
            Caption = 'Invoiced Cost Total';
            ToolTip = 'Specifies the cost (LCY) of invoiced sales for all types on this project task, at the time of the archive.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(116; "Budget Price Resource"; Decimal)
        {
            Caption = 'Budget Price Resource';
            ToolTip = 'Specifies the price (LCY) of budget (schedule) planning lines for resources on this project task, at the time of the archive.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(117; "Budget Price Item"; Decimal)
        {
            Caption = 'Budget Price Item';
            ToolTip = 'Specifies the price (LCY) of budget (schedule) planning lines for items on this project task, at the time of the archive.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(118; "Budget Price G/L Acc."; Decimal)
        {
            Caption = 'Budget Price G/L Acc.';
            ToolTip = 'Specifies the price (LCY) of budget (schedule) planning lines for G/L accounts on this project task, at the time of the archive.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(119; "Budget Price Total"; Decimal)
        {
            Caption = 'Budget Price Total';
            ToolTip = 'Specifies the price (LCY) of budget (schedule) planning lines for all types on this project task, at the time of the archive.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(120; "Usage Price Resource"; Decimal)
        {
            Caption = 'Usage Price Resource';
            ToolTip = 'Specifies the price (LCY) of posted usage for resources on this project task, at the time of the archive.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(121; "Usage Price Item"; Decimal)
        {
            Caption = 'Usage Price Item';
            ToolTip = 'Specifies the price (LCY) of posted usage for items on this project task, at the time of the archive.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(122; "Usage Price G/L Acc."; Decimal)
        {
            Caption = 'Usage Price G/L Acc.';
            ToolTip = 'Specifies the price (LCY) of posted usage for G/L accounts on this project task, at the time of the archive.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(123; "Usage Price Total"; Decimal)
        {
            Caption = 'Usage Price Total';
            ToolTip = 'Specifies the price (LCY) of posted usage for all types on this project task, at the time of the archive.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(124; "Billable Price Resource"; Decimal)
        {
            Caption = 'Billable Price Resource';
            ToolTip = 'Specifies the price (LCY) of billable (contract) planning lines for resources on this project task, at the time of the archive.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(125; "Billable Price Item"; Decimal)
        {
            Caption = 'Billable Price Item';
            ToolTip = 'Specifies the price (LCY) of billable (contract) planning lines for items on this project task, at the time of the archive.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(126; "Billable Price G/L Acc."; Decimal)
        {
            Caption = 'Billable Price G/L Acc.';
            ToolTip = 'Specifies the price (LCY) of billable (contract) planning lines for G/L accounts on this project task, at the time of the archive.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(127; "Billable Price Total"; Decimal)
        {
            Caption = 'Billable Price Total';
            ToolTip = 'Specifies the price (LCY) of billable (contract) planning lines for all types on this project task, at the time of the archive.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(128; "Invoiced Price Resource"; Decimal)
        {
            Caption = 'Invoiced Price Resource';
            ToolTip = 'Specifies the price (LCY) of invoiced sales for resources on this project task, at the time of the archive.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(129; "Invoiced Price Item"; Decimal)
        {
            Caption = 'Invoiced Price Item';
            ToolTip = 'Specifies the price (LCY) of invoiced sales for items on this project task, at the time of the archive.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(130; "Invoiced Price G/L Acc."; Decimal)
        {
            Caption = 'Invoiced Price G/L Acc.';
            ToolTip = 'Specifies the price (LCY) of invoiced sales for G/L accounts on this project task, at the time of the archive.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(131; "Invoiced Price Total"; Decimal)
        {
            Caption = 'Invoiced Price Total';
            ToolTip = 'Specifies the price (LCY) of invoiced sales for all types on this project task, at the time of the archive.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }

    }

    keys
    {
        key(PK; "Job No.", "Version No.", "Job Task No.")
        {
            Clustered = true;
        }
        key(Run; "Run ID", "Job No.", "Job Task No.")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Job No.", "Job Task No.", Description) { }
        fieldgroup(Brick; "Job No.", "Job Task No.", Description) { }
    }
}
