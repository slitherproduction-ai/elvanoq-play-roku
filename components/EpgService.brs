sub init()
    m.top.functionName = "run"
end sub

sub run()
    result = {}
    result.ok = false
    result.entries = {}
    result.message = "Guia indisponível."

    if m.top.epgUrl = "" then
        m.top.result = result
        return
    end if

    transfer = CreateObject("roUrlTransfer")
    port = CreateObject("roMessagePort")
    transfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
    transfer.SetMinimumTransferRate(1, 20)
    transfer.SetUrl(m.top.epgUrl)
    transfer.SetPort(port)
    transfer.EnableEncodings(true)

    if transfer.AsyncGetToString() <> true then
        m.top.result = result
        return
    end if

    event = wait(30000, port)
    if event = invalid or type(event) <> "roUrlEvent" or event.GetSourceIdentity() <> transfer.GetIdentity() then
        m.top.result = result
        return
    end if
    if event.GetResponseCode() < 200 or event.GetResponseCode() >= 300 then
        m.top.result = result
        return
    end if
    body = event.GetString()
    if body = invalid or body = "" then
        m.top.result = result
        return
    end if

    result.ok = true
    result.entries = parseXmltv(body)
    result.message = "Guia carregado."
    m.top.result = result
end sub

function parseXmltv(body)
    entries = {}
    cursor = 1
    total = 0
    nowSec = CreateObject("roDateTime").AsSeconds()

    while total < 3000
        startAt = instr(cursor, body, "<programme")
        if startAt = 0 then
            exit while
        end if
        closeAt = instr(startAt, body, "</programme>")
        if closeAt = 0 then
            exit while
        end if
        openingEnd = instr(startAt, body, ">")
        if openingEnd = 0 then
            exit while
        end if

        opening = mid(body, startAt, openingEnd - startAt + 1)
        channelId = xmlAttribute(opening, "channel")
        startTime = xmlAttribute(opening, "start")
        startSec = xmltvSeconds(startTime)
        stopSec = xmltvSeconds(xmlAttribute(opening, "stop"))
        if startSec > 0 and stopSec = 0 then stopSec = startSec + 7200
        block = mid(body, openingEnd + 1, closeAt - openingEnd - 1)
        title = xmlTagText(block, "title")

        if channelId <> "" and title <> "" and isRelevantProgramme(startSec, stopSec, nowSec) then
            if entries[channelId] = invalid then
                entries[channelId] = []
            end if
            programme = {}
            programme.title = title
            programme.start = startTime
            programme.startSec = startSec
            insertProgramme(entries[channelId], programme)
            total = total + 1
        end if
        cursor = closeAt + len("</programme>")
    end while
    return entries
end function

sub insertProgramme(programmes, programme)
    if programmes.count() >= 6 then
        return
    end if

    ordered = []
    inserted = false
    for each current in programmes
        if not inserted and programmeBefore(programme, current) then
            ordered.push(programme)
            inserted = true
        end if
        ordered.push(current)
    end for

    if not inserted then
        ordered.push(programme)
    end if
    programmes.clear()
    for each current in ordered
        if programmes.count() < 6 then
            programmes.push(current)
        end if
    end for
end sub

function programmeBefore(a, b)
    if a.startSec <> invalid and b.startSec <> invalid and a.startSec > 0 and b.startSec > 0 then
        return a.startSec < b.startSec
    end if
    if a.start <> "" and b.start <> "" then return a.start < b.start
    return false
end function

function isRelevantProgramme(startSec, stopSec, nowSec)
    if startSec = 0 then return true
    if stopSec <= nowSec then return false
    if startSec > nowSec + 28800 then return false
    return true
end function

function xmltvSeconds(value)
    ' Formato XMLTV: "20261029120000 +0000"
    if value = invalid or len(value) < 14 then return 0
    digits = left(value, 14)
    iso = mid(digits, 1, 4) + "-" + mid(digits, 5, 2) + "-" + mid(digits, 7, 2) + "T" + mid(digits, 9, 2) + ":" + mid(digits, 11, 2) + ":" + mid(digits, 13, 2) + "Z"
    dt = CreateObject("roDateTime")
    dt.FromISO8601String(iso)
    seconds = dt.AsSeconds()
    tail = trim(mid(value, 15))
    if len(tail) >= 5 then
        sign = left(tail, 1)
        if sign = "+" or sign = "-" then
            offsetSeconds = (val(mid(tail, 2, 2)) * 3600) + (val(mid(tail, 4, 2)) * 60)
            if sign = "-" then offsetSeconds = 0 - offsetSeconds
            seconds = seconds - offsetSeconds
        end if
    end if
    return int(seconds)
end function

function xmlAttribute(line, attribute)
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

function xmlTagText(block, tag)
    openToken = "<" + tag
    startAt = instr(1, block, openToken)
    if startAt = 0 then
        return ""
    end if
    contentAt = instr(startAt, block, ">")
    if contentAt = 0 then
        return ""
    end if
    endAt = instr(contentAt + 1, block, "</" + tag + ">")
    if endAt = 0 then
        return ""
    end if
    return trim(mid(block, contentAt + 1, endAt - contentAt - 1))
end function
