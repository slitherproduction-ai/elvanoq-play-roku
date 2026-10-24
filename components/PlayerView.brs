sub init()
    m.video = m.top.findNode("video")
    m.title = m.top.findNode("title")
    m.hint = m.top.findNode("hint")
    m.trackStatus = m.top.findNode("trackStatus")
    m.timelineProgress = m.top.findNode("timelineProgress")
    m.timeLabel = m.top.findNode("timeLabel")
    m.controlFocus = m.top.findNode("controlFocus")
    m.controls = m.top.findNode("controls")
    m.osdBackground = m.top.findNode("osdBackground")
    m.osdTimer = m.top.findNode("osdTimer")
    m.topShade = m.top.findNode("topShade")
    m.bottomShade = m.top.findNode("bottomShade")
    m.backLabel = m.top.findNode("backLabel")
    m.contentBadge = m.top.findNode("contentBadge")
    m.nowPlayingLabel = m.top.findNode("nowPlayingLabel")
    m.trackPanel = m.top.findNode("trackPanel")
    m.trackPanelTitle = m.top.findNode("trackPanelTitle")
    m.trackPanelValue = m.top.findNode("trackPanelValue")
    m.controlLabels = [m.top.findNode("controlBack"), m.top.findNode("controlPlay"), m.top.findNode("controlForward"), m.top.findNode("controlAudio"), m.top.findNode("controlSubtitles")]
    m.title.font = "font:MediumBoldSystemFont"
    m.hint.font = "font:SmallSystemFont"
    m.trackStatus.font = "font:SmallSystemFont"
    m.trackStatus.color = "0xB9CBE0FF"
    m.timeLabel.font = "font:SmallSystemFont"
    m.controls.font = "font:SmallSystemFont"
    m.controls.color = "0x8FA9C4FF"
    m.controls.text = "←/→ selecionar"
    m.backLabel.font = "font:LargeBoldSystemFont"
    m.contentBadge.font = "font:SmallSystemFont"
    m.contentBadge.color = "0x73B7FFFF"
    m.nowPlayingLabel.font = "font:SmallSystemFont"
    m.nowPlayingLabel.color = "0x73B7FFFF"
    m.trackPanelTitle.font = "font:SmallSystemFont"
    m.trackPanelTitle.color = "0x73B7FFFF"
    m.trackPanelValue.font = "font:SmallSystemFont"
    m.trackPanelValue.color = "0xD7E3F0FF"
    for each label in m.controlLabels
        label.font = "font:MediumBoldSystemFont"
        label.color = "0xD7E3F0FF"
    end for
    m.liveQueue = []
    m.video.notificationInterval = 1
    m.video.observeField("state", "onVideoState")
    m.video.observeField("position", "onPositionChanged")
    m.osdTimer.observeField("fire", "onOsdTimerFired")
    m.top.observeField("streamUrl", "onStreamChanged")
    m.top.observeField("contentTitle", "onTitleChanged")
    m.selectedControl = 1
    m.lastPersistedSecond = -15
    updateControlFocus()
end sub

sub onTitleChanged()
    m.title.text = m.top.contentTitle
end sub

sub onStreamChanged()
    if m.top.streamUrl = "" then return
    m.lastPersistedSecond = -15
    m.shouldRestorePosition = m.top.resumePosition > 0
    if isParentallyBlocked(m.top.contentCategory) then
        m.video.control = "stop"
        m.hint.text = "Conteúdo protegido. Valide o PIN em Ajustes para assistir."
        showOsd()
        return
    end if
    content = CreateObject("roSGNode", "ContentNode")
    content.url = m.top.streamUrl
    content.title = m.top.contentTitle
    m.video.content = content
    m.video.control = "play"
    if isLivePlayback() then m.hint.text = "↑/↓: trocar canal  •  OK: controles  •  Voltar: sair"
end sub

sub onVideoState()
    if m.video.state = "playing" then
        m.controlLabels[1].text = "❚❚  Pausar"
        if m.shouldRestorePosition then
            m.video.seek = m.top.resumePosition
            m.shouldRestorePosition = false
            m.hint.text = "Retomando de onde você parou."
        end if
        refreshTrackStatus()
        showOsd()
    else if m.video.state = "finished" then
        persistProgress(true)
        m.hint.text = "Reprodução concluída."
        showOsd()
    end if
    if m.video.state = "paused" then m.controlLabels[1].text = "▶  Retomar"
    if m.video.state = "error" then
        m.hint.text = "Não foi possível reproduzir este conteúdo. Tente novamente."
        showOsd()
    end if
