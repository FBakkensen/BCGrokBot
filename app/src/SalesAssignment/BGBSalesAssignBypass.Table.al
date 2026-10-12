namespace FlemmingBakkensen.BCGrokBot.SalesAssignment;

/// <summary>
/// Permission marker. Holds no data. A user with Modify permission on this table data
/// (permission set BGB SALES BYPASS, intended for integration and job queue users) is not
/// restricted by the salesperson assignment rule on sales documents.
/// </summary>
table 50102 "BGB Sales Assign. Bypass"
{
    Caption = 'Sales Assignment Bypass';
    Access = Internal;
    DataClassification = SystemMetadata;
    DataPerCompany = false;
    InherentEntitlements = X;
    InherentPermissions = X;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
            ToolTip = 'Specifies the primary key of the permission marker.';
            NotBlank = false;
        }
    }

    keys
    {
        key(PK; "Primary Key") { Clustered = true; }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Primary Key") { }
        fieldgroup(Brick; "Primary Key") { }
    }
}
