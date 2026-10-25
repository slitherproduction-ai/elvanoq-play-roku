sub init()
    m.poster = m.top.findNode("poster")
    m.title = m.top.findNode("title")
    m.meta = m.top.findNode("meta")
    m.genreLabel = m.top.findNode("genreLabel")
    m.overview = m.top.findNode("overview")
    m.watchFocus = m.top.findNode("watchFocus")
    m.listLabel = m.top.findNode("listLabel")
    m.laterLabel = m.top.findNode("laterLabel")
    m.trailerButton = m.top.findNode("trailerButton")
    m.trailerLabel = m.top.findNode("trailerLabel")
    m.actionStatus = m.top.findNode("actionStatus")
    m.seriesLabel = m.top.findNode("seriesLabel")
    m.seasonHint = m.top.findNode("seasonHint")
    m.episodeLabel = m.top.findNode("episodeLabel")
    m.episodeHint = m.top.findNode("episodeHint")
    m.seasonPanel = m.top.findNode("seasonPanel")
    m.selectedAction = 0
    m.selectedSeasonIndex = 0
    m.top.observeField("item", "onItemChanged")
    m.top.observeField("metadata", "onMetadataChanged")
    m.top.findNode("eyebrow").font = "font:SmallSystemFont"
    m.top.findNode("eyebrow").color = "0x73B7FFFF"
    m.title.font = "font:LargeBoldSystemFont"
    m.meta.font = "font:SmallSystemFont"
    m.meta.color = "0x9AB2CCFF"
    m.genreLabel.font = "font:SmallSystemFont"
    m.genreLabel.color = "0x73B7FFFF"
    m.overview.font = "font:MediumSystemFont"
    m.overview.color = "0xD7E3F0FF"
    m.top.findNode("watchLabel").font = "font:MediumBoldSystemFont"
    m.top.findNode("watchLabel").color = "0x06111FFF"
    m.listLabel.font = "font:MediumSystemFont"
    m.laterLabel.font = "font:SmallSystemFont"
    m.actionStatus.font = "font:SmallSystemFont"
    m.actionStatus.color = "0x8FA9C4FF"
    m.seriesLabel.font = "font:SmallSystemFont"
    m.seriesLabel.color = "0xB9CBE0FF"
    m.seasonHint.font = "font:SmallSystemFont"
    m.seasonHint.color = "0x73B7FFFF"
    m.episodeLabel.font = "font:SmallSystemFont"
    m.episodeLabel.color = "0xB9CBE0FF"
    m.episodeHint.font = "font:SmallSystemFont"
    m.episodeHint.color = "0x73B7FFFF"
    m.episodeFocus = false
    m.selectedEpisodeIndex = 0
    m.top.findNode("similarTitle").font = "font:MediumBoldSystemFont"
    m.top.findNode("similarHint").font = "font:SmallSystemFont"
    updateActionFocus()
end sub

sub onMetadataChanged()
    if m.top.metadata = invalid or m.top.metadata.found <> true then return
    if m.top.metadata.mode = "season" then
        renderEpisodes(m.top.metadata)
        return
    end if
    if m.top.metadata.item = invalid then return
    details = m.top.metadata.item
    if details.title <> invalid and details.title <> "" then m.title.text = details.title
    if details.overview <> invalid and details.overview <> "" then m.overview.text = details.overview
    if details.release_date <> invalid and details.vote_average <> invalid then
        m.meta.text = details.release_date + "  •  Avaliação " + str(details.vote_average)
    end if
    if details.genres <> invalid and details.genres.count() > 0 then m.genreLabel.text = genreSummary(details.genres)
    if details.poster_path <> invalid and details.poster_path <> "" then m.poster.uri = "https://image.tmdb.org/t/p/w780" + details.poster_path
    if details.seasons <> invalid and details.seasons.count() > 0 then
        m.seasons = details.seasons
        m.selectedSeasonIndex = 0
        m.seriesLabel.visible = true
        m.seasonHint.visible = true
        m.seasonPanel.visible = true
        updateSeasonSelection()
    end if
    m.trailerUrl = trailerUrlFromDetails(details)
    m.trailerButton.visible = m.trailerUrl <> ""
    m.trailerLabel.visible = m.trailerUrl <> ""
    if m.trailerUrl <> "" then m.actionStatus.text = "Trailer oficial disponível."
    if details.recommendations <> invalid and details.recommendations.count() > 0 then m.top.findNode("similarHint").text = recommendationSummary(details.recommendations)
end sub

function trailerUrlFromDetails(details as Object) as String
    candidate = ""
    if details.trailer_url <> invalid then candidate = details.trailer_url
    if candidate = "" and details.trailer <> invalid then
        if type(details.trailer) = "roAssociativeArray" then
            if details.trailer.url <> invalid then candidate = details.trailer.url
        else if type(details.trailer) = "roString" then
            candidate = details.trailer
        end if
    end if
    candidate = trim(candidate)
    if left(candidate, 8) = "https://" then return candidate
    return ""
end function

