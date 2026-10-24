sub init()
    m.dots = m.top.findNode("dots")
    m.status = m.top.findNode("status")
    m.pin = ""
    m.categories = []
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
end sub

sub onCategoriesChanged()
    m.categories = m.top.categories
    if m.categories = invalid then m.categories = []
    m.selectedCategory = 0
    renderLocks()
end sub

function handleKey(event as Object) as Boolean
    if event.press <> true then return false
    if not parentalSessionUnlocked() then return false
    if event.key = "down" and m.selectedCategory < m.categories.count() - 1 then
        m.selectedCategory = m.selectedCategory + 1
        renderLocks()
        return true
    end if
    if event.key = "up" and m.selectedCategory > 0 then
        m.selectedCategory = m.selectedCategory - 1
        renderLocks()
        return true
    end if
    if event.key = "OK" and m.categories.count() > 0 then
        toggleCategoryLock(m.categories[m.selectedCategory])
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

sub updateDots()
    text = ""
    for index = 1 to 4
        if index <= len(m.pin) then text = text + "●  " else text = text + "○  "
    end for
    m.dots.text = text
end sub

sub validatePin()
    section = CreateObject("roRegistrySection", "ELVANOQPlay")
    saved = section.Read("parental_pin")
    if saved = invalid or saved = "" then saved = "0000"
    if m.pin = saved then
        m.status.text = "Controle parental desbloqueado nesta sessão."
        section.Write("parental_session", "unlocked")
        section.Flush()
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
    if m.categories = invalid or m.categories.count() = 0 then
        m.lockedCategories.text = "Nenhuma categoria recebida da lista atual."
        return
    end if
    locks = currentLocks()
    output = "CATEGORIAS DA LISTA\n"
    lastIndex = m.categories.count() - 1
    if lastIndex > 5 then lastIndex = 5
    for index = 0 to lastIndex
        category = m.categories[index]
        marker = "○"
        if isCategoryLocked(category, locks) then marker = "●"
        prefix = "  "
        if index = m.selectedCategory then prefix = "› "
        output = output + prefix + marker + "  " + category
        if index < lastIndex then output = output + chr(10)
    end for
    m.lockedCategories.text = output
    m.scopeStatus.text = "↑/↓ selecionar  •  OK bloquear/desbloquear  •  ● bloqueada"
end sub

function currentLocks() as Object
    section = CreateObject("roRegistrySection", "ELVANOQPlay")
    locks = ParseJson(section.Read(parentalScopeKey()))
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
