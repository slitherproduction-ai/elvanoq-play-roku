' DNS seguro (anti-bloqueio de DNS da operadora) — igual ao Android 2.17.83,
' LG 1.2.5, Samsung 1.2.6, MSX 1.2.12, Whale 1.0.6 e Vega 1.2.4.
'
' So PERGUNTA o IP do servidor (Google, Cloudflare ou Portal). A conexao com o
' servidor da lista continua saindo da Roku, com o IP do cliente (pedido do
' dono do servidor). Nada aqui contata o servidor da lista. Nunca registra URLs.
'
' Fluxo: quando um pedido Xtream falha com -6 (o DNS da internet nao achou o
' nome), ElvDns_Learn (so em Task: usa roUrlTransfer) descobre o IP e guarda no
' registro por 6 h. Enquanto valer, ElvDns_SetUrl e ElvDns_CachedUrl trocam o
' dominio pelo IP (com o cabecalho Host original). So http:// (em https o
' certificado nao bate com o IP). Modo: registro "ElvDns", chave "mode"
' ("off" desliga; qualquer outro valor = automatico).

function ElvDns_Section() as Object
    return CreateObject("roRegistrySection", "ElvDns")
end function

function ElvDns_Enabled() as Boolean
    return ElvDns_Section().Read("mode") <> "off"
end function

function ElvDns_Now() as Integer
    return CreateObject("roDateTime").AsSeconds()
end function

' { protocol, host, port, rest } ou invalid
function ElvDns_ParseUrl(url as String) as Dynamic
    match = CreateObject("roRegex", "^(https?:)//([^/:?#@]+)(:[0-9]+)?(.*)$", "i").Match(url)
    if match.count() < 5 then return invalid
    return { protocol: lcase(match[1]), host: lcase(match[2]), port: match[3], rest: match[4] }
end function

function ElvDns_IsIp(host as String) as Boolean
    return CreateObject("roRegex", "^[0-9]{1,3}(\.[0-9]{1,3}){3}$", "").IsMatch(host)
end function

function ElvDns_Eligible(parts as Dynamic) as Boolean
    if parts = invalid then return false
    if parts.protocol <> "http:" then return false
    if ElvDns_IsIp(parts.host) then return false
    return ElvDns_Enabled()
end function

' IP guardado para o host (valido) ou ""
function ElvDns_CachedIp(host as String) as String
    raw = ElvDns_Section().Read("h:" + host)
    if raw = "" then return ""
    pieces = raw.Split("|")
    if pieces.count() < 2 then return ""
    if pieces[1].ToInt() <= ElvDns_Now() then return ""
    return pieces[0]
end function

' URL pelo IP se o host ja precisou do DNS seguro; senao a propria URL.
function ElvDns_CachedUrl(url as String) as String
    parts = ElvDns_ParseUrl(url)
    if not ElvDns_Eligible(parts) then return url
    ip = ElvDns_CachedIp(parts.host)
    if ip = "" then return url
    return parts.protocol + "//" + ip + parts.port + parts.rest
end function

' "dominio:porta" original (cabecalho Host) ou "" se a URL nao foi trocada.
function ElvDns_HostHeader(original as String, used as String) as String
    if original = used then return ""
    parts = ElvDns_ParseUrl(original)
    if parts = invalid then return ""
    return parts.host + parts.port
end function

' SetUrl com o IP quando o host esta marcado (+ Host original).
sub ElvDns_SetUrl(transfer as Object, url as String)
    used = ElvDns_CachedUrl(url)
    transfer.SetUrl(used)
    hostHeader = ElvDns_HostHeader(url, used)
    if hostHeader <> "" then transfer.AddHeader("Host", hostHeader)
end sub

' Cabecalhos para o ContentNode do video (HttpHeaders) quando a URL foi trocada.
sub ElvDns_ApplyToContent(content as Object, original as String)
    used = ElvDns_CachedUrl(original)
    content.url = used
    hostHeader = ElvDns_HostHeader(original, used)
    if hostHeader <> "" then content.HttpHeaders = ["Host: " + hostHeader]
end sub

function ElvDns_GetJson(url as String, accept as String) as Dynamic
    transfer = CreateObject("roUrlTransfer")
    port = CreateObject("roMessagePort")
    transfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
    transfer.InitClientCertificates()
    transfer.SetUrl(url)
    transfer.SetPort(port)
    if accept <> "" then transfer.AddHeader("Accept", accept)
    if transfer.AsyncGetToString() <> true then return invalid
    event = wait(5000, port)
    if event = invalid or type(event) <> "roUrlEvent" then
        transfer.AsyncCancel()
        return invalid
    end if
    if event.GetResponseCode() <> 200 then return invalid
    return ParseJson(event.GetString())
end function

function ElvDns_IsString(value as Dynamic) as Boolean
    t = type(value)
    return t = "roString" or t = "String"
end function

function ElvDns_UsableIp(ip as Dynamic) as Boolean
    if not ElvDns_IsString(ip) then return false
    if ip = "" or ip = "0.0.0.0" or left(ip, 4) = "127." then return false
    return ElvDns_IsIp(ip)
end function

function ElvDns_IsNumber(value as Dynamic, expected as Integer) as Boolean
    t = type(value)
    if t <> "roInt" and t <> "Integer" and t <> "roFloat" and t <> "Float" and t <> "Double" and t <> "roDouble" and t <> "LongInteger" then return false
    return value = expected
end function

function ElvDns_FromDoh(body as Dynamic) as String
    if type(body) <> "roAssociativeArray" then return ""
    if not ElvDns_IsNumber(body.Status, 0) then return ""
    if type(body.Answer) <> "roArray" then return ""
    for each answer in body.Answer
        if type(answer) = "roAssociativeArray" and ElvDns_IsNumber(answer["type"], 1) and ElvDns_UsableIp(answer.data) then return answer.data
    end for
    return ""
end function

' So em Task. Pergunta o IP (Google -> Cloudflare -> Portal) e guarda por 6 h.
' Devolve o IP ou "".
function ElvDns_Learn(url as String) as String
    parts = ElvDns_ParseUrl(url)
    if not ElvDns_Eligible(parts) then return ""
    name = CreateObject("roUrlTransfer").Escape(parts.host)
    ip = ElvDns_FromDoh(ElvDns_GetJson("https://8.8.8.8/resolve?type=A&name=" + name, ""))
    if ip = "" then ip = ElvDns_FromDoh(ElvDns_GetJson("https://1.1.1.1/dns-query?type=A&name=" + name, "application/dns-json"))
    if ip = "" then
        body = ElvDns_GetJson("https://xrrgjssvdqvtrqhxpask.supabase.co/functions/v1/dns-resolve?name=" + name, "")
        if type(body) = "roAssociativeArray" and type(body.ips) = "roArray" and body.ips.count() > 0 and ElvDns_UsableIp(body.ips[0]) then ip = body.ips[0]
    end if
    if ip = "" then return ""
    section = ElvDns_Section()
    section.Write("h:" + parts.host, ip + "|" + (ElvDns_Now() + 6 * 3600).ToStr())
    section.Flush()
    return ip
end function

' Desfaz a marcacao (o IP tambem nao funcionou).
sub ElvDns_Forget(url as String)
    parts = ElvDns_ParseUrl(url)
    if parts = invalid then return
    section = ElvDns_Section()
    section.Delete("h:" + parts.host)
    section.Flush()
end sub
