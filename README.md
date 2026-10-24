# ELVANOQ Play — Roku

Aplicativo Roku do ELVANOQ Play, criado em BrightScript + SceneGraph.

## Identificador do dispositivo

Roku não disponibiliza o endereço MAC físico para canais. O aplicativo usa `roDeviceInfo.GetChannelClientId()`, identificador persistente e exclusivo deste canal naquele aparelho, como chave técnica de ativação. A interface mostra esse valor com o prefixo `ROKU-`.

O Portal deve receber esse identificador em um fluxo Roku próprio; ele não deve ser convertido, chamado ou armazenado como MAC.

## Estado inicial

- Tela de ativação Roku.
- Código persistente por aparelho/canal.
- Portal oficial indicado: `https://elvanoqplay.app`.
- Ainda sem lista, player ou publicação na Channel Store.
