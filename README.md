# 🏫 Patrimônio Escolar — App Mobile (Flutter)

Sistema Integrado de Gestão de Patrimônio Escolar. Aplicativo mobile
oficial para gestão e acompanhamento dos patrimônios de uma instituição
de ensino, operando sobre a API REST em Go fornecida pela equipe.

---

## 📌 Status do Projeto

| Parte | Módulo | Situação |
|-------|--------|----------|
| 1 | Base do projeto (estrutura, tema, rotas, DI) | ✅ Concluída |
| 2 | **Autenticação e Sessão (RF01–RF04)** | ✅ **Concluída** |
| 3 | Camada de dados + biblioteca de widgets | ⏳ Próxima |
| 4 | Painel do Coordenador (RF05–RF07) | ⏳ Planejada |
| 5 | Painel do Professor + Perfil (RF08–RF09) | ⏳ Planejada |

---

## 🧱 Arquitetura

Padrão **MVC** com gerenciamento de estado reativo via **GetX**.

```
lib/
├── main.dart                     Ponto de entrada e configuração do GetMaterialApp
│
├── app/                          Camada de configuração (não é View nem Model)
│   ├── bindings.dart             Injeção de dependências (Bindings do GetX)
│   ├── middleware.dart           Guardas de rota (RBAC) e regra de roteamento
│   ├── rotas.dart                Rotas nomeadas + transições
│   └── tema.dart                 Paleta de cores, tipografia e estilos globais
│
├── core/                         infraestrutura transversal
│   ├── config/api_config.dart    URL base da API (detecta plataforma)
│   ├── servicos/
│   │   ├── api_client.dart       Cliente HTTP (Dio) + interceptors
│   │   ├── auth_service.dart     Endpoints de autenticação
│   │   └── sessao_service.dart   Persistência segura do JWT (GetxService)
│   └── utils/
│       ├── api_erros.dart        Conversão de erro HTTP → AppException
│       ├── app_exception.dart    Exceção de negócio
│       └── validadores.dart      Validações e máscaras reutilizáveis
│
├── models/                       Modelos de dados (JSON ↔ objeto)
│   ├── usuario_model.dart
│   ├── auth_resposta.dart
│   ├── auth_requests.dart
│   ├── professor_request.dart
│   └── patrimonio_model.dart
│
├── controllers/                  Controller (regras de negócio da tela)
│   ├── splash_controller.dart
│   └── auth_controller.dart
│
├── views/                        Views (apenas desenham)
│   ├── splash/splash_view.dart
│   ├── auth/                     login · cadastro_admin · recuperar_senha
│   ├── admin/admin_home_view.dart
│   └── professor/professor_home_view.dart
│
└── widgets/                      Widgets reutilizáveis (RNF04)
    ├── botao_primario.dart
    ├── campo_texto.dart
    ├── cabecalho_usuario.dart
    ├── dialogo_logout.dart
    ├── estado_vazio.dart
    └── mensagem_erro.dart

dev/
└── main_dev.dart                 Entry point de DESENVOLVimento (device_preview)
                                 Fica fora de lib/ de propósito: a dependência
                                 é dev-only e não entra no build de produção.
```

### Onde cada responsabilidade mora

| Camada | Pode fazer | Não pode fazer |
|--------|-----------|----------------|
| **Model** | Guardar dados, `fromJson`/`toJson`, getters de regra (`isAdmin`) | Falar HTTP, conhecer Flutter |
| **Controller** | Validar, orquestrar Service, expor estado reativo, navegar | Desenhar widgets, conhecer Dio |
| **View** | Desenhar, repassar toques, observar estado com `Obx` | Chamar a API, conter regra de negócio |
| **Service** | Falar HTTP e devolver Models | Importar `material.dart` |

---

## 🔐 Parte 2 — Autenticação e Sessão (RF01–RF04)

