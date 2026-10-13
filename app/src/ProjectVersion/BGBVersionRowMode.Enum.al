namespace FlemmingBakkensen.BCGrokBot.ProjectVersion;

/// <summary>
/// Rows of the project version compare: one row per project task, or one row per project in the tree.
/// </summary>
enum 50101 "BGB Version Row Mode"
{
    Access = Public;
    Extensible = false;

    value(0; " ")
    {
        Caption = ' ', Locked = true;
    }
    value(1; Tasks)
    {
        Caption = 'Tasks';
    }
    value(2; Projects)
    {
        Caption = 'Projects';
    }
}
