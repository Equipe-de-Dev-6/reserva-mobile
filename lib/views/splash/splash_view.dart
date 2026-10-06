import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/tema.dart';
import '../../controllers/splash_controller.dart';

/// Tela de abertura. Fica visível enquanto o `SessaoService` restaura
/// o token salvo e o [SplashController] decide para onde ir.
///
/// O acesso a `controller` dentro do `Obx` é o que instancia o
/// Controller via `SplashBinding` e dispara `onReady`.
class SplashView extends GetView<SplashController> {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Tema.azulPrimario, Tema.azulEscuro],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Logo(),
              SizedBox(height: 26),
              Text(
                'Patrimônio Escolar',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Sistema Integrado de Gestão',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              SizedBox(height: 44),
              _IndicadorCarregamento(),
            ],
          ),
        ),
      ),
    );
  }
}

/// Spinner que some assim que o destino da navegação está decidido.
class _IndicadorCarregamento extends GetView<SplashController> {
  const _IndicadorCarregamento();

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => controller.verificando.value
          ? const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                valueColor: AlwaysStoppedAnimation(Colors.white70),
              ),
            )
          : const SizedBox(width: 28, height: 28),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
      ),
      child: const Icon(Icons.school_rounded,
          size: 54, color: Tema.azulPrimario),
    );
  }
}
