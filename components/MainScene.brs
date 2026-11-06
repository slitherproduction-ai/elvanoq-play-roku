sub init()
    clearParentalSession()
    m.playlistSynced = false
    m.codeCard = m.top.findNode("codeCard")
    m.serverCodeButton = m.top.findNode("serverCodeButton")
    m.serverCodeButtonText = m.top.findNode("serverCodeButtonText")
    m.serverCodeAction = m.top.findNode("serverCodeAction")
    m.portalCaption = m.top.findNode("portalCaption")
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
    m.registerTimer = m.top.findNode("registerTimer")
    m.statusDot = m.top.findNode("statusDot")
    m.statusPulse = m.top.findNode("statusPulse")
    m.clockTime = m.top.findNode("clockTime")
    m.clockDate = m.top.findNode("clockDate")
    m.clockTimer = m.top.findNode("clockTimer")
    ' Padrao do login Android 2.17.23 (o mesmo da LG 1.1.1).
    m.eyebrow.font = appFont(19, "bold")
    m.eyebrow.color = "0x00D7FFFF"
    m.headline.font = appFont(66, "bold")
    m.headline.color = "0xF4F8FFFF"
    m.description.font = appFont(27, "regular")
    m.description.color = "0xB8C4D6FF"
    for i = 1 to 3
        n = m.top.findNode("stepNumber" + i.ToStr())
        n.font = appFont(22, "bold")
        n.color = "0xFFFFFFFF"
        t = m.top.findNode("stepText" + i.ToStr())
        t.font = appFont(25, "regular")
        t.color = "0xE4EAF4FF"
    end for
    m.deviceCode.font = appFont(42, "bold")
    m.deviceCode.color = "0xFFFFFFFF"
    m.portalCaption.font = appFont(19, "bold")
    m.portalCaption.color = "0x8E9AAEFF"
    codeLabel = m.top.findNode("codeLabel")
    codeLabel.font = appFont(18, "bold")
    codeLabel.color = "0x8E9AAEFF"
    qrCaption = m.top.findNode("qrCaption")
    qrCaption.font = appFont(21, "semibold")
    qrCaption.color = "0xB8C4D6FF"
    m.portal.font = appFont(26, "bold")
    m.portal.color = "0x00D7FFFF"
    m.serverCodeButtonText.font = appFont(29, "bold")
    m.serverCodeButtonText.color = "0x070B14FF"
    m.checkButton = m.top.findNode("checkButton")
    m.helpButton = m.top.findNode("helpButton")
    for each id in ["checkButtonText", "helpButtonText"]
        label = m.top.findNode(id)
        label.font = appFont(24, "semibold")
        label.color = "0xF4F8FFFF"
    end for
    m.actionIndex = 0
    layoutActivationActions()
    m.status.font = appFont(22, "regular")
    m.status.color = "0xB8C4D6FF"
    m.homeStatus.font = appFont(40, "bold")
    m.clockTime.font = appFont(46, "semibold")
    m.clockTime.color = "0xF4F8FFFF"
    m.clockDate.font = appFont(22, "regular")
    m.clockDate.color = "0x8894A8FF"
    m.appVersion.font = appFont(19, "regular")
    m.appVersion.color = "0x8E9AAEFF"
    appInfo = CreateObject("roAppInfo")
    versionName = appInfo.GetValue("version_name")
    if versionName = "" then versionName = appInfo.GetValue("major_version") + "." + appInfo.GetValue("minor_version") + ".0"
    m.appVersion.text = "ELVANOQ · Roku · Versão " + versionName
    m.expiredOverlay = m.top.findNode("expiredOverlay")
    ' Lista (e nao AA): chaves de AA literal viram minusculas e o findNode diferencia maiusculas.
    styles = [["expiredTitle", 44, "bold", "0xF4F8FFFF"], ["expiredMessage", 24, "regular", "0xB8C4D6FF"], ["expiredCaption", 18, "bold", "0x8894A8FF"], ["expiredCode", 44, "bold", "0xFFFFFFFF"], ["expiredInfo", 20, "regular", "0x8894A8FF"], ["expiredButton", 24, "semibold", "0x070B14FF"], ["expiredFooter", 18, "regular", "0x8894A8FF"]]
    for each style in styles
        label = m.top.findNode(style[0])
        label.font = appFont(style[1], style[2])
        label.color = style[3]
    end for
    m.clockTimer.observeField("fire", "updateActivationClock")
    m.clockTimer.control = "start"
    updateActivationClock()
    setStatusTone("connecting")
    m.licenseTimer.observeField("fire", "onLicenseTimer")
    m.portalWatchdog.observeField("fire", "onPortalWatchdog")
    m.registerTimer.observeField("fire", "onRegisterTimer")
    restoreActivationFocus()
    m.clientId = CreateObject("roDeviceInfo").GetChannelClientId()
    m.deviceKey = deviceRequestKey(m.clientId)
    m.deviceName = "ELVANOQ Play Roku"
    m.deviceCodeValue = formatDeviceCode(m.clientId)
    m.deviceCode.text = m.deviceCodeValue
    m.top.observeField("deepLink", "onDeepLink")
    m.top.observeField("memoryWarning", "onMemoryWarning")
    ' Versao da Roku Store (manifest store_edition=true): gratuita, sem Portal nem licenca;
    ' a lista e conectada na propria TV (exigencia de certificacao da Roku).
    m.storeEdition = (CreateObject("roAppInfo").GetValue("store_edition") = "true")
    if m.storeEdition then
        startStoreEdition()
        return
    end if
    if m.clientId = "" or m.deviceKey = "" or m.deviceCodeValue = "ROKU-CÓDIGO-INDISPONÍVEL" then
        m.status.text = "Não foi possível preparar a ativação deste Roku. Reinicie o aplicativo."
        setStatusTone("error")
        return
    end if
    renderActivationQr()
    m.status.text = "Conectando ao Portal para ativação…"
    setStatusTone("connecting")
    requestPortal("roku-device-register")
    m.registerTimer.control = "start"
    m.licenseTimer.control = "start"
    signalActivationDialog()
