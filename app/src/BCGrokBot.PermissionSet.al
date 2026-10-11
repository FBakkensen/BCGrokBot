namespace FlemmingBakkensen.BCGrokBot;

/// <summary>
/// Grants access to all objects in BCGrokBot.
/// </summary>
permissionset 50100 "BCGrokBot"
{
    Access = Public;
    Caption = 'BCGrokBot', MaxLength = 30;
    Assignable = true;
    Permissions = codeunit "Hello World" = X;
}
