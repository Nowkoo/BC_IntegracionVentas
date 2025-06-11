pageextension 60250 "Sales Order" extends "Sales Order"
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
                SalesLine: Record "Sales Line";
            begin
                SentLinesMgmt.CheckIfPostIsAllowed(Rec."No.", Rec."Is From Exclusive Vendor");

                //optimizar borrado con una única consulta al ws?
                SalesLine.SetRange("Document No.", Rec."No.");
                if SalesLine.FindSet() then
                    repeat
                        SentLinesMgmt.RemoveLineFromWS(Rec."No.", SalesLine."Line No.");
                    until SalesLine.Next() = 0;

                SentLinesMgmt.RemoveHeaderFromWS(Rec."No.");
                //SentLinesMgmt.ChangeDocumentStatus(Rec."No."); // no funciona
            end;
        }

        addafter(Action21)
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
                    ToolTip = 'Inform the vendor about the sales lines in this order.';
                    Visible = Rec."Is From Exclusive Vendor";

                    trigger OnAction()
                    var
                        SentLinesMgmt: Codeunit "Sent Lines Mgmt";
                    begin
                        SentLinesMgmt.Inform(Rec);
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

    trigger OnOpenPage()
    var
        VendorExclusivityMgmt: Codeunit "Vendor Exclusivity Mgmt";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        PurchasesSetup: Record "Purchases & Payables Setup";
    begin
        SalesLine.SetRange("Document No.", Rec."No.");
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        if SalesLine.FindFirst() then begin
            VendorExclusivityMgmt.UpdateOrderOwnership(Rec."No.", SalesLine."No.");
        end;
    end;
}