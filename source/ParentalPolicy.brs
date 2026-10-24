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

function isParentallyBlocked(category as String) as Boolean
    if parentalSessionUnlocked() then return false
    section = CreateObject("roRegistrySection", "ELVANOQPlay")
    locks = ParseJson(section.Read(parentalScopeKey()))
    if locks = invalid or type(locks) <> "roArray" then return false
    for each lockedCategory in locks
        if lcase(lockedCategory) = lcase(category) then return true
    end for
    return false
end function
