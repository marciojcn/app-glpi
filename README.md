# GLPI Inventário

App **Flutter (Android)** com a **identidade visual da Unifeob** para consulta do
inventário do GLPI pela **API REST v2 (High-Level, OAuth2)** e impressão de
**etiquetas com QR code** em impressora térmica **Bluetooth** (TSPL).

É a reescrita do cliente GLPI da casa para a **API nova** — o projeto anterior
usava a API legada (`apirest.php`, App-Token + Session-Token). Esta entrega cobre
**dois inventários**: **Computadores** e **Celulares**.

---

## Funcionalidades

- 🔐 **Login OAuth2** (grant `password`) contra o GLPI v2, com renovação por
  `refresh_token`.
- 💻📱 **Inventário de Computadores e Celulares**: lista paginada com scroll
  infinito, busca por nome/serial/patrimônio (filtro RSQL no servidor) e tela de
  detalhe completa.
- 🏷️ **Etiqueta com QR code via Bluetooth** (TSPL — XD210, Zebra GK, XPrinter…),
  com layout configurável (dimensões, campos, cópias). Fallback: gerar/compartilhar
  **PDF** no mesmo tamanho.

---

## Pré-requisitos

| Item | Versão |
|---|---|
| Flutter | 3.24+ |
| Dart SDK | 3.5+ |
| Android | 7.0 (API 24)+ |
| Servidor | GLPI 11+ com a High-Level API habilitada |

---

## Configurar o client OAuth no GLPI

A API v2 autentica via OAuth2, então é preciso um **client OAuth** no GLPI:

1. **Configurar → Geral → API**: habilite a API REST.
2. **Configurar → Clients OAuth → +**:
   - **Grant types**: `Password` (e `Refresh Token`).
   - **Scopes**: conforme a necessidade (pode deixar o padrão).
   - Salve e anote o **Client ID** e o **Client Secret**.
3. No app, tela de login → **Configuração do servidor**:
   - **URL**: `http://137.131.162.82:8080` (raiz do GLPI — o app monta
     `/api.php/token` e `/api.php/v2/...`)
   - **Client ID** / **Client Secret**
   - **Scope** (opcional)
   - Depois informe **usuário** e **senha** do GLPI e toque em **Entrar**.

> O usuário precisa ter direito de leitura em Computadores e Celulares no GLPI.

---

## Rodar

```bash
flutter pub get
flutter run                 # com um dispositivo Android conectado
# ou gere o APK:
flutter build apk --release
```

---

## Impressão de etiquetas (Bluetooth)

1. **Pareie** a impressora térmica pelo Bluetooth do Android (modo TSPL).
2. No detalhe de um ativo, toque em **Imprimir etiqueta**.
3. Selecione a impressora pareada e toque em **Imprimir (Bluetooth)**.
4. Ajuste o layout (dimensões, campos visíveis, nº de cópias) em **Configurações**.

A etiqueta traz a logo da **Unifeob**, um **QR code** (com o hostname/serial) e os
campos selecionados. Sem impressora à mão, use **PDF** ou **Compartilhar**.

---

## Arquitetura (Professor Nivaldo)

```
lib/
├── main.dart                 # bootstrap (orientação, SSL controlado)
├── app_glpi.dart             # MaterialApp + tema + transição padrão
└── src/
    ├── core/                 # constants, glpi_exception, secure_http
    ├── models/               # asset, asset_tipo, auth_config, auth_token, label_config
    ├── services/             # glpi_api, auth_service, asset_service, label_print_service
    ├── pages/                # login, home, inventory/{list,detail}, etiqueta, settings
    └── widgets/              # design system Glpi* + tema/identidade JCN
```

- **Identificadores em PT-BR**; camadas claras (UI nunca fala HTTP direto — sempre
  via `services/`).
- **Segredos** (`client_secret`, config) em `flutter_secure_storage`; **token só em
  memória** (login a cada abertura).
- Detalhes dos endpoints em [`docs/api.md`](docs/api.md).

---

## Segurança

- O servidor desta atividade roda em **HTTP**; o app libera _cleartext_ via
  `android/app/src/main/res/xml/network_security_config.xml`. **Em produção, use
  HTTPS** e remova/restrinja esse arquivo.
- SSL auto-assinado (HTTPS) só é aceito se o usuário ligar a opção no login — e
  apenas para o host configurado (bloqueia MITM em hosts arbitrários).

---

## Identidade visual (Unifeob)

Paleta aplicada no tema ([lib/src/widgets/glpi_theme.dart](lib/src/widgets/glpi_theme.dart)):

| Cor | Hex | Uso |
|---|---|---|
| Azul elétrico | `#0018FE` | Cor principal (botões, links) |
| Indigo | `#241C84` | AppBar / áreas escuras / fundo do ícone |
| Amarelo | `#FFE000` | Destaque |
| Magenta | `#FF1F5A` | Ação de destaque (FAB) |

A logo é renderizada do vetor [assets/images/unifeob.svg](assets/images/unifeob.svg)
(via `flutter_svg`); o ícone do launcher e a logo da etiqueta térmica são PNGs
gerados a partir dela.

---

Projeto customizado para a **Unifeob** · desenvolvido por Márcio Augusto Garcia Soares · RA: 24000138.
