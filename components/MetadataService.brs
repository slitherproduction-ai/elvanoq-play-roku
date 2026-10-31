sub init()
    m.top.functionName = "run"
end sub

sub run()
    result = { ok: false, found: false, message: "Metadados indisponíveis." }
    if m.top.rokuClientId = "" or m.top.deviceCode = "" or m.top.deviceKey = "" then
        m.top.result = result
        return
    end if

    ' AA case-sensitive: o Portal exige "rokuClientId"/"deviceCode" com maiusculas.
    request = CreateObject("roAssociativeArray")
    request.SetModeCaseSensitive()
    request["action"] = "roku-metadata"
    request["rokuClientId"] = m.top.rokuClientId
    request["deviceCode"] = m.top.deviceCode
    request["device_key"] = m.top.deviceKey
    request["media_type"] = m.top.mediaType
    request["mode"] = m.top.mode
    ' "person": filmografia de um ator (o Portal devolve "titles"); portais antigos tratam como busca comum.
    if m.top.mode = "search" or m.top.mode = "person" then
        if m.top.title = "" then
            m.top.result = result
            return
        end if
        request["query"] = m.top.title
    else
        request["tmdb_id"] = m.top.tmdbId
        if m.top.mode = "season" then request["season_number"] = m.top.seasonNumber
    end if

    transfer = CreateObject("roUrlTransfer")
    port = CreateObject("roMessagePort")
    transfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
    transfer.SetMinimumTransferRate(1, 15)
    ' Busca por ator: funcao propria (roku-person), que valida o aparelho pelo portal-control.
    endpoint = "https://xrrgjssvdqvtrqhxpask.supabase.co/functions/v1/portal-control"
    if m.top.mode = "person" then endpoint = "https://xrrgjssvdqvtrqhxpask.supabase.co/functions/v1/roku-person"
    transfer.SetUrl(endpoint)
    transfer.SetPort(port)
    transfer.AddHeader("Content-Type", "application/json")
    transfer.AddHeader("Accept", "application/json")
    transfer.AddHeader("apikey", "sb_publishable_zTZ9IwqmgdIcQfvsy_Qz0w_ZwIOa1kl")
    transfer.AddHeader("Authorization", "Bearer sb_publishable_zTZ9IwqmgdIcQfvsy_Qz0w_ZwIOa1kl")

    if transfer.AsyncPostFromString(FormatJson(request)) <> true then
        m.top.result = result
        return
    end if

    timeoutMs = 12000
    if m.top.mode = "person" then timeoutMs = 20000
    event = wait(timeoutMs, port)
    if event = invalid or type(event) <> "roUrlEvent" then
        m.top.result = result
        return
    end if
    if event.GetSourceIdentity() <> transfer.GetIdentity() then
        m.top.result = result
        return
    end if

    status = event.GetResponseCode()
    body = event.GetString()
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
