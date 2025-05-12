page 60251 "Sales Order Web API"
{
    APIVersion = 'v1.0';
    APIPublisher = 'vidura';
    APIGroup = 'navuser';
    PageType = API;
    EntityCaption = 'SalesOrderAPI';
    EntitySetCaption = 'SalesOrdersAPI';
    EntityName = 'salesOrderAPI';
    EntitySetName = 'salesOrdersAPI';
    UsageCategory = Administration;
    SourceTable = "Sales Header";
    SourceTableView = WHERE("Document Type" = FILTER(Order));
    ODataKeyFields = SystemId;
    DelayedInsert = true;
    Extensible = false;
    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field("Id"; rec.SystemId) { }
                field("No"; rec."No.") { }
                field("SelltoCustomerNo"; rec."Sell-to Customer No.") { }
                field("SelltoCustomerName"; rec."Sell-to Customer Name") { }
                part(salesOrderLines; "Sales Order Subform")
                {
                    ApplicationArea = All;
                    Caption = 'Lines', Locked = true;
                    SubPageLink = "Document Type" = FIELD("Document Type"), "Document No." = FIELD("No.");
                    EntityName = 'salesOrderLine';
                    EntitySetName = 'salesOrderLines';
                }
            }
        }
    }
}