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
    m.channelOffset = 0
    m.selectedCategoryIndex = 0
    m.categoryOffset = 0
    m.focusColumn = "channels"
    m.localState = loadLocalState()
    m.epg = {}
    m.epgRequested = {}
    m.epgTimer = CreateObject("roSGNode", "Timer")
    m.epgTimer.duration = 0.7
    m.epgTimer.repeat = false
    m.epgTimer.observeField("fire", "onEpgTimer")
    m.preview.observeField("state", "onPreviewState")
    m.categoryLabels = []
    m.channelLabels = []
    m.channelLogos = []
    m.favHearts = []
    m.rows = 14
    for index = 1 to m.rows
        suffix = safeTrim(str(index))
        if len(suffix) < 2 then suffix = "0" + suffix
        m.categoryLabels.push(m.top.findNode("category" + suffix))
        m.channelLabels.push(m.top.findNode("channel" + suffix))
        m.channelLogos.push(m.top.findNode("channelLogo" + suffix))
        m.favHearts.push(m.top.findNode("favHeart" + suffix))
    end for
    for each label in m.categoryLabels
        label.font = appFont(22, "regular")
        label.color = "0x8894A8FF"
    end for
    for each label in m.channelLabels
        label.font = appFont(22, "medium")
        label.color = "0xF4F8FFFF"
    end for
    m.top.findNode("title").font = appFont(40, "bold")
    m.top.findNode("title").color = "0xF4F8FFFF"
    m.top.findNode("subtitle").font = appFont(20, "regular")
    m.top.findNode("subtitle").color = "0x8894A8FF"
    for each heading in ["categoriesTitle", "channelsTitle", "epgTitle"]
        m.top.findNode(heading).font = appFont(18, "bold")
        m.top.findNode(heading).color = "0x00D7FFFF"
    end for
    m.previewTitle.color = "0xF4F8FFFF"
    m.previewHint.color = "0x8894A8FF"
    m.epgNow.color = "0xF4F8FFFF"
    m.epgNext.color = "0x8894A8FF"
    m.previewTitle.font = appFont(26, "semibold")
    m.previewHint.font = appFont(20, "regular")
    m.epgNow.font = appFont(24, "medium")
    m.epgNext.font = appFont(20, "regular")
    m.emptyState.font = appFont(20, "regular")
    m.lazy = false
    m.isLoading = false
    m.loadError = ""
    m.categoryIds = []
    m.favoriteChannels = []
    m.loadingCategoryId = ""
    m.requestTimer = CreateObject("roSGNode", "Timer")
    m.requestTimer.duration = 0.35
    m.requestTimer.repeat = false
    m.requestTimer.observeField("fire", "requestCurrentCategory")
end sub

sub setEpg(entries as Object)
    if entries = invalid or type(entries) <> "roAssociativeArray" then return
    m.epg = entries
    updateSelection()
end sub

sub setCatalog(payload as Object)
    if payload = invalid or type(payload) <> "roAssociativeArray" then return
    m.localState = loadLocalState()
    if payload.lazy = true then
        setLazyCatalog(payload)
        return
    end if
    m.lazy = false
    m.allChannels = []
    for each item in payload.items
        if item.type = invalid or item.type = "live" then m.allChannels.push(item)
    end for
    m.categories = ["Todas", "Favoritos"]
    if payload.categories <> invalid then
        for each category in payload.categories
            if category <> invalid and category <> "" then m.categories.push(category)
        end for
    end if
    m.selectedCategoryIndex = 0
    m.categoryOffset = 0
    m.selectedIndex = 0
    m.channelOffset = 0
    applyCategory()
end sub

' Lista Xtream: categorias completas; os canais de cada uma chegam por setCategoryItems.
sub setLazyCatalog(payload as Object)
    m.favoriteChannels = []
    if payload.favorites <> invalid then m.favoriteChannels = payload.favorites
    categories = payload.liveCategories
    if categories = invalid then categories = []
    signature = categories.count().ToStr()
    if categories.count() > 0 then signature = signature + ":" + categories[0].id + ":" + categories[categories.count() - 1].id
    if m.lazy and m.lazySignature = signature then
        ' Secao reaberta: mantem a posicao; so atualiza Favoritos se estiver nela.
        if m.selectedCategoryIndex = 0 then applyCategory() else renderGuide()
        return
    end if
    m.lazy = true
    m.lazySignature = signature
    m.categories = ["Favoritos"]
    m.categoryIds = [""]
    for each category in categories
        m.categories.push(category.name)
        m.categoryIds.push(category.id)
    end for
    m.selectedCategoryIndex = 0
    if m.favoriteChannels.count() = 0 and m.categories.count() > 1 then m.selectedCategoryIndex = 1
    m.categoryOffset = 0
    m.selectedIndex = 0
    m.channelOffset = 0
    m.loadingCategoryId = ""
    applyCategory()
    requestCurrentCategory()
