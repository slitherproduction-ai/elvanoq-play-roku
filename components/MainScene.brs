sub init()
    i18nAttach(m.top)
    clearParentalSession()
    m.playlistSynced = false
    m.manualSession = false
    m.catalogAuthenticated = false
    m.catalogAuthPending = false
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
    m.codeLoginActive = false
    m.portalWatchdog = m.top.findNode("portalWatchdog")
    m.registerTimer = m.top.findNode("registerTimer")
    m.statusDot = m.top.findNode("statusDot")
    m.statusPulse = m.top.findNode("statusPulse")
    m.clockTime = m.top.findNode("clockTime")
    m.clockDate = m.top.findNode("clockDate")
    m.clockTimer = m.top.findNode("clockTimer")
    ' Padrao do login Android 2.17.23 (o mesmo da LG 1.1.1).
    m.eyebrow.font = appFont(18, "bold")
    m.eyebrow.color = "0x00D7FFFF"
    m.headline.font = appFont(72, "bold")
    m.headline.color = "0xF4F8FFFF"
    m.description.font = appFont(24, "regular")
    m.description.color = "0xC9D2E3FF"
    for i = 1 to 3
        n = m.top.findNode("stepNumber" + i.ToStr())
        ' Passos no padrao do redesign: numero ciano sobre #1A2438.
        n.font = appFont(20, "bold")
        n.color = "0x00D7FFFF"
        t = m.top.findNode("stepText" + i.ToStr())
        t.font = appFont(24, "regular")
        t.color = "0xF4F8FFFF"
    end for
    ' Codigo numa linha so, menor (redesign).
    m.deviceCode.font = appFont(36, "bold")
    m.deviceCode.color = "0xFFFFFFFF"
    m.portalCaption.font = appFont(19, "bold")
    m.portalCaption.color = "0x8E9AAEFF"
    codeLabel = m.top.findNode("codeLabel")
    codeLabel.font = appFont(16, "bold")
    codeLabel.color = "0x8E9AAEFF"
    qrCaption = m.top.findNode("qrCaption")
    qrCaption.font = appFont(20, "regular")
    qrCaption.color = "0xB8C4D6FF"
    m.portal.font = appFont(26, "bold")
    m.portal.color = "0x00D7FFFF"
    m.serverCodeButtonText.font = appFont(24, "bold")
    m.serverCodeButtonText.color = "0x070B14FF"
    m.checkButton = m.top.findNode("checkButton")
    m.helpButton = m.top.findNode("helpButton")
    for each id in ["checkButtonText", "helpButtonText"]
        label = m.top.findNode(id)
        label.font = appFont(20, "semibold")
        label.color = "0xF4F8FFFF"
    end for
    m.actionIndex = 0
    ' Idioma: pilula no topo e janela de escolha (Automatico, Portugues, English).
    m.languagePill = m.top.findNode("languagePill")
    m.languagePillBg = m.top.findNode("languagePillBg")
    m.languageLabel = m.top.findNode("languageLabel")
    m.languageLabel.font = appFont(20, "semibold")
    m.textMeasure = m.top.findNode("textMeasure")
    m.languageOverlay = m.top.findNode("languageOverlay")
    m.languageValues = ["auto", "pt", "en"]
    labels = ["Automático", "Português (Brasil)", "English"]
    subs = ["Igual ao idioma da TV", "Português", "Inglês"]
    for i = 0 to 2
        label = m.top.findNode("languageOptionLabel" + i.ToStr())
        label.font = appFont(26, "semibold")
        label.text = labels[i]
        subLabel = m.top.findNode("languageOptionSub" + i.ToStr())
        subLabel.font = appFont(18, "regular")
        subLabel.text = subs[i]
    end for
    title = m.top.findNode("languageTitle")
    title.font = appFont(34, "bold")
    title.color = "0xF4F8FFFF"
    text = m.top.findNode("languageText")
    text.font = appFont(20, "regular")
    text.color = "0x9AA6BDFF"
    hint = m.top.findNode("languageHint")
    hint.font = appFont(18, "regular")
    hint.color = "0x7F8BA3FF"
    m.global.observeField("language", "onMainLanguage")
    layoutLanguagePill()
    layoutActivationActions()
    m.status.font = appFont(20, "regular")
    m.status.color = "0xB8C4D6FF"
    m.homeStatus.font = appFont(40, "bold")
    m.clockTime.font = appFont(44, "semibold")
    m.clockTime.color = "0xF4F8FFFF"
    m.clockDate.font = appFont(20, "regular")
    m.clockDate.color = "0x8894A8FF"
    m.appVersion.font = appFont(18, "regular")
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
    if CreateObject("roRegistrySection", "ELVANOQPlay").Read("login_removed") = "true" then
        m.status.text = "Login excluído. Entre novamente para continuar."
        return
    end if
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
    m.top.findNode("stepsGroup").translation = [96, 446]
    m.serverCodeButton.translation = [96, 672]
    m.serverCodeButtonText.translation = [96, 672]
    m.top.findNode("statusDot").translation = [96, 786]
    m.status.translation = [120, 772]
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
    loginSection = CreateObject("roRegistrySection", "ELVANOQPlay")
    loginSection.Delete("login_removed")
    loginSection.Flush()
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
    dialog.message = ["Digite o endereço do servidor (ex.: http://servidor.com:8080) ou o link completo da lista M3U."]
    dialog.buttons = ["Continuar", "Cancelar"]
    dialog.text = "http://"
    dialog.observeField("buttonSelected", "onStoreServerKeyboardSelected")
    m.inputDialog = dialog
    i18nDialog(dialog)
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
    m.catalogAuthenticated = false
    m.catalogAuthPending = true
    setActivationVisible(false)
    openAppShell()
    if m.appShell = invalid then return
    m.appShell.callFunc("applyPlaylist", { display_name: "Minha lista", playlist: playlist })
