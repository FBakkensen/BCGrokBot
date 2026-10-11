permissionset 50150 "My BC App Tests"
{
    Caption = 'My BC App Tests', MaxLength = 30;
    Assignable = true;
    IncludedPermissionSets = "My BC App";
    Permissions = codeunit "Hello World Test" = X;
}
