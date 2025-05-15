table 60251 "Sent Lines"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Document No."; Code[20])
        {
            DataClassification = CustomerContent;

        }
        field(2; "Line No."; Code[20])
        {
            DataClassification = CustomerContent;

        }
        field(3; "No."; Code[20])
        {
            DataClassification = CustomerContent;

        }
        field(4; "Description"; Text[100])
        {
            DataClassification = CustomerContent;

        }
        field(5; "Quantity"; Integer)
        {
            DataClassification = CustomerContent;

        }
        field(6; "Vendor Item No."; Text[50])
        {
            DataClassification = CustomerContent;

        }
        field(7; "Ready"; Boolean)
        {
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(Pk; "Document No.", "Line No.")
        {
            Clustered = true;
        }
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