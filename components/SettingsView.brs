' Ajustes: menu principal e paginas (Controle parental e Categorias visiveis).

sub init()
    m.rowKeys = ["parental", "visible", "format", "about", "account"]
    m.selected = 0
    m.page = ""
    m.parentalPage = m.top.findNode("parentalPage")
    m.visiblePage = m.top.findNode("visiblePage")
    m.visiblePage.observeField("changed", "onVisibleCategoriesChanged")
    m.hub = m.top.findNode("hub")
    title = m.top.findNode("pageTitle")
    title.font = appFont(40, "bold")
    title.color = "0xF4F8FFFF"
    subtitle = m.top.findNode("pageSubtitle")
    subtitle.font = appFont(20, "regular")
    subtitle.color = "0x8894A8FF"
    for index = 0 to 2
        label = m.top.findNode("groupLabel" + index.ToStr())
        label.font = appFont(18, "bold")
        label.color = "0x8894A8FF"
    end for
    m.rowBgs = []
    m.rowTitles = []
    m.rowBadges = []
    m.rowBadgeLabels = []
    for index = 0 to m.rowKeys.count() - 1
        suffix = index.ToStr()
        m.rowBgs.push(m.top.findNode("rowBg" + suffix))
        rowTitle = m.top.findNode("rowTitle" + suffix)
        rowTitle.font = appFont(26, "semibold")
        m.rowTitles.push(rowTitle)
        m.rowBadges.push(m.top.findNode("rowBadge" + suffix))
        badgeLabel = m.top.findNode("rowBadgeLabel" + suffix)
        badgeLabel.font = appFont(18, "bold")
        m.rowBadgeLabels.push(badgeLabel)
    end for
    m.detailEyebrow = m.top.findNode("detailEyebrow")
    m.detailEyebrow.font = appFont(18, "bold")
    m.detailEyebrow.color = "0x00D7FFFF"
    m.detailTitle = m.top.findNode("detailTitle")
    m.detailTitle.font = appFont(36, "bold")
    m.detailTitle.color = "0xF4F8FFFF"
    m.detailBody = m.top.findNode("detailBody")
    m.detailBody.font = appFont(24, "regular")
    m.detailBody.color = "0xC9D3E3FF"
    m.detailHint = m.top.findNode("detailHint")
    m.detailHint.font = appFont(20, "regular")
    m.detailHint.color = "0x8894A8FF"
    m.aboutGroup = m.top.findNode("aboutGroup")
    historyLabel = m.top.findNode("historyLabel")
    historyLabel.font = appFont(18, "bold")
    historyLabel.color = "0x8894A8FF"
    history = appHistory()
    for index = 0 to 2
        versionLabel = m.top.findNode("historyVersion" + index.ToStr())
        textLabel = m.top.findNode("historyText" + index.ToStr())
        versionLabel.font = appFont(24, "bold")
        versionLabel.color = "0xF4F8FFFF"
        textLabel.font = appFont(21, "regular")
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
        subtitle.text = "Preferências desta TV   •   Tecla Replay: desconectar a lista desta TV"
    else
        subtitle.text = "Preferências desta TV"
    end if
    titles = ["Controle parental", "Categorias visíveis", "Formato do ao vivo", "Sobre", "Conta"]
    protectedTotal = protectedCategoryTotal(m.top.categories)
    hiddenTotal = hiddenCategoryTotal()
    badges = [protectedTotal.ToStr() + " protegidas", hiddenTotal.ToStr() + " ocultas", liveFormatLabel(liveFormatPreference()), "v" + appVersionText(), "Excluir login"]
    for index = 0 to m.rowKeys.count() - 1
        focused = index = m.selected
        m.rowTitles[index].text = titles[index]
        m.rowBadgeLabels[index].text = badges[index]
        if focused then
            m.rowBgs[index].color = "0x147DFFFF"
            m.rowTitles[index].color = "0xFFFFFFFF"
            m.rowBadges[index].color = "0xFFFFFF2E"
            m.rowBadgeLabels[index].color = "0xFFFFFFFF"
        else
            m.rowBgs[index].color = "0x111B2DFF"
            m.rowTitles[index].color = "0xC9D3E3FF"
            m.rowBadges[index].color = "0x00D7FF26"
            m.rowBadgeLabels[index].color = "0x7FE9FFFF"
        end if
    end for
    renderDetail(m.rowKeys[m.selected], protectedTotal, hiddenTotal)
end sub

sub renderDetail(key as String, protectedTotal as Integer, hiddenTotal as Integer)
    m.aboutGroup.visible = key = "about"
    if key = "parental" then
        m.detailEyebrow.text = "PROTEÇÃO E LISTA"
        m.detailTitle.text = "Controle parental"
        m.detailBody.text = "PIN de quatro dígitos para categorias, canais e títulos. Categorias adultas são protegidas automaticamente. " + protectedTotal.ToStr() + " categorias protegidas nesta lista."
        m.detailHint.text = "OK abrir   •   Voltar sair de Ajustes"
    else if key = "visible" then
        m.detailEyebrow.text = "PROTEÇÃO E LISTA"
        m.detailTitle.text = "Categorias visíveis"
        m.detailBody.text = "Escolha quais categorias de Ao vivo, Filmes e Séries aparecem nesta TV. Ocultar não apaga nada da lista. " + hiddenTotal.ToStr() + " categorias ocultas."
        m.detailHint.text = "OK abrir   •   Voltar sair de Ajustes"
    else if key = "format" then
        m.detailEyebrow.text = "REPRODUÇÃO"
        m.detailTitle.text = "Formato do ao vivo"
        m.detailBody.text = "Automático começa pelo formato que funcionou nesta lista. HLS (.m3u8) ou TS (.ts) fixam o formato dos canais. Atual: " + liveFormatLabel(liveFormatPreference()) + "."
        m.detailHint.text = "OK alternar Automático, HLS e TS"
    else if key = "account" then
        m.detailEyebrow.text = "CONTA"
        m.detailTitle.text = "Conta"
        m.detailBody.text = "Exclua os dados de acesso desta TV e volte para a tela de login."
        m.detailHint.text = "OK excluir login"
    else
        m.detailEyebrow.text = "APLICATIVO"
        m.detailTitle.text = "ELVANOQ Play para Roku"
        m.detailBody.text = "Versão " + appVersionText() + " (build " + appBuildText() + ")"
        m.detailHint.text = "Voltar sair de Ajustes"
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
    if key = "account" then
        m.top.accountRequested = true
        return
    end if
    if key = "parental" then
        openPage("parental")
    else if key = "visible" then
        openPage("visible")
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

