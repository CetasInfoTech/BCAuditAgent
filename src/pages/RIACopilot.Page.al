/// <summary>Risk Intelligence Copilot landing page. Natural-language entry point (AI endpoint configured in setup).</summary>
page 50123 "RIA Copilot"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Tasks;
    Caption = 'Risk Intelligence Copilot';
    SourceTable = "RIA Risk Setup";

    layout
    {
        area(Content)
        {
            group(Ask_AI)
            {
                Caption = 'Ask a Risk Question';
                field(RoleFocus; RoleFocus)
                {
                    ApplicationArea = All;
                    Caption = 'Persona';
                    ToolTip = 'Choose the persona lens the Copilot answers from.';
                }
                field(Question; QuestionTxt)
                {
                    ApplicationArea = All;
                    Caption = 'Question';
                    MultiLine = true;
                    ToolTip = 'Ask a question such as "Which vendors have the highest risk right now?"';
                }
                field(Answer; AnswerTxt)
                {
                    ApplicationArea = All;
                    Caption = 'Answer';
                    MultiLine = true;
                    Editable = false;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Ask)
            {
                Caption = 'Ask';
                Image = Sparkle;
                ToolTip = 'Submit the question to the Risk Intelligence Copilot.';
                trigger OnAction()
                var
                    Copilot: Codeunit "RIA Copilot Mgt";
                begin
                    AnswerTxt := Copilot.AskAs(RoleFocus, QuestionTxt);
                end;
            }
        }
    }

    var
        QuestionTxt: Text;
        AnswerTxt: Text;
        RoleFocus: Enum "RIA Copilot Role";

    trigger OnOpenPage()
    begin
        Rec.GetSetup();
    end;
}
