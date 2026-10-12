namespace FlemmingBakkensen.BCGrokBot.SalesAssignment;

/// <summary>
/// Exempts a user (integration, API, job queue) from the salesperson assignment rule on sales documents.
/// </summary>
permissionset 50102 "BGB SALES BYPASS"
{
    Caption = 'BCGrokBot sales rule bypass', MaxLength = 30;
    Access = Public;
    Assignable = true;
    Permissions = tabledata "BGB Sales Assign. Bypass" = RIMD;
}
