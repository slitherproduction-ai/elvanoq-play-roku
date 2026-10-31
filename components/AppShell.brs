sub init()
    m.localState = loadLocalState()
    m.epg = {}
    m.sectionEyebrow = m.top.findNode("sectionEyebrow")
    m.sectionTitle = m.top.findNode("sectionTitle")
    m.sectionDescription = m.top.findNode("sectionDescription")
    m.sectionHint = m.top.findNode("sectionHint")
    m.homeView = m.top.findNode("homeView")
    m.liveTVView = m.top.findNode("liveTVView")
    m.moviesView = m.top.findNode("moviesView")
    m.seriesView = m.top.findNode("seriesView")
    m.searchView = m.top.findNode("searchView")
    m.libraryView = m.top.findNode("libraryView")
    m.parentalView = m.top.findNode("parentalView")
    m.detailView = m.top.findNode("detailView")
    m.playerView = m.top.findNode("playerView")
    m.moviesView.observeField("selectedItem", "onBrowseItemSelected")
    m.seriesView.observeField("selectedItem", "onBrowseItemSelected")
    m.liveTVView.observeField("playRequested", "onLivePlayRequested")
    m.liveTVView.observeField("epgUpdate", "onLiveEpgUpdate")
    m.homeView.observeField("playRequested", "onHomePlayRequested")
    m.homeView.observeField("selectedItem", "onHomeItemSelected")
    m.searchView.observeField("selectedItem", "onSearchItemSelected")
    m.libraryView.observeField("itemRequested", "onLibraryItemRequested")
    m.detailView.observeField("closeRequested", "onDetailClosed")
    m.detailView.observeField("playRequested", "onPlayRequested")
    m.detailView.observeField("trailerRequested", "onTrailerRequested")
    m.detailView.observeField("episodeRequested", "onEpisodeRequested")
    m.detailView.observeField("seasonRequested", "onSeasonRequested")
    m.playerView.observeField("closeRequested", "onPlayerClosed")
    m.playerView.observeField("channelRequested", "onPlayerChannelRequested")
    m.playerView.observeField("favoriteRequested", "onPlayerFavoriteRequested")
    m.playerView.observeField("nextEpisodeRequested", "onNextEpisodeRequested")
    m.homeView.observeField("sectionRequested", "onHomeSectionRequested")
    m.moviesView.observeField("categoryRequested", "onBrowseCategoryRequested")
    m.seriesView.observeField("categoryRequested", "onBrowseCategoryRequested")
    m.liveTVView.observeField("categoryRequested", "onLiveCategoryRequested")
    m.searchView.observeField("searchRequested", "onSearchRequested")
    m.moviesView.observeField("searchRequested", "onBrowseSearchRequested")
    m.seriesView.observeField("searchRequested", "onBrowseSearchRequested")
    m.lazy = false
    m.categoryCache = {}
    m.categoryCacheOrder = []
    m.pendingCategory = {}
    m.searchItems = []
    m.searchToken = left(CreateObject("roDeviceInfo").GetRandomUUID(), 8)
    m.top.observeField("deepLink", "onDeepLink")
    m.top.observeField("storeEdition", "onStoreEditionChanged")
    m.clockTime = m.top.findNode("clockTime")
    m.clockDate = m.top.findNode("clockDate")
    m.clockTime.font = appFont(36, "semibold")
    m.clockTime.color = "0xF4F8FFFF"
    m.clockDate.font = appFont(20, "regular")
    m.clockDate.color = "0xD6DEEBFF"
    clockTimer = m.top.findNode("clockTimer")
    clockTimer.observeField("fire", "updateClock")
    clockTimer.control = "start"
    updateClock()
    m.sectionEyebrow.font = appFont(24, "regular")
    m.sectionEyebrow.color = "0x00D7FFFF"
    m.sectionTitle.font = appFont(40, "bold")
    m.sectionDescription.font = appFont(24, "regular")
    m.sectionDescription.color = "0xD6DEEBFF"
    m.sectionHint.font = appFont(20, "regular")
    m.sectionHint.color = "0x8894A8FF"
    m.selectedIndex = 0
    showSection()
    showContentFocus()
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
    if not press then return false
    if m.playerView.visible then return m.playerView.callFunc("handleKey", { key: key, press: press })
    if m.detailView.visible then return m.detailView.callFunc("handleKey", { key: key, press: press })
    if handleContentKey(key, press) then return true
    if key = "back" then
        ' Dentro de uma secao, Voltar retorna ao Inicio no bloco de origem.
        ' No Inicio, deixa a tecla seguir e a Roku fecha o app.
        if m.selectedIndex = 0 then return false
        goHomeFromSection()
        return true
    end if
    return key = "OK" or key = "left" or key = "right" or key = "up" or key = "down"
end function

sub goHomeFromSection()
    origin = m.selectedIndex
    m.liveTVView.callFunc("stopPreview")
    m.selectedIndex = 0
    showSection()
    m.homeView.callFunc("focusTile", origin)
end sub

sub onHomeSectionRequested()
    section = m.homeView.sectionRequested
    if section < 1 or section > 6 then return
    m.selectedIndex = section
    showSection()
    showContentFocus()
    if section = 4 then openSearchKeyboard()
end sub

sub showContentFocus()
    m.homeView.callFunc("setFocusVisible", true)
    m.moviesView.callFunc("setFocusVisible", true)
    m.seriesView.callFunc("setFocusVisible", true)
    m.searchView.callFunc("setFocusVisible", true)
    m.top.setFocus(true)
end sub

