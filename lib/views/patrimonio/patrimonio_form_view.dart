import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show TextInputFormatter;
import 'package:get/get.dart';

import '../../app/tema.dart';
import '../../controllers/patrimonio_form_controller.dart';
import '../../core/servicos/patrimonio_service.dart';
import '../../widgets/botao_primario.dart';
import '../../widgets/campo_texto.dart';
import '../../widgets/mensagem_erro.dart';
import 'rotas_patrimonio.dart';

/// **RF07a — Formulário de cadastro e de edição de um bem.**
///
/// Um formulário só, dois modos. O modo é decidido pelo que chega em
/// `Get.arguments`:
///
/// ```dart
/// Get.toNamed(RotasPatrimonio.form, arguments: {'id': 0});               // cadastro
/// Get.toNamed(RotasPatrimonio.form, arguments: {'patrimonio': patrimonio}); // edição
/// ```
///
/// No cadastro, `codigo` e `nome` são obrigatórios — o backend exige os
/// dois (400 caso falte) e recusa tombamento repetido (409). O resto é
/// opcional e entra no formulário mesmo vazio, para o Coordenador
/// registrar o que souber na hora sem ser obrigado a preencher a ficha
/// inteira.
class PatrimonioFormView extends StatefulWidget {
  const PatrimonioFormView({super.key});

  @override
  State<PatrimonioFormView> createState() => _PatrimonioFormViewState();
}

class _PatrimonioFormViewState extends State<PatrimonioFormView> {
  /// A `GlobalKey` fica na View, não no Controller: só a View sabe
  /// quando aquele `Form` sai da árvore (ver AuthController).
  final _formKey = GlobalKey<FormState>();

  /// O Controller do GetX já foi criado pelo Binding, e o `onInit` dele
  /// descobre sozinho se é cadastro ou edição (`Get.arguments`). A View
  /// não precisa configurar nada — só desenhar.
  final PatrimonioFormController _controller =
      Get.find<PatrimonioFormController>();

