sub init()
    m.title = m.top.findNode("title")
    m.description = m.top.findNode("description")
    m.countLabel = m.top.findNode("countLabel")
    m.grid = m.top.findNode("grid")
    m.emptyState = m.top.findNode("emptyState")
    m.filterLabel = m.top.findNode("filterLabel")
    m.eyebrow = m.top.findNode("eyebrow")
    m.page = 0
    m.columns = 6
    m.pageSize = 12
    m.visibleCategories = 14
    m.focusArea = "grid"
    m.showFocus = true
    m.fontRegular = appFont(22, "regular")
    m.fontStrong = appFont(22, "semibold")
    m.categoryIndex = 0
    m.categoryOffset = 0
    m.categories = []
    m.allItems = []
    m.selectedItems = []
    m.selectedTitle = m.top.findNode("selectedTitle")
    m.selectedMeta = m.top.findNode("selectedMeta")
    m.selectedTitle.font = appFont(26, "semibold")
    m.selectedTitle.color = "0xF4F8FFFF"
    m.selectedMeta.font = appFont(20, "regular")
    m.selectedMeta.color = "0x8894A8FF"
    m.selectedGridIndex = 0
    m.grid.observeField("itemSelected", "onItemSelected")
    m.eyebrow.font = appFont(18, "bold")
    m.eyebrow.color = "0x00D7FFFF"
    m.title.font = appFont(40, "bold")
    m.title.color = "0xF4F8FFFF"
    m.description.font = appFont(20, "regular")
    m.description.color = "0x8894A8FF"
    m.filterLabel.font = appFont(20, "regular")
    m.filterLabel.color = "0x8894A8FF"
    m.countLabel.font = appFont(20, "regular")
    m.countLabel.color = "0x8894A8FF"
    m.emptyState.font = appFont(24, "regular")
    m.emptyState.color = "0x8894A8FF"
    m.top.findNode("categoriesTitle").font = appFont(18, "bold")
    m.top.findNode("categoriesTitle").color = "0x8894A8FF"
    m.categoryScroll = m.top.findNode("categoryScroll")
    m.categoryScroll.font = appFont(18, "regular")
    m.categoryScroll.color = "0x8894A8FF"
    m.categoryFocus = m.top.findNode("categoryFocus")
    m.categoryMarker = m.top.findNode("categoryMarker")
    m.categoryLabels = []
    m.categoryCounts = []
    for index = 1 to m.visibleCategories
        suffix = index.ToStr()
        if index < 10 then suffix = "0" + suffix
        label = m.top.findNode("category" + suffix)
        label.font = appFont(22, "regular")
        m.categoryLabels.push(label)
        count = m.top.findNode("categoryCount" + suffix)
        count.font = appFont(18, "regular")
        m.categoryCounts.push(count)
    end for
    m.lazy = false
    m.loadingId = ""
    m.requestTimer = CreateObject("roSGNode", "Timer")
    m.requestTimer.duration = 0.35
    m.requestTimer.repeat = false
    m.requestTimer.observeField("fire", "requestCurrentCategory")
    m.top.observeField("kind", "updateCopy")
    updateCopy()
end sub

sub updateCopy()
    if m.top.kind = "series" then
        m.title.text = "Séries"
        m.description.text = "←  Categorias e Busca   •   OK  Temporadas e episódios"
    else
        m.title.text = "Filmes"
        m.description.text = "←  Categorias e Busca   •   OK  Detalhes e assistir"
    end if
end sub

