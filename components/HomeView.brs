' Inicio em formato de hub: destaque largo, blocos de navegacao e uma fileira.
' O foco fica no AppShell; esta tela recebe as teclas por handleKey().
sub init()
    m.heroArt = m.top.findNode("heroArt")
    m.eyebrow = m.top.findNode("eyebrow")
    m.heroTitle = m.top.findNode("heroTitle")
    m.heroMeta = m.top.findNode("heroMeta")
    m.heroDescription = m.top.findNode("heroDescription")
    m.watchButton = m.top.findNode("watchButton")
    m.detailsButton = m.top.findNode("detailsButton")
    m.watchLabel = m.top.findNode("watchLabel")
    m.detailsLabel = m.top.findNode("detailsLabel")
    m.actionFocus = m.top.findNode("actionFocus")
    m.heroTimer = m.top.findNode("heroTimer")
    m.tileFocus = m.top.findNode("tileFocus")
    m.continueTitle = m.top.findNode("continueTitle")
    m.continueHint = m.top.findNode("continueHint")
    m.continueGrid = m.top.findNode("continueGrid")
    m.emptyState = m.top.findNode("emptyState")
    m.dots = [m.top.findNode("dot0"), m.top.findNode("dot1"), m.top.findNode("dot2")]

    m.eyebrow.font = appFont(18, "bold")
    m.eyebrow.color = "0x00D7FFFF"
    m.heroTitle.font = appFont(56, "bold")
    m.heroTitle.color = "0xF4F8FFFF"
    m.heroMeta.font = appFont(20, "regular")
    m.heroMeta.color = "0xB6C2D6FF"
    m.heroDescription.font = appFont(24, "regular")
    m.heroDescription.color = "0xD6DEEBFF"
    m.watchLabel.font = appFont(26, "semibold")
    m.watchLabel.color = "0x070B14FF"
    m.detailsLabel.font = appFont(26, "semibold")
    m.detailsLabel.color = "0xF4F8FFFF"
    m.continueTitle.font = appFont(26, "semibold")
    m.continueTitle.color = "0xF4F8FFFF"
    m.continueHint.font = appFont(20, "regular")
    m.continueHint.color = "0x8894A8FF"
    m.emptyState.font = appFont(24, "regular")
    m.emptyState.color = "0x8894A8FF"

    ' Blocos: indice da secao no AppShell (1 = TV ao Vivo ... 6 = Ajustes)
    m.tileDefs = [
        { section: 1, title: "TV ao Vivo", icon: "pkg:/images/icon_live.png" },
        { section: 2, title: "Filmes", icon: "pkg:/images/icon_movies.png" },
        { section: 3, title: "Séries", icon: "pkg:/images/icon_series.png" },
        { section: 4, title: "Busca", icon: "pkg:/images/icon_search.png" },
        { section: 5, title: "Minha Lista", icon: "pkg:/images/icon_list.png" },
        { section: 6, title: "Ajustes", icon: "pkg:/images/icon_settings.png" }
    ]
    m.tileWidth = 280
    m.tileHeight = 150
    m.tileGap = 22
    buildTiles()

    m.selectedAction = 0
    m.focusArea = 1
    m.tileIndex = 0
    m.continueIndex = 0
    m.continueOffset = 0
    m.heroCandidates = []
    m.heroIndex = 0
    m.heroArtCache = {}
    m.isActive = true
    m.showFocus = true
    m.page = m.top.findNode("page")
    m.scrollAnimation = m.top.findNode("scrollAnimation")
    m.scrollInterpolator = m.top.findNode("scrollInterpolator")
    m.pageOffset = 0
    m.heroTimer.observeField("fire", "onHeroTimerFired")
    updateFocusArea()
end sub

