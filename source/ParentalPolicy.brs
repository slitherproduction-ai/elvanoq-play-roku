function parentalScopeKey() as String
    section = CreateObject("roRegistrySection", "ELVANOQPlay")
    metadata = ParseJson(section.Read("playlist_metadata"))
    if metadata <> invalid and type(metadata) = "roAssociativeArray" and metadata.server_code <> invalid and metadata.server_code <> "" then
        return "parental_locks_" + metadata.server_code
    end if
    return "parental_locks_default"
end function

function parentalSessionUnlocked() as Boolean
    section = CreateObject("roRegistrySection", "ELVANOQPlay")
    return section.Read("parental_session") = "unlocked"
end function

function parentalItemScopeKey() as String
    return parentalScopeKey() + "_items"
end function

function isParentallyBlocked(category as String) as Boolean
    if parentalSessionUnlocked() then return false
    state = parentalCategoryState(category, currentCategoryLocks())
    return state = "blocked" or state = "auto"
end function

' Lista de bloqueios por categoria da lista ativa. Entradas "!Nome" sao excecoes:
' categorias adultas que o usuario liberou da protecao automatica.
function currentCategoryLocks() as Object
    raw = CreateObject("roRegistrySection", "ELVANOQPlay").Read(parentalScopeKey())
    if raw = "" then return []
    locks = ParseJson(raw)
    if locks = invalid or type(locks) <> "roArray" then return []
    return locks
end function

' "blocked" (bloqueada pelo usuario), "auto" (adulta, protegida automaticamente),
' "released" (adulta liberada pelo usuario) ou "free".
function parentalCategoryState(category as String, locks as Object) as String
    name = lcase(category)
    exception = "!" + name
    released = false
    for each entry in locks
        lowered = lcase(entry)
        if lowered = name then return "blocked"
        if lowered = exception then released = true
    end for
    if adultProtectionEnabled() and isAdultCategoryName(category) then
        if released then return "released"
        return "auto"
    end if
    return "free"
end function

' Categorias protegidas: bloqueadas pelo usuario + adultas protegidas automaticamente.
' Busca por assocarray (sem lacos aninhados).
function protectedCategoryTotal(categories as Dynamic) as Integer
    if categories = invalid then return 0
    lockSet = {}
    exceptionSet = {}
    for each entry in currentCategoryLocks()
        lowered = lcase(entry)
        if left(lowered, 1) = "!" then exceptionSet[mid(lowered, 2)] = true else lockSet[lowered] = true
    end for
    automatic = adultProtectionEnabled()
    total = 0
    for each category in categories
        name = lcase(category)
        if lockSet.DoesExist(name) then
            total = total + 1
        else if automatic and not exceptionSet.DoesExist(name) and isAdultCategoryName(category) then
            total = total + 1
        end if
    end for
    return total
end function

' Protecao automatica de conteudo adulto: ligada por padrao.
function adultProtectionEnabled() as Boolean
    return CreateObject("roRegistrySection", "ELVANOQPlay").Read("adult_protection") <> "off"
end function

sub setAdultProtection(enabled as Boolean)
    section = CreateObject("roRegistrySection", "ELVANOQPlay")
    if enabled then section.Write("adult_protection", "on") else section.Write("adult_protection", "off")
    section.Flush()
end sub

' xxx, porn..., adulto(s)/adulta(s)/adult(s), hentai, erotic.../erótic..., playboy,
' sexy hot, nsfw, +18 ou 18+ (como palavra), sem diferenciar maiusculas.
function isAdultCategoryName(category as String) as Boolean
    if category = "" then return false
    if m.adultRegex = invalid then
        m.adultRegex = CreateObject("roRegex", "xxx|porn|adult[oa]s?|adults?|hentai|er[oó]tic|playboy|sexy\s*hot|nsfw|(^|[^0-9a-z])(\+18|18\+)([^0-9a-z]|$)", "i")
    end if
    return m.adultRegex.IsMatch(category)
end function

function isParentallyBlockedItem(category as String, itemId as String) as Boolean
    if isParentallyBlocked(category) then return true
    if parentalSessionUnlocked() or itemId = "" then return false
    section = CreateObject("roRegistrySection", "ELVANOQPlay")
    raw = section.Read(parentalItemScopeKey())
    if raw = "" then return false
    locks = ParseJson(raw)
    if locks = invalid or type(locks) <> "roArray" then return false
    for each lockedItemId in locks
        if lockedItemId = itemId then return true
    end for
    return false
end function
