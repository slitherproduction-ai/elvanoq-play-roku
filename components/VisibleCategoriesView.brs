' Categorias visiveis: abas Ao vivo / Filmes / Series, OK alterna Visivel e Oculta.
' Grava por lista (ListPrefs); nada e apagado da lista.

sub init()
    m.kinds = ["live", "movies", "series"]
    m.tab = 0
    m.selected = 0
    m.visibleRows = 12
    m.top.findNode("pageTitle").font = appFont(40, "bold")
    m.top.findNode("pageTitle").color = "0xF4F8FFFF"
    m.top.findNode("pageSubtitle").font = appFont(20, "regular")
    m.top.findNode("pageSubtitle").color = "0x8894A8FF"
    m.hiddenCount = m.top.findNode("hiddenCount")
    m.hiddenCount.font = appFont(18, "bold")
    m.hiddenCount.color = "0x00D7FFFF"
    m.emptyState = m.top.findNode("emptyState")
    m.emptyState.font = appFont(24, "regular")
    m.emptyState.color = "0xB8C4D6FF"
    footer = m.top.findNode("footer")
    footer.font = appFont(18, "regular")
    footer.color = "0x8894A8FF"
    m.rowFocus = m.top.findNode("rowFocus")
    m.tabBgs = []
    m.tabLabels = []
    for index = 0 to 2
        m.tabBgs.push(m.top.findNode("tabBg" + index.ToStr()))
        label = m.top.findNode("tabLabel" + index.ToStr())
        label.font = appFont(22, "semibold")
        m.tabLabels.push(label)
    end for
    m.rows = []
    m.badges = []
    m.badgeLabels = []
    for index = 0 to m.visibleRows - 1
        suffix = index.ToStr()
        if index < 10 then suffix = "0" + suffix
        row = m.top.findNode("catRow" + suffix)
        row.font = appFont(22, "regular")
        m.rows.push(row)
        m.badges.push(m.top.findNode("catBadge" + suffix))
        badgeLabel = m.top.findNode("catBadgeLabel" + suffix)
        badgeLabel.font = appFont(18, "bold")
        m.badgeLabels.push(badgeLabel)
    end for
    m.top.observeField("visible", "onVisibleChanged")
    render()
end sub

sub onVisibleChanged()
    if m.top.visible then render()
end sub

sub onGroupsChanged()
    m.selected = 0
    render()
end sub

function currentList() as Object
    groups = m.top.categoryGroups
    if groups = invalid then return []
    list = groups[m.kinds[m.tab]]
    if type(list) <> "roArray" then return []
    return list
end function

sub render()
    if m.rows = invalid then return
    for index = 0 to 2
        if index = m.tab then
            m.tabBgs[index].color = "0x147DFFFF"
            m.tabLabels[index].color = "0xFFFFFFFF"
        else
            m.tabBgs[index].color = "0x111B2DFF"
            m.tabLabels[index].color = "0xC9D3E3FF"
        end if
    end for
    list = currentList()
    hidden = hiddenCategorySet(m.kinds[m.tab])
    hiddenHere = 0
    for each category in list
        if hidden.DoesExist(category.id) then hiddenHere = hiddenHere + 1
    end for
    m.hiddenCount.text = hiddenHere.ToStr() + " ocultas de " + list.count().ToStr()
    if list.count() = 0 then
        m.emptyState.text = "Nenhuma categoria recebida da lista nesta aba."
        m.rowFocus.visible = false
        for row = 0 to m.visibleRows - 1
            m.rows[row].text = ""
            m.badges[row].visible = false
            m.badgeLabels[row].text = ""
        end for
        return
    end if
    m.emptyState.text = ""
    if m.selected > list.count() - 1 then m.selected = list.count() - 1
    firstIndex = 0
    if m.selected > m.visibleRows - 1 then firstIndex = m.selected - m.visibleRows + 1
    for row = 0 to m.visibleRows - 1
        index = firstIndex + row
        if index < list.count() then
            category = list[index]
            m.rows[row].text = category.name
            if index = m.selected then m.rows[row].color = "0xFFFFFFFF" else m.rows[row].color = "0xC9D3E3FF"
            m.badges[row].visible = true
            if hidden.DoesExist(category.id) then
                m.badges[row].color = "0x8894A833"
                m.badgeLabels[row].color = "0xC9D3E3FF"
                m.badgeLabels[row].text = "Oculta"
            else
                m.badges[row].color = "0x2EE59D33"
                m.badgeLabels[row].color = "0x7DF2C2FF"
                m.badgeLabels[row].text = "Visível"
            end if
            if index = m.selected then
                m.badges[row].color = "0xFFFFFF33"
                m.badgeLabels[row].color = "0xFFFFFFFF"
            end if
        else
            m.rows[row].text = ""
            m.badges[row].visible = false
            m.badgeLabels[row].text = ""
        end if
    end for
    m.rowFocus.visible = true
    m.rowFocus.translation = [88, 296 + (m.selected - firstIndex) * 58]
end sub

function handleKey(event as Object) as Boolean
    if event = invalid or event.press <> true then return false
    key = event.key
    if key = "left" or key = "right" then
        if key = "right" then m.tab = (m.tab + 1) mod 3 else m.tab = (m.tab + 2) mod 3
        m.selected = 0
        render()
        return true
    end if
    list = currentList()
    if key = "down" and m.selected < list.count() - 1 then
        m.selected = m.selected + 1
        render()
        return true
    end if
    if key = "up" and m.selected > 0 then
        m.selected = m.selected - 1
        render()
        return true
    end if
    if key = "fastforward" and list.count() > 0 then
        m.selected = m.selected + m.visibleRows
        if m.selected > list.count() - 1 then m.selected = list.count() - 1
        render()
        return true
    end if
    if key = "rewind" and list.count() > 0 then
        m.selected = m.selected - m.visibleRows
        if m.selected < 0 then m.selected = 0
        render()
        return true
    end if
    if key = "OK" and list.count() > 0 then
        toggleCategory(list[m.selected].id)
        return true
    end if
    return false
end function

sub toggleCategory(categoryId as String)
    kind = m.kinds[m.tab]
    hidden = loadHiddenCategories()
    updated = []
    removed = false
    for each entry in hidden[kind]
        if entry = categoryId then removed = true else updated.push(entry)
    end for
    if not removed then updated.push(categoryId)
    hidden[kind] = updated
    saveHiddenCategories(hidden)
    render()
    m.top.changed = true
end sub
