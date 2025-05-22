table 60250 "Exclusive Vendor"
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

}