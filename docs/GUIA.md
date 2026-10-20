# 📖 Guia do Projeto — como funciona e como rodar

Guia de leitura do código e de execução do app. Se você vai apresentar
o projeto na arguição, este é o roteiro: leia na ordem e você consegue
explicar qualquer tela.

---

## PARTE 1 — Como o projeto funciona

### 1.1 A ideia em uma frase

> O app **não fala com o banco de dados**. Ele fala HTTP com a API em Go
> (`api.exe`), que é a única a tocar o SQLite. O app guarda **uma única
> coisa** no celular: o token JWT, criptografado.

```
┌─────────────────┐   HTTPS/HTTP + Bearer token   ┌──────────────┐   SQLite    ┌────────┐
│  App Flutter    │ ─────────────────────────────► │  api.exe     │ ──────────► │ data.db│
│  (celular)      │ ◄───────────────────────────── │  (Go, :8081) │ ◄────────── │ (arquivo)│
└─────────────────┘        JSON                    └──────────────┘              └────────┘
```

### 1.2 As quatro camadas (MVC)

| Camada | Pasta | Pode | Não pode |
|--------|-------|------|----------|
| **Model** | `lib/models/` | Guardar dados, `fromJson`/`toJson`, getters de regra | Falar HTTP, importar `material.dart` |
| **Service** | `lib/core/servicos/` | Falar HTTP, devolver Models | Importar Flutter, tomar decisão de UI |
| **Controller** | `lib/controllers/` | Validar, orquestrar o Service, expor estado reativo, navegar | Desenhar widget, conhecer o Dio |
| **View** | `lib/views/` | Desenhar, repassar toques, observar estado com `Obx` | Chamar a API, conter regra de negócio |

**Teste rápido de understanding:** se a linha tem `Get.` e `http`, ela é
Service. Se tem `Rx` e `TextEditingController`, é Controller. Se tem
`Scaffold`, é View.

### 1.3 O caminho de uma requisição (ex.: listar patrimônios)

```
toque na View
    │
    ▼
PatrimonioController.carregar()          ← decide o quê pedir, guarda o estado
    │  (não conhece HTTP)
    ▼
PatrimonioService.listar(busca: ..., status: ...)
    │  monta a rota e o corpo; devolve Model
    ▼
ApiClient.get('/patrimonios', query: {...})
    │  interceptor 1: injeta "Authorization: Bearer <token>"
    │  interceptor 2: em 401, renova o token e repete a requisição
    ▼
api.exe → SQLite → JSON
    │
    ▼
ApiClient devolve Map<String, dynamic>
    │  (falha vira AppException com texto amigável)
    ▼
PatrimonioService converte JSON → List<PatrimonioModel>
    ▼
Controller guarda em RxList e a View redesenha via Obx
```

**O ponto central:** o Controller **nunca** vê um `DioException`. Tudo
que pode dar errado vira `AppException` com uma frase que o usuário
entende — e essa conversão acontece em **um único lugar**:
`lib/core/utils/api_erros.dart`.

### 1.4 Estado reativo (GetX)

```dart
// Controller: o estado é observável
final RxList<PatrimonioModel> patrimonios = <PatrimonioModel>[].obs;
final RxBool carregando = false.obs;

// View: a tela redesenha sozinha quando o estado muda
Obx(() => controller.carregando.value
    ? const ListaSkeletonPatrimonio()
    : ListView.separated(itemCount: controller.patrimonios.length, ...))
```

Três peças do GetX que você precisa saber explicar:

| Conceito | Onde está | Para que serve |
|----------|-----------|----------------|
| `Rx` / `.obs` | Controllers | Estado observável |
| `Obx` | Views | Redesenha quando o estado muda |
| `Bindings` | `app/bindings.dart` | Injeta dependências (Services e Controllers) por rota |

### 1.5 Navegação nomeada e guardas de rota

Rotas **nunca** são strings soltas. Cada nome vive em `app/rotas.dart`:

```dart
Get.toNamed(Rotas.patrimonios);              // navega
Get.toNamed(Rotas.patrimonioDetalhe, arguments: {'id': 12});  // navega com dados
```

E cada rota declara **quem** pode entrar:

