sub init()
    m.heroImage = m.top.findNode("heroImage")
    m.eyebrow = m.top.findNode("eyebrow")
    m.heroTitle = m.top.findNode("heroTitle")
    m.heroMeta = m.top.findNode("heroMeta")
    m.heroDescription = m.top.findNode("heroDescription")
    m.watchLabel = m.top.findNode("watchLabel")
    m.detailsLabel = m.top.findNode("detailsLabel")
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
end sub

sub setCatalog(payload as Object)
    if payload = invalid or type(payload) <> "roAssociativeArray" then return
    items = payload.items
    if items = invalid or items.count() = 0 then
        m.emptyState.visible = true
        m.emptyState.text = "Sua lista será exibida aqui assim que a sincronização for concluída."
        return
    end if
    m.emptyState.visible = false
    state = loadLocalState()
    continueItems = resolveLocalItems(state.continue_watching, items)
    favoriteItems = resolveLocalItems(state.favorites, items)
    hero = items[0]
    if continueItems.count() > 0 then
        hero = continueItems[0]
        m.eyebrow.text = "CONTINUE ASSISTINDO"
    else if favoriteItems.count() > 0 then
        hero = favoriteItems[0]
        m.eyebrow.text = "SEUS FAVORITOS"
    else
        m.eyebrow.text = "DESTAQUE ELVANOQ"
    end if
    m.heroTitle.text = hero.title
    m.heroMeta.text = hero.category + "  •  Disponível na sua lista"
    m.heroDescription.text = "Conteúdo disponível na sua lista autorizada. Retome, favorite e navegue de forma segura no ELVANOQ Play."
    if hero.logo <> invalid then m.heroImage.uri = hero.logo
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
