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
        JsonObject: JsonObject;
    begin
        //Post del header
        if GetSentHeaderWebServiceId(SalesHeaderNo) = '' then begin
            JsonText := SalesHeaderToJsonText(SalesHeaderNo);
            Url := GetSentHeadersBaseUrl();
            Post(Url, JsonText);
        end;

        //Post de las líneas
        SalesLine.SetRange("Document No.", SalesHeaderNo);
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        if SalesLine.FindSet() then
            repeat
                if SalesLine.Status = SalesLine.Status::Pending then begin
                    JsonText := SalesLineToJsonText(SalesLine);
                    Url := GetSentLinesBaseUrl();
                    Post(Url, JsonText);

                    SalesLine.Status := Status::Sent;
                    SalesLine.Modify();
                end;
            until SalesLine.Next() = 0;
    end;

    procedure RemoveHeaderFromWS(SalesHeaderNo: Code[20])
    var
        Url: Text;
        WebServiceId: Text;
    begin
        WebServiceId := GetSentHeaderWebServiceId(SalesHeaderNo);
        if WebServiceId = '' then
            exit;
        URL := GetSentHeadersBaseUrl() + '(' + WebServiceId + ')';
        Delete(Url);
    end;

    local procedure Delete(URL: Text)
    var
        HttpClient: HttpClient;
        HttpResponseMessage: HttpResponseMessage;
    begin
        AddHttpBasicAuthHeader('admin', 'P@ssword01', HttpClient);

        if not HttpClient.Delete(URL, HttpResponseMessage) then
            Error(ErrorCallFailedLbl);

        if not HttpResponseMessage.IsSuccessStatusCode then
            Error(ErrorWSLbl, HttpResponseMessage.HttpStatusCode, HttpResponseMessage.ReasonPhrase);
    end;

    procedure ChangeDocumentStatus(SalesHeaderNo: Code[20])
    var
        Url: Text;
        JsonText: Text;
        JsonObject: JsonObject;
    begin
        JsonObject.Add('documentStatus', 1);
        JsonObject.WriteTo(JsonText);
        URL := GetSentHeadersBaseUrl() + '(' + SalesHeaderNo + ')';
        Patch(Url, JsonText);
    end;

    local procedure Patch(URL: Text; JsonText: Text)
    var
        HttpRequestMessage: HttpRequestMessage;
        HttpResponseMessage: HttpResponseMessage;
        HttpContent: HttpContent;
        HttpContentHeaders: HttpHeaders;
        HttpClient: HttpClient;
    begin
        AddHttpBasicAuthHeader('admin', 'P@ssword01', HttpClient);
        HttpContent.WriteFrom(JsonText);
        HttpContent.GetHeaders(HttpContentHeaders);
        HttpContentHeaders.Remove('Content-Type');
        HttpContentHeaders.Add('Content-Type', 'application/json');
        HttpRequestMessage.Content := HttpContent;
        HttpRequestMessage.SetRequestUri(URL);
        HttpRequestMessage.Method := 'PATCH';

        if not HttpClient.Send(HttpRequestMessage, HttpResponseMessage) then
            Error(ErrorCallFailedLbl);

        if not HttpResponseMessage.IsSuccessStatusCode then
            Error(ErrorWSLbl, HttpResponseMessage.HttpStatusCode, HttpResponseMessage.ReasonPhrase);
    end;

    local procedure Post(URL: Text; JsonText: Text)
    var
        HttpRequestMessage: HttpRequestMessage;
        HttpResponseMessage: HttpResponseMessage;
        HttpContent: HttpContent;
        HttpContentHeaders: HttpHeaders;
        HttpClient: HttpClient;
    begin
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

    local procedure SalesHeaderToJsonText(SalesHeaderNo: Code[20]): Text
    var
        JsonObject: JsonObject;
        JsonText: Text;
        Item: Record Item;
    begin
        JsonObject.Add('no', SalesHeaderNo);
        JsonObject.Add('customerName', Database.CompanyName);
        JsonObject.Add('documentStatus', '0');
        JsonObject.WriteTo(JsonText);
        exit(JsonText);
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

    local procedure GetSentHeadersBaseUrl(): Text
    var
        ExclusiveVendor: Record "Exclusive Vendor";
        ErrorNoUrlLbl: Label 'Web service URL for sent headers needs to be set up first.';
    begin
        if ExclusiveVendor.Get() then begin
            if ExclusiveVendor."Headers Web Service" = '' then
                Error(ErrorNoUrlLbl);
            exit(ExclusiveVendor."Headers Web Service");
        end;
    end;

    local procedure GetSentLinesBaseUrl(): Text
    var
        ExclusiveVendor: Record "Exclusive Vendor";
        ErrorNoUrlLbl: Label 'Web service URL for sent lines needs to be set up first.';
    begin
        if ExclusiveVendor.Get() then begin
            if ExclusiveVendor."Lines Web Service" = '' then
                Error(ErrorNoUrlLbl);
            exit(ExclusiveVendor."Lines Web Service");
        end;
    end;

    //Sacado de https://www.kauffmann.nl/2017/06/24/al-support-for-rest-web-services/
    local procedure Get(URL: Text; var HttpResponseMessage: HttpResponseMessage): Text
    var
        HttpClient: HttpClient;
        JsonText: Text;
    begin
        AddHttpBasicAuthHeader('admin', 'P@ssword01', HttpClient);
        if not HttpClient.Get(URL, HttpResponseMessage) then
            Error(ErrorCallFailedLbl);

        if not HttpResponseMessage.IsSuccessStatusCode then
            Error(ErrorWSLbl, HttpResponseMessage.HttpStatusCode, HttpResponseMessage.ReasonPhrase);

        HttpResponseMessage.Content.ReadAs(JsonText);
        exit(JsonText);
    end;

    procedure PrepareLines(SalesHeaderNo: Code[20])
    var
        HttpResponseMessage: HttpResponseMessage;
        JsonToken: JsonToken;
        JsonObject: JsonObject;
        JsonArray: JsonArray;
        JsonText: Text;
        LineNosFromOrderInWS: List of [Text];
        LineNoText: Text;
        IsLineReady: Boolean;
        URL: Text;
    begin
        //	/?$filter=documentNo eq '101012' and ready eq true
        URL := GetSentLinesBaseUrl() + '/?$filter=documentNo eq ''' + SalesHeaderNo + '''';
        Get(URL, HttpResponseMessage);

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
                if GetJsonText(JsonObject, 'lineNo') = '0' then
                    InsertSalesLineFromJsonObject(JsonObject)
                else begin
                    UpdateSalesLineFromJsonObject(JsonObject);
                end;
            end;
            LineNosFromOrderInWS.Add(GetJsonText(JsonObject, 'lineNo'));
        end;

        //Se borran del pedido todas las que no están en LineNosFromOrderInWS
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
        URL: Text;
    begin
        URL := GetSentLinesBaseUrl() + '(' + id + ')';
        Delete(URL);
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

    procedure GetSentLineWebServiceId(SalesHeaderNo: Code[20]; LineNo: Integer): Text
    var
        HttpClient: HttpClient;
        HttpResponseMessage: HttpResponseMessage;
        JsonToken: JsonToken;
        JsonObject: JsonObject;
        JsonArray: JsonArray;
        JsonText: Text;
        URL: Text;
        SentLineId: Text[50];
    begin
        URL := GetSentLinesBaseUrl() + '/?$filter=documentNo eq ''' + SalesHeaderNo + ''' and lineNo eq ' + Format(LineNo);
        Get(URL, HttpResponseMessage);

        HttpResponseMessage.Content.ReadAs(JsonText);
        if not JsonObject.ReadFrom(JsonText) then
            Error(ErrorInvalidResponseLbl);

        JsonObject.Get('value', JsonToken);
        JsonArray := JsonToken.AsArray();

        if JsonArray.Get(0, JsonToken) then begin
            JsonObject := JsonToken.AsObject();
            SentLineId := GetJsonText(JsonObject, 'id');
            exit(SentLineId);
        end;
    end;

    procedure GetSentHeaderWebServiceId(SalesHeaderNo: Code[20]): Text
    var
        HttpClient: HttpClient;
        HttpResponseMessage: HttpResponseMessage;
        JsonToken: JsonToken;
        JsonObject: JsonObject;
        JsonArray: JsonArray;
        JsonText: Text;
        URL: Text;
        SentHeaderId: Text[50];
    begin
        URL := GetSentHeadersBaseUrl() + '/?$filter=no eq ''' + SalesHeaderNo + '''';
        Get(URL, HttpResponseMessage);

        HttpResponseMessage.Content.ReadAs(JsonText);
        if not JsonObject.ReadFrom(JsonText) then
            Error(ErrorInvalidResponseLbl);

        JsonObject.Get('value', JsonToken);
        JsonArray := JsonToken.AsArray();

        if JsonArray.Get(0, JsonToken) then begin
            JsonObject := JsonToken.AsObject();
            SentHeaderId := GetJsonText(JsonObject, 'id');
            exit(SentHeaderId);
        end;
    end;

    var
        Username: Text;
        Password: Text;
        ErrorCallFailedLbl: Label 'The call to the web service failed.';
        ErrorWSLbl: Label 'The web service returned an error message:\\Status Code: %1\Description: %2';
        ErrorInvalidResponseLbl: Label 'Invalid response, expected a JSON object as root object.';

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
    *Revisar InsertSalesLineFromJsonObject. Si el vendor item no es de otro proveedor qué
    *Las sent lines insertadas por el proveedor tienen el documentNo vacío por lo que el cliente no las recibe.
    */
}
