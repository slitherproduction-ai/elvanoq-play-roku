# ELVANOQ Play - Roku

Aplicativo Roku do ELVANOQ Play, criado em BrightScript e SceneGraph.

## Versão

0.1.3

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

Favoritos, assistir mais tarde, continuar assistindo, histórico e preferências parentais têm uma base local por dispositivo. As coleções usam identificador de item para evitar duplicações e não armazenam credenciais, URLs ou identificadores técnicos.

Bloqueios parentais são separados por lista ativa e verificados antes de iniciar preview ou reprodução. Uma sessão validada por PIN libera apenas o uso atual do aplicativo.

O PlayerView também aplica essa verificação centralmente: acessos futuros por Home, busca, favoritos, histórico, deep link ou troca rápida não podem iniciar conteúdo protegido sem PIN válido.

## Player Roku

Filmes e séries da lista abrem uma tela de detalhes com as ações Assistir, Minha Lista e Assistir mais tarde. As duas últimas são persistidas localmente, sem URL nem credenciais. A ação Assistir aplica a política parental e encaminha apenas a URL de stream disponível em memória ao PlayerView.

Quando a licença está ativa, a tela consulta `roku-metadata` no Portal para enriquecer título, sinopse, pôster e avaliação. O Portal valida o aparelho e usa o segredo TMDB exclusivamente no servidor; o canal nunca recebe, armazena ou registra esse token.

O componente PlayerView usa o player nativo Roku e oferece saída pelo botão Voltar e OSD reaberto por OK. Informações enriquecidas (sinopse, elenco, trailer e recomendações) permanecem condicionadas à integração TMDB; o app não inventa metadados quando ela não está configurada. A reprodução real será validada com uma lista autorizada em aparelho físico.

O identificador técnico nunca é exibido completo, registrado em logs ou tratado como endereço físico.

## Estados tratados

Ativo, pendente, expirado, bloqueado, offline e erro de API.

## Testes locais

1. Instale o canal pelo fluxo manual de sideload do Roku Developer Mode.
2. Abra o app e confira o código no formato ROKU-XXXXXXXX-XXXXXXXX.
3. Confirme o registro/atualização no Portal.
4. Vincule o código e aguarde a próxima consulta de licença.
5. Valide os cenários pendente, ativo, expirado, bloqueado, sem rede e resposta inválida.
6. Com uma lista autorizada que contenha categorias de filmes ou séries, abra um item, inclua-o em Minha Lista e em Assistir mais tarde e confirme a persistência após reiniciar o canal.
7. Só em Roku físico, valide abertura do PlayerView, retorno pelo botão Voltar e conteúdo protegido com uma categoria bloqueada.

Este repositório não inclui pacote de sideload e não publica na Roku Channel Store.
