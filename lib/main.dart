import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app/bindings.dart';
import 'app/middleware.dart';
import 'app/rotas.dart';
import 'app/tema.dart';
import 'core/servicos/sessao_service.dart';

/// Ponto de entrada do aplicativo.
void main() {
  // Garante que o binding do Flutter (usado pelo flutter_secure_storage)
  // esteja inicializado antes de qualquer chamada de plataforma.
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PatrimonioEscolarApp());
}

class PatrimonioEscolarApp extends StatelessWidget {
  const PatrimonioEscolarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Patrimônio Escolar',
      debugShowCheckedModeBanner: false,
      theme: Tema.claro,

      // Navegação nomeada com injeção de dependências e guardas de rota.
      initialBinding: MainBinding(),
      initialRoute: Rotas.splash,
      getPages: AppRotas.paginas,

      // Rede de segurança: uma URL desconhecida nunca deve renderizar
      // uma tela em branco.
      unknownRoute: _rotaDesconhecida,
    );
  }

  /// Redireciona o usuário ao destino correto quando a rota não existe.
  /// O `GetPage` abaixo não tem View própria: ele serve só de ponte para
  /// o `Get.offAllNamed` executado no primeiro frame.
  static final GetPage _rotaDesconhecida = GetPage(
    name: '/desconhecida',
    page: () => const _TelaDeEspera(),
    middlewares: [AutenticadoMiddleware()],
    transition: Transition.noTransition,
  );
}

class _TelaDeEspera extends StatelessWidget {
  const _TelaDeEspera();

  @override
  Widget build(BuildContext context) {
    final sessao = Get.find<SessaoService>();

    // O redirecionamento acontece fora da fase de build para não
    // provocar um "setState during build" do Flutter.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.offAllNamed(
        sessao.autenticado ? rotaPorSessao(sessao) : Rotas.login,
      );
    });

    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
