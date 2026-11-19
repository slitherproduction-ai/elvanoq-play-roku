' Hora certa para o guia com o relogio do aparelho errado (Android 2.17.75,
' serverClock.ts). A diferenca (m.global.clockOffset, em segundos) e calculada
' pelo CatalogService: cabecalho HTTP Date de duas respostas que concordam ou,
' sem ele, timestamp_now da conta Xtream (ignorado quando a diferenca e um
' numero quase exato de horas). Menos de 2 min: o aparelho esta certo.

function serverNowSeconds() as Integer
    now = CreateObject("roDateTime").AsSeconds()
    offset = 0
    if m.global <> invalid then
        value = m.global.clockOffset
        if value <> invalid then offset = value
    end if
    return now + offset
end function

' "Thu, 19 Nov 2026 12:34:56 GMT" -> segundos UTC (0 se invalido).
function parseHttpDate(header as Dynamic) as Integer
    text = safeTrim(header)
    if text = "" then return 0
    parts = text.Split(" ")
    if parts.count() < 5 then return 0
    months = { jan: "01", feb: "02", mar: "03", apr: "04", may: "05", jun: "06", jul: "07", aug: "08", sep: "09", oct: "10", nov: "11", dec: "12" }
    month = months[lcase(left(parts[2], 3))]
    if month = invalid then return 0
    day = parts[1]
    if len(day) = 1 then day = "0" + day
    dt = CreateObject("roDateTime")
    dt.FromISO8601String(parts[3] + "-" + month + "-" + day + "T" + parts[4] + "Z")
    seconds = dt.AsSeconds()
    if seconds < 1704067200 then return 0
    return seconds
end function

' Diferenca a aplicar (segundos). headerOffsets: diferencas pelo cabecalho Date
' das respostas, na ordem; timestampNow: server_info.timestamp_now.
function computeClockOffset(headerOffsets as Object, timestampNow as Dynamic, receivedAt as Integer) as Integer
    if headerOffsets.count() >= 2 then
        a = headerOffsets[headerOffsets.count() - 2]
        b = headerOffsets[headerOffsets.count() - 1]
        if abs(a - b) <= 30 then
            if abs(b) < 120 then return 0
            return b
        end if
    end if
    value = safeTrim(timestampNow).ToInt()
    if value < 1704067200 then return 0
    candidate = value - receivedAt
    if abs(candidate) < 120 then return 0
    hours = int(candidate / 3600 + 0.5)
    if candidate < 0 then hours = -int(-candidate / 3600 + 0.5)
    if hours <> 0 and abs(hours) <= 14 and abs(candidate - hours * 3600) < 120 then return 0
    return candidate
end function
