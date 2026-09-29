import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/servicos/sessao_service.dart';
import 'rotas.dart';

/// Guarda de rota: garante que apenas quem tem sessão válida entre
/// nas telas internas do app (dashboard, listas, perfil).
///
/// Isto é defesa de interface. A segurança real continua sendo do
/// backend: mesmo que alguém force a tela, a API devolve 401/403 (RNF03).
class AutenticadoMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final sessao = Get.find<SessaoService>();
    if (sessao.autenticado) return null;

    // Importante: aqui NÃO chamamos `Get.offAllNamed`. O GetX já troca o
    // destino quando o middleware devolve um RouteSettings; navegar por
    // conta própria abriria a tela de Login duas vezes.
    return const RouteSettings(name: Rotas.login);
  }
}

/// Guarda de rota inversa: impede que quem já está logado volte para
/// Login, Cadastro ou Recuperação de Senha.
class AnonimoMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final sessao = Get.find<SessaoService>();
    if (!sessao.autenticado) return null;

    // Devolver `null` deixaria o GetX abrir a tela pedida normalmente.
    return RouteSettings(name: rotaPorSessao(sessao));
  }
}

/// Define a rota de destino conforme a role do usuário logado.
/// Regra central do RBAC: `admin` → painel administrativo;
/// qualquer outro papel → painel do docente (somente leitura).
String rotaPorSessao(SessaoService sessao) {
  final usuario = sessao.usuario.value;
  if (usuario != null && usuario.isAdmin) {
    return Rotas.homeAdmin;
  }
  return Rotas.homeProfessor;
}
