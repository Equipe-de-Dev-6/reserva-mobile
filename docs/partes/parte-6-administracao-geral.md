# Parte do Moises — Módulo 6: Administração Geral

> **Responsável:** MoisesTafarello
> **Branch:** `feature/administracao-geral`
> **Base:** `main`
> **Status:** a fazer

---

## 1. Por que esta parte

O escopo exigido pelo enunciado (RF01–RF09) está **completo**. Esta
parte usa os **três endpoints da API que ainda não são consumidos** —
a tag *"Administração Geral"* do Swagger — para dar ao quinto
integrante uma entrega real, com escopo fechado e valor visível:

| Endpoint | O que faz |
|----------|-----------|
| `GET /api/admin/users` | Lista **todos** os usuários da escola (id, nome, e-mail, papel, departamento, total de bens) |
| `PATCH /api/admin/users/{id}/role` | **Promove ou rebaixa** o papel de um usuário (`admin` ↔ `professor` ↔ `user`) |
| `GET /api/admin/stats` | Métricas gerais: total de usuários, admins, professores, sessões ativas e códigos de recuperação pendentes |

Além disso, a parte inclui **duas correções que o time precisa fazer**
(veja a seção 6) — o relatório de cobertura e a limpeza do banco de
testes.

---

## 2. O que já está pronto (use, não reescreva)

| Peça | Onde |
|------|------|
| Sessão e token | `core/servicos/sessao_service.dart` |
| Cliente HTTP com `Bearer` e refresh | `core/servicos/api_client.dart` |
| Padrão de Model | `lib/models/` (veja `professor_model.dart` como referência) |
| Padrão de Service | `lib/core/servicos/professor_service.dart` |
| Padrão de Controller + Validadores | `lib/controllers/professor_lista_controller.dart` |
| Padrão de View com estados | `lib/views/admin/professores/professores_lista_view.dart` |
| Widgets prontos | `lib/widgets/` (`cartao_professor`, `badge_status`, `botao_primario`, `campo_texto`, `estado_vazio`, `esqueleto_lista`, `mensagem_erro`) |
| Guarda de rota por papel | `AdminMiddleware` em `lib/app/middleware.dart` |

---

## 3. Passo a passo da implementação

### Passo 1 — Models

Crie `lib/models/usuario_admin_model.dart`:

```dart
class UsuarioAdminModel {
  final int id;
  final String nome;
  final String email;
  final String role;        // 'admin' | 'professor' | 'user'
  final String matricula;
  final String departamento;
  final String telefone;
  final int totalPatrimonios;
  final DateTime? createdAt;

  bool get isAdmin => role == 'admin';
  bool get isProfessor => role == 'professor';
  String get iniciais { /* mesma regra do UsuarioModel */ }
  String get rotuloPapel { /* 'Coordenador' | 'Professor' | 'Usuário' */ }
}
```

E um Model para as métricas (`lib/models/admin_stats_model.dart`) com
`totalUsers`, `totalAdmins`, `totalProfessores`, `standardUsers`,
`activeRefreshTokens`, `pendingResetCodes`.

> **Regra do projeto:** Model não conhece Flutter, não faz HTTP e não
> importa `material.dart`. Getters de regra moram aqui (como
> `isAdmin` no `UsuarioModel`), não na View.

### Passo 2 — Service

Crie `lib/core/servicos/admin_service.dart`:

```dart
class AdminService {
  AdminService(this._api);
  final ApiClient _api;

  Future<List<UsuarioAdminModel>> listarUsuarios() async { ... }   // GET  /admin/users
  Future<void> alterarPapel(int id, String role) async { ... }     // PATCH /admin/users/{id}/role
  Future<AdminStatsModel> estatisticas() async { ... }             // GET  /admin/stats
}
```

**Atenção:** o `ApiClient` **não tem** método `patch`. Adicione um ao
`lib/core/servicos/api_client.dart`, no mesmo padrão do `put`:

```dart
/// PATCH.
Future<Map<String, dynamic>> patch(String caminho, {Object? body}) async {
  final resposta = await chamar(() => dio.patch<dynamic>(caminho, data: body));
  return _corpo(resposta);
}
```

### Passo 3 — Controller

Crie `lib/controllers/admin_usuarios_controller.dart` com:
- `RxList<UsuarioAdminModel> usuarios`
- `RxBool carregando`, `RxString erro`
- `RxString busca` + debounce de 350 ms (copie o padrão de
  `PatrimonioController.aoDigitarBusca`)
- `Future<void> carregar()`
- `Future<bool> alterarPapel(int id, String novoPapel)` — **`true` só se
  deu certo**; em caso de erro, a mensagem fica em `erro` e a tela
  **não** fecha.

### Passo 4 — View

Crie `lib/views/admin/usuarios/usuarios_lista_view.dart`:
- Título "Usuários do sistema"
- Busca por nome, e-mail ou matrícula
- Um card por usuário: avatar com iniciais, nome, e-mail, `BadgeStatus`
  com o papel, e o contador de bens
