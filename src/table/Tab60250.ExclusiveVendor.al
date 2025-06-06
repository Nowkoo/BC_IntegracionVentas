/* table 60250 "Exclusive Vendor"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Key Field"; Code[20])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(2; "Vendor No"; Code[20])
        {
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
                Vendor: Record Vendor;
            begin
                if Vendor.Get(Rec."Vendor No") then
                    "Vendor Name" := Vendor.Name;
            end;
        }
        field(3; "Vendor Name"; Text[100])
        {
            DataClassification = CustomerContent;
        }
        field(4; "Headers Web Service"; Text[100])
        {
            DataClassification = CustomerContent;
        }
        field(5; "Lines Web Service"; Text[100])
        {
            DataClassification = CustomerContent;
        }
        field(6; "WS Password"; Guid)
        {
            DataClassification = SystemMetadata;
        }
        field(7; "WS Username"; Guid)
        {
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Pk; "Key Field")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        // Add changes to field groups here
    }

    [NonDebuggable]
    procedure SetPassword(Password: SecretText)
    begin
        if IsNullGuid(Rec."WS Password") then
            Rec."WS Password" := CreateGuid();

        if not IsolatedStorage.Set(Rec."WS Password", Password, DataScope::Company) then
            Error('Password could not be saved.');
    end;

    [NonDebuggable]
    procedure GetPassword(PasswordKey: Guid) Password: SecretText
    begin
        if not IsolatedStorage.Get(Format(PasswordKey), DataScope::Company, Password) then
            Error('Password could not be retrieved.');
    end;

    [NonDebuggable]
    procedure SetUsername(Username: SecretText)
    begin
        if IsNullGuid(Rec."WS Username") then
            Rec."WS Username" := CreateGuid();

        if not IsolatedStorage.Set(Rec."WS Username", Username, DataScope::Company) then
            Error('Username could not be saved.');
    end;

    [NonDebuggable]
    procedure GetUsername(UsernameKey: Guid) Username: SecretText
    begin
        if not IsolatedStorage.Get(Format(UsernameKey), DataScope::Company, Username) then
            Error('Username could not be retrieved.');
    end;


    trigger OnInsert()
    begin

    end;

    trigger OnModify()
    begin

    end;

    trigger OnDelete()
    begin

    end;

    trigger OnRename()
    begin

    end;

} */