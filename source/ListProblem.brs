' Janela "A lista nao abriu" (canvas "ELVANOQ Play TV", tela 4): motivo em
' titulo, o que foi verificado e o que fazer, a partir das mensagens do
' CatalogService. Mesmas regras do Android, do Vega e da LG (listProblem).
function listProblemCheck(label as String, detail as String, state as String) as Object
    return { label: label, detail: detail, state: state }
end function

function listProblem(raw as Dynamic) as Object
    message = ""
    if raw <> invalid then message = raw.ToStr().Trim()
    lower = LCase(message)
    internetOk = listProblemCheck("Internet", "O Roku está online", "ok")
    addressOk = listProblemCheck("Endereço", "Existe no DNS público", "ok")
    serverOk = listProblemCheck("Servidor", "Respondeu", "ok")
    if Instr(1, lower, "não encontrou o servidor da lista, mas ele existe") > 0 then
        return { kind: "dnsBlocked", title: "Bloqueio provável da operadora", message: "O endereço do servidor existe, mas o DNS da sua internet não o encontrou. Costuma ser bloqueio da operadora.", advice: "Troque o DNS do roteador (por exemplo 1.1.1.1 ou 8.8.8.8). Se não resolver, fale com a sua revenda.", checks: [internetOk, addressOk, listProblemCheck("DNS da internet", "Não encontrou o servidor", "fail")], primary: "retry" }
    end if
    if Instr(1, lower, "endereço do servidor da lista não existe") > 0 then
        return { kind: "notFound", title: "Endereço do servidor não existe", message: "O nome do servidor da lista não foi encontrado em nenhum DNS. O endereço pode estar errado ou ter sido desativado.", advice: "Confira o endereço com a sua revenda.", checks: [listProblemCheck("Internet", "O Roku está online", "ok"), listProblemCheck("Endereço", "Não existe", "fail"), listProblemCheck("Conexão", "Não testada", "unknown")], primary: "retry" }
    end if
    if Instr(1, lower, "está sem internet") > 0 then
        return { kind: "offline", title: "Roku sem internet", message: "Nem o servidor da lista nem o DNS público responderam.", advice: "Confira o Wi-Fi ou o cabo de rede e tente de novo.", checks: [listProblemCheck("Internet", "Sem conexão", "fail"), listProblemCheck("Endereço", "Não testado", "unknown"), listProblemCheck("Conexão", "Não testada", "unknown")], primary: "retry" }
    end if
    if Instr(1, lower, "servidor da lista não respondeu") > 0 then
        return { kind: "unreachable", title: "O servidor não respondeu", message: "O endereço do servidor existe, mas a conexão não abriu. Ele pode estar fora do ar ou bloqueado pela operadora.", advice: "Tente mais tarde. Se continuar, troque o DNS do roteador (1.1.1.1 ou 8.8.8.8) ou fale com a sua revenda.", checks: [internetOk, addressOk, listProblemCheck("Conexão", "Sem resposta do servidor", "fail")], primary: "retry" }
    end if
    expired = CreateObject("roRegex", "a lista venceu(?: em ([0-9]{1,4}(?:[./-][0-9]{1,4}){2}))?", "i").Match(message)
    if expired.count() > 0 then
        text = "A conta desta lista está vencida no servidor."
        if expired.count() > 1 and expired[1] <> "" then text = "A conta desta lista venceu em " + expired[1] + "."
        return { kind: "expired", title: "A lista venceu", message: text, advice: "Fale com a sua revenda para renovar. Depois, é só tentar de novo.", checks: [internetOk, serverOk, listProblemCheck("Conta", "Vencida", "fail")], primary: "retry" }
    end if
    if Instr(1, lower, "bloqueada no servidor") > 0 then
        return { kind: "blockedAccount", title: "A lista está bloqueada", message: "O servidor respondeu, mas a conta desta lista está bloqueada ou desativada.", advice: "Fale com a sua revenda.", checks: [internetOk, serverOk, listProblemCheck("Conta", "Bloqueada", "fail")], primary: "retry" }
    end if
    if Instr(1, lower, "recusou o usuário e a senha") > 0 then
        return { kind: "refused", title: "Usuário ou senha recusados", message: "O servidor respondeu, mas não aceitou o usuário e a senha desta lista.", advice: "Confira os dados da lista. Se estiverem certos, fale com a sua revenda.", checks: [internetOk, serverOk, listProblemCheck("Conta", "Dados recusados", "fail")], primary: "retry" }
    end if
    http = CreateObject("roRegex", "\(HTTP ([0-9]{3})\)", "").Match(message)
    if http.count() > 1 then
        code = http[1]
        if code = "401" or code = "403" then
            return { kind: "denied", title: "O servidor recusou o acesso", message: "O servidor respondeu, mas recusou o acesso (HTTP " + code + ").", advice: "Confira o usuário e a senha da lista ou fale com a sua revenda.", checks: [internetOk, serverOk, listProblemCheck("Acesso", "Recusado (HTTP " + code + ")", "fail")], primary: "retry" }
        end if
        if Val(code) >= 500 then
            return { kind: "serverDown", title: "Servidor fora do ar", message: "O servidor da lista está fora do ar ou sobrecarregado (HTTP " + code + ").", advice: "Tente novamente em alguns minutos. Se continuar, fale com a sua revenda.", checks: [internetOk, listProblemCheck("Endereço", "Encontrado", "ok"), listProblemCheck("Servidor", "Erro HTTP " + code, "fail")], primary: "retry" }
        end if
    end if
    if Instr(1, lower, "não é uma lista") > 0 then
        return { kind: "invalid", title: "A resposta não é uma lista", message: "O endereço respondeu, mas não com uma lista IPTV. O endereço ou a porta podem estar errados.", advice: "Confira o endereço do servidor com a sua revenda.", checks: [internetOk, listProblemCheck("Endereço", "Respondeu", "ok"), listProblemCheck("Lista", "Resposta inválida", "fail")], primary: "retry" }
    end if
    if message = "" then message = "A lista não respondeu como esperado."
    return { kind: "unknown", title: "Não foi possível conectar", message: message, advice: "Confira os dados da lista e tente de novo. Se continuar, fale com a sua revenda.", checks: [], primary: "retry" }
end function
