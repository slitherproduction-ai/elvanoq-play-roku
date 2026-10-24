sub init()
    m.preview = m.top.findNode("preview")
    m.channelFocus = m.top.findNode("channelFocus")
    m.categoryFocus = m.top.findNode("categoryFocus")
    m.previewTitle = m.top.findNode("previewTitle")
    m.previewHint = m.top.findNode("previewHint")
    m.epgNow = m.top.findNode("epgNow")
    m.epgNext = m.top.findNode("epgNext")
    m.emptyState = m.top.findNode("emptyState")
    m.allChannels = []
    m.visibleChannels = []
    m.categories = ["Todas"]
    m.selectedIndex = 0
    m.selectedCategoryIndex = 0
    m.focusColumn = "channels"
    m.localState = loadLocalState()
    m.categoryLabels = []
    m.channelLabels = []
    m.channelLogos = []
    for index = 1 to 6
        m.categoryLabels.push(m.top.findNode("category0" + trim(str(index))))
    end for
    for index = 1 to 8
        m.channelLabels.push(m.top.findNode("channel0" + trim(str(index))))
        m.channelLogos.push(m.top.findNode("channelLogo0" + trim(str(index))))
    end for
    for each label in m.categoryLabels
        label.font = "font:SmallSystemFont"
        label.color = "0x9EB5CCFF"
    end for
    for each label in m.channelLabels
        label.font = "font:SmallSystemFont"
        label.color = "0xFFFFFFFF"
    end for
    m.top.findNode("title").font = "font:LargeBoldSystemFont"
    m.top.findNode("subtitle").font = "font:SmallSystemFont"
    m.top.findNode("subtitle").color = "0x8FA9C4FF"
    m.top.findNode("categoriesTitle").font = "font:SmallSystemFont"
    m.top.findNode("channelsTitle").font = "font:SmallSystemFont"
    m.previewTitle.font = "font:MediumSystemFont"
    m.previewHint.font = "font:SmallSystemFont"
    m.epgNow.font = "font:SmallSystemFont"
    m.epgNext.font = "font:SmallSystemFont"
    m.emptyState.font = "font:SmallSystemFont"
end sub

sub setCatalog(payload as Object)
    if payload = invalid or type(payload) <> "roAssociativeArray" then return
    m.allChannels = payload.items
    m.categories = ["Todas"]
    if payload.categories <> invalid then
        for each category in payload.categories
            if category <> invalid and category <> "" and m.categories.count() < 6 then m.categories.push(category)
        end for
    end if
    m.selectedCategoryIndex = 0
    m.selectedIndex = 0
    applyCategory()
end sub

sub applyCategory()
    m.visibleChannels = []
    selectedCategory = m.categories[m.selectedCategoryIndex]
    for each channel in m.allChannels
        if selectedCategory = "Todas" or channel.category = selectedCategory then m.visibleChannels.push(channel)
    end for
    m.selectedIndex = 0
    renderGuide()
end sub

sub renderGuide()
    for index = 0 to m.categoryLabels.count() - 1
        if index < m.categories.count() then
            m.categoryLabels[index].text = m.categories[index]
            if index = m.selectedCategoryIndex then
                m.categoryLabels[index].color = "0xFFFFFFFF"
            else
                m.categoryLabels[index].color = "0x9EB5CCFF"
            end if
        else
            m.categoryLabels[index].text = ""
        end if
    end for
    if m.visibleChannels.count() = 0 then
        m.emptyState.visible = true
        m.emptyState.text = "Nenhum canal nesta categoria."
        for each label in m.channelLabels
            label.text = ""
        end for
        for each logo in m.channelLogos
            logo.uri = ""
            logo.visible = false
        end for
        return
    end if
    m.emptyState.visible = false
    for index = 0 to m.channelLabels.count() - 1
        if index < m.visibleChannels.count() then
            channel = m.visibleChannels[index]
            prefix = ""
            if isFavorite(channel.id) then prefix = "★ "
            m.channelLabels[index].text = prefix + channel.title
            if channel.logo <> invalid and channel.logo <> "" then
                m.channelLogos[index].uri = channel.logo
                m.channelLogos[index].visible = true
            else
                m.channelLogos[index].uri = ""
                m.channelLogos[index].visible = false
            end if
        else
            m.channelLabels[index].text = ""
            m.channelLogos[index].uri = ""
            m.channelLogos[index].visible = false
        end if
    end for
    updateSelection()
