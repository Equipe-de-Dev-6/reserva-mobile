# 🎨 Protótipo de Alta Fidelidade — Patrimônio Escolar

Este documento acompanha o protótipo visual do app e explica como
levá-lo para o Figma.

- **Arquivo do protótipo:** [`prototipo.html`](prototipo.html) —
  HTML + CSS autocontido, sem nenhuma dependência externa.
- **Prints reais do app:** [`../docs/prints/`](../docs/prints/) —
  PNGs gerados pelo próprio código Flutter (`tool/gerar_prints_test.dart`).

> **Por que dois?** O HTML serve para **desenhar e iterar** rápido (e
> para importar no Figma). Os PNGs servem para provar que o que está no
> protótipo **existe no app funcionando** — com as mesmas widgets, a
> mesma paleta e a mesma tipografia. São as duas coisas que o §9 do
> enunciado pede: o protótipo visual **e** o app em funcionamento.

---

## 1. Como importar no Figma (gratuito)

O §9 do enunciado menciona o plugin **HTML to Design**, que converte
interfaces geradas por IA em pranchetas do Figma. O passo a passo:

1. **Sirva** a pasta do projeto (o plugin precisa de uma URL, não
   aceita `file://`):

   ```bash
   cd design
   npx serve .          # ou: python -m http.server 8080
   ```

2. No Figma, abra o plugin **HTML to Design** (menu de plugins da
   comunidade, gratuito).

3. Informe a URL `http://localhost:8080/prototipo.html`.

4. O plugin importa cada frame `.phone` como um **artboard de
   390 × 844** — a grade do iPhone 13.

5. Renomeie os artboards conforme a tabela da seção 3 e organize em
   páginas ("Módulo 1", "Módulo 2", "Módulo 3", "Estados").

**Alternativa sem plugin:** o protótipo também pode ser aberto
direto no navegador (`design/prototipo.html`) e usado como referência
visual durante a revisão de código.

---

## 2. Tokens de design

Todos os valores vêm de `lib/app/tema.dart` — o protótipo e o app
não podem divergir.

### Cores

| Token | Hex | Uso |
|-------|-----|-----|
| `Tema.azulPrimario` | `#1B4DB1` | Cor primária, AppBar, botões, destaques |
| `Tema.azulEscuro` | `#0F2E6B` | Fim do gradiente do cabeçalho do usuário |
| `Tema.fundo` | `#F4F6FB` | Fundo das telas |
| `Tema.sucesso` | `#1B8A5A` | "Disponível", mensagens de sucesso |
| `Tema.alerta` | `#D9822B` | "Em manutenção" |
| `Tema.perigo` | `#C0392B` | "Baixado", exclusão, logout |

Gradiente do cabeçalho: `LinearGradient(135°, #1B4DB1 → #0F2E6B)`.

### Tipografia

Família **Roboto** (empacotada em `assets/fonts/`).

| Uso | Tamanho | Peso |
|-----|---------|------|
| Título de tela (AppBar) | 18 | 600 |
| Título de seção | 17 | 700 |
| Título de card | 15–16 | 600–700 |
| Texto do corpo | 14–15 | 400–500 |
| Texto secundário | 12–13 | 400 |
| Rótulo de campo | 12,5 | 600 |
| Eyebrow (título de seção em caixa alta) | 12 | 800, `letterSpacing: 0.7` |

### Formas e espaçamento

| Elemento | Raio |
|----------|------|
| Cartão | 16 |
| Botão / input | 12 |
| Campo de busca | 12 |
| Badge | 999 (pílula) |
| Avatar | 50% (círculo) |

Espaçamento base: **16** (padding de tela), **12** (entre itens),
**8** (interno). Alvo de toque mínimo: 48 px.

### Grade

- **Referência:** iPhone 13 — 390 × 844.
- **Margem lateral:** 16 px (20 px nos painéis).
- **Barra de status:** 44 px.
- **Alvo mínimo testado:** iPhone SE (375 × 667) e iPad.

---

## 3. Inventário de telas

### Módulo 1 — Autenticação e Sessão

| # | Tela | Requisito | Arquivo no app |
|---|------|-----------|-----------------|
| 01 | Login | RF01 | `views/auth/login_view.dart` |
| 02 | Cadastro de Coordenador | RF02 / RN01 | `views/auth/cadastro_admin_view.dart` |
| 03 | Recuperação de senha (3 etapas) | RF03 | `views/auth/recuperar_senha_view.dart` |

### Módulo 2 — Painel do Coordenador

