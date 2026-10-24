# Contrato proposto — Portal Roku

Endpoint: `https://xrrgjssvdqvtrqhxpask.supabase.co/functions/v1/portal-control`

## Registro

```json
{
  "action": "roku-device-register",
  "rokuClientId": "<GetChannelClientId>",
  "deviceCode": "ROKU-XXXXXXXX-XXXXXXXX",
  "deviceName": "Roku Streaming Player",
  "platform": "roku"
}
```

## Consulta de ativação

```json
{
  "action": "roku-license-status",
  "rokuClientId": "<GetChannelClientId>",
  "deviceCode": "ROKU-XXXXXXXX-XXXXXXXX"
}
```

## Regras

- O identificador é persistente e específico do canal ELVANOQ Play.
- Não é um MAC e não deve ser convertido ou registrado como MAC.
- A chave de dispositivo continuará sendo exigida pelo Portal para adicionar ou alterar listas.
