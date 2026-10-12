namespace FlemmingBakkensen.BCGrokBot.SalesAssignment;

/// <summary>
/// Allows changing Customer."Salesperson Code" and the salesperson link on User Setup.
/// Assign together with the user's normal permission sets.
/// </summary>
permissionset 50101 "BGB SALESP ADMIN"
{
    Caption = 'BCGrokBot salesperson admin', MaxLength = 30;
    Access = Public;
    Assignable = true;
    Permissions = tabledata "BGB Salesp. Assign. Admin" = RIMD;
}
