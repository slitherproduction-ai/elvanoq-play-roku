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
    result.mode = m.top.mode

    ' Pedidos sob demanda do AppShell: uma categoria ou uma busca.
    if m.top.mode = "category" or m.top.mode = "search" then
        credentials = m.top.xtream
        if credentials = invalid or credentials.host = invalid then
            result.message = "Lista não conectada."
            m.top.result = result
            return
        end if
        if m.top.mode = "category" then
            loadXtreamCategoryItems(credentials, m.top.kind, m.top.categoryId, m.top.categoryName, result)
        else
            searchXtream(credentials, m.top.query, m.top.categoryNames, m.top.searchToken, m.top.kinds, m.top.titles, result)
        end if
        m.top.result = result
        return
    end if

    ' Listas Xtream sao carregadas pela API, categoria por categoria: baixar o M3U
    ' inteiro estoura a memoria da Roku (EXIT_CHANNEL_MEM_LIMIT_FG).
    credentials = xtreamCredentials(m.top.playlist)
    if credentials <> invalid then
        loadXtreamCatalog(credentials, result)
        result.epgUrl = getPlaylistEpgUrl(m.top.playlist)
        ' Sem XMLTV completo (pode ter centenas de MB): o guia usa get_short_epg por canal.
        m.top.result = result
        return
    end if

    sourceUrl = getPlaylistUrl(m.top.playlist)
    if sourceUrl = "" then
        result.message = "A lista vinculada ainda não possui uma fonte compatível."
        m.top.result = result
        return
    end if

    ' M3U simples: baixa para arquivo e confere o tamanho antes de carregar na memoria.
    tempPath = "tmp:/elvanoq-playlist.m3u"
    DeleteFile(tempPath)
    transfer = CreateObject("roUrlTransfer")
    port = CreateObject("roMessagePort")
    transfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
    transfer.InitClientCertificates()
    transfer.SetMinimumTransferRate(1, 20)
    transfer.SetUrl(sourceUrl)
    transfer.SetPort(port)
    transfer.EnableEncodings(true)

    if transfer.AsyncGetToFile(tempPath) <> true then
        result.message = "Não foi possível iniciar o carregamento do catálogo."
        m.top.result = result
        return
    end if

    event = wait(60000, port)
    if event = invalid or type(event) <> "roUrlEvent" then
        transfer.AsyncCancel()
        DeleteFile(tempPath)
        result.message = "O carregamento do catálogo excedeu o tempo limite."
        m.top.result = result
        return
    end if

    if event.GetResponseCode() < 200 or event.GetResponseCode() >= 300 then
        DeleteFile(tempPath)
        result.message = "O servidor da lista não aceitou a solicitação."
        m.top.result = result
        return
    end if

    fileSystem = CreateObject("roFileSystem")
    info = fileSystem.Stat(tempPath)
    fileSize = 0
    if info <> invalid and info.size <> invalid then fileSize = info.size
    if fileSize > 6000000 then
        DeleteFile(tempPath)
        result.message = "Esta lista M3U é grande demais para a memória da Roku. Use a conexão Xtream (servidor, usuário e senha) no Portal."
        m.top.result = result
        return
    end if

    body = ReadAsciiFile(tempPath)
    DeleteFile(tempPath)
    if body = invalid or body = "" then
        result.message = "A lista retornou vazia."
        m.top.result = result
        return
    end if

    parsed = parseM3u(body)
    body = invalid
    result.ok = true
    result.channels = parsed.items
    result.categories = parsed.categories
    result.epgUrl = getPlaylistEpgUrl(m.top.playlist)
    result.message = "Catálogo atualizado."
    m.top.result = result
end sub

' ---------- Xtream Codes (player_api.php) ----------

