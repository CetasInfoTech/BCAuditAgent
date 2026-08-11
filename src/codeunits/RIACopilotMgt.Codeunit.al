/// <summary>Risk Intelligence Copilot. Calls a configured Azure OpenAI deployment (RAG-grounded on live
/// risk data) when enabled; otherwise returns deterministic, data-grounded answers.</summary>
codeunit 50108 "RIA Copilot Mgt"
{
    Access = Public;
    Permissions = tabledata "RIA Risk Alert" = r, tabledata "RIA Risk Profile" = r, tabledata "RIA Risk Setup" = r;

    var
        KeyNameLbl: Label 'RIA_AOAI_KEY', Locked = true;

    /// <summary>Answers a question with the default (Risk Analyst) persona.</summary>
    procedure Ask(Question: Text): Text
    begin
        exit(AskAs("RIA Copilot Role"::"Risk Analyst", Question));
    end;

    /// <summary>Answers a question in a specific persona. Uses Azure OpenAI if configured, else deterministic fallback.</summary>
    procedure AskAs(Role: Enum "RIA Copilot Role"; Question: Text): Text
    var
        Setup: Record "RIA Risk Setup";
        Answer: Text;
    begin
        Setup.GetSetup();
        if Setup."AI Copilot Enabled" and (Setup."AI Endpoint" <> '') and (Setup."AI Deployment" <> '') and HasKey() then
            if TryAskAOAI(Setup, Role, Question, Answer) then
                exit(Answer);
        exit(DeterministicAnswer(Question));
    end;

    /// <summary>Stores the Azure OpenAI API key securely in Isolated Storage (the value is never displayed).</summary>
    procedure SetApiKey(KeyValue: Text)
    begin
        if KeyValue = '' then
            exit;
        IsolatedStorage.Set(KeyNameLbl, KeyValue, DataScope::Company);
    end;

    procedure HasKey(): Boolean
    begin
        exit(IsolatedStorage.Contains(KeyNameLbl, DataScope::Company));
    end;

    [TryFunction]
    local procedure TryAskAOAI(Setup: Record "RIA Risk Setup"; Role: Enum "RIA Copilot Role"; Question: Text; var Answer: Text)
    var
        Client: HttpClient;
        Content: HttpContent;
        ContentHeaders: HttpHeaders;
        Response: HttpResponseMessage;
        RequestBody: JsonObject;
        Messages: JsonArray;
        SysMsg: JsonObject;
        UserMsg: JsonObject;
        RespJson: JsonObject;
        ChoicesTok: JsonToken;
        MsgTok: JsonToken;
        ContentTok: JsonToken;
        ApiKey: Text;
        Url: Text;
        BodyTxt: Text;
        RespTxt: Text;
    begin
        ApiKey := GetKey();
        Url := Setup."AI Endpoint".TrimEnd('/') + '/openai/deployments/' + Setup."AI Deployment" + '/chat/completions?api-version=2024-02-15-preview';

        SysMsg.Add('role', 'system');
        SysMsg.Add('content', SystemPrompt(Role) + ' ' + RagContext());
        Messages.Add(SysMsg);
        UserMsg.Add('role', 'user');
        UserMsg.Add('content', Question);
        Messages.Add(UserMsg);
        RequestBody.Add('messages', Messages);
        RequestBody.Add('temperature', 0.2);
        RequestBody.Add('max_tokens', 500);
        RequestBody.WriteTo(BodyTxt);

        Content.WriteFrom(BodyTxt);
        Content.GetHeaders(ContentHeaders);
        if ContentHeaders.Contains('Content-Type') then
            ContentHeaders.Remove('Content-Type');
        ContentHeaders.Add('Content-Type', 'application/json');

        Client.DefaultRequestHeaders().Add('api-key', ApiKey);
        Client.Post(Url, Content, Response);
        if not Response.IsSuccessStatusCode() then
            Error('AOAI call failed');
        Response.Content().ReadAs(RespTxt);

        RespJson.ReadFrom(RespTxt);
        RespJson.Get('choices', ChoicesTok);
        ChoicesTok.AsArray().Get(0, MsgTok);
        MsgTok.AsObject().Get('message', ContentTok);
        ContentTok.AsObject().Get('content', ContentTok);
        Answer := ContentTok.AsValue().AsText();
    end;

    local procedure GetKey(): Text
    var
        KeyValue: Text;
    begin
        if IsolatedStorage.Get(KeyNameLbl, DataScope::Company, KeyValue) then
            exit(KeyValue);
        exit('');
    end;

    local procedure SystemPrompt(Role: Enum "RIA Copilot Role"): Text
    begin
        case Role of
            Role::Auditor:
                exit('You are an internal audit assistant for Business Central. Answer with control references and evidence, concisely.');
            Role::"Finance Controller":
                exit('You are a finance controller assistant. Focus on financial exposure, cash, and period-end risk.');
            Role::"Supply Chain":
                exit('You are a supply chain risk assistant. Focus on inventory, procurement, and fulfilment risk.');
            Role::Executive:
                exit('You are an executive risk assistant. Answer in a brief, high-level, decision-oriented way.');
            Role::"Compliance Officer":
                exit('You are a compliance assistant. Map findings to SOX/ISO/IFRS/GDPR requirements where relevant.');
            else
                exit('You are a risk analyst assistant for Business Central. Be precise and cite the control ID where relevant.');
        end;
    end;

    /// <summary>Builds a compact RAG context string from the current open-alert picture.</summary>
    local procedure RagContext(): Text
    var
        RiskAlert: Record "RIA Risk Alert";
        Context: TextBuilder;
        CritCount: Integer;
        HighCount: Integer;
        TotalExposure: Decimal;
    begin
        RiskAlert.SetFilter(Status, '%1|%2|%3|%4',
            RiskAlert.Status::New, RiskAlert.Status::Acknowledged, RiskAlert.Status::"Under Review", RiskAlert.Status::Escalated);
        RiskAlert.SetRange(Severity, RiskAlert.Severity::Critical);
        CritCount := RiskAlert.Count();
        RiskAlert.SetRange(Severity, RiskAlert.Severity::High);
        HighCount := RiskAlert.Count();
        RiskAlert.SetRange(Severity);
        RiskAlert.CalcSums("Amount (LCY)");
        TotalExposure := RiskAlert."Amount (LCY)";
        Context.Append('Current risk context: ');
        Context.Append(StrSubstNo('%1 open critical alerts, %2 open high alerts, total open exposure %3. ', CritCount, HighCount, Format(TotalExposure)));
        Context.Append('Answer only from this context and general BC risk knowledge; do not invent specific figures.');
        exit(Context.ToText());
    end;

    // -------- Deterministic fallback (no AI key configured) --------
    local procedure DeterministicAnswer(Question: Text): Text
    var
        LowerQ: Text;
    begin
        LowerQ := LowerCase(Question);
        case true of
            (StrPos(LowerQ, 'vendor') > 0) and (StrPos(LowerQ, 'risk') > 0):
                exit(TopEntities("RIA Profile Type"::Vendor));
            (StrPos(LowerQ, 'customer') > 0) and (StrPos(LowerQ, 'risk') > 0):
                exit(TopEntities("RIA Profile Type"::Customer));
            StrPos(LowerQ, 'critical') > 0:
                exit(CriticalSummary());
            StrPos(LowerQ, 'exposure') > 0:
                exit(ExposureSummary());
            else
                exit(DefaultSummary());
        end;
    end;

    local procedure TopEntities(ProfileType: Enum "RIA Profile Type"): Text
    var
        RiskProfile: Record "RIA Risk Profile";
        Result: Text;
        Count: Integer;
        LineLbl: Label '%1 (%2) - score %3', Comment = 'positional';
        HeaderLbl: Label 'Highest-risk %1 entities:', Comment = '%1=type';
    begin
        RiskProfile.SetCurrentKey("Risk Score");
        RiskProfile.Ascending(false);
        RiskProfile.SetRange("Profile Type", ProfileType);
        Result := StrSubstNo(HeaderLbl, Format(ProfileType));
        if RiskProfile.FindSet() then
            repeat
                Count += 1;
                Result += '\' + StrSubstNo(LineLbl, RiskProfile."Entity No.", RiskProfile."Entity Name", Format(RiskProfile."Risk Score"));
            until (RiskProfile.Next() = 0) or (Count >= 5);
        if Count = 0 then
            exit(NoDataLbl);
        exit(Result);
    end;

    local procedure CriticalSummary(): Text
    var
        RiskAlert: Record "RIA Risk Alert";
        ResultLbl: Label 'There are %1 open critical alert(s) with total exposure of %2.', Comment = 'positional';
    begin
        RiskAlert.SetRange(Severity, RiskAlert.Severity::Critical);
        RiskAlert.SetFilter(Status, '%1|%2|%3|%4',
            RiskAlert.Status::New, RiskAlert.Status::Acknowledged, RiskAlert.Status::"Under Review", RiskAlert.Status::Escalated);
        RiskAlert.CalcSums("Amount (LCY)");
        exit(StrSubstNo(ResultLbl, RiskAlert.Count(), Format(RiskAlert."Amount (LCY)")));
    end;

    local procedure ExposureSummary(): Text
    var
        RiskAlert: Record "RIA Risk Alert";
        ResultLbl: Label 'Total open exposure across all alerts is %1 across %2 alert(s).', Comment = 'positional';
    begin
        RiskAlert.SetFilter(Status, '%1|%2|%3|%4',
            RiskAlert.Status::New, RiskAlert.Status::Acknowledged, RiskAlert.Status::"Under Review", RiskAlert.Status::Escalated);
        RiskAlert.CalcSums("Amount (LCY)");
        exit(StrSubstNo(ResultLbl, Format(RiskAlert."Amount (LCY)"), RiskAlert.Count()));
    end;

    local procedure DefaultSummary(): Text
    var
        RiskAlert: Record "RIA Risk Alert";
        ResultLbl: Label 'I can answer about critical alerts, exposure, and highest-risk customers/vendors. There are %1 open alert(s).', Comment = '%1=count';
    begin
        RiskAlert.SetFilter(Status, '%1|%2|%3|%4',
            RiskAlert.Status::New, RiskAlert.Status::Acknowledged, RiskAlert.Status::"Under Review", RiskAlert.Status::Escalated);
        exit(StrSubstNo(ResultLbl, RiskAlert.Count()));
    end;

    var
        NoDataLbl: Label 'No risk profile data is available yet. Run detection first.';
}
