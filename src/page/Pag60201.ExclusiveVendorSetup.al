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
                ApplicationArea = All;
                TableRelation = Vendor."No.";
            }
            field("Vendor Name"; Rec."Vendor Name")
            {
                ApplicationArea = All;
                Editable = false;
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