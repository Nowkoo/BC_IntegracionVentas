tableextension 60251 "Sales Header" extends "Sales Header"
{
    fields
    {
        field(303; "Is From Exclusive Vendor"; Boolean)
        {
            DataClassification = CustomerContent;
        }
    }

    trigger OnAfterDelete()
    var
        SentLinesMgmt: Codeunit "Sent Lines Mgmt Cust";
        ExclusiveVendor: Record "Exclusive Vendor";
    begin
        if ExclusiveVendor.Get() and Rec."Is From Exclusive Vendor" then
            SentLinesMgmt.RemoveHeaderFromWS(Rec."No.");
    end;
}