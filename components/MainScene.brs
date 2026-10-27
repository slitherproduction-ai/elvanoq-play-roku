sub init()
    clearParentalSession()
    m.playlistSynced = false
    m.activationCard = m.top.findNode("activationCard")
    m.activationAccent = m.top.findNode("activationAccent")
    m.codeCard = m.top.findNode("codeCard")
    m.serverCodeButton = m.top.findNode("serverCodeButton")
    m.serverCodeButtonText = m.top.findNode("serverCodeButtonText")
    m.portalCaption = m.top.findNode("portalCaption")
    m.statusDivider = m.top.findNode("statusDivider")
    m.eyebrow = m.top.findNode("eyebrow")
    m.headline = m.top.findNode("headline")
    m.description = m.top.findNode("description")
    m.deviceCode = m.top.findNode("deviceCode")
    m.portal = m.top.findNode("portal")
    m.status = m.top.findNode("status")
    m.homeStatus = m.top.findNode("homeStatus")
    m.appVersion = m.top.findNode("appVersion")
    m.licenseTimer = m.top.findNode("licenseTimer")
    m.portalWatchdog = m.top.findNode("portalWatchdog")
    m.eyebrow.font = "font:SmallBoldSystemFont"
    m.eyebrow.color = "0x5CDDF6FF"
    m.headline.font = "font:LargeBoldSystemFont"
    m.headline.color = "0xFFFFFFFF"
    m.description.font = "font:MediumSystemFont"
    m.description.color = "0xD4DFEDFF"
    m.deviceCode.font = "font:MediumBoldSystemFont"
    m.deviceCode.color = "0xFFFFFFFF"
    m.portalCaption.font = "font:SmallSystemFont"
    m.portalCaption.color = "0x8CA6C4FF"
    m.portal.font = "font:MediumBoldSystemFont"
    m.portal.color = "0xFFFFFFFF"
    m.serverCodeButtonText.font = "font:SmallBoldSystemFont"
    m.serverCodeButtonText.color = "0xFFFFFFFF"
    m.status.font = "font:SmallSystemFont"
    m.status.color = "0xB8CAE0FF"
    m.homeStatus.font = "font:LargeBoldSystemFont"
    m.appVersion.font = "font:SmallSystemFont"
    m.appVersion.color = "0x90AAC8CC"
    m.licenseTimer.observeField("fire", "onLicenseTimer")
    m.portalWatchdog.observeField("fire", "onPortalWatchdog")
    m.top.setFocus(true)
    m.clientId = CreateObject("roDeviceInfo").GetChannelClientId()
    m.deviceKey = deviceRequestKey(m.clientId)
    m.deviceName = "ELVANOQ Play Roku"
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

function onKeyEvent(key as String, press as Boolean) as Boolean
    if not press then return false
    if m.appShell <> invalid and m.appShell.visible then return false
    if key = "OK" and m.inputDialog = invalid then
        cancelPendingPortalRequest()
        openServerCodeKeyboard()
        return true
    end if
    return false
end function

sub clearParentalSession()
    section = CreateObject("roRegistrySection", "ELVANOQPlay")
    section.Delete("parental_session")
    section.Flush()
end sub

sub onLicenseTimer()
    requestPortal("roku-license-status")
end sub

sub onPortalWatchdog()
    if m.requestInFlight = true then
        m.status.text = "A conexão está demorando. Verifique a internet e reinicie o aplicativo."
    end if
end sub

sub cancelPendingPortalRequest()
    if m.portalRequest <> invalid then m.portalRequest.control = "STOP"
    m.portalRequest = invalid
    m.requestInFlight = false
    m.portalWatchdog.control = "stop"
end sub

sub requestPortal(action as String)
    if m.requestInFlight = true then return
    m.requestInFlight = true
    m.portalWatchdog.control = "stop"
    m.portalWatchdog.control = "start"
    request = CreateObject("roSGNode", "PortalService")
    request.action = action
    request.rokuClientId = m.clientId
    request.deviceCode = m.deviceCodeValue
    request.deviceKey = m.deviceKey
    request.deviceName = m.deviceName
    if action = "roku-server-code-resolve" then request.serverCode = m.serverCodeInput
    request.observeField("result", "onPortalResult")
    m.portalRequest = request
    request.control = "RUN"
end sub

sub onPortalResult()
    result = m.portalRequest.result
    m.requestInFlight = false
    m.portalWatchdog.control = "stop"
    if result = invalid or type(result) <> "roAssociativeArray" then
        showActivationState("error", "Não foi possível validar a resposta do Portal.")
        return
    end if
    if result.action = "roku-device-register" then
        if result.ok <> true then
            showActivationState(result.state, result.message)
            return
        end if
        requestPortal("roku-license-status")
        return
    end if
    if result.action = "roku-server-code-resolve" then
        handleServerCodeResult(result)
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

