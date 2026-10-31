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
    m.top.observeField("seriesInfo", "onSeriesInfoChanged")
    m.backdrop = m.top.findNode("backdrop")
    m.seasonFocus = m.top.findNode("seasonFocus")
    m.episodesPanel = m.top.findNode("episodesPanel")
    m.episodeFocusBar = m.top.findNode("episodeFocusBar")
    ' Cards de episodio: imagem 16:9, numero e titulo (7 visiveis).
    m.cardCount = 7
    m.cardWidth = 240
    m.cardGap = 18
    m.episodeCards = []
    cardsGroup = m.top.findNode("episodeCards")
    for index = 0 to m.cardCount - 1
        x = index * (m.cardWidth + m.cardGap)
        background = cardsGroup.createChild("RoundRect")
        background.radius = 12
        background.translation = [x, 0]
        background.width = m.cardWidth
        background.height = 135
        background.color = "0x111B2DFF"
        thumb = cardsGroup.createChild("Poster")
        thumb.translation = [x, 0]
        thumb.width = m.cardWidth
        thumb.height = 135
        thumb.loadDisplayMode = "scaleToZoom"
        number = cardsGroup.createChild("Label")
        number.translation = [x, 146]
        number.width = m.cardWidth
        number.height = 26
        number.font = appFont(18, "bold")
        number.color = "0x00D7FFFF"
        title = cardsGroup.createChild("Label")
        title.translation = [x, 172]
        title.width = m.cardWidth
        title.height = 56
        title.wrap = true
        title.maxLines = 2
        title.font = appFont(20, "medium")
        title.color = "0xF4F8FFFF"
        m.episodeCards.push({ background: background, thumb: thumb, number: number, title: title })
    end for
    m.episodeRows = []
    m.episodeOffset = 0
    m.detailFocus = "actions"
    m.top.findNode("eyebrow").font = appFont(18, "bold")
    m.top.findNode("eyebrow").color = "0x00D7FFFF"
    m.title.font = appFont(54, "bold")
    m.title.color = "0xF4F8FFFF"
    m.meta.font = appFont(20, "regular")
    m.meta.color = "0xB6C2D6FF"
    m.genreLabel.font = appFont(20, "regular")
    m.genreLabel.color = "0x00D7FFFF"
    m.overview.font = appFont(24, "regular")
    m.overview.color = "0xD6DEEBFF"
    m.top.findNode("watchLabel").font = appFont(26, "semibold")
    m.top.findNode("watchLabel").color = "0x070B14FF"
    m.listLabel.font = appFont(26, "semibold")
    m.listLabel.color = "0xF4F8FFFF"
    m.laterLabel.font = appFont(26, "semibold")
    m.laterLabel.color = "0xF4F8FFFF"
    m.trailerLabel.font = appFont(26, "semibold")
    m.trailerLabel.color = "0xF4F8FFFF"
    m.actionStatus.font = appFont(20, "regular")
    m.actionStatus.color = "0x00D7FFFF"
    m.top.findNode("similarTitle").color = "0xF4F8FFFF"
    m.top.findNode("similarHint").color = "0x8894A8FF"
    m.seriesLabel.font = appFont(26, "semibold")
    m.seriesLabel.color = "0xF4F8FFFF"
    m.seasonHint.font = appFont(20, "regular")
    m.seasonHint.color = "0x8894A8FF"
    m.episodeLabel.font = appFont(24, "regular")
    m.episodeLabel.color = "0xF4F8FFFF"
    m.episodeHint.font = appFont(20, "regular")
    m.episodeHint.color = "0x8894A8FF"
    m.episodeFocus = false
    m.selectedEpisodeIndex = 0
    m.top.findNode("similarTitle").font = appFont(26, "semibold")
    m.top.findNode("similarHint").font = appFont(20, "regular")
    updateActionFocus()
end sub

