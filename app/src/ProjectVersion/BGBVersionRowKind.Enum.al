namespace FlemmingBakkensen.BCGrokBot.ProjectVersion;

/// <summary>
/// Kind of a compare or report row: a task, a project, or the total.
/// </summary>
enum 50104 "BGB Version Row Kind"
{
    Access = Public;
    Extensible = false;

    value(0; " ")
    {
        Caption = ' ', Locked = true;
    }
    value(1; Task)
    {
        Caption = 'Task';
    }
    value(2; Project)
    {
        Caption = 'Project';
    }
    value(3; Total)
    {
        Caption = 'Total';
    }
}