end sub

sub requestCurrentCategory()
    if not m.lazy or m.selectedCategoryIndex = 0 then return
    categoryId = m.categoryIds[m.selectedCategoryIndex]
    if m.loadingCategoryId = categoryId then return
    m.loadingCategoryId = categoryId
    m.top.categoryRequested = { id: categoryId, name: m.categories[m.selectedCategoryIndex] }
end sub

sub setCategoryItems(payload as Object)
    if not m.lazy or payload = invalid or payload.id = invalid then return
    if m.selectedCategoryIndex = 0 or payload.id <> m.categoryIds[m.selectedCategoryIndex] then return
    m.visibleChannels = []
    if payload.items <> invalid then m.visibleChannels = payload.items
    m.loadError = ""
    if payload.error <> invalid then m.loadError = payload.error
    m.selectedIndex = 0
    m.channelOffset = 0
    m.isLoading = false
    renderGuide()
end sub

sub applyCategory()
    if m.lazy then
        m.visibleChannels = []
        m.selectedIndex = 0
        m.channelOffset = 0
        m.loadError = ""
        if m.selectedCategoryIndex = 0 then
            m.isLoading = false
            for each channel in m.favoriteChannels
                if isFavorite(channel.id) then m.visibleChannels.push(channel)
            end for
        else
            m.isLoading = true
            m.loadingCategoryId = ""
            m.requestTimer.control = "stop"
            m.requestTimer.control = "start"
        end if
        renderGuide()
        return
    end if
    m.visibleChannels = []
    selectedCategory = m.categories[m.selectedCategoryIndex]
    for each channel in m.allChannels
        if selectedCategory = "Todas" or channel.category = selectedCategory then
            m.visibleChannels.push(channel)
        else if selectedCategory = "Favoritos" and isFavorite(channel.id) then
            m.visibleChannels.push(channel)
        end if
    end for
    m.selectedIndex = 0
    m.channelOffset = 0
    renderGuide()
end sub

sub renderGuide()
    for index = 0 to m.categoryLabels.count() - 1
        categoryIndex = m.categoryOffset + index
        if categoryIndex < m.categories.count() then
            m.categoryLabels[index].text = m.categories[categoryIndex]
            if categoryIndex = m.selectedCategoryIndex then
                m.categoryLabels[index].color = "0xF4F8FFFF"
            else
                m.categoryLabels[index].color = "0x8894A8FF"
            end if
        else
            m.categoryLabels[index].text = ""
        end if
    end for
    if m.visibleChannels.count() = 0 then
        m.emptyState.visible = true
        if m.lazy and m.isLoading = true then
            m.emptyState.text = "Carregando canais…"
        else if m.lazy and m.loadError <> invalid and m.loadError <> "" then
            m.emptyState.text = m.loadError
        else if m.categories[m.selectedCategoryIndex] = "Favoritos" then
            m.emptyState.text = "Nenhum favorito ainda. Aperte * em um canal para favoritar."
        else
            m.emptyState.text = "Nenhum canal nesta categoria."
        end if
        for each label in m.channelLabels
            label.text = ""
        end for
        for each logo in m.channelLogos
            logo.uri = ""
            logo.visible = false
        end for
        for each heart in m.favHearts
            heart.visible = false
        end for
        updateFocus()
        m.previewTitle.text = ""
        m.epgNow.text = ""
        m.epgNext.text = ""
        return
    end if
    m.emptyState.visible = false
    for index = 0 to m.channelLabels.count() - 1
        itemIndex = m.channelOffset + index
        if itemIndex < m.visibleChannels.count() then
            channel = m.visibleChannels[itemIndex]
            ' Favorito: coracao na frente do nome (imagem; a fonte nao tem o simbolo).
            m.channelLabels[index].text = channel.title
            m.channelLabels[index].color = "0xF4F8FFFF"
            m.favHearts[index].visible = isFavorite(channel.id)
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
            m.favHearts[index].visible = false
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
    if m.selectedIndex < m.channelOffset then
        m.channelOffset = m.selectedIndex
        renderGuide()
    else if m.selectedIndex >= m.channelOffset + m.rows then
        m.channelOffset = m.selectedIndex - (m.rows - 1)
        renderGuide()
    else
        updateSelection()
    end if