function xtreamCredentials(playlist)
    if playlist = invalid or type(playlist) <> "roAssociativeArray" then return invalid
    host = ""
    username = ""
    password = ""
    credentials = playlist.credentials
    if credentials <> invalid and type(credentials) = "roAssociativeArray" then
        if credentials.host <> invalid then host = safeTrim(credentials.host)
        if credentials.username <> invalid then username = safeTrim(credentials.username)
        if credentials.password <> invalid then password = safeTrim(credentials.password)
        if host = "" and credentials.url <> invalid then
            parsed = xtreamFromGetPhp(credentials.url)
            if parsed <> invalid then return parsed
        end if
    end if
    if host = "" and playlist.url <> invalid then
        parsed = xtreamFromGetPhp(playlist.url)
        if parsed <> invalid then return parsed
    end if
    if host = "" or username = "" or password = "" then return invalid
    return makeXtreamCredentials(host, username, password)
end function

function makeXtreamCredentials(host, username, password)
    while right(host, 1) = "/"
        host = left(host, len(host) - 1)
    end while
    lowerHost = lcase(host)
    if left(lowerHost, 7) <> "http://" and left(lowerHost, 8) <> "https://" then host = "http://" + host
    encoder = CreateObject("roUrlTransfer")
    credentials = {}
    credentials.host = host
    credentials.userEscaped = encoder.Escape(username)
    credentials.passEscaped = encoder.Escape(password)
    return credentials
end function

' Reconhece links "http://host:porta/get.php?username=X&password=Y".
function xtreamFromGetPhp(url)
    if url = invalid then return invalid
    value = safeTrim(url)
    marker = instr(1, lcase(value), "/get.php?")
    if marker = 0 then return invalid
    host = left(value, marker - 1)
    query = mid(value, marker + 9)
    username = ""
    password = ""
    for each pair in query.Split("&")
        equalsAt = instr(1, pair, "=")
        if equalsAt > 0 then
            key = lcase(left(pair, equalsAt - 1))
            decoded = CreateObject("roUrlTransfer").Unescape(mid(pair, equalsAt + 1))
            if key = "username" then username = decoded
            if key = "password" then password = decoded
        end if
    end for
    if host = "" or username = "" or password = "" then return invalid
    return makeXtreamCredentials(host, username, password)
end function

function xtreamApi(credentials, action, categoryId)
    url = credentials.host + "/player_api.php?username=" + credentials.userEscaped + "&password=" + credentials.passEscaped
    if action <> "" then url = url + "&action=" + action
    if categoryId <> "" then url = url + "&category_id=" + CreateObject("roUrlTransfer").Escape(categoryId)
    transfer = CreateObject("roUrlTransfer")
    port = CreateObject("roMessagePort")
    transfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
    transfer.InitClientCertificates()
    transfer.SetMinimumTransferRate(1, 20)
    transfer.SetUrl(url)
    transfer.SetPort(port)
    transfer.EnableEncodings(true)
    if transfer.AsyncGetToString() <> true then return invalid
    event = wait(25000, port)
    if event = invalid or type(event) <> "roUrlEvent" then
        transfer.AsyncCancel()
        return invalid
    end if
    if event.GetResponseCode() < 200 or event.GetResponseCode() >= 300 then return invalid
    body = event.GetString()
    if body = invalid or body = "" then return invalid
    return ParseJson(body)
end function

sub loadXtreamCatalog(credentials, result)
    account = xtreamApi(credentials, "", "")
    if account = invalid or type(account) <> "roAssociativeArray" or account.user_info = invalid then
        result.message = "Não foi possível conectar ao servidor da lista."
        return
    end if
    if safeTrim(account.user_info.auth) <> "1" then
        result.message = "Usuário ou senha da lista recusados pelo servidor."
        return
    end if
    liveExtension = "ts"
    formats = account.user_info.allowed_output_formats
    if formats <> invalid and type(formats) = "roArray" then
        for each format in formats
            if lcase(safeTrim(format)) = "m3u8" then liveExtension = "m3u8"
        end for
    end if
    account = invalid
    credentials.liveExtension = liveExtension

    ' Catalogo completo sob demanda: aqui so chegam as listas de categorias (leves).
    ' Os titulos de cada categoria sao baixados quando ela e aberta, sem limite de total.
    liveCategories = xtreamCategoryList(credentials, "get_live_categories")
    movieCategories = xtreamCategoryList(credentials, "get_vod_categories")
    seriesCategories = xtreamCategoryList(credentials, "get_series_categories")
    if liveCategories.count() = 0 and movieCategories.count() = 0 and seriesCategories.count() = 0 then
        result.message = "O servidor não retornou categorias."
        return
    end if

    ' Semente para o Inicio (Novidades): a primeira categoria de filmes e de series.
    items = []
    seedXtreamCategory(credentials, "movies", movieCategories, items, 150)
    seedXtreamCategory(credentials, "series", seriesCategories, items, 150)

    names = []
    for each group in [liveCategories, movieCategories, seriesCategories]
        for each category in group
            names.push(category.name)
        end for
    end for

    result.ok = true
    result.lazy = true
    result.xtream = credentials
    result.liveCategories = liveCategories
    result.movieCategories = movieCategories
    result.seriesCategories = seriesCategories
    result.channels = items
    result.categories = names
    result.message = "Catálogo atualizado."
