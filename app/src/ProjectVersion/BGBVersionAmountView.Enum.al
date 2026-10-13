namespace FlemmingBakkensen.BCGrokBot.ProjectVersion;

/// <summary>
/// Which planning or ledger type the version compare shows. Total is the sum of Resource, Item and G/L Account.
/// </summary>
enum 50102 "BGB Version Amount View"
{
    Access = Public;
    Extensible = false;

    value(0; " ")
    {
        Caption = ' ', Locked = true;
    }
    value(1; Total)
    {
        Caption = 'Total';
    }
    value(2; Resource)
    {
        Caption = 'Resource';
    }
    value(3; Item)
    {
        Caption = 'Item';
    }
    value(4; "G/L Account")
    {
        Caption = 'G/L Account';
    }
}
