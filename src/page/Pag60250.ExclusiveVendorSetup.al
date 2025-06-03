/* page 60250 "Exclusive Vendor Setup"
{
    ApplicationArea = All;
    Caption = 'Exclusive Vendor Setup';
    SourceTable = "Exclusive Vendor";
    UsageCategory = Lists;
    ModifyAllowed = true;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            field("Vendor No"; Rec."Vendor No")
            {
                Caption = 'Vendor No.';
                ApplicationArea = All;
                TableRelation = Vendor."No.";
            }
            field("Vendor Name"; Rec."Vendor Name")
            {
                Caption = 'Vendor Name';
                ApplicationArea = All;
                Editable = false;
            }
            field("Sent Headers URL"; Rec."Headers Web Service")
            {
                Caption = 'Sent Headers URL';
                ApplicationArea = All;
            }
            field("Sent Lines URL"; Rec."Lines Web Service")
            {
                Caption = 'Sent Lines URL';
                ApplicationArea = All;
            }
            field("Username"; Username)
            {
                Caption = 'WS Username';
                ToolTip = 'Username used to connect to vendor''s web service.';
                ApplicationArea = All;
                trigger OnValidate()
                begin
                    Rec.SetUsername(Username);
                end;
            }
            field("Password"; Password)
            {
                Caption = 'WS Password';
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

    trigger OnOpenPage()
    var
        VendorSettings: Record "Exclusive Vendor";
        SentLinesMgmt: Codeunit "Sent Lines Mgmt Cust";
    begin
        if VendorSettings.IsEmpty then begin
            VendorSettings.Init();
            VendorSettings."Key Field" := '';
            VendorSettings.Insert();
        end;

        if not IsNullGuid(Rec."WS Password") then
            Password := '***';
    end;

    var
        Username: Text;
        Password: Text;
} */