pageextension 60250 "Sales Order" extends "Sales Order"
{
    layout
    {
        // Add changes to page layout here
    }

    actions
    {
        addafter(Action21)
        {
            action(InformVendor)
            {
                ApplicationArea = All;
                Caption = 'Inform Vendor';
                Image = Info;
                ToolTip = 'Inform the vendor about the sales lines in this order';
                Visible = Rec."Is From Exclusive Vendor";

                trigger OnAction()
                begin
                    //Page.Run(Page::"Posting Email Setup");
                end;
            }
        }
    }
}