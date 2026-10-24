sub init()
    m.video = m.top.findNode("video")
    m.title = m.top.findNode("title")
    m.hint = m.top.findNode("hint")
    m.osdBackground = m.top.findNode("osdBackground")
    m.title.font = "font:MediumBoldSystemFont"
    m.hint.font = "font:SmallSystemFont"
    m.video.observeField("state", "onVideoState")
    m.top.observeField("streamUrl", "onStreamChanged")
    m.top.observeField("contentTitle", "onTitleChanged")
end sub

sub onTitleChanged()
    m.title.text = m.top.contentTitle
end sub

sub onStreamChanged()
    if m.top.streamUrl = "" then return
    content = CreateObject("roSGNode", "ContentNode")
    content.url = m.top.streamUrl
    content.title = m.top.contentTitle
    m.video.content = content
    m.video.control = "play"
end sub

sub onVideoState()
    if m.video.state = "error" then
        m.hint.text = "Não foi possível reproduzir este conteúdo. Tente novamente."
        showOsd()
    end if
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
    if not press then return false
    if key = "back" then
        m.video.control = "stop"
        m.top.closeRequested = true
        return true
    end if
    if key = "OK" then
        if m.osdBackground.visible then
            hideOsd()
        else
            showOsd()
        end if
        return true
    end if
    return false
end function

sub showOsd()
    m.osdBackground.visible = true
    m.title.visible = true
    m.hint.visible = true
end sub

sub hideOsd()
    m.osdBackground.visible = false
    m.title.visible = false
    m.hint.visible = false
end sub
