' "Bem-vindo de volta": comandos "start" / "finish" / "hide" pelo campo command;
' etapas pelo campo stage (0 licenca, 1 servidor, 2 catalogo, 3 pronto; so avanca).

sub init()
    i18nAttach(m.top)
    m.progress = m.top.findNode("progress")
    m.greeting = m.top.findNode("greeting")
    m.title = m.top.findNode("title")
    m.initial = m.top.findNode("initial")
    m.name = m.top.findNode("name")
    m.lic = m.top.findNode("lic")
    m.status = m.top.findNode("status")
    m.countsLabel = m.top.findNode("countsLabel")
    m.tip = m.top.findNode("tip")
    m.root = m.top.findNode("welcomeRoot")
    m.greeting.font = appFont(27, "semibold")
    m.greeting.color = "0x00D7FFFF"
    m.title.font = appFont(90, "bold")
    m.title.color = "0xF4F8FFFF"
    m.initial.font = appFont(26, "bold")
    m.initial.color = "0x04080FFF"
    m.name.font = appFont(27, "semibold")
    m.name.color = "0xF4F8FFFF"
    m.lic.font = appFont(24, "regular")
    m.lic.color = "0x9AA6BDFF"
    m.status.font = appFont(28, "medium")
    m.status.color = "0xDCE6F5FF"
    m.countsLabel.font = appFont(24, "regular")
    m.countsLabel.color = "0x9AA6BDFF"
    m.tip.font = appFont(24, "regular")
    m.tip.color = "0x9AA6BDFF"
    m.measure = CreateObject("roSGNode", "Label")
    m.labels = ["Confirmando a licença…", "Conectando ao servidor da lista…", "Carregando canais, filmes e séries…", "Tudo pronto"]
    m.fills = [3, 10, 18, 25]
    m.tips = ["No ao vivo, aperte → duas vezes para abrir as opções do canal.", "Segure OK num canal ou filme para salvar na Minha Lista.", "Em Ajustes você esconde as categorias que não usa."]
    m.frame = 0
    m.target = 0
    m.progressTimer = m.top.findNode("progressTimer")
    m.progressTimer.observeField("fire", "onProgressTick")
    m.tipTimer = m.top.findNode("tipTimer")
    m.tipTimer.observeField("fire", "nextTip")
    m.readyTimer = m.top.findNode("readyTimer")
    m.readyTimer.observeField("fire", "onReady")
    m.guardTimer = m.top.findNode("guardTimer")
    m.guardTimer.observeField("fire", "onGuard")
    m.outAnim = m.top.findNode("outAnim")
    m.outAnim.observeField("state", "onOutState")
end sub

sub onCommand()
    command = m.top.command
    if command = "start" then
        startWelcome()
    else if command = "finish" then
        finishWelcome()
    else if command = "hide" then
        hideWelcome()
    end if
end sub

function welcomeGreeting() as String
    now = CreateObject("roDateTime")
    now.ToLocalTime()
    hour = now.GetHours()
    if hour >= 5 and hour < 12 then return "Bom dia,"
    if hour >= 12 and hour < 18 then return "Boa tarde,"
    return "Boa noite,"
end function

sub startWelcome()
    name = safeTrim(m.top.listName)
    if name = "" then name = "Minha lista"
    m.greeting.text = welcomeGreeting()
    m.initial.text = ucase(left(name, 1))
    m.name.text = name
    layoutChip()
    m.countsLabel.text = ""
    m.frame = 0
    m.target = 0
    m.progress.uri = "pkg:/images/welcome/progress_00.png"
    m.root.opacity = 1
    m.top.active = true
    m.top.visible = true
    m.top.stage = -1
    m.top.stage = 0
    for each id in ["cometAnim", "orbitAnim", "satAnim", "breathAnim", "introAnim"]
        m.top.findNode(id).control = "start"
    end for
    m.tipIndex = -1
    nextTip()
    m.tipTimer.control = "start"
    m.guardTimer.control = "start"
end sub

' Pilula centralizada: inicial + nome + ponto + "TV licenciada".
sub layoutChip()
    m.measure.font = m.name.font
    m.measure.text = m.name.text
    nameWidth = Int(m.measure.boundingRect().width)
    if nameWidth > 640 then nameWidth = 640
    m.name.width = nameWidth + 2
    m.measure.font = m.lic.font
    m.measure.text = m.lic.text
    licWidth = Int(m.measure.boundingRect().width) + 2
    dotX = 84 + nameWidth + 18
    licX = dotX + 6 + 18
    width = licX + licWidth + 27
    m.top.findNode("chipDot").translation = [dotX, 36]
    m.lic.translation = [licX, 0]
    m.lic.width = licWidth
    m.top.findNode("chipBg").width = width
    m.top.findNode("chip").translation = [Int((1920 - width) / 2), 689]
end sub

sub onStage()
    stage = m.top.stage
    if stage < 0 or stage > 3 then return
    m.status.text = m.labels[stage]
    m.target = m.fills[stage]
    m.progressTimer.control = "start"
    widths = [9, 9, 9]
    colors = ["0x24344DFF", "0x24344DFF", "0x24344DFF"]
    for i = 0 to 2
        if i < stage then colors[i] = "0x00D7FFFF"
        if i = stage then
            widths[i] = 51
            colors[i] = "0x7FEBFFFF"
        end if
    end for
    total = widths[0] + widths[1] + widths[2] + 28
    x = Int((1920 - total) / 2)
    for i = 0 to 2
        dot = m.top.findNode("dot" + i.ToStr())
        dot.width = widths[i]
        dot.color = colors[i]
        dot.translation = [x, 926]
        x = x + widths[i] + 14
    end for
end sub

sub onProgressTick()
    if m.frame = m.target then
        m.progressTimer.control = "stop"
        return
    end if
    if m.frame < m.target then m.frame = m.frame + 1 else m.frame = m.target
    index = m.frame.ToStr()
    if len(index) < 2 then index = "0" + index
    m.progress.uri = "pkg:/images/welcome/progress_" + index + ".png"
end sub

sub nextTip()
    m.tipIndex = (m.tipIndex + 1) mod m.tips.count()
    m.tip.text = i18nTr("Dica ·") + " " + i18nTr(m.tips[m.tipIndex])
    anim = m.top.findNode("tipAnim")
    anim.control = "stop"
    anim.control = "start"
end sub

' Catalogo pronto: totais, "Tudo pronto" e esmaece (finished ao fim).
sub finishWelcome()
    if m.top.active <> true then
        m.top.finished = true
        return
    end if
    if m.top.stage < 3 then m.top.stage = 3
    m.countsLabel.text = m.top.counts
    m.guardTimer.control = "stop"
    m.readyTimer.control = "start"
end sub

sub onReady()
    m.outAnim.control = "start"
end sub

sub onOutState()
    if m.outAnim.state <> "stopped" then return
    stopAll()
    m.top.finished = true
end sub

sub hideWelcome()
    stopAll()
end sub

sub onGuard()
    if m.top.active = true then m.top.timedOut = true
end sub

sub stopAll()
    m.top.active = false
    m.top.visible = false
    for each id in ["cometAnim", "orbitAnim", "satAnim", "breathAnim", "introAnim", "tipAnim"]
        m.top.findNode(id).control = "stop"
    end for
    m.progressTimer.control = "stop"
    m.tipTimer.control = "stop"
    m.readyTimer.control = "stop"
    m.guardTimer.control = "stop"
end sub
