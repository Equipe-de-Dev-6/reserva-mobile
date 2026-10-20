# 🎤 Roteiro de Arguição

O §9 do enunciado diz: *"o professor passará pelas mesas de cada equipe
realizando perguntas técnicas diretas aos integrantes sobre o código-fonte
… Caso seja constatado o uso de ferramentas de IA para gerar código que os
alunos não saibam explicar ou justificar, a equipe/aluno receberá nota
ZERO."*

Este documento é o roteiro de estudo. Cada pergunta traz:

- **a resposta curta** (o que dizer);
- **onde está no código** (arquivo e símbolo) — para você abrir e mostrar;
- **por que** (a razão da decisão).

> **Regra de ouro:** se você não sabe explicar um arquivo do projeto,
> ele **não** pode estar no seu nome. Este roteiro cobre o que é provável
> que perguntem; o resto é o `docs/GUIA.md`.

---

## 0. Os números do projeto (cite com confiança)

| | |
|---|---|
| Requisitos funcionais implementados | **9 de 9** (RF01–RF09) |
| Regras de negócio implementadas | **7 de 7** (RN01–RN07) |
| Testes automatizados | **317**, todos passando |
| Cobertura de linhas | **80,4%** |
| Telas | 17 |
| Controllers | 13 |
| Widgets reutilizáveis | 12 |
| Endpoints da API consumidos | 21 de 24 |
| PRs no repositório | 14+ (todos com histórico rastreável) |

Comandos para comprovar na hora:

```bash
flutter analyze          # No issues found!
flutter test             # 317 testes
flutter test --coverage  # gera o lcov.info
```

---

## 1. As 10 perguntas mais prováveis

### 1. "Por que GetX? O que ele te dá?"

**Resposta:** GetX resolve três coisas de uma vez: **estado reativo**
(`Rx` + `Obx`), **navegação nomeada** (rotas declaradas com
`GetPage`, em vez de strings soltas) e **injeção de dependência**
(`Bindings`, que registram Services e Controllers por rota).

**Onde:** `lib/app/rotas.dart` (rotas), `lib/app/bindings.dart` (DI),
`lib/core/servicos/sessao_service.dart` (estado — `token`,
`refreshToken` e `usuario` são `Rx`).

**Por que:** o Controller fica sem estado próprio de UI e a View só
desenha; trocar o GetX por outro pacote exigiria reescrever as três
camadas.

---

### 2. "Me mostra como uma requisição sai do app."

**Resposta:** View → Controller → Service → `ApiClient` → HTTP.

```
toque na View
  → PatrimonioController.carregar()      (decide o quê pedir)
  → PatrimonioService.listar(busca, status, categoria)
  → ApiClient.get('/patrimonios', query: {...})
       ↳ interceptor 1: injeta "Authorization: Bearer <token>"
       ↳ interceptor 2: em 401, renova o token e repete a requisição
  → api.exe → SQLite → JSON
  → ApiClient devolve Map
  → Service converte JSON → List<PatrimonioModel>
  → Controller guarda em RxList
  → View redesenha via Obx
```

**Onde:** `lib/core/servicos/api_client.dart` (`_adicionarToken`,
`_tratarErro`), `lib/core/servicos/patrimonio_service.dart` (`listar`).

**Por que:** o Controller **nunca** conhece o `Dio`. Ele só fala com
Models. Isso mantém a regra de negócio testável sem rede.

---

### 3. "E se o token expirar no meio de uma requisição?"

**Resposta:** o `ApiClient` tem um interceptor de erro. Quando a
resposta é `401` e existe refresh token, ele renova **uma única vez**
e repete a requisição original de forma transparente.

**Onde:** `lib/core/servicos/api_client.dart` → `_tratarErro` e
`_renovarToken`.

**Por que a trava `_renovando`:** se cinco requisições falhassem ao
mesmo tempo, cada uma tentaria renovar o token — e o backend recusaria
a segunda renovação. A trava garante **uma** renovação por vez.

**Detalhe que impressiona:** o `ApiClient` usa **dois** clientes Dio —
`dio` (com interceptors) e `_dioCru` (sem). A renovação usa o cliente
cru para não entrar no interceptor de novo e criar um laço infinito.

---

### 4. "Como vocês garantem que o professor não escreve nada?"

**Resposta:** em **duas camadas independentes**.

1. **Interface:** `podeEditar` e `podeCadastrar` verificam
   `usuario.isAdmin`; o botão de "Novo bem" e as ações do detalhe só
   aparecem para o Coordenador. O `AdminMiddleware` bloqueia as rotas
   `/admin/...`.