end sub

sub onStoreCatalogState()
    if m.appShell = invalid then return
    state = m.appShell.catalogState
    if state = invalid then return
    if m.storeEdition and m.catalogAuthPending = true then
        m.catalogAuthPending = false
        m.catalogAuthenticated = (state.ok = true)
        if m.catalogAuthenticated then openAppShell()
    end if
    if not m.storeEdition then
        if m.catalogAuthPending <> true then return
        m.catalogAuthPending = false
        m.codeLoginActive = false
        if state.ok = true then
            m.catalogAuthenticated = true
            setActivationVisible(false)
            m.homeStatus.visible = false
            openAppShell()
        else
            m.catalogAuthenticated = false
            m.appShell.visible = false
            setActivationVisible(true)
            m.status.text = "Não foi possível autenticar a lista. Confira usuário e senha e tente novamente."
            if state.message <> invalid and state.message <> "" then m.status.text = state.message
            setStatusTone("error")
            restoreActivationFocus()
        end if
        return
    end if
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
    clearParentalSession()
    cancelPendingPortalRequest()
    m.licenseTimer.control = "stop"
    m.registerTimer.control = "stop"
    m.storePlaylist = invalid
    m.retryPlaylist = invalid
    m.manualUsername = ""
    m.resolvedHost = ""
    m.serverCodeInput = ""
    m.playlistSynced = false
    m.manualSession = false
    m.catalogAuthenticated = false
    m.catalogAuthPending = false
    m.appShell.callFunc("stopPlayback")
    m.top.removeChild(m.appShell)
    m.appShell = invalid
    section = CreateObject("roRegistrySection", "ELVANOQPlay")
    section.Delete("playlist_metadata")
    section.Write("login_removed", "true")
    section.Flush()
    if m.storeEdition then
        showStoreConnect("Login excluído. Conecte uma nova lista.", "waiting")
    else
        setActivationVisible(true)
        m.status.text = "Login excluído. Entre novamente para continuar."
        setStatusTone("waiting")
        restoreActivationFocus()
    end if
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
    if m.languageOverlay <> invalid and m.languageOverlay.visible then
        handleLanguageKey(key)
        return true
    end if
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
        if key = "up" or key = "down" then
            m.actionIndex = 0
            if key = "up" then m.actionIndex = 3
            layoutLanguagePill()
            return true
        end if
        if key = "OK" and m.actionIndex = 3 then
            openLanguagePicker()
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
    ' ↑ a partir do botao principal leva ao idioma; ↓ volta.
    if index = 3 then
        if key = "down" then index = 0
    else if key = "up" and index = 0 then
        index = 3
    else if key = "down" and index = 0 then
        index = 1
    end if
    if index = 3 or m.actionIndex = 3 then
        m.actionIndex = index
        layoutActivationActions()
        layoutLanguagePill()
        return
    end if
    if key = "up" and index > 0 then index = 0
    if key = "right" and index = 1 then index = 2
    if key = "left" and index = 2 then index = 1
    if index = m.actionIndex then return
    m.actionIndex = index
    layoutActivationActions()
