sub init()
    m.focusRail = m.top.findNode("focusRail")
    m.sectionEyebrow = m.top.findNode("sectionEyebrow")
    m.sectionTitle = m.top.findNode("sectionTitle")
    m.sectionDescription = m.top.findNode("sectionDescription")
    m.sectionHint = m.top.findNode("sectionHint")
    m.navItems = [
        m.top.findNode("navHome"),
        m.top.findNode("navLive"),
        m.top.findNode("navMovies"),
        m.top.findNode("navSeries"),
        m.top.findNode("navSearch"),
        m.top.findNode("navLibrary"),
        m.top.findNode("navSettings")
    ]
    for each item in m.navItems
        item.font = "font:MediumSystemFont"
        item.color = "0xAFC2D9FF"
    end for
    m.sectionEyebrow.font = "font:MediumSystemFont"
    m.sectionEyebrow.color = "0x73B7FFFF"
    m.sectionTitle.font = "font:LargeBoldSystemFont"
    m.sectionDescription.font = "font:MediumSystemFont"
    m.sectionDescription.color = "0xC4D2E0FF"
    m.sectionHint.font = "font:SmallSystemFont"
    m.sectionHint.color = "0x8FA9C4FF"
    m.selectedIndex = 0
    showSection()
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
    if not press then return false
    if key = "down" and m.selectedIndex < m.navItems.count() - 1 then
        m.selectedIndex = m.selectedIndex + 1
        showSection()
        return true
    end if
    if key = "up" and m.selectedIndex > 0 then
        m.selectedIndex = m.selectedIndex - 1
        showSection()
        return true
    end if
    return key = "OK"
end function

sub showSection()
    for index = 0 to m.navItems.count() - 1
        if index = m.selectedIndex then
            m.navItems[index].color = "0xFFFFFFFF"
        else
            m.navItems[index].color = "0xAFC2D9FF"
        end if
    end for
    m.focusRail.translation = [20, 210 + (m.selectedIndex * 70)]

    sections = [
        { title: "Início", description: "Seus destaques, conteúdos recentes e continuar assistindo aparecerão aqui quando a lista deste Roku for sincronizada.", hint: "Use as setas para navegar pelo menu." },
        { title: "TV ao Vivo", description: "Categorias, canais, preview com áudio e guia de programação serão exibidos nesta área.", hint: "O preview será descarregado ao sair desta tela." },
        { title: "Filmes", description: "Catálogo de filmes, detalhes, favoritos e continuar assistindo.", hint: "A lista sincronizada do Portal abastecerá este catálogo." },
        { title: "Séries", description: "Séries, temporadas expansíveis e episódios em uma experiência otimizada para controle remoto.", hint: "A navegação mantém o foco sempre visível." },
        { title: "Busca", description: "Busca global por canais, filmes, séries e episódios.", hint: "Digite usando o teclado virtual do Roku quando o catálogo estiver disponível." },
        { title: "Minha Lista", description: "Favoritos, assistir mais tarde e histórico de reprodução deste dispositivo.", hint: "Os dados serão persistidos localmente e sincronizados quando aplicável." },
        { title: "Ajustes", description: "Perfil, controle parental, suporte e informações do dispositivo.", hint: "As opções de licença continuam disponíveis no Portal ELVANOQ." }
    ]
    section = sections[m.selectedIndex]
    m.sectionTitle.text = section.title
    m.sectionDescription.text = section.description
    m.sectionHint.text = section.hint
end sub
