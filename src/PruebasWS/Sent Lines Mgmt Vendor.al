codeunit 60252 "Sent Lines Mgmt"
{
    procedure InsertSentLines(SalesHeaderNo: Code[20])
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document No.", SalesHeaderNo);
        if SalesLine.FindSet() then
            repeat
                SalesLine.Status := Status::Sent;
                SalesLine.Insert();
            until SalesLine.Next() = 0;
    end;


    /* procedure CloneCustomer(CustomerNo: Code[20])
    var
        Customer: Record Customer;
        NewCustomer: Record Customer;
    begin
        Customer.Get(CustomerNo);
        NewCustomer.Init();
        NewCustomer.TransferFields(Customer, false);
        NewCustomer.Name := 'WS Test Customer';
        NewCustomer.Insert(true);
    end;

    procedure GetSalesAmount(CustomerNo: Code[20]): Decimal
    var
        SalesLine: Record "Sales Line";
        Total: Decimal;
    begin
        SalesLine.SetRange("Document Type", SalesLine."Document Type");
        SalesLine.SetRange("Sell-to Customer No.", CustomerNo);
        SalesLine.SetFilter(Type, '<>%1', SalesLine.Type::" ");
        if SalesLine.FindSet() then
            repeat
                Total += SalesLine."Line Amount";
            until SalesLine.Next() = 0;
        exit(Total);
    end; */

    procedure Post(URL: Text; JsonText: Text)
    var
        HttpRequestMessage: HttpRequestMessage;
        HttpResponseMessage: HttpResponseMessage;
        HttpContent: HttpContent;
        HttpContentHeaders: HttpHeaders;
        HttpClient: HttpClient;
    begin
        //Se necesita autentificación?
        HttpContent.WriteFrom(JsonText);
        HttpContent.GetHeaders(HttpContentHeaders);
        HttpContentHeaders.Remove('Content-Type');
        HttpContentHeaders.Add('Content-Type', 'application/json');
        HttpRequestMessage.Content := HttpContent;
        HttpRequestMessage.SetRequestUri(URL);
        HttpRequestMessage.Method := 'POST';
        HttpClient.Send(HttpRequestMessage, HttpResponseMessage);
    end;

    local procedure SalesLineToJsonText(SalesLine: Record "Sales Line"): Text
    var
        JsonObject: JsonObject;
        JsonText: Text;
        Item: Record Item;
    begin
        if Item.Get(SalesLine."No.") then begin
            JsonObject.Add('documentNo', SalesLine."Document No.");
            JsonObject.Add('lineNo', SalesLine."Line No.");
            JsonObject.Add('no', SalesLine."No.");
            JsonObject.Add('description', SalesLine.Description);
            JsonObject.Add('quantity', SalesLine.Quantity);
            JsonObject.Add('vendorItemNo', Item."Vendor Item No.");
            JsonObject.WriteTo(JsonText);
            exit(JsonText);
        end;
    end;

    procedure Inform(SalesHeaderNo: Code[20])
    var
        SalesLine: Record "Sales Line";
        JsonText: Text;
        URL: Text;
    begin
        URL := 'http://version24:7048/BC/ODataV4/Company(''CRONUS%20ES'')/MyCustomerCard';
        JsonText := SalesLineToJsonText(SalesLine);
        Post(URL, JsonText);
    end;

    local procedure ReadLines(var SalesLine: Record "Sales Line")
    var
        HttpClient: HttpClient;
        ResponseMessage: HttpResponseMessage;
        RequestMessage: HttpRequestMessage;
        RequestHeaders: HttpHeaders;
        JsonToken: JsonToken;
        JsonValue: JsonValue;
        JsonObject: JsonObject;
        JsonArray: JsonArray;
        JsonText: Text;
        Base64Convert: Codeunit "Base64 Convert";
    begin
        RequestMessage.GetHeaders(RequestHeaders);
        RequestHeaders.Add('Authorization', 'Basic ' + Base64Convert.ToBase64(Username + ':' + Password))
        //https://www.kauffmann.nl/2017/06/24/al-support-for-rest-web-services/
    end;

    var
        username: Text;
        password: Text;
}