| RF | Requisito | Onde está |
|----|-----------|-----------|
| RF01 | Login com e-mail/senha, token JWT seguro e roteamento por role | `views/auth/login_view.dart` · `controllers/auth_controller.dart` |
| RF02 | Cadastro de Coordenador | `views/auth/cadastro_admin_view.dart` |
| RF03 | Recuperação de senha em 3 etapas | `views/auth/recuperar_senha_view.dart` |
| RF04 | Logout seguro | `controllers/auth_controller.dart` · `widgets/dialogo_logout.dart` |

### Decisões técnicas

**1. Armazenamento seguro do token (RF01 / RNF03)**

O JWT **não** vai para `SharedPreferences`. É gravado em
`flutter_secure_storage`, que usa o `EncryptedSharedPreferences` no
Android, o Keychain no iOS/macOS e o DPAPI no Windows:

```dart
// core/servicos/sessao_service.dart
static const FlutterSecureStorage _storage = FlutterSecureStorage();
```

**2. Injeção automática do `Authorization` (RNF03)**

Um interceptor do Dio adiciona o cabeçalho em toda requisição, e outro
intercepta o `401` para renovar o token **uma única vez** e repetir a
requisição original — de forma transparente para quem chamou:

```dart
// core/servicos/api_client.dart
void _adicionarToken(RequestOptions options, RequestInterceptorHandler handler) {
  final token = _sessao.token.value;
  final ehPublica = options.extra['ignorarAuth'] == true;
  if (token.isNotEmpty && !ehPublica) {
    options.headers['Authorization'] = 'Bearer $token';
  }
  handler.next(options);
}
```

A trava `_renovando` evita que várias requisições expiradas ao mesmo
tempo gerem uma corrida de renovação. Quando o refresh token também
falha, a sessão é limpa e o app volta para o Login.

**3. Erros traduzidos em uma única fronteira**

Nenhum Controller conhece `DioException`. A função `chamar()` em
`core/utils/api_erros.dart` converte qualquer falha em `AppException`
com texto amigável, priorizando a mensagem que o próprio backend
enviou no formato `{"error": "..."}`:

```dart
Future<T> chamar<T>(Future<T> Function() acao) async {
  try {
    return await acao();
  } on AppException {
    rethrow;
  } on DioException catch (e) {
    throw AppException(mensagemDeErro(e), statusCode: e.response?.statusCode);
  } catch (e) {
    throw AppException('Ocorreu um erro inesperado. Tente novamente.');
  }
}
```

**4. Roteamento condicional por role (RBAC)**

A regra mora em um único lugar, `rotaPorSessao()`, usada tanto pela
Splash quanto pelo login e pelos middlewares:

```dart
String rotaPorSessao(SessaoService sessao) {
  final usuario = sessao.usuario.value;
  if (usuario != null && usuario.isAdmin) return Rotas.homeAdmin;
  return Rotas.homeProfessor;   // menor privilégio por padrão
}
```

Perfil desconhecido cai no painel do docente — a opção mais restrita.

**5. Defesas de interface (não substituem o backend)**

`AutenticadoMiddleware` e `AnonimoMiddleware` bloqueiam navegações
indevidas pela interface. A segurança real continua no servidor: um
professor que tentar escrever recebe **403 Forbidden** da API. Isso é
coberto por um teste de integração.

**6. FormKeys pertencem às Views**

Uma `GlobalKey<FormState>` guardada no Controller seria reutilizada por
duas instâncias da mesma tela durante uma transição de rota, e o
Flutter lançaria `Duplicate GlobalKey`. Por isso cada View cria a sua
própria key e passa o `FormState` ao Controller, que aplica as regras
de validação.

**7. Registro síncrono das dependências globais**

`Get.putAsync` só registra a instância **depois** que o Future resolve.
Usá-lo para a sessão e logo em seguida fazer `Get.find<SessaoService>()`
faz o `ApiClient` nunca ser registrado — e o login, que depende dele,
quebra em toda execução. O `MainBinding` por isso registra de forma
síncrona, e a leitura do armazenamento (assíncrona) fica a cargo do
`SplashController`, que é justamente a tela que decide o destino com
base na sessão salva:

