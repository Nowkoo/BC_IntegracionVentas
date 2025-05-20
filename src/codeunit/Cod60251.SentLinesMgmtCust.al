//https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/webservices/web-services-authentication
codeunit 60251 "Sent Lines Mgmt Cust"
{
    procedure CheckIfPostIsAllowed(SalesHeaderNo: Code[20]; IsFromExclusiveVendor: Boolean)
    var
        ExclusiveVendor: Record "Exclusive Vendor";
        ErrorNotReadyLbl: Label 'All the sales lines from this order need to be ready before posting.';
    begin
        if ExclusiveVendor.Get() then begin
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

    procedure Inform(SalesHeaderNo: Code[20])
    var
        SalesLine: Record "Sales Line";
        JsonText: Text;
        Url: Text;
    begin
        SalesLine.SetRange("Document No.", SalesHeaderNo);
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        if SalesLine.FindSet() then
            repeat
                if SalesLine.Status = SalesLine.Status::Pending then begin
                    JsonText := SalesLineToJsonText(SalesLine);
                    Url := GetUrl();
                    Post(Url, JsonText);

                    SalesLine.Status := Status::Sent;
                    SalesLine.Modify();
                end;
            until SalesLine.Next() = 0;
    end;

    local procedure Post(URL: Text; JsonText: Text)
    var
        HttpRequestMessage: HttpRequestMessage;
        HttpResponseMessage: HttpResponseMessage;
        HttpContent: HttpContent;
        HttpContentHeaders: HttpHeaders;
        HttpClient: HttpClient;
    begin
        //Añadir autentificación a content headers
        AddHttpBasicAuthHeader('admin', 'P@ssword01', HttpClient);
        HttpContent.WriteFrom(JsonText);
        HttpContent.GetHeaders(HttpContentHeaders);
        HttpContentHeaders.Remove('Content-Type');
        HttpContentHeaders.Add('Content-Type', 'application/json');
        HttpRequestMessage.Content := HttpContent;
        HttpRequestMessage.SetRequestUri(URL);
        HttpRequestMessage.Method := 'POST';

        if not HttpClient.Send(HttpRequestMessage, HttpResponseMessage) then
            Error(ErrorCallFailedLbl);

        if not HttpResponseMessage.IsSuccessStatusCode then
            Error(ErrorWSLbl, HttpResponseMessage.HttpStatusCode, HttpResponseMessage.ReasonPhrase);
    end;

    local procedure SalesLineToJsonText(SalesLine: Record "Sales Line"): Text
    var
        JsonObject: JsonObject;
        JsonText: Text;
        Item: Record Item;
    begin
        if not Item.Get(SalesLine."No.") then
            exit;
        JsonObject.Add('documentNo', SalesLine."Document No.");
        JsonObject.Add('lineNo', SalesLine."Line No.");
        JsonObject.Add('no', SalesLine."No.");
        JsonObject.Add('description', SalesLine.Description);
        JsonObject.Add('quantity', SalesLine.Quantity);
        JsonObject.Add('vendorItemNo', Item."Vendor Item No.");
        JsonObject.Add('ready', false);
        JsonObject.WriteTo(JsonText);
        exit(JsonText);
    end;

    local procedure GetUrl(): Text
    var
        ExclusiveVendor: Record "Exclusive Vendor";
    begin
        if ExclusiveVendor.Get() then
            exit(ExclusiveVendor."Vendor Web Service");
    end;

    //Sacado de https://www.kauffmann.nl/2017/06/24/al-support-for-rest-web-services/
    procedure PrepareLines(SalesHeaderNo: Code[20])
    var
        HttpClient: HttpClient;
        HttpResponseMessage: HttpResponseMessage;
        HttpRequestMessage: HttpRequestMessage;
        HttpRequestHeaders: HttpHeaders;

        JsonToken: JsonToken;
        JsonValue: JsonValue;
        JsonObject: JsonObject;
        JsonArray: JsonArray;
        JsonText: Text;

        LineNosFromOrderInWS: List of [Text];
        LineNoText: Text;
        IsLineReady: Boolean;
        URL: Text;

        ErrorInvalidResponseLbl: Label 'Invalid response, expected a JSON object as root object.';
    begin
        AddHttpBasicAuthHeader('admin', 'P@ssword01', HttpClient);
        //	/?$filter=documentNo eq '101012' and ready eq true
        //	/?$filter=documentNo eq '%1' and ready eq %2
        URL := GetUrl() + '/?$filter=documentNo eq ''' + SalesHeaderNo + '''';
        if not HttpClient.Get(URL, HttpResponseMessage) then
            Error(ErrorCallFailedLbl);

        if not HttpResponseMessage.IsSuccessStatusCode then
            Error(ErrorWSLbl, HttpResponseMessage.HttpStatusCode, HttpResponseMessage.ReasonPhrase);

        HttpResponseMessage.Content.ReadAs(JsonText);
        if not JsonObject.ReadFrom(JsonText) then
            Error(ErrorInvalidResponseLbl);

        JsonObject.Get('value', JsonToken);
        JsonArray := JsonToken.AsArray();

        foreach JsonToken in JsonArray do begin
            JsonObject := JsonToken.AsObject();
            Evaluate(IsLineReady, GetJsonText(JsonObject, 'ready'));

            if IsLineReady then begin
                //Si lineNo está vacío es una nueva línea creada por el proveedor
                if GetJsonText(JsonObject, 'lineNo') = '' then
                    InsertSalesLineFromJsonObject(JsonObject)
                else begin
                    UpdateSalesLineFromJsonObject(JsonObject);
                end;
            end;
            LineNosFromOrderInWS.Add(GetJsonText(JsonObject, 'lineNo'));
        end;

        //Se borran todas las que no están en LineNosFromOrderInWS
        DeleteMissingSentLines(SalesHeaderNo, LineNosFromOrderInWS);

        //Eliminar las líneas que ya se han procesado del web service
        foreach JsonToken in JsonArray do begin
            JsonObject := JsonToken.AsObject();
            Evaluate(IsLineReady, GetJsonText(JsonObject, 'ready'));
            if IsLineReady then
                RemoveLineFromWS(GetJsonText(JsonObject, 'id'));
        end;
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

    local procedure GetJsonText(JsonObject: JsonObject; TokenKey: Text): Text
    var
        JsonToken: JsonToken;
        ErrorTokenNotFoundLbl: Label 'Could not find a token with key %1';
    begin
        if not JsonObject.Get(TokenKey, JsonToken) then
            Error(ErrorTokenNotFoundLbl, TokenKey);
        exit(JsonToken.AsValue().AsText());
    end;

    local procedure InsertSalesLineFromJsonObject(JsonObject: JsonObject)
    var
        SalesLine: Record "Sales Line";
        ExclusiveVendor: Record "Exclusive Vendor";
        Item: Record Item;
        Quantity: Decimal;
        CreateItemLbl: Label 'Vendor %1 has added a line with the next item: %2. There is no registry for this item, do you want to create one? Otherwise the line will be ignored.';
    begin
        Item.SetRange("Vendor Item No.", GetJsonText(JsonObject, 'vendorItemNo'));
        Item.SetRange(Type, Item.Type::Inventory);
        if not Item.FindFirst() then begin
            ExclusiveVendor.Get();
            if not Dialog.Confirm(CreateItemLbl, true, ExclusiveVendor."Vendor Name", GetJsonText(JsonObject, 'description')) then
                exit;
            Item.Reset();
            InsertItem(Item, ExclusiveVendor."Vendor No", GetJsonText(JsonObject, 'vendorItemNo'), GetJsonText(JsonObject, 'description'));
        end;

        Evaluate(Quantity, GetJsonText(JsonObject, 'quantity'));
        InsertSalesLine(Item."No.", GetJsonText(JsonObject, 'documentNo'), Quantity);
    end;

    local procedure InsertItem(var Item: Record Item; VendorNo: Code[20]; VendorItemNo: Code[20]; Description: Code[20])
    begin
        Item."Vendor No." := VendorNo;
        Item.Type := Item.Type::Inventory;
        Item."Vendor Item No." := VendorItemNo;
        Item.Description := Description;
        Item."Search Description" := Text.UpperCase(Description);
        Item.Insert();
    end;

    local procedure InsertSalesLine(ItemNo: Code[20]; SalesHeaderNo: Code[20]; Quantity: Decimal)
    var
        LastLine: Record "Sales Line";
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.Get(SalesHeader."Document Type"::Order, SalesHeaderNo);
        if LastLine.FindLast() then begin
            SalesLine.AddItem(LastLine, ItemNo);

            //Buscamos la línea que acabamos de insertar
            SalesLine.Reset();
            SalesLine.SetRange("Document No.", SalesHeader."No.");
            SalesLine.SetRange("Document Type", SalesHeader."Document Type"::Order);
            SalesLine.FindLast();
        end
        else
            SalesLine.AddItem(SalesLine, ItemNo);

        SalesLine.Status := Status::Ready;
        SalesLine.Validate(Quantity, Quantity);
        SalesLine.Modify();
    end;

    local procedure UpdateSalesLineFromJsonObject(JsonObject: JsonObject)
    var
        SalesLine: Record "Sales Line";
        NewQuantity: Decimal;
    begin
        if SalesLine.Get(SalesLine."Document Type"::Order, GetJsonText(JsonObject, 'documentNo'), GetJsonText(JsonObject, 'lineNo')) then begin
            Evaluate(NewQuantity, GetJsonText(JsonObject, 'quantity'));
            if SalesLine.Quantity <> NewQuantity then begin
                SalesLine.Quantity := NewQuantity;
            end;
        end;
        SalesLine.Status := Status::Ready;
        SalesLine.Modify();
    end;

    procedure RemoveLineFromWS(id: Text)
    var
        HttpClient: HttpClient;
        HttpResponseMessage: HttpResponseMessage;
        URL: Text;
    begin
        URL := GetUrl() + '(' + id + ')';
        AddHttpBasicAuthHeader('admin', 'P@ssword01', HttpClient);

        if not HttpClient.Delete(URL, HttpResponseMessage) then
            Error(ErrorCallFailedLbl);

        if not HttpResponseMessage.IsSuccessStatusCode then
            Error(ErrorWSLbl, HttpResponseMessage.HttpStatusCode, HttpResponseMessage.ReasonPhrase);
    end;

    procedure AddHttpBasicAuthHeader(UserName: Text[50]; Password: Text[50]; var HttpClient: HttpClient);
    var
        AuthString: Text;
        Base64Convert: Codeunit "Base64 Convert";
    begin
        AuthString := STRSUBSTNO('%1:%2', UserName, Password);
        AuthString := Base64Convert.ToBase64(AuthString);
        AuthString := STRSUBSTNO('Basic %1', AuthString);
        HttpClient.DefaultRequestHeaders().Add('Authorization', AuthString);
    end;

    var
        Username: Text;
        Password: Text;
        ErrorCallFailedLbl: Label 'The call to the web service failed.';
        ErrorWSLbl: Label 'The web service returned an error message:\\Status Code: %1\Description: %2';

    /*

    Estados cliente:
        - pendiente (nuevas líneas sin informar, o si modifico una línea después de haber informado)
        - enviada (cuando se informa)
        - preparada (si es una línea modificada o añadida por el proveedor)

    Si el cliente modifica una línea que había sido informada: eliminar línea del web service (se tendrá que volver a informar).
    Si el proveedor crea nuevas líneas: deja el line no en blanco y pone su No. del ítem como Vendor Item No.

    Estados proveedor:
        - sin estado (línea recién recibida)
        - modificada (si cambio la cantidad de una línea)
        - nueva (si creo una nueva línea)
        - eliminada

    El proveedor tiene acción Finalizar para marcar líneas como preparadas (campo "ready" booleano).
    Cuando se finaliza el pedido se aplican los cambios al WS.

    Consultar web service:
    Por cada JSON object (línea de pedido) se hace get de la línea equivalente. Si se encuentra y hay cambios, se aplican.
    Si hay líneas que no se encuentran, se eliminan del pedido.
    Si hay líneas con el line no vacío, se insertan porque significa que son nuevas líneas.

    El cliente solo puede consultar las líneas que el proveedor ha marcado como preparadas.

    Si el estado de la línea es enviado, no se permite enviar otra vez.
    Si la línea se modifica y pasa de enviada a preparada, se elimina del WS.

    *Extender subform para que se vea el estado de cada línea
    *La url del borrado no es correcta.
    *Cuando el cliente consulta y elimina las líneas consultadas, la lista del proveedor no se actualiza.
    *Cuando el cliente borra una línea, eliminarla del web service.
    *Cuando no se marcan las líneas como preparadas y se consultan, a veces se eliminan las líneas locales
    *Añadir document no en sent lines del proveedor
    *Visualización del Vendor Item No. al insertar nuevas líneas en sent lines del proveedor
    *Revisar InsertSalesLineFromJsonObject. Si el vendor item no es del otro proveedor qué
    */
}
