' Tipografia do app: Inter (mesma fonte do app Android), em tamanhos de tela 1080p.
' A Roku reduz automaticamente em TVs 720p.
function appFont(size as Integer, weight as String) as Object
    font = CreateObject("roSGNode", "Font")
    if weight = "bold" then
        font.uri = "pkg:/fonts/Inter-Bold.ttf"
    else if weight = "semibold" then
        font.uri = "pkg:/fonts/Inter-SemiBold.ttf"
    else if weight = "medium" then
        font.uri = "pkg:/fonts/Inter-Medium.ttf"
    else
        font.uri = "pkg:/fonts/Inter-Regular.ttf"
    end if
    font.size = size
    return font
end function