sub updateClock()
    now = CreateObject("roDateTime")
    now.ToLocalTime()
    months = ["jan", "fev", "mar", "abr", "mai", "jun", "jul", "ago", "set", "out", "nov", "dez"]
    hours = safeTrim(str(now.GetHours()))
    minutes = safeTrim(str(now.GetMinutes()))
    if len(hours) < 2 then hours = "0" + hours
    if len(minutes) < 2 then minutes = "0" + minutes
    m.clockTime.text = hours + ":" + minutes
    m.clockDate.text = safeTrim(str(now.GetDayOfMonth())) + " " + months[now.GetMonth() - 1] + " " + safeTrim(str(now.GetYear()))
end sub

function handleContentKey(key as String, press as Boolean) as Boolean
    if m.selectedIndex = 0 then return isTrue(m.homeView.callFunc("handleKey", { key: key, press: press }))
    if m.selectedIndex = 5 then return isTrue(m.libraryView.callFunc("handleKey", { key: key, press: press }))
    if m.selectedIndex = 4 then
        if isTrue(m.searchView.callFunc("handleKey", { key: key, press: press })) then return true
        if key = "OK" or key = "options" then
            openSearchKeyboard()
            return true
        end if
        return false
    end if
    if m.selectedIndex = 2 then return isTrue(m.moviesView.callFunc("handleKey", { key: key, press: press }))
    if m.selectedIndex = 3 then return isTrue(m.seriesView.callFunc("handleKey", { key: key, press: press }))
    if m.selectedIndex = 6 then
        if key = "replay" and m.top.storeEdition then
            openDisconnectDialog()
            return true
        end if
        digit = pinDigitFromKey(key)
        if digit <> "" then
            m.parentalView.callFunc("enterDigit", digit)
            return true
        end if
        if key = "back" then
            m.parentalView.callFunc("cancelPinEntry")
            return false
        end if
        return isTrue(m.parentalView.callFunc("handleKey", { key: key, press: press }))
    end if
    if m.selectedIndex = 1 then
        if key = "down" then
            m.liveTVView.callFunc("moveChannel", 1)
            return true
        end if
        if key = "up" then
            if isTrue(m.liveTVView.callFunc("isAtTop")) then return false
            m.liveTVView.callFunc("moveChannel", -1)
            return true
        end if
        if key = "left" then
            m.liveTVView.callFunc("moveFocus", "categories")
            return true
        end if
        if key = "right" then
            m.liveTVView.callFunc("activateRight")
            return true
        end if
        if key = "OK" then
            m.liveTVView.callFunc("confirmSelection")
            return true
        end if
        if key = "options" then
            m.liveTVView.callFunc("toggleFavorite")
            return true
        end if
        if key = "back" then
            m.liveTVView.callFunc("stopPreview")
            return false
        end if
    end if
    return false
end function

sub returnToHome()
    m.selectedIndex = 0
    showSection()
end sub

sub onHomePlayRequested()
    item = m.homeView.playRequested
    if item = invalid then return
    if item.stream_url = invalid or item.stream_url = "" then
        openCatalogItem(item)
        return
    end if
    playCatalogItem(item, resumePositionFor(item))
end sub

sub onHomeItemSelected()
    item = m.homeView.selectedItem
    if item = invalid then return
    if item.type = "live" then
        playLiveItem(item, [item], 0)
    else
        openCatalogItem(item)
    end if
end sub

sub openSearchKeyboard()
    dialog = CreateObject("roSGNode", "StandardKeyboardDialog")
    dialog.title = "Buscar no ELVANOQ Play"
    dialog.message = "Filmes, séries e canais da sua lista"
    dialog.buttons = ["Buscar", "Cancelar"]
    dialog.observeField("buttonSelected", "onSearchKeyboardSelected")
    m.searchKeyboard = dialog
    m.top.getScene().dialog = dialog
end sub

sub onSearchItemSelected()
    item = m.searchView.selectedItem
    if item = invalid then return
    if item.type = "live" then
        playLiveItem(item, [item], 0)
        return
    end if
    openCatalogItem(item)
end sub

sub onLibraryItemRequested()
    requested = m.libraryView.itemRequested
    resolved = resolveCatalogItem(requested)
    if resolved = invalid then return
    if requested.progress_seconds <> invalid and requested.progress_seconds > 0 then
        playCatalogItem(resolved, requested.progress_seconds)
        return
    end if
    openCatalogItem(resolved)
end sub

sub playCatalogItem(item as Object, resumePosition as Integer)
    if item = invalid or item.stream_url = invalid or item.stream_url = "" then return
    clearEpisodeQueue()
    m.playerView.liveQueue = []
    m.playerView.liveIndex = 0
    m.playerView.contentTitle = item.title
    m.playerView.contentId = item.id
    m.playerView.contentItem = item
    m.playerView.contentCategory = item.category
    m.playerView.resumePosition = resumePosition
    m.playerView.persistEnabled = true
    m.playerView.nextEpisode = invalid
    m.playerView.skipIntroEnd = 0
    m.playerView.streamUrl = item.stream_url
    m.playerView.visible = true
end sub

sub openCatalogItem(item as Object)
    if item = invalid then return
    m.detailView.item = item
    m.detailView.metadata = invalid
    m.detailView.visible = true
    loadMetadata(item, "search", 0, 0)
    if item.series_id <> invalid and safeTrim(item.series_id) <> "" then loadSeriesInfo(item)
end sub

sub loadSeriesInfo(item as Object)
    service = CreateObject("roSGNode", "SeriesService")
    service.apiUrl = item.api_url
    service.seriesBase = item.series_base
    service.seriesId = safeTrim(item.series_id)
    service.observeField("result", "onSeriesInfoResult")
    m.seriesService = service
    service.control = "RUN"
