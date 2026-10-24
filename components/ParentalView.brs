sub init()
    m.dots = m.top.findNode("dots")
    m.status = m.top.findNode("status")
    m.pin = ""
    m.top.findNode("title").font = "font:LargeBoldSystemFont"
    m.top.findNode("description").font = "font:MediumSystemFont"
    m.dots.font = "font:LargeBoldSystemFont"
    m.status.font = "font:SmallSystemFont"
    m.status.color = "0x8FA9C4FF"
    m.top.findNode("lockedCategories").font = "font:MediumSystemFont"
end sub

sub enterDigit(digit as String)
    if len(m.pin) >= 4 then return
    m.pin = m.pin + digit
    updateDots()
    if len(m.pin) = 4 then validatePin()
end sub

sub clearDigit()
    if len(m.pin) > 0 then m.pin = left(m.pin, len(m.pin) - 1)
    updateDots()
end sub

sub updateDots()
    text = ""
    for index = 1 to 4
        if index <= len(m.pin) then text = text + "●  " else text = text + "○  "
    end for
    m.dots.text = text
end sub

sub validatePin()
    section = CreateObject("roRegistrySection", "ELVANOQPlay")
    saved = section.Read("parental_pin")
    if saved = invalid or saved = "" then saved = "0000"
    if m.pin = saved then
        m.status.text = "Controle parental desbloqueado nesta sessão."
        section.Write("parental_session", "unlocked")
        section.Flush()
    else
        m.status.text = "PIN incorreto. Tente novamente."
        m.pin = ""
        updateDots()
    end if
end sub
