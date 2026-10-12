namespace FlemmingBakkensen.BCGrokBot.SalesAssignment;

/// <summary>
/// Kinds of go-live issues found by the salesperson assignment check.
/// </summary>
enum 50100 "BGB Sales Assign. Issue Type"
{
    Access = Public;
    Extensible = false;

    value(0; " ") { Caption = ' ', Locked = true; }
    value(1; "Customer Without Salesperson") { Caption = 'Customer without salesperson'; }
    value(2; "Salesperson Not Linked") { Caption = 'Salesperson not linked to a user'; }
    value(3; "Open Document Would Fail") { Caption = 'Open document would fail'; }
}
