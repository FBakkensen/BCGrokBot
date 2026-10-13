namespace FlemmingBakkensen.BCGrokBot.ProjectVersion;

/// <summary>
/// One row of the project version trend: an archive run or version, or current, with key totals,
/// the change since the previous row, usage as a percentage of budget and invoiced as a percentage of billable.
/// </summary>
table 50109 "BGB Version Trend Buffer"
{
    Caption = 'Version Trend Buffer';
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
        field(2; "Sort Order"; Integer)
        {
            Caption = 'Sort Order';
            ToolTip = 'Specifies the chronological order. Current is last.';
        }
        field(3; "Run ID"; Guid)
        {
            Caption = 'Archive Run ID';
            ToolTip = 'Specifies the archive run. Blank for current and for archives that have no snapshot.';
        }
        field(4; "Run At"; DateTime)
        {
            Caption = 'Run At';
            ToolTip = 'Specifies when the version was archived. For current, this is the moment the trend was built.';
        }
        field(5; "Version No."; Integer)
        {
            Caption = 'Version No.';
            ToolTip = 'Specifies the project archive version. Zero for current.';
        }
        field(6; "Is Current"; Boolean)
        {
            Caption = 'Current';
            ToolTip = 'Specifies that the row is everything posted up to now, with no date filter.';
        }
        field(7; "No Breakdown"; Boolean)
        {
            Caption = 'No Breakdown';
            ToolTip = 'Specifies that this version has no snapshot. Totals come from the project task archive.';
        }
        field(8; "During Project Delete"; Boolean)
        {
            Caption = 'During Project Delete';
            ToolTip = 'Specifies that the snapshot was taken while the project was being deleted. Usage may be incomplete.';
        }
        field(9; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies the version description.';
        }
        field(20; "Budget Cost"; Decimal)
        {
            Caption = 'Budget Cost';
            ToolTip = 'Specifies the budget cost (LCY) of this version.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(40; "Budget Cost Delta"; Decimal)
        {
            Caption = 'Budget Cost Delta';
            ToolTip = 'Specifies the change in budget cost since the previous version. The first version is zero.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(21; "Budget Price"; Decimal)
        {
            Caption = 'Budget Price';
            ToolTip = 'Specifies the budget price (LCY) of this version.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(41; "Budget Price Delta"; Decimal)
        {
            Caption = 'Budget Price Delta';
            ToolTip = 'Specifies the change in budget price since the previous version. The first version is zero.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(22; "Usage Cost"; Decimal)
        {
            Caption = 'Usage Cost';
            ToolTip = 'Specifies the usage cost (LCY) of this version.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(42; "Usage Cost Delta"; Decimal)
        {
            Caption = 'Usage Cost Delta';
            ToolTip = 'Specifies the change in usage cost since the previous version. The first version is zero.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(23; "Usage Price"; Decimal)
        {
            Caption = 'Usage Price';
            ToolTip = 'Specifies the usage price (LCY) of this version.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(43; "Usage Price Delta"; Decimal)
        {
            Caption = 'Usage Price Delta';
            ToolTip = 'Specifies the change in usage price since the previous version. The first version is zero.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(24; "Billable Cost"; Decimal)
        {
            Caption = 'Billable Cost';
            ToolTip = 'Specifies the billable cost (LCY) of this version.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(44; "Billable Cost Delta"; Decimal)
        {
            Caption = 'Billable Cost Delta';
            ToolTip = 'Specifies the change in billable cost since the previous version. The first version is zero.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(25; "Billable Price"; Decimal)
        {
            Caption = 'Billable Price';
            ToolTip = 'Specifies the billable price (LCY) of this version.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(45; "Billable Price Delta"; Decimal)
        {
            Caption = 'Billable Price Delta';
            ToolTip = 'Specifies the change in billable price since the previous version. The first version is zero.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(26; "Invoiced Cost"; Decimal)
        {
            Caption = 'Invoiced Cost';
            ToolTip = 'Specifies the invoiced cost (LCY) of this version.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(46; "Invoiced Cost Delta"; Decimal)
        {
            Caption = 'Invoiced Cost Delta';
            ToolTip = 'Specifies the change in invoiced cost since the previous version. The first version is zero.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(27; "Invoiced Price"; Decimal)
        {
            Caption = 'Invoiced Price';
            ToolTip = 'Specifies the invoiced price (LCY) of this version.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(47; "Invoiced Price Delta"; Decimal)
        {
            Caption = 'Invoiced Price Delta';
            ToolTip = 'Specifies the change in invoiced price since the previous version. The first version is zero.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(60; "Usage % of Budget"; Decimal)
        {
            Caption = 'Usage % of Budget';
            ToolTip = 'Specifies usage cost as a percentage of budget cost. Zero when the budget cost is zero.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(61; "Invoiced % of Billable"; Decimal)
        {
            Caption = 'Invoiced % of Billable';
            ToolTip = 'Specifies invoiced price as a percentage of billable price. Zero when the billable price is zero.';
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
        key(Order; "Sort Order")
        {
        }
        key(RunAt; "Run At", "Version No.")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Version No.", Description, "Run At") { }
        fieldgroup(Brick; Description, "Version No.", "Run At") { }
    }
}