sub setCatalog(payload as Object)
    if payload = invalid or type(payload) <> "roAssociativeArray" then return
    if payload.lazy = true then
        setLazyCatalog(payload.categories)
        return
    end if
    m.lazy = false
    items = payload.items
    if items = invalid then items = []
    previousCategory = ""
    if m.categories.count() > m.categoryIndex then previousCategory = m.categories[m.categoryIndex].name
    selected = []
    ' Categorias na ordem em que chegam da lista (mesma ordem do painel do provedor).
    categoryOrder = []
    categoryCount = {}
    for each item in items
        category = ""
        if item.category <> invalid then category = safeTrim(item.category)
        lowerCategory = lcase(category)
        isSeries = instr(1, lowerCategory, "série") > 0 or instr(1, lowerCategory, "serie") > 0 or instr(1, lowerCategory, "series") > 0
        isMovie = instr(1, lowerCategory, "filme") > 0 or instr(1, lowerCategory, "movie") > 0 or instr(1, lowerCategory, "vod") > 0
        ' Tipo explicito (Xtream) vale mais que o nome da categoria.
        if item.type <> invalid and item.type <> "" then
            isSeries = item.type = "series"
            isMovie = item.type = "movies"
        end if
        if (m.top.kind = "series" and isSeries) or (m.top.kind = "movies" and isMovie and not isSeries) then
            selected.push(item)
            if category = "" then category = "Sem categoria"
            key = lcase(category)
            if categoryCount.DoesExist(key) then
                categoryCount[key] = categoryCount[key] + 1
            else
                categoryCount[key] = 1
                categoryOrder.push(category)
            end if
        end if
    end for
    m.allItems = selected
    m.categories = [searchEntry(), { name: "Todas", key: "", total: selected.count() }]
    for each category in categoryOrder
        m.categories.push({ name: category, key: lcase(category), total: categoryCount[lcase(category)] })
    end for
    m.countLabel.text = selected.count().ToStr() + " títulos   •   " + categoryOrder.count().ToStr() + " categorias"
    ' Mantem a categoria escolhida quando a secao e reaberta.
    m.categoryIndex = 1
    if previousCategory <> "" then
        for index = 0 to m.categories.count() - 1
            if m.categories[index].name = previousCategory then m.categoryIndex = index
        end for
    end if
    m.categoryOffset = 0
    ensureCategoryVisible()
    if selected.count() = 0 then m.focusArea = "grid"
    applyCategory()
end sub

' Lista Xtream: so as categorias chegam aqui; os titulos vem por categoria (setCategoryItems).
sub setLazyCatalog(categories as Object)
    if categories = invalid then categories = []
    signature = categories.count().ToStr()
    if categories.count() > 0 then signature = signature + ":" + categories[0].id + ":" + categories[categories.count() - 1].id
    if m.lazy and m.lazySignature = signature then
        ' Secao reaberta: mantem categoria, pagina e titulos ja carregados.
        renderCategories()
        updateGridFocus()
        return
    end if
    m.lazy = true
    m.lazySignature = signature
    m.categories = [searchEntry()]
    for each category in categories
        m.categories.push({ name: category.name, key: category.id, total: -1 })
    end for
    m.allItems = []
    m.selectedItems = []
    m.categoryIndex = 0
    if m.categories.count() > 1 then m.categoryIndex = 1
    m.categoryOffset = 0
    m.focusArea = "grid"
    m.countLabel.text = (m.categories.count() - 1).ToStr() + " categorias"
    if m.categories.count() = 1 then
        m.eyebrow.text = ""
        m.grid.content = CreateObject("roSGNode", "ContentNode")
        m.emptyState.visible = true
        m.emptyState.text = "Nenhuma categoria encontrada na lista atual."
        renderCategories()
        updateGridFocus()
        return
    end if
    applyCategory()
    requestCurrentCategory()
end sub

sub requestCurrentCategory()
    if not m.lazy or m.categories.count() = 0 then return
    category = m.categories[m.categoryIndex]
    if category.special = true then return
    if m.loadingId = category.key then return
    m.loadingId = category.key
    m.top.categoryRequested = { kind: m.top.kind, id: category.key, name: category.name }
end sub

sub setCategoryItems(payload as Object)
    if not m.lazy or payload = invalid or payload.id = invalid then return
    if m.categories.count() = 0 or payload.id <> m.categories[m.categoryIndex].key then return
    items = payload.items
    if items = invalid then items = []
    category = m.categories[m.categoryIndex]
    if payload.error = invalid then category.total = items.count()
    m.selectedItems = items
    m.page = 0
    m.selectedGridIndex = 0
    renderCategories()
    if items.count() = 0 then
        m.grid.content = CreateObject("roSGNode", "ContentNode")
        m.emptyState.visible = true
        if payload.error <> invalid then
            m.emptyState.text = payload.error
        else
            m.emptyState.text = "Nenhum título nesta categoria."
        end if
        m.filterLabel.text = ""
        m.top.findNode("gridFocus").visible = false
        updateSelectedCopy()
        return
    end if
    m.emptyState.visible = false
    renderPage()
end sub

function searchEntry() as Object
    return { name: "Buscar título ou ator", key: "__search", total: -2, special: true }
end function

