sub init()
    m.top.setFocus(true)
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
    if press <> true then return false
    if key = "OK" then
        m.top.selected = not m.top.selected
        return true
    end if
    return false
end function
