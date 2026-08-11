/// <summary>Outbound delivery: critical-alert push to Teams / webhook, and a scheduled email digest.</summary>
codeunit 50126 "RIA Delivery Mgt"
{
    Access = Public;
    Permissions = tabledata "RIA Risk Alert" = r, tabledata "RIA Risk Setup" = r;

    trigger OnRun()
    begin
        SendDailyDigest();
    end;

    /// <summary>Pushes a single critical alert to the configured Teams and generic webhooks (best-effort).</summary>
    procedure SendCriticalAlert(AlertEntryNo: Integer)
    var
        RiskAlert: Record "RIA Risk Alert";
        Setup: Record "RIA Risk Setup";
        Payload: Text;
    begin
        if not RiskAlert.Get(AlertEntryNo) then
            exit;
        Setup.GetSetup();
        if Setup."Shadow Mode" then
            exit;

        if Setup."Teams Webhook URL" <> '' then begin
            Payload := BuildTeamsCard(RiskAlert);
            PostJson(Setup."Teams Webhook URL", Payload);
        end;
        if Setup."Alert Webhook URL" <> '' then begin
            Payload := BuildAlertJson(RiskAlert);
            PostJson(Setup."Alert Webhook URL", Payload);
        end;
    end;

    /// <summary>Sends a digest email of open High/Critical alerts. Intended for a daily Job Queue run.</summary>
    procedure SendDailyDigest()
    var
        RiskAlert: Record "RIA Risk Alert";
        Setup: Record "RIA Risk Setup";
        EmailMessage: Codeunit "Email Message";
        Email: Codeunit Email;
        Body: TextBuilder;
        Recipients: List of [Text];
        SubjectLbl: Label 'RIA Risk Digest - %1 open high/critical alert(s)', Comment = '%1=count';
        LineLbl: Label '[%1] %2 (score %3) - %4', Comment = 'positional';
        Cnt: Integer;
    begin
        Setup.GetSetup();
        if not Setup."Enable Email Digest" then
            exit;
        if Setup."Digest Recipient" = '' then
            exit;

        RiskAlert.SetFilter(Severity, '%1|%2', RiskAlert.Severity::Critical, RiskAlert.Severity::High);
        RiskAlert.SetFilter(Status, '%1|%2|%3|%4',
            RiskAlert.Status::New, RiskAlert.Status::Acknowledged, RiskAlert.Status::"Under Review", RiskAlert.Status::Escalated);
        RiskAlert.SetCurrentKey(Status, Severity, "Detected DateTime");
        Body.AppendLine('Open high/critical risk alerts:');
        Body.AppendLine('');
        if RiskAlert.FindSet() then
            repeat
                Cnt += 1;
                Body.AppendLine(StrSubstNo(LineLbl, Format(RiskAlert.Severity), RiskAlert.Title, Format(RiskAlert."Risk Score"), Format(RiskAlert.Status)));
            until (RiskAlert.Next() = 0) or (Cnt >= 100);

        if Cnt = 0 then
            exit;

        Recipients.Add(Setup."Digest Recipient");
        EmailMessage.Create(Recipients, StrSubstNo(SubjectLbl, Cnt), Body.ToText(), false);
        Email.Enqueue(EmailMessage);
    end;

    local procedure BuildTeamsCard(var RiskAlert: Record "RIA Risk Alert"): Text
    var
        JObj: JsonObject;
        Txt: Text;
        SummaryLbl: Label 'RIA Critical Alert';
        TextLbl: Label '**%1**\n\nControl %2 | Severity %3 | Score %4\n\n%5', Comment = 'positional';
    begin
        JObj.Add('@type', 'MessageCard');
        JObj.Add('@context', 'http://schema.org/extensions');
        JObj.Add('themeColor', 'D50000');
        JObj.Add('summary', SummaryLbl);
        JObj.Add('title', RiskAlert.Title);
        JObj.Add('text', StrSubstNo(TextLbl, RiskAlert.Title, RiskAlert."Control ID", Format(RiskAlert.Severity), Format(RiskAlert."Risk Score"), RiskAlert.Description));
        JObj.WriteTo(Txt);
        exit(Txt);
    end;

    local procedure BuildAlertJson(var RiskAlert: Record "RIA Risk Alert"): Text
    var
        JObj: JsonObject;
        Txt: Text;
    begin
        JObj.Add('entryNo', RiskAlert."Entry No.");
        JObj.Add('controlId', RiskAlert."Control ID");
        JObj.Add('severity', Format(RiskAlert.Severity));
        JObj.Add('riskScore', RiskAlert."Risk Score");
        JObj.Add('title', RiskAlert.Title);
        JObj.Add('entityNo', RiskAlert."Entity No.");
        JObj.Add('amountLCY', RiskAlert."Amount (LCY)");
        JObj.Add('detectedDateTime', Format(RiskAlert."Detected DateTime", 0, 9));
        JObj.WriteTo(Txt);
        exit(Txt);
    end;

    [TryFunction]
    local procedure PostJson(Url: Text; Payload: Text)
    var
        Client: HttpClient;
        Content: HttpContent;
        Headers: HttpHeaders;
        Response: HttpResponseMessage;
    begin
        Content.WriteFrom(Payload);
        Content.GetHeaders(Headers);
        if Headers.Contains('Content-Type') then
            Headers.Remove('Content-Type');
        Headers.Add('Content-Type', 'application/json');
        Client.Post(Url, Content, Response);
    end;
}
