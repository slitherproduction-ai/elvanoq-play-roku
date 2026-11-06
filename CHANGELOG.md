# Changelog — ELVANOQ Play Roku

## 1.1.1 (build 3)

- **Nova tela de ativação** no padrão do login do Android 2.17.23 (a mesma da LG 1.1.1). Tem logo com slogan, fundo novo, relógio, os três passos e o código da TV em destaque. O botão branco "Entrar com código do servidor" ganhou dois atalhos: "Verificar ativação" (consulta o Portal na hora) e "Como ativar" (aviso padrão da Roku com os passos). O QR do Portal ficou maior (módulos de 8 px, centralizado) e o rodapé mostra o status e a versão. Setas escolhem o botão; OK continua abrindo o teclado do código do servidor.
- Sem chave do aparelho na tela; o Portal vincula pelo código da TV.
- Versão exibida no app vem de `version_name` no manifest.

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
