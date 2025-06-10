//Solicitudes HTTP con autorización y control de errores.
codeunit 60252 "Prepared HTTP Requests"
{
    //Sacado de https://www.kauffmann.nl/2017/06/24/al-support-for-rest-web-services/
    procedure GetJsonData(URL: Text; var HttpResponseMessage: HttpResponseMessage): Text
    var
        HttpClient: HttpClient;
        JsonText: Text;
    begin
        AddHttpBasicAuthHeader(HttpClient);
        if not HttpClient.Get(URL, HttpResponseMessage) then
            Error(ErrorCallFailedLbl);

        if not HttpResponseMessage.IsSuccessStatusCode then
            Error(ErrorWSLbl, HttpResponseMessage.HttpStatusCode, HttpResponseMessage.ReasonPhrase);

        HttpResponseMessage.Content.ReadAs(JsonText);
        exit(JsonText);
    end;

    procedure PostJsonObject(URL: Text; JsonText: Text)
    var
        HttpRequestMessage: HttpRequestMessage;
        HttpResponseMessage: HttpResponseMessage;
        HttpContent: HttpContent;
        HttpContentHeaders: HttpHeaders;
        HttpClient: HttpClient;
    begin
        AddHttpBasicAuthHeader(HttpClient);
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

    procedure DeleteJsonObject(URL: Text)
    var
        HttpClient: HttpClient;
        HttpResponseMessage: HttpResponseMessage;
    begin
        AddHttpBasicAuthHeader(HttpClient);

        if not HttpClient.Delete(URL, HttpResponseMessage) then
            Error(ErrorCallFailedLbl);

        if not HttpResponseMessage.IsSuccessStatusCode then
            Error(ErrorWSLbl, HttpResponseMessage.HttpStatusCode, HttpResponseMessage.ReasonPhrase);
    end;

    procedure Patch(URL: Text; JsonText: Text; OdataEtag: Text)
    var
        HttpRequestMessage: HttpRequestMessage;
        HttpResponseMessage: HttpResponseMessage;
        HttpContent: HttpContent;
        HttpContentHeaders: HttpHeaders;
        HttpClient: HttpClient;
        t: SecretText;
    begin
        AddHttpBasicAuthHeader(HttpClient);
        HttpContent.GetHeaders(HttpContentHeaders);

        if HttpContentHeaders.Contains('Content-Type') then HttpContentHeaders.Remove('Content-Type');
        HttpContentHeaders.Add('Content-Type', 'application/json');

        if HttpContentHeaders.Contains('Content-Encoding') then HttpContentHeaders.Remove('Content-Encoding');
        HttpContentHeaders.Add('Content-Encoding', 'UTF8');

        //HttpContentHeaders.Add('If-Match', OdataEtag);
        HttpContentHeaders.Add('If-Match', '*');

        HttpContent.WriteFrom(JsonText);
        HttpRequestMessage.SetRequestUri(URL);
        HttpRequestMessage.Method := 'PATCH';
        HttpRequestMessage.Content := HttpContent;

        if not HttpClient.Send(HttpRequestMessage, HttpResponseMessage) then
            Error(ErrorCallFailedLbl);

        if not HttpResponseMessage.IsSuccessStatusCode then
            Error(ErrorWSLbl, HttpResponseMessage.HttpStatusCode, HttpResponseMessage.ReasonPhrase);
    end;

    procedure AddHttpBasicAuthHeader(var HttpClient: HttpClient);
    var
        AuthString: SecretText;
        Base64Convert: Codeunit "Base64 Convert";
        PurchasesSetup: Record "Purchases & Payables Setup";
        UserName: SecretText;
        Password: SecretText;
    begin
        PurchasesSetup.Get();
        UserName := PurchasesSetup.GetUsername(PurchasesSetup."WS Username");
        Password := PurchasesSetup.GetPassword(PurchasesSetup."WS Password");
        AuthString := SecretStrSubstNo('%1:%2', UserName, Password);
        AuthString := Base64Convert.ToBase64(AuthString);
        AuthString := SecretStrSubstNo('Basic %1', AuthString);
        HttpClient.DefaultRequestHeaders().Add('Authorization', AuthString);
    end;

    var
        ErrorCallFailedLbl: Label 'The call to the web service failed.';
        ErrorWSLbl: Label 'The web service returned an error message:\\Status Code: %1\Description: %2';
}