| Guarda | Regra | Onde age |
|--------|-------|----------|
| `AutenticadoMiddleware` | exige sessão válida | telas internas |
| `AnonimoMiddleware` | quem já está logado não volta ao Login | Login, Cadastro, Recuperação |
| `AdminMiddleware` | só `role == "admin"` | `/admin/...` |

> **Ponto de arguição:** essas guardas são **defesa de interface**. A
> segurança real é do backend — um professor que forçar a tela recebe
> `403 Forbidden` da API. São duas camadas independentes.

### 1.6 Onde cada coisa mora (mapa rápido)

| Quero… | Vá em… |
|--------|--------|
| Adicionar um campo que a API devolve | `lib/models/` + o `fromJson` do Model |
| Falar com um endpoint novo | `lib/core/servicos/` |
| Criar uma tela | `lib/views/<módulo>/` + uma `GetPage` em `app/rotas.dart` |
| Criar uma regra de tela | `lib/controllers/` (estado + validação) |
| Criar um componente reutilizável | `lib/widgets/` |
| Mudar cor, fonte ou raio | `lib/app/tema.dart` (e só lá) |
| Adicionar um atalho no menu | `admin_home_view.dart` / `professor_home_view.dart` |
| Entender a sessão e o token | `core/servicos/sessao_service.dart` + `api_client.dart` |

### 1.7 Onde está cada requisito

| RF | Controller | View | Service |
|----|-----------|------|---------|
| RF01–RF04 | `auth_controller.dart` | `views/auth/` | `auth_service.dart` |
| RF05 | `dashboard_controller.dart` | `views/admin/dashboard_view.dart` | `patrimonio_service.dart` |
| RF06 | `professor_*_controller.dart` | `views/admin/professores/` | `professor_service.dart` |
| RF07a | `patrimonio_controller.dart` · `patrimonio_detalhe_controller.dart` · `patrimonio_form_controller.dart` | `views/patrimonio/` | `patrimonio_service.dart` |
| RF07b | `patrimonio_ciclo_vida_controller.dart` · `patrimonio_historico_controller.dart` | `views/patrimonio/` | `patrimonio_service.dart` |
| RF08 | `meus_patrimonios_controller.dart` | `views/professor/meus_patrimonios_view.dart` | `patrimonio_service.dart` |
| RF09 | `perfil_controller.dart` | `views/perfil/perfil_view.dart` | `perfil_service.dart` |

### 1.8 As regras de negócio no código

| RN | Onde está garantida |
|----|--------------------|
| RN01 — só admin se cadastra | `CadastroAdminRequestModel` **não tem** campo `role` |
| RN02 — professor é cadastrado pelo admin | rota `/admin/professores` + `AdminMiddleware` |
| RN03 — docente é só leitura | `podeEditar` / `podeCadastrar` verificam `isAdmin`; a tela do docente não tem botão de escrita |
| RN04 — docente pode ter vários bens | `PatrimonioModel.professorId` + `/admin/professores/{id}` |
| RN05 — atribuição e devolução | `PatrimonioService.atribuir()` / `.desatribuir()` |
| RN06 — o docente edita o próprio perfil | `PUT /profile` com `newPassword` |
| RN07 — isolamento por escola | garantido pelo backend (`adminId`); o app só pede o próprio contexto |

### 1.9 Os testes

| Tipo | Onde | Como roda |
|------|------|-----------|
| Model (JSON ↔ objeto) | `test/patrimonio_test.dart` | `flutter test test/patrimonio_test.dart` |
| Service (rota + corpo) | mesmo arquivo | idem |
| Controller (regras) | `test/patrimonio_controller_test.dart` | idem |
| Widget (tela) | `test/patrimonio_lista_view_test.dart` | idem |
| Integração (API real) | `test/integracao_*.dart` | precisa do `api.exe` no ar |

O dublê de rede está em `test/helpers/api_client_falso.dart`: ele
devolve payloads no **mesmo formato do Swagger**, então o teste
verifica a camada que o app controla.

> **Por que existe um dublê do armazenamento seguro?** Dentro de
> `testWidgets` o tempo é *fake*: chamadas reais de plataforma
> (`flutter_secure_storage`) nunca completam e travam o teste. Por isso
> `test/helpers/test_armazenamento.dart` substitui o plugin.

---

## PARTE 2 — Como rodar

### 2.1 Pré-requisitos

