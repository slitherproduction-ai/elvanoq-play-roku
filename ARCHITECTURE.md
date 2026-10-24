# Arquitetura Roku do ELVANOQ Play

O aplicativo Roku replica os domínios funcionais do ELVANOQ Play Android usando componentes nativos BrightScript e SceneGraph.

## Camadas

- source: inicialização do canal e ciclo de vida da tela.
- components: cenas e componentes visuais SceneGraph.
- services: acesso HTTP ao Portal, sincronização de listas e consultas de catálogo.
- models: modelos normalizados de licença, listas, canais, filmes, séries e EPG.
- features: Home, TV ao Vivo, Filmes, Séries, Busca, Favoritos, Controle Parental e Player.
- images: wordmark e ícone oficiais do ELVANOQ.

## Fluxo inicial

1. MainScene obtém o identificador persistente fornecido pelo Roku.
2. PortalService registra o aparelho e consulta a licença.
3. A licença pendente exibe a ativação em elvanoqplay.app.
4. A licença ativa abre o AppShell, raiz das áreas Home, TV ao Vivo, Filmes, Séries, Busca, Minha Lista e Ajustes.

## Equivalência de produto

A implementação não reutiliza código React Native. Ela preserva a organização por domínio e os fluxos de produto, adaptados aos componentes e ao controle remoto do Roku. O AppShell já mantém menu lateral, foco por D-pad e as áreas do produto separadas; os conteúdos dinâmicos entram pela sincronização de listas.

## Empacotamento

O workflow Roku channel validation valida cada alteração. O ZIP para Roku Developer Mode só é criado manualmente, marcando create_sideload_package ao executar o workflow; nenhuma alteração de código gera pacote automaticamente.