end sub

sub onSeriesInfoResult(event as Object)
    result = event.getRoSGNode().result
    if result = invalid then return
    m.detailView.seriesInfo = result
end sub

function resolveCatalogItem(savedItem as Object) as Object
    if savedItem = invalid or savedItem.id = invalid then return invalid
    if m.catalog <> invalid then
        for each item in m.catalog
            if item.id = savedItem.id then return item
        end for
    end if
    for each item in m.searchItems
        if item.id = savedItem.id then return item
    end for
    ' Lista sob demanda: recria o item com o que ficou salvo no Roku.
    if m.lazy then
        state = loadLocalState()
        for each listName in ["favorites", "continue_watching", "watch_later", "history"]
            for each saved in state[listName]
                if saved.id = savedItem.id then
                    rebuilt = xtreamItemFromSaved(m.xtream, saved)
                    if rebuilt <> invalid then return rebuilt
                end if
            end for
        end for
        rebuilt = xtreamItemFromSaved(m.xtream, savedItem)
        if rebuilt <> invalid then return rebuilt
    end if
    return invalid
end function

' Itens salvos (favoritos, continuar, mais tarde) recriados para o Inicio e a TV ao Vivo.
function savedCatalogItems(kindFilter as String) as Object
    items = []
    if not m.lazy then return items
    known = {}
    if m.catalog <> invalid then
        for each item in m.catalog
            known[item.id] = true
        end for
    end if
    state = loadLocalState()
    for each listName in ["continue_watching", "favorites", "watch_later"]
        for each saved in state[listName]
            if saved.id <> invalid and not known.DoesExist(saved.id) then
                itemType = ""
                if saved.type <> invalid then itemType = saved.type
                if kindFilter = "" or itemType = kindFilter then
                    rebuilt = xtreamItemFromSaved(m.xtream, saved)
                    if rebuilt <> invalid then
                        items.push(rebuilt)
                        known[saved.id] = true
                    end if
                end if
            end if
        end for
    end for
    return items
end function

function homeItems() as Object
    items = []
    if m.catalog <> invalid then items.Append(m.catalog)
    items.Append(savedCatalogItems(""))
    return items
end function

' ---------- Categorias sob demanda (lista Xtream) ----------

sub onBrowseCategoryRequested(event as Object)
    view = event.getRoSGNode()
    request = view.categoryRequested
    if request = invalid or request.id = invalid then return
    requestCategory(view, request.kind, request.id, request.name)
end sub

sub onLiveCategoryRequested()
    request = m.liveTVView.categoryRequested
    if request = invalid or request.id = invalid then return
    requestCategory(m.liveTVView, "live", request.id, request.name)
end sub

sub requestCategory(view as Object, kind as String, categoryId as String, categoryName as String)
    key = kind + ":" + categoryId
    m.pendingCategory[kind] = key
    if m.categoryCache.DoesExist(key) then
        touchCategoryCache(key)
        view.callFunc("setCategoryItems", { kind: kind, id: categoryId, items: m.categoryCache[key] })
        return
    end if
    if m.xtream = invalid then return
    service = CreateObject("roSGNode", "CatalogService")
    service.mode = "category"
    service.kind = kind
    service.categoryId = categoryId
    service.categoryName = categoryName
    service.xtream = m.xtream
    service.observeField("result", "onCategoryResult")
    if m.categoryTasks = invalid then m.categoryTasks = {}
    m.categoryTasks[key] = service
    service.control = "RUN"
end sub

sub onCategoryResult(event as Object)
    service = event.getRoSGNode()
    result = service.result
    if result = invalid then return
    key = result.kind + ":" + result.categoryId
    if m.categoryTasks <> invalid then m.categoryTasks.Delete(key)
    items = []
    if result.ok = true and result.items <> invalid then items = result.items
    if result.ok = true then
        m.categoryCache[key] = items
        touchCategoryCache(key)
        trimCategoryCache()
        rebuildCatalogPool()
    end if
    pending = m.pendingCategory[result.kind]
    if pending = invalid or pending <> key then return
    view = invalid
    if result.kind = "movies" then view = m.moviesView
    if result.kind = "series" then view = m.seriesView
    if result.kind = "live" then view = m.liveTVView
    if view = invalid then return
    payload = { kind: result.kind, id: result.categoryId, items: items }
    if result.ok <> true then payload.error = "Não foi possível carregar esta categoria. Tente novamente."
    view.callFunc("setCategoryItems", payload)
end sub

sub touchCategoryCache(key as String)
    order = []
    for each entry in m.categoryCacheOrder
        if entry <> key then order.push(entry)
    end for
    order.push(key)
    m.categoryCacheOrder = order
end sub

' Guarda as ultimas categorias abertas, sem passar de ~12 mil itens na memoria.
sub trimCategoryCache()
    total = 0
    for each key in m.categoryCacheOrder
        total = total + m.categoryCache[key].count()
    end for
    while m.categoryCacheOrder.count() > 1 and (m.categoryCacheOrder.count() > 10 or total > 12000)
        oldest = m.categoryCacheOrder.Shift()
        total = total - m.categoryCache[oldest].count()
        m.categoryCache.Delete(oldest)
    end while
end sub

sub rebuildCatalogPool()
    pool = []
    if m.seedItems <> invalid then pool.Append(m.seedItems)
    for each key in m.categoryCacheOrder
        pool.Append(m.categoryCache[key])
    end for
    m.catalog = pool
end sub