sub openServerCodeKeyboard()
    dialog = CreateObject("roSGNode", "KeyboardDialog")
    dialog.title = "Código do servidor"
    dialog.message = "Digite o código recebido no Portal."
    dialog.buttons = ["Continuar", "Cancelar"]
    dialog.observeField("buttonSelected", "onServerCodeKeyboardSelected")
    m.inputDialog = dialog
    m.top.dialog = dialog
end sub

sub onServerCodeKeyboardSelected()
    dialog = m.inputDialog
    m.top.dialog = invalid
    m.inputDialog = invalid
    if dialog = invalid or dialog.buttonSelected <> 0 then
        m.top.setFocus(true)
        return
    end if
    code = normalizeServerCode(dialog.text)
    if code = "" then
        m.status.text = "Código inválido. Confira o código e tente novamente."
        m.top.setFocus(true)
        return
    end if
    m.serverCodeInput = code
    m.status.text = "Validando o código do servidor…"
    requestPortal("roku-server-code-resolve")
end sub

sub handleServerCodeResult(result as Object)
    if result.ok <> true then
        m.status.text = "Não foi possível validar este código. Tente novamente."
        return
    end if
    host = serverHostFromPayload(result.payload)
    if host = "" then
        m.status.text = "O Portal não retornou um servidor compatível."
        return
    end if
    m.resolvedHost = host
    openCredentialKeyboard("username")
end sub

sub openCredentialKeyboard(stage as String)
    dialog = CreateObject("roSGNode", "KeyboardDialog")
    if stage = "username" then
        dialog.title = "Usuário da lista"
        dialog.message = "Informe o usuário do seu acesso."
        dialog.buttons = ["Continuar", "Cancelar"]
        dialog.observeField("buttonSelected", "onUsernameKeyboardSelected")
    else
        dialog.title = "Senha da lista"
        dialog.message = "Informe a senha do seu acesso."
        dialog.buttons = ["Conectar", "Cancelar"]
        dialog.observeField("buttonSelected", "onPasswordKeyboardSelected")
    end if
    m.inputDialog = dialog
    m.top.dialog = dialog
end sub

sub onUsernameKeyboardSelected()
    dialog = m.inputDialog
    m.top.dialog = invalid
    m.inputDialog = invalid
    if dialog = invalid or dialog.buttonSelected <> 0 or trim(dialog.text) = "" then
        m.status.text = "Login por código cancelado."
        m.top.setFocus(true)
        return
    end if
    m.manualUsername = trim(dialog.text)
    openCredentialKeyboard("password")
end sub

sub onPasswordKeyboardSelected()
    dialog = m.inputDialog
    m.top.dialog = invalid
    m.inputDialog = invalid
    if dialog = invalid or dialog.buttonSelected <> 0 or dialog.text = "" then
        m.status.text = "Login por código cancelado."
        m.top.setFocus(true)
        return
    end if
    password = dialog.text
    playlist = { source_type: "xtream", credentials: { host: m.resolvedHost, username: m.manualUsername, password: password } }
    setActivationVisible(false)
    openAppShell()
    if m.appShell <> invalid then m.appShell.callFunc("applyPlaylist", { display_name: "Acesso por código", server_code: m.serverCodeInput, playlist: playlist })
    m.manualUsername = ""
    m.serverCodeInput = ""
    m.resolvedHost = ""
end sub

function serverHostFromPayload(payload as Object) as String
    if payload = invalid or type(payload) <> "roAssociativeArray" then return ""
    value = ""
    if payload.host <> invalid then value = payload.host
    if value = "" and payload.data <> invalid and type(payload.data) = "roAssociativeArray" and payload.data.host <> invalid then value = payload.data.host
    if value = "" and payload.server <> invalid and type(payload.server) = "roAssociativeArray" and payload.server.host <> invalid then value = payload.server.host
    value = trim(value)
    lower = lcase(value)
    if left(lower, 7) <> "http://" and left(lower, 8) <> "https://" then return ""
    if instr(1, value, "@") > 0 or instr(1, value, "?") > 0 or instr(1, value, "#") > 0 then return ""
    return value
end function

function normalizeServerCode(value as String) as String
    normalized = ""
    for index = 1 to len(value)
        char = mid(value, index, 1)
        code = asc(char)
        if (code >= 48 and code <= 57) or (code >= 65 and code <= 90) or (code >= 97 and code <= 122) or char = "-" then normalized = normalized + ucase(char)
    end for
    if len(normalized) < 4 or len(normalized) > 32 then return ""
    return normalized
end function

sub setActivationVisible(isVisible as Boolean)
    m.activationCard.visible = isVisible
    m.activationAccent.visible = isVisible
    m.codeCard.visible = isVisible
    m.serverCodeButton.visible = isVisible
    m.serverCodeButtonText.visible = isVisible
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
