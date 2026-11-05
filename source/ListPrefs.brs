' Preferencias guardadas por lista (servidor): categorias ocultas e formato do ao vivo.
' Tudo fica no registry da TV; nada e apagado da lista.

' Identificador da lista ativa: codigo do servidor, ou o endereco do servidor
' (sem usuario/senha), ou "default".
function listScopeId() as String
    section = CreateObject("roRegistrySection", "ELVANOQPlay")
    metadata = ParseJson(section.Read("playlist_metadata"))
    raw = "default"
    if metadata <> invalid and type(metadata) = "roAssociativeArray" then
        if metadata.server_code <> invalid and metadata.server_code <> "" then
            raw = "c_" + metadata.server_code
        else if metadata.scope <> invalid and metadata.scope <> "" then
            raw = "h_" + metadata.scope
        end if
    end if
    clean = ""
    for index = 1 to len(raw)
        character = mid(raw, index, 1)
        code = asc(character)
        if (code >= 48 and code <= 57) or (code >= 65 and code <= 90) or (code >= 97 and code <= 122) or character = "_" then
            clean = clean + character
        else
            clean = clean + "_"
        end if
        if len(clean) >= 48 then exit for
    end for
    return clean
end function

' ---------- Categorias visiveis ----------
' Formato: { live: ["id", ...], movies: [...], series: [...] }. Para listas M3U
' (sem id de categoria) o id e o proprio nome da categoria.

function hiddenCategoriesKey() as String
    return "hidden_cats_" + listScopeId()
end function

function loadHiddenCategories() as Object
    hidden = { live: [], movies: [], series: [] }
    raw = CreateObject("roRegistrySection", "ELVANOQPlay").Read(hiddenCategoriesKey())
    if raw = "" then return hidden
    parsed = ParseJson(raw)
    if parsed = invalid or type(parsed) <> "roAssociativeArray" then return hidden
    for each kind in ["live", "movies", "series"]
        if type(parsed[kind]) = "roArray" then hidden[kind] = parsed[kind]
    end for
    return hidden
end function

sub saveHiddenCategories(hidden as Object)
    section = CreateObject("roRegistrySection", "ELVANOQPlay")
    section.Write(hiddenCategoriesKey(), FormatJson(hidden))
    section.Flush()
end sub

' Conjunto (assocarray) de ids ocultos de um tipo: busca direta, sem lacos aninhados.
function hiddenCategorySet(kind as String) as Object
    lookup = {}
    lookup.SetModeCaseSensitive()
    hidden = loadHiddenCategories()
    if type(hidden[kind]) = "roArray" then
        for each categoryId in hidden[kind]
            lookup[categoryId] = true
        end for
    end if
    return lookup
end function

' ---------- Formato do ao vivo ----------

' "auto" (padrao), "hls" ou "ts".
function liveFormatPreference() as String
    value = CreateObject("roRegistrySection", "ELVANOQPlay").Read("live_format_pref")
    if value = "hls" or value = "ts" then return value
    return "auto"
end function

sub saveLiveFormatPreference(value as String)
    section = CreateObject("roRegistrySection", "ELVANOQPlay")
    section.Write("live_format_pref", value)
    section.Flush()
end sub

function liveFormatLabel(value as String) as String
    if value = "hls" then return "HLS (.m3u8)"
    if value = "ts" then return "TS (.ts)"
    return "Automático"
end function

function liveFormatOfUrl(url as String) as String
    lower = lcase(url)
    query = instr(1, lower, "?")
    if query > 0 then lower = left(lower, query - 1)
    if right(lower, 5) = ".m3u8" then return "hls"
    if right(lower, 3) = ".ts" then return "ts"
    return ""
end function

' Troca a extensao de um link /live/ do Xtream para o formato pedido.
function liveUrlWithFormat(url as String, format as String) as String
    if instr(1, url, "/live/") = 0 then return url
    current = liveFormatOfUrl(url)
    if current = "" or current = format then return url
    if current = "hls" then base = left(url, len(url) - 5) else base = left(url, len(url) - 3)
    if format = "hls" then return base + ".m3u8"
    return base + ".ts"
end function

' Formato para abrir agora: a escolha manual sempre vence; no Automatico, o
' ultimo formato que abriu de fato nesta lista.
function preferredLiveUrl(url as String) as String
    preference = liveFormatPreference()
    if preference <> "auto" then return liveUrlWithFormat(url, preference)
    remembered = CreateObject("roRegistrySection", "ELVANOQPlay").Read("liveFormat_" + listScopeId())
    if remembered = "hls" or remembered = "ts" then return liveUrlWithFormat(url, remembered)
    return url
end function

sub rememberWorkingLiveFormat(url as String)
    if liveFormatPreference() <> "auto" then return
    if instr(1, url, "/live/") = 0 then return
    format = liveFormatOfUrl(url)
    if format = "" then return
    section = CreateObject("roRegistrySection", "ELVANOQPlay")
    key = "liveFormat_" + listScopeId()
    if section.Read(key) = format then return
    section.Write(key, format)
    section.Flush()
end sub