sub buildTiles()
    group = m.top.findNode("tiles")
    m.tileBackgrounds = []
    m.tileLabels = []
    for index = 0 to m.tileDefs.count() - 1
        definition = m.tileDefs[index]
        x = index * (m.tileWidth + m.tileGap)
        background = group.createChild("Rectangle")
        background.translation = [x, 0]
        background.width = m.tileWidth
        background.height = m.tileHeight
        background.color = "0x0D1422FF"
        icon = group.createChild("Poster")
        icon.uri = definition.icon
        icon.width = 64
        icon.height = 64
        icon.translation = [x + int((m.tileWidth - 64) / 2), 24]
        label = group.createChild("Label")
        label.text = definition.title
        label.font = appFont(24, "regular")
        label.color = "0xF4F8FFFF"
        label.horizAlign = "center"
        label.width = m.tileWidth
        label.height = 40
        label.translation = [x, 98]
        m.tileBackgrounds.push(background)
        m.tileLabels.push(label)
    end for
end sub

sub setCatalog(payload as Object)
    if payload = invalid or type(payload) <> "roAssociativeArray" then return
    items = payload.items
    if items = invalid or items.count() = 0 then
        m.heroTimer.control = "stop"
        m.heroCandidates = []
        m.continueItems = []
        m.emptyState.visible = true
        m.emptyState.text = "Sua lista será exibida aqui assim que a sincronização for concluída."
        return
    end if
    m.emptyState.visible = false
    state = loadLocalState()
    continueItems = resolveLocalItems(state.continue_watching, items)
    favoriteItems = resolveLocalItems(state.favorites, items)
    m.heroTimer.control = "stop"
    m.heroCandidates = uniqueHeroCandidates(continueItems, favoriteItems, items)
    m.heroIndex = 0
    if m.heroCandidates.count() > 0 then renderHero(m.heroCandidates[0])
    if continueItems.count() > 0 then
        m.continueTitle.text = "Continuar assistindo"
        m.continueHint.text = "Retome de onde parou"
        m.continueItems = continueItems
    else if favoriteItems.count() > 0 then
        m.continueTitle.text = "Seus favoritos"
        m.continueHint.text = "Canais e títulos salvos neste Roku"
        m.continueItems = favoriteItems
    else
        ' Como no Android: filmes e series mais recentes, nao canais.
        m.continueTitle.text = "Novidades para você"
        m.continueHint.text = "Filmes e séries adicionados recentemente"
        m.continueItems = recentTitles(items, 30)
        if m.continueItems.count() = 0 then m.continueItems = items
    end if
    m.continueIndex = 0
    m.continueOffset = 0
    renderRails()
    renderDots()
    if m.isActive and m.heroCandidates.count() > 1 then m.heroTimer.control = "start"
end sub

' ---------- Destaque ----------

function uniqueHeroCandidates(continueItems as Object, favoriteItems as Object, catalogItems as Object) as Object
    ' Como no Android: o destaque prefere filmes e series; canais so se nao houver outros.
    titles = []
    for each item in catalogItems
        if item.type = "movies" or item.type = "series" then titles.push(item)
    end for
    source = titles
    if source.count() = 0 then source = catalogItems
    candidates = []
    appendSingleHeroCandidate(candidates, featuredItem(source), "DESTAQUE DA SEMANA")
    appendSingleHeroCandidate(candidates, newestItem(source), "RECÉM-ADICIONADO")
    appendSingleHeroCandidate(candidates, highestRatedItem(source), "MAIS BEM AVALIADO")
    appendHeroCandidate(candidates, continueItems, "CONTINUE ASSISTINDO")
    appendHeroCandidate(candidates, source, "DESTAQUE ELVANOQ")
    while candidates.count() > 3
        candidates.pop()
    end while
    return candidates
end function

' Filmes e series ordenados do mais recente para o mais antigo.
function recentTitles(items as Object, limit as Integer) as Object
    titles = []
    for each item in items
        if item.type = "movies" or item.type = "series" then
            entry = {}
            entry.item = item
            entry.added = 0
            if item.added_at <> invalid then entry.added = safeTrim(item.added_at).ToInt()
            titles.push(entry)
        end if
    end for
    titles.SortBy("added", "r")
    result = []
    for each entry in titles
        if result.count() >= limit then exit for
        result.push(entry.item)
    end for
    return result