end sub

' Avisa a Roku que a primeira tela esta pronta (certificacao 3.2: medir o tempo de abertura).
' A tela de ativacao/login aparece antes do Inicio: a Roku pede AppDialogInitiate ao mostrar
' e AppDialogComplete ao sair dela; AppLaunchComplete so quando o Inicio e exibido.
sub signalActivationDialog()
    if m.launchSignaled = true or m.dialogSignaled = true then return
    m.dialogSignaled = true
    m.top.signalBeacon("AppDialogInitiate")
end sub

sub signalLaunch()
    if m.launchSignaled = true then return
    if m.dialogSignaled = true then
        m.top.signalBeacon("AppDialogComplete")
        m.dialogSignaled = false
    end if
    m.launchSignaled = true
    m.top.signalBeacon("AppLaunchComplete")
end sub

sub onMemoryWarning()
    if m.appShell <> invalid then m.appShell.callFunc("releaseMemory")
end sub

sub onDeepLink()
    link = m.top.deepLink
    if link = invalid or link.contentId = invalid or link.contentId = "" then return
    m.pendingDeepLink = link
    if m.appShell <> invalid then
        m.appShell.deepLink = link
        m.pendingDeepLink = invalid
    end if
end sub

' ---------- Versao da loja: lista conectada na TV ----------

sub startStoreEdition()
    saved = loadStorePlaylist()
    if saved <> invalid then
        connectStorePlaylist(saved, false)
        return
    end if
    showStoreConnect("Nenhuma lista conectada neste aparelho.", "waiting")
end sub

sub showStoreConnect(message as String, tone as String)
    setActivationVisible(true)
    for each id in ["portalCaption", "codeBorder", "codeCard", "codeLabel", "deviceCode", "qrGroup", "portal"]
        m.top.findNode(id).visible = false
    end for
    m.eyebrow.text = "PRIMEIRO ACESSO"
    m.headline.text = "Conecte sua lista"
    m.description.text = "O ELVANOQ Play é um player: ele não fornece canais nem conteúdo."
    m.top.findNode("stepText1").text = "Tenha em mãos o servidor, usuário e senha do seu provedor"
    m.top.findNode("stepText2").text = "Aperte OK e informe os dados com o controle remoto"
    m.top.findNode("stepText3").text = "Pronto: canais, filmes e séries aparecem na sua TV"
    m.storeLayout = true
    for each id in ["checkButton", "checkIcon", "checkButtonText", "helpButton", "helpIcon", "helpButtonText"]
        m.top.findNode(id).visible = false
    end for
    m.actionIndex = 0
    m.top.findNode("stepsGroup").translation = [112, 408]
    m.serverCodeButton.translation = [112, 600]
    m.serverCodeButtonText.translation = [112, 600]
    m.top.findNode("statusDot").translation = [112, 733]
    m.status.translation = [140, 720]
    layoutActivationActions()
    if m.retryPlaylist <> invalid then
        m.serverCodeButtonText.text = "Tentar de novo   •   *  Outra lista"
    else
        m.serverCodeButtonText.text = "Conectar minha lista"
    end if
    layoutActivationActions()
    m.status.text = message
    setStatusTone(tone)
    restoreActivationFocus()
    signalActivationDialog()