function genreSummary(genres as Object) as String
    summary = ""
    lastIndex = genres.count() - 1
    if lastIndex > 3 then lastIndex = 3
    for index = 0 to lastIndex
        genre = genres[index]
        if index > 0 then summary = summary + "  •  "
        if type(genre) = "roAssociativeArray" and genre.name <> invalid then
            summary = summary + genre.name
        else
            summary = summary + genre
        end if
    end for
    return summary
end function

function seasonSummary(seasons as Object) as String
    summary = "Temporadas: "
    lastIndex = seasons.count() - 1
    if lastIndex > 5 then lastIndex = 5
    for index = 0 to lastIndex
        season = seasons[index]
        if index > 0 then summary = summary + "  •  "
        summary = summary + season.name + " (" + trim(str(season.episode_count)) + ")"
    end for
    return summary
end function

sub updateSeasonSelection()
    if m.seasons = invalid or m.seasons.count() = 0 then return
    season = m.seasons[m.selectedSeasonIndex]
    m.seriesLabel.text = "Temporada selecionada: " + season.name + " (" + trim(str(season.episode_count)) + " episódios)"
    m.seasonHint.text = "↑/↓: trocar temporada  •  episódios da fonte autorizada"
end sub

function recommendationSummary(items as Object) as String
    summary = "Recomendações: "
    lastIndex = items.count() - 1
    if lastIndex > 3 then lastIndex = 3
    for index = 0 to lastIndex
        if index > 0 then summary = summary + "  •  "
        summary = summary + items[index].title
    end for
    return summary
end function

sub renderEpisodes(payload as Object)
    episodes = payload.episodes
    if episodes = invalid or episodes.count() = 0 then return
    m.episodes = episodes
    m.selectedEpisodeIndex = 0
    m.episodeLabel.visible = true
    m.episodeHint.visible = true
    renderEpisodeSelection()
end sub

sub renderEpisodeSelection()
    if m.episodes = invalid or m.episodes.count() = 0 then return
    selected = m.episodes[m.selectedEpisodeIndex]
    number = ""
    if selected.number <> invalid then number = trim(str(selected.number)) + ". "
    name = episodeDisplayName(selected)
    prefix = "Episódio selecionado: "
    if m.episodeFocus then prefix = "▶ " + prefix
    m.episodeLabel.text = prefix + number + name
    if m.episodeFocus then
        m.episodeHint.text = "←/→ escolher  •  OK assistir  •  * voltar às ações"
    else
        m.episodeHint.text = "*: selecionar episódio para assistir"
    end if
end sub

function episodeStreamUrl(episode as Object) as String
    if episode = invalid then return ""
    candidate = ""
    if episode.stream_url <> invalid then candidate = episode.stream_url
    if candidate = "" and episode.playback_url <> invalid then candidate = episode.playback_url
    if candidate = "" and episode.url <> invalid then candidate = episode.url
    candidate = trim(candidate)
    ' IPTV providers may expose authorized episode streams over HTTP.
    ' The URL stays only in memory and is never logged or persisted locally.
    if left(candidate, 8) = "https://" or left(candidate, 7) = "http://" then return candidate
    return ""
end function

function episodeDisplayName(episode as Object) as String
    if episode <> invalid and episode.name <> invalid and episode.name <> "" then return episode.name
    return "Episódio"
end function

function episodeRequestAt(index as Integer) as Object
    if m.episodes = invalid or index < 0 or index >= m.episodes.count() then return invalid
    episode = m.episodes[index]
    streamUrl = episodeStreamUrl(episode)
    if streamUrl = "" then return invalid
    episodeNumber = index + 1
    if episode.number <> invalid then episodeNumber = int(episode.number)
    request = { url: streamUrl, title: m.top.item.title + " • " + episodeDisplayName(episode), id: m.top.item.id + ":episode:" + trim(str(episodeNumber)), parentId: m.top.item.id, category: m.top.item.category }
    return request
end function

function authorizedEpisodeQueue(startIndex as Integer) as Object
    queue = []
    if m.episodes = invalid then return queue
    for index = startIndex to m.episodes.count() - 1
        request = episodeRequestAt(index)
        if request = invalid then exit for
        queue.push(request)
    end for
    return queue
end function

sub onItemChanged()
    if m.top.item = invalid then return
    item = m.top.item
    m.title.text = item.title
    m.meta.text = item.category + "  •  Conteúdo da sua lista"
    m.genreLabel.text = ""
    m.overview.text = "Informações complementares, elenco, trailer e recomendações serão exibidos quando os metadados estiverem disponíveis."
    if item.logo <> invalid then m.poster.uri = item.logo
    m.actionStatus.text = ""
    m.trailerUrl = ""
    m.episodes = invalid
    m.episodeFocus = false
    m.episodeLabel.visible = false
    m.episodeHint.visible = false
    m.trailerButton.visible = false
    m.trailerLabel.visible = false
    m.seasonPanel.visible = false
    updateCollectionLabels()
end sub

