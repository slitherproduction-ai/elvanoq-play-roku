sub init()
    m.video = m.top.findNode("video")
    logCodecSupport()
    m.title = m.top.findNode("title")
    m.hint = m.top.findNode("hint")
    m.trackStatus = m.top.findNode("trackStatus")
    m.liveGuideLabel = m.top.findNode("liveGuideLabel")
    m.timelineProgress = m.top.findNode("timelineProgress")
    m.timeLabel = m.top.findNode("timeLabel")
    m.controlFocus = m.top.findNode("controlFocus")
    m.controls = m.top.findNode("controls")
    m.osdBackground = m.top.findNode("osdBackground")
    m.osdTimer = m.top.findNode("osdTimer")
    m.nextEpisodeTimer = m.top.findNode("nextEpisodeTimer")
    m.retryTimer = m.top.findNode("retryTimer")
    m.liveRetries = 0
    m.nextEpisodePanel = m.top.findNode("nextEpisodePanel")
    m.nextEpisodeTitle = m.top.findNode("nextEpisodeTitle")
    m.nextEpisodeHint = m.top.findNode("nextEpisodeHint")
    m.topShade = m.top.findNode("topShade")
    m.bottomShade = m.top.findNode("bottomShade")
    m.backLabel = m.top.findNode("backLabel")
    m.contentBadge = m.top.findNode("contentBadge")
    m.nowPlayingLabel = m.top.findNode("nowPlayingLabel")
    m.trackPanel = m.top.findNode("trackPanel")
    m.trackPanelTitle = m.top.findNode("trackPanelTitle")
    m.trackPanelValue = m.top.findNode("trackPanelValue")
    m.controlLabels = [m.top.findNode("controlBack"), m.top.findNode("controlPlay"), m.top.findNode("controlForward"), m.top.findNode("controlAudio"), m.top.findNode("controlSubtitles")]
    m.title.font = appFont(44, "bold")
    m.title.color = "0xF4F8FFFF"
    m.hint.font = appFont(22, "medium")
    m.hint.color = "0xF4F8FFFF"
    m.trackStatus.font = appFont(20, "regular")
    m.trackStatus.color = "0xB6C2D6FF"
    m.liveGuideLabel.font = appFont(22, "medium")
    m.liveGuideLabel.color = "0x00D7FFFF"
    m.timeLabel.font = appFont(20, "medium")
    m.timeLabel.color = "0xD6DEEBFF"
    m.controls.font = appFont(20, "regular")
    m.controls.color = "0x8894A8FF"
    m.controls.text = "←/→ selecionar   •   OK confirmar"
    m.backLabel.font = appFont(40, "bold")
    m.contentBadge.font = appFont(18, "bold")
    m.contentBadge.color = "0x00D7FFFF"
    m.nowPlayingLabel.font = appFont(18, "bold")
    m.nowPlayingLabel.color = "0x00D7FFFF"
    m.trackPanelTitle.font = appFont(20, "regular")
    m.trackPanelTitle.color = "0x00D7FFFF"
    m.trackPanelValue.font = appFont(20, "regular")
    m.trackPanelValue.color = "0xD7E3F0FF"
    m.nextEpisodeTitle.font = appFont(26, "semibold")
    m.nextEpisodeTitle.color = "0x00D7FFFF"
    m.nextEpisodeHint.font = appFont(20, "regular")
    m.nextEpisodeHint.color = "0xD7E3F0FF"
    for each label in m.controlLabels
        label.font = appFont(22, "semibold")
        label.color = "0xF4F8FFFF"
    end for
    m.liveQueue = []
    m.video.notificationInterval = 1
    m.video.observeField("state", "onVideoState")
    m.video.observeField("position", "onPositionChanged")
    m.osdTimer.observeField("fire", "onOsdTimerFired")
    m.nextEpisodeTimer.observeField("fire", "onNextEpisodeTimerFired")
    m.retryTimer.observeField("fire", "onRetryTimer")
    m.top.observeField("streamUrl", "onStreamChanged")
    m.top.observeField("contentTitle", "onTitleChanged")
    m.selectedControl = 1
    m.lastPersistedSecond = -30
    updateControlFocus()
end sub

sub onTitleChanged()
    m.title.text = m.top.contentTitle
end sub