end sub

sub runActivationAction()
    if m.actionIndex = 3 then
        openLanguagePicker()
        return
    end if
    if m.actionIndex <> 2 then
        section = CreateObject("roRegistrySection", "ELVANOQPlay")
        section.Delete("login_removed")
        section.Flush()
    end if
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
    dialog.message = ["Código desta TV: " + m.deviceCodeValue, "1. No celular ou computador, abra elvanoqplay.app", "2. Ou aponte a câmera do celular para o QR code da tela", "3. Informe o código desta TV e cadastre a sua lista", "4. A TV ativa sozinha em alguns segundos", "Tem o código do seu servidor? Use ""Entrar com código do servidor""."]
    dialog.buttons = ["Entendi"]
    dialog.observeField("buttonSelected", "closeActivationHelp")
    dialog.observeField("wasClosed", "closeActivationHelp")
    m.helpDialog = dialog
    i18nDialog(dialog)
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
    textWidth = 354
    if m.serverCodeButtonText.text <> "Entrar com código do servidor" then textWidth = len(m.serverCodeButtonText.text) * 13
    if i18nLanguage() = "en" then textWidth = measureText(m.serverCodeButtonText)
    startX = primary[0] + int((760 - (28 + 16 + textWidth)) / 2)
    m.top.findNode("serverCodeIcon").translation = [startX, primary[1] + 24]
    m.serverCodeButtonText.translation = [startX + 44, primary[1]]
    m.serverCodeButtonText.width = textWidth + 40
    m.serverCodeButtonText.horizAlign = "left"
    ' Foco = pilula clara com texto escuro; sem foco = superficie escura com
    ' texto claro (mesma regra do menu, do player e dos Ajustes).
    inner = m.top.findNode("serverCodeInner")
    icon = m.top.findNode("serverCodeIcon")
    inner.translation = primary
    inner.width = 760
    inner.height = 76
    m.serverCodeButton.color = "0x00000000"
    if m.actionIndex = 0 then
        inner.color = "0xF4F8FFFF"
        m.serverCodeButtonText.color = "0x070B14FF"
        icon.blendColor = "0x070B14FF"
    else
        inner.color = "0x0E1524EB"
        m.serverCodeButtonText.color = "0xF4F8FFFF"
        icon.blendColor = "0xF4F8FFFF"
    end if
    checkWidth = 170
    helpWidth = 117
    if i18nLanguage() = "en" then
        checkWidth = measureText(m.top.findNode("checkButtonText"))
        helpWidth = measureText(m.top.findNode("helpButtonText"))
    end if
    layoutShortcut("check", 96, checkWidth, m.actionIndex = 1)
    layoutShortcut("help", 484, helpWidth, m.actionIndex = 2)
end sub