2. **Servidor:** o backend responde `403 Forbidden` a qualquer escrita
   de professor. Isso é testado de verdade —
   `test/integracao_auth_test.dart` faz o professor autenticado tentar
   criar um bem e exige o 403.

**Onde:** `lib/controllers/patrimonio_controller.dart` (`podeCadastrar`),
`lib/controllers/patrimonio_detalhe_controller.dart` (`podeEditar`),
`lib/app/middleware.dart` (`AdminMiddleware`).

**Por que as duas:** a camada 1 é usabilidade (não mostrar o que não
pode usar); a camada 2 é segurança. Se alguém burlar a interface
(entrando na rota direto), o servidor ainda recusa.

---

### 5. "Onde está o JWT guardado? Por que não SharedPreferences?"

**Resposta:** em `flutter_secure_storage`, que usa o
`EncryptedSharedPreferences` no Android, o Keychain no iOS/macOS e o
DPAPI no Windows. O `SharedPreferences` grava em texto plano — não
serve para um token.

**Onde:** `lib/core/servicos/sessao_service.dart` →
`static const FlutterSecureStorage _storage`.

**Por que um GetxService:** `SessaoService` é `permanent: true` — a
sessão vive a vida inteira do app, e o `Get.put` síncrono garante que
o `ApiClient` (que depende dela) já esteja registrado.

---

### 6. "Como vocês testam? E os testes de tela?"

**Resposta:** 317 testes em três níveis:

| Nível | Arquivo | O que prova |
|-------|---------|-------------|
| **Model** | `patrimonio_test.dart`, `auth_test.dart` | o JSON que entra e sai |
| **Service/Controller** | `patrimonio_controller_test.dart`, `ciclo_vida_patrimonio_test.dart` | a rota chamada, o corpo enviado, a regra aplicada |
| **Widget** | `patrimonio_lista_view_test.dart`, `varredura_telas_test.dart` | a tela desenha, e o usuário consegue mexer |

**Dois detalhes que valem pontos:**

- **`test/varredura_telas_test.dart`** monta as **17 telas** em 3
  tamanhos (iPhone 13, iPhone SE e a janela larga do Chrome) e exige
  que nenhuma estoure layout. Foi assim que apareceram os bugs de
  overflow.
- **`test/helpers/test_armazenamento.dart`** é um dublê do
  `flutter_secure_storage`. Dentro de `testWidgets` o tempo é *fake*:
  uma chamada real de plataforma nunca completa e trava o teste. Com o
  dublê, o ciclo "gravar sessão → reabrir o app → restaurar sessão" é
  testado de ponta a ponta.

**Onde:** `test/` inteiro; `test/helpers/`.

---

### 7. "Por que o `dart_test.yaml` tem `concurrency: 1`?"

**Resposta:** dois arquivos de teste de integração batem na API real ao
mesmo tempo, e o backend em Go tem uma corrida na tabela de refresh
token: com os arquivos em paralelo, o `POST /auth/refresh` responde
*"Erro ao salvar sessão de refresh token"* e o teste falha por um motivo
que **não é do app**.

**Onde:** `dart_test.yaml`.

**Por que não foi corrigido no app:** o problema é do servidor. Forçar
`concurrency: 1` na CI é a correção honesta — e o arquivo está
comentado explicando o porquê.

---

### 8. "Como vocês garantem que não há duplicação de código?"

**Resposta:** o widget de patrimônio (`CardPatrimonio`) é **um só** e
serve às três telas onde o bem aparece: a listagem do acervo, os bens
de um docente e "Meus Patrimônios". Ele é estritamente informativo —
quem tem ação de escrita (o Coordenador) coloca o botão **na tela**,
fora do card. Assim o mesmo widget serve ao docente sem precisar de uma
variante "sem botões".

**Onde:** `lib/widgets/card_patrimonio.dart` (usado em
`patrimonio_lista_view.dart`, `professor_detalhe_view.dart` e
`meus_patrimonios_view.dart`).

**Outros exemplos:** `CampoTexto` (input com máscara, senha e
validação), `BotaoPrimario` (com estado de carregando),
`BadgeStatus`, `EstadoVazio`, `EsqueletoLista`, `MensagemErro`,
`LinhaDado`.

---

### 9. "Por que o Controller guarda `TextEditingController`? Achei que isso era da View."