end sub

sub moveChannel(delta as Integer)
    if m.focusColumn = "categories" then
        moveCategory(delta)
        return
    end if
    if m.visibleChannels.count() = 0 then return
    nextIndex = m.selectedIndex + delta
    if nextIndex < 0 then nextIndex = 0
    if nextIndex > m.visibleChannels.count() - 1 then nextIndex = m.visibleChannels.count() - 1
    m.selectedIndex = nextIndex
    updateSelection()
end sub

sub moveCategory(delta as Integer)
    nextIndex = m.selectedCategoryIndex + delta
    if nextIndex < 0 then nextIndex = 0
    if nextIndex > m.categories.count() - 1 then nextIndex = m.categories.count() - 1
    if nextIndex = m.selectedCategoryIndex then return
    m.selectedCategoryIndex = nextIndex
    stopPreview()
    applyCategory()
end sub

sub moveFocus(column as String)
    if column <> "categories" and column <> "channels" then return
    m.focusColumn = column
    updateFocus()
end sub

sub activateRight()
    if m.focusColumn = "categories" then
        moveFocus("channels")
    else
        playSelected()
    end if
end sub

sub confirmSelection()
    if m.focusColumn = "categories" then
        moveFocus("channels")
    else
        openSelected()
    end if
end sub

sub updateFocus()
    m.categoryFocus.visible = m.focusColumn = "categories"
    m.channelFocus.visible = m.focusColumn = "channels"
    m.categoryFocus.translation = [364, 256 + (m.selectedCategoryIndex * 40)]
    if m.visibleChannels.count() > 0 then
        visibleIndex = m.selectedIndex
        if visibleIndex > 7 then visibleIndex = 7
        m.channelFocus.translation = [615, 258 + (visibleIndex * 55)]
    end if
end sub

sub updateSelection()
    if m.visibleChannels.count() = 0 then return
    updateFocus()
    selected = m.visibleChannels[m.selectedIndex]
    m.previewTitle.text = selected.title
    favoriteHint = ""
    if isFavorite(selected.id) then favoriteHint = "  •  ★ Favorito"
    m.previewHint.text = "→ prévia  •  OK tela cheia  •  * favorito" + favoriteHint
    m.epgNow.text = "Programação disponível após sincronizar XMLTV."
    m.epgNext.text = "Próximo: —"
end sub

sub playSelected()
    if m.visibleChannels.count() = 0 then return
    selected = m.visibleChannels[m.selectedIndex]
    if isParentallyBlocked(selected.category) then
        m.previewHint.text = "Conteúdo protegido. Valide o PIN em Ajustes para continuar."
        return
    end if
    content = CreateObject("roSGNode", "ContentNode")
    content.url = selected.stream_url
    content.title = selected.title
    m.preview.content = content
    m.preview.control = "play"
    m.previewHint.text = "Prévia em execução  •  OK para assistir em tela cheia"
end sub

sub openSelected()
    if m.visibleChannels.count() = 0 then return
    selected = m.visibleChannels[m.selectedIndex]
    if isParentallyBlocked(selected.category) then
        m.previewHint.text = "Conteúdo protegido. Valide o PIN em Ajustes para continuar."
        return
    end if
    stopPreview()
    m.top.playRequested = { item: selected, channels: m.visibleChannels, index: m.selectedIndex }
end sub

sub toggleFavorite()
    if m.visibleChannels.count() = 0 then return
    selected = m.visibleChannels[m.selectedIndex]
    if isFavorite(selected.id) then
        m.localState.favorites = removeLocalItem(m.localState.favorites, selected.id)
    else
        favorite = { id: selected.id, title: selected.title, category: selected.category, kind: "live" }
        m.localState.favorites = upsertLocalItem(m.localState.favorites, favorite)
    end if
    saveLocalState(m.localState)
    renderGuide()
end sub

function isFavorite(itemId as String) as Boolean
    for each item in m.localState.favorites
        if item.id = itemId then return true
    end for
    return false
end function

sub stopPreview()
    m.preview.control = "stop"
end sub