end sub

function xtreamCategoryList(credentials, action)
    list = []
    categories = xtreamApi(credentials, action, "")
    if categories = invalid or type(categories) <> "roArray" then return list
    for each category in categories
        if type(category) = "roAssociativeArray" then
            categoryId = safeTrim(category.category_id)
            categoryName = safeTrim(category.category_name)
            if categoryName = "" then categoryName = "Sem categoria"
            if categoryId <> "" then list.push({ id: categoryId, name: categoryName })
        end if
    end for
    return list
end function

sub seedXtreamCategory(credentials, kind, categories, items, limit)
    if categories.count() = 0 then return
    first = categories[0]
    loaded = fetchXtreamCategory(credentials, kind, first.id, first.name, limit)
    for each item in loaded
        items.push(item)
    end for
end sub

function fetchXtreamCategory(credentials, kind, categoryId, categoryName, limit)
    items = []
    action = "get_vod_streams"
    if kind = "live" then action = "get_live_streams"
    if kind = "series" then action = "get_series"
    streams = xtreamApi(credentials, action, categoryId)
    if streams = invalid or type(streams) <> "roArray" then return items
    liveExtension = "ts"
    if credentials.liveExtension <> invalid then liveExtension = credentials.liveExtension
    for each stream in streams
        if items.count() >= limit then exit for
        item = xtreamItem(credentials, kind, liveExtension, categoryName, stream)
        if item <> invalid then items.push(item)
    end for
    return items
end function

sub loadXtreamCategoryItems(credentials, kind, categoryId, categoryName, result)
    result.kind = kind
    result.categoryId = categoryId
    items = fetchXtreamCategory(credentials, kind, categoryId, categoryName, 5000)
    result.items = items
    result.ok = true
    result.message = ""
end sub

' ---------- Busca em todo o catalogo ----------
' Baixa a lista completa de cada tipo para o cachefs (uma vez por sessao) e le o
' arquivo em blocos de 256 KB: so os titulos encontrados sao convertidos em itens.

sub searchXtream(credentials, query, categoryNames, token, kinds, titles, result)
    result.query = query
    result.items = []
    needle = lcase(safeTrim(query))
    if needle = "" then
        result.ok = true
        return
    end if
    if kinds = invalid or kinds.count() = 0 then kinds = ["movies", "series", "live"]
    ' Titulos da filmografia do ator (vindos do TMDB pelo Portal), nas duas grafias do JSON.
    matcher = { needle: needle, escaped: jsonEscapedNeedle(needle), titles: [] }
    if titles <> invalid then
        for each title in titles
            plain = lcase(safeTrim(title))
            if len(plain) >= 4 then matcher.titles.push({ plain: plain, escaped: jsonEscapedNeedle(plain) })
        end for
    end if
    cleanupSearchCache(token)
    failed = 0
    for each kind in kinds
        path = searchCachePath(token, kind)
        if ensureSearchFile(credentials, kind, path) then
            names = {}
            if categoryNames <> invalid and categoryNames[kind] <> invalid then names = categoryNames[kind]
            scanSearchFile(path, matcher, kind, credentials, names, result.items, 120)
        else
            failed = failed + 1
        end if
    end for
    result.ok = failed < kinds.count()
    if not result.ok then result.message = "Não foi possível consultar o servidor da lista."
