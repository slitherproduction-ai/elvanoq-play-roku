function streamFormatForUrl(streamUrl as String) as String
    url = lcase(streamUrl)
    if instr(1, url, "output=m3u8") > 0 then return "hls"
    path = url
    queryAt = instr(1, url, "?")
    if queryAt > 0 then path = left(url, queryAt - 1)
    if right(path, 5) = ".m3u8" then return "hls"
    if right(path, 4) = ".mpd" then return "dash"
    if right(path, 4) = ".mkv" then return "mkv"
    if right(path, 4) = ".mp4" then return "mp4"
    if instr(1, path, ".m3u8") > 0 then return "hls"
    return ""
end function
