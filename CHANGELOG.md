# Changelog — ELVANOQ Play Roku

## 1.1.1 (build 3)

- **Nova tela de ativação** no padrão do login do Android 2.17.23 (a mesma da LG 1.1.1). Tem logo com slogan, fundo novo, relógio, os três passos e o código da TV em destaque. O botão branco "Entrar com código do servidor" ganhou dois atalhos: "Verificar ativação" (consulta o Portal na hora) e "Como ativar" (aviso padrão da Roku com os passos). O QR do Portal ficou maior (módulos de 8 px, centralizado) e o rodapé mostra o status e a versão. Setas escolhem o botão; OK continua abrindo o teclado do código do servidor.
- Sem chave do aparelho na tela; o Portal vincula pelo código da TV.
- Versão exibida no app vem de `version_name` no manifest.
- **Desempenho do player** (mesmas correções do Android 2.17.25, para aparelhos fracos):
  - A retomada automática só é armada depois que o vídeo começa a andar, com limites de 20 s no ao vivo e 30 s em filmes e episódios. Um servidor lento na abertura não é mais reiniciado em ciclo.
  - Menos trabalho por segundo: a posição do vídeo é notificada a cada 30 s no ao vivo e 5 s em filmes (1 s só quando há "Pular abertura"), e a barra de tempo só é redesenhada com os controles visíveis. O progresso continua salvo a cada 30 s.
- **Voltar no player** (Android 2.17.29 e 2.17.30):
  - Com os controles na tela, Voltar primeiro fecha os controles. Com a tela limpa, Voltar sai do player. Vale para ao vivo, filmes e séries.
  - Ao sair do ao vivo, a lista de canais volta com o canal que estava tocando selecionado (inclusive depois de canal +/-), e a prévia continua nele.
  - O Roku não tinha confirmação de saída nem grade de canais no player, então nada a remover.
- **Correção: ao vivo reabrindo sozinho** (tela preta e volta). O campo `position` do Video só é atualizado no `notificationInterval`. Com 30 s no ao vivo, a posição parecia parada e a retomada automática (20 s) reabria o canal que estava tocando normalmente. Agora o intervalo é de 4 s (1 s com "Pular abertura"), bem abaixo dos limites de 20/30 s.
- **Busca na TV ao Vivo** (igual ao Android): campo "Pesquisar categoria" no topo da coluna de categorias e "Pesquisar canais" no topo da coluna de canais. Suba da primeira linha até o campo e aperte OK para abrir o teclado da Roku ("Pesquisar", "Limpar" ou "Cancelar"). As categorias são filtradas pelo nome (Todas e Favoritos ficam sempre no topo). Os canais da categoria aberta são filtrados pelo nome ou pelo programa atual do guia, com a contagem "N de M". O filtro de canais continua ao trocar de categoria. Na coluna de canais agora cabem 13 linhas.
- **Fluidez em aparelhos simples** (prompt 1.1.0 revisado, paridade com o Android 2.17.21 a 2.17.28):
  - A prévia do guia agora é parada e descarregada (`control = "stop"` e `content = invalid`) ao abrir o player, o rever ou sair da aba.
  - Listas grandes: a resposta bruta de `get_live_streams`, `get_vod_streams`, `get_series` e das categorias é solta logo depois de montar os itens. Os links da API e dos episódios de série deixaram de ser repetidos em cada item; são montados ao abrir a série.
  - Player: com os controles ocultos, a posição chega a cada 5 s (filmes) ou 30 s (ao vivo); com os controles visíveis, a cada segundo.
- **Resposta mais rápida** (testes no aparelho em 06/11):
  - Filme ou episódio retomado começa direto no ponto salvo (`PlayStart`), sem abrir do início e pular depois, o que bufferizava duas vezes. Vale também para a reconexão automática e para a troca de formato.
  - Imagens no tamanho da tela: capas do TMDB nas grades pedidas em `w342` (antes podiam vir em `original`), destaque do Início em `w1280`, pôster dos detalhes em `w500` em vez de `w780`, e todas decodificadas no tamanho exibido (`loadWidth`/`loadHeight`), inclusive os logos dos canais. Some o aviso "texture larger than the UI resolution" e cai o uso de memória.
  - Não portado: o limite de buffer do Android (o Roku não expõe tamanho de buffer; o sistema já gerencia). A prévia do ao vivo já era parada (`control = "stop"`, que libera o decodificador) ao abrir o player, o rever e ao sair da aba.

## 1.1.0 (build 2) — atualização de dezembro

- **Retomada automática quando o vídeo trava.** A cada 4 s o player confere se a posição avançou. Sem avanço por 12 s no ao vivo ou 20 s em filme/episódio (carregando ou tocando), o mesmo conteúdo é reaberto; filme e episódio voltam ao último ponto. No máximo 3 tentativas seguidas, com o aviso "O sinal parou de chegar. Reconectando…"; depois disso, tela de erro com "Tentar". O contador zera quando o vídeo volta a avançar e o timer para ao sair do player. Quedas por erro de rede também esperam mais entre as tentativas (ao vivo 3/6/9 s, filme 5/10/15 s).
- **Formato do ao vivo lembrado por lista.** Em "Automático", o formato que abriu de fato (HLS ou TS) fica gravado em `liveFormat_<lista>` e é usado primeiro nas próximas aberturas e trocas de canal. Nova opção Ajustes > Formato do ao vivo (Automático, HLS, TS); a escolha manual sempre vence.
- **Rever programas.** Em canais com `tv_archive=1` e `tv_archive_duration>0`, a tecla Replay na TV ao Vivo abre os programas passados do guia. São tentados três formatos de link (timeshift `.m3u8`, timeshift `.ts` com data local e `timeshift.php`). Se nenhum abrir: "Este programa não está disponível para rever." Não cai para o ao vivo.
- **Proteção automática de conteúdo adulto.** Categorias com xxx, porn…, adulto(s)/adulta(s)/adult(s), hentai, erótic…, playboy, sexy hot, nsfw, +18 ou 18+ pedem o PIN sem configuração. Nova opção "Proteger conteúdo adulto" (ligada por padrão). Essas categorias aparecem como "Automática"; liberar grava a exceção `!<nome>` na lista de bloqueios da lista ativa, e liberar de novo volta à regra automática. A contagem de protegidas inclui as automáticas.
- **Categorias visíveis.** Nova tela em Ajustes com abas Ao vivo, Filmes e Séries (Visível/Oculta, OK alterna). Categorias ocultas somem da coluna de categorias, de "Todos", das grades, do Início e da busca. Gravado por lista no registry; nada é apagado. Filtro por assocarray, sem laços aninhados.
- **Novo visual de Ajustes.** Menu com grupos (Proteção e lista, Reprodução, Aplicativo), Controle parental, Categorias visíveis e Sobre com fundo `elvanoq-login-tv-backdrop.jpg`, rótulos de grupo em maiúsculas, foco azul e selos de estado (Bloqueada, Livre, Automática, Visível, Oculta).
- Privacidade: mensagens de erro do vídeo não mostram mais o texto do servidor (só o código); logs sem URLs ou credenciais.

## 1.0.1 (build 1)

- Ajustes de certificação da Roku Store: `rsg_version=1.3`, `supports_input_launch=1`, deep links, `roAppMemoryMonitor`, beacons de lançamento, e-mail pela Roku (RFI), diálogos padrão.

## 1.0.0

- Primeira versão: ativação pelo Portal, TV ao vivo com guia, filmes, séries, busca, Minha Lista e controle parental.
