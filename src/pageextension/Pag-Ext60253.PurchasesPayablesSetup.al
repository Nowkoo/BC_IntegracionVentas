pageextension 60253 "Purchases & Payables Setup" extends "Purchases & Payables Setup"
{
    layout
    {
        addafter("Number Series")
        {
            group(SalesIntegration)
            {
                Caption = 'Sales Integration';

                group(Vendor)
                {
                    Caption = 'Vendor Setup';
                    field("Vendor No"; Rec."Vendor No.")
                    {
                        ApplicationArea = All;
                        TableRelation = Vendor."No.";
                    }
                    field("Vendor Name"; Rec."Vendor Name")
                    {
                        ApplicationArea = All;
                        Editable = false;
                    }
                    field("Customer No."; Rec."Customer No.")
                    {
                        ApplicationArea = All;
                    }
                }

                group(WebService)
                {
                    Caption = 'Web Service Setup';
                    field("Sent Headers URL"; Rec."Headers Web Service")
                    {
                        ApplicationArea = All;
                    }
                    field("Sent Lines URL"; Rec."Lines Web Service")
                    {
                        ApplicationArea = All;
                    }
                    field("Username"; Username)
                    {
                        Caption = 'Username';
                        ToolTip = 'Username used to connect to vendor''s web service.';
                        ApplicationArea = All;
                        ExtendedDatatype = Masked;

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

                group(NewItems)
                {
                    Caption = 'New Items Setup';
                    field("Gen. Prod. Posting Group"; Rec."Gen. Prod. Posting Group")
                    {
                        ApplicationArea = All;
                    }
                    field("Inventory Posting Group"; Rec."Inventory Posting Group")
                    {
                        ApplicationArea = All;
                    }
                    field("Unit of Measure"; Rec."Base Unit of Measure")
                    {
                        ApplicationArea = All;
                    }
                }
            }
        }
    }

    trigger OnOpenPage()
    var
    begin
        if not IsNullGuid(Rec."WS Password") then
            Password := '******';

        if not IsNullGuid(Rec."WS Username") then
            Username := '******';
    end;

    var
        Username: Text;
        Password: Text;
}