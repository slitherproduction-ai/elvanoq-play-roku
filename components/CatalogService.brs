sub init()
    m.top.functionName = "run"
end sub

sub run()
    result = { ok: false, message: "Catálogo indisponível.", channels: [], categories: [] }
    sourceUrl = playlistUrl(m.top.playlist)
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
    result.epgUrl = playlistEpgUrl(m.top.playlist)
    result.message = "Catálogo atualizado."
    m.top.result = result
end sub

function playlistUrl(playlist as Object) as String
    if playlist = invalid or type(playlist) <> "roAssociativeArray" then return ""
    if playlist.url <> invalid and playlist.url <> "" then return playlist.url
    if playlist.credentials = invalid or type(playlist.credentials) <> "roAssociativeArray" then return ""
    credentials = playlist.credentials
    if credentials.url <> invalid and credentials.url <> "" then return credentials.url
    if credentials.host <> invalid and credentials.username <> invalid and credentials.password <> invalid then
        return credentials.host + "/get.php?username=" + credentials.username + "&password=" + credentials.password + "&type=m3u_plus&output=ts"
    end if
    return ""
end function

function playlistEpgUrl(playlist as Object) as String
    if playlist = invalid or type(playlist) <> "roAssociativeArray" then return ""
    if playlist.epg_url <> invalid and playlist.epg_url <> "" then return playlist.epg_url
    if playlist.xmltv_url <> invalid and playlist.xmltv_url <> "" then return playlist.xmltv_url
    if playlist.credentials <> invalid and type(playlist.credentials) = "roAssociativeArray" then
        credentials = playlist.credentials
        if credentials.epg_url <> invalid and credentials.epg_url <> "" then return credentials.epg_url
        if credentials.xmltv_url <> invalid and credentials.xmltv_url <> "" then return credentials.xmltv_url
    end if
    return ""
end function

function parseM3u(body as String) as Object
    items = []
    categories = {}
    pending = invalid
    lines = body.Split(chr(10))
    for each rawLine in lines
        line = trim(rawLine)
        if left(line, 7) = "#EXTINF" then
            pending = {
                title: extinfTitle(line)
                group: extinfAttribute(line, "group-title")
                logo: extinfAttribute(line, "tvg-logo")
                tvg_id: extinfAttribute(line, "tvg-id")
                tvg_name: extinfAttribute(line, "tvg-name")
                added_at: firstExtinfAttribute(line, ["added", "date", "release-date"])
                rating: firstExtinfAttribute(line, ["rating", "tvg-rating", "score"])
                featured: firstExtinfAttribute(line, ["featured", "weekly-featured", "is-featured"])
            }
        else if pending <> invalid and line <> "" and left(line, 1) <> "#" then
            if items.count() < 1500 then
                if pending.group = "" then pending.group = "Sem categoria"
                item = { id: channelLocalId(pending, items.count()), title: pending.title, category: pending.group, logo: pending.logo, tvg_id: pending.tvg_id, tvg_name: pending.tvg_name, added_at: pending.added_at, rating: pending.rating, featured: pending.featured, stream_url: line, type: "live" }
                items.push(item)
                categories[pending.group] = true
            end if
            pending = invalid
        end if
    end for
    names = []
    for each name in categories
        names.push(name)
    end for
    return { items: items, categories: names }
end function

function channelLocalId(pending as Object, position as Integer) as String
    if pending.tvg_id <> invalid and pending.tvg_id <> "" then return "live:" + pending.tvg_id
    identity = pending.group + ":" + pending.title
    if identity <> ":" then return "live:" + identity
    return "live:channel:" + trim(str(position))
end function

function extinfAttribute(line as String, attribute as String) as String
    token = attribute + "=\""
    startAt = instr(1, line, token)
    if startAt = 0 then return ""
    valueStart = startAt + len(token)
    valueEnd = instr(valueStart, line, "\"")
    if valueEnd = 0 then return ""
    return mid(line, valueStart, valueEnd - valueStart)
end function

function firstExtinfAttribute(line as String, attributes as Object) as String
    for each attribute in attributes
        value = extinfAttribute(line, attribute)
        if value <> "" then return value
    end for
    return ""
end function

function extinfTitle(line as String) as String
    commaAt = instr(1, line, ",")
    if commaAt = 0 then return "Canal"
    title = trim(mid(line, commaAt + 1))
    if title = "" then return "Canal"
    return title
end function
