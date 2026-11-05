sub init()
    m.dots = m.top.findNode("dots")
    m.status = m.top.findNode("status")
    m.pin = ""
    m.pinMode = "unlock"
    m.categories = []
    m.items = []
    m.mode = "categories"
    m.selectedCategory = 0
    m.top.findNode("pageTitle").font = appFont(40, "bold")
    m.top.findNode("pageTitle").color = "0xF4F8FFFF"
    m.top.findNode("pageSubtitle").font = appFont(20, "regular")
    m.top.findNode("pageSubtitle").color = "0x8894A8FF"
    m.top.findNode("title").font = appFont(26, "semibold")
    m.top.findNode("title").color = "0xF4F8FFFF"
    m.top.findNode("description").font = appFont(20, "regular")
    m.top.findNode("description").color = "0xB6C2D6FF"
    m.dots.font = appFont(40, "bold")
    m.dots.color = "0x00D7FFFF"
    ' Teclado de PIN navegavel (o controle da Roku nao tem teclas numericas).
    m.keyValues = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "clear", "0", "back"]
    m.keyIndex = 0
    m.keyFocus = m.top.findNode("keyFocus")
    m.keyBackgrounds = []
    for index = 0 to 11
        suffix = safeTrim(str(index))
        if len(suffix) < 2 then suffix = "0" + suffix
        label = m.top.findNode("keyLabel" + suffix)
        if index = 9 or index = 11 then
            label.font = appFont(20, "semibold")
        else
            label.font = appFont(32, "semibold")
        end if
        label.color = "0xF4F8FFFF"
        m.keyBackgrounds.push(m.top.findNode("keyBg" + suffix))
    end for
    updateKeyFocus()
    m.status.font = appFont(20, "regular")
    m.status.color = "0x8894A8FF"
    m.lockedCategories = m.top.findNode("lockedCategories")
    m.lockedCategories.font = appFont(24, "regular")
    m.lockedCategories.color = "0xB8C4D6FF"
    m.visibleLockRows = 12
    m.lockRows = []
    m.lockBadges = []
    m.lockBadgeLabels = []
    for index = 0 to m.visibleLockRows - 1
        suffix = index.ToStr()
        if index < 10 then suffix = "0" + suffix
        row = m.top.findNode("lockRow" + suffix)
        row.font = appFont(22, "regular")
        m.lockRows.push(row)
        m.lockBadges.push(m.top.findNode("lockBadge" + suffix))
        badgeLabel = m.top.findNode("lockBadgeLabel" + suffix)
        badgeLabel.font = appFont(18, "bold")
        m.lockBadgeLabels.push(badgeLabel)
    end for
    m.lockFocus = m.top.findNode("lockFocus")
    m.listGroupLabel = m.top.findNode("listGroupLabel")
    m.listGroupLabel.font = appFont(18, "bold")
    m.listGroupLabel.color = "0x8894A8FF"
    m.protectedCount = m.top.findNode("protectedCount")
    m.protectedCount.font = appFont(18, "bold")
    m.protectedCount.color = "0x00D7FFFF"
    m.scopeStatus = m.top.findNode("scopeStatus")
    m.scopeStatus.font = appFont(20, "regular")
    m.scopeStatus.color = "0x8894A8FF"
    m.scopeStatus.text = "Bloqueios são separados por lista ativa."
    migrateLegacyPin()
    refreshPinPrompt()
    m.top.observeField("visible", "onVisibleChanged")
    m.top.observeField("categories", "onCategoriesChanged")
    m.top.observeField("items", "onItemsChanged")
end sub

sub onVisibleChanged()
    if m.top.visible = true then refreshPinPrompt()
end sub