end sub

function loadStorePlaylist() as Object
    raw = CreateObject("roRegistrySection", "ELVANOQPlay").Read("store_playlist")
    if raw = "" then return invalid
    playlist = ParseJson(raw)
    if playlist = invalid or type(playlist) <> "roAssociativeArray" then return invalid
    return playlist
end function

sub saveStorePlaylist(playlist as Object)
    section = CreateObject("roRegistrySection", "ELVANOQPlay")
    section.Write("store_playlist", FormatJson(playlist))
    section.Flush()
end sub

sub clearStorePlaylist()
    section = CreateObject("roRegistrySection", "ELVANOQPlay")
    section.Delete("store_playlist")
    section.Delete("playlist_metadata")
    section.Flush()
end sub

sub openStoreServerKeyboard()
    m.status.text = "Informe o servidor da sua lista."
    setStatusTone("waiting")
    dialog = CreateObject("roSGNode", "StandardKeyboardDialog")
    dialog.title = "Servidor da lista"
    dialog.message = "Digite o endereço do servidor (ex.: http://servidor.com:8080) ou o link completo da lista M3U."
    dialog.buttons = ["Continuar", "Cancelar"]
    dialog.text = "http://"
    dialog.observeField("buttonSelected", "onStoreServerKeyboardSelected")
    m.inputDialog = dialog
    m.top.dialog = dialog
end sub

sub onStoreServerKeyboardSelected()
    dialog = m.inputDialog
    m.top.dialog = invalid
    m.inputDialog = invalid
    if dialog = invalid or dialog.buttonSelected <> 0 then
        showStoreConnect("Conexão cancelada.", "waiting")
        return
    end if
    value = safeTrim(dialog.text)
    lower = lcase(value)
    if value = "" or lower = "http://" or lower = "https://" or instr(1, value, " ") > 0 then
        showStoreConnect("Endereço inválido. Confira e tente novamente.", "error")
        return
    end if
    if left(lower, 7) <> "http://" and left(lower, 8) <> "https://" then
        value = "http://" + value
        lower = lcase(value)
    end if
    ' Link completo (get.php ou .m3u): conecta direto; o carregador reconhece o get.php como Xtream.
    if instr(1, lower, "get.php?") > 0 or instr(1, lower, "username=") > 0 or instr(1, lower, ".m3u") > 0 then
        connectStorePlaylist({ source_type: "m3u", url: value }, true)
        return
    end if
    while right(value, 1) = "/"
        value = left(value, len(value) - 1)
    end while
    m.resolvedHost = value
    openCredentialKeyboard("username")
end sub

sub connectStorePlaylist(playlist as Object, isNew as Boolean)
    m.storePlaylist = playlist
    m.storeIsNew = isNew
    m.retryPlaylist = invalid
    setActivationVisible(false)
    openAppShell()
    if m.appShell = invalid then return
    m.appShell.callFunc("applyPlaylist", { display_name: "Minha lista", playlist: playlist })
end sub

sub onStoreCatalogState()
    if not m.storeEdition or m.appShell = invalid then return
    state = m.appShell.catalogState
    if state = invalid then return
    if state.ok = true then
        if m.storeIsNew = true and m.storePlaylist <> invalid then saveStorePlaylist(m.storePlaylist)
        m.storeIsNew = false
        return
    end if
    message = "Não foi possível carregar a lista."
    if state.message <> invalid and state.message <> "" then message = state.message
    if m.storeIsNew <> true and m.storePlaylist <> invalid then m.retryPlaylist = m.storePlaylist
    returnToStoreConnect(message, "error")