sub layoutShortcut(prefix as String, x as Integer, textWidth as Integer, focused as Boolean)
    button = m.top.findNode(prefix + "Button")
    startX = x + int((372 - (24 + 12 + textWidth)) / 2)
    m.top.findNode(prefix + "Icon").translation = [startX, 918]
    label = m.top.findNode(prefix + "ButtonText")
    label.translation = [startX + 36, 900]
    label.width = textWidth + 30
    label.horizAlign = "left"
    icon = m.top.findNode(prefix + "Icon")
    if focused then
        button.color = "0xF4F8FFFF"
        label.color = "0x070B14FF"
        icon.blendColor = "0x070B14FF"
    else
        button.color = "0x0E1524EB"
        label.color = "0xF4F8FFFF"
        icon.blendColor = "0x00D7FFFF"
    end if
end sub

sub clearParentalSession()
    section = CreateObject("roRegistrySection", "ELVANOQPlay")
    section.Delete("parental_session")
    section.Flush()
end sub

sub onLicenseTimer()
    ' Durante o login por código a TV já fica ativa no Portal depois do código; a consulta
    ' periódica abriria o app por cima do teclado de usuário e senha.
    if m.codeLoginActive = true then return
    requestPortal("roku-device-register")
end sub

sub onRegisterTimer()
    if m.codeLoginActive = true then return
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
    if action = "roku-playlist-sync" and m.manualSession = true then return
    ' O código do servidor é ação do usuário: não pode ser descartado por uma consulta automática em andamento.
    if m.requestInFlight = true and action = "roku-server-code-resolve" then cancelPendingPortalRequest()
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
    ' Licença e sincronização não podem interromper credenciais/autenticação em andamento.
    if m.codeLoginActive = true and result.action <> "roku-server-code-resolve" then return
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
    ' Resposta de uma consulta automática que chegou durante o login por código: ignora.
    if m.codeLoginActive = true then return
    if result.action = "roku-playlist-sync" then
        ' Uma resposta atrasada nunca substitui as credenciais digitadas.
        if m.manualSession = true then return
        if result.ok = true then
            payload = result.payload
            if payload <> invalid and type(payload) = "roAssociativeArray" and payload.playlist <> invalid then
                m.playlistSynced = true
                m.catalogAuthenticated = false
                m.catalogAuthPending = true
                m.status.text = "Validando a lista vinculada no servidor IPTV…"
                setStatusTone("connecting")
                setActivationVisible(false)
                openAppShell()
                if m.appShell <> invalid then m.appShell.callFunc("applyPlaylist", result.payload)
            else
                setActivationVisible(true)
                m.status.text = "Nenhuma lista no Portal. Adicione pelo QR code ou entre com o código do servidor."
                setStatusTone("waiting")
            end if
        end if
        return
    end if
    if result.ok <> true then
        showActivationState(result.state, result.message)
        return
    end if
    showActivationState(result.state, result.message)
    if result.action = "roku-license-status" and result.state = "active" and m.playlistSynced <> true and m.manualSession <> true then requestPortal("roku-playlist-sync")
end sub

sub showActivationState(state as String, message as String)
    m.expiredOverlay.visible = (state = "expired")
    if state = "expired" then
        m.top.findNode("expiredCode").text = m.deviceCodeValue
        m.top.findNode("expiredInfo").text = "A ativação é verificada automaticamente a cada minuto."
    end if
    if state = "active" then
        m.licenseTimer.control = "start"
        if m.catalogAuthenticated <> true then
            setActivationVisible(true)
            if m.catalogAuthPending = true then
                m.status.text = "Validando o acesso no servidor IPTV…"
                setStatusTone("connecting")
            else
                m.status.text = "Licença ativa. Entre com o código do servidor ou adicione sua lista pelo QR code."
                setStatusTone("active")
            end if
            return
        end if
        setActivationVisible(false)
        m.homeStatus.visible = false
        firstOpen = (m.appShell = invalid)
        openAppShell()
        if firstOpen then showWelcomeBack()
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
    m.codeLoginActive = true
    m.status.text = "Informe o código do servidor para continuar."
    setStatusTone("waiting")
    dialog = CreateObject("roSGNode", "StandardKeyboardDialog")
    dialog.title = "Código do servidor"
    dialog.message = ["Digite o código recebido no Portal."]
    dialog.buttons = ["Continuar", "Cancelar"]
    dialog.observeField("buttonSelected", "onServerCodeKeyboardSelected")
    m.inputDialog = dialog
    i18nDialog(dialog)
    m.top.dialog = dialog
