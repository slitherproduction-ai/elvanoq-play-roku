# ELVANOQ Play - Roku

Aplicativo Roku do ELVANOQ Play, criado em BrightScript e SceneGraph.

## Versão

0.1.1

## Fluxo de ativação

1. Na abertura, o app obtém exclusivamente roDeviceInfo.GetChannelClientId().
2. O identificador técnico é transformado somente para apresentação em um código visual no padrão ROKU-XXXXXXXX-XXXXXXXX.
3. Na primeira abertura, o app cria uma chave aleatória persistente no registro local do Roku. Ela não é mostrada ao cliente.
4. O app chama roku-device-register, seguido de roku-license-status, enviando a chave somente por HTTPS ao Portal.
5. Enquanto estiver pendente, o status é consultado a cada 60 segundos, sem bloquear a tela.
6. O cliente abre elvanoqplay.app e vincula a TV com o Código Roku mostrado.
7. Quando a licença fica ativa, o app prepara a transição para a Home.
8. Após a ativação, o app solicita roku-playlist-sync para receber a configuração da lista. As credenciais retornadas não são mostradas nem registradas em logs.

O identificador técnico nunca é exibido completo, registrado em logs ou tratado como endereço físico.

## Estados tratados

Ativo, pendente, expirado, bloqueado, offline e erro de API.

## Testes locais

1. Instale o canal pelo fluxo manual de sideload do Roku Developer Mode.
2. Abra o app e confira o código no formato ROKU-XXXXXXXX-XXXXXXXX.
3. Confirme o registro/atualização no Portal.
4. Vincule o código e aguarde a próxima consulta de licença.
5. Valide os cenários pendente, ativo, expirado, bloqueado, sem rede e resposta inválida.

Este repositório não inclui pacote de sideload e não publica na Roku Channel Store.
