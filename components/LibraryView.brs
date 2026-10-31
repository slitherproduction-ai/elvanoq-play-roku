sub init()
    m.title = m.top.findNode("title")
    m.tabs = m.top.findNode("tabs")
    m.tabFocus = m.top.findNode("tabFocus")
    m.itemFocus = m.top.findNode("itemFocus")
    m.items = m.top.findNode("items")
    m.rows = 12
    m.title.font = appFont(40, "bold")
    m.title.color = "0xF4F8FFFF"
    m.items.font = appFont(24, "regular")
    m.items.color = "0x8894A8FF"
    m.top.findNode("hint").font = appFont(20, "regular")
    m.top.findNode("hint").color = "0x8894A8FF"
    m.tabLabels = []
    for index = 0 to 3
        label = m.top.findNode("tab" + safeTrim(str(index)))
        label.font = appFont(22, "semibold")
        m.tabLabels.push(label)
    end for
    m.rowTitles = []
    m.rowMetas = []
    for index = 1 to m.rows
        suffix = safeTrim(str(index))
        if len(suffix) < 2 then suffix = "0" + suffix
        titleLabel = m.top.findNode("rowTitle" + suffix)
        metaLabel = m.top.findNode("rowMeta" + suffix)
        titleLabel.font = appFont(24, "medium")
        titleLabel.color = "0xF4F8FFFF"
        metaLabel.font = appFont(20, "regular")
        metaLabel.color = "0x8894A8FF"
        m.rowTitles.push(titleLabel)
        m.rowMetas.push(metaLabel)
    end for
    m.selectedTab = 0
    m.selectedItemIndex = 0
    m.collectionOffset = 0
    m.collection = []
    refresh()
end sub

function handleKey(event as Object) as Boolean
    if event.press <> true then return false
    if event.key = "right" and m.selectedTab < 3 then
        m.selectedTab = m.selectedTab + 1
        m.selectedItemIndex = 0
        m.collectionOffset = 0
        refresh()
        return true
    end if
    if event.key = "left" and m.selectedTab > 0 then
        m.selectedTab = m.selectedTab - 1
        m.selectedItemIndex = 0
        m.collectionOffset = 0
        refresh()
        return true
    end if
    if event.key = "down" and m.collection.count() > 0 and m.selectedItemIndex < m.collection.count() - 1 then
        m.selectedItemIndex = m.selectedItemIndex + 1
        updateViewport()
        return true
    end if
    if event.key = "up" and m.collection.count() > 0 and m.selectedItemIndex > 0 then
        m.selectedItemIndex = m.selectedItemIndex - 1
        updateViewport()
        return true
    end if
    if event.key = "OK" and m.collection.count() > 0 then
        m.top.itemRequested = m.collection[m.selectedItemIndex]
        return true
    end if
    return false
end function

sub refresh()
    state = loadLocalState()
    collections = [state.watch_later, state.favorites, state.continue_watching, state.history]
    m.tabFocus.translation = [64 + (m.selectedTab * 216), 146]
    for index = 0 to 3
        if index = m.selectedTab then
            m.tabLabels[index].color = "0xF4F8FFFF"
        else
            m.tabLabels[index].color = "0x8894A8FF"
        end if
    end for
    collection = collections[m.selectedTab]
    if collection = invalid then collection = []
    m.collection = collection
    for index = 0 to m.rows - 1
        m.rowTitles[index].text = ""
        m.rowMetas[index].text = ""
    end for
    if collection.count() = 0 then
        m.items.text = "Nenhum item salvo nesta coleção ainda."
        m.items.visible = true
        m.itemFocus.visible = false
        return
    end if
    m.items.visible = false
    if m.selectedItemIndex > collection.count() - 1 then m.selectedItemIndex = collection.count() - 1
    for row = 0 to m.rows - 1
        index = m.collectionOffset + row
        if index < collection.count() then
            item = collection[index]
            title = ""
            if item.title <> invalid then title = item.title
            m.rowTitles[row].text = title
            meta = ""
            if item.category <> invalid then meta = item.category
            if item.progress_seconds <> invalid and item.duration_seconds <> invalid and item.duration_seconds > 0 then
                percent = safeTrim(str(int((item.progress_seconds / item.duration_seconds) * 100))) + "% assistido"
                if meta <> "" then meta = meta + "   •   "
                meta = meta + percent
            end if
            m.rowMetas[row].text = meta
        end if
    end for
    updateItemFocus()
end sub

sub updateItemFocus()
    if m.collection = invalid or m.collection.count() = 0 then
        m.itemFocus.visible = false
        return
    end if
    visibleIndex = m.selectedItemIndex - m.collectionOffset
    if visibleIndex > m.rows - 1 then visibleIndex = m.rows - 1
    m.itemFocus.visible = true
    for row = 0 to m.rows - 1
        if row = visibleIndex then
            m.rowMetas[row].color = "0xD6DEEBFF"
        else
            m.rowMetas[row].color = "0x8894A8FF"
        end if
    end for
    m.itemFocus.translation = [76, 256 + (visibleIndex * 62)]
end sub

sub updateViewport()
    if m.selectedItemIndex < m.collectionOffset then
        m.collectionOffset = m.selectedItemIndex
        refresh()
    else if m.selectedItemIndex >= m.collectionOffset + m.rows then
        m.collectionOffset = m.selectedItemIndex - (m.rows - 1)
        refresh()
    else
        updateItemFocus()
    end if
end sub
