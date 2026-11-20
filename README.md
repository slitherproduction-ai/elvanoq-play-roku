# ELVANOQ Roku Sim

> Fica numa branch própria (`roku-sim`) do repositório `elvanoq-play-roku`, sem misturar com o canal na `main`.

Simulador de Roku para Android, no mesmo modelo do ELVANOQ webOS Sim e do ELVANOQ Samsung Sim.
Roda o **próprio código do canal** (BrightScript + SceneGraph) no [brs-engine](https://github.com/lvcabral/brs-engine)
(MIT, de Marcelo Lv Cabral), um interpretador de BrightScript feito para navegador.

## O que simula
- **Aparelhos Roku**: Express (HD), Express 4K, Streaming Stick 4K, Ultra 2024, Roku TV 4K e HD, OS 15.1 e 16,
  e uma Roku antiga com OS 14.6 para ver o aviso de firmware mínimo (`rsg_version=1.3` exige 15.1).
  Cada um com o código do modelo, firmware e resolução da interface (720p/1080p) que o `roDeviceInfo` devolve.
- **Canal direto do GitHub**: baixa qualquer branch (inclusive a de um PR) e monta o pacote **igual ao ZIP do workflow**
  (`manifest source components images fonts locale`), ou o repositório inteiro. Também importa o ZIP de sideload ou o artefato
  do Actions (zip dentro de zip), pelo seletor ou por "Abrir com".
- **Conferência do pacote**: manifest (version_name × major.minor.build, ícones e splash), Main(), XML dos componentes,
  scripts que faltam e todo caminho `pkg:/…` escrito no código que não está no pacote.
- **Rede como na Roku**: tudo que o canal pede passa pelo servidor local do simulador, com o User-Agent da Roku e sem
  CORS. Playlists HLS são reescritas para os segmentos também passarem por ali.
- **Controle Roku na tela**: Voltar, Home, setas (segurar repete), OK, ↺, ✱, ⏪ ⏯ ⏩ e ⌨ para digitar no teclado do canal
  (como o app Roku do celular). Controle físico e teclado também funcionam.
- **Deep link** na abertura (`contentId`/`mediaType`) e com o canal aberto (roInput).
- **Registro** (login, listas, licença) guardado entre aberturas; dá para zerar ou gerar outro ID (outro código ROKU-…).
- **Log ao vivo e compartilhável**: `print` do BrightScript, erros, beacons, teclas e rede (senhas mascaradas).

## Como roda
O motor precisa de `SharedArrayBuffer`, que a WebView do Android não libera. Por isso o padrão é abrir no **Chrome**
(`http://127.0.0.1:6502/`), com o servidor local preso numa notificação ("Parar" encerra). A opção "WebView do app"
tenta primeiro dentro do app e cai para o Chrome se não der.

## Limites
- É um interpretador, não a Roku: confira o resultado final no aparelho antes de enviar à loja.
- Vídeo: HLS e MP4 tocam (hls.js no navegador). MPEG-TS direto (`.ts`) não toca no navegador.
- Sem Roku Pay real (ChannelStore simulado pelo motor).

## Build
Sem Gradle: `aapt2` + `javac` + `d8` + `apksigner` (`build.sh`). O workflow `build-apk.yml` compila o brs-engine
(tag fixa em `BRS_ENGINE_TAG`, com cache), coloca em `assets/web/lib`, gera o APK a cada push na branch `roku-sim`
e publica em `roku-sim-apk` (e como artifact). A chave em `keys/` é só deste simulador de testes (não usar em apps de loja).