sub onSearchRequested()
    request = m.searchView.searchRequested
    if request = invalid or request.query = invalid then return
    if not m.lazy or m.xtream = invalid then return
    service = CreateObject("roSGNode", "CatalogService")
    service.mode = "search"
    service.query = request.query
    service.searchToken = m.searchToken
    service.categoryNames = m.categoryNames
    service.xtream = m.xtream
    service.observeField("result", "onSearchResult")
    m.searchService = service
    service.control = "RUN"
end sub

sub onSearchResult(event as Object)
    service = event.getRoSGNode()
    if m.searchService = invalid or not service.isSameNode(m.searchService) then return
    result = service.result
    if result = invalid then return
    items = []
    if result.items <> invalid then items = result.items
    m.searchItems = items
    payload = { query: result.query, items: items }
    if result.ok <> true then payload.error = result.message
    m.searchView.callFunc("setResults", payload)
end sub

'---------- Busca dentro de Filmes / Series (titulo ou ator) ----------

sub onBrowseSearchRequested(event as Object)
    view = event.getRoSGNode()
    request = view.searchRequested
    if request = invalid then return
    m.browseSearchView = view
    m.browseSearchKind = request.kind
    dialog = CreateObject("roSGNode", "StandardKeyboardDialog")
    if request.kind = "series" then
        dialog.title = "Buscar séries"
    else
        dialog.title = "Buscar filmes"
    end if
    dialog.message = "Digite o nome do título ou de um ator"
    dialog.buttons = ["Buscar", "Cancelar"]
    dialog.observeField("buttonSelected", "onBrowseSearchKeyboardSelected")
    m.browseSearchKeyboard = dialog
    m.top.getScene().dialog = dialog
end sub

sub onBrowseSearchKeyboardSelected()
    query = ""
    if m.browseSearchKeyboard.buttonSelected = 0 then query = safeTrim(m.browseSearchKeyboard.text)
    m.top.getScene().dialog = invalid
    m.browseSearchKeyboard = invalid
    m.top.setFocus(true)
    if query = "" then return
    m.browseSearchQuery = query
    m.browseSearchView.callFunc("setSearchResults", { query: query, loading: true, items: [] })
    if not m.lazy then
        m.browseSearchView.callFunc("setSearchResults", { query: query, items: localTitleSearch(query, m.browseSearchKind) })
        return
    end if
    if m.top.storeEdition then
        m.browseSearchPerson = ""
        runBrowseCatalogSearch([])
        return
    end if
    ' Primeiro pergunta ao Portal se o texto e um ator (filmografia via TMDB); depois busca na lista.
    meta = CreateObject("roSGNode", "MetadataService")
    meta.rokuClientId = m.top.rokuClientId
    meta.deviceCode = m.top.deviceCode
    meta.deviceKey = m.top.deviceKey
    meta.title = query
    meta.mode = "person"
    if m.browseSearchKind = "series" then meta.mediaType = "tv" else meta.mediaType = "movie"
    meta.observeField("result", "onBrowsePersonResult")
    m.browsePersonService = meta
    meta.control = "RUN"
end sub

sub onBrowsePersonResult(event as Object)
    service = event.getRoSGNode()
    if m.browsePersonService = invalid or not service.isSameNode(m.browsePersonService) then return
    result = service.result
    titles = []
    person = ""
    if result <> invalid and result.ok = true and type(result.titles) = "roArray" then
        for each entry in result.titles
            if type(entry) = "roAssociativeArray" then
                if entry.title <> invalid and entry.title <> "" then titles.push(entry.title)
                if entry.original_title <> invalid and entry.original_title <> "" and entry.original_title <> entry.title then titles.push(entry.original_title)
            else if entry <> invalid then
                titles.push(entry)
            end if
        end for
        if result.person <> invalid and result.person.name <> invalid then person = result.person.name
    end if
    m.browseSearchPerson = person
    runBrowseCatalogSearch(titles)
end sub

sub runBrowseCatalogSearch(titles as Object)
    service = CreateObject("roSGNode", "CatalogService")
    service.mode = "search"
    service.query = m.browseSearchQuery
    service.kinds = [m.browseSearchKind]
    service.titles = titles
    service.searchToken = m.searchToken
    service.categoryNames = m.categoryNames
    service.xtream = m.xtream
    service.observeField("result", "onBrowseSearchResult")
    m.browseSearchService = service
    service.control = "RUN"
end sub

sub onBrowseSearchResult(event as Object)
    service = event.getRoSGNode()
    if m.browseSearchService = invalid or not service.isSameNode(m.browseSearchService) then return
    result = service.result
    if result = invalid or m.browseSearchView = invalid then return
    items = []
    if result.items <> invalid then items = result.items
    if m.searchItems.count() > 500 then m.searchItems = []
    for each item in items
        m.searchItems.push(item)
    end for
    payload = { query: result.query, items: items }
    if m.browseSearchPerson <> invalid and m.browseSearchPerson <> "" then payload.person = m.browseSearchPerson
    if result.ok <> true then payload.error = result.message
    m.browseSearchView.callFunc("setSearchResults", payload)
end sub

function localTitleSearch(query as String, kind as String) as Object
    found = []
    needle = lcase(query)
    if m.catalog = invalid then return found
    for each item in m.catalog
        if item.type = kind and item.title <> invalid and instr(1, lcase(item.title), needle) > 0 then
            found.push(item)
            if found.count() >= 300 then exit for
        end if
    end for
    return found
end function

function categoryNameMap(categories as Object) as Object
    names = {}
    names.SetModeCaseSensitive()
    if categories = invalid then return names
    for each category in categories
        names[category.id] = category.name
    end for
    return names