' Texto inicial conforme o estado do PIN (sem PIN criado, bloqueado por tentativas ou pedido normal).
sub refreshPinPrompt()
    if m.pinMode = "change" or m.pinMode = "change_confirm" then return
    description = m.top.findNode("description")
    if parentalSessionUnlocked() then
        m.pinMode = "unlock"
        description.text = "Controle parental liberado nesta sessão."
        m.status.text = "* alterar PIN"
    else if not hasParentalPin() then
        if m.pinMode <> "create_confirm" then m.pinMode = "create"
        description.text = "Crie um PIN de quatro dígitos para proteger categorias e conteúdos."
        if m.pinMode = "create" then m.status.text = "Digite o novo PIN."
    else
        m.pinMode = "unlock"
        description.text = "Digite o PIN para acessar categorias e restrições."
        remaining = pinLockRemainingSeconds()
        if remaining > 0 then
            m.status.text = lockoutMessage(remaining)
        else
            m.status.text = "Digite seu PIN de quatro dígitos."
        end if
    end if
    m.pin = ""
    updateDots()
    if m.keyBackgrounds <> invalid then updateKeyFocus()
end sub

sub onItemsChanged()
    m.items = m.top.items
    if m.items = invalid then m.items = []
    renderLocks()
end sub

sub onCategoriesChanged()
    m.categories = m.top.categories
    if m.categories = invalid then m.categories = []
    m.selectedCategory = 0
    renderLocks()
end sub

function handleKey(event as Object) as Boolean
    if event.press <> true then return false
    if event.key = "options" and parentalSessionUnlocked() then
        m.pinMode = "change"
        m.pin = ""
        m.pendingPin = ""
        updateDots()
        updateKeyFocus()
        m.status.text = "Digite o novo PIN de quatro dígitos."
        return true
    end if
    if keypadActive() then return handleKeypad(event.key)
    if event.key = "left" or event.key = "right" then
        if m.mode = "categories" then m.mode = "items" else m.mode = "categories"
        m.selectedCategory = 0
        renderLocks()
        return true
    end if
    selectable = lockEntries()
    if event.key = "down" and m.selectedCategory < selectable.count() - 1 then
        m.selectedCategory = m.selectedCategory + 1
        renderLocks()
        return true
    end if
    if event.key = "up" and m.selectedCategory > 0 then
        m.selectedCategory = m.selectedCategory - 1
        renderLocks()
        return true
    end if
    if event.key = "OK" and selectable.count() > 0 then
        entry = selectable[m.selectedCategory]
        if entry.kind = "adult" then
            setAdultProtection(not adultProtectionEnabled())
            if adultProtectionEnabled() then
                m.status.text = "Proteção automática de conteúdo adulto ligada."
            else
                m.status.text = "Proteção automática desligada: as categorias adultas foram liberadas."
            end if
            renderLocks()
        else if entry.kind = "category" then
            toggleCategoryLock(entry.name)
        else
            toggleItemLock(entry.item)
        end if
        return true
    end if
    return false
end function

function keypadActive() as Boolean
    return not parentalSessionUnlocked() or m.pinMode <> "unlock"
end function

sub enterDigit(digit as String)
    if len(m.pin) >= 4 then return
    if m.pinMode = "unlock" and pinLockRemainingSeconds() > 0 then
        m.status.text = lockoutMessage(pinLockRemainingSeconds())
        return
    end if
    m.pin = m.pin + digit
    updateDots()
    if len(m.pin) = 4 then validatePin()
    updateKeyFocus()
end sub

sub clearDigit()
    if len(m.pin) > 0 then m.pin = left(m.pin, len(m.pin) - 1)
    updateDots()
end sub

sub cancelPinEntry()
    m.pin = ""
    if m.pinMode = "change" or m.pinMode = "change_confirm" then
        m.pinMode = "unlock"
        m.status.text = "Alteração de PIN cancelada."
    else if m.pinMode = "create_confirm" then
        m.pinMode = "create"
        m.status.text = "Digite o novo PIN."
    end if
    updateDots()
end sub

sub updateDots()
    text = ""
    for index = 1 to 4
        if index <= len(m.pin) then text = text + "*  " else text = text + "_  "
    end for
    m.dots.text = text
end sub

