namespace FlemmingBakkensen.BCGrokBot.ProjectVersion;

using Microsoft.Projects.Project.Job;

/// <summary>
/// One row of the project version compare: a task, a project, or the total, with amounts for side A and side B,
/// the difference and the percentage change.
/// </summary>
table 50108 "BGB Version Compare Buffer"
{
    Caption = 'Version Compare Buffer';
    TableType = Temporary;
    Access = Public;
    DataClassification = SystemMetadata;
    AllowInCustomizations = Never;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            ToolTip = 'Specifies the row number.';
        }
        field(2; "Row Kind"; Enum "BGB Version Row Kind")
        {
            Caption = 'Row Kind';
            ToolTip = 'Specifies whether the row is a task, a project or the total.';
        }
        field(3; "Project No."; Code[20])
        {
            Caption = 'Project No.';
            ToolTip = 'Specifies the project.';
            TableRelation = Job;
        }
        field(4; "Job Task No."; Code[20])
        {
            Caption = 'Project Task No.';
            ToolTip = 'Specifies the project task. Blank on project and total rows.';
        }
        field(5; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies the description.';
        }
        field(6; Level; Integer)
        {
            Caption = 'Level';
            ToolTip = 'Specifies the hierarchy level of a project row.';
        }
        field(7; "Job Task Type"; Enum "Job Task Type")
        {
            Caption = 'Project Task Type';
            ToolTip = 'Specifies the task type. Only posting tasks are included in the total.';
        }
        field(8; "Include in Total"; Boolean)
        {
            Caption = 'Include in Total';
            ToolTip = 'Specifies that this row is added into the total row.';
        }
        field(9; "No Breakdown"; Boolean)
        {
            Caption = 'No Breakdown';
            ToolTip = 'Specifies that a side of this row comes from a project archive that has no snapshot, so there is no Resource, Item or G/L split.';
        }
        field(10; "During Project Delete"; Boolean)
        {
            Caption = 'During Project Delete';
            ToolTip = 'Specifies that a snapshot on this row was taken while the project was being deleted. Usage may be incomplete.';
        }
        field(11; "Version No. A"; Integer)
        {
            Caption = 'Version No. A';
            ToolTip = 'Specifies the archive version used for side A of this project.';
        }
        field(12; "Version No. B"; Integer)
        {
            Caption = 'Version No. B';
            ToolTip = 'Specifies the archive version used for side B. Zero when side B is current.';
        }
        field(20; "Budget Cost A"; Decimal)
        {
            Caption = 'Budget Cost A';
            ToolTip = 'Specifies budget cost (LCY) for version A.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(21; "Budget Price A"; Decimal)
        {
            Caption = 'Budget Price A';
            ToolTip = 'Specifies budget price (LCY) for version A.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(22; "Usage Cost A"; Decimal)
        {
            Caption = 'Usage Cost A';
            ToolTip = 'Specifies usage cost (LCY) for version A.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(23; "Usage Price A"; Decimal)
        {
            Caption = 'Usage Price A';
            ToolTip = 'Specifies usage price (LCY) for version A.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(24; "Billable Cost A"; Decimal)
        {
            Caption = 'Billable Cost A';
            ToolTip = 'Specifies billable cost (LCY) for version A.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(25; "Billable Price A"; Decimal)
        {
            Caption = 'Billable Price A';
            ToolTip = 'Specifies billable price (LCY) for version A.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(26; "Invoiced Cost A"; Decimal)
        {
            Caption = 'Invoiced Cost A';
            ToolTip = 'Specifies invoiced cost (LCY) for version A.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(27; "Invoiced Price A"; Decimal)
        {
            Caption = 'Invoiced Price A';
            ToolTip = 'Specifies invoiced price (LCY) for version A.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(30; "Budget Cost B"; Decimal)
        {
            Caption = 'Budget Cost B';
            ToolTip = 'Specifies budget cost (LCY) for version B or current.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(31; "Budget Price B"; Decimal)
        {
            Caption = 'Budget Price B';
            ToolTip = 'Specifies budget price (LCY) for version B or current.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(32; "Usage Cost B"; Decimal)
        {
            Caption = 'Usage Cost B';
            ToolTip = 'Specifies usage cost (LCY) for version B or current.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(33; "Usage Price B"; Decimal)
        {
            Caption = 'Usage Price B';
            ToolTip = 'Specifies usage price (LCY) for version B or current.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(34; "Billable Cost B"; Decimal)
        {
            Caption = 'Billable Cost B';
            ToolTip = 'Specifies billable cost (LCY) for version B or current.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(35; "Billable Price B"; Decimal)
        {
            Caption = 'Billable Price B';
            ToolTip = 'Specifies billable price (LCY) for version B or current.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(36; "Invoiced Cost B"; Decimal)
        {
            Caption = 'Invoiced Cost B';
            ToolTip = 'Specifies invoiced cost (LCY) for version B or current.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(37; "Invoiced Price B"; Decimal)
        {
            Caption = 'Invoiced Price B';
            ToolTip = 'Specifies invoiced price (LCY) for version B or current.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(40; "Budget Cost Difference"; Decimal)
        {
            Caption = 'Budget Cost Difference';
            ToolTip = 'Specifies budget cost (LCY) for the difference (B minus A).';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(41; "Budget Price Difference"; Decimal)
        {
            Caption = 'Budget Price Difference';
            ToolTip = 'Specifies budget price (LCY) for the difference (B minus A).';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(42; "Usage Cost Difference"; Decimal)
        {
            Caption = 'Usage Cost Difference';
            ToolTip = 'Specifies usage cost (LCY) for the difference (B minus A).';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(43; "Usage Price Difference"; Decimal)
        {
            Caption = 'Usage Price Difference';
            ToolTip = 'Specifies usage price (LCY) for the difference (B minus A).';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(44; "Billable Cost Difference"; Decimal)
        {
            Caption = 'Billable Cost Difference';
            ToolTip = 'Specifies billable cost (LCY) for the difference (B minus A).';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(45; "Billable Price Difference"; Decimal)
        {
            Caption = 'Billable Price Difference';
            ToolTip = 'Specifies billable price (LCY) for the difference (B minus A).';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(46; "Invoiced Cost Difference"; Decimal)
        {
            Caption = 'Invoiced Cost Difference';
            ToolTip = 'Specifies invoiced cost (LCY) for the difference (B minus A).';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(47; "Invoiced Price Difference"; Decimal)
        {
            Caption = 'Invoiced Price Difference';
            ToolTip = 'Specifies invoiced price (LCY) for the difference (B minus A).';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(50; "Budget Cost Change %"; Decimal)
        {
            Caption = 'Budget Cost Change %';
            ToolTip = 'Specifies the percentage change from A to B for budget cost. Zero when version A is zero.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(51; "Budget Price Change %"; Decimal)
        {
            Caption = 'Budget Price Change %';
            ToolTip = 'Specifies the percentage change from A to B for budget price. Zero when version A is zero.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(52; "Usage Cost Change %"; Decimal)
        {
            Caption = 'Usage Cost Change %';
            ToolTip = 'Specifies the percentage change from A to B for usage cost. Zero when version A is zero.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(53; "Usage Price Change %"; Decimal)
        {
            Caption = 'Usage Price Change %';
            ToolTip = 'Specifies the percentage change from A to B for usage price. Zero when version A is zero.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(54; "Billable Cost Change %"; Decimal)
        {
            Caption = 'Billable Cost Change %';
            ToolTip = 'Specifies the percentage change from A to B for billable cost. Zero when version A is zero.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(55; "Billable Price Change %"; Decimal)
        {
            Caption = 'Billable Price Change %';
            ToolTip = 'Specifies the percentage change from A to B for billable price. Zero when version A is zero.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(56; "Invoiced Cost Change %"; Decimal)
        {
            Caption = 'Invoiced Cost Change %';
            ToolTip = 'Specifies the percentage change from A to B for invoiced cost. Zero when version A is zero.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(57; "Invoiced Price Change %"; Decimal)
        {
            Caption = 'Invoiced Price Change %';
            ToolTip = 'Specifies the percentage change from A to B for invoiced price. Zero when version A is zero.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }

    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(Kind; "Row Kind", "Project No.", "Job Task No.")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Entry No.", Description) { }
        fieldgroup(Brick; Description, "Project No.", "Job Task No.") { }
    }
}
