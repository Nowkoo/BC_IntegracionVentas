pageextension 60251 "Sales Orders" extends "Sales Order List"
{
    layout
    {
        // Add changes to page layout here
    }

    actions
    {
        addafter(Action12)
        {
            action(InformVendor)
            {
                ApplicationArea = All;
                Caption = 'Inform Vendor';
                Image = Info;
                ToolTip = 'Inform the vendor about the sales lines in this order';
                Visible = Rec."Is From Exclusive Vendor";

                trigger OnAction()
                var
                    WebServiceMgmt: Codeunit "Web Service Mgmt";
                begin
                    WebServiceMgmt.Inform(Rec);
                end;
            }
        }
    }
}