' Linha "Buscar" (primeira da lista): mostra os ultimos resultados ou a orientacao.
sub showSearchState()
    m.requestTimer.control = "stop"
    m.loadingId = ""
    m.page = 0
    m.selectedGridIndex = 0
    renderCategories()
    if m.searchQuery = invalid or m.searchQuery = "" then
        m.selectedItems = []
        m.eyebrow.text = "BUSCA"
        m.grid.content = CreateObject("roSGNode", "ContentNode")
        m.top.findNode("gridFocus").visible = false
        m.emptyState.visible = true
        if m.top.kind = "series" then
            m.emptyState.text = "Aperte OK para digitar o nome da série ou de um ator."
        else
            m.emptyState.text = "Aperte OK para digitar o nome do filme ou de um ator."
        end if
        m.filterLabel.text = ""
        updateSelectedCopy()
        return
    end if
    showSearchResults()
end sub

sub showSearchResults()
    m.selectedItems = m.searchResults
    m.page = 0
    m.selectedGridIndex = 0
    label = "RESULTADOS PARA " + chr(34) + ucase(m.searchQuery) + chr(34)
    if m.searchPerson <> invalid and m.searchPerson <> "" then label = label + "   •   COM " + ucase(m.searchPerson)
    m.eyebrow.text = label
    if m.searchLoading = true then
        m.grid.content = CreateObject("roSGNode", "ContentNode")
        m.top.findNode("gridFocus").visible = false
        m.emptyState.visible = true
        m.emptyState.text = "Buscando em todo o catálogo…"
        m.filterLabel.text = ""
        updateSelectedCopy()
        return
    end if
    if m.selectedItems.count() = 0 then
        m.grid.content = CreateObject("roSGNode", "ContentNode")
        m.top.findNode("gridFocus").visible = false
        m.emptyState.visible = true
        if m.searchError <> invalid and m.searchError <> "" then
            m.emptyState.text = m.searchError
        else
            m.emptyState.text = "Nada encontrado para " + chr(34) + m.searchQuery + chr(34) + ". Aperte OK para buscar de novo."
        end if
        m.filterLabel.text = ""
        updateSelectedCopy()
        return
    end if
    m.emptyState.visible = false
    renderPage()
end sub

' AppShell avisa o inicio (loading) e o fim da busca.
sub setSearchResults(payload as Object)
    if payload = invalid or payload.query = invalid then return
    m.searchQuery = payload.query
    m.searchLoading = (payload.loading = true)
    m.searchResults = []
    if payload.items <> invalid then m.searchResults = payload.items
    m.searchError = ""
    if payload.error <> invalid then m.searchError = payload.error
    m.searchPerson = ""
    if payload.person <> invalid then m.searchPerson = payload.person
    m.categoryIndex = 0
    ensureCategoryVisible()
    if not m.searchLoading and m.searchResults.count() > 0 then m.focusArea = "grid"
    renderCategories()
    showSearchResults()
    updateGridFocus()
end sub

sub applyCategory()
    if m.categories.count() > 0 and m.categories[m.categoryIndex].special = true then
        showSearchState()
        return
    end if
    if m.lazy then
        category = m.categories[m.categoryIndex]
        m.selectedItems = []
        m.page = 0
        m.selectedGridIndex = 0
        m.eyebrow.text = ucase(category.name)
        m.grid.content = CreateObject("roSGNode", "ContentNode")
        m.top.findNode("gridFocus").visible = false
        m.emptyState.visible = true
        m.emptyState.text = "Carregando " + category.name + "…"
        m.filterLabel.text = ""
        renderCategories()
        updateSelectedCopy()
        ' Espera o controle parar para pedir (rolar a lista nao dispara um pedido por tecla).
        m.loadingId = ""
        m.requestTimer.control = "stop"
        m.requestTimer.control = "start"
        return
    end if
    category = m.categories[m.categoryIndex]
    if category.key = "" then
        m.selectedItems = m.allItems
    else
        filtered = []
        for each item in m.allItems
            name = ""
            if item.category <> invalid then name = safeTrim(item.category)
            if name = "" then name = "Sem categoria"
            if lcase(name) = category.key then filtered.push(item)
        end for
        m.selectedItems = filtered
    end if
    m.page = 0
    m.selectedGridIndex = 0
    m.eyebrow.text = ucase(category.name)
    renderCategories()
    if m.selectedItems.count() = 0 then
        m.grid.content = CreateObject("roSGNode", "ContentNode")
        m.emptyState.visible = true
        m.emptyState.text = "Nenhum título encontrado na lista atual."
        m.filterLabel.text = ""
        m.top.findNode("gridFocus").visible = false
        updateSelectedCopy()
        return
    end if
    m.emptyState.visible = false
    renderPage()
