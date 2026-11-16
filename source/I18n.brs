' Idioma do aplicativo (Portugues / English / Automatico), igual ao Android
' 2.17.72 e a LG/MSX. Os textos continuam em portugues no codigo; em ingles,
' cada Label observado passa pelo dicionario pkg:/locale/en.json (texto exato
' ou modelo com partes variaveis, "Versao {0}"). Com o app em portugues nada
' e traduzido. A escolha fica no registry ("language"); Automatico segue o
' idioma do Roku. m.global.language guarda o idioma em uso.

function i18nPreference() as String
    section = CreateObject("roRegistrySection", "ELVANOQPlay")
    value = section.Read("language")
    if value = "pt" or value = "en" then return value
    return "auto"
end function

function i18nResolve(preference as String) as String
    if preference = "pt" or preference = "en" then return preference
    locale = LCase(CreateObject("roDeviceInfo").GetCurrentLocale())
    if Left(locale, 2) = "pt" then return "pt"
    return "en"
end function

function i18nLanguage() as String
    if m.global <> invalid and m.global.hasField("language") then return m.global.language
    return i18nResolve(i18nPreference())
end function

function i18nDictionary() as Object
    if m.i18nDict = invalid then
        m.i18nDict = ParseJson(ReadAsciiFile("pkg:/locale/en.json"))
        if m.i18nDict = invalid then m.i18nDict = { exact: {}, buckets: {}, tails: [] }
        m.i18nRegex = {}
        m.i18nSpaces = CreateObject("roRegex", "\s+", "")
    end if
    return m.i18nDict
end function

function i18nMatch(entry as Object, text as String) as Dynamic
    regex = m.i18nRegex[entry[0]]
    if regex = invalid then
        regex = CreateObject("roRegex", entry[0], "")
        m.i18nRegex[entry[0]] = regex
    end if
    groups = regex.Match(text)
    if groups.count() = 0 then return invalid
    out = entry[1]
    for index = 1 to groups.count() - 1
        out = out.Replace("{" + (index - 1).ToStr() + "}", i18nTranslate(groups[index]))
    end for
    return out
end function

function i18nTranslate(text as String) as String
    if text = "" then return text
    dict = i18nDictionary()
    trimmed = m.i18nSpaces.ReplaceAll(text, " ").Trim()
    if trimmed = "" then return text
    hit = dict.exact.Lookup(trimmed)
    if hit <> invalid then return hit
    first = trimmed
    space = Instr(1, trimmed, " ")
    if space > 0 then first = Left(trimmed, space - 1)
    bucket = dict.buckets.Lookup(first)
    if bucket <> invalid then
        for each entry in bucket
            out = i18nMatch(entry, trimmed)
            if out <> invalid then return out
        end for
    end if
    for each entry in dict.tails
        out = i18nMatch(entry, trimmed)
        if out <> invalid then return out
    end for
    return text
end function

' Traduz um texto em portugues para o idioma em uso.
function tr(text as Dynamic) as Dynamic
    if text = invalid or i18nLanguage() <> "en" then return text
    return i18nTranslate(text)
end function

' Observa os Labels do componente (e dos filhos) para traduzir todo texto
' que aparecer; ao trocar o idioma, retraduz ou volta ao portugues.
sub i18nAttach(root as Object)
    if m.global <> invalid and m.global.hasField("language") and m.i18nWatching <> true then
        m.global.observeField("language", "onI18nLanguage")
        m.i18nWatching = true
    end if
    i18nWalk(root, true)
end sub

sub i18nWalk(node as Object, attach as Boolean)
    if node = invalid then return
    if node.isSubtype("Label") then
        if attach then
            if not node.hasField("i18nSrc") then
                node.addFields({ i18nSrc: node.text, i18nOut: "" })
                node.observeField("text", "onI18nText")
            end if
        end if
        i18nApply(node)
    end if
    for each child in node.getChildren(-1, 0)
        i18nWalk(child, attach)
    end for
end sub

sub i18nApply(node as Object)
    if not node.hasField("i18nSrc") then return
    source = node.i18nSrc
    if i18nLanguage() = "en" then
        out = i18nTranslate(source)
    else
        out = source
    end if
    node.i18nOut = out
    if node.text <> out then node.text = out
end sub

sub onI18nText(event as Object)
    node = event.getRoSGNode()
    text = node.text
    if text = node.i18nOut then return
    node.i18nSrc = text
    if i18nLanguage() <> "en" then
        node.i18nOut = text
        return
    end if
    out = i18nTranslate(text)
    node.i18nOut = out
    if out <> text then node.text = out
end sub

sub onI18nLanguage()
    i18nWalk(m.top, false)
end sub

' Caixas de dialogo padrao da Roku: titulo, mensagem, botoes e dica.
sub i18nDialog(dialog as Object)
    if dialog = invalid or i18nLanguage() <> "en" then return
    if dialog.hasField("title") then dialog.title = tr(dialog.title)
    if dialog.hasField("message") and dialog.message <> invalid then
        lines = []
        for each line in dialog.message
            lines.push(tr(line))
        end for
        dialog.message = lines
    end if
    if dialog.hasField("buttons") and dialog.buttons <> invalid then
        buttons = []
        for each button in dialog.buttons
            buttons.push(tr(button))
        end for
        dialog.buttons = buttons
    end if
    if dialog.hasField("textEditBox") and dialog.textEditBox <> invalid then
        editBox = dialog.textEditBox
        if editBox.hintText <> invalid and editBox.hintText <> "" then editBox.hintText = tr(editBox.hintText)
    end if
end sub
