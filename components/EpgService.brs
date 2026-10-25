sub init()
    m.top.functionName = "run"
end sub

sub run()
    result = { ok: false, entries: {}, message: "Guia indisponível." }
    if m.top.epgUrl = "" then
        m.top.result = result
        return
    end if
    transfer = CreateObject("roUrlTransfer")
    transfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
    transfer.SetConnectTimeout(10)
    transfer.SetMinimumTransferRate(1, 20)
    transfer.SetUrl(m.top.epgUrl)
    body = transfer.GetToString()
    status = transfer.GetResponseCode()
    if status < 200 or status >= 300 or body = invalid or body = "" then
        m.top.result = result
        return
    end if
    result.ok = true
    result.entries = parseXmltv(body)
    result.message = "Guia carregado."
    m.top.result = result
end sub

function parseXmltv(body as String) as Object
    entries = {}
    cursor = 1
    total = 0
    while total < 1800
        startAt = instr(cursor, body, "<programme")
        if startAt = 0 then exit while
        closeAt = instr(startAt, body, "</programme>")
        if closeAt = 0 then exit while
        openingEnd = instr(startAt, body, ">")
        if openingEnd = 0 then exit while
        opening = mid(body, startAt, openingEnd - startAt + 1)
        channelId = xmlAttribute(opening, "channel")
        startTime = xmlAttribute(opening, "start")
        block = mid(body, openingEnd + 1, closeAt - openingEnd - 1)
        title = xmlTagText(block, "title")
        if channelId <> "" and title <> "" then
            if entries[channelId] = invalid then entries[channelId] = []
            insertProgramme(entries[channelId], { title: title, start: startTime })
            total = total + 1
        end if
        cursor = closeAt + len("</programme>")
    end while
    return entries
end function

sub insertProgramme(programmes as Object, programme as Object)
    if programmes.count() >= 6 then return
    ordered = []
    inserted = false
    for each current in programmes
        if not inserted and programme.start <> "" and current.start <> "" and programme.start < current.start then
            ordered.push(programme)
            inserted = true
        end if
        ordered.push(current)
    end for
    if not inserted then ordered.push(programme)
    programmes.clear()
    for each current in ordered
        if programmes.count() < 6 then programmes.push(current)
    end for
end sub

function xmlAttribute(line as String, attribute as String) as String
    token = attribute + "=\""
    startAt = instr(1, line, token)
    if startAt = 0 then return ""
    valueStart = startAt + len(token)
    valueEnd = instr(valueStart, line, "\"")
    if valueEnd = 0 then return ""
    return mid(line, valueStart, valueEnd - valueStart)
end function

function xmlTagText(block as String, tag as String) as String
    openToken = "<" + tag
    startAt = instr(1, block, openToken)
    if startAt = 0 then return ""
    contentAt = instr(startAt, block, ">")
    if contentAt = 0 then return ""
    endAt = instr(contentAt + 1, block, "</" + tag + ">")
    if endAt = 0 then return ""
    return trim(mid(block, contentAt + 1, endAt - contentAt - 1))
end function