sub onMetadataChanged()
    if m.top.metadata = invalid or m.top.metadata.found <> true then return
    ' Series Xtream usam temporadas e episodios do servidor da lista, nao do TMDB.
    if isXtreamSeries() and m.top.metadata.mode = "season" then return
    if m.top.metadata.mode = "season" then
        renderEpisodes(m.top.metadata)
        return
    end if
    if m.top.metadata.item = invalid then return
    details = m.top.metadata.item
    if details.title <> invalid and details.title <> "" then m.title.text = details.title
    if details.overview <> invalid and details.overview <> "" then m.overview.text = details.overview
    if details.release_date <> invalid and details.vote_average <> invalid then
        m.meta.text = safeTrim(details.release_date) + "   •   Avaliação " + safeTrim(str(details.vote_average))
    end if
    if details.genres <> invalid and details.genres.count() > 0 then m.genreLabel.text = genreSummary(details.genres)
    if details.poster_path <> invalid and details.poster_path <> "" then m.poster.uri = "https://image.tmdb.org/t/p/w780" + details.poster_path
    if details.backdrop_path <> invalid and details.backdrop_path <> "" then m.backdrop.uri = "https://image.tmdb.org/t/p/w1280" + details.backdrop_path
    if details.seasons <> invalid and details.seasons.count() > 0 and not isXtreamSeries() then
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
    candidate = safeTrim(candidate)
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
        summary = summary + season.name + " (" + safeTrim(str(season.episode_count)) + ")"
    end for
    return summary
end function

sub updateSeasonSelection()
    if m.seasons = invalid or m.seasons.count() = 0 then return
    season = m.seasons[m.selectedSeasonIndex]
    m.seriesLabel.text = season.name + "   •   " + safeTrim(str(season.episode_count)) + " episódios   •   " + safeTrim(str(m.selectedSeasonIndex + 1)) + " de " + safeTrim(str(m.seasons.count()))
    if m.xtreamEpisodes <> invalid then
        m.seasonHint.text = "←/→ trocar temporada   •   ↓ ver episódios"
    else
        m.seasonHint.text = "↑/↓: trocar temporada"
    end if
    m.seasonFocus.visible = m.detailFocus = "seasons"
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
    m.episodeOffset = 0
    m.episodeHint.visible = true
    renderEpisodeSelection()
end sub

' Fileira de cards; a janela anda com o episodio selecionado.
sub renderEpisodeSelection()
    if m.episodes = invalid or m.episodes.count() = 0 then return
    m.top.findNode("episodeCards").visible = true
    if m.selectedEpisodeIndex < m.episodeOffset then m.episodeOffset = m.selectedEpisodeIndex
    if m.selectedEpisodeIndex >= m.episodeOffset + m.cardCount then m.episodeOffset = m.selectedEpisodeIndex - (m.cardCount - 1)
    for slot = 0 to m.cardCount - 1
        index = m.episodeOffset + slot
        card = m.episodeCards[slot]
        visible = index < m.episodes.count()
        card.background.visible = visible
        card.thumb.visible = visible
        card.number.visible = visible
        card.title.visible = visible
        if visible then
            episode = m.episodes[index]
            number = index + 1
            if episode.number <> invalid and type(episode.number) <> "roString" and type(episode.number) <> "String" and episode.number > 0 then number = episode.number
            card.number.text = "EPISÓDIO " + safeTrim(str(number))
            card.title.text = episodeDisplayName(episode)
            image = ""
            if episode.image <> invalid then image = episode.image
            if image = "" and m.top.item <> invalid and m.top.item.backdrop <> invalid then image = m.top.item.backdrop
            if image = "" and m.top.item <> invalid and m.top.item.logo <> invalid then image = m.top.item.logo
            card.thumb.uri = image
        end if
    end for
    focused = m.detailFocus = "episodes" or m.episodeFocus = true
    m.episodeFocusBar.visible = focused
    slot = m.selectedEpisodeIndex - m.episodeOffset
    m.episodeFocusBar.translation = [64 + slot * (m.cardWidth + m.cardGap) - 6, 786 - 6]
    m.episodeFocusBar.width = m.cardWidth + 12
    m.episodeFocusBar.height = 135 + 12
    if focused then
        m.episodeHint.text = "←/→ escolher episódio   •   OK assistir   •   ↑ temporadas"
    else
        m.episodeHint.text = "↓ para escolher um episódio"
    end if
end sub

function episodeStreamUrl(episode as Object) as String
    if episode = invalid then return ""
    candidate = ""
    if episode.stream_url <> invalid then candidate = episode.stream_url
    if candidate = "" and episode.playback_url <> invalid then candidate = episode.playback_url
    if candidate = "" and episode.url <> invalid then candidate = episode.url
    candidate = safeTrim(candidate)
    ' IPTV providers may expose authorized episode streams over HTTP.
    ' The URL stays only in memory and is never logged or persisted locally.
    if left(candidate, 8) = "https://" or left(candidate, 7) = "http://" then return candidate
    return ""
