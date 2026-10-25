# ELVANOQ Play - Roku

Aplicativo Roku do ELVANOQ Play, criado em BrightScript e SceneGraph.

## Versão

0.1.41

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

Favoritos, assistir mais tarde, continuar assistindo, histórico e preferências parentais têm uma base local por dispositivo. As coleções usam identificador de item para evitar duplicações e não armazenam credenciais, URLs ou identificadores técnicos. Canais usam um identificador local baseado no `tvg-id` ou em metadados públicos do M3U, nunca na URL de stream. Ao carregar e gravar o estado, a camada local remove campos não permitidos; a reprodução é sempre resolvida novamente a partir do catálogo autorizado em memória.

Registros locais legados cujo identificador corresponda a uma URL são descartados automaticamente na próxima carga para remover esse dado. O usuário pode favoritar novamente o canal a partir do catálogo sincronizado.

Navegação: Voltar fecha primeiro player e detalhes; nas seções de aplicativo, retorna à Home de forma consistente. Em Busca, o primeiro Voltar limpa a consulta ativa; o próximo retorna à Home.

Bloqueios parentais são separados por lista ativa e verificados antes de iniciar preview ou reprodução. Uma sessão validada por PIN libera apenas o uso atual do aplicativo.

Em Ajustes, digite o PIN e use ↑/↓ para escolher uma categoria da lista atual; OK bloqueia ou desbloqueia a categoria. As regras permanecem isoladas por lista ativa e são verificadas antes de preview, player, busca, Home e coleções locais.

Em TV ao Vivo, a lista central exibe logotipo e nome do canal quando o M3U autorizado fornecer `tvg-logo`; caso contrário, o app mantém a linha limpa e legível, sem imagem substituta enganosa.

Quando a configuração da lista autorizada fornecer `epg_url` ou `xmltv_url`, o app baixa o XMLTV em tarefa HTTP separada e correlaciona a programação pelo `tvg-id` do M3U. A tela mostra apenas os primeiros itens retornados para aquele canal; sem URL ou correspondência, mantém o estado explícito de guia indisponível. A origem XMLTV não é gravada no registro local.

O PlayerView também aplica essa verificação centralmente: acessos futuros por Home, busca, favoritos, histórico, deep link ou troca rápida não podem iniciar conteúdo protegido sem PIN válido.

## Player Roku

Filmes e séries da lista abrem uma tela de detalhes com as ações Assistir, Minha Lista e Assistir mais tarde. As duas últimas são persistidas localmente, sem URL nem credenciais. A ação Assistir aplica a política parental e encaminha apenas a URL de stream disponível em memória ao PlayerView.

Na tela de detalhes, Minha Lista e Assistir mais tarde são alternâncias: OK adiciona quando o item ainda não existe e remove quando já está salvo. Os rótulos exibem o estado atual da coleção local.

Quando a licença está ativa, a tela consulta `roku-metadata` no Portal para enriquecer título, sinopse, pôster e avaliação. O Portal valida o aparelho e usa o segredo TMDB exclusivamente no servidor; o canal nunca recebe, armazena ou registra esse token.

Para séries, o mesmo fluxo solicita temporadas e episódios reais. No controle remoto, ↑/↓ troca a temporada selecionada na própria tela de detalhes. Trailer e recomendações só aparecem quando retornados pelo TMDB; não há catálogo ou episódios inventados no canal. A reprodução de episódios depende de a lista autorizada fornecer a URL desse episódio.

A tela de detalhes apresenta a hierarquia adaptada do Android/Prime para Roku: metadados, gêneros retornados pelo TMDB, ações principais, painel de temporada/episódios e recomendações. O canal só exibe informações que tenham sido retornadas pela fonte autorizada.

Em Busca, OK abre o teclado nativo do Roku e filtra somente o catálogo autorizado. Depois da consulta, ←/→/↑/↓ percorrem os resultados e OK abre os detalhes; o botão * alterna entre Todos, Filmes, Séries e Canais, e Voltar limpa a consulta para iniciar outra. Minha Lista alterna com ←/→ entre assistir mais tarde, favoritos, continuar assistindo e histórico locais; ↑/↓ escolhem um item e OK abre os detalhes somente após resolver o item no catálogo autorizado em memória. Itens com progresso salvo retomam no player a partir da posição registrada. Em TV ao Vivo, ← alterna para as categorias, ↑/↓ seleciona a categoria ou o canal em foco, → inicia a prévia, OK abre o canal no player e * adiciona/remove o canal de Favoritos. A prévia é parada ao trocar de categoria, sair da área ou abrir o player.

Na Home, o destaque prioriza um conteúdo em andamento e, na ausência dele, um favorito resolvido pelo catálogo atual. O primeiro trilho mostra continuar assistindo, favoritos ou uma seleção da lista, sem ler URL ou credenciais do estado local.

A Home alterna automaticamente entre até três destaques reais. Quando a lista autorizada fornecer os atributos de curadoria, a ordem é: recém-adicionado (`added`, `date` ou `release-date`), destaque semanal (`featured`, `weekly-featured` ou `is-featured`) e mais bem avaliado (`rating`, `tvg-rating` ou `score`). Sem esses atributos, os destaques usam continuar assistindo, favoritos e catálogo. A rotação só acontece enquanto a Home está ativa e não busca conteúdo fora da lista autorizada.

