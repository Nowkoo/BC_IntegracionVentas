page 60250 "Exclusive Vendor Setup"
{
    ApplicationArea = All;
    Caption = 'Exclusive Vendor Setup';
    SourceTable = "Exclusive Vendor";
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
        }
    }

    trigger OnOpenPage()
    var
        VendorSettings: Record "Exclusive Vendor";
    begin
        if VendorSettings.IsEmpty then begin
            VendorSettings.Init();
            VendorSettings."Key Field" := '';
            VendorSettings.Insert();
        end;
    end;
}