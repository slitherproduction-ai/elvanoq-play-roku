sub init()
    m.queryLabel = m.top.findNode("queryLabel")
    m.resultsGrid = m.top.findNode("resultsGrid")
    m.emptyState = m.top.findNode("emptyState")
    m.resultsTitle = m.top.findNode("resultsTitle")
    m.filterFocus = m.top.findNode("filterFocus")
    m.items = []
    m.query = ""
    m.lazy = false
    m.matches = []
    m.selectedIndex = 0
    m.resultOffset = 0
    m.selectedFilter = 0
    m.filterLabels = [m.top.findNode("allLabel"), m.top.findNode("moviesLabel"), m.top.findNode("seriesLabel"), m.top.findNode("channelsLabel")]
    m.resultsGrid.observeField("itemSelected", "onItemSelected")
    m.top.findNode("title").font = appFont(40, "bold")
    m.top.findNode("title").color = "0xF4F8FFFF"
    m.queryLabel.font = appFont(26, "medium")
    m.queryLabel.color = "0xF4F8FFFF"
    m.top.findNode("queryHint").font = appFont(20, "regular")
    m.top.findNode("queryHint").color = "0x8894A8FF"
    m.top.findNode("allLabel").font = appFont(20, "regular")
    m.top.findNode("allLabel").color = "0xFFFFFFFF"
    m.top.findNode("moviesLabel").font = appFont(20, "regular")
    m.top.findNode("seriesLabel").font = appFont(20, "regular")
    m.top.findNode("channelsLabel").font = appFont(20, "regular")
    m.resultsTitle.font = appFont(26, "semibold")
    m.resultsTitle.color = "0xF4F8FFFF"
    m.columns = 8
    m.windowSize = 16
    m.emptyState.font = appFont(24, "regular")
    m.emptyState.color = "0x8894A8FF"
    m.emptyState.text = "Use o teclado do Roku para pesquisar no catálogo da sua lista."
    updateFilterFocus()
end sub

sub setCatalog(payload as Object)
    if payload = invalid or type(payload) <> "roAssociativeArray" then return
    if payload.lazy = true then
        ' Lista Xtream: a busca roda no servidor (todo o catalogo), nao so no que esta carregado.
        if m.lazy <> true then
            m.items = []
            m.resultsQuery = invalid
        end if
        m.lazy = true
        return
    end if
    m.lazy = false
    m.items = payload.items
end sub

sub setResults(payload as Object)
    if payload = invalid or payload.query = invalid or m.query = invalid then return
    if payload.query <> m.query then return
    m.items = []
    if payload.items <> invalid then m.items = payload.items
    m.resultsQuery = payload.query
    m.searchError = ""
    if payload.error <> invalid then m.searchError = payload.error
    m.selectedIndex = 0
    m.resultOffset = 0
    renderQuery()
end sub

sub setQuery(query as String)
    m.query = query
    m.selectedIndex = 0
    m.resultOffset = 0
    m.matches = []
    renderQuery()
end sub

sub renderQuery()
    query = m.query
    m.matches = []
    if query = "" then
        m.queryLabel.text = "Buscar filmes, séries e canais"
        m.resultsGrid.content = CreateObject("roSGNode", "ContentNode")
        m.resultsTitle.text = "Resultados"
        m.emptyState.visible = true
        m.emptyState.text = "Use o teclado do Roku para pesquisar no catálogo da sua lista."
        return
    end if
    m.queryLabel.text = query
    if m.lazy = true and (m.resultsQuery = invalid or m.resultsQuery <> query) then
        m.resultsGrid.content = CreateObject("roSGNode", "ContentNode")
        m.top.findNode("resultsFocus").visible = false
        m.resultsTitle.text = "Resultados"
        m.emptyState.visible = true
        m.emptyState.text = "Buscando em todo o catálogo… a primeira busca pode levar alguns segundos."
        m.top.searchRequested = { query: query }
        return
    end if
    needle = lcase(query)
    matches = 0
    for each item in m.items
        if matchesFilter(item) and (m.lazy = true or instr(1, lcase(item.title), needle) > 0 or instr(1, lcase(item.category), needle) > 0) then
            m.matches.push(item)
            matches = matches + 1
            if matches = 300 then exit for
        end if
    end for
    m.emptyState.visible = matches = 0
    m.resultsTitle.text = "Resultados — " + safeTrim(str(matches)) + " encontrados"
    if matches = 0 then m.emptyState.text = "Nenhum " + filterName() + " encontrado na lista atual."
    if matches = 0 and m.lazy = true and m.searchError <> invalid and m.searchError <> "" then m.emptyState.text = m.searchError
    if matches = 0 then
        m.resultsGrid.content = CreateObject("roSGNode", "ContentNode")
        m.top.findNode("resultsFocus").visible = false
    end if
    if matches > 0 then renderResultsWindow()
end sub