end sub

sub ensureCategoryVisible()
    if m.categoryIndex < m.categoryOffset then m.categoryOffset = m.categoryIndex
    if m.categoryIndex >= m.categoryOffset + m.visibleCategories then m.categoryOffset = m.categoryIndex - m.visibleCategories + 1
    if m.categoryOffset < 0 then m.categoryOffset = 0
end sub

sub renderCategories()
    focusOnList = (m.focusArea = "categories" and m.showFocus <> false)
    for row = 0 to m.visibleCategories - 1
        index = m.categoryOffset + row
        label = m.categoryLabels[row]
        count = m.categoryCounts[row]
        if index < m.categories.count() then
            category = m.categories[index]
            label.text = category.name
            if category.total < 0 then
                count.text = ""
            else
                count.text = category.total.ToStr()
            end if
            isCurrent = (index = m.categoryIndex)
            if isCurrent and focusOnList then
                label.color = "0xFFFFFFFF"
                count.color = "0xFFFFFFFF"
                label.font = m.fontStrong
            else if isCurrent then
                label.color = "0x00D7FFFF"
                count.color = "0x00D7FFFF"
                label.font = m.fontStrong
            else
                label.color = "0xC9D3E3FF"
                count.color = "0x8894A8FF"
                label.font = m.fontRegular
            end if
            if category.special = true and not isCurrent then label.color = "0x00D7FFFF"
        else
            label.text = ""
            count.text = ""
        end if
    end for
    visibleRow = m.categoryIndex - m.categoryOffset
    y = 236 + visibleRow * 52
    m.categoryFocus.translation = [76, y]
    m.categoryMarker.translation = [76, y]
    m.categoryFocus.visible = focusOnList
    m.categoryMarker.visible = not focusOnList and m.categories.count() > 0
    if m.categories.count() > m.visibleCategories then
        m.categoryScroll.text = (m.categoryIndex + 1).ToStr() + " de " + m.categories.count().ToStr()
    else
        m.categoryScroll.text = ""
    end if
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
    updateGridFocus()
    totalPages = int((m.selectedItems.count() + m.pageSize - 1) / m.pageSize)
    m.filterLabel.text = m.selectedItems.count().ToStr() + " títulos   •   Página " + (m.page + 1).ToStr() + " de " + totalPages.ToStr()
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
    if m.focusArea = "categories" then return handleCategoryKey(event.key)
    if m.selectedItems = invalid or m.selectedItems.count() = 0 then
        if event.key = "left" and m.categories.count() > 0 then
            setFocusArea("categories")
            return true
        end if
        return false
    end if
    pageCount = m.selectedItems.count() - (m.page * m.pageSize)
    if pageCount > m.pageSize then pageCount = m.pageSize
    if event.key = "right" and m.selectedGridIndex < pageCount - 1 and (m.selectedGridIndex mod m.columns) < m.columns - 1 then
        m.selectedGridIndex = m.selectedGridIndex + 1
        m.grid.jumpToItem = m.selectedGridIndex
        updateGridFocus()
        return true
    end if
    if event.key = "left" and (m.selectedGridIndex mod m.columns) > 0 then
        m.selectedGridIndex = m.selectedGridIndex - 1
        m.grid.jumpToItem = m.selectedGridIndex
        updateGridFocus()
        return true
    end if
    ' Esquerda na primeira coluna abre a lista de categorias.
    if event.key = "left" then
        setFocusArea("categories")
        return true
    end if
    if event.key = "down" and m.selectedGridIndex + m.columns < pageCount then
        m.selectedGridIndex = m.selectedGridIndex + m.columns
        m.grid.jumpToItem = m.selectedGridIndex
        updateGridFocus()
        return true
    end if
    if event.key = "up" and m.selectedGridIndex - m.columns >= 0 then
        m.selectedGridIndex = m.selectedGridIndex - m.columns
        m.grid.jumpToItem = m.selectedGridIndex
        updateGridFocus()
        return true
    end if
    if event.key = "OK" then
        absoluteIndex = (m.page * m.pageSize) + m.selectedGridIndex
        if absoluteIndex < m.selectedItems.count() then m.top.selectedItem = m.selectedItems[absoluteIndex]
        return true
    end if
    ' Paginacao automatica: Baixo na ultima fileira avanca, Cima na primeira volta.
    totalPages = int((m.selectedItems.count() + m.pageSize - 1) / m.pageSize)
    if event.key = "down" and m.page < totalPages - 1 then
        column = m.selectedGridIndex mod m.columns
        m.page = m.page + 1
        m.selectedGridIndex = column
        nextCount = m.selectedItems.count() - (m.page * m.pageSize)
        if m.selectedGridIndex > nextCount - 1 then m.selectedGridIndex = nextCount - 1
        renderPage()
        return true
    end if
    if event.key = "up" and m.page > 0 then
        column = m.selectedGridIndex mod m.columns
        m.page = m.page - 1
        m.selectedGridIndex = m.columns + column
        renderPage()
        return true
    end if
    if event.key = "up" then return false
    if event.key = "right" or event.key = "down" then return true
    if event.key <> "options" then return false
    if totalPages < 2 then return true
    m.page = m.page + 1
    if m.page >= totalPages then m.page = 0
    m.selectedGridIndex = 0
    renderPage()
    updateGridFocus()
    return true
