namespace FlemmingBakkensen.BCGrokBot.Test;

using FlemmingBakkensen.BCGrokBot;

/// <summary>
/// Grants access to BCGrokBot and its test objects.
/// </summary>
permissionset 50150 "BCGrokBot.Test"
{
    Access = Public;
    Caption = 'BCGrokBot.Test', MaxLength = 30;
    Assignable = true;
    IncludedPermissionSets = "BCGrokBot";
    Permissions = codeunit "Hello World Test" = X;
}