end function

sub pushSectionCatalog()
    if m.catalog = invalid then return
    if m.selectedIndex = 0 then m.homeView.callFunc("setCatalog", { items: homeItems(), categories: m.categories })
    if m.lazy then
        if m.selectedIndex = 1 then m.liveTVView.callFunc("setCatalog", { lazy: true, liveCategories: m.liveCategories, favorites: savedCatalogItems("live"), items: [] })
        if m.selectedIndex = 2 then m.moviesView.callFunc("setCatalog", { lazy: true, categories: m.movieCategories })
        if m.selectedIndex = 3 then m.seriesView.callFunc("setCatalog", { lazy: true, categories: m.seriesCategories })
        if m.selectedIndex = 4 then m.searchView.callFunc("setCatalog", { lazy: true, items: [] })
    else
        if m.selectedIndex = 1 then m.liveTVView.callFunc("setCatalog", { items: m.catalog, categories: m.categories })
        if m.selectedIndex = 2 then m.moviesView.callFunc("setCatalog", { items: m.catalog })
        if m.selectedIndex = 3 then m.seriesView.callFunc("setCatalog", { items: m.catalog })
        if m.selectedIndex = 4 then m.searchView.callFunc("setCatalog", { items: m.catalog })
    end if
end sub

sub onLivePlayRequested()
    request = m.liveTVView.playRequested
    if request = invalid or request.item = invalid then return
    item = request.item
    if item = invalid or item.stream_url = invalid or item.stream_url = "" then return
    playLiveItem(item, request.channels, request.index)
end sub

sub playLiveItem(item as Object, channels as Object, index as Integer)
    if item = invalid or item.stream_url = invalid or item.stream_url = "" then return
    clearEpisodeQueue()
    m.playerView.liveQueue = channels
    m.playerView.liveIndex = index
    m.playerView.liveGuide = liveGuideFor(item)
    m.playerView.contentTitle = item.title
    m.playerView.contentId = item.id
    m.playerView.contentCategory = item.category
    m.playerView.resumePosition = 0
    m.playerView.persistEnabled = false
    m.playerView.nextEpisode = invalid
    m.playerView.skipIntroEnd = 0
    m.playerView.streamUrl = item.stream_url
    m.playerView.visible = true
end sub

sub onPlayerChannelRequested()
    request = m.playerView.channelRequested
    if request = invalid or request.item = invalid then return
    playLiveItem(request.item, m.playerView.liveQueue, request.index)
end sub

sub onPlayerFavoriteRequested()
    request = m.playerView.favoriteRequested
    if request = invalid or request.id = invalid then return
    item = resolveCatalogItem(request)
    if item = invalid then return
    state = loadLocalState()
    for each favorite in state.favorites
        if favorite.id = item.id then
            removeFavorite(item.id)
            return
        end if
    end for
    saveFavorite(item)
end sub

sub onSearchKeyboardSelected()
    if m.searchKeyboard.buttonSelected = 0 then m.searchView.callFunc("setQuery", m.searchKeyboard.text)
    m.top.getScene().dialog = invalid
    m.searchKeyboard = invalid
    m.top.setFocus(true)
end sub

sub onBrowseItemSelected()
    selected = invalid
    if m.selectedIndex = 2 then selected = m.moviesView.selectedItem
    if m.selectedIndex = 3 then selected = m.seriesView.selectedItem
    if selected = invalid then return
    ' Mesmo caminho do Inicio e da Busca: inclui o pedido de temporadas das series.
    openCatalogItem(selected)
end sub

sub loadMetadata(item as Object, mode as String, tmdbId as Integer, seasonNumber as Integer)
    ' Versao da loja nao usa o Portal (sem licenca): os detalhes vem so da propria lista.
    if m.top.storeEdition then return
    if m.top.rokuClientId = "" or m.top.deviceCode = "" or m.top.deviceKey = "" then return
    mediaType = "movie"
    if item <> invalid and item.category <> invalid then
        category = lcase(item.category)
        if instr(1, category, "série") > 0 or instr(1, category, "serie") > 0 or instr(1, category, "series") > 0 then mediaType = "tv"
    end if
    if item <> invalid and item.type <> invalid and item.type = "series" then mediaType = "tv"
    service = CreateObject("roSGNode", "MetadataService")
    service.rokuClientId = m.top.rokuClientId
    service.deviceCode = m.top.deviceCode
    service.deviceKey = m.top.deviceKey
    if item <> invalid and item.title <> invalid then service.title = item.title
    service.mediaType = mediaType
    service.mode = mode
    service.tmdbId = tmdbId
    service.seasonNumber = seasonNumber
    service.observeField("result", "onMetadataResult")
    m.metadataService = service
    service.control = "RUN"
end sub

sub onMetadataResult()
    result = m.metadataService.result
    if result = invalid or result.ok <> true then return
    m.detailView.metadata = result
    if result.mode = "search" and result.item <> invalid and result.item.id <> invalid then
        item = { title: m.detailView.item.title }
        loadMetadata(item, "details", result.item.id, 0)
    else if result.mode = "details" and result.media_type = "tv" and result.item <> invalid and result.item.seasons <> invalid and result.item.seasons.count() > 0 and not detailIsXtreamSeries() then
        m.detailTmdbId = result.item.id
        item = { title: m.detailView.item.title }
        loadMetadata(item, "season", result.item.id, result.item.seasons[0].number)
    end if
end sub

