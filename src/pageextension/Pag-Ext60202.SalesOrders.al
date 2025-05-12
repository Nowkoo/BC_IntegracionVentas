pageextension 60251 "Sales Orders" extends "Customer List"
{
    layout
    {
        // Add changes to page layout here
    }

    actions
    {
        addafter(Action24)
        {
            action(InformVendor)
            {
                ApplicationArea = All;
                Caption = 'Inform Vendor';
                Image = Info;
                ToolTip = 'Inform the vendor about the sales lines in this order';
                //Visible = Rec."Is From Ex Vendor";

                trigger OnAction()
                begin
                    //Page.Run(Page::"Posting Email Setup");
                end;
            }
        }
    }
}