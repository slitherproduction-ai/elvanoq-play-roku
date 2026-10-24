sub init()
    m.queryLabel = m.top.findNode("queryLabel")
    m.resultsGrid = m.top.findNode("resultsGrid")
    m.emptyState = m.top.findNode("emptyState")
    m.items = []
    m.matches = []
    m.selectedIndex = 0
    m.resultsGrid.observeField("itemSelected", "onItemSelected")
    m.top.findNode("title").font = "font:LargeBoldSystemFont"
    m.queryLabel.font = "font:MediumSystemFont"
    m.queryLabel.color = "0xB9CBE0FF"
    m.top.findNode("allLabel").font = "font:SmallSystemFont"
    m.top.findNode("allLabel").color = "0xFFFFFFFF"
    m.top.findNode("moviesLabel").font = "font:SmallSystemFont"
    m.top.findNode("seriesLabel").font = "font:SmallSystemFont"
    m.top.findNode("channelsLabel").font = "font:SmallSystemFont"
    m.top.findNode("resultsTitle").font = "font:MediumBoldSystemFont"
    m.emptyState.font = "font:MediumSystemFont"
    m.emptyState.color = "0x8FA9C4FF"
    m.emptyState.text = "Use o teclado do Roku para pesquisar no catálogo da sua lista."
end sub

sub setCatalog(payload as Object)
    if payload = invalid or type(payload) <> "roAssociativeArray" then return
    m.items = payload.items
end sub

sub setQuery(query as String)
    m.query = query
    m.selectedIndex = 0
    m.matches = []
    if query = "" then
        m.queryLabel.text = "Buscar filmes, séries, canais e episódios…"
        m.resultsGrid.content = CreateObject("roSGNode", "ContentNode")
        m.emptyState.visible = true
        return
    end if
    m.queryLabel.text = query
    needle = lcase(query)
    content = CreateObject("roSGNode", "ContentNode")
    matches = 0
    for each item in m.items
        if instr(1, lcase(item.title), needle) > 0 or instr(1, lcase(item.category), needle) > 0 then
            child = CreateObject("roSGNode", "ContentNode")
            child.title = item.title
            if item.logo <> invalid then child.hdPosterUrl = item.logo
            content.appendChild(child)
            m.matches.push(item)
            matches = matches + 1
            if matches = 12 then exit for
        end if
    end for
    m.resultsGrid.content = content
    m.emptyState.visible = matches = 0
    if matches = 0 then m.emptyState.text = "Nenhum resultado encontrado na lista atual."
    if matches > 0 then m.resultsGrid.setFocus(true)
end sub

sub onItemSelected()
    index = m.resultsGrid.itemSelected
    if index < 0 or index >= m.matches.count() then return
    m.top.selectedItem = m.matches[index]
end sub

function handleKey(event as Object) as Boolean
    if event.press <> true then return false
    if m.matches.count() = 0 then return false
    if event.key = "right" and m.selectedIndex < m.matches.count() - 1 then
        m.selectedIndex = m.selectedIndex + 1
        updateSelection()
        return true
    end if
    if event.key = "left" and m.selectedIndex > 0 then
        m.selectedIndex = m.selectedIndex - 1
        updateSelection()
        return true
    end if
    if event.key = "down" and m.selectedIndex + 6 < m.matches.count() then
        m.selectedIndex = m.selectedIndex + 6
        updateSelection()
        return true
    end if
    if event.key = "up" and m.selectedIndex - 6 >= 0 then
        m.selectedIndex = m.selectedIndex - 6
        updateSelection()
        return true
    end if
    if event.key = "OK" then
        m.top.selectedItem = m.matches[m.selectedIndex]
        return true
    end if
    return false
end function

sub updateSelection()
    m.resultsGrid.jumpToItem = m.selectedIndex
end sub