end function

function episodeDisplayName(episode as Object) as String
    if episode <> invalid and episode.name <> invalid and episode.name <> "" then return episode.name
    return "Episódio"
end function

function episodeSkipIntroEnd(episode as Object) as Integer
    if episode = invalid then return 0
    value = 0
    if episode.intro_end_seconds <> invalid then value = int(episode.intro_end_seconds)
    if value <= 0 and episode.introEnd <> invalid then value = int(episode.introEnd)
    if value < 0 then value = 0
    return value
end function

function episodeRequestAt(index as Integer) as Object
    if m.episodes = invalid or index < 0 or index >= m.episodes.count() then return invalid
    episode = m.episodes[index]
    streamUrl = episodeStreamUrl(episode)
    if streamUrl = "" then return invalid
    episodeNumber = index + 1
    if episode.number <> invalid then episodeNumber = int(episode.number)
    request = { url: streamUrl, title: m.top.item.title + " • " + episodeDisplayName(episode), id: m.top.item.id + ":episode:" + safeTrim(str(episodeNumber)), parentId: m.top.item.id, category: m.top.item.category, introEnd: episodeSkipIntroEnd(episode) }
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
    ' Fundo: imagem larga da lista (series) ou o proprio poster ampliado.
    m.backdrop.uri = ""
    if item.backdrop <> invalid and item.backdrop <> "" then
        m.backdrop.uri = item.backdrop
    else if item.logo <> invalid then
        m.backdrop.uri = item.logo
    end if
    m.top.findNode("similarTitle").visible = not isXtreamSeries()
    m.top.findNode("similarHint").visible = not isXtreamSeries()
    m.top.findNode("similarHint").text = ""
    if isXtreamSeries() then
        m.top.findNode("watchLabel").text = "Ver episódios"
    else
        m.top.findNode("watchLabel").text = "Assistir"
    end if
    m.actionStatus.text = ""
    m.trailerUrl = ""
    m.seasons = invalid
    m.selectedSeasonIndex = 0
    m.xtreamEpisodes = invalid
    m.episodes = invalid
    m.episodeFocus = false
    m.episodeLabel.visible = false
    m.episodeHint.visible = false
    m.trailerButton.visible = false
    m.trailerLabel.visible = false
    m.seasonPanel.visible = false
    m.seasonFocus.visible = false
    m.episodesPanel.visible = false
    m.episodeFocusBar.visible = false
    m.top.findNode("episodeCards").visible = false
    m.episodeOffset = 0
    m.detailFocus = "actions"
    m.watchFocus.visible = true
    if isXtreamSeries() then m.actionStatus.text = "Carregando temporadas…"
    updateCollectionLabels()
end sub

sub updateCollectionLabels()
    if m.top.item = invalid then return
    state = loadLocalState()
    if collectionContains(state.favorites, m.top.item.id) then
        m.listLabel.text = "Na Minha Lista"
    else
        m.listLabel.text = "+ Minha Lista"
    end if
    if collectionContains(state.watch_later, m.top.item.id) then
        m.laterLabel.text = "Na lista: mais tarde"
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
    if isXtreamSeries() and m.seasons <> invalid and m.seasons.count() > 0 then
        handled = handleSeriesKey(key)
        if handled then return true
    end if
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
        if m.xtreamEpisodes <> invalid then
            renderXtreamSeason()
        else
            m.top.seasonRequested = m.seasons[m.selectedSeasonIndex].number
        end if
        return true
    end if
    if key = "up" and m.seasons <> invalid and m.selectedSeasonIndex > 0 then
        m.selectedSeasonIndex = m.selectedSeasonIndex - 1
        updateSeasonSelection()
        if m.xtreamEpisodes <> invalid then
            renderXtreamSeason()
        else
            m.top.seasonRequested = m.seasons[m.selectedSeasonIndex].number
        end if
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
    ' Contorno ciano atras do botao selecionado.
    positions = [64, 324, 604, 914]
    widths = [240, 260, 290, 180]
    m.watchFocus.translation = [positions[m.selectedAction] - 6, 534]
    m.watchFocus.width = widths[m.selectedAction] + 12
