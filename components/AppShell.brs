sub init()
    m.localState = loadLocalState()
    m.focusRail = m.top.findNode("focusRail")
    m.sectionEyebrow = m.top.findNode("sectionEyebrow")
    m.sectionTitle = m.top.findNode("sectionTitle")
    m.sectionDescription = m.top.findNode("sectionDescription")
    m.sectionHint = m.top.findNode("sectionHint")
    m.homeView = m.top.findNode("homeView")
    m.liveTVView = m.top.findNode("liveTVView")
    m.moviesView = m.top.findNode("moviesView")
    m.seriesView = m.top.findNode("seriesView")
    m.searchView = m.top.findNode("searchView")
    m.parentalView = m.top.findNode("parentalView")
    m.detailView = m.top.findNode("detailView")
    m.playerView = m.top.findNode("playerView")
    m.moviesView.observeField("selectedItem", "onBrowseItemSelected")
    m.seriesView.observeField("selectedItem", "onBrowseItemSelected")
    m.detailView.observeField("closeRequested", "onDetailClosed")
    m.detailView.observeField("playRequested", "onPlayRequested")
    m.detailView.observeField("seasonRequested", "onSeasonRequested")
    m.playerView.observeField("closeRequested", "onPlayerClosed")
    m.navItems = [
        m.top.findNode("navHome"),
        m.top.findNode("navLive"),
        m.top.findNode("navMovies"),
        m.top.findNode("navSeries"),
        m.top.findNode("navSearch"),
        m.top.findNode("navLibrary"),
        m.top.findNode("navSettings")
    ]
    for each item in m.navItems
        item.font = "font:MediumSystemFont"
        item.color = "0xAFC2D9FF"
    end for
    m.sectionEyebrow.font = "font:MediumSystemFont"
    m.sectionEyebrow.color = "0x73B7FFFF"
    m.sectionTitle.font = "font:LargeBoldSystemFont"
    m.sectionDescription.font = "font:MediumSystemFont"
    m.sectionDescription.color = "0xC4D2E0FF"
    m.sectionHint.font = "font:SmallSystemFont"
    m.sectionHint.color = "0x8FA9C4FF"
    m.selectedIndex = 0
    showSection()
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
    if not press then return false
    if m.playerView.visible then return m.playerView.callFunc("handleKey", { key: key, press: press })
    if m.detailView.visible then return m.detailView.callFunc("handleKey", { key: key, press: press })
    if m.selectedIndex = 6 then
        if key >= "0" and key <= "9" then
            m.parentalView.callFunc("enterDigit", key)
            return true
        end if
        if key = "back" then
            m.parentalView.callFunc("clearDigit")
            return true
        end if
    end if
    if m.selectedIndex = 1 then
        if key = "down" then
            m.liveTVView.callFunc("moveChannel", 1)
            return true
        end if
        if key = "up" then
            m.liveTVView.callFunc("moveChannel", -1)
            return true
        end if
        if key = "OK" or key = "right" then
            m.liveTVView.callFunc("playSelected")
            return true
        end if
    end if
    if key = "down" and m.selectedIndex < m.navItems.count() - 1 then
        m.selectedIndex = m.selectedIndex + 1
        showSection()
        return true
    end if
    if key = "up" and m.selectedIndex > 0 then
        m.selectedIndex = m.selectedIndex - 1
        showSection()
        return true
    end if
    return key = "OK"
end function

sub onBrowseItemSelected()
    selected = invalid
    if m.selectedIndex = 2 then selected = m.moviesView.selectedItem
    if m.selectedIndex = 3 then selected = m.seriesView.selectedItem
    if selected = invalid then return
    m.detailView.item = selected
    m.detailView.metadata = invalid
    m.detailView.visible = true
    loadMetadata(selected, "search", 0, 0)
end sub

sub loadMetadata(item as Object, mode as String, tmdbId as Integer, seasonNumber as Integer)
    if m.top.rokuClientId = "" or m.top.deviceCode = "" or m.top.deviceKey = "" then return
    mediaType = "movie"
    if m.selectedIndex = 3 then mediaType = "tv"
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
    else if result.mode = "details" and result.media_type = "tv" and result.item <> invalid and result.item.seasons <> invalid and result.item.seasons.count() > 0 then
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
end sub

