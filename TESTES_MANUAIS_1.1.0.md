# Testes manuais — ELVANOQ Play Roku 1.1.0

Rode no aparelho (sideload pelo Developer Mode) antes de enviar. Marque cada item.

## 1. Retomada automática
- [ ] Canal ao vivo tocando: desligue a internet do roteador por **15 s** e religue. Aparece "O sinal parou de chegar. Reconectando…" (ou "Reconectando ao canal… n/3") e o canal volta sozinho.
- [ ] Filme tocando (passe dos 2 min): desligue a internet por **15 s**. O filme volta sozinho **no mesmo ponto**.
- [ ] Repita com a internet desligada por **1 min**: aparece a tela "O sinal não voltou" com "OK • Tentar". Religue a internet e aperte OK: o vídeo volta. Voltar sai do player.
- [ ] Pausar o filme por mais de 30 s **não** dispara reconexão.
- [ ] Sair do player durante a reconexão: nada volta a tocar em segundo plano.

## 2. Formato do ao vivo
- [ ] Ajustes > Formato do ao vivo em "Automático". Abra um canal que só funciona em TS: a primeira abertura troca de formato sozinha; feche e abra de novo, ou troque de canal: começa **direto em TS** (sem o erro inicial).
- [ ] Mude para "HLS (.m3u8)" e depois "TS (.ts)": os canais abrem sempre no formato escolhido, sem trocar sozinhos.

## 3. Rever programas
- [ ] Servidor com catch-up: na TV ao Vivo, num canal com o selo "Replay ou Voltar rápido • Rever programas", aperte Replay (ou ◀◀). A lista de programas passados aparece; OK abre o programa por um dos três formatos.
- [ ] Programa que o servidor não tem: aparece "Este programa não está disponível para rever." e **não** abre o ao vivo.
- [ ] Canal sem catch-up: o selo não aparece e Replay/◀◀ não faz nada.

## 4. Proteção de conteúdo adulto
- [ ] Sem configurar nada, uma categoria "Adultos" (ou "XXX", "+18") pede PIN ao abrir conteúdo.
- [ ] Ajustes > Controle parental (com PIN): a categoria aparece como **Automática**. OK libera (vira **Livre**, abre sem PIN); OK de novo volta a **Automática**.
- [ ] Linha "Proteger conteúdo adulto": OK em **Desligada** libera todas as automáticas; ligar de novo volta a proteger.
- [ ] A contagem "N categorias protegidas" e o selo do menu Ajustes incluem as automáticas.

## 5. Categorias visíveis
- [ ] Ajustes > Categorias visíveis, aba Filmes: OK em uma categoria → **Oculta**. Volte a Filmes: ela sumiu da coluna (e de "Todas" numa lista M3U), do Início e da busca.
- [ ] OK de novo → **Visível**: a categoria volta.
- [ ] Repita nas abas Ao vivo e Séries. Trocar de lista (outro código/servidor) não leva as escolhas junto.

## 6. Visual
- [ ] Ajustes, Controle parental, Categorias visíveis e Sobre com o fundo, rótulos em maiúsculas, foco azul e selos. Sobre mostra "Versão 1.1.0 (build 2)" e o histórico.
- [ ] Voltar dentro de Controle parental/Categorias visíveis volta ao menu de Ajustes; no menu, Voltar vai para o Início.

## 7. Regressão de certificação
- [ ] Deep links: `curl -d '' "http://IP_DA_ROKU:8060/launch/dev?contentId=movie:ID:mp4&mediaType=movie"` e com o app aberto `.../input?contentId=channel:ID&mediaType=live`.
- [ ] Voltar em todas as telas; Voltar no Início fecha o app.
- [ ] Memória baixa (`roAppMemoryMonitor`) e relançar o app.
- [ ] Teste encerrado: tela sem pagamento, QR de pagamento ou link externo.
- [ ] Rodar a **Análise Estática** no Developer Dashboard antes de enviar.
