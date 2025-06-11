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

                if SalesLine.FindSet() then begin
                    //Modificación de la primera línea
                    if (SalesLine.Count = 1) and (xRec."No." <> '') then
                        VendorExclusivityMgmt.UpdateOrderOwnership(Rec."Document No.", Rec."No.")
                    //Modificación/inserción de otras líneas
                    else
                        VendorExclusivityMgmt.CheckIfInsertIsAllowed(Rec."No.", Rec."Document No.");
                end
                else begin
                    //Inserción de la primera línea
                    if xRec."No." = '' then begin
                        VendorExclusivityMgmt.UpdateOrderOwnership(Rec."Document No.", Rec."No.");
                    end;
                end;
            end;
        }
    }

    trigger OnBeforeInsert()
    var
        SalesHeader: Record "Sales Header";
    begin
        //Rec.Status := Status::Pending;
    end;

    trigger OnAfterDelete()
    var
        SentLinesMgmt: Codeunit "Sent Lines Mgmt";
        VendorExclusivityMgmt: Codeunit "Vendor Exclusivity Mgmt";
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        PurchasesSetup: Record "Purchases & Payables Setup";
        SentLineId: Text[50];
    begin
        RemoveLineFromWS();

        //Si se está eliminando el pedido, no es necesario actualizar la cabecera
        if SalesHeader.Get(SalesHeader."Document Type"::Order, Rec."Document No.") and not SalesHeader.Deleting then begin
            //Si no quedan líneas, el pedido no es de nadie
            SalesLine.SetRange("Document No.", Rec."Document No.");
            if not SalesLine.FindFirst() then
                VendorExclusivityMgmt.RemoveOrderOwnership(rec."Document No.");
        end;
    end;

    trigger OnBeforeModify()
    var
        SentLinesMgmt: Codeunit "Sent Lines Mgmt";
        SalesHeader: Record "Sales Header";
        PurchasesSetup: Record "Purchases & Payables Setup";
        SentLineId: Text[50];
    begin
        PurchasesSetup.Get();
        if PurchasesSetup."Vendor No." <> '' then begin
            RemoveLineFromWS();
            Rec.Status := Status::Pending;
        end;
    end;

    local procedure RemoveLineFromWS()
    var
        SentLinesMgmt: Codeunit "Sent Lines Mgmt";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SentLineId: Text[50];
    begin
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange("Document No.", Rec."Document No.");
        SalesHeader.Get(SalesHeader."Document Type"::Order, Rec."Document No.");

        if (Rec.Status = Status::Sent) and
            SalesHeader.Get(SalesHeader."Document Type"::Order, Rec."Document No.") and
            SalesHeader."Is From Exclusive Vendor" then begin
            SentLinesMgmt.RemoveLineFromWS(Rec."Document No.", Rec."Line No.");
        end;
    end;
}