sub onPlayRequested()
    item = m.detailView.playRequested
    if item = invalid then return
    if item.stream_url = invalid or item.stream_url = "" then return
    m.playerView.contentTitle = item.title
    m.playerView.contentId = item.id
    m.playerView.contentCategory = item.category
    m.playerView.streamUrl = item.stream_url
    m.playerView.visible = true
end sub

sub onPlayerClosed()
    if m.playerView.closeRequested <> true then return
    m.playerView.visible = false
    m.playerView.closeRequested = false
end sub

sub showSection()
    isHome = m.selectedIndex = 0
    isLive = m.selectedIndex = 1
    isMovies = m.selectedIndex = 2
    isSeries = m.selectedIndex = 3
    isSearch = m.selectedIndex = 4
    isSettings = m.selectedIndex = 6
    m.homeView.visible = isHome
    m.liveTVView.visible = isLive
    m.moviesView.visible = isMovies
    m.seriesView.visible = isSeries
    m.searchView.visible = isSearch
    m.parentalView.visible = isSettings
    if not isLive then m.liveTVView.callFunc("stopPreview")
    m.sectionEyebrow.visible = not isHome and not isLive and not isMovies and not isSeries and not isSearch and not isSettings
    m.sectionTitle.visible = not isHome and not isLive and not isMovies and not isSeries and not isSearch and not isSettings
    m.sectionDescription.visible = not isHome and not isLive and not isMovies and not isSeries and not isSearch and not isSettings
    m.sectionHint.visible = not isHome and not isLive and not isMovies and not isSeries and not isSearch and not isSettings
    for index = 0 to m.navItems.count() - 1
        if index = m.selectedIndex then
            m.navItems[index].color = "0xFFFFFFFF"
        else
            m.navItems[index].color = "0xAFC2D9FF"
        end if
    end for
    m.focusRail.translation = [20, 210 + (m.selectedIndex * 70)]

    sections = [
        { title: "Início", description: "Seus destaques, conteúdos recentes e continuar assistindo aparecerão aqui quando a lista deste Roku for sincronizada.", hint: "Use as setas para navegar pelo menu." },
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
    if isHome and m.catalog <> invalid then m.homeView.callFunc("setCatalog", { items: m.catalog, categories: m.categories })
    if isLive and m.catalog <> invalid then m.liveTVView.callFunc("setCatalog", { items: m.catalog, categories: m.categories })
    if isMovies and m.catalog <> invalid then m.moviesView.callFunc("setCatalog", { items: m.catalog })
    if isSeries and m.catalog <> invalid then m.seriesView.callFunc("setCatalog", { items: m.catalog })
    if isSearch and m.catalog <> invalid then m.searchView.callFunc("setCatalog", { items: m.catalog })
end sub

function libraryDescription() as String
    return str(m.localState.favorites.count()) + " favoritos, " + str(m.localState.watch_later.count()) + " para assistir mais tarde e " + str(m.localState.continue_watching.count()) + " em andamento."
end function

sub saveFavorite(item as Object)
    m.localState.favorites = upsertLocalItem(m.localState.favorites, item)
    saveLocalState(m.localState)
end sub

sub removeFavorite(itemId as String)
    m.localState.favorites = removeLocalItem(m.localState.favorites, itemId)
    saveLocalState(m.localState)
end sub

sub saveProgress(item as Object)
    m.localState.continue_watching = upsertLocalItem(m.localState.continue_watching, item)
    saveLocalState(m.localState)
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
    if result = invalid or result.ok <> true then return
    m.catalog = result.channels
    m.categories = result.categories
    if m.selectedIndex = 0 then m.homeView.callFunc("setCatalog", { items: m.catalog, categories: m.categories })
    if m.selectedIndex = 1 then m.liveTVView.callFunc("setCatalog", { items: m.catalog, categories: m.categories })
    if m.selectedIndex = 2 then m.moviesView.callFunc("setCatalog", { items: m.catalog })
    if m.selectedIndex = 3 then m.seriesView.callFunc("setCatalog", { items: m.catalog })
    if m.selectedIndex = 4 then m.searchView.callFunc("setCatalog", { items: m.catalog })
end sub

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
