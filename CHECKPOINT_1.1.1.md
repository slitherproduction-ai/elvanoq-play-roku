# Checkpoint — ELVANOQ Play Roku 1.1.1 (build 3)

Base: `main` 5621a38 (1.1.1 já com a nova ativação e a correção de compilação). Branch `perf/imagens-e-retomada` (PR #5).
Este checkpoint cobre o prompt "Roku 1.1.0" revisado (paridade com o Android 2.17.21 a 2.17.28). A versão no manifest continua **1.1.1 (build 3)**, porque a 1.1.0 (build 2) já existia e a 1.1.1 ainda não foi enviada à loja.

## Itens do prompt e onde estão

| Item | Situação |
|---|---|
| 1. Retomada automática | Feito. Só arma depois do vídeo andar, 20 s ao vivo / 30 s VOD, desarma ao trocar de canal ou conteúdo, 3 tentativas, "O sinal parou de chegar. Reconectando…", erro com "Tentar", contador zera com progresso, Timer de 4 s parado ao sair. **Diferença:** o retorno à posição usa `content.PlayStart` na reabertura em vez de `seek` depois do "playing" (o seek bufferizava duas vezes). |
| 2. Formato do ao vivo por lista | Feito (1.1.0): `liveFormat_<lista>`; manual vence. |
| 3. Rever com 3 formatos | Feito (1.1.0): ordem do prompt, horário local, sem cair para o ao vivo, só com `tv_archive=1` e `tv_archive_duration>0`. |
| 4. Proteção adulta automática | Feito (1.1.0). Exceção gravada como `!<nome>` (os bloqueios do Roku são por nome da categoria). |
| 5. Categorias visíveis | Feito (1.1.0): abas, Visível/Oculta, filtro por assocarray, por lista. Na lista Xtream não existe "Todos"; na M3U as ocultas saem de "Todas". |
| 6. Prévia do guia | Feito: `control = "stop"` + `content = invalid`. |
| 6. Listas grandes | Feito: itens só com os campos usados; resposta bruta solta (`invalid`) logo após montar os itens; links da série montados ao abrir. Catálogo já era sob demanda por categoria (até 5000 por categoria, cache em memória até 10 categorias / 12 mil itens). Nada do JSON fica em nós ou no `m.global`. |
| 6. Memória baixa | Já existia: `roAppMemoryMonitor` → `releaseMemory` mantém só a categoria mais recente (a da tela), limpa a busca e refaz o pool. |
| 6. Sem cache permanente | Mantido: nenhum catálogo no registry. A busca usa `cachefs:` só durante a sessão (apagado na próxima). |
| 6. Player com controles ocultos | Feito: `notificationInterval` 5 s (VOD) / 30 s (ao vivo) com os controles ocultos, 1 s com os controles visíveis ou "Pular abertura". |
| 7. Visual de Ajustes | Feito (1.1.0). |
| Extra | Imagens no tamanho da tela (`w342` nas grades, `w500` nos detalhes, `loadWidth`/`loadHeight`) e retomada com `PlayStart` (log de 06/11). |

## Verificado aqui
- CI do GitHub: XML, **compilação real com o bsc** (desde o PR #4), contrato de ativação e simulador 27/27.
- Local: estrutura dos blocos, escopo das funções por componente, simulador 26/27 (só "relay health" falha, por rede do ambiente).
- Regras mantidas: `rsg_version=1.3`, `supports_input_launch=1`, deep links, beacons, `roAppMemoryMonitor`, diálogos padrão, tela de teste encerrado sem pagamento, User-Agent `ELVANOQPlay-Roku/0.1.88`, nenhum `print` com URL ou credencial.

## Falta (no aparelho)
Ver `TESTES_MANUAIS_1.1.1.md`. Depois: Análise Estática no Developer Dashboard e envio.