end sub

sub runAction()
    if m.top.item = invalid then return
    item = m.top.item
    if m.selectedAction = 0 then
        if isParentallyBlockedItem(item.category, item.id) then
            m.actionStatus.text = "Conteúdo protegido. Valide o PIN em Ajustes para assistir."
        else if isXtreamSeries() then
            ' Serie: "Assistir" toca o episodio selecionado da temporada atual.
            if m.episodes = invalid or m.episodes.count() = 0 then
                m.actionStatus.text = "Carregando episódios…"
            else
                queue = authorizedEpisodeQueue(m.selectedEpisodeIndex)
                if queue.count() > 0 then
                    request = queue[0]
                    request.queue = queue
                    m.top.episodeRequested = request
                end if
            end if
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

function isXtreamSeries() as Boolean
    item = m.top.item
    if item = invalid then return false
    return item.series_id <> invalid and safeTrim(item.series_id) <> ""
end function

sub onSeriesInfoChanged()
    info = m.top.seriesInfo
    if info = invalid or m.top.item = invalid then return
    if safeTrim(info.seriesId) <> safeTrim(m.top.item.series_id) then return
    if info.ok <> true then
        m.actionStatus.text = info.message
        return
    end if
    m.seasons = info.seasons
    m.xtreamEpisodes = info.episodes
    m.selectedSeasonIndex = 0
    m.seriesLabel.visible = true
    m.seasonHint.visible = true
    m.seasonPanel.visible = true
    updateSeasonSelection()
    renderXtreamSeason()
    m.top.findNode("watchLabel").text = "Assistir"
    m.actionStatus.text = ""
end sub

sub renderXtreamSeason()
    if m.seasons = invalid or m.xtreamEpisodes = invalid then return
    season = m.seasons[m.selectedSeasonIndex]
    key = ""
    if season.key <> invalid then key = season.key
    if key = "" then key = str(season.number).Trim()
    list = m.xtreamEpisodes[key]
    if list = invalid then
        return
    end if
    m.episodeFocus = false
    renderEpisodes({ episodes: list })
end sub

' Navegacao das series: acoes -> temporadas -> episodios.
function handleSeriesKey(key as String) as Boolean
    if m.detailFocus = "actions" then
        if key = "down" then
            setDetailFocus("seasons")
            return true
        end if
        return key = "up"
    end if
    if key = "back" then
        setDetailFocus("actions")
        return true
    end if
    if m.detailFocus = "seasons" then
        if key = "left" and m.selectedSeasonIndex > 0 then
            m.selectedSeasonIndex = m.selectedSeasonIndex - 1
            renderXtreamSeason()
            updateSeasonSelection()
        else if key = "right" and m.selectedSeasonIndex < m.seasons.count() - 1 then
            m.selectedSeasonIndex = m.selectedSeasonIndex + 1
            renderXtreamSeason()
            updateSeasonSelection()
        else if key = "up" then
            setDetailFocus("actions")
        else if (key = "down" or key = "OK") and m.episodes <> invalid and m.episodes.count() > 0 then
            setDetailFocus("episodes")
        end if
        return true
    end if
    ' episodios (fileira horizontal)
    if key = "up" then
        setDetailFocus("seasons")
    else if key = "left" and m.selectedEpisodeIndex > 0 then
        m.selectedEpisodeIndex = m.selectedEpisodeIndex - 1
        renderEpisodeSelection()
    else if key = "right" and m.selectedEpisodeIndex < m.episodes.count() - 1 then
        m.selectedEpisodeIndex = m.selectedEpisodeIndex + 1
        renderEpisodeSelection()
    else if key = "OK" then
        queue = authorizedEpisodeQueue(m.selectedEpisodeIndex)
        if queue.count() = 0 then
            m.actionStatus.text = "Este episódio não possui reprodução disponível na sua lista."
        else
            request = queue[0]
            request.queue = queue
            m.top.episodeRequested = request
        end if
    end if
    return true
end function

sub setDetailFocus(zone as String)
    m.detailFocus = zone
    m.episodeFocus = false
    m.watchFocus.visible = zone = "actions"
    m.seasonFocus.visible = zone = "seasons"
    if m.episodes <> invalid then renderEpisodeSelection()
end sub
