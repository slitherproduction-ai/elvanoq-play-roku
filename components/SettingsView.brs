' Ajustes: menu principal e paginas (Controle parental e Categorias visiveis).

sub init()
    i18nAttach(m.top)
    m.rowKeys = ["parental", "visible", "format", "join", "language", "account", "about"]
    m.rowTitleText = ["Controle parental", "Categorias visíveis", "Formato do ao vivo", "Juntar qualidades", "Idioma", "Conta", "Sobre"]
    m.rowSubText = ["PIN, conteúdo adulto e bloqueios", "Mostrar ou ocultar categorias desta lista", "OK alterna entre Automático, HLS e TS", "OK liga ou desliga", "Português, English ou Automático", "Excluir o login desta TV", "Versão e novidades"]
    m.rowIconUri = ["pkg:/images/icon_lock.png", "pkg:/images/icon_grid.png", "pkg:/images/icon_broadcast.png", "pkg:/images/icon_grid.png", "pkg:/images/icon_language.png", "pkg:/images/icon_key.png", "pkg:/images/icon_sparkles.png"]
    ' Idioma trocado: refaz valores e detalhes desta tela.
    m.global.observeField("language", "onSettingsLanguage")
    m.selected = 0
    m.page = ""
    m.parentalPage = m.top.findNode("parentalPage")
    m.visiblePage = m.top.findNode("visiblePage")
    m.visiblePage.observeField("changed", "onVisibleCategoriesChanged")
    m.hub = m.top.findNode("hub")
    title = m.top.findNode("pageTitle")
    title.font = appFont(44, "bold")
    title.color = "0xF4F8FFFF"
    subtitle = m.top.findNode("pageSubtitle")
    subtitle.font = appFont(21, "regular")
    subtitle.color = "0x8894A8FF"
    m.deviceInfo = m.top.findNode("deviceInfo")
    m.deviceInfo.font = appFont(20, "regular")
    m.deviceInfo.color = "0xB6C2D6FF"
    m.deviceInfo.text = "Roku   •   Versão " + appVersionText()
    for index = 0 to 1
        label = m.top.findNode("groupLabel" + index.ToStr())
        label.font = appFont(16, "bold")
        label.color = "0x63728AFF"
    end for
    footer = m.top.findNode("footerHint")
    footer.font = appFont(18, "regular")
    footer.color = "0x63728AFF"
    m.rowBgs = []
    m.rowTitles = []
    m.rowSubs = []
    m.rowMetas = []
    for index = 0 to m.rowKeys.count() - 1
        suffix = index.ToStr()
        m.rowBgs.push(m.top.findNode("rowBg" + suffix))
        m.top.findNode("rowIcon" + suffix).uri = m.rowIconUri[index]
        rowTitle = m.top.findNode("rowTitle" + suffix)
        rowTitle.font = appFont(25, "semibold")
        rowTitle.color = "0xF4F8FFFF"
        rowTitle.text = m.rowTitleText[index]
        m.rowTitles.push(rowTitle)
        rowSub = m.top.findNode("rowSub" + suffix)
        rowSub.font = appFont(18, "regular")
        rowSub.color = "0x9AA6BDFF"
        rowSub.text = m.rowSubText[index]
        m.rowSubs.push(rowSub)
        rowMeta = m.top.findNode("rowMeta" + suffix)
        rowMeta.font = appFont(20, "regular")
        rowMeta.color = "0xB8C4D6FF"
        m.rowMetas.push(rowMeta)
    end for
    m.detailIcon = m.top.findNode("detailIcon")
    m.detailTitle = m.top.findNode("detailTitle")
    m.detailTitle.font = appFont(32, "bold")
    m.detailTitle.color = "0xF4F8FFFF"
    m.detailBody = m.top.findNode("detailBody")
    m.detailBody.font = appFont(22, "regular")
    m.detailBody.color = "0xB8C4D6FF"
    m.detailValue = m.top.findNode("detailValue")
    m.detailValue.font = appFont(22, "semibold")
    m.detailValue.color = "0x00D7FFFF"
    m.detailHint = m.top.findNode("detailHint")
    m.detailHint.font = appFont(20, "regular")
    m.detailHint.color = "0x8894A8FF"
    m.aboutGroup = m.top.findNode("aboutGroup")
    historyLabel = m.top.findNode("historyLabel")
    historyLabel.font = appFont(16, "bold")
    historyLabel.color = "0x63728AFF"
    history = appHistory()
    for index = 0 to 2
        versionLabel = m.top.findNode("historyVersion" + index.ToStr())
        textLabel = m.top.findNode("historyText" + index.ToStr())
        versionLabel.font = appFont(22, "bold")
        versionLabel.color = "0xF4F8FFFF"
        textLabel.font = appFont(19, "regular")
        textLabel.color = "0xB8C4D6FF"
        if index < history.count() then
            versionLabel.text = history[index][0]
            textLabel.text = history[index][1]
        end if
    end for
    m.top.observeField("visible", "onVisibleChanged")
    renderHub()
