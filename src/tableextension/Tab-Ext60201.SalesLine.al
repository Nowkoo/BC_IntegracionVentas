tableextension 60250 "Sales Line" extends "Sales Line"
{
    fields
    {
        // Add changes to table fields here
    }

    keys
    {
        // Add changes to keys here
    }

    fieldgroups
    {
        // Add changes to field groups here
    }

    trigger OnBeforeInsert()
    var
        VendorExclusivityMgmt: Codeunit "Vendor Exclusivity Management";
    begin
        VendorExclusivityMgmt.CheckIfAllowed(Rec."No.", Rec."Document No.");
    end;

    //Se ejecuta dos veces
    trigger OnAfterModify()
    var
        VendorExclusivityMgmt: Codeunit "Vendor Exclusivity Management";
        SalesLine: Record "Sales Line";
    begin
        VendorExclusivityMgmt.CheckIfAllowed(Rec."No.", Rec."Document No.");

        SalesLine.SetRange("Document No.", Rec."Document No.");
        SalesLine.FindSet();
        if SalesLine.Count = 1 then
            VendorExclusivityMgmt.UpdateOrderOwnership(Rec."Document No.", Rec."No.");

    end;

    trigger OnAfterInsert()
    var
        VendorExclusivityMgmt: Codeunit "Vendor Exclusivity Management";
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document No.", Rec."Document No.");
        SalesLine.FindSet();
        if SalesLine.Count = 1 then
            VendorExclusivityMgmt.UpdateOrderOwnership(Rec."Document No.", Rec."No.");
    end;

    trigger OnAfterDelete()
    var
        VendorExclusivityMgmt: Codeunit "Vendor Exclusivity Management";
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document No.", Rec."Document No.");

        if not SalesLine.FindFirst() then
            VendorExclusivityMgmt.RemoveOrderOwnership(rec."Document No.");
    end;
}