sub onStreamChanged()
    if m.top.streamUrl = "" then return
    cancelNextEpisode(false)
    m.skipIntroAvailable = m.top.skipIntroEnd > 0
    m.subtitlesDisabled = false
    m.lastPersistedSecond = -30
    m.shouldRestorePosition = m.top.resumePosition > 0
    m.liveRetries = 0
    m.formatFallbackTried = false
    ' Uma troca de qualidade em andamento mantem a lista de versoes ja tentadas.
    if m.qualityFallbackPending = true then
        m.qualityFallbackPending = false
    else
        m.qualityTried = {}
    end if
    m.retryTimer.control = "stop"
    if isParentallyBlockedItem(m.top.contentCategory, m.top.contentId) then
        m.video.control = "stop"
        m.hint.text = "Conteúdo protegido. Valide o PIN em Ajustes para assistir."
        showOsd()
        return
    end if
    ' TV sem H.265: pula direto para HD/SD quando o canal e sabidamente HEVC,
    ' em vez de esperar o erro -5 (economiza alguns segundos por canal).
    if isLivePlayback() and m.hevcSupported <> true and shouldSkipHevcVariant(m.top.contentTitle) then
        if tryLowerQualityChannel() then
            m.video.control = "stop"
            m.hint.text = "Abrindo versão compatível com esta TV…"
            showOsd()
            return
        end if
    end if
    content = CreateObject("roSGNode", "ContentNode")
    content.url = m.top.streamUrl
    content.title = m.top.contentTitle
    streamFormat = streamFormatForUrl(m.top.streamUrl)
    if streamFormat <> "" then content.streamFormat = streamFormat
    ' Ao vivo: comeca no ponto mais recente do HLS em vez de bufferizar a janela inteira.
    if isLivePlayback() then content.live = true
    m.currentContent = content
    m.video.content = content
    m.video.control = "play"
    if isLivePlayback() then
        m.hint.text = "↑/↓: trocar canal  •  *: favorito  •  Voltar: sair"
        renderLiveGuide()
    else
        m.liveGuideLabel.visible = false
    end if
end sub

sub renderLiveGuide()
    if not isLivePlayback() or m.top.liveGuide = invalid then
        m.liveGuideLabel.visible = false
        return
    end if
    nowText = programmeText(m.top.liveGuide.now)
    nextText = programmeText(m.top.liveGuide.next)
    if nowText = "" and nextText = "" then
        m.liveGuideLabel.visible = false
        return
    end if
    m.liveGuideLabel.text = "Agora: " + nowText
    if nextText <> "" then m.liveGuideLabel.text = m.liveGuideLabel.text + "      A seguir: " + nextText
    m.liveGuideLabel.visible = true
end sub

function programmeText(programme as Dynamic) as String
    if programme = invalid or type(programme) <> "roAssociativeArray" then return ""
    title = ""
    if programme.title <> invalid then title = programme.title
    if title = "" then return ""
    if programme.start <> invalid and len(programme.start) >= 12 then
        return mid(programme.start, 9, 2) + ":" + mid(programme.start, 11, 2) + "  " + title
    end if
    return title
end function

sub onVideoState()
    if m.video.state = "error" then print "ELVANOQ video error code="; m.video.errorCode; " msg="; m.video.errorMsg; " retry="; m.liveRetries
    ' Formato nao suportado (-5): tenta uma vez o outro formato do Xtream (.m3u8 <-> .ts).
    if m.video.state = "error" and m.video.errorCode = -5 then
        ' TV sem H.265: tenta antes a versao HD/SD do mesmo canal.
        if m.hevcSupported <> true and isLivePlayback() then rememberUnsupportedVariant(m.top.contentTitle)
        if m.hevcSupported <> true and tryLowerQualityChannel() then return
        if tryAlternateFormat() then return
        m.hint.text = "Formato de vídeo não suportado por esta TV (provavelmente H.265/HEVC). Tente a versão HD ou SD do canal."
        showOsd()
        return
    end if
    if isLivePlayback() and (m.video.state = "error" or m.video.state = "finished") and m.liveRetries < 3 then
        m.liveRetries = m.liveRetries + 1
        m.hint.text = "Reconectando ao canal… (" + safeTrim(str(m.liveRetries)) + "/3)"
        showOsd()
        m.retryTimer.control = "start"
        return
    end if
    if m.video.state = "playing" then
        m.liveRetries = 0
        if m.qualityNotice <> invalid and m.qualityNotice <> "" then
            m.hint.text = m.qualityNotice
            m.qualityNotice = ""
            showOsd()
        end if
        m.controlLabels[1].text = "Pausar"
        if m.shouldRestorePosition then
            m.video.seek = m.top.resumePosition
            m.shouldRestorePosition = false
            m.hint.text = "Retomando de onde você parou."
        end if
        refreshTrackStatus()
        showOsd()
    else if m.video.state = "finished" then
        persistProgress(true)
        if m.top.nextEpisode <> invalid and m.top.nextEpisode.url <> invalid and m.top.nextEpisode.url <> "" then
            m.osdTimer.control = "stop"
            m.awaitingNextEpisode = true
            m.nextEpisodePanel.visible = true
            m.nextEpisodeTitle.visible = true
            m.nextEpisodeHint.visible = true
            m.nextEpisodeHint.text = "A seguir: " + m.top.nextEpisode.title + chr(10) + "OK iniciar agora  •  * cancelar"
            m.hint.text = "Próximo episódio em 6 segundos."
            showOsd()
            m.nextEpisodeTimer.control = "start"
            return
        end if
        m.hint.text = "Reprodução concluída."
        showOsd()
    else if m.video.state = "buffering" then
        m.hint.text = "Carregando stream…"
        showOsd()
    end if
    if m.video.state = "paused" then m.controlLabels[1].text = "Retomar"
    if m.video.state = "error" then
        m.hint.text = "Não foi possível reproduzir: " + m.video.errorMsg + " (" + safeTrim(str(m.video.errorCode)) + ")"
        showOsd()
    end if