end sub

function searchCachePath(token, kind)
    return "cachefs:/elvanoq-busca-" + token + "-" + kind + ".json"
end function

sub cleanupSearchCache(token)
    fileSystem = CreateObject("roFileSystem")
    listing = fileSystem.GetDirectoryListing("cachefs:/")
    if listing = invalid then return
    for each name in listing
        if left(name, 14) = "elvanoq-busca-" and instr(1, name, "-" + token + "-") = 0 then DeleteFile("cachefs:/" + name)
    end for
end sub

function ensureSearchFile(credentials, kind, path)
    fileSystem = CreateObject("roFileSystem")
    if fileSystem.Exists(path) then return true
    action = "get_vod_streams"
    if kind = "live" then action = "get_live_streams"
    if kind = "series" then action = "get_series"
    url = credentials.host + "/player_api.php?username=" + credentials.userEscaped + "&password=" + credentials.passEscaped + "&action=" + action
    partial = path + ".part"
    DeleteFile(partial)
    transfer = CreateObject("roUrlTransfer")
    port = CreateObject("roMessagePort")
    transfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
    transfer.InitClientCertificates()
    transfer.SetMinimumTransferRate(1, 20)
    transfer.SetUrl(url)
    transfer.SetPort(port)
    transfer.EnableEncodings(true)
    if transfer.AsyncGetToFile(partial) <> true then return false
    event = wait(90000, port)
    if event = invalid or type(event) <> "roUrlEvent" then
        transfer.AsyncCancel()
        DeleteFile(partial)
        return false
    end if
    if event.GetResponseCode() < 200 or event.GetResponseCode() >= 300 then
        DeleteFile(partial)
        return false
    end if
    return fileSystem.Rename(partial, path)
end function

sub scanSearchFile(path, matcher, kind, credentials, names, results, limit)
    needle = matcher.needle
    escapedNeedle = matcher.escaped
    fileSystem = CreateObject("roFileSystem")
    info = fileSystem.Stat(path)
    if info = invalid or info.size = invalid then return
    size = info.size
    nameRegex = CreateObject("roRegex", chr(34) + "name" + chr(34) + ":" + chr(34) + "((?:[^" + chr(34) + "\\]|\\.)*)" + chr(34), "")
    castRegex = CreateObject("roRegex", chr(34) + "cast" + chr(34) + ":" + chr(34) + "((?:[^" + chr(34) + "\\]|\\.)*)" + chr(34), "")
    checkCast = len(needle) >= 3
    liveExtension = "ts"
    if credentials.liveExtension <> invalid then liveExtension = credentials.liveExtension
    bytes = CreateObject("roByteArray")
    chunkSize = 262144
    position = 0
    carry = ""
    while position < size and results.count() < limit
        length = chunkSize
        if position + length > size then length = size - position
        if not bytes.ReadFile(path, position, length) then exit while
        position = position + length
        text = carry + bytes.ToAsciiString()
        parts = text.Split("},{")
        lastIndex = parts.count() - 1
        carry = ""
        if position < size then
            carry = parts[lastIndex]
            lastIndex = lastIndex - 1
        end if
        for index = 0 to lastIndex
            if results.count() >= limit then exit for
            part = parts[index]
            match = nameRegex.Match(part)
            if match.count() > 1 then
                rawName = lcase(match[1])
                found = instr(1, rawName, needle) > 0 or (escapedNeedle <> needle and instr(1, rawName, escapedNeedle) > 0)
                ' Nome do ator no elenco (as series do Xtream costumam trazer "cast").
                if not found and checkCast then
                    castMatch = castRegex.Match(part)
                    if castMatch.count() > 1 then
                        rawCast = lcase(castMatch[1])
                        found = instr(1, rawCast, needle) > 0 or (escapedNeedle <> needle and instr(1, rawCast, escapedNeedle) > 0)
                    end if
                end if
                if not found then
                    for each title in matcher.titles
                        if instr(1, rawName, title.plain) > 0 or (title.escaped <> title.plain and instr(1, rawName, title.escaped) > 0) then
                            found = true
                            exit for
                        end if
                    end for
                end if
                if found then
                    item = searchItemFromPart(part, kind, credentials, liveExtension, names)
                    if item <> invalid then results.push(item)
                end if
            end if
        end for
    end while
