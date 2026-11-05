sub init()
    m.visibleRows = 10
    m.selected = 0
    m.offset = 0
    m.rows = []
    for index = 0 to m.visibleRows - 1
        suffix = index.ToStr()
        if index < 10 then suffix = "0" + suffix
        label = m.top.findNode("row" + suffix)
        label.font = appFont(24, "regular")
        m.rows.push(label)
    end for
    m.rowFocus = m.top.findNode("rowFocus")
    styles = [["eyebrow", 18, "bold", "0x00D7FFFF"], ["channelTitle", 40, "bold", "0xF4F8FFFF"], ["windowLabel", 20, "regular", "0x8894A8FF"], ["emptyState", 24, "regular", "0xB8C4D6FF"], ["footer", 18, "regular", "0x8894A8FF"]]
    for each style in styles
        label = m.top.findNode(style[0])
        label.font = appFont(style[1], style[2])
        label.color = style[3]
    end for
    m.top.observeField("channel", "onChannelChanged")
end sub

sub onChannelChanged()
    channel = m.top.channel
    m.selected = 0
    m.offset = 0
    if channel = invalid then return
    m.top.findNode("channelTitle").text = channel.title
    days = channelArchiveDays(channel)
    if days = 1 then
        m.top.findNode("windowLabel").text = "Programas exibidos nas últimas 24 horas"
    else
        m.top.findNode("windowLabel").text = "Programas exibidos nos últimos " + days.ToStr() + " dias"
    end if
end sub

sub onProgrammesChanged()
    render()
end sub

sub render()
    programmes = m.top.programmes
    if programmes = invalid then programmes = []
    empty = m.top.findNode("emptyState")
    if m.top.loading then
        empty.text = "Carregando a programação…"
    else if programmes.count() = 0 then
        if m.top.message <> "" then
            empty.text = m.top.message
        else
            empty.text = "Nenhum programa disponível para rever neste canal."
        end if
    else
        empty.text = ""
    end if
    showList = (not m.top.loading) and programmes.count() > 0
    for row = 0 to m.visibleRows - 1
        index = m.offset + row
        label = m.rows[row]
        if showList and index < programmes.count() then
            programme = programmes[index]
            label.text = catchupWhenLabel(programme.startSec) + "      " + programme.title
            if index = m.selected then
                label.color = "0xFFFFFFFF"
            else
                label.color = "0xC9D3E3FF"
            end if
        else
            label.text = ""
        end if
    end for
    m.rowFocus.visible = showList
    m.rowFocus.translation = [424, 312 + (m.selected - m.offset) * 58]
end sub

function handleKey(event as Object) as Boolean
    if event.press <> true then return false
    programmes = m.top.programmes
    if programmes = invalid then programmes = []
    if event.key = "back" then
        m.top.visible = false
        return true
    end if
    if programmes.count() = 0 or m.top.loading then return true
    if event.key = "down" and m.selected < programmes.count() - 1 then
        m.selected = m.selected + 1
        if m.selected >= m.offset + m.visibleRows then m.offset = m.selected - m.visibleRows + 1
        render()
    else if event.key = "up" and m.selected > 0 then
        m.selected = m.selected - 1
        if m.selected < m.offset then m.offset = m.selected
        render()
    else if event.key = "OK" or event.key = "play" then
        m.top.programmeSelected = programmes[m.selected]
    end if
    return true
end function