| # | Tela | Requisito | Arquivo no app |
|---|------|-----------|-----------------|
| 04 | Painel do Coordenador (menu) | — | `views/admin/admin_home_view.dart` |
| 05 | Indicadores | RF05 | `views/admin/dashboard_view.dart` |
| 06 | Lista de patrimônios | RF07a | `views/patrimonio/patrimonio_lista_view.dart` |
| 07 | Detalhe do bem | RF07a | `views/patrimonio/patrimonio_detalhe_view.dart` |
| 08 | Formulário de patrimônio | RF07a | `views/patrimonio/patrimonio_form_view.dart` |
| 09 | Atribuição a um docente | RF07b / RN05 | `views/patrimonio/patrimonio_atribuicao_view.dart` |
| 10 | Devolução (com motivo) | RF07b / RN05 | `views/patrimonio/patrimonio_devolucao_view.dart` |
| 11 | Histórico / linha do tempo | RF07b | `views/patrimonio/patrimonio_historico_view.dart` |
| 12 | Lista de professores | RF06 | `views/admin/professores/professores_lista_view.dart` |
| 13 | Cadastro de professor | RF06 / RN02 | `views/admin/professores/professor_cadastro_view.dart` |
| 14 | Detalhe do professor | RF06 | `views/admin/professores/professor_detalhe_view.dart` |

### Módulo 3 — Painel do Professor

| # | Tela | Requisito | Arquivo no app |
|---|------|-----------|-----------------|
| 15 | Painel do Professor (menu) | — | `views/professor/professor_home_view.dart` |
| 16 | Meus Patrimônios | RF08 / RN03 | `views/professor/meus_patrimonios_view.dart` |
| 17 | Perfil (leitura, edição, senha) | RF09 / RN06 | `views/perfil/perfil_view.dart` |

### Estados assíncronos (RNF02)

| Estado | Onde aparece |
|--------|--------------|
| Loading com skeleton | listas de patrimônio, de professor e de meus bens |
| Estado vazio (com ação sugerida) | acervo vazio, busca sem resultado, docente sem bens |
| Erro com "Tentar novamente" | qualquer falha de rede em qualquer listagem |
| Toast de sucesso | atribuição, devolução, cadastro, exclusão, logout |

### Diagnóstico de conexão (troubleshooting)

A tela de Login tem o botão **"Verificar conexão com a API"**. Ele testa
`GET /health` e mostra o endereço em uso, se a API respondeu e o que
fazer — cada pessoa precisa do `api.exe` rodando na própria máquina, e o
endereço muda conforme o dispositivo.

| Onde o app roda | Endereço |
|------------------|----------|
| Emulador Android | `http://10.0.2.2:8081/api` |
| Simulador iOS / desktop / web | `http://localhost:8081/api` |
| Celular físico (Wi-Fi) | `http://192.168.x.x:8081/api` |

---

## 4. Princípios de UX aplicados

1. **O docente não vê ações de escrita — nem esmaecidas.** Esconder o
   botão (e não apenas desabilitá-lo) é a forma de a RN03 ficar
   visível na interface. O botão "Novo bem" e as ações do detalhe só
   aparecem para o Coordenador.

2. **Cada estado vazio diz o que fazer.** "Nenhum bem cadastrado"
   sugere cadastrar; "Nenhum bem encontrado" sugere limpar o filtro.
   São mensagens diferentes porque a ação seguinte é diferente.

3. **A mensagem de erro diz o que aconteceu, não o código HTTP.**
   O backend responde `403`; a tela responde "Você não tem permissão
   para realizar esta ação.".

4. **O motivo da devolução é obrigatório.** Ele é o que fica
   registrado na linha do tempo e explica, meses depois, por que o
   equipamento saiu da mão do docente.

5. **O contador de bens acompanha o docente.** O card do professor
   mostra "3 bens sob responsabilidade" — o dado que o RF06 pede,
   pronto do servidor.

6. **O mesmo card de bem nas três telas.** Listagem do acervo, bens de
   um docente e "Meus Patrimônios" usam o mesmo `CardPatrimonio`. Um
   card só, três contextos — e nenhuma duplicação de layout (RNF04).

---

## 5. Checklist de revisão visual

Antes de dar o protótipo como pronto, confira:

- [ ] Nenhum texto ultrapassa a largura do card (em 390 px e em 375 px)
- [ ] Nenhum botão fica com o rótulo cortado
- [ ] Todo toque tem no mínimo 48 px de altura
- [ ] O estado vazio de cada lista diz a próxima ação
- [ ] Nenhuma ação de escrita aparece para o perfil professor
- [ ] Os estados de erro, de carregamento e vazio foram desenhados
- [ ] O contraste do texto sobre o azul da AppBar passa em 4,5:1