sub onSeasonRequested()
    seasonNumber = m.detailView.seasonRequested
    if seasonNumber < 0 then return
    if m.detailTmdbId = invalid or m.detailTmdbId <= 0 then return
    item = { title: m.detailView.item.title }
    loadMetadata(item, "season", m.detailTmdbId, seasonNumber)
end sub

sub onDetailClosed()
    if m.detailView.closeRequested <> true then return
    m.detailView.visible = false
    m.detailView.closeRequested = false
    m.top.setFocus(true)
end sub

sub onPlayRequested()
    item = m.detailView.playRequested
    if item = invalid then return
    if item.stream_url = invalid or item.stream_url = "" then return
    playCatalogItem(item, resumePositionFor(item))
end sub

sub onTrailerRequested()
    trailer = m.detailView.trailerRequested
    if trailer = invalid or trailer.url = invalid or trailer.url = "" then return
    if trailer.id = invalid or trailer.category = invalid then return
    if isParentallyBlockedItem(trailer.category, trailer.id) then return
    clearEpisodeQueue()
    m.playerView.liveQueue = []
    m.playerView.liveIndex = 0
    m.playerView.contentTitle = trailer.title
    m.playerView.contentId = trailer.id
    m.playerView.contentCategory = trailer.category
    m.playerView.resumePosition = 0
    m.playerView.persistEnabled = false
    m.playerView.nextEpisode = invalid
    m.playerView.skipIntroEnd = 0
    m.playerView.streamUrl = trailer.url
    m.playerView.visible = true
end sub

sub onEpisodeRequested()
    episode = m.detailView.episodeRequested
    if episode = invalid or episode.url = invalid or episode.url = "" then return
    if episode.parentId = invalid or episode.category = invalid then return
    if isParentallyBlockedItem(episode.category, episode.parentId) then return
    if episode.queue <> invalid and type(episode.queue) = "roArray" then
        m.episodeQueue = episode.queue
    else
        m.episodeQueue = [episode]
    end if
    m.episodeQueueIndex = 0
    m.playerView.liveQueue = []
    m.playerView.liveIndex = 0
    m.playerView.contentTitle = episode.title
    m.playerView.contentId = episode.id
    m.playerView.contentCategory = episode.category
    m.playerView.resumePosition = resumePositionFor(episode)
    m.playerView.persistEnabled = true
    if episode.introEnd <> invalid then m.playerView.skipIntroEnd = int(episode.introEnd) else m.playerView.skipIntroEnd = 0
    if m.episodeQueue.count() > 1 then
        m.playerView.nextEpisode = m.episodeQueue[1]
    else
        m.playerView.nextEpisode = invalid
    end if
    m.playerView.streamUrl = episode.url
    m.playerView.visible = true
end sub

sub onNextEpisodeRequested()
    if m.episodeQueue = invalid or m.episodeQueueIndex = invalid then return
    nextIndex = m.episodeQueueIndex + 1
    if nextIndex >= m.episodeQueue.count() then return
    episode = m.episodeQueue[nextIndex]
    if episode = invalid or episode.url = invalid or episode.url = "" then return
    if episode.parentId = invalid or episode.category = invalid then return
    if isParentallyBlockedItem(episode.category, episode.parentId) then return
    m.episodeQueueIndex = nextIndex
    m.playerView.liveQueue = []
    m.playerView.liveIndex = 0
    m.playerView.contentTitle = episode.title
    m.playerView.contentId = episode.id
    m.playerView.contentCategory = episode.category
    m.playerView.resumePosition = resumePositionFor(episode)
    m.playerView.persistEnabled = true
    if episode.introEnd <> invalid then m.playerView.skipIntroEnd = int(episode.introEnd) else m.playerView.skipIntroEnd = 0
    if m.episodeQueueIndex < m.episodeQueue.count() - 1 then
        m.playerView.nextEpisode = m.episodeQueue[m.episodeQueueIndex + 1]
    else
        m.playerView.nextEpisode = invalid
    end if
    m.playerView.streamUrl = episode.url
end sub

function resumePositionFor(item as Object) as Integer
    if item = invalid or item.id = invalid then return 0
    state = loadLocalState()
    if state.continue_watching = invalid then return 0
    for each saved in state.continue_watching
        if saved.id = item.id then
            if saved.completed <> invalid and saved.completed = true then return 0
            if saved.progress_seconds <> invalid and saved.progress_seconds > 0 then return int(saved.progress_seconds)
            return 0
        end if
    end for
    return 0
end function

sub onPlayerClosed()
    if m.playerView.closeRequested <> true then return
    clearEpisodeQueue()
    m.playerView.visible = false
    ' Zera a URL: sem isso, reabrir o mesmo canal/titulo nao dispara onStreamChanged
    m.playerView.streamUrl = ""
    m.playerView.closeRequested = false
    m.top.setFocus(true)
end sub

sub stopPlayback()
    clearEpisodeQueue()
    m.liveTVView.callFunc("stopPreview")
    m.playerView.callFunc("stopPlayback")
    m.playerView.visible = false
    m.playerView.streamUrl = ""
    m.detailView.visible = false
end sub

sub clearEpisodeQueue()
    m.episodeQueue = []
    m.episodeQueueIndex = 0
    m.playerView.nextEpisode = invalid
end sub

