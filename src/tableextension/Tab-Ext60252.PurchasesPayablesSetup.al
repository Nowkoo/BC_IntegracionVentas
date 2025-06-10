tableextension 60252 "Purchases & Payables Setup" extends "Purchases & Payables Setup"
{
    fields
    {
        field(354; "Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
            ToolTip = 'Your identification number for the vendor that hosts the web service.';
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
            Caption = 'Vendor Name';
            ToolTip = 'The name of the vendor selected above.';
            DataClassification = CustomerContent;
        }
        field(356; "Headers Web Service"; Text[200])
        {
            Caption = 'Sent Headers URL';
            ToolTip = 'URL of the vendor''s web service that stores the sales headers data.';
            DataClassification = CustomerContent;
        }
        field(357; "Lines Web Service"; Text[200])
        {
            Caption = 'Sent Lines URL';
            ToolTip = 'URL of the vendor''s web service that stores the sales lines data.';
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
            Caption = 'Customer No.';
            ToolTip = 'The identification number that the vendor uses in their system to identify you as a customer.';
            DataClassification = SystemMetadata;
        }
        field(361; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            ToolTip = 'Specifies the default Gen. Prod. Posting Group. for newly inserted items.';
            DataClassification = CustomerContent;
            TableRelation = "Gen. Product Posting Group";
        }
        field(362; "Inventory Posting Group"; Code[20])
        {
            Caption = 'Inventory Posting Group';
            ToolTip = 'Specifies the default Inventory Posting Group for newly inserted items.';
            DataClassification = CustomerContent;
            TableRelation = "Inventory Posting Group";
        }
        field(363; "Base Unit of Measure"; Code[10])
        {
            Caption = 'Base Unit of Measure';
            ToolTip = 'Specifies the default Base Unit of Measure for newly inserted items.';
            DataClassification = CustomerContent;
            TableRelation = "Unit of Measure";
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