end sub

sub onServerCodeKeyboardSelected()
    dialog = m.inputDialog
    m.top.dialog = invalid
    m.inputDialog = invalid
    if dialog = invalid or dialog.buttonSelected <> 0 then
        m.codeLoginActive = false
        restoreActivationFocus()
        return
    end if
    code = normalizeServerCode(dialog.text)
    if code = "" then
        m.codeLoginActive = false
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
        m.codeLoginActive = false
        if result.message <> invalid and result.message <> "" and result.message <> "Não foi possível consultar o Portal." then
            m.status.text = result.message
        else
            m.status.text = "Não foi possível validar este código. Tente novamente."
        end if
        setStatusTone("error")
        restoreActivationFocus()
        return
    end if
    host = serverHostFromPayload(result.payload)
    if host = "" then
        m.codeLoginActive = false
        m.status.text = "O Portal não retornou um servidor compatível."
        setStatusTone("error")
        restoreActivationFocus()
        return
    end if
    m.resolvedHost = host
    openCredentialKeyboard("username")
end sub

sub openCredentialKeyboard(stage as String)
    dialog = CreateObject("roSGNode", "StandardKeyboardDialog")
    if stage = "username" then
        dialog.title = "Usuário da lista"
        dialog.message = ["Informe o usuário do seu acesso."]
        dialog.buttons = ["Continuar", "Cancelar"]
        dialog.observeField("buttonSelected", "onUsernameKeyboardSelected")
    else
        dialog.title = "Senha da lista"
        dialog.message = ["Informe a senha do seu acesso."]
        dialog.buttons = ["Conectar", "Cancelar"]
        dialog.observeField("buttonSelected", "onPasswordKeyboardSelected")
        if dialog.textEditBox <> invalid then dialog.textEditBox.secureMode = true
    end if
    m.inputDialog = dialog
    i18nDialog(dialog)
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
        m.codeLoginActive = false
        m.status.text = "Login por código cancelado."
        setStatusTone("waiting")
        restoreActivationFocus()
        requestPortal("roku-device-register")
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
        m.codeLoginActive = false
        m.status.text = "Login por código cancelado."
        setStatusTone("waiting")
        restoreActivationFocus()
        requestPortal("roku-device-register")
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
    m.codeLoginActive = true
    m.manualSession = true
    m.playlistSynced = true
    m.catalogAuthenticated = false
    m.catalogAuthPending = true
    m.status.text = "Validando usuário e senha no servidor IPTV…"
    setStatusTone("connecting")
    setActivationVisible(false)
    openAppShell()
    if m.appShell <> invalid then m.appShell.callFunc("applyPlaylist", { display_name: "Acesso por código", server_code: m.serverCodeInput, playlist: playlist })
    m.manualUsername = ""
    m.serverCodeInput = ""
    m.resolvedHost = ""
end sub

function serverHostFromPayload(payload as Object) as String
    if payload = invalid or type(payload) <> "roAssociativeArray" then return ""
    ' O portal-control responde { ok, state, payload: { server: { code, host } } }; o relay pode
    ' entregar esse objeto inteiro ou só o payload, então os dois formatos são aceitos.
    if payload.payload <> invalid and type(payload.payload) = "roAssociativeArray" then
        nested = serverHostFromPayload(payload.payload)
        if nested <> "" then return nested
    end if
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
    ' Modulos de 8 px centralizados no quadro branco de 300 px.
    moduleSize = 8
    if matrix.count() * moduleSize > 264 then moduleSize = int(264 / matrix.count())
    offset = int((300 - matrix.count() * moduleSize) / 2)
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
    if i18nLanguage() = "en" then
        days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
        m.clockDate.text = days[now.GetDayOfWeek()] + ", " + months[now.GetMonth() - 1] + " " + now.GetDayOfMonth().ToStr()
    else
        days = ["Domingo", "Segunda", "Terça", "Quarta", "Quinta", "Sexta", "Sábado"]
        months = ["jan", "fev", "mar", "abr", "mai", "jun", "jul", "ago", "set", "out", "nov", "dez"]
        m.clockDate.text = days[now.GetDayOfWeek()] + ", " + now.GetDayOfMonth().ToStr() + " " + months[now.GetMonth() - 1]
    end if
    layoutLanguagePill()