sub showSection()
    isHome = m.selectedIndex = 0
    isLive = m.selectedIndex = 1
    isMovies = m.selectedIndex = 2
    isSeries = m.selectedIndex = 3
    isSearch = m.selectedIndex = 4
    isSettings = m.selectedIndex = 6
    m.homeView.visible = isHome
    m.homeView.callFunc("setActive", isHome)
    m.liveTVView.visible = isLive
    m.moviesView.visible = isMovies
    m.seriesView.visible = isSeries
    m.searchView.visible = isSearch
    m.libraryView.visible = m.selectedIndex = 5
    m.parentalView.visible = isSettings
    if not isLive then m.liveTVView.callFunc("stopPreview")
    m.sectionEyebrow.visible = false
    m.sectionTitle.visible = false
    m.sectionDescription.visible = false
    m.sectionHint.visible = false
    sections = [
        { title: "Início", description: "Seus destaques, conteúdos recentes e continuar assistindo aparecerão aqui quando a lista deste Roku for sincronizada.", hint: "Escolha uma seção nos blocos." },
        { title: "TV ao Vivo", description: "Categorias, canais, preview com áudio e guia de programação serão exibidos nesta área.", hint: "O preview será descarregado ao sair desta tela." },
        { title: "Filmes", description: "Catálogo de filmes, detalhes, favoritos e continuar assistindo.", hint: "A lista sincronizada do Portal abastecerá este catálogo." },
        { title: "Séries", description: "Séries, temporadas expansíveis e episódios em uma experiência otimizada para controle remoto.", hint: "A navegação mantém o foco sempre visível." },
        { title: "Busca", description: "Busca global por canais, filmes, séries e episódios.", hint: "Digite usando o teclado virtual do Roku quando o catálogo estiver disponível." },
        { title: "Minha Lista", description: libraryDescription(), hint: "Favoritos, assistir mais tarde, continuar e histórico ficam neste Roku sem dados sensíveis." },
        { title: "Ajustes", description: "Perfil, controle parental, suporte e informações do dispositivo.", hint: "As opções de licença continuam disponíveis no Portal ELVANOQ." }
    ]
    section = sections[m.selectedIndex]
    m.sectionTitle.text = section.title
    m.sectionDescription.text = section.description
    m.sectionHint.text = section.hint
    pushSectionCatalog()
    if m.selectedIndex = 5 then m.libraryView.callFunc("refresh")
    if isSettings and m.categories <> invalid then m.parentalView.categories = m.categories
    if isSettings and m.catalog <> invalid then m.parentalView.items = m.catalog
end sub

function libraryDescription() as String
    state = loadLocalState()
    return safeTrim(str(state.favorites.count())) + " favoritos, " + safeTrim(str(state.watch_later.count())) + " para assistir mais tarde e " + safeTrim(str(state.continue_watching.count())) + " em andamento."
end function

sub saveFavorite(item as Object)
    state = loadLocalState()
    state.favorites = upsertLocalItem(state.favorites, item)
    saveLocalState(state)
    m.localState = state
end sub

sub removeFavorite(itemId as String)
    state = loadLocalState()
    state.favorites = removeLocalItem(state.favorites, itemId)
    saveLocalState(state)
    m.localState = state
end sub

sub saveProgress(item as Object)
    state = loadLocalState()
    state.continue_watching = upsertLocalItem(state.continue_watching, item)
    saveLocalState(state)
    m.localState = state
end sub

sub applyPlaylist(payload as Object)
    if payload = invalid or type(payload) <> "roAssociativeArray" then return
    savePlaylistMetadata(payload)
    if payload.display_name <> invalid and payload.display_name <> "" then
        m.playlistName = payload.display_name
        if m.selectedIndex = 0 then
            m.sectionDescription.text = "Lista conectada: " + m.playlistName + ". Seus destaques aparecerão aqui conforme o catálogo for carregado."
            m.sectionHint.text = "A sincronização foi concluída com segurança."
        end if
    end if
    if payload.playlist <> invalid and type(payload.playlist) = "roAssociativeArray" then loadCatalog(payload.playlist)
end sub

sub loadCatalog(playlist as Object)
    service = CreateObject("roSGNode", "CatalogService")
    service.playlist = playlist
    service.observeField("result", "onCatalogResult")
    m.catalogService = service
    service.control = "RUN"
end sub

sub onCatalogResult()
    result = m.catalogService.result
    if result = invalid then return
    state = { ok: result.ok = true, message: "" }
    if result.message <> invalid then state.message = result.message
    m.top.catalogState = state
    if result.ok <> true then return
    m.categories = result.categories
    m.lazy = (result.lazy = true)
    m.categoryCache = {}
    m.categoryCacheOrder = []
    m.searchItems = []
    if m.lazy then
        m.xtream = result.xtream
        m.liveCategories = result.liveCategories
        m.movieCategories = result.movieCategories
        m.seriesCategories = result.seriesCategories
        m.categoryNames = { live: categoryNameMap(m.liveCategories), movies: categoryNameMap(m.movieCategories), series: categoryNameMap(m.seriesCategories) }
        m.seedItems = result.channels
        rebuildCatalogPool()
    else
        m.xtream = invalid
        m.seedItems = invalid
        m.catalog = result.channels
    end if
    if result.epgUrl <> invalid and result.epgUrl <> "" then loadEpg(result.epgUrl)
    pushSectionCatalog()
    tryDeepLink()
end sub

sub loadEpg(epgUrl as String)
    service = CreateObject("roSGNode", "EpgService")
    service.epgUrl = epgUrl
    service.observeField("result", "onEpgResult")
    m.epgService = service
    service.control = "RUN"
end sub

sub onEpgResult()
    result = m.epgService.result
    if result = invalid or result.ok <> true then return
    m.epg = result.entries
    m.liveTVView.callFunc("setEpg", result.entries)
end sub

sub onLiveEpgUpdate()
    update = m.liveTVView.epgUpdate
    if update = invalid then return
    if m.epg = invalid then m.epg = {}
    for each key in update
        m.epg[key] = update[key]
    end for