- Botão de ação para **alterar o papel**, com **diálogo de
  confirmação** — é uma operação de **elevação de privilégio**, então
  a confirmação precisa avisar claramente ("Você está dando acesso
  total ao patrimônio da escola a esta pessoa").
- Estados de loading (skeleton), vazio e erro — copie de
  `professores_lista_view.dart`.

### Passo 5 — Rotas e injeção

Em `lib/app/rotas.dart`:
- `static const usuarios = '/admin/usuarios';`
- `GetPage` com `middlewares: [AutenticadoMiddleware(), AdminMiddleware()]`

Em `lib/app/bindings.dart`: um `AdminBinding` com o `AdminService` e o
Controller.

E **um atalho novo** no `lib/views/admin/admin_home_view.dart`:
"Usuários do sistema".

### Passo 6 — Dashboard

Some as métricas de `/admin/stats` ao `DashboardController` (RF05) como
**mais um cartão** — "Sessões ativas" — ou como um bloco "Sistema".

### Passo 7 — Testes (obrigatório)

Crie `test/admin_usuarios_test.dart` usando o dublê
`test/helpers/api_client_falso.dart`. Cobre, no mínimo:

| Teste | O que prova |
|-------|-------------|
| o Model lê o JSON real | `role`, `totalPatrimonios`, `iniciais` |
| o Service chama `GET /admin/users` | rota certa |
| o Service envia `{"role": "..."}` no `PATCH` | corpo certo |
| o Controller filtra a busca | regra no Model, não na View |
| erro 400 do backend vira mensagem | `AppException` tratada |
| a rota exige `AdminMiddleware` | RBAC |

Rode: `flutter test test/admin_usuarios_test.dart`

### Passo 8 — Print e protótipo

- Adicione o print em `tool/gerar_prints_test.dart` (copie o padrão do
  `print 12`) e gere o PNG.
- Adicione a tela em `design/prototipo.html`.

---

## 4. Respostas reais da API (já testadas)

```jsonc
// GET /api/admin/users
{
  "total": 9,
  "users": [{
    "id": 2,
    "email": "professor@escola.com",
    "nome": "Prof. Carlos Drummond",
    "role": "professor",
    "matricula": "PROF-2024-01",
    "departamento": "Língua Portuguesa e Literatura",
    "telefone": "(11) 98765-1001",
    "totalPatrimonios": 0,
    "createdAt": "2026-10-20T11:26:42Z"
    // ... demais campos do UserResponse
  }]
}

// PATCH /api/admin/users/2/role   body: {"role": "admin"}
{ "message": "Role do usuário atualizada com sucesso", "newRole": "admin", "userId": 2 }

// GET /api/admin/stats
{
  "totalUsers": 9,
  "totalAdmins": 1,
  "totalProfessores": 8,
  "standardUsers": 0,
  "activeRefreshTokens": 41,
  "pendingResetCodes": 0
}
```

**Erros esperados:** `400` (papel inválido — o backend responde
`Role inválida. Valores aceitos: 'admin', 'professor' ou 'user'`),
`403` (quem chamou não é admin), `404` (usuário inexistente).

---

## 5. Critérios de aceitação

- [ ] `flutter analyze` sem problemas
- [ ] `flutter test` passa (os 247 testes atuais + os novos)
- [ ] A tela de usuários **só** aparece para `admin` (uma sessão de
      professor não vê nem o atalho nem a rota)
- [ ] Um `professor` que tentar `PATCH /admin/users/{id}/role` recebe
      **403** do backend (teste de integração)
- [ ] Alterar o papel exige confirmação explícita na tela
- [ ] A documentação do README foi atualizada (RF novo + print)

---

## 6. Correções que o time precisa fazer (podem ir na mesma parte)

### 6.1 O banco de teste se suja

`test/integracao_auth_test.dart` cria um professor em **cada** execução
do grupo e **não apaga** — por isso `GET /admin/users` já mostra vários
`Prof. Teste RN03`. Como o `data.db` deixou de ser versionado, isso
não afeta mais o Git, mas atrapalha a demonstração.

**Correção:** no `tearDown` do grupo, deletar o professor criado
(`DELETE` não existe para usuário — use o `ApiClient` direto com o
`admin` para ajustar o papel, ou peça ao backend uma rota de remoção).

### 6.2 Relatório de cobertura na CI

O `.github/workflows/ci.yml` roda cobertura com `continue-on-error:
true`. Substitua por um step que **falha** se a cobertura cair, e
adicione o badge no README:

```yaml
- name: Cobertura
  run: flutter test --coverage
- name: Verificar cobertura
  run: dart run coverage:format_coverage --lcov --in=coverage --out=coverage/lcov.info --report-on=lib
```

---

## 7. Como abrir o Pull Request

A branch `feature/administracao-geral` **já existe** e está alinhada com
a `main`. O Pull Request é aberto **por você**, com os seus commits — é
isso que evidencia a sua participação no §8 do enunciado.

```bash
git checkout feature/administracao-geral
git pull origin feature/administracao-geral
# ... implementa ...
git add -A
git commit -m "feat(admin): tela de usuarios e alteracao de papel (Administração Geral)"
git push origin feature/administracao-geral
```

Depois, no GitHub: **Compare & pull request** → `main`. No corpo do
PR, descreva o que foi feito e cole a saída de `flutter test`.

> Confirme que o `git config user.name` / `user.email` da sua máquina
> estão com **a sua identidade**: é o commit com o seu nome no
> histórico que o professor vai ver.

---

## 8. Checklist de domínio para a arguição

Estes são os pontos que o professor provavelmente vai perguntar sobre
esta parte:

1. **Por que só o admin vê essa tela?** — `AdminMiddleware` na rota +
   backend responde `403` (defesa em duas camadas).
2. **O que acontece se o app deixar vazar a tela?** — a API responde 403;
   a segurança real é do servidor.
3. **Como o Controller sabe que a requisição deu certo?** — o Service
   devolve `void` e **lança** `AppException`; o Controller é quem
   decide a mensagem.
4. **Por que a busca filtra no aparelho e não na API?** — o endpoint
   `GET /admin/users` não aceita parâmetro de busca; a regra ficou no
   Model (`correspondeAoTermo`), para ser testável sem widget.
5. **Por que a alteração de papel pede confirmação?** — é elevação de
   privilégio; a confirmação impede clique acidental.
