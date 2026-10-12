namespace FlemmingBakkensen.BCGrokBot.SalesAssignment;

using Microsoft.CRM.Team;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;

/// <summary>
/// Temporary buffer for the salesperson assignment go-live check.
/// </summary>
table 50103 "BGB Sales Assign. Issue"
{
    Caption = 'Sales Assignment Issue';
    Access = Public;
    TableType = Temporary;
    Extensible = false;
    AllowInCustomizations = Never;
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            ToolTip = 'Specifies the number of the issue.';
        }
        field(2; "Issue Type"; Enum "BGB Sales Assign. Issue Type")
        {
            Caption = 'Issue Type';
            ToolTip = 'Specifies why the customer or document will be blocked by the salesperson assignment rule.';
        }
        field(3; "Customer No."; Code[20])
        {
            Caption = 'Customer No.';
            ToolTip = 'Specifies the customer (bill-to customer for documents).';
            TableRelation = Customer;
        }
        field(4; "Customer Name"; Text[100])
        {
            Caption = 'Customer Name';
            ToolTip = 'Specifies the name of the customer.';
        }
        field(5; "Salesperson Code"; Code[20])
        {
            Caption = 'Salesperson Code';
            ToolTip = 'Specifies the salesperson assigned to the customer.';
            TableRelation = "Salesperson/Purchaser";
        }
        field(6; "Document Type"; Enum "Sales Document Type")
        {
            Caption = 'Document Type';
            ToolTip = 'Specifies the type of the open sales document.';
        }
        field(7; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            ToolTip = 'Specifies the number of the open sales document.';
        }
        field(8; Description; Text[250])
        {
            Caption = 'Description';
            ToolTip = 'Specifies what must be fixed before go-live.';
        }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
        key(Type; "Issue Type", "Customer No.") { }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Issue Type", "Customer No.", "Document No.") { }
        fieldgroup(Brick; "Issue Type", "Customer No.", "Customer Name", "Document No.") { }
    }
}