end sub

sub onPositionChanged()
    updateTimeline()
    updateSkipIntroHint()
    if m.video.position <> invalid and m.video.position - m.lastPersistedSecond >= 30 then persistProgress(false)
end sub

sub updateSkipIntroHint()
    if m.skipIntroAvailable <> true then return
    if m.video.position = invalid or m.top.skipIntroEnd <= 0 then return
    if m.video.position >= m.top.skipIntroEnd then
        m.skipIntroAvailable = false
        return
    end if
    m.hint.text = "*: pular abertura  •  OK: controles  •  Voltar: sair"
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
    if not press then return false
    if m.awaitingNextEpisode = true then
        if key = "OK" then
            requestNextEpisode()
            return true
        end if
        if key = "options" or key = "back" then
            cancelNextEpisode(true)
            return true
        end if
        return true
    end if
    if key = "play" then
        togglePlayPause()
        return true
    end if
    if key = "rev" or key = "replay" then
        seekBy(-10)
        showOsd()
        return true
    end if
    if key = "fwd" then
        seekBy(10)
        showOsd()
        return true
    end if
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
    if key = "options" and m.skipIntroAvailable = true and m.video.position <> invalid and m.video.position < m.top.skipIntroEnd then
        m.video.seek = m.top.skipIntroEnd
        m.skipIntroAvailable = false
        m.hint.text = "Abertura pulada."
        showOsd()
        return true
    end if
    if key = "options" and isLivePlayback() then
        m.top.favoriteRequested = { id: m.top.contentId, title: m.top.contentTitle, category: m.top.contentCategory }
        m.hint.text = "Favorito atualizado."
        showOsd()
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

sub onNextEpisodeTimerFired()
    requestNextEpisode()
end sub

sub requestNextEpisode()
    if m.awaitingNextEpisode <> true then return
    m.nextEpisodeTimer.control = "stop"
    m.awaitingNextEpisode = false
    m.nextEpisodePanel.visible = false
    m.nextEpisodeTitle.visible = false
    m.nextEpisodeHint.visible = false
    if m.top.nextEpisode <> invalid then m.top.nextEpisodeRequested = m.top.nextEpisode
end sub

sub cancelNextEpisode(showMessage as Boolean)
    m.nextEpisodeTimer.control = "stop"
    m.awaitingNextEpisode = false
    m.nextEpisodePanel.visible = false
    m.nextEpisodeTitle.visible = false
    m.nextEpisodeHint.visible = false
    if showMessage then
        m.top.nextEpisode = invalid
        m.hint.text = "Próximo episódio cancelado."
        showOsd()
    end if
end sub

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
    if isLivePlayback() then renderLiveGuide()
    ' A barra de tempo so faz sentido em filmes e episodios, nao em canal ao vivo.
    showTimeline = not isLivePlayback()
    m.top.findNode("timelineTrack").visible = showTimeline
    m.timelineProgress.visible = showTimeline
    m.timeLabel.visible = showTimeline
    m.controlFocus.visible = true
    m.controls.visible = true
    m.topShade.visible = true
    m.bottomShade.visible = true
    m.backLabel.visible = true
    m.contentBadge.visible = true
    m.nowPlayingLabel.text = playbackBadge()
    m.nowPlayingLabel.visible = true
    m.trackPanel.visible = false
    m.trackPanelTitle.visible = false
    m.trackPanelValue.visible = false
    if m.awaitingNextEpisode = true then
        m.nextEpisodePanel.visible = true
        m.nextEpisodeTitle.visible = true
        m.nextEpisodeHint.visible = true
    end if
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
    m.liveGuideLabel.visible = false
    m.top.findNode("timelineTrack").visible = false
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
    m.nextEpisodePanel.visible = false
    m.nextEpisodeTitle.visible = false
    m.nextEpisodeHint.visible = false
    for each label in m.controlLabels
        label.visible = false
    end for
