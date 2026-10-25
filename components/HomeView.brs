sub init()
    m.heroImage = m.top.findNode("heroImage")
    m.eyebrow = m.top.findNode("eyebrow")
    m.heroTitle = m.top.findNode("heroTitle")
    m.heroMeta = m.top.findNode("heroMeta")
    m.heroDescription = m.top.findNode("heroDescription")
    m.watchLabel = m.top.findNode("watchLabel")
    m.detailsLabel = m.top.findNode("detailsLabel")
    m.actionFocus = m.top.findNode("actionFocus")
    m.heroTimer = m.top.findNode("heroTimer")
    m.continueTitle = m.top.findNode("continueTitle")
    m.continueHint = m.top.findNode("continueHint")
    m.catalogTitle = m.top.findNode("catalogTitle")
    m.continueGrid = m.top.findNode("continueGrid")
    m.catalogGrid = m.top.findNode("catalogGrid")
    m.emptyState = m.top.findNode("emptyState")
    m.eyebrow.font = "font:SmallSystemFont"
    m.eyebrow.color = "0x73B7FFFF"
    m.heroTitle.font = "font:LargeBoldSystemFont"
    m.heroMeta.font = "font:SmallSystemFont"
    m.heroMeta.color = "0x9AB2CCFF"
    m.heroDescription.font = "font:MediumSystemFont"
    m.heroDescription.color = "0xD7E3F0FF"
    m.watchLabel.font = "font:MediumBoldSystemFont"
    m.watchLabel.color = "0x06111FFF"
    m.detailsLabel.font = "font:MediumSystemFont"
    m.detailsLabel.color = "0xFFFFFFFF"
    m.continueTitle.font = "font:MediumBoldSystemFont"
    m.catalogTitle.font = "font:MediumBoldSystemFont"
    m.continueHint.font = "font:SmallSystemFont"
    m.continueHint.color = "0x8FA9C4FF"
    m.emptyState.font = "font:MediumSystemFont"
    m.emptyState.color = "0xB9CBE0FF"
    m.selectedAction = 0
    m.heroCandidates = []
    m.heroIndex = 0
    m.isActive = true
    m.heroTimer.observeField("fire", "onHeroTimerFired")
    updateActionFocus()
end sub

sub setCatalog(payload as Object)
    if payload = invalid or type(payload) <> "roAssociativeArray" then return
    items = payload.items
    if items = invalid or items.count() = 0 then
        m.heroTimer.control = "stop"
        m.heroCandidates = []
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
        m.continueGrid.content = buildContent(continueItems, 5)
    else if favoriteItems.count() > 0 then
        m.continueTitle.text = "Seus favoritos"
        m.continueHint.text = "Canais e títulos salvos neste Roku"
        m.continueGrid.content = buildContent(favoriteItems, 5)
    else
        m.continueTitle.text = "Para você"
        m.continueHint.text = "Conteúdos da sua lista autorizada"
        m.continueGrid.content = buildContent(items, 5)
    end if
    m.catalogTitle.text = "Canais em destaque"
    m.catalogGrid.content = buildContent(items, 7)
    if m.isActive and m.heroCandidates.count() > 1 then m.heroTimer.control = "start"
end sub

function uniqueHeroCandidates(continueItems as Object, favoriteItems as Object, catalogItems as Object) as Object
    candidates = []
    recent = newestItem(catalogItems)
    weekly = featuredItem(catalogItems)
    topRated = highestRatedItem(catalogItems)

    appendSingleHeroCandidate(candidates, recent, "RECÉM-ADICIONADO")
    appendSingleHeroCandidate(candidates, weekly, "DESTAQUE DA SEMANA")
    appendSingleHeroCandidate(candidates, topRated, "MAIS BEM AVALIADO")

    ' Fallbacks mantêm a Home útil quando a fonte não fornece curadoria.
    appendHeroCandidate(candidates, continueItems, "CONTINUE ASSISTINDO")
    appendHeroCandidate(candidates, favoriteItems, "SEUS FAVORITOS")
    appendHeroCandidate(candidates, catalogItems, "DESTAQUE ELVANOQ")
    while candidates.count() > 3
        candidates.pop()
    end while
    return candidates
end function

function newestItem(items as Object) as Object
    best = invalid
    bestValue = ""
    for each item in items
        if item.added_at <> invalid and item.added_at <> "" and item.added_at > bestValue then
            best = item
            bestValue = item.added_at
        end if
    end for
    return best
end function

function featuredItem(items as Object) as Object
    for each item in items
        if item.featured <> invalid then
            value = lcase(item.featured)
            if value = "true" or value = "1" or value = "yes" then return item
        end if
    end for
    return invalid
end function

function highestRatedItem(items as Object) as Object
    best = invalid
    bestValue = -1
    for each item in items
        if item.rating <> invalid and item.rating <> "" then
            value = val(item.rating)
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
    candidate = source[0]
    for each existing in target
        if existing.item.id = candidate.id then return
    end for
    target.push({ item: candidate, eyebrow: eyebrow })
end sub

sub renderHero(candidate as Object)
    if candidate = invalid or candidate.item = invalid then return
    hero = candidate.item
    m.hero = hero
    m.eyebrow.text = candidate.eyebrow
    m.heroTitle.text = hero.title
    m.heroMeta.text = hero.category + "  •  Disponível na sua lista"
    m.heroDescription.text = "Conteúdo disponível na sua lista autorizada. Retome, favorite e navegue de forma segura no ELVANOQ Play."
    if hero.logo <> invalid and hero.logo <> "" then m.heroImage.uri = hero.logo
    updateActionCopy()
end sub

sub onHeroTimerFired()
    if not m.isActive or m.heroCandidates.count() < 2 then return
    m.heroIndex = m.heroIndex + 1
    if m.heroIndex >= m.heroCandidates.count() then m.heroIndex = 0
    renderHero(m.heroCandidates[m.heroIndex])
end sub

sub setActive(active as Boolean)
    m.isActive = active
    if active and m.heroCandidates.count() > 1 then
        m.heroTimer.control = "start"
    else
        m.heroTimer.control = "stop"
    end if
end sub

function handleKey(event as Object) as Boolean
    if event.press <> true or m.hero = invalid then return false
    if event.key = "right" and m.selectedAction = 0 then
        m.selectedAction = 1
        updateActionFocus()
        return true
    end if
    if event.key = "left" and m.selectedAction = 1 then
        m.selectedAction = 0
        updateActionFocus()
        return true
    end if
    if event.key = "OK" then
        if m.selectedAction = 0 then
            m.top.playRequested = m.hero
        else
            toggleHeroFavorite()
        end if
        return true
    end if
    return false
end function

sub updateActionFocus()
    if m.selectedAction = 0 then
        m.actionFocus.translation = [384, 398]
        m.actionFocus.width = 202
    else
        m.actionFocus.translation = [590, 398]
        m.actionFocus.width = 212
    end if
end sub

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
        m.detailsLabel.text = "✓  Na Minha Lista"
    else
        m.detailsLabel.text = "+  Minha Lista"
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

function buildContent(items as Object, maximum as Integer) as Object
    content = CreateObject("roSGNode", "ContentNode")
    lastIndex = items.count() - 1
    if lastIndex > maximum - 1 then lastIndex = maximum - 1
    for index = 0 to lastIndex
        item = items[index]
        child = CreateObject("roSGNode", "ContentNode")
        child.title = item.title
        if item.logo <> invalid then child.hdPosterUrl = item.logo
        content.appendChild(child)
    end for
    return content
end function
