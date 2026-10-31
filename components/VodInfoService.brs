' Imagem larga (backdrop) e sinopse de um filme Xtream, para o destaque do Inicio.
sub init()
    m.top.functionName = "run"
end sub

sub run()
    result = {}
    result.itemId = m.top.itemId
    result.backdrop = ""
    result.plot = ""
    url = m.top.streamUrl
    movieAt = instr(1, url, "/movie/")
    if movieAt = 0 then
        m.top.result = result
        return
    end if
    host = left(url, movieAt - 1)
    parts = mid(url, movieAt + 7).Split("/")
    if parts.count() < 3 then
        m.top.result = result
        return
    end if
    vodId = parts[2]
    dotAt = instr(1, vodId, ".")
    if dotAt > 0 then vodId = left(vodId, dotAt - 1)

    transfer = CreateObject("roUrlTransfer")
    port = CreateObject("roMessagePort")
    transfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
    transfer.InitClientCertificates()
    transfer.SetMinimumTransferRate(1, 15)
    transfer.SetUrl(host + "/player_api.php?username=" + parts[0] + "&password=" + parts[1] + "&action=get_vod_info&vod_id=" + vodId)
    transfer.SetPort(port)
    transfer.EnableEncodings(true)
    if transfer.AsyncGetToString() = true then
        event = wait(15000, port)
        if type(event) = "roUrlEvent" and event.GetResponseCode() = 200 then
            json = ParseJson(event.GetString())
            if json <> invalid and type(json) = "roAssociativeArray" and json.info <> invalid and type(json.info) = "roAssociativeArray" then
                info = json.info
                result.backdrop = firstImage(info.backdrop_path)
                result.plot = safeTrim(info.plot)
                if result.plot = "" then result.plot = safeTrim(info.description)
            end if
        else
            transfer.AsyncCancel()
        end if
    end if
    m.top.result = result
end sub

' backdrop_path pode vir como lista ou como texto.
function firstImage(value)
    if value = invalid then return ""
    if type(value) = "roArray" then
        for each entry in value
            candidate = safeTrim(entry)
            if left(lcase(candidate), 4) = "http" then return candidate
        end for
        return ""
    end if
    candidate = safeTrim(value)
    if left(lcase(candidate), 4) = "http" then return candidate
    return ""
end function
