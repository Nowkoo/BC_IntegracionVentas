codeunit 60251 "Web Service Mgmt"
{
    procedure Inform(SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        if SalesLine.FindSet() then
            repeat
                //escribir en ws
                Post();

                SalesLine.Status := Status::Sent;
                SalesLine.Modify();
            until SalesLine.Next() = 0;
    end;

    // http://version24:7048/BC/ODataV4/Company('CRONUS%20ES')/SalesOrdersWS
    local procedure Post()
    var
        HttpClient: HttpClient;
        HttpContent: HttpContent;
        ContentHeaders: HttpHeaders;
        ResponseMessage: HttpResponseMessage;

        JsonToken: JsonToken;
        JsonValue: JsonValue;
        JsonObject: JsonObject;
        JsonText: Text;
    begin
        HttpContent.GetHeaders(ContentHeaders);
        ContentHeaders.Clear();

        if not HttpClient.Post('http://version24:7048/BC/ODataV4/Company(''CRONUS%20ES'')/SalesOrdersWS', HttpContent, ResponseMessage) then
            Error('no post');

        if not ResponseMessage.IsSuccessStatusCode then
            Error('The web service returned an error message:\\' +
                'Status Code: %1\' +
                'Description: %2',
                ResponseMessage.HttpStatusCode,
                ResponseMessage.ReasonPhrase);

        ResponseMessage.Content().ReadAs(JsonText);
        Message(JsonText);
    end;
}