end sub

sub onStoreDisconnect()
    if m.appShell = invalid or m.appShell.disconnectRequested <> true then return
    clearStorePlaylist()
    m.storePlaylist = invalid
    m.retryPlaylist = invalid
    returnToStoreConnect("Lista desconectada. Conecte uma nova lista quando quiser.", "waiting")
end sub

sub returnToStoreConnect(message as String, tone as String)
    if m.appShell <> invalid then
        m.appShell.callFunc("stopPlayback")
        m.appShell.visible = false
    end if
    m.top.dialog = invalid
    showStoreConnect(message, tone)
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
    if not press then return false
    if m.appShell <> invalid and m.appShell.visible then return false
    ' Aviso de teste encerrado: OK verifica de novo; Voltar sai do app (Roku exige sair pela tela inicial).
    if m.expiredOverlay <> invalid and m.expiredOverlay.visible then
        if key = "back" then return false
        if key = "OK" then
            m.top.findNode("expiredInfo").text = "Verificando a ativação…"
            requestPortal("roku-device-register")
        end if
        return true
    end if
    if m.storeEdition = true and m.inputDialog = invalid then
        if key = "OK" and m.retryPlaylist <> invalid then
            connectStorePlaylist(m.retryPlaylist, false)
            return true
        end if
        if key = "OK" or key = "options" then
            openStoreServerKeyboard()
            return true
        end if
        return false
    end if
    if key = "OK" and m.inputDialog = invalid then
        if m.channelStore = invalid then runActivationAction()
        return true
    end if
    if key = "up" or key = "down" or key = "left" or key = "right" then
        moveActivationFocus(key)
        return true
    end if
    return false
end function

' ---------- Acoes da ativacao: botao principal + "Verificar ativacao" + "Como ativar" ----------

sub moveActivationFocus(key as String)
    index = m.actionIndex
    if key = "down" and index = 0 then index = 1
    if key = "up" and index > 0 then index = 0
    if key = "right" and index = 1 then index = 2
    if key = "left" and index = 2 then index = 1
    if index = m.actionIndex then return
    m.actionIndex = index
    layoutActivationActions()
end sub

sub runActivationAction()
    if m.actionIndex = 1 then
        m.status.text = "Verificando a ativação…"
        setStatusTone("connecting")
        requestPortal("roku-device-register")
    else if m.actionIndex = 2 then
        openActivationHelp()
    else
        startServerCodeLogin()
    end if
end sub

sub openActivationHelp()
    dialog = CreateObject("roSGNode", "StandardMessageDialog")
    dialog.title = "Como ativar esta TV"
    dialog.message = ["Código desta TV: " + m.deviceCodeValue, "1. No celular ou computador, abra elvanoqplay.app", "2. Ou aponte a câmera do celular para o QR code da tela", "3. Informe o código desta TV e cadastre a sua lista", "4. A TV ativa sozinha em alguns segundos", "Tem o código do seu servidor? Use \"Entrar com código do servidor\"."]
    dialog.buttons = ["Entendi"]
    dialog.observeField("buttonSelected", "closeActivationHelp")
    dialog.observeField("wasClosed", "closeActivationHelp")
    m.helpDialog = dialog
    m.top.dialog = dialog
end sub

sub closeActivationHelp()
    if m.helpDialog = invalid then return
    m.helpDialog = invalid
    m.top.dialog = invalid
    restoreActivationFocus()
end sub

' Icone + texto centralizados juntos em cada botao; o foco e o anel ciano.
' Larguras medidas com a fonte Inter nos tamanhos usados.
sub layoutActivationActions()
    primary = m.serverCodeButton.translation
    textWidth = 428
    if m.serverCodeButtonText.text <> "Entrar com código do servidor" then textWidth = len(m.serverCodeButtonText.text) * 16
    startX = primary[0] + int((930 - (33 + 18 + textWidth)) / 2)
    m.top.findNode("serverCodeIcon").translation = [startX, primary[1] + 30]
    m.serverCodeButtonText.translation = [startX + 51, primary[1]]
    m.serverCodeButtonText.width = textWidth + 40
    m.serverCodeButtonText.horizAlign = "left"
    inner = m.top.findNode("serverCodeInner")
    if m.actionIndex = 0 then
        m.serverCodeButton.color = "0x00D7FFFF"
        inner.translation = [primary[0] + 4, primary[1] + 4]
        inner.width = 922
        inner.height = 85
    else
        m.serverCodeButton.color = "0xF4F8FFFF"
        inner.translation = primary
        inner.width = 930
        inner.height = 93
    end if
    layoutShortcut("check", 112, 204, m.actionIndex = 1)
    layoutShortcut("help", 583, 140, m.actionIndex = 2)
