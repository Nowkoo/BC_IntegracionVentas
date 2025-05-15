pageextension 60251 "Sales Orders" extends "Sales Order List"
{
    layout
    {
        // Add changes to page layout here
    }

    actions
    {
        modify(Post)
        {
            trigger OnBeforeAction()
            var
                SentLinesMgmt: Codeunit "Sent Lines Mgmt Cust";
            begin
                SentLinesMgmt.CheckIfPostIsAllowed(Rec."No.", Rec."Is From Exclusive Vendor");
            end;
        }

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
                    SentLinesMgmt: Codeunit "Sent Lines Mgmt Cust";
                begin
                    SentLinesMgmt.Inform(Rec."No.");
                end;
            }
        }
    }
}