sub updateCollectionLabels()
    if m.top.item = invalid then return
    state = loadLocalState()
    if collectionContains(state.favorites, m.top.item.id) then
        m.listLabel.text = "✓ Minha Lista"
    else
        m.listLabel.text = "+ Minha Lista"
    end if
    if collectionContains(state.watch_later, m.top.item.id) then
        m.laterLabel.text = "✓ Assistir mais tarde"
    else
        m.laterLabel.text = "Assistir mais tarde"
    end if
end sub

function collectionContains(items as Object, itemId as String) as Boolean
    if items = invalid then return false
    for each current in items
        if current.id = itemId then return true
    end for
    return false
end function

function onKeyEvent(key as String, press as Boolean) as Boolean
    if not press then return false
    if key = "back" then
        if m.episodeFocus then
            m.episodeFocus = false
            renderEpisodeSelection()
            return true
        end if
        m.top.closeRequested = true
        return true
    end if
    if key = "options" and m.episodes <> invalid and m.episodes.count() > 0 then
        m.episodeFocus = not m.episodeFocus
        renderEpisodeSelection()
        return true
    end if
    if m.episodeFocus then
        if key = "left" and m.selectedEpisodeIndex > 0 then
            m.selectedEpisodeIndex = m.selectedEpisodeIndex - 1
            renderEpisodeSelection()
            return true
        end if
        if key = "right" and m.selectedEpisodeIndex < m.episodes.count() - 1 then
            m.selectedEpisodeIndex = m.selectedEpisodeIndex + 1
            renderEpisodeSelection()
            return true
        end if
        if key = "OK" then
            queue = authorizedEpisodeQueue(m.selectedEpisodeIndex)
            if queue.count() = 0 then
                m.actionStatus.text = "Este episódio ainda não possui reprodução autorizada na sua lista."
                return true
            end if
            request = queue[0]
            request.queue = queue
            m.top.episodeRequested = request
            return true
        end if
        return key = "left" or key = "right" or key = "up" or key = "down"
    end if
    maxAction = 2
    if m.trailerUrl <> invalid and m.trailerUrl <> "" then maxAction = 3
    if key = "right" and m.selectedAction < maxAction then
        m.selectedAction = m.selectedAction + 1
        updateActionFocus()
        return true
    end if
    if key = "left" and m.selectedAction > 0 then
        m.selectedAction = m.selectedAction - 1
        updateActionFocus()
        return true
    end if
    if key = "down" and m.seasons <> invalid and m.selectedSeasonIndex < m.seasons.count() - 1 then
        m.selectedSeasonIndex = m.selectedSeasonIndex + 1
        updateSeasonSelection()
        m.top.seasonRequested = m.seasons[m.selectedSeasonIndex].number
        return true
    end if
    if key = "up" and m.seasons <> invalid and m.selectedSeasonIndex > 0 then
        m.selectedSeasonIndex = m.selectedSeasonIndex - 1
        updateSeasonSelection()
        m.top.seasonRequested = m.seasons[m.selectedSeasonIndex].number
        return true
    end if
    if key = "OK" then
        runAction()
        return true
    end if
    return false
end function

function handleKey(event as Object) as Boolean
    return onKeyEvent(event.key, event.press)
end function

sub updateActionFocus()
    positions = [150, 386, 632, 850]
    widths = [220, 230, 205, 150]
    m.watchFocus.translation = [positions[m.selectedAction], 500]
    m.watchFocus.width = widths[m.selectedAction]
    if m.selectedAction = 0 then m.watchFocus.color = "0xFFFFFFFF" else m.watchFocus.color = "0x2E91EFFF"
end sub

sub runAction()
    if m.top.item = invalid then return
    item = m.top.item
    if m.selectedAction = 0 then
        if isParentallyBlockedItem(item.category, item.id) then
            m.actionStatus.text = "Conteúdo protegido. Valide o PIN em Ajustes para assistir."
        else
            m.top.playRequested = item
        end if
    else if m.selectedAction = 1 then
        state = loadLocalState()
        if collectionContains(state.favorites, item.id) then
            state.favorites = removeLocalItem(state.favorites, item.id)
            m.actionStatus.text = "Removido dos favoritos."
        else
            state.favorites = upsertLocalItem(state.favorites, item)
            m.actionStatus.text = "Adicionado aos favoritos."
        end if
        saveLocalState(state)
        updateCollectionLabels()
    else if m.selectedAction = 2 then
        state = loadLocalState()
        if collectionContains(state.watch_later, item.id) then
            state.watch_later = removeLocalItem(state.watch_later, item.id)
            m.actionStatus.text = "Removido de assistir mais tarde."
        else
            state.watch_later = upsertLocalItem(state.watch_later, item)
            m.actionStatus.text = "Adicionado para assistir mais tarde."
        end if
        saveLocalState(state)
        updateCollectionLabels()
    else if m.trailerUrl <> invalid and m.trailerUrl <> "" then
        m.top.trailerRequested = { url: m.trailerUrl, title: item.title + " • Trailer", id: item.id, category: item.category }
    end if
end sub
