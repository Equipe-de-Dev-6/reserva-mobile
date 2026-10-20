import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/tema.dart';
import '../../controllers/auth_controller.dart';
import '../../models/resultado_diagnostico.dart';
import '../../widgets/mensagem_erro.dart';

/// Bloco de **diagnóstico de conexão** da tela de Login.
///
/// O erro "Não foi possível conectar ao servidor" é o problema mais
/// comum de desenvolvimento com este projeto: cada pessoa precisa do
/// `api.exe` rodando **na própria máquina**, e o endereço da API muda
/// conforme o dispositivo (emulador Android, iOS, web ou celular
/// físico).
///
/// Em vez de só reclamar, o app **mostra o endereço que ele está
/// usando** e testa a conexão com `GET /health`. O resultado diz o que
/// está errado e o que fazer.
class BlocoDiagnostico extends StatelessWidget {
  const BlocoDiagnostico({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AuthController>();

    return Obx(() {
      final resultado = controller.diagnostico.value;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextButton.icon(
            onPressed: controller.verificandoConexao.value
                ? null
                : controller.verificarConexao,
            icon: controller.verificandoConexao.value
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.wifi_tethering, size: 16),
            label: Text(
              controller.verificandoConexao.value
                  ? 'Verificando...'
                  : 'Verificar conexão com a API',
            ),
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
          ),
          if (resultado != null) ...[
            const SizedBox(height: 4),
            _CartaoDiagnostico(resultado: resultado),
            const SizedBox(height: 12),
          ],
        ],
      );
    });
  }
}

/// Cartão com o resultado da verificação.
class _CartaoDiagnostico extends StatelessWidget {
  const _CartaoDiagnostico({required this.resultado});

  final ResultadoDiagnostico resultado;

  @override
  Widget build(BuildContext context) {
    final cor = resultado.conseguiuConectar ? Tema.sucesso : Tema.alerta;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                resultado.conseguiuConectar
                    ? Icons.check_circle_outline
                    : Icons.error_outline,
                size: 18,
                color: cor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  resultado.conseguiuConectar
                      ? 'API conectada'
                      : 'API não respondeu',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: cor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _LinhaDiagnostico(rotulo: 'Endereço', valor: resultado.endereco),
          const SizedBox(height: 4),
          _LinhaDiagnostico(rotulo: 'Detalhe', valor: resultado.mensagem),
          if (resultado.sugestao.isNotEmpty) ...[
            const SizedBox(height: 10),
            MensagemErro.mensagem(
              resultado.sugestao,
              tipo: TipoMensagem.aviso,
            ),
          ],
        ],
      ),
    );
  }
}

/// Linha "rótulo: valor" do diagnóstico.
class _LinhaDiagnostico extends StatelessWidget {
  const _LinhaDiagnostico({required this.rotulo, required this.valor});

  final String rotulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          rotulo,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
            color: Colors.black.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 1),
        Text(
          valor,
          style: const TextStyle(fontSize: 13, height: 1.35),
        ),
      ],
    );
  }
}