| Item | Versão | Observação |
|------|--------|------------|
| Flutter | 3.38.7 (stable) | `flutter --version` |
| Dart | 3.10.7 | vem com o Flutter |
| Windows | qualquer | o `api.exe` é Windows |
| Git | qualquer | — |

**Nada além disso.** Sem banco de dados para instalar, sem Docker, sem
conta em nuvem, sem chave de API.

### 2.2 Rodar o backend

```bash
cd <pasta do projeto>
./api.exe
```

Sobe na porta **8081** e abre o Swagger em
<http://localhost:8081/swagger/>.

**O banco é criado sozinho.** O `api.exe` usa SQLite em arquivo
(`data.db`): na primeira execução ele cria o arquivo, cria as tabelas
e popula o usuário administrador. Se você apagar o `data.db`, ele é
recriado do zero na próxima execução. Não há script de migração nem
`seed` para rodar.

Usuário administrador semeado:

| E-mail | Senha | Papel |
|--------|-------|-------|
| `admin@admin.com` | `admin123` | `admin` |

#### CPF e telefone: dados livres

**CPF e telefone são apenas dados de identificação — não precisam
existir de verdade.** O app aceita qualquer valor:

| Campo | O que o app aceita | Por quê |
|-------|--------------------|---------|
| **CPF** | Qualquer sequência de **11 dígitos** (a máscara `000.000.000-00` é aplicada). O **dígito verificador não é conferido**. | O backend também não confere (ele grava `123.456.789-45` sem reclamar). A escola precisa cadastrar professor convidado, servidor terceirizado e docente de outra instituição — todos sem CPF próprio. |
| **Telefone** | De **8 a 15 dígitos** (fixo, celular ou E.164 internacional). | O app não consulta nenhuma base para saber se o número existe. |

Consequência prática: **para testar, digite qualquer coisa**. Um CPF
inventado não impede o cadastro — o que protege o patrimônio é o
token de sessão, não o número do documento.

> A regra está em `lib/core/utils/validadores.dart` (`cpf()` e
> `telefone()`), e o mesmo vale para os formulários de Coordenador,
> Professor e Perfil — eles usam o mesmo validador.

### 2.3 Rodar o app

```bash
flutter pub get
flutter run
```

| Onde | URL da API (automático) |
|------|-------------------------|
| Emulador Android | `http://10.0.2.2:8081/api` |
| Simulador iOS | `http://localhost:8081/api` |
| Desktop (Windows/macOS/Linux) | `http://localhost:8081/api` |
| Celular físico (Wi-Fi) | `http://192.168.x.x:8081/api` → usar `--dart-define` |

```bash
# celular físico na mesma rede
flutter run --dart-define=API_BASE_URL=http://192.168.0.10:8081/api
```

> O `api_config.dart` escolhe o endereço sozinho conforme a
> plataforma. O `--dart-define` só é necessário para apontar para
> outro host.

### 2.4 Ver o app como um celular (sem emulador)

```bash
flutter run -d chrome -t dev/main_dev.dart
```

O `dev/main_dev.dart` (fora de `lib/` de propósito — `device_preview`
é `dev_dependency`) envolve o app no **DevicePreview**: você troca o
aparelho na barra lateral, gira a tela, liga o teclado virtual e
ajusta o tamanho da fonte. É a forma mais rápida de checar o
comportamento responsivo (RNF01).

### 2.5 Rodar os testes

```bash
flutter analyze          # análise estática (0 problemas esperado)
flutter test             # suíte completa (247 testes)
flutter test --concurrency=1   # recomendado: ver 2.8
```

Para rodar um arquivo só:

```bash
flutter test test/patrimonio_test.dart
flutter test --plain-name "Cadastro → detalhe → edição → exclusão"
```

### 2.6 Gerar os prints

```bash
flutter test tool/gerar_prints_test.dart
```

Monta as 17 telas com as widgets reais e grava os PNGs em
`docs/prints/`. Use depois de mexer numa tela para atualizar a imagem
do README.

### 2.7 Ver o protótipo

```bash
cd design
python -m http.server 8080
# abra http://localhost:8080/prototipo.html
```

Para levar ao Figma: plugin gratuito **HTML to Design** apontando para
esse endereço.

### 2.8 ⚠️ Se o `flutter test` falhar com "objective_c"