```dart
// app/bindings.dart
final sessao = Get.put(SessaoService(), permanent: true);
Get.put(ApiClient(sessao), permanent: true);
```

```dart
// controllers/splash_controller.dart
final sessao = Get.find<SessaoService>();
await sessao.init();      // restaura token e perfil do armazenamento
```

---

## 🚀 Como Executar

### 1. Backend

```bash
# na raiz do projeto
./api.exe
```

A API sobe na porta **8081** e a documentação fica em
<http://localhost:8081/swagger/>.

### 2. App

```bash
flutter pub get
flutter run
```

### 2.1 Device Preview (ver as telas em vários aparelhos)

Para conferir o comportamento responsivo (RNF01) sem trocar de
emulador, existe um entrypoint de desenvolvimento que envolve o app no
`device_preview`:

```bash
flutter run -t dev/main_dev.dart
```

A barra lateral permite trocar de aparelho, girar a tela, alternar o
dark mode, ajustar o tamanho do texto e ligar o teclado virtual.

Aparelhos mais úteis para conferir o app:

| Referência | Device |
|------------|--------|
| Tela pequena (checar overflow) | `Devices.ios.iPhoneSE` · `Devices.android.smallPhone` |
| Base do design | `Devices.ios.iPhone13` |
| Tela grande | `Devices.ios.iPhone16ProMax` · `Devices.android.bigPhone` |
| Tablet | `Devices.ios.iPad` · `Devices.android.mediumTablet` |

> O arquivo fica em `dev/` e **não** em `lib/` de propósito: o
> `device_preview` é uma `dev_dependency` e não deve entrar no build de
> produção. Comparando os dois builds fica evidente:

> ```bash
> flutter build bundle -t dev/main_dev.dart   # 73,5 MB (com preview)
> flutter build bundle                        # 66,3 MB (produção)
> ```

### Endereço da API

`core/config/api_config.dart` escolhe o endereço automaticamente:

| Ambiente | URL |
|----------|-----|
| Emulador Android | `http://10.0.2.2:8081/api` |
| Simulador iOS / desktop | `http://localhost:8081/api` |
| Celular físico (Wi-Fi) | `http://192.168.x.x:8081/api` |

Para apontar manualmente, sem alterar o código:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.0.10:8081/api
```

### 3. Testes

```bash
flutter analyze          # análise estática
flutter test             # suíte completa (41 testes)
```

A suíte é dividida em quatro arquivos:

| Arquivo | Escopo | Precisa do backend? |
|---------|--------|---------------------|
| `test/widget_test.dart` | Regras de RBAC, estado da sessão, widgets | Não |
| `test/bindings_test.dart` | Grafo de dependências do `MainBinding` e guardas de rota | Não |
| `test/fluxo_rotas_test.dart` | Navegação, guards, validação e restauração de sessão | Não |
| `test/integracao_auth_test.dart` | Login, cadastro, recuperação e 403 do docente | Sim (ignorados se a API estiver fora) |

> **Detalhe importante:** dentro de `testWidgets` o tempo é *fake*, então
> chamadas reais de plataforma (o `flutter_secure_storage`) nunca
> completam e travam o teste. Por isso existe um dublê do armazenamento
> seguro em `test/helpers/test_armazenamento.dart`. Com ele, o ciclo
> "gravar sessão → reabrir o app → restaurar sessão" é testado de ponta
> a ponta, pelo mesmo caminho usado pelo app real.

---

## 👥 Equipe

| Membro | Responsabilidade | Parte |
|--------|------------------|-------|
| _a preencher_ | Estrutura base, tema, rotas e DI | 1 |
| _a preencher_ | Autenticação, sessão e comunicação com a API | 2 |
| _a preencher_ | Biblioteca de widgets e camada de dados | 3 |
| _a preencher_ | Painel do Coordenador | 4 |
| _a preencher_ | Painel do Professor e Perfil | 5 |