end sub

' "Bem-vindo de volta": na primeira abertura com lista salva, por 1,2 s, por
' cima da Inicio que ja carrega por baixo. Entra sozinho, sem apertar nada.
sub showWelcomeBack()
    if m.welcomeShown = true then return
    m.welcomeShown = true
    section = CreateObject("roRegistrySection", "ELVANOQPlay")
    raw = section.Read("playlist_metadata")
    if raw = invalid or raw = "" then return
    metadata = ParseJson(raw)
    if metadata = invalid or type(metadata) <> "roAssociativeArray" then return
    name = ""
    if metadata.display_name <> invalid then name = safeTrim(metadata.display_name)
    if name = "" then name = "Minha lista"
    overlay = m.top.findNode("welcomeOverlay")
    ' Traz o aviso para a frente da AppShell recem-criada.
    m.top.removeChild(overlay)
    m.top.appendChild(overlay)
    status = m.top.findNode("welcomeStatus")
    status.font = appFont(22, "regular")
    status.color = "0xC9D2E3FF"
    title = m.top.findNode("welcomeTitle")
    title.font = appFont(66, "bold")
    title.color = "0xF4F8FFFF"
    subtitle = m.top.findNode("welcomeSubtitle")
    subtitle.font = appFont(27, "regular")
    subtitle.color = "0xC9D2E3FF"
    initial = m.top.findNode("welcomeInitial")
    initial.font = appFont(34, "bold")
    initial.color = "0x00D7FFFF"
    initial.text = ucase(left(name, 1))
    nameLabel = m.top.findNode("welcomeName")
    nameLabel.font = appFont(30, "bold")
    nameLabel.color = "0xF4F8FFFF"
    nameLabel.text = name
    info = m.top.findNode("welcomeInfo")
    info.font = appFont(20, "regular")
    info.color = "0x9AA6BDFF"
    m.top.findNode("welcomeBar").width = 0
    overlay.visible = true
    animation = m.top.findNode("welcomeAnimation")
    animation.observeField("state", "onWelcomeAnimation")
    animation.control = "start"
end sub

sub onWelcomeAnimation()
    animation = m.top.findNode("welcomeAnimation")
    if animation.state <> "stopped" then return
    m.top.findNode("welcomeOverlay").visible = false
end sub

sub openAppShell()
    if m.appShell <> invalid then
        if m.catalogAuthenticated <> true then
            m.appShell.visible = false
            setActivationVisible(true)
            restoreActivationFocus()
            return
        end if
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
    m.appShell.visible = false
    m.top.appendChild(m.appShell)
    if m.catalogAuthenticated <> true then
        setActivationVisible(true)
        restoreActivationFocus()
        return
    end if
    m.appShell.visible = true
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

' ---------- Idioma do aplicativo ----------

function measureText(label as Object) as Integer
    m.textMeasure.font = label.font
    m.textMeasure.text = label.text
    return Int(m.textMeasure.boundingRect().width)
end function

function languageName(preference as String) as String
    if preference = "en" then return "English"
    if preference = "pt" then return "Português (Brasil)"
    return "Automático"
end function