sub validatePin()
    section = CreateObject("roRegistrySection", "ELVANOQPlay")
    entered = m.pin
    m.pin = ""
    updateDots()
    if m.pinMode = "create" or m.pinMode = "change" then
        m.pendingPin = entered
        if m.pinMode = "create" then m.pinMode = "create_confirm" else m.pinMode = "change_confirm"
        m.status.text = "Confirme o novo PIN."
        return
    end if
    if m.pinMode = "create_confirm" or m.pinMode = "change_confirm" then
        wasCreate = (m.pinMode = "create_confirm")
        if entered <> m.pendingPin then
            if wasCreate then m.pinMode = "create" else m.pinMode = "change"
            m.pendingPin = ""
            m.status.text = "Os PINs não conferem. Digite o novo PIN novamente."
            return
        end if
        saveParentalPin(entered)
        m.pendingPin = ""
        m.pinMode = "unlock"
        if wasCreate then
            section.Write("parental_session", "unlocked")
            section.Flush()
            m.top.findNode("description").text = "Controle parental liberado nesta sessão."
            m.status.text = "PIN criado. Guarde-o: ele protege os bloqueios."
        else
            m.status.text = "PIN atualizado com sucesso."
        end if
        renderLocks()
        return
    end if
    remaining = pinLockRemainingSeconds()
    if remaining > 0 then
        m.status.text = lockoutMessage(remaining)
        return
    end if
    if hashPin(entered, section.Read("parental_salt")) = section.Read("parental_pin_hash") then
        section.Write("parental_fail_count", "0")
        section.Write("parental_session", "unlocked")
        section.Flush()
        m.top.findNode("description").text = "Controle parental liberado nesta sessão."
        m.status.text = "Controle parental desbloqueado nesta sessão."
        renderLocks()
        return
    end if
    failures = section.Read("parental_fail_count").ToInt() + 1
    if failures >= 5 then
        section.Write("parental_fail_count", "0")
        section.Write("parental_lock_until", (nowSeconds() + 300).ToStr())
        section.Flush()
        m.status.text = lockoutMessage(300)
    else
        section.Write("parental_fail_count", failures.ToStr())
        section.Flush()
        remainingTries = 5 - failures
        if remainingTries = 1 then
            m.status.text = "PIN incorreto. Resta 1 tentativa."
        else
            m.status.text = "PIN incorreto. Restam " + remainingTries.ToStr() + " tentativas."
        end if
    end if
end sub

function hasParentalPin() as Boolean
    return CreateObject("roRegistrySection", "ELVANOQPlay").Read("parental_pin_hash") <> ""
end function

' O PIN fica salvo apenas como SHA-256 com sal aleatorio do aparelho.
function hashPin(pin as String, salt as String) as String
    bytes = CreateObject("roByteArray")
    bytes.FromAsciiString("elvanoq-pin:" + salt + ":" + pin)
    digest = CreateObject("roEVPDigest")
    digest.Setup("sha256")
    return digest.Process(bytes)
end function

sub saveParentalPin(pin as String)
    section = CreateObject("roRegistrySection", "ELVANOQPlay")
    salt = CreateObject("roDeviceInfo").GetRandomUUID()
    section.Write("parental_salt", salt)
    section.Write("parental_pin_hash", hashPin(pin, salt))
    section.Delete("parental_pin")
    section.Write("parental_fail_count", "0")
    section.Flush()
end sub

' Versoes antigas guardavam o PIN em texto. Quem ja tinha trocado o PIN mantem o mesmo valor,
' agora protegido; quem nunca trocou (0000 padrao) cria um PIN proprio no primeiro acesso.
sub migrateLegacyPin()
    section = CreateObject("roRegistrySection", "ELVANOQPlay")
    legacy = section.Read("parental_pin")
    if legacy = "" then return
    if section.Read("parental_pin_hash") = "" and legacy <> "0000" then
        saveParentalPin(legacy)
    else
        section.Delete("parental_pin")
        section.Flush()
    end if
end sub

function nowSeconds() as Integer
    return CreateObject("roDateTime").AsSeconds()
end function

function pinLockRemainingSeconds() as Integer
    lockUntil = CreateObject("roRegistrySection", "ELVANOQPlay").Read("parental_lock_until").ToInt()
    remaining = lockUntil - nowSeconds()
    if remaining < 0 or remaining > 300 then return 0
    return remaining
end function

function lockoutMessage(seconds as Integer) as String
    minutes = int((seconds + 59) / 60)
    if minutes <= 1 then return "Muitas tentativas. Tente novamente em 1 minuto."
    return "Muitas tentativas. Tente novamente em " + minutes.ToStr() + " minutos."
