sub init()
    m.brand = m.top.findNode("brand")
    m.headline = m.top.findNode("headline")
    m.description = m.top.findNode("description")
    m.deviceCode = m.top.findNode("deviceCode")
    m.portal = m.top.findNode("portal")
    m.status = m.top.findNode("status")
    m.homeStatus = m.top.findNode("homeStatus")
    m.licenseTimer = m.top.findNode("licenseTimer")
    m.brand.font = "font:LargeBoldSystemFont"
    m.headline.font = "font:LargeBoldSystemFont"
    m.description.font = "font:MediumSystemFont"
    m.deviceCode.font = "font:LargeBoldSystemFont"
    m.portal.font = "font:MediumSystemFont"
    m.status.font = "font:MediumSystemFont"
    m.homeStatus.font = "font:LargeBoldSystemFont"
    m.licenseTimer.observeField("fire", "onLicenseTimer")
    m.clientId = CreateObject("roDeviceInfo").GetChannelClientId()
    m.deviceKey = getOrCreateDeviceKey()
    m.deviceCodeValue = formatDeviceCode(m.clientId)
    m.deviceCode.text = m.deviceCodeValue
    if m.clientId = "" or m.deviceKey = "" or m.deviceCodeValue = "ROKU-CÓDIGO-INDISPONÍVEL" then
        m.status.text = "Não foi possível preparar a ativação deste Roku. Reinicie o aplicativo."
        return
    end if
    m.status.text = "Conectando ao Portal para ativação…"
    requestPortal("roku-device-register")
    m.licenseTimer.control = "start"
end sub

sub onLicenseTimer()
    requestPortal("roku-license-status")
end sub

sub requestPortal(action as String)
    if m.requestInFlight = true then return
    m.requestInFlight = true
    request = CreateObject("roSGNode", "PortalService")
    request.action = action
    request.rokuClientId = m.clientId
    request.deviceCode = m.deviceCodeValue
    request.deviceKey = m.deviceKey
    request.observeField("result", "onPortalResult")
    m.portalRequest = request
    request.control = "RUN"
end sub

sub onPortalResult()
    result = m.portalRequest.result
    m.requestInFlight = false
    if result = invalid or type(result) <> "roAssociativeArray" then
        showActivationState("error", "Não foi possível validar a resposta do Portal.")
        return
    end if
    if result.action = "roku-device-register" then
        requestPortal("roku-license-status")
        return
    end if
    if result.ok <> true then
        showActivationState(result.state, result.message)
        return
    end if
    showActivationState(result.state, result.message)
end sub

sub showActivationState(state as String, message as String)
    if state = "active" then
        m.licenseTimer.control = "stop"
        m.headline.visible = false
        m.description.visible = false
        m.deviceCode.visible = false
        m.portal.visible = false
        m.status.visible = false
        m.homeStatus.visible = false
        openAppShell()
        return
    end if
    m.homeStatus.visible = false
    m.headline.visible = true
    m.description.visible = true
    m.deviceCode.visible = true
    m.portal.visible = true
    m.status.visible = true
    if state = "expired" then
        m.status.text = "Licença expirada. Renove em elvanoqplay.app."
    else if state = "blocked" then
        m.status.text = "Dispositivo bloqueado. Consulte o suporte no Portal."
    else if state = "offline" then
        m.status.text = "Sem conexão. A tela continuará disponível e a ativação será verificada novamente."
    else if state = "error" then
        m.status.text = "Falha ao consultar o Portal. Vamos tentar novamente."
    else
        m.status.text = "Aguardando ativação. Vincule este Roku em elvanoqplay.app."
    end if
end sub

sub openAppShell()
    if m.appShell <> invalid then return
    m.appShell = CreateObject("roSGNode", "AppShell")
    m.top.appendChild(m.appShell)
    m.appShell.setFocus(true)
end sub

function formatDeviceCode(clientId as String) as String
    normalized = ""
    for index = 1 to len(clientId)
        char = mid(clientId, index, 1)
        code = asc(char)
        if (code >= 48 and code <= 57) or (code >= 65 and code <= 90) or (code >= 97 and code <= 122) then normalized = normalized + ucase(char)
    end for
    if len(normalized) < 16 then return "ROKU-CÓDIGO-INDISPONÍVEL"
    return "ROKU-" + left(normalized, 8) + "-" + mid(normalized, 9, 8)
end function

function getOrCreateDeviceKey() as String
    section = CreateObject("roRegistrySection", "ELVANOQPlay")
    savedKey = section.Read("device_key")
    if savedKey <> invalid and savedKey <> "" then return savedKey

    generatedKey = CreateObject("roDeviceInfo").GetRandomUUID()
    generatedKey = replace(generatedKey, "-", "")
    if generatedKey = "" then return ""
    section.Write("device_key", generatedKey)
    section.Flush()
    return generatedKey
end function
