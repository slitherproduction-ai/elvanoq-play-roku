# Checkpoint — ELVANOQ Play Roku 1.1.0 (build 2)

Branch `release/1.1.0`, a partir de `main` 4448986 (1.0.1 publicada na Roku Store, canal 890395).

## O que foi verificado aqui (sem aparelho Roku)

| Verificação | Resultado |
|---|---|
| XML de todos os componentes (21) | OK, todos abrem no parser |
| Estrutura dos blocos BrightScript (sub/function/if/for/while) | OK em `components/` e `source/` |
| Funções chamadas existem no escopo de cada componente (scripts do XML) | OK, 0 pendências |
| `callFunc` só chama funções declaradas no `<interface>` | OK |
| `onChange` dos campos aponta para sub existente | OK |
| `tests/roku_preflight_simulator.py` | 26/27. A falha é só "relay health", que precisa de internet (falha igual na `main`) |
| Manifest | `major 1`, `minor 1`, `build 2`, `rsg_version=1.3`, `supports_input_launch=1` mantidos |
| User-Agent do relay | `ELVANOQPlay-Roku/0.1.88` mantido |
| Logs e tela | nenhum `print` com URL, usuário, senha ou token; erro do vídeo mostra só o código |
| Regra da CI "sem MAC" | OK |
| Regex de conteúdo adulto (mesmo padrão, em Python) | 30 nomes, 0 erros: 18 positivos (Adultos, Adulta, XXX Filmes, Pornô HD, Hentai, Eróticos, Playboy TV, Sexy Hot, NSFW, Filmes +18, 18+ Night, [+18] Canais…) e 12 negativos (Esportes, Canal 180, 2018, +180, Filmes 18, Sexy, Hotel…). Nota: "adult" também pega palavras como "adulterado", como pede a regra |
| Prévia visual 1920x1080 | Ajustes/Sobre, Controle parental e Categorias visíveis renderizadas e conferidas |

O compilador `bsc` (brighterscript) não pôde ser baixado neste ambiente; a CI do GitHub roda a compilação no push.

## Não mudou
- Deep links (`movie:`, `episode:`, `series:`, `channel:`), beacons, `roAppMemoryMonitor`, `StandardKeyboardDialog`/`StandardMessageDialog`.
- Tela de teste encerrado: sem pagamento, sem QR de pagamento, sem link externo.
- Ativação, Portal, licença e catálogo sob demanda.

## Decisões e diferenças em relação ao prompt
- **Exceção da proteção adulta por nome (`!<nome>`).** Os bloqueios do app já são gravados por nome de categoria (lista M3U não tem id), então a exceção segue o mesmo formato, na mesma chave por servidor.
- **"Todos".** Na lista Xtream (sob demanda) não existe "Todos"; o filtro vale para a coluna de categorias, Início, busca e favoritos. Na lista M3U, o filtro também tira os itens de "Todas".
- **Rever programas** abre pela tecla Replay (ou Voltar rápido, para controles sem Replay) no canal selecionado da TV ao Vivo, com a lista de programas passados do servidor (`get_simple_data_table`).
- **Tela Sobre** e **Formato do ao vivo** não existiam; foram criadas no novo menu de Ajustes.
- Reconexão por erro de rede (além do travamento sem erro): espera crescente entre tentativas (ao vivo 3/6/9 s, filme 5/10/15 s) para uma queda de 15 s voltar sozinha.

## Testes manuais pendentes (no aparelho)
Ver `TESTES_MANUAIS_1.1.0.md`.
