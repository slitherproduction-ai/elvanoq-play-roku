sub init()
    m.poster = m.top.findNode("poster")
    m.title = m.top.findNode("title")
    m.meta = m.top.findNode("meta")
    m.overview = m.top.findNode("overview")
    m.watchFocus = m.top.findNode("watchFocus")
    m.actionStatus = m.top.findNode("actionStatus")
    m.selectedAction = 0
    m.top.observeField("item", "onItemChanged")
    m.top.observeField("metadata", "onMetadataChanged")
    m.top.findNode("eyebrow").font = "font:SmallSystemFont"
    m.top.findNode("eyebrow").color = "0x73B7FFFF"
    m.title.font = "font:LargeBoldSystemFont"
    m.meta.font = "font:SmallSystemFont"
    m.meta.color = "0x9AB2CCFF"
    m.overview.font = "font:MediumSystemFont"
    m.overview.color = "0xD7E3F0FF"
    m.top.findNode("watchLabel").font = "font:MediumBoldSystemFont"
    m.top.findNode("watchLabel").color = "0x06111FFF"
    m.top.findNode("listLabel").font = "font:MediumSystemFont"
    m.top.findNode("laterLabel").font = "font:SmallSystemFont"
    m.actionStatus.font = "font:SmallSystemFont"
    m.actionStatus.color = "0x8FA9C4FF"
    m.top.findNode("similarTitle").font = "font:MediumBoldSystemFont"
    m.top.findNode("similarHint").font = "font:SmallSystemFont"
    updateActionFocus()
end sub

sub onMetadataChanged()
    if m.top.metadata = invalid or m.top.metadata.found <> true or m.top.metadata.item = invalid then return
    details = m.top.metadata.item
    if details.title <> invalid and details.title <> "" then m.title.text = details.title
    if details.overview <> invalid and details.overview <> "" then m.overview.text = details.overview
    if details.release_date <> invalid and details.vote_average <> invalid then
        m.meta.text = details.release_date + "  •  Avaliação " + str(details.vote_average)
    end if
    if details.poster_path <> invalid and details.poster_path <> "" then m.poster.uri = "https://image.tmdb.org/t/p/w780" + details.poster_path
end sub

sub onItemChanged()
    if m.top.item = invalid then return
    item = m.top.item
    m.title.text = item.title
    m.meta.text = item.category + "  •  Conteúdo da sua lista"
    m.overview.text = "Informações complementares, elenco, trailer e recomendações serão exibidos quando os metadados estiverem disponíveis."
    if item.logo <> invalid then m.poster.uri = item.logo
    m.actionStatus.text = ""
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
    if not press then return false
    if key = "back" then
        m.top.closeRequested = true
        return true
    end if
    if key = "right" and m.selectedAction < 2 then
        m.selectedAction = m.selectedAction + 1
        updateActionFocus()
        return true
    end if
    if key = "left" and m.selectedAction > 0 then
        m.selectedAction = m.selectedAction - 1
        updateActionFocus()
        return true
    end if
    if key = "OK" then
        runAction()
        return true
    end if
    return false
end function

function handleKey(event as Object) as Boolean
    return onKeyEvent(event.key, event.press)
end function

sub updateActionFocus()
    positions = [150, 386, 632]
    widths = [220, 230, 205]
    m.watchFocus.translation = [positions[m.selectedAction], 500]
    m.watchFocus.width = widths[m.selectedAction]
    if m.selectedAction = 0 then m.watchFocus.color = "0xFFFFFFFF" else m.watchFocus.color = "0x2E91EFFF"
end sub

sub runAction()
    if m.top.item = invalid then return
    item = m.top.item
    if m.selectedAction = 0 then
        if isParentallyBlocked(item.category) then
            m.actionStatus.text = "Conteúdo protegido. Valide o PIN em Ajustes para assistir."
        else
            m.top.playRequested = item
        end if
    else if m.selectedAction = 1 then
        state = loadLocalState()
        state.favorites = upsertLocalItem(state.favorites, item)
        saveLocalState(state)
        m.actionStatus.text = "Adicionado aos favoritos."
    else
        state = loadLocalState()
        state.watch_later = upsertLocalItem(state.watch_later, item)
        saveLocalState(state)
        m.actionStatus.text = "Adicionado para assistir mais tarde."
    end if
end sub
