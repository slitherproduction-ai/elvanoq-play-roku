sub init()
    m.top.functionName = "run"
end sub

sub run()
    result = { ok: false, found: false, message: "Metadados indisponíveis." }
    if m.top.rokuClientId = "" or m.top.deviceCode = "" or m.top.deviceKey = "" or m.top.title = "" then
        m.top.result = result
        return
    end if
    request = {
        action: "roku-metadata"
        rokuClientId: m.top.rokuClientId
        deviceCode: m.top.deviceCode
        device_key: m.top.deviceKey
        query: m.top.title
        media_type: m.top.mediaType
    }
    transfer = CreateObject("roUrlTransfer")
    transfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
    transfer.SetConnectTimeout(8)
    transfer.SetMinimumTransferRate(1, 15)
    transfer.SetUrl("https://xrrgjssvdqvtrqhxpask.supabase.co/functions/v1/portal-control")
    transfer.SetRequest("POST")
    transfer.AddHeader("Content-Type", "application/json")
    body = transfer.PostFromString(FormatJson(request))
    status = transfer.GetResponseCode()
    if status < 200 or status >= 300 or body = invalid or body = "" then
        m.top.result = result
        return
    end if
    payload = ParseJson(body)
    if payload = invalid or type(payload) <> "roAssociativeArray" then
        m.top.result = result
        return
    end if
    payload.ok = true
    m.top.result = payload
end sub
