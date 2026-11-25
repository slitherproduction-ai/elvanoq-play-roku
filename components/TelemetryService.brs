sub init()
    m.top.functionName = "runTask"
end sub

sub runTask()
    if m.top.payload = "" then return
    transfer = CreateObject("roUrlTransfer")
    transfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
    transfer.InitClientCertificates()
    transfer.SetUrl("https://xrrgjssvdqvtrqhxpask.supabase.co/functions/v1/tv-telemetry")
    transfer.AddHeader("Content-Type", "application/json")
    transfer.AddHeader("Accept", "application/json")
    port = CreateObject("roMessagePort")
    transfer.SetPort(port)
    if transfer.AsyncPostFromString(m.top.payload) <> true then return
    event = wait(15000, port)
    if type(event) = "roUrlEvent" then
        m.top.status = event.GetResponseCode()
    else
        transfer.AsyncCancel()
    end if
end sub
