' Montagem dos itens Xtream (compartilhado entre o CatalogService e o AppShell).
' credentials: { host, userEscaped, passEscaped, liveExtension }

function xtreamItem(credentials, itemType, liveExtension, categoryName, stream)
    if stream = invalid or type(stream) <> "roAssociativeArray" then return invalid
    if itemType = "series" then return xtreamSeriesItem(credentials, categoryName, stream)
    streamId = safeTrim(stream.stream_id)
    if streamId = "" then return invalid
    title = safeTrim(stream.name)
    if title = "" then title = "Sem título"
    item = {}
    item.title = title
    item.category = categoryName
    item.logo = safeTrim(stream.stream_icon)
    item.tvg_name = title
    item.added_at = safeTrim(stream.added)
    item.rating = safeTrim(stream.rating)
    item.featured = ""
    item.type = itemType
    base = credentials.host + "/"
    item.stream_id = streamId
    if itemType = "live" then
        item.tvg_id = safeTrim(stream.epg_channel_id)
        ' Mesmo formato de id do carregador M3U, para manter favoritos e bloqueios.
        if item.tvg_id <> "" then
            item.id = "live:" + item.tvg_id
        else
            item.id = "live:" + categoryName + ":" + title
        end if
        item.stream_url = base + "live/" + credentials.userEscaped + "/" + credentials.passEscaped + "/" + streamId + "." + liveExtension
    else
        item.tvg_id = ""
        item.id = "live:" + categoryName + ":" + title
        extension = lcase(safeTrim(stream.container_extension))
        if extension = "" then extension = "mp4"
        item.stream_url = base + "movie/" + credentials.userEscaped + "/" + credentials.passEscaped + "/" + streamId + "." + extension
    end if
    return item
end function

' Serie: sem link direto; os episodios vem do get_series_info ao abrir o detalhe.
function xtreamSeriesItem(credentials, categoryName, stream)
    seriesId = safeTrim(stream.series_id)
    if seriesId = "" then return invalid
    title = safeTrim(stream.name)
    if title = "" then title = "Sem título"
    item = {}
    item.id = "series:" + seriesId
    item.series_id = seriesId
    item.title = title
    item.category = categoryName
    item.logo = safeTrim(stream.cover)
    item.tvg_id = ""
    item.tvg_name = title
    item.added_at = safeTrim(stream.last_modified)
    item.rating = safeTrim(stream.rating)
    item.featured = ""
    item.type = "series"
    item.stream_url = ""
    item.api_url = credentials.host + "/player_api.php?username=" + credentials.userEscaped + "&password=" + credentials.passEscaped
    item.series_base = credentials.host + "/series/" + credentials.userEscaped + "/" + credentials.passEscaped + "/"
    ' Sinopse curta e imagem larga para o destaque do Inicio.
    item.plot = left(safeTrim(stream.plot), 320)
    item.backdrop = ""
    if type(stream.backdrop_path) = "roArray" then
        for each entry in stream.backdrop_path
            candidate = safeTrim(entry)
            if item.backdrop = "" and left(lcase(candidate), 4) = "http" then item.backdrop = candidate
        end for
    end if
    return item
end function

' Recria um item a partir do que fica salvo no Roku (favoritos, continuar, historico),
' para que ele funcione mesmo quando a categoria dele ainda nao foi carregada.
function xtreamItemFromSaved(credentials, saved)
    if credentials = invalid or saved = invalid then return invalid
    if saved.sid = invalid or saved.type = invalid then return invalid
    sid = safeTrim(saved.sid)
    if sid = "" then return invalid
    stream = {}
    stream.name = ""
    if saved.title <> invalid then stream.name = saved.title
    stream.stream_id = sid
    stream.series_id = sid
    stream.stream_icon = ""
    if saved.logo <> invalid then stream.stream_icon = saved.logo
    stream.cover = stream.stream_icon
    stream.container_extension = ""
    if saved.ext <> invalid then stream.container_extension = saved.ext
    stream.epg_channel_id = ""
    if saved.tvg <> invalid then stream.epg_channel_id = saved.tvg
    category = ""
    if saved.category <> invalid then category = saved.category
    liveExtension = "ts"
    if credentials.liveExtension <> invalid and credentials.liveExtension <> "" then liveExtension = credentials.liveExtension
    item = xtreamItem(credentials, saved.type, liveExtension, category, stream)
    if item = invalid then return invalid
    item.id = saved.id
    return item
end function