**Resposta (esta é uma pergunta sobre uma decisão real do projeto):**
o Controller guarda para que a **regra** (validação, montagem do corpo)
fique em um lugar só. O problema que isso criou é conhecido e
documentado: o GetX descarta o Controller no instante em que a rota
sai, enquanto a View ainda está saindo da árvore — e o `TextFormField`,
ao ser desmontado, chama `removeListener` num controller já
descartado. O Flutter então estoura *"A TextEditingController was used
after being disposed"*.

**A solução adotada** (`lib/core/utils/text_controllers.dart`): o
Controller **limpa** os campos e **não** os descarta — eles são
liberados junto com o Controller, pelo coletor de lixo.

**Alternativa que seria o ideal:** o `TextEditingController` pertence à
**widget** que o usa, como a `GlobalKey<FormState>` — que já pertence à
View. É uma refatoração grande (6 Controllers, 8 telas) e ficou como
melhoria futura.

**Onde:** `lib/core/utils/text_controllers.dart`,
`lib/widgets/campo_texto.dart`.

**Por que citar isso:** mostra que vocês conhecem o trade-off e sabem
explicar o porquê. Se o professor perguntar "e por que não refatorou?",
a resposta honesta é "por tempo de entrega; o risco está neutralizado e
tem teste de regressão".

---

### 10. "Como vocês tratam um erro de rede?"

**Resposta:** há **uma única fronteira** de tradução de erro:
`lib/core/utils/api_erros.dart`. Nenhum Controller conhece
`DioException`.

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

A prioridade é a mensagem que o **backend** enviou (`{"error": "..."}`),
porque ela já é escrita para o usuário final. Sem ela, há um texto
padrão por código HTTP (401, 403, 404, 409…).

**Onde:** `lib/core/utils/api_erros.dart`, `lib/core/utils/app_exception.dart`.

**Detalhe:** a mensagem de falha de **conexão** cita a **URL tentada**
— é o dado que resolve na hora o problema mais comum do time (cada
pessoa precisa do `api.exe` rodando na própria máquina, e o endereço
muda conforme o dispositivo). Há até um botão "Verificar conexão com a
API" na tela de Login (`lib/views/auth/bloco_diagnostico.dart`).

---

## 2. Perguntas por módulo

### Módulo 1 — Autenticação (RF01–RF04)

**P. "Por que o cadastro cria só Coordenador?"**
**R:** o corpo da requisição **não tem** o campo `role`
(`CadastroAdminRequestModel` em `lib/models/auth_requests.dart`) — o
app não pode escolher o papel de ninguém. O backend fixa `admin` (RN01).
Teste: `test/auth_test.dart` verifica que o JSON **não** contém `role`.

**P. "A recuperação de senha funciona de verdade?"**
**R:** são 3 etapas (`solicitarCodigo` → `verificarCodigo` →
`redefinirSenha`) em `lib/controllers/auth_controller.dart`, com os
endpoints `/auth/forgot-password`, `/auth/verify-code` e
`/auth/reset-password`. O detalhe honesto: **o backend não envia
e-mail** — ele imprime o código de 6 dígitos no console do servidor
(validade de 15 min). Por isso a tela diz "confira o console do
`api.exe`" em vez de prometer um e-mail que não chega. Documentado em
`docs/GUIA.md`.

**P. "Por que a senha não é guardada?"**
**R:** só o token JWT e o refresh token são guardados — em
`flutter_secure_storage`. A senha nunca é persistida. E o Controller
**limpa** os campos de senha no `onClose`.

---

### Módulo 2 — Coordenador (RF05–RF07)

**P. "Como vocês calculam o dashboard?"**
**R:** **não calculamos**. O backend devolve os contadores prontos em
`GET /admin/patrimonios/stats` (`totalPatrimonios`,
`patrimoniosEmUso`, `patrimoniosDisponiveis`,
`patrimoniosEmManutencao`, `totalProfessores`, `porCategoria`) e o
`PatrimonioStatsModel` só os lê. Calcular no cliente repetiria a regra
do servidor e poderia divergir (um bem `baixado`, por exemplo).

**P. "A atribuição e a devolução estão ligadas ao histórico?"**
**R:** sim — o backend grava a movimentação a cada uma das duas
operações, e a linha do tempo (`GET /admin/patrimonios/{id}/historico`)
mostra os eventos. Verificado de ponta a ponta: criar → atribuir →
devolver → histórico devolve 3 eventos (`criacao`, `atribuicao`,
`desatribuicao`).

**P. "Por que a devolução exige motivo?"**
**R:** é o que fica registrado na linha do tempo. Sem ele, o histórico
mostra *que* o bem saiu, mas não *por quê* — e é justamente o que se
precisa saber meses depois. A validação está no Controller
(`validarMotivo`).

