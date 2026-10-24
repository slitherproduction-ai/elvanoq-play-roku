sub init()
    m.poster = m.top.findNode("poster")
    m.title = m.top.findNode("title")
    m.meta = m.top.findNode("meta")
    m.genreLabel = m.top.findNode("genreLabel")
    m.overview = m.top.findNode("overview")
    m.watchFocus = m.top.findNode("watchFocus")
    m.actionStatus = m.top.findNode("actionStatus")
    m.seriesLabel = m.top.findNode("seriesLabel")
    m.seasonHint = m.top.findNode("seasonHint")
    m.episodeLabel = m.top.findNode("episodeLabel")
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
    m.top.findNode("listLabel").font = "font:MediumSystemFont"
    m.top.findNode("laterLabel").font = "font:SmallSystemFont"
    m.actionStatus.font = "font:SmallSystemFont"
    m.actionStatus.color = "0x8FA9C4FF"
    m.seriesLabel.font = "font:SmallSystemFont"
    m.seriesLabel.color = "0xB9CBE0FF"
    m.seasonHint.font = "font:SmallSystemFont"
    m.seasonHint.color = "0x73B7FFFF"
    m.episodeLabel.font = "font:SmallSystemFont"
    m.episodeLabel.color = "0xB9CBE0FF"
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
    if details.trailer <> invalid then m.actionStatus.text = "Trailer oficial disponível."
    if details.recommendations <> invalid and details.recommendations.count() > 0 then m.top.findNode("similarHint").text = recommendationSummary(details.recommendations)
end sub

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
    line = "Episódios: "
    lastIndex = episodes.count() - 1
    if lastIndex > 3 then lastIndex = 3
    for index = 0 to lastIndex
        if index > 0 then line = line + "  •  "
        episode = episodes[index]
        line = line + trim(str(episode.number)) + ". " + episode.name
    end for
    m.episodeLabel.visible = true
    m.episodeLabel.text = line
end sub

sub onItemChanged()
    if m.top.item = invalid then return
    item = m.top.item
    m.title.text = item.title
    m.meta.text = item.category + "  •  Conteúdo da sua lista"
    m.genreLabel.text = ""
    m.overview.text = "Informações complementares, elenco, trailer e recomendações serão exibidos quando os metadados estiverem disponíveis."
    if item.logo <> invalid then m.poster.uri = item.logo
    m.actionStatus.text = ""
    m.seasonPanel.visible = false
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
    if not press then return false
    if key = "back" then
        m.top.closeRequested = true
        return true
    end if
    if key = "right" and m.selectedAction < 2 then
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
    positions = [150, 386, 632]
    widths = [220, 230, 205]
    m.watchFocus.translation = [positions[m.selectedAction], 500]
    m.watchFocus.width = widths[m.selectedAction]
    if m.selectedAction = 0 then m.watchFocus.color = "0xFFFFFFFF" else m.watchFocus.color = "0x2E91EFFF"
end sub

sub runAction()
    if m.top.item = invalid then return
    item = m.top.item
    if m.selectedAction = 0 then
        if isParentallyBlocked(item.category) then
            m.actionStatus.text = "Conteúdo protegido. Valide o PIN em Ajustes para assistir."
        else
            m.top.playRequested = item
        end if
    else if m.selectedAction = 1 then
        state = loadLocalState()
        state.favorites = upsertLocalItem(state.favorites, item)
        saveLocalState(state)
        m.actionStatus.text = "Adicionado aos favoritos."
    else
        state = loadLocalState()
        state.watch_later = upsertLocalItem(state.watch_later, item)
        saveLocalState(state)
        m.actionStatus.text = "Adicionado para assistir mais tarde."
    end if
end sub