O catálogo diferencia canais ao vivo, filmes e séries pelo grupo recebido na lista: grupos contendo `filme`, `movie` ou `vod` vão para Filmes; grupos contendo `série`, `serie` ou `series` vão para Séries; os demais permanecem em TV ao Vivo. A classificação não altera a URL do stream nem inventa itens; listas com nomes de grupo diferentes precisarão de ajuste após a validação no Roku físico.

Em Busca, o filtro `*` alterna entre Todos, Filmes, Séries e Canais usando a classificação recebida do catálogo. A grade informa a quantidade retornada e mantém a mensagem específica quando o tipo escolhido não possui itens correspondentes.

Filmes e Séries exibem até doze pôsteres por vez. Use `*` para avançar a página; depois da última, a navegação retorna à primeira. Isso evita preencher a grade de uma só vez em dispositivos Roku com menos memória.

Dentro da grade de Filmes e Séries, ←/→/↑/↓ movem o foco entre os pôsteres e OK abre o título selecionado. As setas não trocam de seção enquanto a grade estiver ativa; Voltar retorna à Home conforme o padrão do canal.

Na Home, ↓ entra nos carrosséis e ↑ retorna ao destaque. Em cada carrossel, ←/→ move o foco e OK abre o item: canais ao vivo iniciam a reprodução e filmes/séries abrem os detalhes. A navegação é mantida somente sobre os itens da lista autorizada.

Em TV ao Vivo, a lista lateral mantém uma janela de oito canais. Ao navegar acima ou abaixo dessa janela, a lista avança de forma incremental, sem reconstruir o catálogo completo nem perder a seleção, a prévia ou o guia do canal atual.

Em Ajustes, o PIN inicial é `0000`. Depois de desbloquear a sessão, use `*` para iniciar a troca e digite o novo PIN de quatro dígitos. O PIN não é exibido em texto e os bloqueios continuam separados por lista ativa.

Para conteúdo sob demanda, o botão Assistir dos detalhes e o destaque da Home consultam o progresso local associado ao item e retomam da última posição quando ela existir. Conteúdo marcado como concluído começa do início. A posição é sempre resolvida contra o catálogo autorizado em memória.

Quando o stream informa duração, o player marca o título como concluído ao chegar a 95% ou ao terminar. O item é removido de Continuar assistindo e permanece somente no Histórico. Streams ao vivo não entram nessa regra.

O desbloqueio parental vale apenas enquanto o canal permanece aberto. Ao iniciar o ELVANOQ Play novamente, a sessão desbloqueada é removida e o PIN volta a ser exigido para conteúdo ou categorias protegidas.

Após desbloquear o Controle Parental, ←/→ alterna entre Categorias e Canais e títulos. Use ↑/↓ para selecionar e OK para bloquear ou desbloquear. Os bloqueios individuais usam apenas o identificador local do catálogo, são separados pela lista ativa e são verificados antes de prévia, detalhes e reprodução.

TV ao Vivo exibe seis categorias por vez e percorre as demais de forma incremental ao navegar com ↑/↓. Assim, listas grandes continuam acessíveis sem aumentar a quantidade de elementos visuais simultâneos.

Minha Lista, Favoritos, Continuar e Histórico exibem doze itens por vez. Ao navegar além da janela atual com ↑/↓, a lista percorre os itens incrementalmente e preserva o item selecionado para abrir com OK.

Depois da ativação, o canal continua consultando `roku-license-status` em intervalo leve de 60 segundos sem interromper a navegação. A sincronização da lista acontece uma vez por ativação; se o Portal informar expiração ou bloqueio, o acesso ao app é removido até que a licença volte a ficar ativa.

Os dois carrosséis da Home mantêm uma janela leve: cinco itens no primeiro trilho e sete no segundo. Ao navegar com ←/→ além da janela, os itens seguintes da lista autorizada são exibidos sem montar todos os pôsteres de uma vez.

No destaque da Home, ←/→ alterna entre Assistir e Minha Lista; OK executa a ação selecionada. Adicionar/remover usa somente a coleção local protegida e a reprodução ainda recebe a URL exclusivamente do catálogo em memória.

O componente PlayerView usa uma linguagem visual em camadas adaptada da experiência Android: TopBar discreta, identificação do conteúdo, OSD inferior, timeline, foco individual de controles e painel contextual de áudio/legendas. Ele oferece saída pelo botão Voltar, avanço/retorno de 10 segundos em VOD, pausa, progresso persistido a cada 15 segundos e histórico local. O OSD permanece visível durante a interação e se oculta após cinco segundos de reprodução; OK, setas ou * o exibem novamente. Em TV ao Vivo, ↑/↓ faz troca rápida apenas entre os canais da categoria atual, mantidos somente em memória; cada canal é verificado novamente pela política parental antes de iniciar. O painel apresenta apenas as faixas efetivamente informadas pelo stream e a seleção usa os identificadores nativos retornados pelo Video node. Informações enriquecidas permanecem condicionadas à integração TMDB; o app não inventa metadados quando ela não está configurada. A reprodução real será validada com uma lista autorizada em aparelho físico.

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