end function

function newestItem(items as Object) as Object
    best = invalid
    bestValue = 0
    for each item in items
        value = 0
        if item.added_at <> invalid then value = safeTrim(item.added_at).ToInt()
        if value > bestValue then
            best = item
            bestValue = value
        end if
    end for
    return best
end function

function featuredItem(items as Object) as Object
    for each item in items
        if item.featured <> invalid then
            value = lcase(safeTrim(item.featured))
            if value = "true" or value = "1" or value = "yes" then return item
        end if
    end for
    return invalid
end function

function highestRatedItem(items as Object) as Object
    best = invalid
    bestValue = -1
    for each item in items
        if item.rating <> invalid and safeTrim(item.rating) <> "" then
            value = val(safeTrim(item.rating))
            if value > bestValue then
                best = item
                bestValue = value
            end if
        end if
    end for
    return best
end function

sub appendSingleHeroCandidate(target as Object, candidate as Object, eyebrow as String)
    if candidate = invalid then return
    for each existing in target
        if existing.item.id = candidate.id then return
    end for
    target.push({ item: candidate, eyebrow: eyebrow })
end sub

sub appendHeroCandidate(target as Object, source as Object, eyebrow as String)
    if source = invalid or source.count() = 0 then return
    appendSingleHeroCandidate(target, source[0], eyebrow)
end sub

sub renderHero(candidate as Object)
    if candidate = invalid or candidate.item = invalid then return
    hero = candidate.item
    m.hero = hero
    m.eyebrow.text = candidate.eyebrow
    m.heroTitle.text = hero.title
    meta = hero.category
    if hero.rating <> invalid and safeTrim(hero.rating) <> "" and val(safeTrim(hero.rating)) > 0 then meta = meta + "   •   Nota " + safeTrim(hero.rating)
    m.heroMeta.text = meta
    if hero.plot <> invalid and safeTrim(hero.plot) <> "" then
        m.heroDescription.text = safeTrim(hero.plot)
    else
        m.heroDescription.text = "Disponível na sua lista autorizada."
    end if
    m.watchLabel.font = appFont(26, "semibold")
    if hero.type = "series" then
        m.watchLabel.text = "Ver episódios"
    else
        m.watchLabel.text = "Assistir agora"
    end if
    art = ""
    if hero.backdrop <> invalid and safeTrim(hero.backdrop) <> "" then art = safeTrim(hero.backdrop)
    if art = "" and m.heroArtCache[hero.id] <> invalid then art = m.heroArtCache[hero.id]
    if art = "" and hero.logo <> invalid then art = hero.logo
    m.heroArt.uri = art
    ' Filmes Xtream nao trazem imagem larga na lista: busca no get_vod_info.
    if hero.type = "movies" and m.heroArtCache[hero.id] = invalid then requestVodInfo(hero)
    updateActionCopy()
    renderDots()
end sub

sub requestVodInfo(hero as Object)
    if hero.stream_url = invalid or instr(1, hero.stream_url, "/movie/") = 0 then return
    task = CreateObject("roSGNode", "VodInfoService")
    task.streamUrl = hero.stream_url
    task.itemId = hero.id
    task.observeField("result", "onVodInfo")
    m.vodInfoTask = task
    task.control = "RUN"
end sub

sub onVodInfo(event as Object)
    result = event.getRoSGNode().result
    if result = invalid or result.itemId = invalid then return
    m.heroArtCache[result.itemId] = ""
    if result.backdrop <> invalid and result.backdrop <> "" then m.heroArtCache[result.itemId] = result.backdrop
    if m.hero = invalid or m.hero.id <> result.itemId then return
    if result.backdrop <> invalid and result.backdrop <> "" then m.heroArt.uri = result.backdrop
    if result.plot <> invalid and result.plot <> "" then m.heroDescription.text = result.plot
