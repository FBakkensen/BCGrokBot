namespace FlemmingBakkensen.BCGrokBot.ProjectHierarchy;

using Microsoft.Projects.Project.Job;

/// <summary>
/// Hierarchy totals: the standard project statistics (LCY) summed over the project and all its subprojects.
/// </summary>
page 50101 "BGB Hierarchy Totals FactBox"
{
    Caption = 'Hierarchy Totals';
    Editable = false;
    LinksAllowed = false;
    PageType = CardPart;
    SourceTable = Job;
    ApplicationArea = Jobs;

    layout
    {
        area(Content)
        {
            field(SubprojectCount; SubprojectCount)
            {
                Caption = 'Subprojects (all levels)';
                ToolTip = 'Specifies the number of subprojects below this project, at any depth.';
            }
            group(BudgetCost)
            {
                Caption = 'Budget Cost';
                field(BudgetCostResource; CostAmounts[1])
                {
                    AutoFormatType = 1;
                    AutoFormatExpression = '';
                    Caption = 'Resource';
                    ToolTip = 'Specifies the budgeted cost (LCY) of resources for this project and all its subprojects.';
                }
                field(BudgetCostItem; CostAmounts[2])
                {
                    AutoFormatType = 1;
                    AutoFormatExpression = '';
                    Caption = 'Item';
                    ToolTip = 'Specifies the budgeted cost (LCY) of items for this project and all its subprojects.';
                }
                field(BudgetCostGLAcc; CostAmounts[3])
                {
                    AutoFormatType = 1;
                    AutoFormatExpression = '';
                    Caption = 'G/L Account';
                    ToolTip = 'Specifies the budgeted cost (LCY) of G/L accounts for this project and all its subprojects.';
                }
                field(BudgetCostTotal; CostAmounts[4])
                {
                    AutoFormatType = 1;
                    AutoFormatExpression = '';
                    Caption = 'Total';
                    ToolTip = 'Specifies the budgeted cost (LCY) of all types for this project and all its subprojects.';
                }
            }
            group(ActualCost)
            {
                Caption = 'Actual Cost';
                field(ActualCostResource; CostAmounts[5])
                {
                    AutoFormatType = 1;
                    AutoFormatExpression = '';
                    Caption = 'Resource';
                    ToolTip = 'Specifies the actual (usage) cost (LCY) of resources for this project and all its subprojects.';
                }
                field(ActualCostItem; CostAmounts[6])
                {
                    AutoFormatType = 1;
                    AutoFormatExpression = '';
                    Caption = 'Item';
                    ToolTip = 'Specifies the actual (usage) cost (LCY) of items for this project and all its subprojects.';
                }
                field(ActualCostGLAcc; CostAmounts[7])
                {
                    AutoFormatType = 1;
                    AutoFormatExpression = '';
                    Caption = 'G/L Account';
                    ToolTip = 'Specifies the actual (usage) cost (LCY) of G/L accounts for this project and all its subprojects.';
                }
                field(ActualCostTotal; CostAmounts[8])
                {
                    AutoFormatType = 1;
                    AutoFormatExpression = '';
                    Caption = 'Total';
                    ToolTip = 'Specifies the actual (usage) cost (LCY) of all types for this project and all its subprojects.';
                }
            }
            group(BillablePrice)
            {
                Caption = 'Billable Price';
                field(BillablePriceResource; PriceAmounts[9])
                {
                    AutoFormatType = 1;
                    AutoFormatExpression = '';
                    Caption = 'Resource';
                    ToolTip = 'Specifies the billable price (LCY) of resources for this project and all its subprojects.';
                }
                field(BillablePriceItem; PriceAmounts[10])
                {
                    AutoFormatType = 1;
                    AutoFormatExpression = '';
                    Caption = 'Item';
                    ToolTip = 'Specifies the billable price (LCY) of items for this project and all its subprojects.';
                }
                field(BillablePriceGLAcc; PriceAmounts[11])
                {
                    AutoFormatType = 1;
                    AutoFormatExpression = '';
                    Caption = 'G/L Account';
                    ToolTip = 'Specifies the billable price (LCY) of G/L accounts for this project and all its subprojects.';
                }
                field(BillablePriceTotal; PriceAmounts[12])
                {
                    AutoFormatType = 1;
                    AutoFormatExpression = '';
                    Caption = 'Total';
                    ToolTip = 'Specifies the billable price (LCY) of all types for this project and all its subprojects.';
                }
            }
            group(InvoicedPrice)
            {
                Caption = 'Invoiced Price';
                field(InvoicedPriceResource; PriceAmounts[13])
                {
                    AutoFormatType = 1;
                    AutoFormatExpression = '';
                    Caption = 'Resource';
                    ToolTip = 'Specifies the invoiced price (LCY) of resources for this project and all its subprojects.';
                }
                field(InvoicedPriceItem; PriceAmounts[14])
                {
                    AutoFormatType = 1;
                    AutoFormatExpression = '';
                    Caption = 'Item';
                    ToolTip = 'Specifies the invoiced price (LCY) of items for this project and all its subprojects.';
                }
                field(InvoicedPriceGLAcc; PriceAmounts[15])
                {
                    AutoFormatType = 1;
                    AutoFormatExpression = '';
                    Caption = 'G/L Account';
                    ToolTip = 'Specifies the invoiced price (LCY) of G/L accounts for this project and all its subprojects.';
                }
                field(InvoicedPriceTotal; PriceAmounts[16])
                {
                    AutoFormatType = 1;
                    AutoFormatExpression = '';
                    Caption = 'Total';
                    ToolTip = 'Specifies the invoiced price (LCY) of all types for this project and all its subprojects.';
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        ProjectHierarchyMgt: Codeunit "BGB Project Hierarchy Mgt.";
    begin
        SubprojectCount := ProjectHierarchyMgt.CountDescendants(Rec."No.");
        ProjectHierarchyMgt.CalcHierarchyAmounts(Rec, CostAmounts, PriceAmounts);
    end;

    var
        CostAmounts: array[16] of Decimal;
        PriceAmounts: array[16] of Decimal;
        SubprojectCount: Integer;
}
