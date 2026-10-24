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
    hero = items[0]
    m.heroTitle.text = hero.title
    m.heroMeta.text = hero.category + "  •  Ao vivo  •  HD"
    m.heroDescription.text = "Conteúdo disponível na sua lista autorizada. Navegue pelas categorias e continue de onde parou."
    if hero.logo <> invalid then m.heroImage.uri = hero.logo
    m.continueGrid.content = buildContent(items, 5)
    m.catalogGrid.content = buildContent(items, 7)
end sub

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
