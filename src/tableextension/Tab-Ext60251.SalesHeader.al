tableextension 60251 "Sales Header" extends "Sales Header"
{
    fields
    {
        field(303; "Is From Exclusive Vendor"; Boolean)
        {
            DataClassification = CustomerContent;
        }
        field(304; "Deleting"; Boolean)
        {
            DataClassification = CustomerContent;
        }
    }

    trigger OnBeforeDelete()
    var
        SentLinesMgmt: Codeunit "Sent Lines Mgmt Cust";
        PurchasesSetup: Record "Purchases & Payables Setup";
    begin
        Rec.Deleting := true;
        Modify();
        //***
        PurchasesSetup.Get();
        if (PurchasesSetup."Vendor No." <> '') and Rec."Is From Exclusive Vendor" then
            SentLinesMgmt.RemoveHeaderFromWS(Rec."No.");
    end;


}