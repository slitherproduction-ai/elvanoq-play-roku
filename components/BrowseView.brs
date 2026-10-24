sub init()
    m.title = m.top.findNode("title")
    m.description = m.top.findNode("description")
    m.countLabel = m.top.findNode("countLabel")
    m.grid = m.top.findNode("grid")
    m.emptyState = m.top.findNode("emptyState")
    m.grid.observeField("itemSelected", "onItemSelected")
    m.top.findNode("eyebrow").font = "font:SmallSystemFont"
    m.top.findNode("eyebrow").color = "0x73B7FFFF"
    m.title.font = "font:LargeBoldSystemFont"
    m.description.font = "font:MediumSystemFont"
    m.description.color = "0xB9CBE0FF"
    m.top.findNode("filterLabel").font = "font:SmallSystemFont"
    m.top.findNode("filterLabel").color = "0xFFFFFFFF"
    m.countLabel.font = "font:SmallSystemFont"
    m.countLabel.color = "0x8FA9C4FF"
    m.emptyState.font = "font:MediumSystemFont"
    m.emptyState.color = "0xB9CBE0FF"
    updateCopy()
end sub

sub updateCopy()
    if m.top.kind = "series" then
        m.title.text = "Séries"
        m.description.text = "Temporadas e episódios organizados para a sua experiência de TV."
    else
        m.title.text = "Filmes"
        m.description.text = "Descubra títulos e continue assistindo com navegação otimizada para Roku."
    end if
end sub

sub setCatalog(payload as Object)
    if payload = invalid or type(payload) <> "roAssociativeArray" then return
    items = payload.items
    selected = []
    for each item in items
        category = lcase(item.category)
        isSeries = instr(1, category, "série") > 0 or instr(1, category, "serie") > 0 or instr(1, category, "series") > 0
        isMovie = instr(1, category, "filme") > 0 or instr(1, category, "movie") > 0 or instr(1, category, "vod") > 0
        if (m.top.kind = "series" and isSeries) or (m.top.kind = "movies" and isMovie and not isSeries) then selected.push(item)
    end for
    m.countLabel.text = trim(str(selected.count())) + " títulos disponíveis"
    m.selectedItems = selected
    if selected.count() = 0 then
        m.grid.content = CreateObject("roSGNode", "ContentNode")
        m.emptyState.visible = true
        m.emptyState.text = "Nenhum título desta categoria foi encontrado na lista atual."
        return
    end if
    m.emptyState.visible = false
    content = CreateObject("roSGNode", "ContentNode")
    lastIndex = selected.count() - 1
    if lastIndex > 11 then lastIndex = 11
    for index = 0 to lastIndex
        item = selected[index]
        child = CreateObject("roSGNode", "ContentNode")
        child.title = item.title
        if item.logo <> invalid then child.hdPosterUrl = item.logo
        content.appendChild(child)
    end for
    m.grid.content = content
end sub

sub onItemSelected()
    index = m.grid.itemSelected
    if m.selectedItems = invalid then return
    if index < 0 or index >= m.selectedItems.count() then return
    m.top.selectedItem = m.selectedItems[index]
end sub
