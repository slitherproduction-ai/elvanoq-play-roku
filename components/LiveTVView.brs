sub init()
    m.preview = m.top.findNode("preview")
    m.channelFocus = m.top.findNode("channelFocus")
    m.previewTitle = m.top.findNode("previewTitle")
    m.previewHint = m.top.findNode("previewHint")
    m.epgNow = m.top.findNode("epgNow")
    m.epgNext = m.top.findNode("epgNext")
    m.emptyState = m.top.findNode("emptyState")
    m.categories = []
    m.channels = []
    m.selectedIndex = 0
    m.categoryLabels = []
    m.channelLabels = []
    for index = 1 to 6
        m.categoryLabels.push(m.top.findNode("category0" + trim(str(index))))
    end for
    for index = 1 to 8
        m.channelLabels.push(m.top.findNode("channel0" + trim(str(index))))
    end for
    for each label in m.categoryLabels
        label.font = "font:SmallSystemFont"
        label.color = "0x9EB5CCFF"
    end for
    for each label in m.channelLabels
        label.font = "font:SmallSystemFont"
        label.color = "0xFFFFFFFF"
    end for
    m.top.findNode("title").font = "font:LargeBoldSystemFont"
    m.top.findNode("subtitle").font = "font:SmallSystemFont"
    m.top.findNode("subtitle").color = "0x8FA9C4FF"
    m.top.findNode("categoriesTitle").font = "font:SmallSystemFont"
    m.top.findNode("channelsTitle").font = "font:SmallSystemFont"
    m.previewTitle.font = "font:MediumSystemFont"
    m.previewHint.font = "font:SmallSystemFont"
    m.epgNow.font = "font:SmallSystemFont"
    m.epgNext.font = "font:SmallSystemFont"
    m.emptyState.font = "font:SmallSystemFont"
end sub

sub setCatalog(payload as Object)
    if payload = invalid or type(payload) <> "roAssociativeArray" then return
    m.channels = payload.items
    m.categories = payload.categories
    renderGuide()
end sub

sub renderGuide()
    for index = 0 to m.categoryLabels.count() - 1
        if index < m.categories.count() then
            m.categoryLabels[index].text = m.categories[index]
        else
            m.categoryLabels[index].text = ""
        end if
    end for
    if m.channels.count() = 0 then
        m.emptyState.visible = true
        m.emptyState.text = "Nenhum canal disponível nesta lista."
        return
    end if
    m.emptyState.visible = false
    for index = 0 to m.channelLabels.count() - 1
        if index < m.channels.count() then
            m.channelLabels[index].text = m.channels[index].title
        else
            m.channelLabels[index].text = ""
        end if
    end for
    updateSelection()
end sub

sub moveChannel(delta as Integer)
    if m.channels.count() = 0 then return
    nextIndex = m.selectedIndex + delta
    if nextIndex < 0 then nextIndex = 0
    if nextIndex > m.channels.count() - 1 then nextIndex = m.channels.count() - 1
    m.selectedIndex = nextIndex
    updateSelection()
end sub

sub updateSelection()
    visibleIndex = m.selectedIndex
    if visibleIndex > 7 then visibleIndex = 7
    m.channelFocus.translation = [615, 258 + (visibleIndex * 55)]
    selected = m.channels[m.selectedIndex]
    m.previewTitle.text = selected.title
    m.previewHint.text = "OK ou → para iniciar a prévia"
    m.epgNow.text = "Programação disponível após sincronizar XMLTV."
    m.epgNext.text = "Próximo: —"
end sub

sub playSelected()
    if m.channels.count() = 0 then return
    selected = m.channels[m.selectedIndex]
    if isParentallyBlocked(selected.category) then
        m.previewHint.text = "Conteúdo protegido. Valide o PIN em Ajustes para continuar."
        return
    end if
    content = CreateObject("roSGNode", "ContentNode")
    content.url = selected.stream_url
    content.title = selected.title
    m.preview.content = content
    m.preview.control = "play"
    m.previewHint.text = "Prévia em execução  •  OK para assistir em tela cheia"
end sub

sub stopPreview()
    m.preview.control = "stop"
end sub
