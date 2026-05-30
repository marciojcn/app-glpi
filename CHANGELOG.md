# Changelog

Todas as mudanças relevantes deste projeto. Segue [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/)
e [SemVer](https://semver.org/lang/pt-BR/).

## [1.0.0] - 2026-05-29

### Adicionado
- Projeto Flutter (Android) inicial no padrão JCN para a **API REST v2** do GLPI.
- Autenticação **OAuth2** (grant `password`) com renovação por `refresh_token`
  e configuração do client OAuth (URL, Client ID/Secret, scope) em armazenamento
  seguro.
- **Inventário de Computadores** e **Celulares**: listagem paginada com scroll
  infinito, busca (RSQL por nome/serial/patrimônio) e tela de detalhe.
- **Impressão de etiqueta com QR code** via Bluetooth (TSPL), layout configurável
  (dimensões, campos, cópias) e fallback PDF/compartilhar.
- Design system `Glpi*` com a **identidade visual da Unifeob**: tema (azul
  elétrico `#0018FE`, indigo `#241C84`, amarelo `#FFE000`, magenta `#FF1F5A`),
  logo vetorial (`flutter_svg`), ícone do launcher e logo da etiqueta.
- Testes unitários de normalização de URL e formatação de AnyDesk.
