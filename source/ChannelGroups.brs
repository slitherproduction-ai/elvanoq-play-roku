' Qualidades do mesmo canal numa linha so (Android 2.17.75, channelGroups.ts).
' Canais da mesma categoria cujo nome, tirando as marcas de qualidade (4K, FHD,
' HD, SD, H265, ALT, Backup, Opcao N...), e igual viram uma linha com o nome
' limpo e "N fontes". No player, "Fonte" troca entre elas e, se uma nao abre,
' a proxima e tentada sozinha. Nomes diferentes ("ESPN" e "ESPN 2", "Globo SP"
' e "Globo RJ") continuam separados.

function channelQualityWords() as String
    return "4k|uhd|fhd|full ?hd|hd|sd|hevc|h\.?265|h\.?264|1080p?|720p?|480p?|2160p?|[0-9]{2}fps|alt[0-9]?|alternativo|backup|bkp|reserva|op[cç][aã]o ?[0-9]|opc ?[0-9]"
end function

function channelQualityToken() as Object
    if m.channelQualityTokenRegex = invalid then
        m.channelQualityTokenRegex = CreateObject("roRegex", "(^|[^a-z0-9])(" + channelQualityWords() + ")(?=$|[^a-z0-9])", "i")
    end if
    return m.channelQualityTokenRegex
end function

function channelSuperscriptToken() as Object
    if m.channelSuperscriptRegex = invalid then
        m.channelSuperscriptRegex = CreateObject("roRegex", "ᵁᴴᴰ|ᶠᴴᴰ|ᴴᴰ|ˢᴰ|⁴ᴷ", "")
    end if
    return m.channelSuperscriptRegex
end function

' Nome sem as marcas de qualidade, para comparar canais.
function channelGroupKey(title as Dynamic) as String
    text = lcase(safeTrim(title))
    if text = "" then return ""
    text = channelSuperscriptToken().ReplaceAll(text, " ")
    text = channelQualityToken().ReplaceAll(text, " ")
    if m.channelNonWordRegex = invalid then m.channelNonWordRegex = CreateObject("roRegex", "[^a-z0-9]+", "i")
    return m.channelNonWordRegex.ReplaceAll(text, " ").Trim()
end function

' Nome para mostrar na linha agrupada: o original sem a qualidade.
function channelGroupName(title as Dynamic) as String
    original = safeTrim(title)
    text = channelSuperscriptToken().ReplaceAll(original, " ")
    text = channelQualityToken().ReplaceAll(text, "\1")
    text = CreateObject("roRegex", "[\(\[\{]\s*[\)\]\}]", "").ReplaceAll(text, " ")
    text = CreateObject("roRegex", "\s*[-|:•·/]+\s*$", "").ReplaceAll(text, "")
    text = CreateObject("roRegex", "^\s*[-|:•·/]+\s*", "").ReplaceAll(text, "")
    text = CreateObject("roRegex", "\s{2,}", "").ReplaceAll(text, " ").Trim()
    if text = "" then return original
    return text
end function

' Marca de qualidade (4K, FHD, H265, HD, SD, ALT) ou "".
function channelSourceLabel(title as Dynamic) as String
    text = lcase(safeTrim(title))
    b = "(^|[^a-z0-9])("
    e = ")(?=$|[^a-z0-9])"
    if CreateObject("roRegex", b + "4k|uhd|2160p?" + e + "|⁴ᴷ|ᵁᴴᴰ", "i").IsMatch(text) then return "4K"
    if CreateObject("roRegex", b + "fhd|full ?hd|1080p?" + e + "|ᶠᴴᴰ", "i").IsMatch(text) then return "FHD"
    if CreateObject("roRegex", b + "h\.?265|hevc" + e, "i").IsMatch(text) then return "H265"
    if CreateObject("roRegex", b + "hd|720p?" + e + "|ᴴᴰ", "i").IsMatch(text) then return "HD"
    if CreateObject("roRegex", b + "sd|480p?" + e + "|ˢᴰ", "i").IsMatch(text) then return "SD"
    if CreateObject("roRegex", b + "alt[0-9]?|alternativo|backup|bkp|reserva|op[cç][aã]o ?[0-9]|opc ?[0-9]" + e, "i").IsMatch(text) then return "ALT"
    return ""
end function

' Rotulos unicos na ordem da lista: FHD, HD, HD 2, Fonte 4...
function channelSourceLabels(sources as Object) as Object
    used = {}
    out = []
    for index = 0 to sources.count() - 1
        base = channelSourceLabel(sources[index].title)
        if base = "" then base = "Fonte " + safeTrim(str(index + 1))
        count = 1
        if used[base] <> invalid then count = used[base] + 1
        used[base] = count
        if count > 1 then
            out.push(base + " " + safeTrim(str(count)))
        else
            out.push(base)
        end if
    end for
    return out
end function

' Uma linha por canal, na posicao da primeira fonte. A linha e uma copia da 1a
' fonte com group_title e sources (as fontes, ela incluida). Listas muito grandes
' ficam como estao para nao pesar na navegacao.
function groupChannelRows(list as Object) as Object
    if list = invalid or list.count() < 2 or list.count() > 3000 then return list
    if not joinQualitiesEnabled() then return list
    groups = {}
    order = []
    merged = false
    for each item in list
        key = item.gk
        if key = invalid then
            key = channelGroupKey(item.title)
            item.gk = key
        end if
        if key = "" then
            order.push({ single: item })
        else
            groupId = safeTrim(item.category) + "|" + key
            entry = groups[groupId]
            if entry = invalid then
                entry = { members: [item] }
                groups[groupId] = entry
                order.push(entry)
            else
                entry.members.push(item)
                merged = true
            end if
        end if
    end for
    if not merged then return list
    out = []
    for each entry in order
        if entry.single <> invalid then
            out.push(entry.single)
        else if entry.members.count() = 1 then
            out.push(entry.members[0])
        else
            row = {}
            row.Append(entry.members[0])
            row.group_title = channelGroupName(entry.members[0].title)
            row.sources = entry.members
            out.push(row)
        end if
    end for
    return out
end function

' A linha (ou uma das fontes dela) tem este id?
function channelRowHasId(row as Dynamic, itemId as Dynamic) as Boolean
    if row = invalid or itemId = invalid then return false
    if row.id = itemId then return true
    if row.sources = invalid then return false
    for each source in row.sources
        if source.id = itemId then return true
    end for
    return false
end function

' Proxima fonte ainda nao tentada (tried: { id: true }).
function nextUntriedSource(sources as Dynamic, currentId as Dynamic, tried as Object) as Dynamic
    if sources = invalid or sources.count() < 2 then return invalid
    start = 0
    for index = 0 to sources.count() - 1
        if sources[index].id = currentId then start = index
    end for
    for stepIndex = 1 to sources.count() - 1
        candidate = sources[(start + stepIndex) mod sources.count()]
        if candidate.id <> currentId and tried[safeTrim(candidate.id)] <> true then return candidate
    end for
    return invalid
end function
