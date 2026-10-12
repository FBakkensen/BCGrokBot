namespace FlemmingBakkensen.BCGrokBot.ProjectAnalysis;

using Microsoft.Projects.Project.Job;
using Microsoft.Sales.Customer;

/// <summary>
/// One row per project of a project hierarchy for the Project Hierarchy Analysis report: tree position,
/// master data, the project's own statistics (same figures as standard Job Calculate Statistics, LCY)
/// and the rolled-up totals of the project and all its subprojects.
/// </summary>
table 50104 "BGB Project Analysis Buffer"
{
    Caption = 'Project Analysis Buffer';
    TableType = Temporary;
    Access = Public;
    DataClassification = SystemMetadata;
    AllowInCustomizations = Never;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            ToolTip = 'Specifies the row number in tree order (parents before their subprojects).';
        }
        field(2; "Top-Level Project No."; Code[20])
        {
            Caption = 'Top-Level Project No.';
            ToolTip = 'Specifies the top-level project of the hierarchy.';
            TableRelation = Job;
        }
        field(3; "Project No."; Code[20])
        {
            Caption = 'Project No.';
            ToolTip = 'Specifies the project.';
            TableRelation = Job;
        }
        field(4; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies the project description.';
        }
        field(5; "Indented Description"; Text[250])
        {
            Caption = 'Indented Description';
            ToolTip = 'Specifies the project description indented by its level.';
        }
        field(6; "Parent Project No."; Code[20])
        {
            Caption = 'Parent Project No.';
            ToolTip = 'Specifies the parent project.';
            TableRelation = Job;
        }
        field(7; Level; Integer)
        {
            Caption = 'Level';
            ToolTip = 'Specifies the depth in the hierarchy. The top-level project has level 0.';
        }
        field(8; "Sort Key"; Text[250])
        {
            Caption = 'Sort Key';
            ToolTip = 'Specifies a key that sorts the rows in tree order, for example 0001.0002.0001.';
        }
        field(9; "Bill-to Customer No."; Code[20])
        {
            Caption = 'Bill-to Customer No.';
            ToolTip = 'Specifies the bill-to customer of the project.';
            TableRelation = Customer;
        }
        field(10; "Bill-to Name"; Text[100])
        {
            Caption = 'Bill-to Name';
            ToolTip = 'Specifies the bill-to customer name.';
        }
        field(11; "Sell-to Customer No."; Code[20])
        {
            Caption = 'Sell-to Customer No.';
            ToolTip = 'Specifies the sell-to customer of the project.';
            TableRelation = Customer;
        }
        field(12; "Sell-to Name"; Text[100])
        {
            Caption = 'Sell-to Name';
            ToolTip = 'Specifies the sell-to customer name.';
        }
        field(13; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            ToolTip = 'Specifies the project currency (blank = LCY).';
        }
        field(14; "Invoice Currency Code"; Code[10])
        {
            Caption = 'Invoice Currency Code';
            ToolTip = 'Specifies the invoice currency of the project (blank = LCY).';
        }
        field(15; Status; Enum "Job Status")
        {
            Caption = 'Status';
            ToolTip = 'Specifies the project status.';
        }
        field(16; "Person Responsible"; Code[20])
        {
            Caption = 'Person Responsible';
            ToolTip = 'Specifies the person responsible for the project.';
        }
        field(17; "Subproject Count"; Integer)
        {
            Caption = 'Subproject Count';
            ToolTip = 'Specifies the number of subprojects at any depth below the project.';
        }
        field(100; "Budget Cost Resource"; Decimal)
        {
            Caption = 'Budget Cost Resource';
            ToolTip = 'Specifies the cost (LCY) of budget (schedule) planning lines for resources on this project only.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(101; "Budget Cost Item"; Decimal)
        {
            Caption = 'Budget Cost Item';
            ToolTip = 'Specifies the cost (LCY) of budget (schedule) planning lines for items on this project only.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(102; "Budget Cost G/L Acc."; Decimal)
        {
            Caption = 'Budget Cost G/L Acc.';
            ToolTip = 'Specifies the cost (LCY) of budget (schedule) planning lines for G/L accounts on this project only.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(103; "Budget Cost Total"; Decimal)
        {
            Caption = 'Budget Cost Total';
            ToolTip = 'Specifies the cost (LCY) of budget (schedule) planning lines for all types on this project only.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(104; "Usage Cost Resource"; Decimal)
        {
            Caption = 'Usage Cost Resource';
            ToolTip = 'Specifies the cost (LCY) of posted usage for resources on this project only.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(105; "Usage Cost Item"; Decimal)
        {
            Caption = 'Usage Cost Item';
            ToolTip = 'Specifies the cost (LCY) of posted usage for items on this project only.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(106; "Usage Cost G/L Acc."; Decimal)
        {
            Caption = 'Usage Cost G/L Acc.';
            ToolTip = 'Specifies the cost (LCY) of posted usage for G/L accounts on this project only.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(107; "Usage Cost Total"; Decimal)
        {
            Caption = 'Usage Cost Total';
            ToolTip = 'Specifies the cost (LCY) of posted usage for all types on this project only.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(108; "Billable Cost Resource"; Decimal)
        {
            Caption = 'Billable Cost Resource';
            ToolTip = 'Specifies the cost (LCY) of billable (contract) planning lines for resources on this project only.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(109; "Billable Cost Item"; Decimal)
        {
            Caption = 'Billable Cost Item';
            ToolTip = 'Specifies the cost (LCY) of billable (contract) planning lines for items on this project only.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(110; "Billable Cost G/L Acc."; Decimal)
        {
            Caption = 'Billable Cost G/L Acc.';
            ToolTip = 'Specifies the cost (LCY) of billable (contract) planning lines for G/L accounts on this project only.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(111; "Billable Cost Total"; Decimal)
        {
            Caption = 'Billable Cost Total';
            ToolTip = 'Specifies the cost (LCY) of billable (contract) planning lines for all types on this project only.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(112; "Invoiced Cost Resource"; Decimal)
        {
            Caption = 'Invoiced Cost Resource';
            ToolTip = 'Specifies the cost (LCY) of invoiced sales for resources on this project only.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(113; "Invoiced Cost Item"; Decimal)
        {
            Caption = 'Invoiced Cost Item';
            ToolTip = 'Specifies the cost (LCY) of invoiced sales for items on this project only.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(114; "Invoiced Cost G/L Acc."; Decimal)
        {
            Caption = 'Invoiced Cost G/L Acc.';
            ToolTip = 'Specifies the cost (LCY) of invoiced sales for G/L accounts on this project only.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(115; "Invoiced Cost Total"; Decimal)
        {
            Caption = 'Invoiced Cost Total';
            ToolTip = 'Specifies the cost (LCY) of invoiced sales for all types on this project only.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(116; "Budget Price Resource"; Decimal)
        {
            Caption = 'Budget Price Resource';
            ToolTip = 'Specifies the price (LCY) of budget (schedule) planning lines for resources on this project only.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(117; "Budget Price Item"; Decimal)
        {
            Caption = 'Budget Price Item';
            ToolTip = 'Specifies the price (LCY) of budget (schedule) planning lines for items on this project only.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(118; "Budget Price G/L Acc."; Decimal)
        {
            Caption = 'Budget Price G/L Acc.';
            ToolTip = 'Specifies the price (LCY) of budget (schedule) planning lines for G/L accounts on this project only.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(119; "Budget Price Total"; Decimal)
        {
            Caption = 'Budget Price Total';
            ToolTip = 'Specifies the price (LCY) of budget (schedule) planning lines for all types on this project only.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(120; "Usage Price Resource"; Decimal)
        {
            Caption = 'Usage Price Resource';
            ToolTip = 'Specifies the price (LCY) of posted usage for resources on this project only.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(121; "Usage Price Item"; Decimal)
        {
            Caption = 'Usage Price Item';
            ToolTip = 'Specifies the price (LCY) of posted usage for items on this project only.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(122; "Usage Price G/L Acc."; Decimal)
        {
            Caption = 'Usage Price G/L Acc.';
            ToolTip = 'Specifies the price (LCY) of posted usage for G/L accounts on this project only.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(123; "Usage Price Total"; Decimal)
        {
            Caption = 'Usage Price Total';
            ToolTip = 'Specifies the price (LCY) of posted usage for all types on this project only.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(124; "Billable Price Resource"; Decimal)
        {
            Caption = 'Billable Price Resource';
            ToolTip = 'Specifies the price (LCY) of billable (contract) planning lines for resources on this project only.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(125; "Billable Price Item"; Decimal)
        {
            Caption = 'Billable Price Item';
            ToolTip = 'Specifies the price (LCY) of billable (contract) planning lines for items on this project only.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(126; "Billable Price G/L Acc."; Decimal)
        {
            Caption = 'Billable Price G/L Acc.';
            ToolTip = 'Specifies the price (LCY) of billable (contract) planning lines for G/L accounts on this project only.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(127; "Billable Price Total"; Decimal)
        {
            Caption = 'Billable Price Total';
            ToolTip = 'Specifies the price (LCY) of billable (contract) planning lines for all types on this project only.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(128; "Invoiced Price Resource"; Decimal)
        {
            Caption = 'Invoiced Price Resource';
            ToolTip = 'Specifies the price (LCY) of invoiced sales for resources on this project only.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(129; "Invoiced Price Item"; Decimal)
        {
            Caption = 'Invoiced Price Item';
            ToolTip = 'Specifies the price (LCY) of invoiced sales for items on this project only.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(130; "Invoiced Price G/L Acc."; Decimal)
        {
            Caption = 'Invoiced Price G/L Acc.';
            ToolTip = 'Specifies the price (LCY) of invoiced sales for G/L accounts on this project only.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(131; "Invoiced Price Total"; Decimal)
        {
            Caption = 'Invoiced Price Total';
            ToolTip = 'Specifies the price (LCY) of invoiced sales for all types on this project only.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(200; "Budget Profit"; Decimal)
        {
            Caption = 'Budget Profit';
            ToolTip = 'Specifies the budget price minus the budget cost (LCY) on this project only.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(201; "Budget Margin %"; Decimal)
        {
            Caption = 'Budget Margin %';
            ToolTip = 'Specifies the budget profit as a percentage of the budget price on this project only.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(202; "Usage Profit"; Decimal)
        {
            Caption = 'Usage Profit';
            ToolTip = 'Specifies the usage price minus the usage cost (LCY) on this project only.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(203; "Usage Margin %"; Decimal)
        {
            Caption = 'Usage Margin %';
            ToolTip = 'Specifies the usage profit as a percentage of the usage price on this project only.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(204; "Billable Profit"; Decimal)
        {
            Caption = 'Billable Profit';
            ToolTip = 'Specifies the billable price minus the billable cost (LCY) on this project only.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(205; "Billable Margin %"; Decimal)
        {
            Caption = 'Billable Margin %';
            ToolTip = 'Specifies the billable profit as a percentage of the billable price on this project only.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(206; "Invoiced Profit"; Decimal)
        {
            Caption = 'Invoiced Profit';
            ToolTip = 'Specifies the invoiced price minus the invoiced cost (LCY) on this project only.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(207; "Invoiced Margin %"; Decimal)
        {
            Caption = 'Invoiced Margin %';
            ToolTip = 'Specifies the invoiced profit as a percentage of the invoiced price on this project only.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(300; "Hier. Budget Cost"; Decimal)
        {
            Caption = 'Hier. Budget Cost';
            ToolTip = 'Specifies the total budget cost (LCY) of this project and all its subprojects.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(301; "Hier. Usage Cost"; Decimal)
        {
            Caption = 'Hier. Usage Cost';
            ToolTip = 'Specifies the total usage cost (LCY) of this project and all its subprojects.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(302; "Hier. Billable Cost"; Decimal)
        {
            Caption = 'Hier. Billable Cost';
            ToolTip = 'Specifies the total billable cost (LCY) of this project and all its subprojects.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(303; "Hier. Invoiced Cost"; Decimal)
        {
            Caption = 'Hier. Invoiced Cost';
            ToolTip = 'Specifies the total invoiced cost (LCY) of this project and all its subprojects.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(304; "Hier. Budget Price"; Decimal)
        {
            Caption = 'Hier. Budget Price';
            ToolTip = 'Specifies the total budget price (LCY) of this project and all its subprojects.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(305; "Hier. Usage Price"; Decimal)
        {
            Caption = 'Hier. Usage Price';
            ToolTip = 'Specifies the total usage price (LCY) of this project and all its subprojects.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(306; "Hier. Billable Price"; Decimal)
        {
            Caption = 'Hier. Billable Price';
            ToolTip = 'Specifies the total billable price (LCY) of this project and all its subprojects.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(307; "Hier. Invoiced Price"; Decimal)
        {
            Caption = 'Hier. Invoiced Price';
            ToolTip = 'Specifies the total invoiced price (LCY) of this project and all its subprojects.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
        key(Project; "Project No.") { }
    }
}
