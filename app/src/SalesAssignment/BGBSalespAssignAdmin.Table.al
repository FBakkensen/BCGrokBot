namespace FlemmingBakkensen.BCGrokBot.SalesAssignment;

/// <summary>
/// Permission marker. Holds no data. A user with Modify permission on this table data
/// (permission set BGB SALESP ADMIN) may change customer salesperson codes and the
/// salesperson link on User Setup.
/// </summary>
table 50101 "BGB Salesp. Assign. Admin"
{
    Caption = 'Salesperson Assignment Admin';
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
