# ELVANOQ Play - Roku

Aplicativo Roku do ELVANOQ Play, criado em BrightScript e SceneGraph.

## Versão

0.1.13

## Fluxo de ativação

1. Na abertura, o app obtém exclusivamente roDeviceInfo.GetChannelClientId().
2. O identificador técnico é transformado somente para apresentação em um código visual no padrão ROKU-XXXXXXXX-XXXXXXXX.
3. Na primeira abertura, o app cria uma chave aleatória persistente no registro local do Roku. Ela não é mostrada ao cliente.
4. O app chama roku-device-register, seguido de roku-license-status, enviando a chave somente por HTTPS ao Portal.
5. Enquanto estiver pendente, o status é consultado a cada 60 segundos, sem bloquear a tela.
6. O cliente abre elvanoqplay.app e vincula a TV com o Código Roku mostrado.
7. Quando a licença fica ativa, o app prepara a transição para a Home.
8. Após a ativação, o app solicita roku-playlist-sync para receber a configuração da lista. As credenciais retornadas não são mostradas nem registradas em logs.

O app persiste apenas metadados não sensíveis da lista para identificar a sincronização local. URLs, usuários e senhas não são gravados no registro local.

## Estado local

Favoritos, assistir mais tarde, continuar assistindo, histórico e preferências parentais têm uma base local por dispositivo. As coleções usam identificador de item para evitar duplicações e não armazenam credenciais, URLs ou identificadores técnicos. Ao carregar e gravar o estado, a camada local remove campos não permitidos; a reprodução é sempre resolvida novamente a partir do catálogo autorizado em memória.

Bloqueios parentais são separados por lista ativa e verificados antes de iniciar preview ou reprodução. Uma sessão validada por PIN libera apenas o uso atual do aplicativo.

O PlayerView também aplica essa verificação centralmente: acessos futuros por Home, busca, favoritos, histórico, deep link ou troca rápida não podem iniciar conteúdo protegido sem PIN válido.

## Player Roku

Filmes e séries da lista abrem uma tela de detalhes com as ações Assistir, Minha Lista e Assistir mais tarde. As duas últimas são persistidas localmente, sem URL nem credenciais. A ação Assistir aplica a política parental e encaminha apenas a URL de stream disponível em memória ao PlayerView.

Quando a licença está ativa, a tela consulta `roku-metadata` no Portal para enriquecer título, sinopse, pôster e avaliação. O Portal valida o aparelho e usa o segredo TMDB exclusivamente no servidor; o canal nunca recebe, armazena ou registra esse token.

Para séries, o mesmo fluxo solicita temporadas e episódios reais. No controle remoto, ↑/↓ troca a temporada selecionada na própria tela de detalhes. Trailer e recomendações só aparecem quando retornados pelo TMDB; não há catálogo ou episódios inventados no canal. A reprodução de episódios depende de a lista autorizada fornecer a URL desse episódio.

Em Busca, OK abre o teclado nativo do Roku e filtra somente o catálogo autorizado. Depois da consulta, ←/→/↑/↓ percorrem os resultados e OK abre os detalhes; o botão * reabre o teclado para uma nova consulta. Minha Lista alterna com ←/→ entre assistir mais tarde, favoritos, continuar assistindo e histórico locais; ↑/↓ escolhem um item e OK abre os detalhes somente após resolver o item no catálogo autorizado em memória. Itens com progresso salvo retomam no player a partir da posição registrada. Em TV ao Vivo, ← alterna para as categorias, ↑/↓ seleciona a categoria ou o canal em foco, → inicia a prévia, OK abre o canal no player e * adiciona/remove o canal de Favoritos. A prévia é parada ao trocar de categoria, sair da área ou abrir o player.

Na Home, o destaque prioriza um conteúdo em andamento e, na ausência dele, um favorito resolvido pelo catálogo atual. O primeiro trilho mostra continuar assistindo, favoritos ou uma seleção da lista, sem ler URL ou credenciais do estado local.

No destaque da Home, ←/→ alterna entre Assistir e Minha Lista; OK executa a ação selecionada. Adicionar/remover usa somente a coleção local protegida e a reprodução ainda recebe a URL exclusivamente do catálogo em memória.

O componente PlayerView usa o player nativo Roku e oferece saída pelo botão Voltar, avanço/retorno de 10 segundos em VOD, pausa, progresso persistido a cada 15 segundos e histórico local. Em TV ao Vivo, ↑/↓ faz troca rápida apenas entre os canais da categoria atual, mantidos somente em memória; cada canal é verificado novamente pela política parental antes de iniciar. O OSD apresenta as opções de áudio e legenda somente quando o stream informa faixas compatíveis; a seleção usa os identificadores nativos retornados pelo Video node. Informações enriquecidas (sinopse, elenco, trailer e recomendações) permanecem condicionadas à integração TMDB; o app não inventa metadados quando ela não está configurada. A reprodução real será validada com uma lista autorizada em aparelho físico.

O identificador técnico nunca é exibido completo, registrado em logs ou tratado como endereço físico.

## Estados tratados

Ativo, pendente, expirado, bloqueado, offline e erro de API.

## Testes locais

1. Instale o canal pelo fluxo manual de sideload do Roku Developer Mode.
2. Abra o app e confira o código no formato ROKU-XXXXXXXX-XXXXXXXX.
3. Confirme o registro/atualização no Portal.
4. Vincule o código e aguarde a próxima consulta de licença.
5. Valide os cenários pendente, ativo, expirado, bloqueado, sem rede e resposta inválida.
6. Com uma lista autorizada que contenha categorias de filmes ou séries, abra um item, inclua-o em Minha Lista e em Assistir mais tarde, retorne à coleção, abra os detalhes por OK e confirme a persistência após reiniciar o canal.
7. Só em Roku físico, valide a troca de foco entre categorias e canais, filtro de categoria, favorito com o botão *, prévia em →, abertura em tela cheia com OK, retorno pelo botão Voltar e conteúdo protegido com uma categoria bloqueada.

Este repositório não inclui pacote de sideload e não publica na Roku Channel Store.
