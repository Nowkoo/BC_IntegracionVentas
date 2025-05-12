tableextension 60250 "Sales Line" extends "Sales Line"
{
    fields
    {
        field(303; "Status"; Enum Status)
        {
            DataClassification = CustomerContent;
        }

        modify("No.")
        {
            trigger OnAfterValidate()
            var
                VendorExclusivityMgmt: Codeunit "Vendor Exclusivity Mgmt";
                SalesLine: Record "Sales Line";
            begin
                SalesLine.SetRange("Document No.", Rec."Document No.");
                if SalesLine.FindSet() and (SalesLine.Count = 1) then begin
                    if xRec."No." = '' then begin
                        //es un insert
                        VendorExclusivityMgmt.CheckIfAllowed(Rec."No.", Rec."Document No.");
                        VendorExclusivityMgmt.UpdateOrderOwnership(Rec."Document No.", Rec."No.")
                    end
                end
                else
                    VendorExclusivityMgmt.CheckIfAllowed(Rec."No.", Rec."Document No.");
            end;
        }
    }

    trigger OnBeforeInsert()
    begin
        Rec.Status := Status::Pending;
    end;

    trigger OnAfterDelete()
    var
        VendorExclusivityMgmt: Codeunit "Vendor Exclusivity Mgmt";
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document No.", Rec."Document No.");

        if not SalesLine.FindFirst() then
            VendorExclusivityMgmt.RemoveOrderOwnership(rec."Document No.");
    end;
}