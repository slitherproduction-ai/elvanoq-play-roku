'Temporadas e episodios de uma serie Xtream (get_series_info).
sub init()
    m.top.functionName = "run"
end sub

sub run()
    result = {}
    result.ok = false
    result.seriesId = m.top.seriesId
    result.message = "Não foi possível carregar os episódios."
    result.seasons = []
    result.episodes = {}
    if m.top.apiUrl = "" or m.top.seriesId = "" then
        m.top.result = result
        return
    end if

    transfer = CreateObject("roUrlTransfer")
    port = CreateObject("roMessagePort")
    transfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
    transfer.InitClientCertificates()
    transfer.SetMinimumTransferRate(1, 20)
    transfer.SetUrl(m.top.apiUrl + "&action=get_series_info&series_id=" + m.top.seriesId)
    transfer.SetPort(port)
    transfer.EnableEncodings(true)
    if transfer.AsyncGetToString() <> true then
        m.top.result = result
        return
    end if
    event = wait(25000, port)
    if event = invalid or type(event) <> "roUrlEvent" then
        transfer.AsyncCancel()
        m.top.result = result
        return
    end if
    if event.GetResponseCode() < 200 or event.GetResponseCode() >= 300 then
        m.top.result = result
        return
    end if
    json = ParseJson(event.GetString())
    if json = invalid or type(json) <> "roAssociativeArray" or json.episodes = invalid then
        result.message = "Esta série não tem episódios na sua lista."
        m.top.result = result
        return
    end if

    ' "episodes" vem como objeto {"1": [...], "2": [...]} ou como lista de listas.
    groups = []
    if type(json.episodes) = "roAssociativeArray" then
        for each seasonKey in json.episodes
            groups.push({ number: seasonKey.ToInt(), key: seasonKey.Trim(), list: json.episodes[seasonKey] })
        end for
    else if type(json.episodes) = "roArray" then
        position = 1
        for each list in json.episodes
            seasonNumber = position
            if type(list) = "roArray" and list.count() > 0 and type(list[0]) = "roAssociativeArray" and list[0].season <> invalid then seasonNumber = safeTrim(list[0].season).ToInt()
            groups.push({ number: seasonNumber, key: str(seasonNumber).Trim(), list: list })
            position = position + 1
        end for
    end if
    groups.SortBy("number")

    seasons = []
    episodes = {}
    for each group in groups
        if type(group.list) = "roArray" and group.list.count() > 0 then
            entries = []
            for each episode in group.list
                if type(episode) = "roAssociativeArray" then
                    episodeId = safeTrim(episode.id)
                    if episodeId <> "" then
                        extension = lcase(safeTrim(episode.container_extension))
                        if extension = "" then extension = "mp4"
                        entry = {}
                        entry.number = safeTrim(episode.episode_num).ToInt()
                        entry.name = safeTrim(episode.title)
                        if entry.name = "" then entry.name = "Episódio " + safeTrim(episode.episode_num)
                        entry.stream_url = m.top.seriesBase + episodeId + "." + extension
                        entry.image = ""
                        if type(episode.info) = "roAssociativeArray" then
                            image = safeTrim(episode.info.movie_image)
                            if left(lcase(image), 4) = "http" then entry.image = image
                        end if
                        entries.push(entry)
                    end if
                end if
            end for
            if entries.count() > 0 then
                key = group.key
                episodes[key] = entries
                season = {}
                season.number = group.number
                season.key = key
                season.name = "Temporada " + key
                season.episode_count = entries.count()
                seasons.push(season)
            end if
        end if
    end for

    if seasons.count() = 0 then
        result.message = "Esta série não tem episódios na sua lista."
        m.top.result = result
        return
    end if
    result.ok = true
    result.seasons = seasons
    result.episodes = episodes
    result.message = "Episódios carregados."
    m.top.result = result
end sub
