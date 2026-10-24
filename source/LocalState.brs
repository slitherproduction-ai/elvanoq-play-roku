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
    if state.parental = invalid then state.parental = { enabled: false, locked_categories: [] }
    return state
end function

sub saveLocalState(state as Object)
    section = CreateObject("roRegistrySection", "ELVANOQPlay")
    section.Write("local_state", FormatJson(state))
    section.Flush()
end sub

function upsertLocalItem(items as Object, item as Object) as Object
    if item = invalid or item.id = invalid or item.id = "" then return items
    nextItems = []
    replaced = false
    for each current in items
        if current.id = item.id then
            nextItems.push(item)
            replaced = true
        else
            nextItems.push(current)
        end if
    end for
    if not replaced then nextItems.push(item)
    return nextItems
end function

function removeLocalItem(items as Object, itemId as String) as Object
    nextItems = []
    for each current in items
        if current.id <> itemId then nextItems.push(current)
    end for
    return nextItems
end function
