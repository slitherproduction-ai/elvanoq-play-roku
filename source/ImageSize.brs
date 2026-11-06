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
