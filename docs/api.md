# API GLPI v2 (High-Level) — endpoints usados

Mapeamento do que o app consome da **API REST v2** do GLPI. Base configurável
pelo usuário (ex.: `http://137.131.162.82:8080`). O app monta as URLs a partir
dela.

## Autenticação — OAuth2

`POST {base}/api.php/token` (corpo `application/x-www-form-urlencoded`).

**Login (password grant):**

```
grant_type=password
client_id=<id>
client_secret=<secret>
username=<usuário GLPI>
password=<senha>
scope=<opcional>
```

**Renovação (refresh):**

```
grant_type=refresh_token
client_id=<id>
client_secret=<secret>
refresh_token=<token>
```

**Resposta:**

```json
{ "token_type": "Bearer", "expires_in": 3600,
  "access_token": "…", "refresh_token": "…" }
```

As demais chamadas enviam `Authorization: Bearer <access_token>`.

> Implementado em `lib/src/services/auth_service.dart` e `glpi_api.dart`.

## Listagem de ativos

`GET {base}/api.php/v2/Assets/Computer`
`GET {base}/api.php/v2/Assets/Phone`

**Query params:**

| Param | Uso |
|---|---|
| `start` | offset da página (0, 30, 60…) |
| `limit` | tamanho da página (padrão 30) |
| `filter` | filtro **RSQL** (busca) |
| `sort` | ordenação (campo) |

**Busca** (RSQL, OR = `,`):

```
filter=name=="*texto*",serial=="*texto*",otherserial=="*texto*"
```

**Resposta** — o app aceita as duas formas que a API pode devolver:

```json
{ "results": [ { … } ], "start": 0, "limit": 30, "total": 123 }
```

…ou um array puro `[ { … } ]` com o total no header `Content-Range: …/123`.

## Detalhe de um ativo

`GET {base}/api.php/v2/Assets/Computer/{id}`
`GET {base}/api.php/v2/Assets/Phone/{id}`

Retorna o objeto do ativo. Os "dropdowns" (fabricante, modelo, localização,
estado, usuário…) podem vir como **objeto aninhado** (`{ "id": 1, "name": "Dell" }`)
ou como id; o parser (`lib/src/models/_helpers.dart`) absorve ambos.

> Implementado em `lib/src/services/asset_service.dart`.

## Observações

- A versão `v2` aponta para a última `minor/patch` do servidor (o servidor desta
  atividade roda `v2.3.0`). Para fixar, troque `apiVersion` em
  `lib/src/core/constants.dart`.
- A documentação OpenAPI viva do servidor fica em `{base}/api.php/doc`.
