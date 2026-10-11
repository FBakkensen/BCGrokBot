permissionset 50100 "My BC App"
{
    Caption = 'My BC App', MaxLength = 30;
    Assignable = true;
    Permissions = codeunit "Hello World" = X;
}
