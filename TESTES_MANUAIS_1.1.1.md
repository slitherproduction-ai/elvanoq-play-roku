# Testes manuais — ELVANOQ Play Roku 1.1.1 (build 3)

## Ativação (nova tela)
- [ ] O app abre na nova tela de ativação. O ícone do canal na tela inicial do Roku mostra a nova logo.
- [ ] Setas alternam entre "Entrar com código do servidor", "Verificar ativação" e "Como ativar".
- [ ] "Verificar ativação" mostra "Verificando a ativação…" e depois o status. "Como ativar" abre o aviso e fecha com "Entendi" ou Voltar.
- [ ] QR centralizado abre o Portal com o código da TV. Ativação pelo Portal e login por código do servidor funcionam.

## Retomada automática
- [ ] Canal ao vivo e filme **já tocando**: desligar a internet por **25 s**. Volta sozinho, e o filme volta ao mesmo ponto.
- [ ] Internet desligada por **2 min**: aparece "O sinal não voltou" com "Tentar".
- [ ] Canal de **servidor lento** (abre em mais de 20 s): não é reiniciado antes de começar.
- [ ] Trocar de canal no meio de uma reconexão: o novo canal não herda a contagem.

## Fluidez
- [ ] Abrir um canal pelo guia **com a prévia tocando**: a prévia para e o canal abre sem engasgar. Voltar ao guia: a prévia volta.
- [ ] Lista grande (**30 mil filmes ou mais**) num **Roku Express**: sincroniza sem fechar o canal; Filmes, Séries e Busca continuam fluidos.
- [ ] Abrir uma série (lista Xtream): temporadas e episódios carregam e tocam.
- [ ] "Continuar assistindo" abre direto no ponto salvo, sem começar do início.
- [ ] Abrir os detalhes de vários filmes: no log (porta 8085), não aparece `sg.scene.bitmap.big`.
- [ ] No player com os controles ocultos, apertar OK: a barra de tempo aparece certa e anda a cada segundo.

## Recursos da 1.1.0
- [ ] Canal que só abre em TS com "Automático": a segunda abertura já começa em TS.
- [ ] Rever programa num servidor com catch-up abre por um dos três formatos; num canal sem catch-up a opção não aparece.
- [ ] Categoria "Adultos" pede PIN sem configurar nada; liberar e bloquear de novo funciona; desligar a opção libera todas as automáticas.
- [ ] Ocultar uma categoria some da lista (e de "Todas" na M3U); mostrar de novo volta.

## Regressão de certificação
- [ ] Deep links (`movie:`, `episode:`, `series:`, `channel:`) na abertura e com o app aberto.
- [ ] Voltar em todas as telas; Voltar no Início fecha o app.
- [ ] Memória baixa e relançamento.
- [ ] **Análise Estática** no Developer Dashboard antes de enviar.
