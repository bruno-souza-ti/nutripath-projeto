<div align="center">

<img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" />
<img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" />
<img src="https://img.shields.io/badge/SQLite-07405E?style=for-the-badge&logo=sqlite&logoColor=white" />
<img src="https://img.shields.io/badge/iOS-000000?style=for-the-badge&logo=apple&logoColor=white" />

# 🌿 NutriPath AI

**Consultoria nutricional e coleta biométrica via chat com Inteligência Artificial**

</div>

---

## 📱 Sobre o Projeto

O **NutriPath AI** é um aplicativo mobile desenvolvido em Flutter para iOS que oferece consultoria nutricional personalizada por meio de um chat com Inteligência Artificial. O app coleta dados biométricos do usuário, armazena informações localmente via SQLite e fornece recomendações nutricionais com base no perfil individual de cada pessoa.

### ✨ Funcionalidades

- 🔐 **Autenticação JWT** — Login seguro com tokens JWT
- 💬 **Chat com IA** — Entrevista nutricional conduzida por IA via endpoint fornecido
- 📊 **Dashboard** — Visualização de métricas e progresso do usuário

---

## 👥 Integrantes

| Nome | RA |
|------|----|
| Arthur Saraiva de Souza | 2404043 |
| Augusto dos Santos Barbosa | 2403301 |
| Bruno Lombardo Souza | 2407753 |
| Lucas Campos Citolino | 2400533 |
| Lucas Gobbo Cruz | 2406898 |

---

## 🗺️ Roadmap

| Semana | Conteúdo Técnico | Atividade do Grupo | Status |
|--------|-----------------|-------------------|--------|
| 04/04 | Navegação | Criar as rotas entre Login, Entrevista (Chat) e Dashboard | ✅ |
| 11/04 | Navegação | Criar as rotas entre Login, Entrevista (Chat) e Dashboard | ✅ |
| 18/04 | SQLite | Criar as tabelas `User`, `Measurements` e `InterviewLogs` | ⬜ |
| 25/04 | API & JWT | **Consumo de API e Autenticação JWT + Checkpoint 1** | ⬜ |
| 02/05 | Integração IA | Integrar o endpoint fornecido pelo professor para processar a entrevista | ⬜ |
| 09/05 | Sync & Background | Implementar a lógica de "Forçar Sincronismo" dos dados da entrevista | ⬜ |
| 16/05 | Arquivos Locais | Armazenar logs de exportação da dieta em formato local (ex: JSON/PDF) | ⬜ |
| 23/05 | Hardware & Fotos | **Hardware: Câmera e Galeria no iOS + Checkpoint 2** | ⬜ |
| 23/05 | P2/Entrega | Polimento final e documentação conforme exigido pelo cliente | ⬜ |
| Sábado antes da P2 | — | **Entrega Final** | ⬜ |

---

## 🗂️ Estrutura do Projeto

```
nutripath_ai/
├── lib/
│   ├── main.dart               # Entrada do app, tema e rotas
│   └── screens/
│       ├── login_screen.dart   # Tela de login com validação
│       ├── dashboard_screen.dart # Dashboard com métricas
│       └── chat_screen.dart    # Chat com IA
├── pubspec.yaml
└── README.md
```

---

## 🚀 Como Executar

### Pré-requisitos

- [Flutter SDK](https://flutter.dev/docs/get-started/install) `>=3.0.0`

### Instalação

```bash
# 1. Clone o repositório
git clone https://github.com/seu-usuario/nutripath-ai.git

# 2. Entre na pasta
cd nutripath-ai

# 3. Instale as dependências
flutter pub get

# 4. Execute no simulador iOS
flutter run
```

---

<div align="center">
  <sub> Desenvolvido pelo Grupo NutriPath</sub>
</div>
