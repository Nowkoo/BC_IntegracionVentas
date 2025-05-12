tableextension 60251 "Sales Header" extends "Sales Header"
{
    fields
    {
        field(303; "Is From Exclusive Vendor"; Boolean)
        {
            DataClassification = CustomerContent;
        }
    }
}