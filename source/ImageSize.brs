' Imagens no tamanho em que aparecem na tela.
' Capas do TMDB (inclusive as que vem do servidor Xtream como "original") sao
' pedidas no tamanho certo: menos download, menos decodificacao e menos memoria.

function sizedImageUrl(url as Dynamic, size as String) as String
    if url = invalid then return ""
    text = url
    marker = "image.tmdb.org/t/p/"
    at = instr(1, text, marker)
    if at = 0 then return text
    start = at + len(marker)
    slash = instr(start, text, "/")
    if slash = 0 then return text
    return left(text, start - 1) + size + mid(text, slash)
end function

' Tamanho conforme o uso e o aparelho (Android 2.17.45, features/images/sizedImage.ts).
' Roku de entrada (grafico DirectFB ou interface em 720p) recebe capas menores:
' menos download e menos memoria para decodificar.
'   poster: w185 / w342   detail: w342 / w500   backdrop: w780 / w1280   still: w185 / w300
function sizedImageFor(url as Dynamic, role as String) as String
    sizes = {
        poster: ["w185", "w342"],
        detail: ["w342", "w500"],
        backdrop: ["w780", "w1280"],
        still: ["w185", "w300"]
    }
    choice = sizes[role]
    if choice = invalid then choice = sizes.poster
    if isLowImageTier() then return sizedImageUrl(url, choice[0])
    return sizedImageUrl(url, choice[1])
end function

function isLowImageTier() as Boolean
    if m.lowImageTier <> invalid then return m.lowImageTier
    low = false
    info = CreateObject("roDeviceInfo")
    if info <> invalid then
        if LCase(info.GetGraphicsPlatform()) = "directfb" then low = true
        resolution = info.GetUIResolution()
        if resolution <> invalid and resolution.name <> invalid and UCase(resolution.name) = "HD" then low = true
    end if
    m.lowImageTier = low
    return low
end function
