namespace FlemmingBakkensen.BCGrokBot;

using FlemmingBakkensen.BCGrokBot.ProjectAnalysis;
using FlemmingBakkensen.BCGrokBot.ProjectHierarchy;
using FlemmingBakkensen.BCGrokBot.ProjectVersion;
using FlemmingBakkensen.BCGrokBot.SalesAssignment;

/// <summary>
/// Grants access to all objects in BCGrokBot.
/// </summary>
permissionset 50100 "BCGrokBot"
{
    Access = Public;
    Caption = 'BCGrokBot', MaxLength = 30;
    Assignable = true;
    Permissions = table "BGB Project Analysis Buffer" = X,
                  table "BGB Project Archive Run" = X,
                  table "BGB Project Snapshot" = X,
                  table "BGB Project Task Snapshot" = X,
                  table "BGB Sales Assign. Bypass" = X,
                  table "BGB Sales Assign. Issue" = X,
                  table "BGB Salesp. Assign. Admin" = X,
                  table "BGB Version Compare Buffer" = X,
                  table "BGB Version Report Buffer" = X,
                  table "BGB Version Trend Buffer" = X,
                  codeunit "BGB Archive Hierarchies JQ" = X,
                  codeunit "BGB Archive Run Context" = X,
                  codeunit "BGB Hierarchy Archive" = X,
                  codeunit "BGB Hierarchy Inv. Binding" = X,
                  codeunit "BGB Hierarchy Invoicing" = X,
                  codeunit "BGB Project Analysis Mgt." = X,
                  codeunit "BGB Project Archive Mgt." = X,
                  codeunit "BGB Project Archive Subs." = X,
                  codeunit "BGB Project Hierarchy Mgt." = X,
                  codeunit "BGB Project Hierarchy Subs." = X,
                  codeunit "BGB Sales Assign. Go-Live" = X,
                  codeunit "BGB Sales Assign. Subscribers" = X,
                  codeunit "BGB Sales Assignment Mgt." = X,
                  codeunit "BGB Version Compare Mgt." = X,
                  codeunit "Hello World" = X,
                  page "BGB Hierarchy Totals FactBox" = X,
                  page "BGB Project Version Compare" = X,
                  page "BGB Project Version Trend" = X,
                  page "BGB Sales Assign. Go-Live" = X,
                  page "BGB Subprojects" = X,
                  report "BGB Create Hierarchy Invoices" = X,
                  report "BGB Project Hierarchy Analysis" = X,
                  report "BGB Project Version Trend" = X;
}
