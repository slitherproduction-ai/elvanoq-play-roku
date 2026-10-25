sub init()
    m.title = m.top.findNode("title")
    m.tabs = m.top.findNode("tabs")
    m.tabFocus = m.top.findNode("tabFocus")
    m.itemFocus = m.top.findNode("itemFocus")
    m.items = m.top.findNode("items")
    m.title.font = "font:LargeBoldSystemFont"
    m.tabs.font = "font:MediumBoldSystemFont"
    m.tabs.color = "0xB9CBE0FF"
    m.items.font = "font:MediumSystemFont"
    m.items.color = "0xD7E3F0FF"
    m.top.findNode("hint").font = "font:SmallSystemFont"
    m.top.findNode("hint").color = "0x8FA9C4FF"
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
    labels = ["Minha Lista", "Favoritos", "Continuar", "Histórico"]
    collections = [state.watch_later, state.favorites, state.continue_watching, state.history]
    m.tabs.text = "Minha Lista     Favoritos     Continuar     Histórico"
    m.title.text = labels[m.selectedTab]
    m.tabFocus.translation = [390 + (m.selectedTab * 235), 246]
    collection = collections[m.selectedTab]
    m.collection = collection
    if collection = invalid or collection.count() = 0 then
        m.items.text = "Nenhum item salvo nesta coleção ainda."
        m.itemFocus.visible = false
        return
    end if
    if m.selectedItemIndex > collection.count() - 1 then m.selectedItemIndex = collection.count() - 1
    output = ""
    firstIndex = m.collectionOffset
    lastIndex = firstIndex + 11
    if lastIndex > collection.count() - 1 then lastIndex = collection.count() - 1
    for index = firstIndex to lastIndex
        item = collection[index]
        if index > firstIndex then output = output + chr(10)
        output = output + "•  " + item.title
        if item.progress_seconds <> invalid and item.duration_seconds <> invalid and item.duration_seconds > 0 then output = output + "  —  " + trim(str(int((item.progress_seconds / item.duration_seconds) * 100))) + "%"
    end for
    m.items.text = output
    updateItemFocus()
end sub

sub updateItemFocus()
    if m.collection = invalid or m.collection.count() = 0 then
        m.itemFocus.visible = false
        return
    end if
    visibleIndex = m.selectedItemIndex - m.collectionOffset
    if visibleIndex > 11 then visibleIndex = 11
    m.itemFocus.visible = true
    m.itemFocus.translation = [370, 302 + (visibleIndex * 48)]
end sub

sub updateViewport()
    if m.selectedItemIndex < m.collectionOffset then
        m.collectionOffset = m.selectedItemIndex
        refresh()
    else if m.selectedItemIndex >= m.collectionOffset + 12 then
        m.collectionOffset = m.selectedItemIndex - 11
        refresh()
    else
        updateItemFocus()
    end if
end sub
