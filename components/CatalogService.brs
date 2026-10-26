' Compatibility-first M3U loader. Keep this component free of typed signatures
' and inline multi-field literals so it also compiles on older Roku firmware.
sub init()
    m.top.functionName = "run"
end sub

sub run()
    result = {}
    result.ok = false
    result.message = "Catálogo indisponível."
    result.channels = []
    result.categories = []

    sourceUrl = getPlaylistUrl(m.top.playlist)
    if sourceUrl = "" then
        result.message = "A lista vinculada ainda não possui uma fonte compatível."
        m.top.result = result
        return
    end if

    transfer = CreateObject("roUrlTransfer")
    transfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
    transfer.SetConnectTimeout(10)
    transfer.SetMinimumTransferRate(1, 20)
    transfer.SetUrl(sourceUrl)
    body = transfer.GetToString()
    status = transfer.GetResponseCode()

    if status < 200 or status >= 300 or body = invalid or body = "" then
        result.message = "Não foi possível atualizar o catálogo agora."
        m.top.result = result
        return
    end if

    parsed = parseM3u(body)
    result.ok = true
    result.channels = parsed.items
    result.categories = parsed.categories
    result.epgUrl = getPlaylistEpgUrl(m.top.playlist)
    result.message = "Catálogo atualizado."
    m.top.result = result
end sub

function getPlaylistUrl(playlist)
    if playlist = invalid then
        return ""
    end if
    if type(playlist) <> "roAssociativeArray" then
        return ""
    end if
    if playlist.url <> invalid and playlist.url <> "" then
        return playlist.url
    end if
    if playlist.credentials = invalid then
        return ""
    end if
    if type(playlist.credentials) <> "roAssociativeArray" then
        return ""
    end if

    credentials = playlist.credentials
    if credentials.url <> invalid and credentials.url <> "" then
        return credentials.url
    end if
    if credentials.host <> invalid and credentials.username <> invalid and credentials.password <> invalid then
        return credentials.host + "/get.php?username=" + credentials.username + "&password=" + credentials.password + "&type=m3u_plus&output=ts"
    end if
    return ""
end function

function getPlaylistEpgUrl(playlist)
    if playlist = invalid or type(playlist) <> "roAssociativeArray" then
        return ""
    end if
    if playlist.epg_url <> invalid and playlist.epg_url <> "" then
        return playlist.epg_url
    end if
    if playlist.xmltv_url <> invalid and playlist.xmltv_url <> "" then
        return playlist.xmltv_url
    end if
    if playlist.credentials = invalid or type(playlist.credentials) <> "roAssociativeArray" then
        return ""
    end if

    credentials = playlist.credentials
    if credentials.epg_url <> invalid and credentials.epg_url <> "" then
        return credentials.epg_url
    end if
    if credentials.xmltv_url <> invalid and credentials.xmltv_url <> "" then
        return credentials.xmltv_url
    end if
    return ""
end function

function parseM3u(body)
    items = []
    groups = {}
    pending = invalid
    lines = body.Split(chr(10))

    for each rawLine in lines
        line = trim(rawLine)
        if left(line, 7) = "#EXTINF" then
            pending = makePendingEntry(line)
        else if pending <> invalid and line <> "" and left(line, 1) <> "#" then
            if items.count() < 1500 then
                item = makeCatalogItem(pending, line, items.count())
                items.push(item)
                if item.type = "live" then
                    groups[item.category] = true
                end if
            end if
            pending = invalid
        end if
    end for

    categories = []
    for each groupName in groups
        categories.push(groupName)
    end for

    parsed = {}
    parsed.items = items
    parsed.categories = categories
    return parsed
end function

function makePendingEntry(line)
    entry = {}
    entry.title = extinfTitle(line)
    entry.group = extinfAttribute(line, "group-title")
    entry.logo = extinfAttribute(line, "tvg-logo")
    entry.tvg_id = extinfAttribute(line, "tvg-id")
    entry.tvg_name = extinfAttribute(line, "tvg-name")
    entry.added_at = firstExtinfAttribute(line, ["added", "date", "release-date"])
    entry.rating = firstExtinfAttribute(line, ["rating", "tvg-rating", "score"])
    entry.featured = firstExtinfAttribute(line, ["featured", "weekly-featured", "is-featured"])
    entry.content_type = firstExtinfAttribute(line, ["content-type", "content_type", "media-type", "media_type", "tvg-type", "tvg_type", "type", "category-type"])
    return entry
end function

function makeCatalogItem(pending, streamUrl, position)
    groupName = pending.group
    if groupName = "" then
        groupName = "Sem categoria"
    end if

    item = {}
    item.id = channelLocalId(pending, groupName, position)
    item.title = pending.title
    item.category = groupName
    item.logo = pending.logo
    item.tvg_id = pending.tvg_id
    item.tvg_name = pending.tvg_name
    item.added_at = pending.added_at
    item.rating = pending.rating
    item.featured = pending.featured
    item.stream_url = streamUrl
    item.type = contentTypeForEntry(pending, groupName)
    return item
end function

function contentTypeForEntry(pending, groupName)
    explicitType = normalizedContentType(pending.content_type)
    if explicitType <> "" then
        return explicitType
    end if

    inferredType = normalizedContentType(groupName)
    if inferredType <> "" then
        return inferredType
    end if
    return "live"
end function

function normalizedContentType(value)
    normalized = lcase(trim(value))
    if normalized = "" then
        return ""
    end if

    if normalized = "series" or normalized = "serie" or normalized = "series tv" or normalized = "tv shows" or normalized = "show" or normalized = "shows" then
        return "series"
    end if
    if normalized = "movie" or normalized = "movies" or normalized = "film" or normalized = "films" or normalized = "vod" then
        return "movies"
    end if
    if normalized = "live" or normalized = "live tv" or normalized = "tv" or normalized = "channel" or normalized = "channels" then
        return "live"
    end if

    if instr(1, normalized, "série") > 0 or instr(1, normalized, "serie") > 0 or instr(1, normalized, "tv show") > 0 then
        return "series"
    end if
    if instr(1, normalized, "filme") > 0 or instr(1, normalized, "movie") > 0 or instr(1, normalized, "film") > 0 or instr(1, normalized, "vod") > 0 then
        return "movies"
    end if
    if instr(1, normalized, "ao vivo") > 0 or instr(1, normalized, "ao-vivo") > 0 or instr(1, normalized, "live") > 0 then
        return "live"
    end if
    return ""
end function

function channelLocalId(pending, groupName, position)
    if pending.tvg_id <> invalid and pending.tvg_id <> "" then
        return "live:" + pending.tvg_id
    end if
    identity = groupName + ":" + pending.title
    if identity <> ":" then
        return "live:" + identity
    end if
    return "live:channel:" + trim(str(position))
end function

function extinfAttribute(line, attribute)
    token = attribute + "=" + chr(34)
    startAt = instr(1, line, token)
    if startAt = 0 then
        return ""
    end if
    valueStart = startAt + len(token)
    valueEnd = instr(valueStart, line, chr(34))
    if valueEnd = 0 then
        return ""
    end if
    return mid(line, valueStart, valueEnd - valueStart)
end function

function firstExtinfAttribute(line, attributes)
    for each attribute in attributes
        value = extinfAttribute(line, attribute)
        if value <> "" then
            return value
        end if
    end for
    return ""
end function

function extinfTitle(line)
    commaAt = instr(1, line, ",")
    if commaAt = 0 then
        return "Canal"
    end if
    title = trim(mid(line, commaAt + 1))
    if title = "" then
        return "Canal"
    end if
    return title
end function
