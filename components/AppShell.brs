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

sub showSection()
    isHome = m.selectedIndex = 0
    isLive = m.selectedIndex = 1
    isMovies = m.selectedIndex = 2
    isSeries = m.selectedIndex = 3
    m.homeView.visible = isHome
    m.liveTVView.visible = isLive
    m.moviesView.visible = isMovies
    m.seriesView.visible = isSeries
    if not isLive then m.liveTVView.callFunc("stopPreview")
    m.sectionEyebrow.visible = not isHome and not isLive and not isMovies and not isSeries
    m.sectionTitle.visible = not isHome and not isLive and not isMovies and not isSeries
    m.sectionDescription.visible = not isHome and not isLive and not isMovies and not isSeries
    m.sectionHint.visible = not isHome and not isLive and not isMovies and not isSeries
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