end sub

sub onPositionChanged()
    updateTimeline()
    if m.video.position <> invalid and m.video.position - m.lastPersistedSecond >= 15 then persistProgress(false)
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
    if not press then return false
    if key = "back" then
        persistProgress(false)
        m.video.control = "stop"
        m.top.closeRequested = true
        return true
    end if
    if key = "left" then
        if m.selectedControl > 0 then m.selectedControl = m.selectedControl - 1
        updateControlFocus()
        showOsd()
        return true
    end if
    if key = "right" then
        if m.selectedControl < 4 then m.selectedControl = m.selectedControl + 1
        updateControlFocus()
        showOsd()
        return true
    end if
    if key = "up" and isLivePlayback() then
        switchLiveChannel(-1)
        return true
    end if
    if key = "down" and isLivePlayback() then
        switchLiveChannel(1)
        return true
    end if
    if key = "up" or key = "down" or key = "options" then
        showOsd()
        refreshTrackStatus()
        return true
    end if
    if key = "OK" then
        if m.osdBackground.visible then
            runSelectedControl()
        else
            showOsd()
        end if
        return true
    end if
    return false
end function

function handleKey(event as Object) as Boolean
    return onKeyEvent(event.key, event.press)
end function

function isLivePlayback() as Boolean
    if m.top.liveQueue = invalid then return false
    return m.top.liveQueue.count() > 0
end function

sub switchLiveChannel(delta as Integer)
    if not isLivePlayback() then return
    nextIndex = m.top.liveIndex + delta
    if nextIndex < 0 then nextIndex = 0
    if nextIndex > m.top.liveQueue.count() - 1 then nextIndex = m.top.liveQueue.count() - 1
    if nextIndex = m.top.liveIndex then
        m.hint.text = "Não há outro canal nesta direção."
        showOsd()
        return
    end if
    nextChannel = m.top.liveQueue[nextIndex]
    if nextChannel = invalid then return
    m.top.channelRequested = { item: nextChannel, index: nextIndex }
end sub

sub showOsd()
    m.osdBackground.visible = true
    m.title.visible = true
    m.hint.visible = true
    m.trackStatus.visible = true
    m.timelineProgress.visible = true
    m.timeLabel.visible = true
    m.controlFocus.visible = true
    m.controls.visible = true
    m.topShade.visible = true
    m.bottomShade.visible = true
    m.backLabel.visible = true
    m.contentBadge.visible = true
    m.nowPlayingLabel.visible = true
    m.trackPanel.visible = true
    m.trackPanelTitle.visible = true
    m.trackPanelValue.visible = true
    for each label in m.controlLabels
        label.visible = true
    end for
    if m.video.state = "playing" then m.osdTimer.control = "start"
end sub

sub onOsdTimerFired()
    if m.video.state = "playing" then hideOsd()
end sub

sub hideOsd()
    m.osdTimer.control = "stop"
    m.osdBackground.visible = false
    m.title.visible = false
    m.hint.visible = false
    m.trackStatus.visible = false
    m.timelineProgress.visible = false
    m.timeLabel.visible = false
    m.controlFocus.visible = false
    m.controls.visible = false
    m.topShade.visible = false
    m.bottomShade.visible = false
    m.backLabel.visible = false
    m.contentBadge.visible = false
    m.nowPlayingLabel.visible = false
    m.trackPanel.visible = false
    m.trackPanelTitle.visible = false
    m.trackPanelValue.visible = false
    for each label in m.controlLabels
        label.visible = false
    end for
end sub

sub updateControlFocus()
    positions = [70, 350, 630, 910, 1190]
    m.controlFocus.translation = [positions[m.selectedControl], 934]
    for index = 0 to m.controlLabels.count() - 1
        if index = m.selectedControl then
            m.controlLabels[index].color = "0xFFFFFFFF"
        else
            m.controlLabels[index].color = "0xD7E3F0FF"
        end if
    end for
    refreshTrackStatus()
end sub

sub runSelectedControl()
    if m.selectedControl = 0 then
        seekBy(-10)
    else if m.selectedControl = 1 then
        if m.video.state = "playing" then
            m.video.control = "pause"
        else if m.video.state = "paused" then
            m.video.control = "resume"
        end if
    else if m.selectedControl = 2 then
        seekBy(10)
    else if m.selectedControl = 3 then
        cycleAudioTrack()
    else if m.selectedControl = 4 then
        cycleSubtitleTrack()
    end if
    showOsd()
end sub

