' Rever programas (catch-up do Xtream).

function channelHasArchive(item as Object) as Boolean
    if item = invalid or item.stream_url = invalid then return false
    if instr(1, item.stream_url, "/live/") = 0 then return false
    if item.tv_archive = invalid or item.tv_archive_duration = invalid then return false
    return safeTrim(item.tv_archive) = "1" and safeTrim(item.tv_archive_duration).ToInt() > 0
end function

function channelArchiveDays(item as Object) as Integer
    if item = invalid or item.tv_archive_duration = invalid then return 0
    return safeTrim(item.tv_archive_duration).ToInt()
end function

' Os tres formatos mais comuns de servidores Xtream, na ordem em que sao tentados.
' Usuario e senha ja vem codificados do proprio link /live/ do canal.
function catchupUrlsFor(item as Object, programme as Object) as Object
    urls = []
    url = item.stream_url
    liveAt = instr(1, url, "/live/")
    if liveAt = 0 then return urls
    host = left(url, liveAt - 1)
    parts = mid(url, liveAt + 6).Split("/")
    if parts.count() < 3 then return urls
    user = parts[0]
    password = parts[1]
    streamId = safeTrim(item.stream_id)
    if streamId = "" then return urls
    minutes = int((programme.stopSec - programme.startSec + 59) / 60)
    if minutes < 1 then minutes = 1
    duration = minutes.ToStr()
    stamp = catchupLocalStamp(programme.startSec)
    urls.push(host + "/timeshift/" + user + "/" + password + "/" + duration + "/" + programme.startSec.ToStr() + "/" + streamId + ".m3u8")
    urls.push(host + "/timeshift/" + user + "/" + password + "/" + duration + "/" + stamp + "/" + streamId + ".ts")
    urls.push(host + "/streaming/timeshift.php?username=" + user + "&password=" + password + "&stream=" + streamId + "&start=" + stamp + "&duration=" + duration)
    return urls
end function

' AAAA-MM-DD:HH-MM no horario local da TV.
function catchupLocalStamp(seconds as Integer) as String
    dt = CreateObject("roDateTime")
    dt.FromSeconds(seconds)
    dt.ToLocalTime()
    return dt.GetYear().ToStr() + "-" + catchupPad(dt.GetMonth()) + "-" + catchupPad(dt.GetDayOfMonth()) + ":" + catchupPad(dt.GetHours()) + "-" + catchupPad(dt.GetMinutes())
end function

function catchupPad(value as Integer) as String
    text = value.ToStr()
    if len(text) < 2 then text = "0" + text
    return text
end function

' "Hoje 20:00", "Ontem 18:30" ou "Seg 03/11 21:00".
function catchupWhenLabel(seconds as Integer) as String
    dt = CreateObject("roDateTime")
    dt.FromSeconds(seconds)
    dt.ToLocalTime()
    today = CreateObject("roDateTime")
    today.ToLocalTime()
    clock = catchupPad(dt.GetHours()) + ":" + catchupPad(dt.GetMinutes())
    dayStart = today.AsSeconds() - (today.GetHours() * 3600 + today.GetMinutes() * 60 + today.GetSeconds())
    localSeconds = dt.AsSeconds()
    if localSeconds >= dayStart then return "Hoje " + clock
    if localSeconds >= dayStart - 86400 then return "Ontem " + clock
    names = ["Dom", "Seg", "Ter", "Qua", "Qui", "Sex", "Sáb"]
    return names[dt.GetDayOfWeek()] + " " + catchupPad(dt.GetDayOfMonth()) + "/" + catchupPad(dt.GetMonth()) + " " + clock
end function