---

### Módulo 3 — Professor (RF08–RF09)

**P. "O que impede o professor de ver os bens de outro?"**
**R:** o backend filtra por `professorId` no token; o app só pede
`GET /patrimonios/meus`. Não é uma proteção do app — é do servidor.
O app **não mostra** botão de escrita para o professor (RN03).

**P. "O professor consegue mudar a própria senha?"**
**R:** sim, e é pelo mesmo endpoint dos dados: `PUT /profile` com a
chave `newPassword` (`lib/core/servicos/perfil_service.dart`). Não
existe rota separada de troca de senha no Swagger. O Controller
**sincroniza a sessão** depois de salvar, para o cabeçalho do app
mostrar o nome novo sem novo login.

---

## 3. As 6 decisões técnicas (o README explica cada uma)

| # | Decisão | Onde |
|---|---------|-------|
| 1 | Token em `flutter_secure_storage` | `core/servicos/sessao_service.dart` |
| 2 | `Authorization` automático + refresh single-flight | `core/servicos/api_client.dart` |
| 3 | Uma fronteira só de erro | `core/utils/api_erros.dart` |
| 4 | Roteamento por `role` em um lugar só | `app/middleware.dart` → `rotaPorSessao` |
| 5 | Três guardas de rota (sessão / anônimo / admin) | `app/middleware.dart` |
| 6 | `FormKey` na View, validação no Controller **e** no Form | `controllers/*` |

---

## 4. As 3 armadilhas do projeto (o professor pode pegar vocês nelas)

### ⚠️ 1. O `data.db` não está no Git — de propósito

O `api.exe` é versionado (é binário Windows fornecido pela equipe de
backend), mas o **banco não**. Ele é criado e alterado a cada
execução — versioná-lo garante conflito de merge binário a cada PR.
O `.gitignore` diz isso explicitamente.

**Se perguntarem como o banco é criado:** o `api.exe` o cria sozinho na
primeira execução e popula o administrador. Não há script de migração
nem `seed` para rodar.

### ⚠️ 2. A branch `main` teve que ser "desfeita" uma vez

O merge `6f25d67` resolveu um conflito tomando o lado da `main` e
**apagou** o módulo de patrimônio inteiro (4.669 linhas) — a `main`
ficou sem compilar. O commit `revert: "Merge branch 'main' of" (6f25d67)`
desfaz isso.

**Como explicar:** é honesto e mostra domínio de Git. Se preferirem não
mencionar, saibam que o histórico está lá e o professor pode ver.

### ⚠️ 3. A CI roda em Windows, não em Linux

Porque o backend é um **binário Windows**. A CI sobe o `api.exe`,
espera o `/health` responder e só então roda a suíte — assim os
testes de integração rodam de verdade, contra a API real.

**Onde:** `.github/workflows/ci.yml`.

---

## 5. Roteiro de demonstração (5 minutos)

Se o professor pedir para ver o app funcionando:

1. **Terminal 1:** `./api.exe` (deixe a janela aberta — o código sai
   **nela**).
2. **Terminal 2:** `flutter run` (ou `flutter run -d chrome -t dev/main_dev.dart`).
3. **Login** com `admin@admin.com` / `admin123`.
4. **Indicadores** → mostre os 4 cards e as barras por categoria.
5. **Patrimônios** → filtre por "Em uso", abra um bem.
6. **Entregar a um professor** → selecione o docente → confirme.
7. **Ver histórico** → mostre os 3 eventos na linha do tempo.
8. **Meus patrimônios** (login como `professor@escola.com` / `prof123`)
   → mostre que o docente **não tem** botão de escrita.
9. **Verificar conexão com a API** → mostre o diagnóstico (e desligue a
   API no meio para ver o erro de conexão).

---

## 6. Checklist antes da arguição

- [ ] Consigo explicar o caminho de uma requisição sem olhar o código
- [ ] Consigo explicar o refresh single-flight e a trava `_renovando`
- [ ] Consigo explicar as 3 guardas de rota e por que a segurança real
      é do backend
- [ ] Consigo dizer por que o `TextEditingController` é limpo e não
      descartado
- [ ] Consigo dizer por que a validação está no Controller **e** no Form
- [ ] Consigo apontar onde está cada RF na tela
- [ ] Consigo rodar `flutter analyze` e `flutter test` sem travar
- [ ] Sei o número de testes e a cobertura
- [ ] Sei por que o `data.db` não está no Git
- [ ] Sei por que a CI roda em Windows
