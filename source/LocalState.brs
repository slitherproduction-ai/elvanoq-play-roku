function defaultLocalState() as Object
    return {
        favorites: []
        watch_later: []
        continue_watching: []
        history: []
        parental: { enabled: false, locked_categories: [] }
    }
end function

function loadLocalState() as Object
    section = CreateObject("roRegistrySection", "ELVANOQPlay")
    raw = section.Read("local_state")
    if raw = invalid or raw = "" then return defaultLocalState()
    state = ParseJson(raw)
    if state = invalid or type(state) <> "roAssociativeArray" then return defaultLocalState()
    if state.favorites = invalid then state.favorites = []
    if state.watch_later = invalid then state.watch_later = []
    if state.continue_watching = invalid then state.continue_watching = []
    if state.history = invalid then state.history = []
    state.favorites = sanitizeLocalItems(state.favorites)
    state.watch_later = sanitizeLocalItems(state.watch_later)
    state.continue_watching = sanitizeLocalItems(state.continue_watching)
    state.history = sanitizeLocalItems(state.history)
    if state.parental = invalid then state.parental = { enabled: false, locked_categories: [] }
    return state
end function

sub saveLocalState(state as Object)
    ' O registry da Roku aceita cerca de 32 KB por canal: limite as listas
    ' para que Write() nunca falhe em silencio.
    state.favorites = trimLocalItems(state.favorites, 150)
    state.watch_later = trimLocalItems(state.watch_later, 100)
    state.continue_watching = trimLocalItems(state.continue_watching, 30)
    state.history = trimLocalItems(state.history, 40)
    json = FormatJson(state)
    if len(json) > 24000 then
        state.history = trimLocalItems(state.history, 10)
        state.continue_watching = trimLocalItems(state.continue_watching, 15)
        state.watch_later = trimLocalItems(state.watch_later, 40)
        state.favorites = trimLocalItems(state.favorites, 80)
        json = FormatJson(state)
    end if
    section = CreateObject("roRegistrySection", "ELVANOQPlay")
    section.Write("local_state", json)
    section.Flush()
end sub

function trimLocalItems(items as Object, maxCount as Integer) as Object
    if items = invalid then return []
    if items.count() <= maxCount then return items
    trimmed = []
    for index = items.count() - maxCount to items.count() - 1
        trimmed.push(items[index])
    end for
    return trimmed
end function

function upsertLocalItem(items as Object, item as Object) as Object
    if item = invalid or item.id = invalid or item.id = "" then return items
    safeItem = sanitizeLocalItem(item)
    nextItems = []
    replaced = false
    for each current in items
        if current.id = item.id then
            nextItems.push(safeItem)
            replaced = true
        else
            nextItems.push(current)
        end if
    end for
    if not replaced then nextItems.push(safeItem)
    return nextItems
end function

function sanitizeLocalItems(items as Object) as Object
    safeItems = []
    if items = invalid then return safeItems
    for each item in items
        if item <> invalid and item.id <> invalid and item.id <> "" and instr(1, item.id, "://") = 0 then safeItems.push(sanitizeLocalItem(item))
    end for
    return safeItems
end function

function sanitizeLocalItem(item as Object) as Object
    safeItem = { id: item.id }
    if item.title <> invalid then safeItem.title = item.title
    if item.category <> invalid then safeItem.category = item.category
    if item.kind <> invalid then safeItem.kind = item.kind
    if item.progress_seconds <> invalid then safeItem.progress_seconds = item.progress_seconds
    if item.duration_seconds <> invalid then safeItem.duration_seconds = item.duration_seconds
    if item.completed <> invalid then safeItem.completed = item.completed
    if item.updated_at <> invalid then safeItem.updated_at = item.updated_at
    return safeItem
end function

function removeLocalItem(items as Object, itemId as String) as Object
    nextItems = []
    for each current in items
        if current.id <> itemId then nextItems.push(current)
    end for
    return nextItems
end function
