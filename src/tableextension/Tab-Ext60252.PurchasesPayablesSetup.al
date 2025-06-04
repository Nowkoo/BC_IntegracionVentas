tableextension 60252 "Purchases & Payables Setup" extends "Purchases & Payables Setup"
{
    fields
    {
        field(354; "Vendor No."; Code[20])
        {
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
                Vendor: Record Vendor;
                SentLinesMgmt: Codeunit "Sent Lines Mgmt Cust";
                DeleteVendorDataLbl: Label 'If you change vendor all the data from the current vendor will be deleted from the web service. Are you sure you want to change vendor?';
            begin
                if xRec."Vendor No." <> '' then begin
                    if Dialog.Confirm(DeleteVendorDataLbl) then
                        SentLinesMgmt.DeleteAll()
                    else
                        "Vendor No." := xRec."Vendor No.";
                end;

                if Vendor.Get(Rec."Vendor No.") then
                    "Vendor Name" := Vendor.Name;
            end;
        }

        field(355; "Vendor Name"; Text[100])
        {
            DataClassification = CustomerContent;
        }
        field(356; "Headers Web Service"; Text[100])
        {
            DataClassification = CustomerContent;
        }
        field(357; "Lines Web Service"; Text[100])
        {
            DataClassification = CustomerContent;
        }

        field(358; "WS Password"; Guid)
        {
            DataClassification = SystemMetadata;
        }
        field(359; "WS Username"; Guid)
        {
            DataClassification = SystemMetadata;
        }
        field(360; "Customer No."; Code[20])
        {
            DataClassification = SystemMetadata;
        }
    }

    [NonDebuggable]
    procedure SetPassword(Password: SecretText)
    var
        ErrorPasswordNotSavedLbl: Label 'Password could not be saved.';
    begin
        if IsNullGuid(Rec."WS Password") then
            Rec."WS Password" := CreateGuid();

        if not IsolatedStorage.Set(Rec."WS Password", Password, DataScope::Company) then
            Error(ErrorPasswordNotSavedLbl);
    end;

    [NonDebuggable]
    procedure GetPassword(PasswordKey: Guid) Password: SecretText
    var
        ErrorPasswordNotRetrievedLbl: Label 'Password could not be retrieved.';
    begin
        if not IsolatedStorage.Get(Format(PasswordKey), DataScope::Company, Password) then
            Error(ErrorPasswordNotRetrievedLbl);
    end;

    [NonDebuggable]
    procedure SetUsername(Username: SecretText)
    var
        ErrorUsernameNotSavedLbl: Label 'Username could not be saved.';
    begin
        if IsNullGuid(Rec."WS Username") then
            Rec."WS Username" := CreateGuid();

        if not IsolatedStorage.Set(Rec."WS Username", Username, DataScope::Company) then
            Error(ErrorUsernameNotSavedLbl);
    end;

    [NonDebuggable]
    procedure GetUsername(UsernameKey: Guid) Username: SecretText
    var
        ErrorUsernameNotRetrievedLbl: Label 'Username could not be retrieved.';
    begin
        if not IsolatedStorage.Get(Format(UsernameKey), DataScope::Company, Username) then
            Error(ErrorUsernameNotRetrievedLbl);
    end;
}