end sub

sub renderDots()
    count = m.heroCandidates.count()
    for index = 0 to 2
        dot = m.dots[index]
        dot.visible = count > 1 and index < count
        if index = m.heroIndex then
            dot.color = "0x00D7FFFF"
        else
            dot.color = "0x8894A880"
        end if
    end for
end sub

sub onHeroTimerFired()
    if not m.isActive or m.heroCandidates.count() < 2 then return
    ' Nao troca o destaque enquanto o usuario esta nos botoes dele.
    if m.focusArea = 0 then return
    m.heroIndex = m.heroIndex + 1
    if m.heroIndex >= m.heroCandidates.count() then m.heroIndex = 0
    renderHero(m.heroCandidates[m.heroIndex])
end sub

' ---------- Foco e teclas ----------

sub setActive(active as Boolean)
    m.isActive = active
    if active and m.heroCandidates.count() > 1 then
        m.heroTimer.control = "start"
    else
        m.heroTimer.control = "stop"
    end if
    updateFocusArea()
end sub

sub setFocusVisible(visible as Boolean)
    m.showFocus = visible
    updateFocusArea()
end sub

' Volta ao Inicio com o foco no bloco da secao de origem.
sub focusTile(section as Integer)
    for index = 0 to m.tileDefs.count() - 1
        if m.tileDefs[index].section = section then m.tileIndex = index
    end for
    m.focusArea = 1
    updateFocusArea()
end sub

function handleKey(event as Object) as Boolean
    if event.press <> true then return false
    key = event.key
    if key = "back" then return false
    if key = "down" then
        if m.focusArea < 2 then
            m.focusArea = m.focusArea + 1
            if m.focusArea = 2 and (m.continueItems = invalid or m.continueItems.count() = 0) then m.focusArea = 1
            updateFocusArea()
        end if
        return true
    end if
    if key = "up" then
        if m.focusArea > 0 and not (m.focusArea = 1 and m.hero = invalid) then
            m.focusArea = m.focusArea - 1
            updateFocusArea()
        end if
        return true
    end if
    if m.focusArea = 0 then return handleHeroKey(key)
    if m.focusArea = 1 then return handleTileKey(key)
    return handleRailKey(key)
end function

function handleHeroKey(key as String) as Boolean
    if key = "right" and m.selectedAction = 0 then
        m.selectedAction = 1
        updateFocusArea()
    else if key = "left" and m.selectedAction = 1 then
        m.selectedAction = 0
        updateFocusArea()
    else if key = "OK" and m.hero <> invalid then
        if m.selectedAction = 0 then
            m.top.playRequested = m.hero
        else
            toggleHeroFavorite()
        end if
    end if
    return true
end function

function handleTileKey(key as String) as Boolean
    if key = "right" and m.tileIndex < m.tileDefs.count() - 1 then
        m.tileIndex = m.tileIndex + 1
        updateFocusArea()
    else if key = "left" and m.tileIndex > 0 then
        m.tileIndex = m.tileIndex - 1
        updateFocusArea()
    else if key = "OK" then
        m.top.sectionRequested = m.tileDefs[m.tileIndex].section
    end if
    return true
end function

function handleRailKey(key as String) as Boolean
    items = m.continueItems
    if items = invalid or items.count() = 0 then return true
    index = m.continueIndex
    offset = m.continueOffset
    if key = "right" and index < items.count() - 1 then index = index + 1
    if key = "left" and index > 0 then index = index - 1
    if index < offset then offset = index
    if index >= offset + 8 then offset = index - 7
    windowChanged = offset <> m.continueOffset
    m.continueIndex = index
    m.continueOffset = offset
    if windowChanged then renderRails()
    if key = "OK" then m.top.selectedItem = items[index]
    updateFocusArea()
    return true
end function

