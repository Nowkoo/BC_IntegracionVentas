page 60253 "Sent Lines API"
{
    PageType = API;
    APIVersion = 'v1.0';
    APIPublisher = 'mycompany';
    APIGroup = 'sentlines';
    EntityName = 'sentline';
    EntitySetName = 'sentlines';
    DelayedInsert = true;
    SourceTable = "Sent Lines";
    ODataKeyFields = SystemId;


    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field(id; Rec.SystemId)
                {
                    ApplicationArea = All;
                }
                field(documentNo; Rec."Document No.")
                {
                    ApplicationArea = All;
                }
                field(lineNo; Rec."Line No.")
                {
                    ApplicationArea = All;
                }
                field(no; Rec."No.")
                {
                    ApplicationArea = All;
                }
                field(description; Rec.Description)
                {
                    ApplicationArea = All;
                }
                field(quantity; Rec.Quantity)
                {
                    ApplicationArea = All;
                }
                field(vendorItemNo; Rec."Vendor Item No.")
                {
                    ApplicationArea = All;
                }
                field(ready; Rec.Ready)
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    /* [ServiceEnabled]
    procedure SendLines(DocumentNo: Code[20])
    var
        actionContext: WebServiceActionContext;
        CustomerWsMgmt: Codeunit "Sent Lines Mgmt";
    begin
        actionContext.SetObjectType(ObjectType::Page);
        actionContext.SetObjectId(Page::"My Customer Card");
        //actionContext.AddEntityKey(Rec.FieldNo("No."), Rec."No.");
        CustomerWsMgmt.InsertSentLines(DocumentNo);
        actionContext.SetResultCode(WebServiceActionResultCode::Created);
    end;

    [ServiceEnabled]
    procedure CloneCustomer(var actionContext: WebServiceActionContext)
    var
        CustomerWsMgmt: Codeunit "Sent Lines Mgmt";
    begin
        CustomerWsMgmt.CloneCustomer(Rec."No.");
        actionContext.SetObjectType(ObjectType::Page);
        actionContext.SetObjectId(Page::"My Customer Card");
        actionContext.AddEntityKey(Rec.FieldNo("No."), Rec."No.");
        actionContext.SetResultCode(WebServiceActionResultCode::Created);
    end;

    [ServiceEnabled]
    procedure GetSalesAmounts(CustomerNo: Code[20]): Decimal
    var
        actionContext: WebServiceActionContext;
        CustomerWsMgmt: Codeunit "Sent Lines Mgmt";
        Total: Decimal;
    begin
        actionContext.SetObjectType(ObjectType::Page);
        actionContext.SetObjectId(Page::"My Customer Card");
        actionContext.AddEntityKey(Rec.FieldNo("No."), Rec."No.");
        Total := CustomerWsMgmt.GetSalesAmount(CustomerNo);
        actionContext.SetResultCode(WebServiceActionResultCode::Get);
        exit(Total);
    end; */
}