```
Building native assets for package:objective_c failed
```

A causa: o hook de native assets do pacote `objective_c` (dependência
transitiva do `flutter_secure_storage` para macOS) é invocado com o
caminho **sem aspas**, e o caminho do projeto ou do perfil do Windows
tem **espaço**.

Duas saídas:

```bash
# 1. PUB_CACHE sem espaços
set PUB_CACHE=C:\pubcache
flutter pub get
flutter test

# 2. (recomendado) clonar em um caminho sem espaços
#    git clone <url> C:\dev\reserva-mobile
```

### 2.9 Por que os testes de integração falham em paralelo

Dois arquivos de teste batem na API real ao mesmo tempo e o backend em
Go tem uma corrida na tabela de refresh token
(`Erro ao salvar sessão de refresh token`). O `dart_test.yaml` já
define `concurrency: 1` para evitar isso — **não apague esse arquivo**.

---

## PARTE 3 — Rotina de trabalho no projeto

### 3.1 Antes de começar

```bash
git checkout main
git pull origin main
git checkout -b feature/minha-tarefa
```

### 3.2 Durante

- Escreva o **Model** antes do Service (o Service devolve Model).
- Escreva o **Service** antes do Controller (o Controller orquestra).
- Escreva o **Controller** antes da View (a View desenha o que ele
  expõe).
- Regra de negócio **nunca** na View.
- Texto de interface **nunca** no Controller.
- `TextEditingController` e `GlobalKey<FormState>` **sempre** na View.
- Valide **no Controller** e também no `Form` — a tela não deve ser o
  único guardião da regra.

### 3.3 Antes de abrir o PR

```bash
flutter analyze
flutter test
flutter test tool/gerar_prints_test.dart   # se mexeu em tela
```

### 3.4 Abrir o PR

```bash
git add -A
git commit -m "feat(modulo): o que foi feito"
git push -u origin feature/minha-tarefa
```

No GitHub: **Compare & pull request** → `main`. No corpo, descreva o
que foi feito e cole a saída de `flutter test`.

---

## PARTE 4 — Mapa da API (o que o app consome)

| Endpoint | Quem usa | Para quê |
|----------|----------|-----------|
| `POST /auth/register` | `auth_service` | RF02 — cria só Coordenador |
| `POST /auth/login` | `auth_service` | RF01 |
| `POST /auth/refresh` | `api_client` | renova o token em 401 |
| `POST /auth/logout` | `auth_service` | RF04 |
| `POST /auth/forgot-password` | `auth_service` | RF03 — etapa 1 |
| `POST /auth/verify-code` | `auth_service` | RF03 — etapa 2 |
| `POST /auth/reset-password` | `auth_service` | RF03 — etapa 3 |
| `GET /patrimonios` | `patrimonio_service` | RF07a — listagem com filtros |
| `GET /patrimonios/meus` | `patrimonio_service` | RF08 — bens do docente |
| `GET /patrimonios/{id}` | `patrimonio_service` | RF07a — detalhe |
| `POST /patrimonios` | `patrimonio_service` | RF07a — cadastro |
| `PUT /patrimonios/{id}` | `patrimonio_service` | RF07a — edição |
| `DELETE /patrimonios/{id}` | `patrimonio_service` | RF07a — exclusão |
| `POST /admin/patrimonios/{id}/atribuir` | `patrimonio_service` | RF07b — entrega |
| `POST /admin/patrimonios/{id}/desatribuir` | `patrimonio_service` | RF07b — devolução |
| `GET /admin/patrimonios/{id}/historico` | `patrimonio_service` | RF07b — linha do tempo |
| `GET /admin/patrimonios/stats` | `patrimonio_service` | RF05 — indicadores |
| `GET /admin/professores` | `professor_service` | RF06 — listagem |
| `POST /admin/professores` | `professor_service` | RF06 — cadastro |
| `GET /admin/professores/{id}` | `professor_service` | RF06 — detalhe |
| `GET /profile` · `PUT /profile` | `perfil_service` | RF09 |

**Endpoints da API que o app ainda não usa** (disponíveis para a parte
do Moises — ver `docs/partes/parte-6-administracao-geral.md`):

- `GET /admin/users`
- `PATCH /admin/users/{id}/role`
- `GET /admin/stats`
