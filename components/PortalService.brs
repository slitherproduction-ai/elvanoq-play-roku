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
    transfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
    transfer.SetConnectTimeout(10)
    transfer.SetMinimumTransferRate(1, 15)
    transfer.SetUrl("https://xrrgjssvdqvtrqhxpask.supabase.co/functions/v1/portal-control")
    transfer.AddHeader("Content-Type", "application/json")
    transfer.AddHeader("Accept", "application/json")
    payload = { action: m.top.action, rokuClientId: m.top.rokuClientId, deviceCode: m.top.deviceCode, device_key: m.top.deviceKey, platform: "roku" }
    responseText = transfer.PostFromString(FormatJson(payload))
    result.httpStatus = transfer.GetResponseCode()

    if result.httpStatus = 0 then
        result.state = "offline"
        result.message = "Sem conexão. Vamos tentar novamente quando a internet voltar."
        m.top.result = result
        return
    end if
    if result.httpStatus < 200 or result.httpStatus >= 300 or responseText = invalid or responseText = "" then
        result.message = "O Portal não respondeu corretamente. Tente novamente em instantes."
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
