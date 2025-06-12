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
                SentLinesMgmt: Codeunit "Sent Lines Mgmt";
            begin
                SentLinesMgmt.CheckIfAllLinesReady(Rec."No.", Rec."Is From Exclusive Vendor");
            end;
        }

        addafter(Action12)
        {
            group(SalesIntegration)
            {
                Caption = 'Sales Integration';
                Image = Web;
                action(InformVendor)
                {
                    ApplicationArea = All;
                    Caption = 'Inform Vendor';
                    Image = Info;
                    ToolTip = 'Inform the vendor about the sales lines in this order';
                    Visible = Rec."Is From Exclusive Vendor";

                    trigger OnAction()
                    var
                        SentLinesMgmt: Codeunit "Sent Lines Mgmt";
                    begin
                        SentLinesMgmt.SendLinesToWS(Rec);
                    end;
                }

                action(PrepareLines)
                {
                    ApplicationArea = All;
                    Caption = 'Prepare Lines';
                    Image = GetLines;
                    ToolTip = 'Updates the sales line in the order based on changes made by the vendor.';
                    Visible = Rec."Is From Exclusive Vendor";

                    trigger OnAction()
                    var
                        SentLinesMgmt: Codeunit "Sent Lines Mgmt";
                    begin
                        SentLinesMgmt.PrepareLines(Rec);
                    end;
                }
            }
        }
    }
}