end sub

sub updateControlFocus()
    ' Pilula branca no controle selecionado, com texto escuro.
    positions = [64, 240, 416, 592, 768]
    m.controlFocus.translation = [positions[m.selectedControl], 958]
    for index = 0 to m.controlLabels.count() - 1
        if index = m.selectedControl then
            m.controlLabels[index].color = "0x070B14FF"
        else
            m.controlLabels[index].color = "0xF4F8FFFF"
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
        else if m.video.state = "error" then
            m.video.control = "retry"
            m.hint.text = "Tentando reconectar ao stream…"
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
    selectedIndex = trackIndex(tracks, m.video.subtitleTrack, "TrackName")
    if m.subtitlesDisabled <> true and selectedIndex >= tracks.count() - 1 then
        m.video.globalCaptionMode = "Off"
        m.video.subtitleTrack = ""
        m.subtitlesDisabled = true
        m.hint.text = "Legendas desativadas."
        refreshTrackStatus()
        return
    end if
    nextIndex = selectedIndex + 1
    if nextIndex >= tracks.count() then nextIndex = 0
    m.video.subtitleTrack = tracks[nextIndex].TrackName
    m.video.globalCaptionMode = "On"
    m.subtitlesDisabled = false
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
    if m.subtitlesDisabled = true then
        subtitlesText = "Legendas: desativadas"
    else if m.video.subtitleTrack <> invalid and m.video.subtitleTrack <> "" then
        subtitlesText = "Legendas: " + m.video.subtitleTrack
    end if
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
    m.timelineProgress.width = int(1792 * percentage)
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
    if value < 10 then return "0" + safeTrim(str(value))
    return safeTrim(str(value))
end function

sub persistProgress(completed as Boolean)
    if m.top.persistEnabled <> true then return
    if m.top.contentId = "" or m.video.position = invalid then return
    if m.video.duration <> invalid and m.video.duration > 0 and m.video.position / m.video.duration >= 0.95 then completed = true
    item = { id: m.top.contentId, title: m.top.contentTitle, category: m.top.contentCategory, progress_seconds: int(m.video.position), duration_seconds: 0, completed: completed, updated_at: CreateObject("roDateTime").ToISOString() }
    if m.video.duration <> invalid then item.duration_seconds = int(m.video.duration)
    ' Campos para recriar o filme depois, mesmo sem a categoria dele carregada.
    source = m.top.contentItem
    if source <> invalid and source.id = m.top.contentId then
        for each field in ["type", "stream_id", "series_id", "stream_url", "logo", "tvg_id"]
            if source[field] <> invalid then item[field] = source[field]
        end for
    end if
    state = loadLocalState()
    if not isLivePlayback() then
        if completed then
            state.continue_watching = removeLocalItem(state.continue_watching, item.id)
        else
            state.continue_watching = upsertLocalItem(state.continue_watching, item)
        end if
    end if
    state.history = upsertLocalItem(state.history, item)
    saveLocalState(state)
    m.lastPersistedSecond = int(m.video.position)
end sub


sub togglePlayPause()
    if m.video.state = "playing" then
        m.video.control = "pause"
    else if m.video.state = "paused" then
        m.video.control = "resume"
    else if m.video.state = "error" then
        m.video.control = "retry"
    end if
    showOsd()
end sub

sub onRetryTimer()
    if not isLivePlayback() or m.currentContent = invalid then return
    m.video.control = "stop"
    m.video.content = m.currentContent
    m.video.control = "play"
end sub

sub stopPlayback()
    m.retryTimer.control = "stop"
    m.awaitingNextEpisode = false
    m.video.control = "stop"
end sub

function tryAlternateFormat() as Boolean
    if m.formatFallbackTried = true or m.currentContent = invalid then return false
    url = m.currentContent.url
    lower = lcase(url)
    alternate = ""
    alternateFormat = ""
    if right(lower, 5) = ".m3u8" then
        alternate = left(url, len(url) - 5) + ".ts"
        alternateFormat = "ts"
    else if right(lower, 3) = ".ts" then
        alternate = left(url, len(url) - 3) + ".m3u8"
        alternateFormat = "hls"
    end if
    if alternate = "" then return false
    m.formatFallbackTried = true
    content = CreateObject("roSGNode", "ContentNode")
    content.url = alternate
    content.title = m.currentContent.title
    content.streamFormat = alternateFormat
    content.live = m.currentContent.live
    m.currentContent = content
    m.hint.text = "Tentando outro formato de vídeo…"
    showOsd()
    m.video.control = "stop"
    m.video.content = content
    m.video.control = "play"
    return true
