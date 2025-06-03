codeunit 60250 "Vendor Exclusivity Mgmt"
{
    procedure CheckIfInsertIsAllowed(ItemNo: Code[20]; DocumentNo: Code[20])
    var
        SalesLine: Record "Sales Line";
        Item: Record "Item";
        PurchasesSetup: Record "Purchases & Payables Setup";

        ExclusiveVendorNo: Code[20];
        CurrentVendorNo: Code[20];

        CurrentVendorIsExclusiveVendor: Boolean;
        AllowInsert: Boolean;

        ErrorLbl: Label 'Items acquired from vendor %1 cannot be purchased together with items acquired from other vendors.';
        ExclusiveVendorName: Text;
    begin
        //***
        if PurchasesSetup.Get() then
            ExclusiveVendorNo := PurchasesSetup."Vendor No.";

        if Item.Get(ItemNo) then
            CurrentVendorNo := Item."Vendor No.";

        if ExclusiveVendorNo = CurrentVendorNo then
            CurrentVendorIsExclusiveVendor := true;

        if CurrentVendorIsExclusiveVendor then begin
            if IsTheUniqueVendorInOrder(ExclusiveVendorNo, DocumentNo) then
                AllowInsert := true;
        end
        else begin
            if not IsVendorInOrder(ExclusiveVendorNo, DocumentNo) then
                AllowInsert := true;
        end;

        if not AllowInsert then
            Error(ErrorLbl, PurchasesSetup."Vendor Name");
    end;

    local procedure IsTheUniqueVendorInOrder(ExclusiveVendorNo: Code[20]; DocumentNo: Code[20]): Boolean
    var
        SalesLine: Record "Sales Line";
        Item: Record "Item";
    begin
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        if SalesLine.FindSet() then
            repeat
                if Item.Get(SalesLine."No.") then begin
                    if Item."Vendor No." <> ExclusiveVendorNo then
                        exit(false);
                end;
            until SalesLine.Next() = 0;
        exit(true);
    end;

    local procedure IsVendorInOrder(VendorNo: Code[20]; DocumentNo: Code[20]): Boolean
    var
        SalesLine: Record "Sales Line";
        Item: Record "Item";
    begin
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        if SalesLine.FindSet() then
            repeat
                if Item.Get(SalesLine."No.") then begin
                    if Item."Vendor No." = VendorNo then
                        exit(true);
                end;
            until SalesLine.Next() = 0;
        exit(false);
    end;

    procedure UpdateOrderOwnership(DocumentNo: Code[20]; ItemNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        PurchasesSetup: Record "Purchases & Payables Setup";
        IsFromExclusiveVendor: Boolean;
    begin
        //***
        if SalesHeader.Get(SalesHeader."Document Type"::Order, DocumentNo) and PurchasesSetup.Get() then begin
            Item.Get(ItemNo);
            IsFromExclusiveVendor := PurchasesSetup."Vendor No." = Item."Vendor No.";

            if SalesHeader."Is From Exclusive Vendor" <> IsFromExclusiveVendor then begin
                SalesHeader."Is From Exclusive Vendor" := IsFromExclusiveVendor;
                SalesHeader.Modify();
            end;
        end;
    end;

    procedure RemoveOrderOwnership(DocumentNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
        IsFromExclusiveVendor: Boolean;
    begin
        if SalesHeader.Get(SalesHeader."Document Type"::Order, DocumentNo) then begin
            IsFromExclusiveVendor := false;
            if SalesHeader."Is From Exclusive Vendor" <> IsFromExclusiveVendor then begin
                SalesHeader."Is From Exclusive Vendor" := IsFromExclusiveVendor;
                SalesHeader.Modify();
            end;
        end;
    end;
}