end sub

sub layoutShortcut(prefix as String, x as Integer, textWidth as Integer, focused as Boolean)
    button = m.top.findNode(prefix + "Button")
    startX = x + int((459 - (28 + 15 + textWidth)) / 2)
    m.top.findNode(prefix + "Icon").translation = [startX, 911]
    label = m.top.findNode(prefix + "ButtonText")
    label.translation = [startX + 43, 885]
    label.width = textWidth + 30
    label.horizAlign = "left"
    if focused then
        button.color = "0xFFFFFF24"
        button.borderColor = "0x00D7FFFF"
    else
        button.color = "0x0D1422B8"
        button.borderColor = "0xBEDCFF29"
    end if
end sub

sub clearParentalSession()
    section = CreateObject("roRegistrySection", "ELVANOQPlay")
    section.Delete("parental_session")
    section.Flush()
end sub

sub onLicenseTimer()
    requestPortal("roku-device-register")
end sub

sub onRegisterTimer()
    requestPortal("roku-device-register")
end sub

sub onPortalWatchdog()
    if m.requestInFlight = true then
        ' Libera o "em andamento": antes a flag ficava presa e nenhuma nova consulta era feita
        cancelPendingPortalRequest()
        m.status.text = "A conexão está demorando. Tentaremos novamente em instantes."
        setStatusTone("waiting")
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

sub onPortalResult(event as Object)
    node = event.getRoSGNode()
    if m.portalRequest = invalid or node = invalid then return
    if not node.isSameNode(m.portalRequest) then return
    result = node.result
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
    m.expiredOverlay.visible = (state = "expired")
    if state = "expired" then
        m.top.findNode("expiredCode").text = m.deviceCodeValue
        m.top.findNode("expiredInfo").text = "A ativação é verificada automaticamente a cada minuto."
    end if
    if state = "active" then
        m.licenseTimer.control = "start"
        setActivationVisible(false)
        m.homeStatus.visible = false
        openAppShell()
        return
    end if
    if (state = "expired" or state = "blocked") and m.appShell <> invalid and m.appShell.visible then
        m.appShell.callFunc("stopPlayback")
        m.appShell.visible = false
        m.top.dialog = invalid
        restoreActivationFocus()
    end if
    m.homeStatus.visible = false
    setActivationVisible(true)
    if state = "expired" then
        m.status.text = "Teste gratuito encerrado. Este aparelho não possui licença ativa."
        setStatusTone("error")
    else if state = "blocked" then
        m.status.text = "Dispositivo bloqueado. Consulte o suporte no Portal."
        setStatusTone("error")
    else if state = "offline" then
        if message <> invalid and message <> "" then
            m.status.text = message
            setStatusTone("error")
        else
            m.status.text = "Sem conexão. A tela continuará disponível e a ativação será verificada novamente."
            setStatusTone("error")
        end if
    else if state = "error" then
        if message <> invalid and message <> "" then
            m.status.text = message
            setStatusTone("error")
        else
            m.status.text = "Falha ao consultar o Portal. Vamos tentar novamente."
            setStatusTone("error")
        end if
    else
        m.status.text = "Aguardando ativação. Vincule esta TV em elvanoqplay.app."
        setStatusTone("waiting")
    end if
end sub

sub onServerCodeButtonSelected()
    if m.inputDialog <> invalid or m.channelStore <> invalid then return
    startServerCodeLogin()
end sub

sub restoreActivationFocus()
    ' The Scene owns the remote focus while activation is displayed.
    ' This keeps OK delivery independent of a transparent or native overlay.
    m.top.setFocus(true)
end sub

