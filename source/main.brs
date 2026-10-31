sub Main(args as Dynamic)
    screen = CreateObject("roSGScreen")
    port = CreateObject("roMessagePort")
    screen.SetMessagePort(port)
    scene = screen.CreateScene("MainScene")
    screen.Show()
    scene.SetFocus(true)

    ' Deep linking: na abertura (args) e com o app ja aberto (roInput), pela busca e voz da Roku.
    input = CreateObject("roInput")
    input.SetMessagePort(port)
    if args <> invalid and type(args) = "roAssociativeArray" and args.contentId <> invalid and args.mediaType <> invalid then
        scene.deepLink = { contentId: args.contentId, mediaType: args.mediaType }
    end if

    while true
        message = wait(0, port)
        messageType = type(message)
        if messageType = "roSGScreenEvent" and message.isScreenClosed() then return
        if messageType = "roInputEvent" and message.IsInput() then
            info = message.GetInfo()
            if info <> invalid and info.contentId <> invalid and info.mediaType <> invalid then scene.deepLink = { contentId: info.contentId, mediaType: info.mediaType }
        end if
    end while
end sub
