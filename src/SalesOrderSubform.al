pageextension 60252 "Sales Order Subform" extends "Sales Order Subform"
{
    layout
    {
        addbefore(Type)
        {
            field(Status; Rec.Status)
            {
                Caption = 'Status';
                ApplicationArea = All;
                ToolTip = 'Specifies the status of the line: Pending (waiting to be sent to de web service), Sent: (the line has been informed) and Prepared (changes made by the Vendor have been applied)';
                Visible = true; //consultar header, pero desde dónde
                Editable = false;
            }
        }
    }

    actions
    {
        // Add changes to page actions here
    }
}