end sub

function searchItemFromPart(part, kind, credentials, liveExtension, names)
    ' So o primeiro e o ultimo objeto do arquivo trazem "[{" e "}]"; os do meio ja vem sem chaves.
    body = part
    while len(body) > 0 and (right(body, 1) = chr(10) or right(body, 1) = chr(13) or right(body, 1) = " ")
        body = left(body, len(body) - 1)
    end while
    if left(body, 2) = "[{" then
        body = mid(body, 3)
    else if left(body, 1) = "{" then
        body = mid(body, 2)
    end if
    if right(body, 2) = "}]" then
        body = left(body, len(body) - 2)
    else if right(body, 1) = "}" then
        body = left(body, len(body) - 1)
    end if
    stream = ParseJson("{" + body + "}")
    if stream = invalid or type(stream) <> "roAssociativeArray" then return invalid
    categoryName = "Sem categoria"
    categoryId = safeTrim(stream.category_id)
    if categoryId <> "" and names[categoryId] <> invalid then categoryName = names[categoryId]
    return xtreamItem(credentials, kind, liveExtension, categoryName, stream)
end function

' Servidores PHP costumam enviar acentos como ç: a busca procura dos dois jeitos.
function jsonEscapedNeedle(needle)
    output = ""
    for index = 1 to len(needle)
        character = mid(needle, index, 1)
        code = asc(character)
        if code > 127 and code < 65536 then
            hex = lcase(StrI(code, 16))
            while len(hex) < 4
                hex = "0" + hex
            end while
            output = output + "\u" + hex
        else
            output = output + character
        end if
    end for
    return output
end function

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
        encoder = CreateObject("roUrlTransfer")
        host = credentials.host
        if right(host, 1) = "/" then host = left(host, len(host) - 1)
        return host + "/get.php?username=" + encoder.Escape(credentials.username) + "&password=" + encoder.Escape(credentials.password) + "&type=m3u_plus&output=ts"
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
    counts = {}
    pending = invalid
    lines = body.Split(chr(10))

    for each rawLine in lines
        line = safeTrim(rawLine)
        if left(line, 7) = "#EXTINF" then
            pending = makePendingEntry(line)
        else if pending <> invalid and line <> "" and left(line, 1) <> "#" then
            item = makeCatalogItem(pending, line, items.count())
            if counts[item.type] = invalid then counts[item.type] = 0
            if counts[item.type] < typeLimit(item.type) then
                counts[item.type] = counts[item.type] + 1
                items.push(item)
                if item.type = "live" then
                    groups[item.category] = true
                end if
            end if
            pending = invalid
            if allTypesFull(counts) then exit for
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

function typeLimit(itemType)
    if itemType = "live" then return 1500
    return 1000
end function

function allTypesFull(counts)
    if counts.live = invalid or counts.live < typeLimit("live") then return false
    if counts.movies = invalid or counts.movies < typeLimit("movies") then return false
    if counts.series = invalid or counts.series < typeLimit("series") then return false
    return true
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
    normalized = lcase(safeTrim(value))
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
    return "live:channel:" + safeTrim(str(position))
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
    ' Atributos podem conter virgulas: usa a virgula depois da ultima aspa
    lastQuote = 0
    cursor = 1
    while true
        found = instr(cursor, line, chr(34))
        if found = 0 then exit while
        lastQuote = found
        cursor = found + 1
    end while
    commaAt = instr(lastQuote + 1, line, ",")
    if commaAt = 0 then
        return "Canal"
    end if
    title = safeTrim(mid(line, commaAt + 1))
    if title = "" then
        return "Canal"
    end if
    return title
end function

