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
    transfer.AddHeader("X-Roku-Reserved-Dev-Id", "")
    transfer.InitClientCertificates()
    transfer.SetMinimumTransferRate(1, 15)
    ' Sem isto a Roku descarta o corpo das respostas 4xx/5xx e a mensagem do Portal se perde
    transfer.RetainBodyOnError(true)
    transfer.SetUrl("https://roku.elvanoqplay.app/api/roku")
    transfer.AddHeader("Content-Type", "application/json")
    transfer.AddHeader("Accept", "application/json")
    transfer.AddHeader("User-Agent", "ELVANOQPlay-Roku/0.1.88")
    ' Chaves de AA literal viram minusculas no FormatJson ("devicecode"); o Portal
    ' diferencia maiusculas, entao o payload usa um AA case-sensitive.
    payload = CreateObject("roAssociativeArray")
    payload.SetModeCaseSensitive()
    payload["action"] = m.top.action
    payload["rokuClientId"] = m.top.rokuClientId
    payload["deviceCode"] = m.top.deviceCode
    if m.top.action = "roku-server-code-resolve" then
        payload["code"] = m.top.serverCode
    else
        payload["device_key"] = m.top.deviceKey
        payload["deviceName"] = m.top.deviceName
        payload["platform"] = "roku"
    end if
    port = CreateObject("roMessagePort")
    transfer.SetPort(port)
    started = transfer.AsyncPostFromString(FormatJson(payload))
    result.action = m.top.action
    responseText = ""
    result.httpStatus = 0
    if started <> true then
        result.state = "offline"
        result.message = "Não foi possível iniciar a conexão com o Portal. RKU-NET-0."
        m.top.result = result
        return
    end if
    event = wait(20000, port)
    if event = invalid then
        transfer.AsyncCancel()
        result.state = "offline"
        result.message = "O Portal não respondeu a tempo. RKU-NET-0."
        m.top.result = result
        return
    end if
    if type(event) <> "roUrlEvent" then
        transfer.AsyncCancel()
        result.state = "offline"
        result.message = "Não foi possível concluir a conexão com o Portal. RKU-NET-0."
        m.top.result = result
        return
    end if
    responseText = event.GetString()
    result.httpStatus = event.GetResponseCode()
    if result.httpStatus = invalid or result.httpStatus < 0 then result.httpStatus = 0
    if result.httpStatus = 0 then
        result.state = "offline"
        result.message = "Não foi possível estabelecer conexão segura com o Portal. RKU-NET-0."
        m.top.result = result
        return
    end if
    if result.httpStatus < 200 or result.httpStatus >= 300 or responseText = invalid or responseText = "" then
        result.message = portalHttpMessage(responseText, result.httpStatus)
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
    if response.ok <> invalid and response.ok = false then
        result.ok = false
        result.message = portalMessage(response, state)
        result.payload = response
        m.top.result = result
        return
    end if
    result.ok = true
    result.message = portalMessage(response, state)
    result.payload = response
    m.top.result = result
end sub

function portalHttpMessage(responseText as Dynamic, httpStatus as Integer) as String
    message = "O Portal recusou a solicitação."
    if responseText <> invalid and responseText <> "" then
        response = ParseJson(responseText)
        if response <> invalid and type(response) = "roAssociativeArray" then
            if response.message <> invalid and portalDisplayText(response.message) <> "" then
                message = portalDisplayText(response.message)
            else if response.error <> invalid and portalDisplayText(response.error) <> "" then
                message = portalDisplayText(response.error)
            end if
        end if
    end if
    if httpStatus > 0 then return message + " (HTTP " + safeTrim(str(httpStatus)) + ")"
    return message
end function

function portalDisplayText(value as Dynamic) as String
    if value = invalid then return ""
    t = lcase(type(value))
    if t = "rostring" or t = "string" then return (value)
    if instr(1, t, "int") > 0 or instr(1, t, "float") > 0 or instr(1, t, "double") > 0 then return str(value).Trim()
    return ""
end function

function portalState(response as Object) as String
    state = ""
    if response.status <> invalid then state = portalText(response.status)
    if state = "" and response.licenseStatus <> invalid then state = portalText(response.licenseStatus)
    if state = "" and response.activation_status <> invalid then state = portalText(response.activation_status)
    if state = "" and response.license <> invalid and type(response.license) = "roAssociativeArray" and response.license.status <> invalid then state = portalText(response.license.status)
    if state = "" and response.license <> invalid and type(response.license) = "roAssociativeArray" and response.license.can_play = true then state = "active"
    if state = "" and response.data <> invalid and type(response.data) = "roAssociativeArray" and response.data.status <> invalid then state = portalText(response.data.status)
    if state = "active" or state = "ativo" then return "active"
    if state = "expired" or state = "expirado" then return "expired"
    if state = "blocked" or state = "bloqueado" then return "blocked"
    return "pending"
end function

function portalMessage(response as Object, state as String) as String
    if response.message <> invalid and response.message <> "" then return response.message
    if state = "active" then return "Licença ativa."
    if state = "expired" then return "Sua licença expirou."
    if state = "blocked" then return "Este dispositivo está bloqueado. Consulte o suporte no Portal."
    return "Aguardando a vinculação deste Roku no Portal."
end function

function portalText(value as Dynamic) as String
    if value = invalid then return ""
    t = lcase(type(value))
    if t = "rostring" or t = "string" then return lcase(value)
    if instr(1, t, "int") > 0 or instr(1, t, "float") > 0 or instr(1, t, "double") > 0 then return str(value).Trim()
    return ""
end function
