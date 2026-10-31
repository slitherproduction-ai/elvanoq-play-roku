' BrightScript nao tem trim() global (so o metodo .Trim()).
' Use safeTrim() para texto ou numero; invalid vira "".
function safeTrim(value as Dynamic) as String
    if value = invalid then return ""
    t = lcase(type(value))
    if t = "rostring" or t = "string" then return value.Trim()
    ' Nomes de tipo numerico variam entre versoes do Roku OS (roInt, roInteger, LongInteger...).
    if instr(1, t, "int") > 0 or instr(1, t, "float") > 0 or instr(1, t, "double") > 0 then return str(value).Trim()
    if t = "roboolean" or t = "boolean" then
        if value then return "true"
        return "false"
    end if
    return ""
end function

' Chave do guia: tvg-id da lista ou, nas listas Xtream sem tvg-id, o stream_id.
function epgKeyFor(item as Dynamic) as String
    if item = invalid or type(item) <> "roAssociativeArray" then return ""
    if item.tvg_id <> invalid and safeTrim(item.tvg_id) <> "" then return safeTrim(item.tvg_id)
    if item.stream_id <> invalid and safeTrim(item.stream_id) <> "" then return "sid:" + safeTrim(item.stream_id)
    return ""
end function
