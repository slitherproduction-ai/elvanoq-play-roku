# ELVANOQ Play - Roku

Aplicativo Roku do ELVANOQ Play, criado em BrightScript e SceneGraph.

## Versão

0.1.88

## Ativação e entrada por código

1. Na abertura, o app obtém exclusivamente `roDeviceInfo.GetChannelClientId()`.
2. O identificador é mostrado somente como código visual no padrão `ROKU-XXXXXXXX-XXXXXXXX`.
3. O app registra e consulta o estado pelo Portal via HTTPS no domínio próprio `roku.elvanoqplay.app`: `roku-device-register` e `roku-license-status`.
4. Enquanto a ativação estiver pendente, o usuário pode vincular a TV em `elvanoqplay.app`; a consulta é refeita a cada 60 segundos sem bloquear a tela.
5. A mesma tela também oferece **Entrar com código do servidor**. O Roku envia o código e seus identificadores de ativação ao Portal usando a ação `roku-server-code-resolve`.
6. O cliente HTTP Roku envia um `User-Agent` identificável para compatibilidade com a camada de proteção do domínio.
7. O host retornado pelo Portal é validado antes de o Roku solicitar usuário e senha. Esses dados servem somente para montar a sessão em memória e não são gravados no registro local, exibidos ou registrados em logs.
8. Quando a licença estiver ativa, o app sincroniza a configuração autorizada e abre a Home.

O fluxo não usa, solicita, transmite nem registra identificador físico do aparelho. O identificador técnico completo também não é exibido ou colocado em logs.

## Estados tratados

Ativo, pendente, expirado, bloqueado, offline e erro de API.

## Simulador de homologação

O repositório executa `tests/roku_preflight_simulator.py` em todo push e pull request. É um simulador de contrato e não usa dispositivos, listas, credenciais ou códigos reais.

Ele valida:

- compilação BrightScript e XML SceneGraph;
- formato do código visual e rejeição de identificador sintético inválido;
- presença dos estados pendente, ativo, expirado, bloqueado, offline e erro;
- abertura do login por código pelo evento **OK** do controle;
- identificador persistente `GetChannelClientId()`, sem MAC;
- contrato das ações do Portal e proteção HTTP (timeout e `User-Agent`);
- resposta pública do relay `/health`.

O relatório `roku-homologation-report.json` fica disponível como artefato do GitHub Actions. O pacote de sideload só é criado quando essa suíte e as validações do canal forem aprovadas.

O simulador não substitui o teste físico de reprodução, codecs, desempenho e navegação real pelo controle Roku.

## Resolução e layout

O canal usa uma única base de projeto **FHD (1920×1080)**. O Roku faz a escala automática para aparelhos HD/720p, mantendo proporções e áreas seguras; não há layouts distintos e conflitantes para HD e FHD.

## Testes locais

1. Execute `python3 tests/roku_preflight_simulator.py` para a homologação de contrato.
2. Instale o pacote pelo Roku Developer Mode.
3. Abra o app e confirme o código visual no formato esperado.
4. Teste vinculação no Portal, pendente, ativo, expirado, bloqueado, sem rede e resposta inválida.
5. Pressione OK na tela inicial e teste código inválido, código rejeitado e código válido.
6. Em código válido, informe credenciais de teste e confirme que o catálogo é carregado sem mostrar ou salvar a senha.
7. Confirme no console de depuração que nenhuma mensagem contém o identificador técnico completo ou credenciais.

Este repositório não publica na Roku Channel Store.
