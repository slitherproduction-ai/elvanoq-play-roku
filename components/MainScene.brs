sub init()
    m.brand = m.top.findNode("brand")
    m.headline = m.top.findNode("headline")
    m.description = m.top.findNode("description")
    m.deviceCode = m.top.findNode("deviceCode")
    m.portal = m.top.findNode("portal")
    m.status = m.top.findNode("status")

    m.brand.font = "font:LargeBoldSystemFont"
    m.headline.font = "font:LargeBoldSystemFont"
    m.description.font = "font:MediumSystemFont"
    m.deviceCode.font = "font:LargeBoldSystemFont"
    m.portal.font = "font:MediumSystemFont"
    m.status.font = "font:MediumSystemFont"

    clientId = CreateObject("roDeviceInfo").GetChannelClientId()
    m.deviceCode.text = formatDeviceCode(clientId)
    m.status.text = "Código seguro deste Roku gerado. Aguardando ativação no Portal."
end sub

function formatDeviceCode(clientId as String) as String
    ' Roku does not expose the physical MAC address to channels.
    ' Channel Client ID is persistent, unique to this channel/device and is the supported binding key.
    cleanId = ucase(clientId)
    if cleanId = "" then return "ROKU-CÓDIGO-INDISPONÍVEL"
    return "ROKU-" + left(cleanId, 8) + "-" + mid(cleanId, 9)
end function
