sub init()
    m.dots = m.top.findNode("dots")
    m.status = m.top.findNode("status")
    m.pin = ""
    m.pinMode = "unlock"
    m.categories = []
    m.items = []
    m.mode = "categories"
    m.selectedCategory = 0
    m.top.findNode("title").font = "font:LargeBoldSystemFont"
    m.top.findNode("description").font = "font:MediumSystemFont"
    m.dots.font = "font:LargeBoldSystemFont"
    m.status.font = "font:SmallSystemFont"
    m.status.color = "0x8FA9C4FF"
    m.lockedCategories = m.top.findNode("lockedCategories")
    m.lockedCategories.font = "font:MediumSystemFont"
    m.scopeStatus = m.top.findNode("scopeStatus")
    m.scopeStatus.font = "font:SmallSystemFont"
    m.scopeStatus.color = "0x8FA9C4FF"
    m.scopeStatus.text = "Bloqueios são separados por lista ativa."
    m.top.observeField("categories", "onCategoriesChanged")
    m.top.observeField("items", "onItemsChanged")
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
        updateDots()
        m.status.text = "Digite o novo PIN de quatro dígitos."
        return true
    end if
    if not parentalSessionUnlocked() then return false
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

sub enterDigit(digit as String)
    if len(m.pin) >= 4 then return
    m.pin = m.pin + digit
    updateDots()
    if len(m.pin) = 4 then validatePin()
end sub

sub clearDigit()
    if len(m.pin) > 0 then m.pin = left(m.pin, len(m.pin) - 1)
    updateDots()
end sub

sub cancelPinEntry()
    m.pin = ""
    if m.pinMode = "change" then
        m.pinMode = "unlock"
        m.status.text = "Alteração de PIN cancelada."
    end if
    updateDots()
end sub

sub updateDots()
    text = ""
    for index = 1 to 4
        if index <= len(m.pin) then text = text + "●  " else text = text + "○  "
    end for
    m.dots.text = text
end sub

sub validatePin()
    section = CreateObject("roRegistrySection", "ELVANOQPlay")
    if m.pinMode = "change" then
        section.Write("parental_pin", m.pin)
        section.Flush()
        m.pin = ""
        m.pinMode = "unlock"
        updateDots()
        m.status.text = "PIN atualizado com sucesso."
        return
    end if
    saved = section.Read("parental_pin")
    if saved = invalid or saved = "" then saved = "0000"
    if m.pin = saved then
        m.status.text = "Controle parental desbloqueado nesta sessão."
        section.Write("parental_session", "unlocked")
        section.Flush()
        m.pin = ""
        updateDots()
        renderLocks()
    else
        m.status.text = "PIN incorreto. Tente novamente."
        m.pin = ""
        updateDots()
    end if
end sub

sub renderLocks()
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
    output = "CATEGORIAS DA LISTA\n"
    if m.mode = "items" then output = "CANAIS E TÍTULOS\n"
    firstIndex = 0
    if m.selectedCategory > 5 then firstIndex = m.selectedCategory - 5
    lastIndex = firstIndex + 5
    if lastIndex > entries.count() - 1 then lastIndex = entries.count() - 1
    for index = firstIndex to lastIndex
        entry = entries[index]
        label = entry
        entryId = entry
        if m.mode = "items" then
            label = entry.title
            entryId = entry.id
        end if
        marker = "○"
        if isCategoryLocked(entryId, locks) then marker = "●"
        prefix = "  "
        if index = m.selectedCategory then prefix = "› "
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