end sub

sub moveCategory(delta as Integer)
    nextIndex = m.selectedCategoryIndex + delta
    if nextIndex < 0 then nextIndex = 0
    if nextIndex > m.categories.count() - 1 then nextIndex = m.categories.count() - 1
    if nextIndex = m.selectedCategoryIndex then return
    m.selectedCategoryIndex = nextIndex
    if m.selectedCategoryIndex < m.categoryOffset then
        m.categoryOffset = m.selectedCategoryIndex
    else if m.selectedCategoryIndex >= m.categoryOffset + m.rows then
        m.categoryOffset = m.selectedCategoryIndex - (m.rows - 1)
    end if
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
    visibleCategoryIndex = m.selectedCategoryIndex - m.categoryOffset
    if visibleCategoryIndex < 0 then visibleCategoryIndex = 0
    if visibleCategoryIndex > m.rows - 1 then visibleCategoryIndex = m.rows - 1
    m.categoryFocus.translation = [76, 236 + (visibleCategoryIndex * 52)]
    if m.visibleChannels.count() > 0 then
        visibleIndex = m.selectedIndex - m.channelOffset
        if visibleIndex < 0 then visibleIndex = 0
        if visibleIndex > m.rows - 1 then visibleIndex = m.rows - 1
        m.channelFocus.translation = [546, 236 + (visibleIndex * 52)]
    end if
end sub

sub updateSelection()
    if m.visibleChannels.count() = 0 then return
    updateFocus()
    selected = m.visibleChannels[m.selectedIndex]
    m.previewTitle.text = selected.title
    favoriteHint = ""
    if isFavorite(selected.id) then favoriteHint = "  •  Favorito"
    m.previewHint.text = "→ prévia  •  OK tela cheia  •  * favorito" + favoriteHint
    epgId = epgKeyFor(selected)
    if epgId <> "" and m.epg[epgId] <> invalid and m.epg[epgId].count() > 0 then
        m.epgNow.text = "Agora: " + programmeLabel(m.epg[epgId][0])
        updateEpgProgress(m.epg[epgId][0])
        if m.epg[epgId].count() > 1 then
            m.epgNext.text = "A seguir: " + programmeLabel(m.epg[epgId][1])
        else
            m.epgNext.text = "A seguir: —"
        end if
    else if epgId <> "" and m.epg[epgId] <> invalid then
        m.epgNow.text = "Sem programação informada para este canal."
        m.top.findNode("epgProgress").width = 0
        m.epgNext.text = "A seguir: —"
    else
        m.epgNow.text = "Carregando guia…"
        m.top.findNode("epgProgress").width = 0
        m.epgNext.text = "A seguir: —"
        m.epgTimer.control = "stop"
        m.epgTimer.control = "start"
    end if
end sub

sub onEpgTimer()
    if m.visibleChannels = invalid or m.visibleChannels.count() = 0 then return
    selected = m.visibleChannels[m.selectedIndex]
    key = epgKeyFor(selected)
    if key = "" or m.epgRequested[key] = true then return
    if selected.stream_id = invalid or safeTrim(selected.stream_id) = "" then
        m.epgNow.text = "Guia indisponível para este canal."
        return
    end if
    m.epgRequested[key] = true
    task = CreateObject("roSGNode", "EpgService")
    task.streamUrl = selected.stream_url
    task.streamId = safeTrim(selected.stream_id)
    task.epgKey = key
    task.observeField("result", "onShortEpgResult")
    m.epgTasks = task
    task.control = "RUN"
end sub

sub onShortEpgResult(event as Object)
    task = event.getRoSGNode()
    result = task.result
    key = task.epgKey
    programmes = []
    if result <> invalid and result.ok = true and result.entries <> invalid and result.entries[key] <> invalid then programmes = result.entries[key]
    m.epg[key] = programmes
    update = {}
    update[key] = programmes
    m.top.epgUpdate = update
    if m.visibleChannels <> invalid and m.visibleChannels.count() > 0 then
        if epgKeyFor(m.visibleChannels[m.selectedIndex]) = key then updateSelection()
    end if