' Login (Roku 2.1/4.1): antes do primeiro login, pede o e-mail pela tela nativa da Roku
' ("Request for Information"). E opcional: recusando, o login segue normalmente.
sub startServerCodeLogin()
    section = CreateObject("roRegistrySection", "ELVANOQPlay")
    if section.Read("rfi_asked") = "1" then
        openServerCodeKeyboard()
        return
    end if
    section.Write("rfi_asked", "1")
    section.Flush()
    store = CreateObject("roSGNode", "ChannelStore")
    info = CreateObject("roSGNode", "ContentNode")
    info.addFields({ context: "signin" })
    store.requestedUserData = "email"
    store.requestedUserDataInfo = info
    store.observeField("userData", "onUserDataResult")
    m.top.appendChild(store)
    m.channelStore = store
    store.command = "getUserData"
end sub

sub onUserDataResult()
    store = m.channelStore
    m.channelStore = invalid
    if store <> invalid then
        data = store.userData
        if data <> invalid and data.email <> invalid and data.email <> "" then
            section = CreateObject("roRegistrySection", "ELVANOQPlay")
            section.Write("contact_email", data.email)
            section.Flush()
        end if
        m.top.removeChild(store)
    end if
    restoreActivationFocus()
    openServerCodeKeyboard()
end sub

sub openServerCodeKeyboard()
    m.status.text = "Informe o código do servidor para continuar."
    setStatusTone("waiting")
    dialog = CreateObject("roSGNode", "StandardKeyboardDialog")
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
        restoreActivationFocus()
        return
    end if
    code = normalizeServerCode(dialog.text)
    if code = "" then
        m.status.text = "Código inválido. Confira o código e tente novamente."
        setStatusTone("error")
        restoreActivationFocus()
        return
    end if
    m.serverCodeInput = code
    m.status.text = "Validando o código do servidor…"
    setStatusTone("connecting")
    requestPortal("roku-server-code-resolve")
end sub

sub handleServerCodeResult(result as Object)
    if result.ok <> true then
        m.status.text = "Não foi possível validar este código. Tente novamente."
        setStatusTone("error")
        return
    end if
    host = serverHostFromPayload(result.payload)
    if host = "" then
        m.status.text = "O Portal não retornou um servidor compatível."
        setStatusTone("error")
        return
    end if
    m.resolvedHost = host
    openCredentialKeyboard("username")
end sub

sub openCredentialKeyboard(stage as String)
    dialog = CreateObject("roSGNode", "StandardKeyboardDialog")
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
        if dialog.textEditBox <> invalid then dialog.textEditBox.secureMode = true
    end if
    m.inputDialog = dialog
    m.top.dialog = dialog
end sub

sub onUsernameKeyboardSelected()
    dialog = m.inputDialog
    m.top.dialog = invalid
    m.inputDialog = invalid
    if dialog = invalid or dialog.buttonSelected <> 0 or safeTrim(dialog.text) = "" then
        if m.storeEdition = true then
            showStoreConnect("Conexão cancelada.", "waiting")
            return
        end if
        m.status.text = "Login por código cancelado."
        setStatusTone("waiting")
        restoreActivationFocus()
        return
    end if
    m.manualUsername = safeTrim(dialog.text)
    openCredentialKeyboard("password")
end sub

sub onPasswordKeyboardSelected()
    dialog = m.inputDialog
    m.top.dialog = invalid
    m.inputDialog = invalid
    if dialog = invalid or dialog.buttonSelected <> 0 or dialog.text = "" then
        if m.storeEdition = true then
            showStoreConnect("Conexão cancelada.", "waiting")
            return
        end if
        m.status.text = "Login por código cancelado."
        setStatusTone("waiting")
        restoreActivationFocus()
        return
    end if
    password = dialog.text
    playlist = { source_type: "xtream", credentials: { host: m.resolvedHost, username: m.manualUsername, password: password } }
    if m.storeEdition = true then
        m.manualUsername = ""
        m.resolvedHost = ""
        connectStorePlaylist(playlist, true)
        return
    end if
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
    value = safeTrim(value)
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
    ids = ["background", "ambientBottom", "loginShade", "loginShadeBottom", "brandMark", "clockTime", "clockDate", "eyebrow", "headline", "description", "stepsGroup", "portalCaption", "codeBorder", "codeCard", "deviceCode", "qrGroup", "portal", "serverCodeButton", "serverCodeInner", "serverCodeIcon", "serverCodeButtonText", "serverCodeAction", "codeLabel", "checkButton", "checkIcon", "checkButtonText", "helpButton", "helpIcon", "helpButtonText", "statusDot", "status", "appVersion"]
    for each id in ids
        node = m.top.findNode(id)
        if node <> invalid then node.visible = isVisible
    end for
    if isVisible then
        m.clockTimer.control = "start"
        m.statusPulse.control = "start"
    else
        m.clockTimer.control = "stop"
        m.statusPulse.control = "stop"
    end if