end sub

' Historico exibido em Sobre (o mesmo do CHANGELOG.md).
function appHistory() as Object
    return [
        ["1.1.10", "Novidades para você sem filmes repetidos: versões dublada e legendada aparecem uma vez só."],
        ["1.1.9", "Novidades para você igual ao Android: os filmes adicionados mais recentemente na lista inteira."],
        ["1.1.8", "Novo visual na TV: menu com ícones na Início, destaque que acompanha o título em foco, faixa do título acima da grade e player com relógio e capa na abertura."],
        ["1.1.7", "Canais que não abrem mostram o erro em vez de carregar sem fim, troca de formato mais rápida e Novidades para você com os lançamentos da lista."],
        ["1.1.6", "Avance e volte filmes com as setas na barra de tempo, mais rápido ao apertar seguido, e capas no tamanho certo para cada Roku."],
        ["1.1.5", "Tela inicial com duas fileiras: Novidades para você e Continuar assistindo."],
        ["1.1.4", "Favoritos e Continuar assistindo não se misturam mais entre versões HD/FHD do mesmo canal, aviso quando a categoria tem mais títulos que o carregado e busca mais confiável com acentos."],
        ["1.1.3", "Nova tela de ativação, busca de canais e categorias na TV ao Vivo, novo Voltar no player e app mais leve em aparelhos simples."],
        ["1.1.0", "Retomada automática quando o vídeo trava, formato do ao vivo lembrado por lista, rever programas, proteção automática de conteúdo adulto, categorias visíveis e novo visual de Ajustes."],
        ["1.0.1", "Ajustes para a Roku Store: deep links, memória baixa, ativação com teclado e caixas de diálogo padrão da Roku."]
    ]
end function

' Nome da versao (1.1.0) e numero de build lidos do manifest.
function appVersionText() as String
    info = CreateObject("roAppInfo")
    name = info.GetValue("version_name")
    if name <> "" then return name
    return info.GetValue("major_version") + "." + info.GetValue("minor_version") + ".0"
end function

function appBuildText() as String
    return CreateObject("roAppInfo").GetValue("build_version")
end function

sub onVisibleChanged()
    if m.top.visible then
        renderHub()
    else
        closePage()
    end if
end sub

sub onCategoriesChanged()
    m.parentalPage.categories = m.top.categories
    renderHub()
end sub

sub onItemsChanged()
    m.parentalPage.items = m.top.items
end sub

sub onCategoryGroupsChanged()
    m.visiblePage.categoryGroups = m.top.categoryGroups
    renderHub()
end sub

sub onVisibleCategoriesChanged()
    m.top.hiddenChanged = true
end sub

sub renderHub()
    if m.rowBgs = invalid then return
    subtitle = m.top.findNode("pageSubtitle")
    if m.top.storeEdition then
        subtitle.text = "Conteúdo e sistema desta TV   •   Replay: desconectar a lista"
    else
        subtitle.text = "Conteúdo e sistema desta TV"
    end if
    protectedTotal = protectedCategoryTotal(m.top.categories)
    hiddenTotal = hiddenCategoryTotal()
    visibleText = "Todas visíveis"
    if hiddenTotal > 0 then visibleText = hiddenTotal.ToStr() + " ocultas"
    languagePref = i18nPreference()
    languageText = "Automático"
    if languagePref = "en" then languageText = "English"
    if languagePref = "pt" then languageText = "Português (Brasil)"
    joinText = "Desligado"
    if joinQualitiesEnabled() then joinText = "Ligado"
    metas = [protectedTotal.ToStr() + " protegidas", visibleText, liveFormatLabel(liveFormatPreference()), joinText, languageText, "", "Versão " + appVersionText()]
    for index = 0 to m.rowKeys.count() - 1
        m.rowMetas[index].text = metas[index]
        ' Foco como na LG/MSX: contorno ciano; sem foco, contorno quase invisível.
        if index = m.selected then
            m.rowBgs[index].borderColor = "0x00D7FFFF"
        else
            m.rowBgs[index].borderColor = "0xBEDEFF1A"
        end if
    end for
    renderDetail(m.rowKeys[m.selected], protectedTotal, hiddenTotal)
end sub