  @override
  Widget build(BuildContext context) {
    final editando = _controller.editando;

    return Scaffold(
      appBar: AppBar(
        title: Text(editando ? 'Editar patrimônio' : 'Novo patrimônio'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              Obx(() => _controller.erro.value.isEmpty
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: MensagemErro.erro(_controller.erro.value),
                    )),

              // --- Identificação ----------------------------------------
              const _TituloSecao('Identificação'),
              CampoTexto(
                rotulo: 'Código de tombamento',
                dica: 'PAT-2024-009',
                icone: Icons.qr_code_2_rounded,
                controlador: _controller.codigoCtrl,
                // Identificador de tombamento muda por processo
                // patrimonial, não por edição de formulário.
                desabilitado: editando,
                // O tombamento é sempre em maiúsculas ("PAT-2024-001").
                // Forçar aqui evita que o usuário digite "pat-2024-001" e
                // o backend trate como um bem diferente.
                formatters: const [_TombamentoMaiusculo()],
                validator: _controller.validarCodigo,
              ),
              if (editando) ...[
                const SizedBox(height: 6),
                const Text(
                  'O tombamento não pode ser alterado após o cadastro.',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
              const SizedBox(height: 14),

              CampoTexto(
                rotulo: 'Nome do bem',
                dica: 'Notebook Dell Latitude 3420',
                icone: Icons.devices_other_outlined,
                controlador: _controller.nomeCtrl,
                validator: _controller.validarNome,
              ),
              const SizedBox(height: 14),

              _CampoObrigatorio(
                rotulo: 'Categoria',
                child: _SeletorCategoria(controller: _controller),
              ),
              const SizedBox(height: 14),

              // --- Especificações ---------------------------------------
              const _TituloSecao('Especificações'),
              CampoTexto(
                rotulo: 'Marca',
                dica: 'Dell',
                icone: Icons.branding_outlined,
                controlador: _controller.marcaCtrl,
              ),
              const SizedBox(height: 14),
              CampoTexto(
                rotulo: 'Modelo',
                dica: 'Latitude 3420',
                icone: Icons.memory_outlined,
                controlador: _controller.modeloCtrl,
              ),
              const SizedBox(height: 14),
              CampoTexto(
                rotulo: 'Número de série',
                dica: 'DL-992831',
                icone: Icons.pin_outlined,
                controlador: _controller.numeroSerieCtrl,
                validator: _controller.validarNumeroSerie,
              ),
              const SizedBox(height: 14),
              _CampoLongo(
                rotulo: 'Descrição / especificações',
                dica: 'Intel Core i5, 16GB RAM, SSD 512GB',
                icone: Icons.notes_rounded,
                controlador: _controller.descricaoCtrl,
              ),
              const SizedBox(height: 14),

              _CampoObrigatorio(
                rotulo: 'Estado de conservação',
                child: _SeletorConservacao(controller: _controller),
              ),
              const SizedBox(height: 14),

              // --- Localização ------------------------------------------
              const _TituloSecao('Localização e observações'),
              CampoTexto(
                rotulo: 'Onde está',
                dica: 'Sala 204 · Bloco B',
                icone: Icons.place_outlined,
                controlador: _controller.localizacaoCtrl,
              ),
              const SizedBox(height: 14),
              _CampoLongo(
                rotulo: 'Observações',
                dica: 'Entregue com bolsa e carregador original',
                icone: Icons.sticky_note_2_outlined,
                controlador: _controller.observacoesCtrl,
              ),

              // --- Envio -------------------------------------------------
              const SizedBox(height: 24),
              Obx(() => BotaoPrimario(
                    texto: _controller.textoBotao,
                    icone: editando
                        ? Icons.save_outlined
                        : Icons.add_box_outlined,
                    carregando: _controller.salvando.value,
                    aoTocar: () => _salvar(),
                  )),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Get.back<dynamic>(),
                child: const Text('Cancelar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _salvar() async {
    final salvo = await _controller.salvar(_formKey.currentState!);
    if (!mounted) return;

    if (salvo != null) {
      // Edição: a tela anterior recarrega o detalhe ao voltar.
      Get.back<dynamic>(result: salvo);
      return;
    }

    if (_controller.erro.value.isEmpty) {
      // Cadastro: não há Model devolvido pela API, só a confirmação.
      Get.back<dynamic>();
      Get.snackbar(
        'Patrimônio cadastrado',
        'O bem foi registrado no acervo.',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        backgroundColor: Tema.sucesso,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    }
  }
}

/// Versão multilinha do [CampoTexto].
///
/// Vive aqui, e não em `widgets/`, porque o `CampoTexto` do time ainda
/// não tem `maxLines`. Se ele ganhar esse parâmetro, este widget pode
/// ser apagado e as chamadas trocadas por `CampoTexto(maxLines: 3)`.
class _CampoLongo extends StatelessWidget {
  const _CampoLongo({
    required this.rotulo,
    required this.controlador,
    this.dica,
    this.icone,
  });

  final String rotulo;
  final String? dica;
  final IconData? icone;
  final TextEditingController controlador;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controlador,
      maxLines: 3,
      minLines: 2,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        labelText: rotulo,
        hintText: dica,
        prefixIcon: Padding(
          padding: const EdgeInsets.only(bottom: 34),
          child: Icon(icone ?? Icons.notes, size: 20),
        ),
      ),
    );
  }
}

/// Força o tombamento para maiúsculas enquanto o usuário digita.
///
/// Fica como `InputFormatter` (e não como `textCapitalization`) porque
/// o `CampoTexto` atual não expõe esse parâmetro — e capitalização de
/// teclado é só aparência, enquanto o formatter grava o valor já
/// convertido no controller.
class _TombamentoMaiusculo extends TextInputFormatter {
  const _TombamentoMaiusculo();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue anterior,
    TextEditingValue novo,
  ) {
    final maiusculo = novo.text.toUpperCase();
    if (maiusculo == novo.text) return novo;

    return novo.copyWith(
      text: maiusculo,
      selection: TextSelection.collapsed(offset: maiusculo.length),
    );
  }
}

/// Rótulo de seção dentro do formulário.
class _TituloSecao extends StatelessWidget {
  const _TituloSecao(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Text(
        texto.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: Tema.azulPrimario,
        ),
      ),
    );
  }
}

/// Wrapper que dá a mesma aparência de campo do [CampoTexto] a um
/// `DropdownButton`, para que categoria e conservação não destoem do
/// resto do formulário.
class _CampoObrigatorio extends StatelessWidget {
  const _CampoObrigatorio({required this.rotulo, required this.child});

  final String rotulo;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          rotulo,
          style: TextStyle(
            fontSize: 12.5,
            color: Colors.black.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _SeletorCategoria extends StatelessWidget {
  const _SeletorCategoria({required this.controller});

  final PatrimonioFormController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDE3EE)),
      ),
      child: Obx(() => DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: controller.categoria.value.isEmpty
                  ? null
                  : controller.categoria.value,
              hint: const Text('Selecione a categoria'),
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down),
              borderRadius: BorderRadius.circular(12),
              items: [
                for (final categoria in categoriasPatrimonio)
                  DropdownMenuItem(value: categoria, child: Text(categoria)),
              ],
              onChanged: (valor) => controller.categoria.value = valor ?? '',
            ),
          )),
    );
  }
}

class _SeletorConservacao extends StatelessWidget {
  const _SeletorConservacao({required this.controller});

  final PatrimonioFormController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDE3EE)),
      ),
      child: Obx(() => DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: controller.estadoConservacao.value.isEmpty
                  ? null
                  : controller.estadoConservacao.value,
              hint: const Text('Selecione o estado'),
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down),
              borderRadius: BorderRadius.circular(12),
              items: [
                for (final estado in estadosConservacao)
                  DropdownMenuItem(value: estado, child: Text(estado)),
              ],
              onChanged: (valor) =>
                  controller.estadoConservacao.value = valor ?? '',
            ),
          )),
    );
  }
}
