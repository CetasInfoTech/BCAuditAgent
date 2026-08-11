/// <summary>Persona/focus for the Risk Intelligence Copilot (drives the AI system prompt).</summary>
enum 50110 "RIA Copilot Role"
{
    Extensible = true;
    Caption = 'RIA Copilot Role';

    value(0; "Risk Analyst") { Caption = 'Risk Analyst'; }
    value(1; Auditor) { Caption = 'Auditor'; }
    value(2; "Finance Controller") { Caption = 'Finance Controller'; }
    value(3; "Supply Chain") { Caption = 'Supply Chain'; }
    value(4; Executive) { Caption = 'Executive'; }
    value(5; "Compliance Officer") { Caption = 'Compliance Officer'; }
}