sub renderDetail(key as String, protectedTotal as Integer, hiddenTotal as Integer)
    m.aboutGroup.visible = key = "about"
    m.detailIcon.uri = m.rowIconUri[m.selected]
    m.detailTitle.text = m.rowTitleText[m.selected]
    m.detailValue.text = ""
    if key = "parental" then
        m.detailBody.text = "Crie um PIN e escolha as categorias e títulos protegidos. Categorias adultas são protegidas automaticamente."
        m.detailValue.text = protectedTotal.ToStr() + " categorias protegidas"
        m.detailHint.text = "OK abrir"
    else if key = "visible" then
        m.detailBody.text = "Oculte categorias que você não usa em Ao vivo, Filmes e Séries. Ocultar não apaga nada da lista."
        m.detailValue.text = hiddenTotal.ToStr() + " categorias ocultas"
        m.detailHint.text = "OK abrir"
    else if key = "format" then
        m.detailBody.text = "No Automático, a TV começa pelo formato que funcionou nesta lista. HLS (.m3u8) ou TS (.ts) fixam o formato dos canais."
        m.detailValue.text = "Atual: " + liveFormatLabel(liveFormatPreference())
        m.detailHint.text = "OK alterna entre Automático, HLS e TS"
    else if key = "join" then
        m.detailBody.text = "FHD, HD e SD do mesmo canal numa linha só, com o botão Fonte no player. Desligue se algum canal for agrupado errado: cada canal da lista volta a ter a sua linha."
        if joinQualitiesEnabled() then
            m.detailValue.text = "Ligado"
        else
            m.detailValue.text = "Desligado"
        end if
        m.detailHint.text = "OK liga ou desliga"
    else if key = "language" then
        m.detailBody.text = "Muda os textos do app. O áudio e as legendas dos vídeos continuam os da sua lista."
        m.detailValue.text = metasLanguage()
        m.detailHint.text = "OK abrir"
    else if key = "account" then
        m.detailBody.text = "Apaga os dados de acesso desta TV e volta para a tela de login."
        m.detailHint.text = "OK excluir login"
    else
        m.detailBody.text = "ELVANOQ Play para Roku   •   Versão " + appVersionText() + " (build " + appBuildText() + ")"
        m.detailHint.text = ""
    end if
end sub

function hiddenCategoryTotal() as Integer
    hidden = loadHiddenCategories()
    return hidden.live.count() + hidden.movies.count() + hidden.series.count()
end function

function handleKey(event as Object) as Boolean
    if event = invalid or event.press <> true then return false
    key = event.key
    if m.page = "parental" then
        if key = "back" then
            m.parentalPage.callFunc("cancelPinEntry")
            closePage()
            return true
        end if
        return isTrue(m.parentalPage.callFunc("handleKey", event))
    end if
    if m.page = "visible" then
        if key = "back" then
            closePage()
            return true
        end if
        return isTrue(m.visiblePage.callFunc("handleKey", event))
    end if
    if key = "down" and m.selected < m.rowKeys.count() - 1 then
        m.selected = m.selected + 1
        renderHub()
        return true
    end if
    if key = "up" and m.selected > 0 then
        m.selected = m.selected - 1
        renderHub()
        return true
    end if
    if key = "OK" then
        activateRow(m.rowKeys[m.selected])
        return true
    end if
    return false
end function

sub activateRow(key as String)
    if key = "language" then
        m.top.getScene().languageRequested = true
        return
    end if
    if key = "account" then
        m.top.accountRequested = true
        return
    end if
    if key = "parental" then
        openPage("parental")
    else if key = "visible" then
        openPage("visible")
    else if key = "join" then
        saveJoinQualities(not joinQualitiesEnabled())
        m.top.hiddenChanged = true
        renderHub()
    else if key = "format" then
        current = liveFormatPreference()
        nextValue = "auto"
        if current = "auto" then nextValue = "hls"
        if current = "hls" then nextValue = "ts"
        saveLiveFormatPreference(nextValue)
        renderHub()
    end if
end sub

sub openPage(page as String)
    m.page = page
    m.hub.visible = false
    m.parentalPage.visible = page = "parental"
    m.visiblePage.visible = page = "visible"
end sub

sub closePage()
    if m.page = "" then return
    m.page = ""
    m.parentalPage.visible = false
    m.visiblePage.visible = false
    m.hub.visible = true
    renderHub()
end sub

sub enterDigit(digit as String)
    if m.page = "parental" then m.parentalPage.callFunc("enterDigit", digit)
end sub

sub cancelPinEntry()
    if m.page = "parental" then m.parentalPage.callFunc("cancelPinEntry")
end sub

function isTrue(value as Dynamic) as Boolean
    t = type(value)
    if t = "roBoolean" or t = "Boolean" then return value
    return false
end function


function metasLanguage() as String
    preference = i18nPreference()
    if preference = "en" then return "English"
    if preference = "pt" then return "Português (Brasil)"
    return "Automático"
end function

sub onSettingsLanguage()
    renderHub()
end sub
