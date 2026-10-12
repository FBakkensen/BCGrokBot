namespace FlemmingBakkensen.BCGrokBot;

using FlemmingBakkensen.BCGrokBot.SalesAssignment;

/// <summary>
/// Grants access to all objects in BCGrokBot.
/// </summary>
permissionset 50100 "BCGrokBot"
{
    Access = Public;
    Caption = 'BCGrokBot', MaxLength = 30;
    Assignable = true;
    Permissions = table "BGB Sales Assign. Bypass" = X,
                  table "BGB Sales Assign. Issue" = X,
                  table "BGB Salesp. Assign. Admin" = X,
                  codeunit "BGB Sales Assign. Go-Live" = X,
                  codeunit "BGB Sales Assign. Subscribers" = X,
                  codeunit "BGB Sales Assignment Mgt." = X,
                  codeunit "Hello World" = X,
                  page "BGB Sales Assign. Go-Live" = X;
}