sub renderResultsWindow()
    content = CreateObject("roSGNode", "ContentNode")
    lastIndex = m.resultOffset + m.windowSize - 1
    if lastIndex > m.matches.count() - 1 then lastIndex = m.matches.count() - 1
    for index = m.resultOffset to lastIndex
        item = m.matches[index]
        child = CreateObject("roSGNode", "ContentNode")
        child.title = item.title
        if item.logo <> invalid then child.hdPosterUrl = item.logo
        content.appendChild(child)
    end for
    m.resultsGrid.content = content
    m.resultsGrid.jumpToItem = m.selectedIndex - m.resultOffset
    updateResultsFocus()
end sub

sub onItemSelected()
    index = m.resultsGrid.itemSelected
    absoluteIndex = m.resultOffset + index
    if absoluteIndex < 0 or absoluteIndex >= m.matches.count() then return
    m.top.selectedItem = m.matches[absoluteIndex]
end sub

function handleKey(event as Object) as Boolean
    if event.press <> true then return false
    if event.key = "back" and m.query <> "" then
        m.query = ""
        m.selectedIndex = 0
        m.resultOffset = 0
        renderQuery()
        return true
    end if
    if event.key = "options" then
        m.selectedFilter = m.selectedFilter + 1
        if m.selectedFilter > 3 then m.selectedFilter = 0
        m.selectedIndex = 0
        m.resultOffset = 0
        updateFilterFocus()
        renderQuery()
        return true
    end if
    if m.matches.count() = 0 then return false
    if event.key = "right" and m.selectedIndex < m.matches.count() - 1 then
        m.selectedIndex = m.selectedIndex + 1
        updateResultViewport()
        return true
    end if
    if event.key = "left" and (m.selectedIndex mod m.columns) = 0 then return false
    if event.key = "left" and m.selectedIndex > 0 then
        m.selectedIndex = m.selectedIndex - 1
        updateResultViewport()
        return true
    end if
    if event.key = "down" and m.selectedIndex + m.columns < m.matches.count() then
        m.selectedIndex = m.selectedIndex + m.columns
        updateResultViewport()
        return true
    end if
    if event.key = "up" and m.selectedIndex - m.columns >= 0 then
        m.selectedIndex = m.selectedIndex - m.columns
        updateResultViewport()
        return true
    end if
    if event.key = "OK" then
        m.top.selectedItem = m.matches[m.selectedIndex]
        return true
    end if
    return false
end function

sub updateSelection()
    m.resultsGrid.jumpToItem = m.selectedIndex - m.resultOffset
    updateResultsFocus()
end sub

sub updateResultsFocus()
    frame = m.top.findNode("resultsFocus")
    if m.showFocus = false or m.top.visible <> true or m.matches = invalid or m.matches.count() = 0 then
        frame.visible = false
        return
    end if
    placeFocusFrame(frame, m.resultsGrid, m.selectedIndex - m.resultOffset, m.columns, 200, 300, 28, 36)
end sub

sub setFocusVisible(visible as Boolean)
    m.showFocus = visible
    updateResultsFocus()
end sub

sub updateResultViewport()
    ' A janela anda de fileira em fileira para nao desalinhar a grade.
    row = int(m.selectedIndex / m.columns)
    if m.selectedIndex < m.resultOffset then
        m.resultOffset = row * m.columns
        renderResultsWindow()
    else if m.selectedIndex >= m.resultOffset + m.windowSize then
        m.resultOffset = (row - 1) * m.columns
        renderResultsWindow()
    else
        updateSelection()
    end if
end sub

function matchesFilter(item as Object) as Boolean
    if m.selectedFilter = 0 then return true
    itemType = catalogItemType(item)
    if m.selectedFilter = 1 then return itemType = "movies"
    if m.selectedFilter = 2 then return itemType = "series"
    return itemType = "live"
end function

function catalogItemType(item as Object) as String
    if item.type <> invalid and item.type <> "" then return item.type
    category = ""
    if item.category <> invalid then category = lcase(item.category)
    isSeries = instr(1, category, "série") > 0 or instr(1, category, "serie") > 0 or instr(1, category, "series") > 0
    isMovie = instr(1, category, "filme") > 0 or instr(1, category, "movie") > 0 or instr(1, category, "vod") > 0
    if isSeries then return "series"
    if isMovie then return "movies"
    return "live"
end function

function filterName() as String
    names = ["resultado", "filme", "série", "canal"]
    return names[m.selectedFilter]
end function

sub updateFilterFocus()
    positions = [64, 204, 344, 484]
    m.filterFocus.translation = [positions[m.selectedFilter], 236]
    m.filterFocus.width = 124
    for index = 0 to m.filterLabels.count() - 1
        if index = m.selectedFilter then
            m.filterLabels[index].color = "0xF4F8FFFF"
        else
            m.filterLabels[index].color = "0x8894A8FF"
        end if
    end for
end sub