' Pilula ao lado do relogio: 18 + globo 26 + 12 + texto + 12 + seta 20 + 22,
' terminando a 36 px do texto mais largo do relogio.
sub layoutLanguagePill()
    if m.languagePill = invalid then return
    m.languageLabel.text = languageName(i18nPreference())
    labelWidth = measureText(m.languageLabel)
    m.languageLabel.width = labelWidth + 4
    width = 18 + 26 + 12 + labelWidth + 12 + 20 + 22
    m.languagePillBg.width = width
    m.top.findNode("languageChevron").translation = [56 + labelWidth + 12, 18]
    clockWidth = measureText(m.clockDate)
    timeWidth = measureText(m.clockTime)
    if timeWidth > clockWidth then clockWidth = timeWidth
    m.languagePill.translation = [1824 - clockWidth - 36 - width, 79]
    focused = m.actionIndex = 3
    if focused then
        m.languagePillBg.color = "0xF4F8FFFF"
        m.languageLabel.color = "0x070B14FF"
        m.top.findNode("languageGlobe").blendColor = "0x070B14FF"
        m.top.findNode("languageChevron").blendColor = "0x070B14FF"
    else
        m.languagePillBg.color = "0x0E1524EB"
        m.languageLabel.color = "0xF4F8FFFF"
        m.top.findNode("languageGlobe").blendColor = "0x00D7FFFF"
        m.top.findNode("languageChevron").blendColor = "0xF4F8FFFF"
    end if
end sub

sub onLanguageRequested()
    openLanguagePicker()
end sub

' No que esta em foco agora, para devolver o foco ao fechar a janela.
function focusedNode(node as Object) as Object
    if node = invalid then return invalid
    if node.hasFocus() then return node
    for each child in node.getChildren(-1, 0)
        if child.isInFocusChain() then return focusedNode(child)
    end for
    return invalid
end function

sub openLanguagePicker()
    m.languageReturn = focusedNode(m.top)
    preference = i18nPreference()
    m.languageSelected = 0
    for i = 0 to 2
        if m.languageValues[i] = preference then m.languageSelected = i
        m.top.findNode("languageOptionCheck" + i.ToStr()).visible = m.languageValues[i] = preference
    end for
    m.top.removeChild(m.languageOverlay)
    m.top.appendChild(m.languageOverlay)
    m.languageOverlay.visible = true
    m.languageOverlay.setFocus(true)
    renderLanguagePicker()
end sub

sub renderLanguagePicker()
    for i = 0 to 2
        focused = i = m.languageSelected
        option = m.top.findNode("languageOption" + i.ToStr())
        label = m.top.findNode("languageOptionLabel" + i.ToStr())
        subLabel = m.top.findNode("languageOptionSub" + i.ToStr())
        check = m.top.findNode("languageOptionCheck" + i.ToStr())
        if focused then
            option.color = "0xF4F8FFFF"
            label.color = "0x070B14FF"
            subLabel.color = "0x4A5568FF"
            check.blendColor = "0x070B14FF"
        else
            option.color = "0x00000000"
            label.color = "0xF4F8FFFF"
            subLabel.color = "0x9AA6BDFF"
            check.blendColor = "0x00D7FFFF"
        end if
    end for
end sub

sub handleLanguageKey(key as String)
    if key = "back" then
        closeLanguagePicker()
    else if key = "up" and m.languageSelected > 0 then
        m.languageSelected = m.languageSelected - 1
        renderLanguagePicker()
    else if key = "down" and m.languageSelected < 2 then
        m.languageSelected = m.languageSelected + 1
        renderLanguagePicker()
    else if key = "OK" then
        chooseLanguage(m.languageValues[m.languageSelected])
    end if
end sub

sub closeLanguagePicker()
    m.languageOverlay.visible = false
    if m.languageReturn <> invalid then
        m.languageReturn.setFocus(true)
    else
        m.top.setFocus(true)
    end if
end sub

' Salva a escolha e troca o idioma na hora (os textos observados se refazem).
sub chooseLanguage(preference as String)
    section = CreateObject("roRegistrySection", "ELVANOQPlay")
    if preference = "auto" then
        section.Delete("language")
    else
        section.Write("language", preference)
    end if
    section.Flush()
    closeLanguagePicker()
    language = i18nResolve(preference)
    if m.global.language <> language then
        m.global.language = language
    else
        layoutLanguagePill()
    end if
end sub

sub onMainLanguage()
    updateActivationClock()
    layoutActivationActions()
    layoutLanguagePill()
end sub