sub seekBy(delta as Integer)
    if m.video.position = invalid or m.video.duration = invalid or m.video.duration <= 0 then
        m.hint.text = "Avanço não disponível neste stream ao vivo."
        return
    end if
    destination = m.video.position + delta
    if destination < 0 then destination = 0
    if destination > m.video.duration then destination = m.video.duration
    m.video.seek = destination
end sub

sub cycleAudioTrack()
    tracks = m.video.availableAudioTracks
    if tracks = invalid or tracks.count() < 2 then
        m.hint.text = "Não há outra faixa de áudio neste stream."
        return
    end if
    nextIndex = trackIndex(tracks, m.video.audioTrack, "Track") + 1
    if nextIndex >= tracks.count() then nextIndex = 0
    m.video.audioTrack = tracks[nextIndex].Track
    m.hint.text = "Faixa de áudio atualizada."
    refreshTrackStatus()
end sub

sub cycleSubtitleTrack()
    tracks = m.video.availableSubtitleTracks
    if tracks = invalid or tracks.count() = 0 then
        m.hint.text = "Não há legendas neste stream."
        return
    end if
    nextIndex = trackIndex(tracks, m.video.subtitleTrack, "TrackName") + 1
    if nextIndex >= tracks.count() then nextIndex = 0
    m.video.subtitleTrack = tracks[nextIndex].TrackName
    m.video.globalCaptionMode = "On"
    m.hint.text = "Legenda atualizada."
    refreshTrackStatus()
end sub

function trackIndex(tracks as Object, selected as String, key as String) as Integer
    for index = 0 to tracks.count() - 1
        if tracks[index][key] = selected then return index
    end for
    return -1
end function

sub refreshTrackStatus()
    audioText = "Áudio: automático"
    subtitlesText = "Legendas: automático"
    if m.video.audioTrack <> invalid and m.video.audioTrack <> "" then audioText = "Áudio: " + m.video.audioTrack
    if m.video.subtitleTrack <> invalid and m.video.subtitleTrack <> "" then subtitlesText = "Legendas: " + m.video.subtitleTrack
    m.trackStatus.text = audioText + "  •  " + subtitlesText
    updateTrackPanel(audioText, subtitlesText)
end sub

sub updateTrackPanel(audioText as String, subtitlesText as String)
    if m.selectedControl = 3 then
        m.trackPanelTitle.text = "ÁUDIO"
        m.trackPanelValue.text = audioText
    else if m.selectedControl = 4 then
        m.trackPanelTitle.text = "LEGENDAS"
        m.trackPanelValue.text = subtitlesText
    else
        m.trackPanelTitle.text = "ÁUDIO E LEGENDAS"
        m.trackPanelValue.text = audioText + "  •  " + subtitlesText
    end if
end sub

sub updateTimeline()
    if m.video.position = invalid or m.video.duration = invalid or m.video.duration <= 0 then
        m.timelineProgress.width = 0
        m.timeLabel.text = "Transmissão ao vivo"
        return
    end if
    percentage = m.video.position / m.video.duration
    if percentage < 0 then percentage = 0
    if percentage > 1 then percentage = 1
    m.timelineProgress.width = int(1780 * percentage)
    m.timeLabel.text = formatTime(m.video.position) + " / " + formatTime(m.video.duration)
end sub

function formatTime(value as Dynamic) as String
    seconds = int(value)
    hours = int(seconds / 3600)
    minutes = int((seconds mod 3600) / 60)
    remaining = seconds mod 60
    if hours > 0 then return twoDigits(hours) + ":" + twoDigits(minutes) + ":" + twoDigits(remaining)
    return twoDigits(minutes) + ":" + twoDigits(remaining)
end function

function twoDigits(value as Integer) as String
    if value < 10 then return "0" + trim(str(value))
    return trim(str(value))
end function

sub persistProgress(completed as Boolean)
    if m.top.contentId = "" or m.video.position = invalid then return
    item = { id: m.top.contentId, title: m.top.contentTitle, category: m.top.contentCategory, progress_seconds: int(m.video.position), duration_seconds: 0, completed: completed, updated_at: CreateObject("roDateTime").ToISOString() }
    if m.video.duration <> invalid then item.duration_seconds = int(m.video.duration)
    state = loadLocalState()
    if not isLivePlayback() then state.continue_watching = upsertLocalItem(state.continue_watching, item)
    state.history = upsertLocalItem(state.history, item)
    saveLocalState(state)
    m.lastPersistedSecond = int(m.video.position)
end sub