end function

' Cima/Baixo troca a categoria (a grade atualiza na hora); Direita ou OK volta para os titulos.
function handleCategoryKey(key as String) as Boolean
    total = m.categories.count()
    if total = 0 then return false
    if key = "down" or key = "up" or key = "fastforward" or key = "rewind" then
        nextIndex = m.categoryIndex
        if key = "down" then nextIndex = nextIndex + 1
        if key = "up" then nextIndex = nextIndex - 1
        if key = "fastforward" then nextIndex = nextIndex + m.visibleCategories
        if key = "rewind" then nextIndex = nextIndex - m.visibleCategories
        if nextIndex < 0 then nextIndex = 0
        if nextIndex > total - 1 then nextIndex = total - 1
        if nextIndex = m.categoryIndex then return true
        m.categoryIndex = nextIndex
        ensureCategoryVisible()
        applyCategory()
        return true
    end if
    if key = "right" or key = "OK" then
        if m.categories[m.categoryIndex].special = true and (key = "OK" or m.selectedItems.count() = 0) then
            m.top.searchRequested = { kind: m.top.kind }
            return true
        end if
        if m.selectedItems.count() > 0 then setFocusArea("grid")
        return true
    end if
    ' Esquerda na lista de categorias fica parada; Voltar segue para o AppShell (Inicio).
    if key = "left" then return true
    return false
end function

sub setFocusArea(area as String)
    m.focusArea = area
    renderCategories()
    updateGridFocus()
end sub

sub updateGridFocus()
    if m.showFocus = false or m.top.visible <> true or m.focusArea <> "grid" then
        m.top.findNode("gridFocus").visible = false
        updateSelectedCopy()
        return
    end if
    placeFocusFrame(m.top.findNode("gridFocus"), m.grid, m.selectedGridIndex, m.columns, 200, 300, 28, 36)
    updateSelectedCopy()
end sub

sub setFocusVisible(visible as Boolean)
    m.showFocus = visible
    renderCategories()
    updateGridFocus()
end sub

sub updateSelectedCopy()
    if m.focusArea = "categories" and m.categories.count() > m.categoryIndex then
        category = m.categories[m.categoryIndex]
        if category.special = true then
            m.selectedTitle.text = "Buscar"
            m.selectedMeta.text = "OK  digitar o nome do título ou de um ator"
            return
        end if
        m.selectedTitle.text = category.name
        if category.total < 0 then
            m.selectedMeta.text = "Carregando títulos…"
        else
            m.selectedMeta.text = category.total.ToStr() + " títulos   •   →  ou  OK para ver os títulos"
        end if
        return
    end if
    if m.selectedItems = invalid or m.selectedItems.count() = 0 then
        m.selectedTitle.text = ""
        m.selectedMeta.text = ""
        return
    end if
    index = (m.page * m.pageSize) + m.selectedGridIndex
    if index < 0 or index >= m.selectedItems.count() then return
    item = m.selectedItems[index]
    m.selectedTitle.text = item.title
    meta = ""
    if item.category <> invalid then meta = item.category
    if item.rating <> invalid and safeTrim(item.rating) <> "" and val(safeTrim(item.rating)) > 0 then meta = meta + "   •   Nota " + safeTrim(item.rating)
    m.selectedMeta.text = meta
end sub