sub updateFocusArea()
    visible = m.isActive = true and m.showFocus <> false
    ' Botoes do destaque
    m.actionFocus.visible = visible and m.focusArea = 0
    if m.selectedAction = 0 then
        m.actionFocus.translation = [58, 494]
        m.actionFocus.width = 252
    else
        m.actionFocus.translation = [318, 494]
        m.actionFocus.width = 272
    end if
    ' Blocos
    for index = 0 to m.tileBackgrounds.count() - 1
        if visible and m.focusArea = 1 and index = m.tileIndex then
            m.tileBackgrounds[index].color = "0x147DFFFF"
        else
            m.tileBackgrounds[index].color = "0x0D1422FF"
        end if
    end for
    m.tileFocus.visible = visible and m.focusArea = 1
    m.tileFocus.translation = [58 + m.tileIndex * (m.tileWidth + m.tileGap), 656]
    ' Fileira
    frame = m.top.findNode("continueFocus")
    frame.visible = false
    if visible and m.focusArea = 2 then
        m.continueGrid.jumpToItem = m.continueIndex - m.continueOffset
        placeFocusFrame(frame, m.continueGrid, m.continueIndex - m.continueOffset, 8, 196, 294, 24, 0)
    end if
    ' Fileira com foco: a pagina sobe para mostrar os posteres inteiros.
    if m.focusArea = 2 then
        scrollPage(-270)
    else
        scrollPage(0)
    end if
end sub

sub renderRails()
    if m.continueItems <> invalid then m.continueGrid.content = buildContentWindow(m.continueItems, 8, m.continueOffset)
end sub

' ---------- Auxiliares (da versao anterior) ----------

function resolveLocalItems(savedItems as Object, catalogItems as Object) as Object
    resolved = []
    if savedItems = invalid or catalogItems = invalid then return resolved
    for each saved in savedItems
        if saved.id <> invalid then
            for each item in catalogItems
                if item.id = saved.id then
                    resolved.push(item)
                    exit for
                end if
            end for
        end if
    end for
    return resolved
end function

function buildContentWindow(items as Object, maximum as Integer, offset as Integer) as Object
    content = CreateObject("roSGNode", "ContentNode")
    if items = invalid or items.count() = 0 then return content
    lastIndex = offset + maximum - 1
    if lastIndex > items.count() - 1 then lastIndex = items.count() - 1
    for index = offset to lastIndex
        item = items[index]
        child = CreateObject("roSGNode", "ContentNode")
        child.title = item.title
        if item.logo <> invalid then child.hdPosterUrl = item.logo
        content.appendChild(child)
    end for
    return content
end function

sub updateActionCopy()
    if m.hero = invalid then return
    state = loadLocalState()
    isFavorite = false
    for each item in state.favorites
        if item.id = m.hero.id then
            isFavorite = true
            exit for
        end if
    end for
    if isFavorite then
        m.detailsLabel.text = "Na Minha Lista"
    else
        m.detailsLabel.text = "+ Minha Lista"
    end if
end sub

sub toggleHeroFavorite()
    if m.hero = invalid then return
    state = loadLocalState()
    exists = false
    for each item in state.favorites
        if item.id = m.hero.id then
            exists = true
            exit for
        end if
    end for
    if exists then
        state.favorites = removeLocalItem(state.favorites, m.hero.id)
        m.heroMeta.text = m.hero.category + "  •  Removido da Minha Lista"
    else
        state.favorites = upsertLocalItem(state.favorites, m.hero)
        m.heroMeta.text = m.hero.category + "  •  Adicionado à Minha Lista"
    end if
    saveLocalState(state)
    updateActionCopy()
end sub

sub scrollPage(target as Integer)
    if m.pageOffset = target then return
    m.scrollAnimation.control = "stop"
    m.scrollInterpolator.keyValue = [[0.0, m.page.translation[1]], [0.0, target]]
    m.pageOffset = target
    m.scrollAnimation.control = "start"
end sub
