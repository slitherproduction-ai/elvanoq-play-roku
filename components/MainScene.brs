sub init()
    clearParentalSession()
    m.playlistSynced = false
    m.activationCard = m.top.findNode("activationCard")
    m.activationAccent = m.top.findNode("activationAccent")
    m.codeCard = m.top.findNode("codeCard")
    m.portalCaption = m.top.findNode("portalCaption")
    m.statusDivider = m.top.findNode("statusDivider")
    m.eyebrow = m.top.findNode("eyebrow")
    m.headline = m.top.findNode("headline")
    m.description = m.top.findNode("description")
    m.deviceCode = m.top.findNode("deviceCode")
    m.portal = m.top.findNode("portal")
    m.status = m.top.findNode("status")
    m.homeStatus = m.top.findNode("homeStatus")
    m.licenseTimer = m.top.findNode("licenseTimer")
    m.eyebrow.font = "font:SmallSystemFont"
    m.eyebrow.color = "0x78B9FFFF"
    m.headline.font = "font:LargeBoldSystemFont"
    m.headline.color = "0xFFFFFFFF"
    m.description.font = "font:MediumSystemFont"
    m.description.color = "0xC5D8ECFF"
    m.deviceCode.font = "font:LargeBoldSystemFont"
    m.deviceCode.color = "0xFFFFFFFF"
    m.portal.font = "font:LargeBoldSystemFont"
    m.portal.color = "0x7EC0FFFF"
    m.status.font = "font:SmallSystemFont"
    m.status.color = "0xB9CCE0FF"
    m.homeStatus.font = "font:LargeBoldSystemFont"
    m.licenseTimer.observeField("fire", "onLicenseTimer")
    m.clientId = CreateObject("roDeviceInfo").GetChannelClientId()
    m.deviceKey = deviceRequestKey(m.clientId)
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

sub clearParentalSession()
    section = CreateObject("roRegistrySection", "ELVANOQPlay")
    section.Delete("parental_session")
    section.Flush()
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
    if result.action = "roku-playlist-sync" then
        if result.ok = true and m.appShell <> invalid then
            m.playlistSynced = true
            m.appShell.callFunc("applyPlaylist", result.payload)
        end if
        return
    end if
    if result.ok <> true then
        showActivationState(result.state, result.message)
        return
    end if
    showActivationState(result.state, result.message)
    if result.action = "roku-license-status" and result.state = "active" and m.playlistSynced <> true then requestPortal("roku-playlist-sync")
end sub

sub showActivationState(state as String, message as String)
    if state = "active" then
        m.licenseTimer.control = "start"
        setActivationVisible(false)
        m.homeStatus.visible = false
        openAppShell()
        return
    end if
    if (state = "expired" or state = "blocked") and m.appShell <> invalid then m.appShell.visible = false
    m.homeStatus.visible = false
    setActivationVisible(true)
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

sub setActivationVisible(isVisible as Boolean)
    m.activationCard.visible = isVisible
    m.activationAccent.visible = isVisible
    m.codeCard.visible = isVisible
    m.portalCaption.visible = isVisible
    m.statusDivider.visible = isVisible
    m.eyebrow.visible = isVisible
    m.headline.visible = isVisible
    m.description.visible = isVisible
    m.deviceCode.visible = isVisible
    m.portal.visible = isVisible
    m.status.visible = isVisible
    m.top.findNode("brandMark").visible = isVisible
    m.top.findNode("brandPanel").visible = isVisible
    m.top.findNode("ambientLeft").visible = isVisible
    m.top.findNode("ambientBottom").visible = isVisible
end sub

sub openAppShell()
    if m.appShell <> invalid then
        m.appShell.visible = true
        m.appShell.setFocus(true)
        return
    end if
    m.appShell = CreateObject("roSGNode", "AppShell")
    m.appShell.rokuClientId = m.clientId
    m.appShell.deviceCode = m.deviceCodeValue
    m.appShell.deviceKey = m.deviceKey
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

function deviceRequestKey(clientId as String) as String
    normalized = ""
    for index = 1 to len(clientId)
        char = mid(clientId, index, 1)
        code = asc(char)
        if (code >= 48 and code <= 57) or (code >= 65 and code <= 90) or (code >= 97 and code <= 122) then normalized = normalized + ucase(char)
    end for
    if len(normalized) < 16 then return ""
    return left(normalized, 16)
end function