end function

sub logCodecSupport()
    check = CreateObject("roDeviceInfo").CanDecodeVideo({ Codec: "hevc" })
    m.hevcSupported = (check <> invalid and check.result = true)
end sub

function shouldSkipHevcVariant(title as String) as Boolean
    if title = "" then return false
    if CreateObject("roRegex", "h\.?265|hevc|\b(4k|uhd)\b", "i").IsMatch(title) then return true
    return unsupportedVariants().DoesExist(lcase(safeTrim(title)))
end function

function unsupportedVariants() as Object
    if m.unsupportedVariants <> invalid then return m.unsupportedVariants
    m.unsupportedVariants = {}
    raw = CreateObject("roRegistrySection", "ELVANOQPlay").Read("unsupported_variants")
    if raw <> "" then
        parsed = ParseJson(raw)
        if type(parsed) = "roArray" then
            for each name in parsed
                if type(name) = "roString" or type(name) = "String" then m.unsupportedVariants[name] = true
            end for
        end if
    end if
    return m.unsupportedVariants
end function

' Guarda (no maximo 120) os canais que falharam por codec, para pular direto na proxima vez.
sub rememberUnsupportedVariant(title as String)
    key = lcase(safeTrim(title))
    if key = "" then return
    known = unsupportedVariants()
    if known.DoesExist(key) then return
    known[key] = true
    names = known.Keys()
    while names.count() > 120
        names.Shift()
    end while
    section = CreateObject("roRegistrySection", "ELVANOQPlay")
    section.Write("unsupported_variants", FormatJson(names))
    section.Flush()
end sub

' Procura na lista atual o mesmo canal em HD (ou SD) e pede a troca.
function tryLowerQualityChannel() as Boolean
    if not isLivePlayback() then return false
    queue = m.top.liveQueue
    if queue = invalid or queue.count() < 2 then return false
    if m.qualityTried = invalid then m.qualityTried = {}
    current = queue[m.top.liveIndex]
    if current = invalid or current.title = invalid then return false
    m.qualityTried[safeTrim(m.top.liveIndex)] = true
    baseName = channelBaseName(current.title)
    if baseName = "" then return false
    for each wanted in ["hd", "sd", ""]
        for index = 0 to queue.count() - 1
            if m.qualityTried[safeTrim(index)] <> true then
                candidate = queue[index]
                if candidate <> invalid and candidate.title <> invalid then
                    if channelBaseName(candidate.title) = baseName and channelQuality(candidate.title) = wanted then
                        m.qualityTried[safeTrim(index)] = true
                        m.qualityFallbackPending = true
                        m.top.channelRequested = { item: candidate, index: index }
                        m.qualityNotice = "Versão " + channelQualityLabel(current.title) + " não suportada nesta TV. Exibindo " + candidate.title + "."
                        return true
                    end if
                end if
            end if
        end for
    end for
    return false
end function

function channelBaseName(title as String) as String
    tags = CreateObject("roRegex", "\[[^\]]*\]|\([^\)]*\)|\b(fhd|uhd|4k|hd|sd|h\.?265|h\.?264|hevc|60fps)\b", "i")
    cleaned = lcase(tags.ReplaceAll(title, " "))
    spaces = CreateObject("roRegex", "[^a-z0-9]+", "i")
    return safeTrim(spaces.ReplaceAll(cleaned, " "))
end function

function channelQuality(title as String) as String
    lower = lcase(title)
    if CreateObject("roRegex", "\b(fhd|uhd|4k)\b|h\.?265|hevc", "i").IsMatch(lower) then return "fhd"
    if CreateObject("roRegex", "\bhd\b", "i").IsMatch(lower) then return "hd"
    if CreateObject("roRegex", "\bsd\b", "i").IsMatch(lower) then return "sd"
    return ""
end function

function channelQualityLabel(title as String) as String
    quality = channelQuality(title)
    if quality = "fhd" then return "FHD"
    if quality = "hd" then return "HD"
    if quality = "sd" then return "SD"
    return "original"
end function

function playbackBadge() as String
    if isLivePlayback() then return "AO VIVO"
    if m.top.nextEpisode <> invalid then return "EPISÓDIO"
    return "REPRODUZINDO"
end function
