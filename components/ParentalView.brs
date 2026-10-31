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
    m.lockedCategories.color = "0xF4F8FFFF"
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
    selectable = m.categories
    if m.mode = "items" then selectable = m.items
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
        if m.mode = "categories" then
            toggleCategoryLock(m.categories[m.selectedCategory])
        else
            toggleItemLock(m.items[m.selectedCategory])
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
    if not parentalSessionUnlocked() then
        m.lockedCategories.text = "Digite o PIN para gerenciar categorias."
        return
    end if
    entries = m.categories
    if m.mode = "items" then entries = m.items
    if entries = invalid or entries.count() = 0 then
        m.lockedCategories.text = "Nenhum item recebido da lista atual."
        return
    end if
    locks = currentLocks()
    if m.mode = "items" then locks = currentItemLocks()
    output = "CATEGORIAS DA LISTA" + chr(10) + chr(10)
    if m.mode = "items" then output = "CANAIS E TÍTULOS" + chr(10) + chr(10)
    firstIndex = 0
    if m.selectedCategory > 15 then firstIndex = m.selectedCategory - 15
    lastIndex = firstIndex + 15
    if lastIndex > entries.count() - 1 then lastIndex = entries.count() - 1
    for index = firstIndex to lastIndex
        entry = entries[index]
        label = entry
        entryId = entry
        if m.mode = "items" then
            label = entry.title
            entryId = entry.id
        end if
        marker = "[  ]"
        if isCategoryLocked(entryId, locks) then marker = "[X]"
        prefix = "  "
        if index = m.selectedCategory then prefix = "> "
        output = output + prefix + marker + "  " + label
        if index < lastIndex then output = output + chr(10)
    end for
    m.lockedCategories.text = output
    m.scopeStatus.text = "←/→ alternar modo  •  ↑/↓ selecionar  •  OK bloquear/desbloquear  •  * alterar PIN"
end sub

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
    updated = []
    removed = false
    for each locked in locks
        if lcase(locked) = lcase(category) then
            removed = true
        else
            updated.push(locked)
        end if
    end for
    if removed then
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