end sub

sub onPreviewState()
    state = m.preview.state
    if state = "error" then
        m.previewHint.text = "Prévia falhou: " + m.preview.errorMsg + " (" + safeTrim(str(m.preview.errorCode)) + ")"
    else if state = "buffering" then
        m.previewHint.text = "Carregando prévia…"
    end if
end sub

function programmeLabel(programme as Dynamic) as String
    if type(programme) = "roAssociativeArray" then
        label = programme.title
        if programme.start <> invalid and len(programme.start) >= 12 then
            label = mid(programme.start, 9, 2) + ":" + mid(programme.start, 11, 2) + "  •  " + label
        end if
        return label
    end if
    return programme
end function

sub playSelected()
    if m.visibleChannels.count() = 0 then return
    selected = m.visibleChannels[m.selectedIndex]
    if isParentallyBlockedItem(selected.category, selected.id) then
        m.previewHint.text = "Conteúdo protegido. Valide o PIN em Ajustes para continuar."
        return
    end if
    content = CreateObject("roSGNode", "ContentNode")
    content.url = selected.stream_url
    content.title = selected.title
    previewFormat = streamFormatForUrl(selected.stream_url)
    if previewFormat <> "" then content.streamFormat = previewFormat
    content.live = true
    m.preview.content = content
    m.preview.control = "play"
    m.previewHint.text = "Prévia em execução  •  OK para assistir em tela cheia"
end sub

sub openSelected()
    if m.visibleChannels.count() = 0 then return
    selected = m.visibleChannels[m.selectedIndex]
    if isParentallyBlockedItem(selected.category, selected.id) then
        m.previewHint.text = "Conteúdo protegido. Valide o PIN em Ajustes para continuar."
        return
    end if
    stopPreview()
    m.top.playRequested = { item: selected, channels: m.visibleChannels, index: m.selectedIndex }
end sub

sub toggleFavorite()
    if m.visibleChannels.count() = 0 then return
    m.localState = loadLocalState()
    selected = m.visibleChannels[m.selectedIndex]
    if isFavorite(selected.id) then
        m.localState.favorites = removeLocalItem(m.localState.favorites, selected.id)
        if m.lazy then
            kept = []
            for each channel in m.favoriteChannels
                if channel.id <> selected.id then kept.push(channel)
            end for
            m.favoriteChannels = kept
        end if
    else
        if m.lazy then m.favoriteChannels.push(selected)
        favorite = {}
        favorite.Append(selected)
        favorite.kind = "live"
        m.localState.favorites = upsertLocalItem(m.localState.favorites, favorite)
    end if
    saveLocalState(m.localState)
    ' Na categoria Favoritos, remover um canal atualiza a lista.
    if m.categories[m.selectedCategoryIndex] = "Favoritos" then
        keepIndex = m.selectedIndex
        applyCategory()
        if m.visibleChannels.count() > 0 then
            if keepIndex > m.visibleChannels.count() - 1 then keepIndex = m.visibleChannels.count() - 1
            m.selectedIndex = keepIndex
            if m.selectedIndex >= m.channelOffset + m.rows then m.channelOffset = m.selectedIndex - (m.rows - 1)
            renderGuide()
        end if
        return
    end if
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

function focusColumnName() as String
    if m.focusColumn = invalid then return "categories"
    return m.focusColumn
end function

function isAtTop() as Boolean
    if m.focusColumn = "categories" then return m.selectedCategoryIndex = invalid or m.selectedCategoryIndex <= 0
    return m.selectedIndex = invalid or m.selectedIndex <= 0
end function

' Barra de progresso do programa atual (largura total 640).
sub updateEpgProgress(programme as Dynamic)
    bar = m.top.findNode("epgProgress")
    bar.width = 0
    if type(programme) <> "roAssociativeArray" then return
    if programme.startSec = invalid or programme.stopSec = invalid then return
    total = programme.stopSec - programme.startSec
    if total <= 0 then return
    elapsed = CreateObject("roDateTime").AsSeconds() - programme.startSec
    if elapsed < 0 then elapsed = 0
    if elapsed > total then elapsed = total
    bar.width = int(556 * elapsed / total)
end sub
