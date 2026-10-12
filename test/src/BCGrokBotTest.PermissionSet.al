namespace FlemmingBakkensen.BCGrokBot.Test;

using FlemmingBakkensen.BCGrokBot;
using FlemmingBakkensen.BCGrokBot.Test.ProjectHierarchy;
using FlemmingBakkensen.BCGrokBot.Test.SalesAssignment;
using FlemmingBakkensen.BCGrokBot.Test.WebDemo;

/// <summary>
/// Grants access to BCGrokBot and its test objects.
/// </summary>
permissionset 50150 "BCGrokBot.Test"
{
    Access = Public;
    Caption = 'BCGrokBot.Test', MaxLength = 30;
    Assignable = true;
    IncludedPermissionSets = "BCGrokBot";
    Permissions = codeunit "BGB Hierarchy Invoicing Tests" = X,
                  codeunit "BGB Project Hierarchy Tests" = X,
                  codeunit "BGB Project Test Data" = X,
                  codeunit "BGB Sales Assign. Perm. Tests" = X,
                  codeunit "BGB Sales Assign. Unit Tests" = X,
                  codeunit "BGB Web Demo Install" = X,
                  codeunit "BGB Web Demo Registration" = X,
                  codeunit "BGB Web Demo Setup" = X,
                  codeunit "BGB Web Demo Upgrade" = X,
                  codeunit "Hello World Test" = X;
}
