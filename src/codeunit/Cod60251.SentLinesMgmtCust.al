//https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/webservices/web-services-authentication
codeunit 60251 "Sent Lines Mgmt Cust"
{
    trigger OnRun()
    var
        SalesHeader: Record "Sales Header";
        PurchasesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesSetup.Get();
        if (PurchasesSetup."Vendor No." = '') or (PurchasesSetup."Customer No." = '') then
            Error(ErrorNotConfiguredLbl);
        SalesHeader.SetRange("Is From Exclusive Vendor", true);
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
        if SalesHeader.FindSet() then
            repeat
                PrepareLines(SalesHeader);
                Inform(SalesHeader);
            until SalesHeader.Next() = 0;
    end;

    procedure Inform(SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
        Item: Record Item;
        PurchasesSetup: Record "Purchases & Payables Setup";
        JsonText: Text;
        Url: Text;
        SentHeader: JsonObject;
        UnconfiguredItemsNos: List of [Text];
        VendorItemNoNeededLbl: Label 'Some items in the order do not have Vendor Item No. configured. Sales lines containing these items could not be sent.';
    begin
        PurchasesSetup.Get();
        if (PurchasesSetup."Vendor No." = '') or (PurchasesSetup."Customer No." = '') then
            Error(ErrorNotConfiguredLbl);

        //Post del header
        SentHeader := GetSentHeader(SalesHeader."No.");
        if GetJsonText(SentHeader, 'id') = '' then begin
            JsonText := SalesHeaderToJsonText(SalesHeader."No.");
            Url := GetSentHeadersBaseUrl();
            HttpRequests.PostJsonObject(Url, JsonText);
        end;

        //Post de las líneas
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        if SalesLine.FindSet() then
            repeat
                if Item.Get(SalesLine."No.") and (Item."Vendor Item No." = '') then begin
                    if not UnconfiguredItemsNos.Contains(Item."No.") then
                        UnconfiguredItemsNos.Add(Item."No.");
                end
                else begin
                    if SalesLine.Status = SalesLine.Status::Pending then begin
                        JsonText := SalesLineToJsonText(SalesLine);
                        Url := GetSentLinesBaseUrl();
                        HttpRequests.PostJsonObject(Url, JsonText);

                        SalesLine.Status := Status::Sent;
                        SalesLine.Modify();
                    end;
                end;
            until SalesLine.Next() = 0;

        if UnconfiguredItemsNos.Count <> 0 then begin
            Message(VendorItemNoNeededLbl);
            //Se podrían mostrar una lista filtrada de los items en cuestión
        end;

        SalesHeader.Modify();
    end;

    procedure PrepareLines(SalesHeader: Record "Sales Header")
    var
        HttpResponseMessage: HttpResponseMessage;
        JsonToken: JsonToken;
        JsonObject: JsonObject;
        JsonArray: JsonArray;
        JsonText: Text;
        LineNosFromOrderInWS: List of [Text];
        LineNoText: Text;
        IsLineReady: Boolean;
        IsLineNew: Boolean;
        URL: Text;
        SalesLine: Record "Sales Line";
        PurchasesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesSetup.Get();
        if (PurchasesSetup."Vendor No." = '') or (PurchasesSetup."Customer No." = '') then
            Error(ErrorNotConfiguredLbl);

        //	/?$filter=documentNo eq '101012' and ready eq true
        URL := GetSentLinesBaseUrl() + '/?$filter=documentNo eq ''' + SalesHeader."No." + ''' and customerNo eq ''' + PurchasesSetup."Customer No." + '''';
        HttpRequests.GetJsonData(URL, HttpResponseMessage);

        HttpResponseMessage.Content.ReadAs(JsonText);
        if not JsonObject.ReadFrom(JsonText) then
            Error(ErrorInvalidResponseLbl);

        JsonObject.Get('value', JsonToken);
        JsonArray := JsonToken.AsArray();
        foreach JsonToken in JsonArray do begin
            JsonObject := JsonToken.AsObject();
            Evaluate(IsLineReady, GetJsonText(JsonObject, 'ready'));

            if IsLineReady then begin
                Evaluate(IsLineNew, GetJsonText(JsonObject, 'new'));
                if IsLineNew then begin
                    InsertSalesLineFromJsonObject(JsonObject)
                end
                else begin
                    UpdateSalesLineFromJsonObject(JsonObject);
                end;
            end;
            LineNosFromOrderInWS.Add(GetJsonText(JsonObject, 'lineNo'));
        end;

        //Se borran del pedido todas las que no están en LineNosFromOrderInWS
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        if SalesLine.FindSet() then
            repeat
                if (SalesLine.Status = SalesLine.Status::Sent) and not LineNosFromOrderInWS.Contains(Format(SalesLine."Line No.")) then
                    SalesLine.Delete();
            until SalesLine.Next() = 0;

        //Eliminar las líneas que ya se han procesado del web service
        foreach JsonToken in JsonArray do begin
            JsonObject := JsonToken.AsObject();
            Evaluate(IsLineReady, GetJsonText(JsonObject, 'ready'));
            if IsLineReady then begin
                URL := GetSentLinesBaseUrl() + '(' + GetJsonText(JsonObject, 'id') + ')';
                HttpRequests.DeleteJsonObject(URL);
            end;
        end;
    end;

    local procedure InsertSalesLineFromJsonObject(JsonObject: JsonObject)
    var
        SalesLine: Record "Sales Line";
        PurchasesSetup: Record "Purchases & Payables Setup";
        Item: Record Item;
        Quantity: Decimal;
        CreateItemLbl: Label 'Vendor %1 has added a line with the next item: %2. There is no registry for this item, do you want to create one? Otherwise the line will be ignored.';
    begin
        Item.SetRange("Vendor Item No.", GetJsonText(JsonObject, 'vendorItemNo'));
        Item.SetRange(Type, Item.Type::Inventory);
        if not Item.FindFirst() then begin
            //***
            PurchasesSetup.Get();
            if not Dialog.Confirm(CreateItemLbl, true, PurchasesSetup."Vendor Name", GetJsonText(JsonObject, 'description')) then
                exit;
            Item.Reset();
            InsertItem(Item, PurchasesSetup."Vendor No.", GetJsonText(JsonObject, 'vendorItemNo'), GetJsonText(JsonObject, 'description'));
        end;

        Evaluate(Quantity, GetJsonText(JsonObject, 'quantity'));
        InsertSalesLine(Item, GetJsonText(JsonObject, 'documentNo'), Quantity);
    end;

    local procedure UpdateSalesLineFromJsonObject(JsonObject: JsonObject)
    var
        SalesLine: Record "Sales Line";
        Item: Record Item;
        PurchasesSetup: Record "Purchases & Payables Setup";
        NewQuantity: Decimal;
    begin
        if SalesLine.Get(SalesLine."Document Type"::Order, GetJsonText(JsonObject, 'documentNo'), GetJsonText(JsonObject, 'lineNo')) then begin
            Evaluate(NewQuantity, GetJsonText(JsonObject, 'quantity'));
            if SalesLine.Quantity <> NewQuantity then
                SalesLine.Quantity := NewQuantity;

            Item.Get(SalesLine."No.");
            if Item."Vendor Item No." <> GetJsonText(JsonObject, 'vendorItemNo') then begin
                Item.Reset();
                Item.SetRange("Vendor Item No.", GetJsonText(JsonObject, 'vendorItemNo'));
                PurchasesSetup.Get();
                if Item.FindFirst() and (Item."Vendor No." = PurchasesSetup."Vendor No.") then begin
                    SalesLine."No." := Item."No.";
                    SalesLine.Description := Item.Description;
                end
                else begin
                    Item.Reset();
                    InsertItem(Item, PurchasesSetup."Vendor No.", GetJsonText(JsonObject, 'vendorItemNo'), GetJsonText(JsonObject, 'description'));
                    SalesLine."No." := Item."No.";
                end;
            end;
            SalesLine.Status := Status::Ready;
            SalesLine.Modify();
        end;
    end;

    //mercadería hardcoded?
    local procedure InsertItem(var Item: Record Item; VendorNo: Code[20]; VendorItemNo: Code[20]; Description: Text[100])
    var
        NoSeries: Codeunit "No. Series";
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        Item."No." := NoSeries.GetNextNo(InventorySetup."Item Nos.");
        Item."Vendor No." := VendorNo;
        Item."Gen. Prod. Posting Group" := 'MERCADERÍA';
        Item."Inventory Posting Group" := 'MERCADERÍA';
        Item.Type := Item.Type::Inventory;
        Item."Vendor Item No." := VendorItemNo;
        Item.Description := Description;
        Item."Search Description" := Text.UpperCase(Description);
        Item.Insert();
    end;

    local procedure InsertSalesLine(Item: Record Item; SalesHeaderNo: Code[20]; Quantity: Decimal)
    var
        LastLine: Record "Sales Line";
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.Get(SalesHeader."Document Type"::Order, SalesHeaderNo);
        LastLine.SetRange("Document No.", SalesHeaderNo);
        LastLine.SetRange("Document Type", SalesHeader."Document Type"::Order);

        if LastLine.FindLast() then
            SalesLine."Line No." := LastLine."Line No." + 10000;

        SalesLine.Init();
        SalesLine."Document No." := SalesHeaderNo;
        SalesLine."Document Type" := SalesLine."Document Type"::Order;
        SalesLine.Type := SalesLine.Type::Item;
        SalesLine.SetSalesHeader(SalesHeader);
        SalesLine."Unit of Measure Code" := Item."Base Unit of Measure";
        SalesLine."No." := Item."No.";
        SalesLine.Description := Item.Description;
        SalesLine.Status := Status::Ready;
        SalesLine.Validate(Quantity, Quantity);
        SalesLine.Insert();
    end;

    local procedure DeleteMissingSentLines(SalesHeaderNo: Code[20]; LineNosFromOrderInWS: List of [Text])
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document No.", SalesHeaderNo);
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        if SalesLine.FindSet() then
            repeat
                if (SalesLine.Status = SalesLine.Status::Sent) and not LineNosFromOrderInWS.Contains(Format(SalesLine."Line No.")) then begin
                    SalesLine.Delete();
                end;
            until SalesLine.Next() = 0;
    end;

    procedure RemoveHeaderFromWS(SalesHeaderNo: Code[20])
    var
        Url: Text;
        WebServiceId: Text;
        SentHeader: JsonObject;
    begin
        SentHeader := GetSentHeader(SalesHeaderNo);
        WebServiceId := GetJsonText(SentHeader, 'id');
        if WebServiceId = '' then
            exit;
        URL := GetSentHeadersBaseUrl() + '(' + WebServiceId + ')';
        HttpRequests.DeleteJsonObject(Url);
    end;

    procedure RemoveLineFromWS(SalesHeaderNo: Code[20]; LineNo: Integer)
    var
        URL: Text;
        SentLineWSId: Text;
        SentLine: JsonObject;
    begin
        SentLine := GetSentLine(SalesHeaderNo, LineNo);
        SentLineWSId := GetJsonText(SentLine, 'id');
        if SentLineWSId = '' then
            exit;
        URL := GetSentLinesBaseUrl() + '(' + SentLineWSId + ')';
        HttpRequests.DeleteJsonObject(Url);
    end;

    procedure GetSentLine(SalesHeaderNo: Code[20]; LineNo: Integer): JsonObject
    var
        HttpClient: HttpClient;
        HttpResponseMessage: HttpResponseMessage;
        JsonToken: JsonToken;
        JsonObject: JsonObject;
        JsonArray: JsonArray;
        JsonText: Text;
        URL: Text;
        SentLineId: Text[50];
        PurchasesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesSetup.Get();
        URL := GetSentLinesBaseUrl() + '/?$filter=documentNo eq ''' + SalesHeaderNo + ''' and lineNo eq ' + Format(LineNo) + ' and customerNo eq ''' + PurchasesSetup."Customer No." + '''';
        HttpRequests.GetJsonData(URL, HttpResponseMessage);

        HttpResponseMessage.Content.ReadAs(JsonText);
        if not JsonObject.ReadFrom(JsonText) then
            Error(ErrorInvalidResponseLbl);

        JsonObject.Get('value', JsonToken);
        JsonArray := JsonToken.AsArray();

        if JsonArray.Get(0, JsonToken) then begin
            JsonObject := JsonToken.AsObject();
            exit(JsonObject);
        end;
    end;

    procedure GetSentHeader(SalesHeaderNo: Code[20]): JsonObject
    var
        HttpClient: HttpClient;
        HttpResponseMessage: HttpResponseMessage;
        JsonToken: JsonToken;
        JsonObject: JsonObject;
        JsonArray: JsonArray;
        JsonText: Text;
        URL: Text;
        SentHeaderId: Text[50];
        PurchasesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesSetup.Get();
        URL := GetSentHeadersBaseUrl() + '/?$filter=no eq ''' + SalesHeaderNo + ''' and customerNo eq ''' + PurchasesSetup."Customer No." + '''';
        HttpRequests.GetJsonData(URL, HttpResponseMessage);

        HttpResponseMessage.Content.ReadAs(JsonText);
        if not JsonObject.ReadFrom(JsonText) then
            Error(ErrorInvalidResponseLbl);

        JsonObject.Get('value', JsonToken);
        JsonArray := JsonToken.AsArray();

        if JsonArray.Get(0, JsonToken) then begin
            JsonObject := JsonToken.AsObject();
            exit(JsonObject);
        end;
    end;

    procedure DeleteAll()
    var
        URL: Text;
        PurchasesSetup: Record "Purchases & Payables Setup";
        HttpResponseMessage: HttpResponseMessage;
        JsonObject: JsonObject;
        JsonToken: JsonToken;
        JsonArray: JsonArray;
        JsonText: Text;
        LineNo: Integer;
    begin
        PurchasesSetup.Get();

        //Borrar todas las líneas del cliente
        URL := GetSentLinesBaseUrl() + '/?$filter=customerNo eq ''' + PurchasesSetup."Customer No." + '''';
        HttpRequests.GetJsonData(URL, HttpResponseMessage);

        HttpResponseMessage.Content.ReadAs(JsonText);
        if not JsonObject.ReadFrom(JsonText) then
            Error(ErrorInvalidResponseLbl);

        JsonObject.Get('value', JsonToken);
        JsonArray := JsonToken.AsArray();
        foreach JsonToken in JsonArray do begin
            JsonObject := JsonToken.AsObject();
            Evaluate(LineNo, GetJsonText(JsonObject, 'lineNo'));
            RemoveLineFromWS(GetJsonText(JsonObject, 'documentNo'), LineNo);
        end;

        //Borrar todos los headers del cliente
        URL := GetSentHeadersBaseUrl() + '/?$filter=customerNo eq ''' + PurchasesSetup."Customer No." + '''';
        HttpRequests.GetJsonData(URL, HttpResponseMessage);

        HttpResponseMessage.Content.ReadAs(JsonText);
        if not JsonObject.ReadFrom(JsonText) then
            Error(ErrorInvalidResponseLbl);

        JsonObject.Get('value', JsonToken);
        JsonArray := JsonToken.AsArray();
        foreach JsonToken in JsonArray do begin
            JsonObject := JsonToken.AsObject();
            RemoveHeaderFromWS(GetJsonText(JsonObject, 'no'));
        end;
    end;

    local procedure GetSentHeadersBaseUrl(): Text
    var
        PurchasesSetup: Record "Purchases & Payables Setup";
        ErrorNoUrlLbl: Label 'Web service URL for sent headers needs to be set up first.';
    begin
        //***
        PurchasesSetup.Get();
        if PurchasesSetup."Vendor No." <> '' then begin
            if PurchasesSetup."Headers Web Service" = '' then
                Error(ErrorNoUrlLbl);
            exit(PurchasesSetup."Headers Web Service");
        end;
    end;

    local procedure GetSentLinesBaseUrl(): Text
    var
        PurchasesSetup: Record "Purchases & Payables Setup";
        ErrorNoUrlLbl: Label 'Web service URL for sent lines needs to be set up first.';
    begin
        //***
        PurchasesSetup.Get();
        if PurchasesSetup."Vendor No." <> '' then begin
            if PurchasesSetup."Lines Web Service" = '' then
                Error(ErrorNoUrlLbl);
            exit(PurchasesSetup."Lines Web Service");
        end;
    end;

    procedure CheckIfPostIsAllowed(SalesHeaderNo: Code[20]; IsFromExclusiveVendor: Boolean)
    var
        PurchasesSetup: Record "Purchases & Payables Setup";
        ErrorNotReadyLbl: Label 'All the sales lines from this order need to be ready before posting.';
    begin
        //***
        PurchasesSetup.Get();
        if PurchasesSetup."Vendor No." <> '' then begin
            if IsFromExclusiveVendor and not IsOrderReady(SalesHeaderNo) then
                Error(ErrorNotReadyLbl);
        end;
    end;

    local procedure IsOrderReady(SalesHeaderNo: Code[20]): Boolean
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document No.", SalesHeaderNo);
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        if SalesLine.FindSet() then
            repeat
                if SalesLine.Status <> SalesLine.Status::Ready then
                    exit(false);
            until SalesLine.Next() = 0;
        exit(true);
    end;

    procedure ChangeDocumentStatus(SalesHeaderNo: Code[20])
    var
        Url: Text;
        JsonText: Text;
        NewHeader: JsonObject;
        OldHeader: JsonObject;
        SystemId: Text;
        OdataEtag: Text;
    begin
        OldHeader := GetSentHeader(SalesHeaderNo);
        SystemId := GetJsonText(OldHeader, 'id');
        OdataEtag := GetJsonText(OldHeader, '@odata.etag');

        NewHeader.Add('documentStatus', '1');
        NewHeader.WriteTo(JsonText);
        URL := GetSentHeadersBaseUrl() + '(' + SystemId + ')';

        HttpRequests.Patch(Url, JsonText, OdataEtag);
    end;

    local procedure SalesHeaderToJsonText(SalesHeaderNo: Code[20]): Text
    var
        JsonObject: JsonObject;
        JsonText: Text;
        Item: Record Item;
        PurchasesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesSetup.Get();
        JsonObject.Add('no', SalesHeaderNo);
        JsonObject.Add('documentStatus', '0');
        JsonObject.Add('customerNo', PurchasesSetup."Customer No.");
        JsonObject.WriteTo(JsonText);
        exit(JsonText);
    end;

    local procedure SalesLineToJsonText(SalesLine: Record "Sales Line"): Text
    var
        JsonObject: JsonObject;
        JsonText: Text;
        Item: Record Item;
        PurchasesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesSetup.Get();
        if not Item.Get(SalesLine."No.") then
            exit;
        JsonObject.Add('documentNo', SalesLine."Document No.");
        JsonObject.Add('lineNo', SalesLine."Line No.");
        JsonObject.Add('no', SalesLine."No.");
        JsonObject.Add('description', SalesLine.Description);
        JsonObject.Add('quantity', SalesLine.Quantity);
        JsonObject.Add('vendorItemNo', Item."Vendor Item No.");
        JsonObject.Add('ready', false);
        //JsonObject.Add('vendorLineNo', 0);
        JsonObject.Add('new', false);
        JsonObject.Add('customerNo', PurchasesSetup."Customer No.");

        JsonObject.WriteTo(JsonText);
        exit(JsonText);
    end;

    local procedure GetJsonText(JsonObject: JsonObject; TokenKey: Text): Text
    var
        JsonToken: JsonToken;
        ErrorTokenNotFoundLbl: Label 'Could not find a token with key %1';
    begin
        if not JsonObject.Get(TokenKey, JsonToken) then
            Error(ErrorTokenNotFoundLbl, TokenKey);
        exit(JsonToken.AsValue().AsText());
    end;

    var
        HttpRequests: Codeunit "Prepared HTTP Requests";
        ErrorInvalidResponseLbl: Label 'Invalid response, expected a JSON object as root object.';
        ErrorNotConfiguredLbl: Label 'Vendor No. and Customer No. need to be configured first from page Purchases & Payables Setup.';

    /*
    *patch no funciona, cuestión de permisos?: 'No se puede realizar la operación solicitada en este contexto.'.
    *batch requests
    */
}
