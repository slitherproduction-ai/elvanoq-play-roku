sub init()
    m.title = m.top.findNode("title")
    m.tabs = m.top.findNode("tabs")
    m.tabFocus = m.top.findNode("tabFocus")
    m.items = m.top.findNode("items")
    m.title.font = "font:LargeBoldSystemFont"
    m.tabs.font = "font:MediumBoldSystemFont"
    m.tabs.color = "0xB9CBE0FF"
    m.items.font = "font:MediumSystemFont"
    m.items.color = "0xD7E3F0FF"
    m.top.findNode("hint").font = "font:SmallSystemFont"
    m.top.findNode("hint").color = "0x8FA9C4FF"
    m.selectedTab = 0
    refresh()
end sub

function handleKey(event as Object) as Boolean
    if event.press <> true then return false
    if event.key = "right" and m.selectedTab < 3 then
        m.selectedTab = m.selectedTab + 1
        refresh()
        return true
    end if
    if event.key = "left" and m.selectedTab > 0 then
        m.selectedTab = m.selectedTab - 1
        refresh()
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
    if collection = invalid or collection.count() = 0 then
        m.items.text = "Nenhum item salvo nesta coleção ainda."
        return
    end if
    output = ""
    lastIndex = collection.count() - 1
    if lastIndex > 11 then lastIndex = 11
    for index = 0 to lastIndex
        item = collection[index]
        if index > 0 then output = output + chr(10)
        output = output + "•  " + item.title
        if item.progress_seconds <> invalid and item.duration_seconds <> invalid and item.duration_seconds > 0 then output = output + "  —  " + trim(str(int((item.progress_seconds / item.duration_seconds) * 100))) + "%"
    end for
    m.items.text = output
end sub
