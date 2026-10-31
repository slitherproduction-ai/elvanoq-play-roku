'Contorno de selecao para grades que nao recebem o foco nativo.
' O AppShell fica com o foco e repassa as teclas; a PosterGrid sem foco nao
' desenha selecao, entao um Rectangle atras do poster faz esse papel.
sub placeFocusFrame(frame as Object, grid as Object, index as Integer, columns as Integer, cellWidth as Integer, cellHeight as Integer, gapX as Integer, gapY as Integer)
    if frame = invalid or grid = invalid then return
    if index < 0 or grid.content = invalid or index >= grid.content.getChildCount() then
        frame.visible = false
        return
    end if
    column = index mod columns
    row = int(index / columns)
    origin = grid.translation
    frame.translation = [origin[0] + column * (cellWidth + gapX) - 8, origin[1] + row * (cellHeight + gapY) - 8]
    frame.width = cellWidth + 16
    frame.height = cellHeight + 16
    frame.visible = true
end sub