end function

sub renderLocks()
    if m.keyBackgrounds <> invalid then updateKeyFocus()
    if m.lockRows = invalid then return
    unlocked = parentalSessionUnlocked()
    entries = lockEntries()
    if m.mode = "items" then
        m.listGroupLabel.text = "CANAIS E TÍTULOS"
    else
        m.listGroupLabel.text = "CATEGORIAS DA LISTA"
    end if
    m.protectedCount.text = protectedCategoryCount().ToStr() + " categorias protegidas"
    if not unlocked then
        clearLockRows()
        m.lockedCategories.text = "Digite o PIN para gerenciar categorias."
        m.scopeStatus.text = "Bloqueios são separados por lista ativa."
        return
    end if
    if entries.count() = 0 then
        clearLockRows()
        m.lockedCategories.text = "Nenhum item recebido da lista atual."
        return
    end if
    m.lockedCategories.text = ""
    if m.selectedCategory > entries.count() - 1 then m.selectedCategory = entries.count() - 1
    firstIndex = 0
    if m.selectedCategory > m.visibleLockRows - 1 then firstIndex = m.selectedCategory - m.visibleLockRows + 1
    categoryLocks = currentLocks()
    itemLocks = currentItemLocks()
    for row = 0 to m.visibleLockRows - 1
        index = firstIndex + row
        label = m.lockRows[row]
        if index < entries.count() then
            entry = entries[index]
            badge = lockBadgeFor(entry, categoryLocks, itemLocks)
            label.text = entry.label
            if index = m.selectedCategory then label.color = "0xFFFFFFFF" else label.color = "0xC9D3E3FF"
            setLockBadge(row, badge)
            if index = m.selectedCategory then
                m.lockBadges[row].color = "0xFFFFFF33"
                m.lockBadgeLabels[row].color = "0xFFFFFFFF"
            end if
        else
            label.text = ""
            setLockBadge(row, invalid)
        end if
    end for
    m.lockFocus.visible = true
    m.lockFocus.translation = [732, 264 + (m.selectedCategory - firstIndex) * 58]
    m.scopeStatus.text = "←/→ categorias ou títulos   •   OK alterar   •   * alterar PIN"
end sub

' Linhas da lista: no modo categorias, a primeira e a chave "Proteger conteudo adulto".
function lockEntries() as Object
    entries = []
    if m.mode = "items" then
        if m.items <> invalid then
            for each item in m.items
                if item <> invalid and item.title <> invalid then entries.push({ kind: "item", label: item.title, item: item })
            end for
        end if
        return entries
    end if
    entries.push({ kind: "adult", label: "Proteger conteúdo adulto" })
    if m.categories <> invalid then
        for each category in m.categories
            entries.push({ kind: "category", label: category, name: category })
        end for
    end if
    return entries
end function

function lockBadgeFor(entry as Object, categoryLocks as Object, itemLocks as Object) as Object
    if entry.kind = "adult" then
        if adultProtectionEnabled() then return { text: "Ligada", tone: "on" }
        return { text: "Desligada", tone: "off" }
    end if
    if entry.kind = "item" then
        if isCategoryLocked(entry.item.id, itemLocks) then return { text: "Bloqueado", tone: "blocked" }
        return { text: "Livre", tone: "free" }
    end if
    state = parentalCategoryState(entry.name, categoryLocks)
    if state = "blocked" then return { text: "Bloqueada", tone: "blocked" }
    if state = "auto" then return { text: "Automática", tone: "auto" }
    return { text: "Livre", tone: "free" }
end function

sub setLockBadge(row as Integer, badge as Dynamic)
    background = m.lockBadges[row]
    label = m.lockBadgeLabels[row]
    if badge = invalid then
        background.visible = false
        label.text = ""
        return
    end if
    tones = { blocked: ["0xFF5C7240", "0xFF9AA8FF"], auto: ["0xFFB54740", "0xFFD08AFF"], free: ["0x2EE59D33", "0x7DF2C2FF"], on: ["0x00D7FF33", "0x7FE9FFFF"], off: ["0x8894A833", "0xC9D3E3FF"] }
    colors = tones[badge.tone]
    background.color = colors[0]
    background.visible = true
    label.color = colors[1]
    label.text = badge.text