end sub

function liveGuideFor(item as Object) as Object
    guide = {}
    key = epgKeyFor(item)
    if key = "" then return guide
    if m.epg = invalid or m.epg[key] = invalid then return guide
    programmes = m.epg[key]
    if programmes = invalid or programmes.count() = 0 then return guide
    guide.now = programmes[0]
    if programmes.count() > 1 then guide.next = programmes[1]
    return guide
end function

sub savePlaylistMetadata(payload as Object)
    metadata = { synced_at: CreateObject("roDateTime").ToISOString() }
    if payload.display_name <> invalid then metadata.display_name = payload.display_name
    if payload.server_code <> invalid then metadata.server_code = payload.server_code
    if payload.playlist <> invalid and type(payload.playlist) = "roAssociativeArray" then
        if payload.playlist.source_type <> invalid then metadata.source_type = payload.playlist.source_type
    end if
    section = CreateObject("roRegistrySection", "ELVANOQPlay")
    section.Write("playlist_metadata", FormatJson(metadata))
    section.Flush()
end sub

function pinDigitFromKey(key as String) as String
    ' O controle Roku nao tem teclado numerico; o app mobile envia "Lit_5".
    if len(key) = 1 and key >= "0" and key <= "9" then return key
    if len(key) = 5 and left(key, 4) = "Lit_" then
        digit = right(key, 1)
        if digit >= "0" and digit <= "9" then return digit
    end if
    return ""
end function

' callFunc devolve invalid se a funcao falhar; comparar invalid = true derruba o app.
function isTrue(value as Dynamic) as Boolean
    t = type(value)
    if t = "roBoolean" or t = "Boolean" then return value
    return false
end function

function detailIsXtreamSeries() as Boolean
    item = m.detailView.item
    if item = invalid then return false
    return item.series_id <> invalid and safeTrim(item.series_id) <> ""
end function

' ---------- Versao da loja ----------

sub onStoreEditionChanged()
    if not m.top.storeEdition then return
    subtitle = m.parentalView.findNode("pageSubtitle")
    if subtitle <> invalid then subtitle.text = "Controle parental   •   Tecla Replay: desconectar a lista desta TV"
end sub

sub openDisconnectDialog()
    dialog = CreateObject("roSGNode", "StandardMessageDialog")
    dialog.title = "Desconectar lista"
    dialog.message = ["Os dados de acesso da lista serão apagados desta TV. Favoritos e progresso continuam salvos."]
    dialog.buttons = ["Desconectar", "Cancelar"]
    dialog.observeField("buttonSelected", "onDisconnectDialogSelected")
    m.disconnectDialog = dialog
    m.top.getScene().dialog = dialog
end sub

sub onDisconnectDialogSelected()
    choice = m.disconnectDialog.buttonSelected
    m.top.getScene().dialog = invalid
    m.disconnectDialog = invalid
    m.top.setFocus(true)
    if choice <> 0 then return
    m.selectedIndex = 0
    showSection()
    m.top.disconnectRequested = true
end sub

' ---------- Deep linking (busca e voz da Roku) ----------
' contentId aceito: o id de um item ja conhecido, ou "movie:<stream_id>[:ext]",
' "episode:<id>[:ext]", "series:<series_id>", "channel:<stream_id>".

sub onDeepLink()
    link = m.top.deepLink
    if link = invalid or link.contentId = invalid or link.contentId = "" then return
    m.pendingDeepLink = link
    tryDeepLink()
end sub

sub tryDeepLink()
    link = m.pendingDeepLink
    if link = invalid or m.catalog = invalid then return
    m.pendingDeepLink = invalid
    contentId = safeTrim(link.contentId)
    mediaType = ""
    if link.mediaType <> invalid then mediaType = lcase(safeTrim(link.mediaType))
    item = resolveCatalogItem({ id: contentId })
    if item = invalid then item = deepLinkItem(contentId)
    if item = invalid then return
    m.detailView.visible = false
    if item.type = "live" or mediaType = "live" then
        playLiveItem(item, [item], 0)
    else if item.type = "series" or mediaType = "series" or mediaType = "season" then
        openCatalogItem(item)
    else if item.stream_url <> invalid and item.stream_url <> "" then
        ' Direct to Play: filme/episodio comecam direto, retomando de onde parou.
        playCatalogItem(item, resumePositionFor(item))
    else
        openCatalogItem(item)
    end if
end sub

function deepLinkItem(contentId as String) as Object
    if m.xtream = invalid then return invalid
    parts = contentId.Split(":")
    if parts.count() < 2 then return invalid
    kind = lcase(parts[0])
    sid = safeTrim(parts[1])
    if sid = "" then return invalid
    ext = ""
    if parts.count() > 2 then ext = safeTrim(parts[2])
    if kind = "episode" then
        if ext = "" then ext = "mp4"
        item = { id: contentId, title: "Episódio", category: "", type: "movies", logo: "" }
        item.stream_url = m.xtream.host + "/series/" + m.xtream.userEscaped + "/" + m.xtream.passEscaped + "/" + sid + "." + ext
        return item
    end if
    itemType = ""
    if kind = "movie" then itemType = "movies"
    if kind = "series" then itemType = "series"
    if kind = "channel" then itemType = "live"
    if itemType = "" then return invalid
    if itemType = "movies" and ext = "" then ext = "mp4"
    saved = { id: contentId, type: itemType, sid: sid, ext: ext, title: "" }
    return xtreamItemFromSaved(m.xtream, saved)
end function
