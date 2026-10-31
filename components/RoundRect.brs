sub init()
    m.shape = m.top.findNode("shape")
    m.border = m.top.findNode("border")
    applyShape()
    applyColor()
end sub

sub applyShape()
    width = m.top.width
    height = m.top.height
    m.shape.width = width
    m.shape.height = height
    smallest = width
    if height < smallest then smallest = height
    radius = m.top.radius
    if radius * 2 > smallest then radius = int(smallest / 2)
    if m.top.mask then
        m.shape.uri = "pkg:/images/ui/mask_r" + nearestRadius([8, 10, 12, 14, 16], radius).ToStr() + ".9.png"
    else if m.top.stroke > 0 then
        m.shape.uri = ringUri(radius, m.top.stroke)
    else
        m.shape.uri = "pkg:/images/ui/fill_r" + nearestRadius([3, 4, 6, 7, 8, 10, 12, 14, 16, 20, 24, 28, 32], radius).ToStr() + ".9.png"
    end if
    if m.top.borderColor <> "" and not m.top.mask then
        m.border.width = width
        m.border.height = height
        m.border.uri = ringUri(radius, 2)
        setTint(m.border, m.top.borderColor)
        m.border.visible = true
    else
        m.border.visible = false
    end if
end sub

function ringUri(radius as Integer, stroke as Integer) as String
    thickness = stroke
    if thickness > 4 then thickness = 4
    if thickness < 2 then thickness = 2
    return "pkg:/images/ui/ring_r" + nearestRadius([8, 10, 12, 14, 16, 18, 20, 22, 24], radius).ToStr() + "_t" + thickness.ToStr() + ".9.png"
end function

' Maior raio disponivel que nao passa do pedido (ou o menor de todos).
function nearestRadius(options as Object, wanted as Integer) as Integer
    chosen = options[0]
    for each value in options
        if value <= wanted then chosen = value
    end for
    return chosen
end function

sub applyColor()
    setTint(m.shape, m.top.color)
end sub

' "0xRRGGBBAA": a cor vai para o blendColor e o alfa para a opacidade da imagem.
sub setTint(node as Object, value as String)
    if len(value) < 10 then
        node.blendColor = value
        node.opacity = 1.0
        return
    end if
    node.blendColor = left(value, 8) + "FF"
    alpha = Val(right(value, 2), 16)
    node.opacity = alpha / 255.0
end sub