end sub

sub clearLockRows()
    for row = 0 to m.visibleLockRows - 1
        m.lockRows[row].text = ""
        setLockBadge(row, invalid)
    end for
    m.lockFocus.visible = false
end sub

function protectedCategoryCount() as Integer
    return protectedCategoryTotal(m.categories)
end function

function currentLocks() as Object
    section = CreateObject("roRegistrySection", "ELVANOQPlay")
    locks = ParseJson(section.Read(parentalScopeKey()))
    if locks = invalid or type(locks) <> "roArray" then return []
    return locks
end function

function currentItemLocks() as Object
    section = CreateObject("roRegistrySection", "ELVANOQPlay")
    locks = ParseJson(section.Read(parentalItemScopeKey()))
    if locks = invalid or type(locks) <> "roArray" then return []
    return locks
end function

function isCategoryLocked(category as String, locks as Object) as Boolean
    for each locked in locks
        if lcase(locked) = lcase(category) then return true
    end for
    return false
end function

sub toggleCategoryLock(category as String)
    locks = currentLocks()
    state = parentalCategoryState(category, locks)
    name = lcase(category)
    updated = []
    for each locked in locks
        lowered = lcase(locked)
        if lowered <> name and lowered <> "!" + name then updated.push(locked)
    end for
    ' Adulta automatica: OK libera (grava a excecao "!Nome"); de novo, volta a regra automatica.
    if state = "auto" then
        updated.push("!" + category)
        m.status.text = "Liberada da proteção automática: " + category
    else if state = "released" then
        m.status.text = "Protegida automaticamente de novo: " + category
    else if state = "blocked" then
        m.status.text = "Categoria desbloqueada: " + category
    else
        updated.push(category)
        m.status.text = "Categoria bloqueada: " + category
    end if
    section = CreateObject("roRegistrySection", "ELVANOQPlay")
    section.Write(parentalScopeKey(), FormatJson(updated))
    section.Flush()
    renderLocks()
end sub

sub toggleItemLock(item as Object)
    if item = invalid or item.id = invalid or item.id = "" then return
    locks = currentItemLocks()
    updated = []
    removed = false
    for each locked in locks
        if locked = item.id then
            removed = true
        else
            updated.push(locked)
        end if
    end for
    if removed then
        m.status.text = "Item desbloqueado: " + item.title
    else
        updated.push(item.id)
        m.status.text = "Item bloqueado: " + item.title
    end if
    section = CreateObject("roRegistrySection", "ELVANOQPlay")
    section.Write(parentalItemScopeKey(), FormatJson(updated))
    section.Flush()
    renderLocks()
end sub

function handleKeypad(key as String) as Boolean
    column = m.keyIndex mod 3
    row = int(m.keyIndex / 3)
    if key = "left" and column > 0 then
        m.keyIndex = m.keyIndex - 1
    else if key = "right" and column < 2 then
        m.keyIndex = m.keyIndex + 1
    else if key = "up" and row > 0 then
        m.keyIndex = m.keyIndex - 3
    else if key = "down" and row < 3 then
        m.keyIndex = m.keyIndex + 3
    else if key = "OK" then
        value = m.keyValues[m.keyIndex]
        if value = "back" then
            clearDigit()
        else if value = "clear" then
            m.pin = ""
            updateDots()
        else
            enterDigit(value)
        end if
    else if key = "up" then
        return false
    else
        return key = "left" or key = "right" or key = "down"
    end if
    updateKeyFocus()
    return true
end function

sub updateKeyFocus()
    for index = 0 to m.keyBackgrounds.count() - 1
        if index = m.keyIndex then
            m.keyBackgrounds[index].color = "0x147DFFFF"
        else
            m.keyBackgrounds[index].color = "0x111B2DFF"
        end if
    end for
    m.keyFocus.translation = [98 + (m.keyIndex mod 3) * 176, 424 + int(m.keyIndex / 3) * 100]
    m.keyFocus.visible = keypadActive()
end sub
