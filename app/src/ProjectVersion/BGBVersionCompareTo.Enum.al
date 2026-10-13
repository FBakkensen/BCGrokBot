namespace FlemmingBakkensen.BCGrokBot.ProjectVersion;

/// <summary>
/// The right-hand side of a version compare: another archived version, or everything posted up to now.
/// </summary>
enum 50103 "BGB Version Compare To"
{
    Access = Public;
    Extensible = false;

    value(0; " ")
    {
        Caption = ' ', Locked = true;
    }
    value(1; Current)
    {
        Caption = 'Current';
    }
    value(2; Version)
    {
        Caption = 'Version';
    }
}
