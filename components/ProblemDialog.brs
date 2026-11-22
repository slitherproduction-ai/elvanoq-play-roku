' Janela "A lista nao abriu" (canvas "ELVANOQ Play TV", tela 4).
sub init()
    m.content = m.top.findNode("content")
    m.buttons = []
    m.selected = 0
end sub

function pdLabel(parent as Object, text as String, x as Integer, y as Integer, w as Integer, h as Integer, size as Integer, weight as String, color as String) as Object
    label = parent.createChild("Label")
    label.translation = [x, y]
    label.width = w
    label.height = h
    label.font = appFont(size, weight)
    label.color = color
    label.text = i18nTr(text)
    return label
end function

function pdRect(parent as Object, x as Integer, y as Integer, w as Integer, h as Integer, radius as Integer, color as String) as Object
    rect = parent.createChild("RoundRect")
    rect.translation = [x, y]
    rect.width = w
    rect.height = h
    rect.radius = radius
    rect.color = color
    return rect
end function

sub build()
    m.content.removeChildrenIndex(m.content.getChildCount(), 0)
    problem = listProblem(m.top.message)
    m.problem = problem
    hasChecks = problem.checks.count() > 0
    shift = 0
    if not hasChecks then shift = 140
    top = 170 + Int(shift / 2)
    card = pdRect(m.content, 400, top, 1120, 742 - shift, 32, "0x0E1524FF")
    card.borderColor = "0x8894A838"
    box = pdRect(m.content, 464, top + 64, 96, 96, 28, "0xF5B83D24")
    icon = m.content.createChild("Poster")
    icon.uri = "pkg:/images/icon_warning.png"
    icon.translation = [488, top + 88]
    icon.width = 48
    icon.height = 48
    icon.blendColor = "0xF5B83DFF"
    pdLabel(m.content, "A LISTA NÃO ABRIU", 592, top + 64, 864, 24, 18, "semibold", "0xF5B83DFF")
    pdLabel(m.content, problem.title, 592, top + 96, 864, 58, 46, "bold", "0xF4F8FFFF")
    msg = pdLabel(m.content, problem.message, 592, top + 162, 864, 74, 24, "regular", "0xC9D2E0FF")
    msg.wrap = true
    msg.maxLines = 2
    y = top + 270
    if hasChecks then
        x = 464
        for each check in problem.checks
            pdRect(m.content, x, y, 320, 104, 20, "0x141F33FF")
            color = "0xA9B4C7FF"
            iconUri = ""
            if check.state = "ok" then
                color = "0x16C784FF"
                iconUri = "pkg:/images/icon_check.png"
            else if check.state = "fail" then
                color = "0xFF8A8AFF"
                iconUri = "pkg:/images/icon_close.png"
            end if
            if iconUri <> "" then
                mark = m.content.createChild("Poster")
                mark.uri = iconUri
                mark.translation = [x + 24, y + 26]
                mark.width = 20
                mark.height = 20
                mark.blendColor = color
            else
                pdRect(m.content, x + 27, y + 35, 14, 3, 3, color)
            end if
            pdLabel(m.content, check.label, x + 54, y + 22, 250, 28, 19, "semibold", color)
            pdLabel(m.content, check.detail, x + 24, y + 58, 280, 28, 20, "regular", "0xA9B4C7FF")
            x = x + 336
        end for
        y = y + 140
    end if
    advice = pdRect(m.content, 464, y, 992, 148, 20, "0x147DFF1A")
    advice.borderColor = "0x147DFF4D"
    pdLabel(m.content, "O que fazer", 494, y + 26, 932, 28, 21, "bold", "0xF4F8FFFF")
    adviceText = pdLabel(m.content, problem.advice, 494, y + 60, 932, 66, 21, "regular", "0xC9D2E0FF")
    adviceText.wrap = true
    adviceText.maxLines = 2
    y = y + 188
    ' Acoes: Tentar de novo (principal) e Fechar.
    m.actions = [{ id: "retry", label: "Tentar de novo", primary: true, x: 464, w: 566 }, { id: "close", label: "Fechar", primary: false, x: 1046, w: 410 }]
    m.buttons = []
    for each action in m.actions
        halo = pdRect(m.content, action.x - 8, y - 8, action.w + 16, 96, 28, "0xF4F8FF1A")
        fillColor = "0x141F33FF"
        textColor = "0xF4F8FFFF"
        weight = "semibold"
        if action.primary then
            fillColor = "0xF4F8FFFF"
            textColor = "0x070B14FF"
            weight = "bold"
        end if
        fill = pdRect(m.content, action.x, y, action.w, 80, 20, fillColor)
        if not action.primary then fill.borderColor = "0x8894A859"
        ring = pdRect(m.content, action.x, y, action.w, 80, 20, "0xF4F8FFFF")
        ring.stroke = 3
        text = pdLabel(m.content, action.label, action.x, y + 24, action.w, 32, 24, weight, textColor)
        text.horizAlign = "center"
        m.buttons.push({ halo: halo, fill: fill, ring: ring, primary: action.primary })
    end for
    m.selected = 0
    render()
end sub

sub render()
    for index = 0 to m.buttons.count() - 1
        b = m.buttons[index]
        focused = (index = m.selected)
        b.halo.visible = focused and b.primary
        b.ring.visible = focused and not b.primary
        if not b.primary then
            if focused then b.fill.color = "0x1A2438FF" else b.fill.color = "0x141F33FF"
        end if
    end for
end sub

function handleKey(args as Object) as Boolean
    key = args.key
    if key = "back" then
        m.top.action = "close"
        return true
    end if
    if key = "left" or key = "up" then
        if m.selected > 0 then m.selected = m.selected - 1
        render()
    else if key = "right" or key = "down" then
        if m.selected < m.buttons.count() - 1 then m.selected = m.selected + 1
        render()
    else if key = "OK" then
        m.top.action = m.actions[m.selected].id
    end if
    return true
end function
