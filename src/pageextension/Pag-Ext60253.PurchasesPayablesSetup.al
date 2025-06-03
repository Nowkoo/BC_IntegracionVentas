pageextension 60253 "Purchases & Payables Setup" extends "Purchases & Payables Setup"
{
    layout
    {
        addafter("Number Series")
        {
            group(SalesIntegration)
            {
                Caption = 'Sales Integration';

                field("Vendor No"; Rec."Vendor No.")
                {
                    Caption = 'Vendor No.';
                    ToolTip = 'Your identification number for the vendor that hosts the web service.';
                    ApplicationArea = All;
                    TableRelation = Vendor."No.";
                }
                field("Vendor Name"; Rec."Vendor Name")
                {
                    Caption = 'Vendor Name';
                    ToolTip = 'The name of the vendor selected above.';
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Customer No."; Rec."Customer No.")
                {
                    ToolTip = 'The identification number that the vendor uses in their system to identify you as a customer.';
                    Caption = 'Customer No.';
                    ApplicationArea = All;
                }
                field("Sent Headers URL"; Rec."Headers Web Service")
                {
                    Caption = 'Sent Headers URL';
                    ToolTip = 'URL of the vendor''s web service that stores the sales headers data.';
                    ApplicationArea = All;
                }
                field("Sent Lines URL"; Rec."Lines Web Service")
                {
                    Caption = 'Sent Lines URL';
                    ToolTip = 'URL of the vendor''s web service that stores the sales lines data.';
                    ApplicationArea = All;
                }
                field("Username"; Username)
                {
                    Caption = 'Username';
                    ToolTip = 'Username used to connect to vendor''s web service.';
                    ApplicationArea = All;
                    trigger OnValidate()
                    begin
                        Rec.SetUsername(Username);
                    end;
                }
                field("Password"; Password)
                {
                    Caption = 'Password';
                    ToolTip = 'Password used to connect to vendor''s web service.';
                    ApplicationArea = All;
                    ExtendedDatatype = Masked;

                    trigger OnValidate()
                    begin
                        Rec.SetPassword(Password);
                    end;
                }
            }
        }
    }

    actions
    {
        // Add changes to page actions here
    }

    var
        Username: Text;
        Password: Text;
}