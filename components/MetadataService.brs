sub init()
    m.top.functionName = "run"
end sub

sub run()
    result = { ok: false, found: false, message: "Metadados indisponíveis." }
    if m.top.rokuClientId = "" or m.top.deviceCode = "" or m.top.deviceKey = "" then
        m.top.result = result
        return
    end if
    request = {
        action: "roku-metadata"
        rokuClientId: m.top.rokuClientId
        deviceCode: m.top.deviceCode
        device_key: m.top.deviceKey
        media_type: m.top.mediaType
        mode: m.top.mode
    }
    if m.top.mode = "search" then
        if m.top.title = "" then
            m.top.result = result
            return
        end if
        request.query = m.top.title
    else
        request.tmdb_id = m.top.tmdbId
        if m.top.mode = "season" then request.season_number = m.top.seasonNumber
    end if
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
    payload.mode = m.top.mode
    m.top.result = payload
end sub
