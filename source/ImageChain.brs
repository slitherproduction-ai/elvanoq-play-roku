' Imagens com reserva (Android 2.17.68, features/images/fallbackImage.tsx).
' Em algumas redes o servidor de imagens do TMDB (image.tmdb.org) nao
' responde, enquanto a API funciona. Cada endereco do TMDB ganha o mesmo
' arquivo no outro servidor do TMDB (media.themoviedb.org) e, depois, as
' imagens seguintes da lista. A troca so acontece quando a anterior falha.
' Quem inclui este arquivo define imageChainExhausted(node).

function tmdbMirrorUrl(url as Dynamic) as String
    if url = invalid then return ""
    marker = "://image.tmdb.org/"
    at = instr(1, url, marker)
    if at = 0 then return ""
    return left(url, at - 1) + "://media.themoviedb.org/" + mid(url, at + len(marker))
end function

function isTmdbImage(url as Dynamic) as Boolean
    return url <> invalid and instr(1, url, "image.tmdb.org/t/p/") > 0
end function

function imageCandidates(urls as Object) as Object
    out = []
    seen = {}
    for each url in urls
        if url <> invalid and url <> "" then
            for each candidate in [url, tmdbMirrorUrl(url)]
                if candidate <> "" and seen[candidate] = invalid then
                    seen[candidate] = true
                    out.push(candidate)
                end if
            end for
        end if
    end for
    return out
end function

sub setImageChain(node as Object, urls as Object)
    if m.imageChains = invalid then m.imageChains = {}
    candidates = imageCandidates(urls)
    m.imageChains[node.id] = { urls: candidates, index: 0 }
    if m.imageChainObserved = invalid then m.imageChainObserved = {}
    if m.imageChainObserved[node.id] = invalid then
        node.observeField("loadStatus", "onImageChainStatus")
        m.imageChainObserved[node.id] = true
    end if
    if candidates.count() = 0 then
        node.uri = ""
        imageChainExhausted(node)
    else
        node.uri = candidates[0]
    end if
end sub

sub onImageChainStatus(event as Object)
    if event.getData() <> "failed" then return
    node = event.getRoSGNode()
    chain = m.imageChains[node.id]
    if chain = invalid then return
    chain.index = chain.index + 1
    if chain.index < chain.urls.count() then
        node.uri = chain.urls[chain.index]
    else
        node.uri = ""
        imageChainExhausted(node)
    end if
end sub
