sub init()
    m.top.functionName = "run"
end sub

sub run()
    result = { action: m.top.action, ok: false, state: "error", message: "Não foi possível consultar o Portal.", httpStatus: 0 }
    if m.top.rokuClientId = "" or m.top.deviceCode = "" or m.top.deviceKey = "" or m.top.action = "" then
        result.message = "Dados de ativação indisponíveis neste momento."
        m.top.result = result
        return
    end if

    transfer = CreateObject("roUrlTransfer")
    port = CreateObject("roMessagePort")
    transfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
    transfer.AddHeader("X-Roku-Reserved-Dev-Id", "")
    transfer.InitClientCertificates()
    transfer.SetConnectTimeout(10)
    transfer.SetMinimumTransferRate(1, 15)
    transfer.SetUrl("https://xrrgjssvdqvtrqhxpask.supabase.co/functions/v1/portal-control")
    transfer.SetPort(port)
    transfer.AddHeader("Content-Type", "application/json")
    transfer.AddHeader("Accept", "application/json")
    transfer.AddHeader("apikey", "sb_publishable_zTZ9IwqmgdIcQfvsy_Qz0w_ZwIOa1kl")
    transfer.AddHeader("Authorization", "Bearer sb_publishable_zTZ9IwqmgdIcQfvsy_Qz0w_ZwIOa1kl")

    payload = { action: m.top.action, rokuClientId: m.top.rokuClientId, deviceCode: m.top.deviceCode, device_key: m.top.deviceKey, deviceName: m.top.deviceName, platform: "roku" }
    if m.top.serverCode <> invalid and m.top.serverCode <> "" then payload.serverCode = m.top.serverCode

    if transfer.AsyncPostFromString(FormatJson(payload)) <> true then
        result.state = "offline"
        result.message = "Não foi possível iniciar a conexão com o Portal."
        m.top.result = result
        return
    end if

    event = wait(15000, port)
    if event = invalid or type(event) <> "roUrlEvent" then
        result.state = "offline"
        result.message = "A conexão com o Portal excedeu o tempo limite. Verifique a internet e tente novamente."
        m.top.result = result
        return
    end if

    result.action = m.top.action
    result.httpStatus = event.GetResponseCode()
    responseText = event.GetString()
    if result.httpStatus = 0 then
        result.state = "offline"
        result.message = "Não foi possível estabelecer conexão segura com o Portal. RKU-NET-0."
        m.top.result = result
        return
    end if
    if result.httpStatus < 200 or result.httpStatus >= 300 or responseText = invalid or responseText = "" then
        result.message = "O Portal recusou a solicitação. Tente novamente em instantes."
        m.top.result = result
        return
    end if

    response = ParseJson(responseText)
    if response = invalid or type(response) <> "roAssociativeArray" then
        result.message = "Resposta inválida do Portal."
        m.top.result = result
        return
    end if
    state = portalState(response)
    result.state = state
    result.ok = true
    result.message = portalMessage(response, state)
    result.payload = response
    m.top.result = result
end sub

function portalState(response as Object) as String
    state = ""
    if response.status <> invalid then state = lcase(str(response.status))
    if state = "" and response.licenseStatus <> invalid then state = lcase(str(response.licenseStatus))
    if state = "" and response.license <> invalid and type(response.license) = "roAssociativeArray" and response.license.status <> invalid then state = lcase(str(response.license.status))
    if state = "" and response.data <> invalid and type(response.data) = "roAssociativeArray" and response.data.status <> invalid then state = lcase(str(response.data.status))
    if state = "active" or state = "ativo" then return "active"
    if state = "expired" or state = "expirado" then return "expired"
    if state = "blocked" or state = "bloqueado" then return "blocked"
    return "pending"
end function

function portalMessage(response as Object, state as String) as String
    if response.message <> invalid and response.message <> "" then return response.message
    if state = "active" then return "Licença ativa."
    if state = "expired" then return "Sua licença expirou. Renove no Portal."
    if state = "blocked" then return "Este dispositivo está bloqueado. Consulte o suporte no Portal."
    return "Aguardando a vinculação deste Roku no Portal."
end function
