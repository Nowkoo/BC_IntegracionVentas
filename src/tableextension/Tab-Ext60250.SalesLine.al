tableextension 60250 "Sales Line" extends "Sales Line"
{
    fields
    {
        field(303; "Status"; Enum Status)
        {
            Caption = 'Status';
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
                //Modificación de la primera línea
                if SalesLine.FindSet() then begin
                    if (SalesLine.Count = 1) and (xRec."No." <> '') then begin
                        VendorExclusivityMgmt.UpdateOrderOwnership(Rec."Document No.", Rec."No.");
                    end;
                end
                else begin
                    //Inserción de la primera línea
                    if xRec."No." = '' then begin
                        VendorExclusivityMgmt.CheckIfInsertIsAllowed(Rec."No.", Rec."Document No.");
                        VendorExclusivityMgmt.UpdateOrderOwnership(Rec."Document No.", Rec."No.");
                    end
                    else
                        VendorExclusivityMgmt.CheckIfInsertIsAllowed(Rec."No.", Rec."Document No.");
                end;
            end;
        }
    }

    trigger OnBeforeInsert()
    begin
        Rec.Status := Status::Pending;
    end;

    trigger OnAfterDelete()
    var
        SentLinesMgmt: Codeunit "Sent Lines Mgmt Cust";
        VendorExclusivityMgmt: Codeunit "Vendor Exclusivity Mgmt";
        SalesLine: Record "Sales Line";
        SentLineId: Text[50];

    begin
        //Si no quedan líneas, el pedido no es de nadie
        SalesLine.SetRange("Document No.", Rec."Document No.");
        if not SalesLine.FindFirst() then
            VendorExclusivityMgmt.RemoveOrderOwnership(rec."Document No.");

        RemoveLineFromWS();
    end;

    trigger OnAfterModify()
    var
        SentLinesMgmt: Codeunit "Sent Lines Mgmt Cust";
        ExclusiveVendor: Record "Exclusive Vendor";
        SalesHeader: Record "Sales Header";
        SentLineId: Text[50];
    begin
        RemoveLineFromWS();
        Rec.Status := Status::Pending;
        Rec.Modify();
    end;

    local procedure RemoveLineFromWS()
    var
        SentLinesMgmt: Codeunit "Sent Lines Mgmt Cust";
        ExclusiveVendor: Record "Exclusive Vendor";
        SalesHeader: Record "Sales Header";
        SentLineId: Text[50];
    begin
        SalesHeader.Get(SalesHeader."Document Type"::Order, Rec."Document No.");
        if SalesHeader."Is From Exclusive Vendor" and (Rec.Status = Status::Sent) then begin
            SentLineId := SentLinesMgmt.GetSentLineWebServiceId(Rec."Document No.", Rec."Line No.");
            if SentLineId <> '' then
                SentLinesMgmt.RemoveLineFromWS(SentLineId);
        end;
    end;
}