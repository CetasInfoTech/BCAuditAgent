/// <summary>Open Cases / Investigation Workspace — active investigation cases.</summary>
page 50112 "RIA Open Cases"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "RIA Investigation Case";
    Caption = 'Investigation Cases';
    CardPageId = "RIA Investigation Case Card";
    SourceTableView = sorting(Status, Severity);

    layout
    {
        area(Content)
        {
            repeater(Cases)
            {
                field("No."; Rec."No.") { }
                field(Title; Rec.Title) { }
                field(Status; Rec.Status) { StyleExpr = StatusStyle; }
                field(Severity; Rec.Severity) { }
                field("Assigned To"; Rec."Assigned To") { }
                field("Linked Alert Count"; Rec."Linked Alert Count") { }
                field("Total Exposure (LCY)"; Rec."Total Exposure (LCY)") { }
                field("Opened By"; Rec."Opened By") { }
                field("Opened Date"; Rec."Opened Date") { }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(CloseCase)
            {
                Caption = 'Close Case';
                Image = Close;
                ToolTip = 'Mark this case as closed.';
                trigger OnAction()
                var
                    CaseMgt: Codeunit "RIA Case Mgt";
                begin
                    CaseMgt.CloseCase(Rec);
                    CurrPage.Update(false);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';
                actionref(Close_P; CloseCase) { }
            }
        }
    }

    var
        StatusStyle: Text;

    trigger OnAfterGetRecord()
    begin
        if Rec.Status = Rec.Status::Closed then
            StatusStyle := 'Favorable'
        else
            StatusStyle := 'Standard';
    end;
}