end sub

' QR com o codigo do aparelho: o Portal abre ja com o codigo preenchido.
' Se algo falhar, fica o QR fixo que leva so para a pagina do Portal.
sub renderActivationQr()
    url = "https://elvanoqplay.app/adicionar-lista/?codigo=" + m.deviceCodeValue
    matrix = qrMatrix(url)
    if matrix = invalid then return
    holder = m.top.findNode("qrModules")
    ' Modulos de 8 px centralizados no cartao branco de 294 px.
    moduleSize = 8
    if matrix.count() * moduleSize > 264 then moduleSize = int(264 / matrix.count())
    offset = int((294 - matrix.count() * moduleSize) / 2)
    holder.translation = [offset, offset]
    for r = 0 to matrix.count() - 1
        row = matrix[r]
        c = 0
        while c < row.count()
            if row[c] = 1 then
                start = c
                while c < row.count() and row[c] = 1
                    c = c + 1
                end while
                block = holder.createChild("Rectangle")
                block.translation = [start * moduleSize, r * moduleSize]
                block.width = (c - start) * moduleSize
                block.height = moduleSize
                block.color = "0x070B14FF"
            else
                c = c + 1
            end if
        end while
    end for
    m.top.findNode("qrStatic").visible = false
end sub

sub setStatusTone(tone as String)
    if m.statusDot = invalid then return
    if tone = "error" then
        m.statusDot.blendColor = "0xFF5C72FF"
        m.status.color = "0xFFB3BEFF"
        m.statusPulse.control = "stop"
        m.statusDot.opacity = 1.0
        return
    end if
    if tone = "waiting" then
        m.statusDot.blendColor = "0xFFB547FF"
    else if tone = "active" then
        m.statusDot.blendColor = "0x2EE59DFF"
    else
        m.statusDot.blendColor = "0x00D7FFFF"
    end if
    m.status.color = "0xF4F8FFFF"
    m.statusPulse.control = "start"
end sub

sub updateActivationClock()
    if m.clockTime = invalid then return
    now = CreateObject("roDateTime")
    now.ToLocalTime()
    h = now.GetHours()
    mi = now.GetMinutes()
    hs = h.ToStr()
    if h < 10 then hs = "0" + hs
    ms = mi.ToStr()
    if mi < 10 then ms = "0" + ms
    m.clockTime.text = hs + ":" + ms
    days = ["Domingo", "Segunda", "Terça", "Quarta", "Quinta", "Sexta", "Sábado"]
    months = ["jan", "fev", "mar", "abr", "mai", "jun", "jul", "ago", "set", "out", "nov", "dez"]
    m.clockDate.text = days[now.GetDayOfWeek()] + ", " + now.GetDayOfMonth().ToStr() + " " + months[now.GetMonth() - 1]
end sub

sub openAppShell()
    if m.appShell <> invalid then
        m.appShell.visible = true
        signalLaunch()
        if m.top.dialog = invalid and not m.appShell.isInFocusChain() then m.appShell.setFocus(true)
        return
    end if
    m.appShell = CreateObject("roSGNode", "AppShell")
    m.appShell.rokuClientId = m.clientId
    m.appShell.deviceCode = m.deviceCodeValue
    m.appShell.deviceKey = m.deviceKey
    m.appShell.storeEdition = (m.storeEdition = true)
    m.appShell.observeField("catalogState", "onStoreCatalogState")
    m.appShell.observeField("disconnectRequested", "onStoreDisconnect")
    m.top.appendChild(m.appShell)
    m.appShell.setFocus(true)
    if m.pendingDeepLink <> invalid then
        m.appShell.deepLink = m.pendingDeepLink
        m.pendingDeepLink = invalid
    end if
    signalLaunch()
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
