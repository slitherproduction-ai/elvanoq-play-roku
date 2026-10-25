sub init()
    m.title = m.top.findNode("title")
    m.description = m.top.findNode("description")
    m.countLabel = m.top.findNode("countLabel")
    m.grid = m.top.findNode("grid")
    m.emptyState = m.top.findNode("emptyState")
    m.filterLabel = m.top.findNode("filterLabel")
    m.page = 0
    m.pageSize = 12
    m.selectedGridIndex = 0
    m.grid.observeField("itemSelected", "onItemSelected")
    m.top.findNode("eyebrow").font = "font:SmallSystemFont"
    m.top.findNode("eyebrow").color = "0x73B7FFFF"
    m.title.font = "font:LargeBoldSystemFont"
    m.description.font = "font:MediumSystemFont"
    m.description.color = "0xB9CBE0FF"
    m.filterLabel.font = "font:SmallSystemFont"
    m.filterLabel.color = "0xFFFFFFFF"
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
        if item.type = "series" then isSeries = true
        if item.type = "movies" then isMovie = true
        if (m.top.kind = "series" and isSeries) or (m.top.kind = "movies" and isMovie and not isSeries) then selected.push(item)
    end for
    m.countLabel.text = trim(str(selected.count())) + " títulos disponíveis"
    m.selectedItems = selected
    m.page = 0
    m.selectedGridIndex = 0
    if selected.count() = 0 then
        m.grid.content = CreateObject("roSGNode", "ContentNode")
        m.emptyState.visible = true
        m.emptyState.text = "Nenhum título desta categoria foi encontrado na lista atual."
        return
    end if
    m.emptyState.visible = false
    renderPage()
end sub

sub renderPage()
    if m.selectedItems = invalid or m.selectedItems.count() = 0 then return
    content = CreateObject("roSGNode", "ContentNode")
    firstIndex = m.page * m.pageSize
    lastIndex = firstIndex + m.pageSize - 1
    if lastIndex > m.selectedItems.count() - 1 then lastIndex = m.selectedItems.count() - 1
    for index = firstIndex to lastIndex
        item = m.selectedItems[index]
        child = CreateObject("roSGNode", "ContentNode")
        child.title = item.title
        if item.logo <> invalid then child.hdPosterUrl = item.logo
        content.appendChild(child)
    end for
    m.grid.content = content
    m.grid.jumpToItem = m.selectedGridIndex
    m.grid.setFocus(true)
    totalPages = int((m.selectedItems.count() + m.pageSize - 1) / m.pageSize)
    m.filterLabel.text = "Página " + trim(str(m.page + 1)) + " de " + trim(str(totalPages)) + "  •  * avançar"
end sub

sub onItemSelected()
    index = m.grid.itemSelected
    if m.selectedItems = invalid then return
    absoluteIndex = (m.page * m.pageSize) + index
    if absoluteIndex < 0 or absoluteIndex >= m.selectedItems.count() then return
    m.top.selectedItem = m.selectedItems[absoluteIndex]
end sub

function handleKey(event as Object) as Boolean
    if event.press <> true then return false
    if m.selectedItems = invalid or m.selectedItems.count() = 0 then return false
    pageCount = m.selectedItems.count() - (m.page * m.pageSize)
    if pageCount > m.pageSize then pageCount = m.pageSize
    if event.key = "right" and m.selectedGridIndex < pageCount - 1 then
        m.selectedGridIndex = m.selectedGridIndex + 1
        m.grid.jumpToItem = m.selectedGridIndex
        return true
    end if
    if event.key = "left" and m.selectedGridIndex > 0 then
        m.selectedGridIndex = m.selectedGridIndex - 1
        m.grid.jumpToItem = m.selectedGridIndex
        return true
    end if
    if event.key = "down" and m.selectedGridIndex + 6 < pageCount then
        m.selectedGridIndex = m.selectedGridIndex + 6
        m.grid.jumpToItem = m.selectedGridIndex
        return true
    end if
    if event.key = "up" and m.selectedGridIndex - 6 >= 0 then
        m.selectedGridIndex = m.selectedGridIndex - 6
        m.grid.jumpToItem = m.selectedGridIndex
        return true
    end if
    if event.key = "OK" then
        absoluteIndex = (m.page * m.pageSize) + m.selectedGridIndex
        if absoluteIndex < m.selectedItems.count() then m.top.selectedItem = m.selectedItems[absoluteIndex]
        return true
    end if
    if event.key = "left" or event.key = "right" or event.key = "up" or event.key = "down" then return true
    if event.key <> "options" then return false
    totalPages = int((m.selectedItems.count() + m.pageSize - 1) / m.pageSize)
    if totalPages < 2 then return true
    m.page = m.page + 1
    if m.page >= totalPages then m.page = 0
    m.selectedGridIndex = 0
    renderPage()
    m.grid.setFocus(true)
    return true
end function
