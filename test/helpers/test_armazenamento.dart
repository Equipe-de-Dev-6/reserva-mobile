import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reserva_mobile/core/servicos/sessao_service.dart';
import 'package:reserva_mobile/models/usuario_model.dart';

/// Canal de plataforma usado pelo `flutter_secure_storage`.
const MethodChannel canalArmazenamentoSeguro =
    MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

/// Armazenamento seguro falso, com o mesmo comportamento do plugin
/// (grava, lê e apaga), porém em memória.
///
/// Por que existe: dentro de `testWidgets` o tempo é *fake*, então uma
/// chamada real de plataforma nunca completa e trava o teste. Com este
/// dublê o [SessaoService.init] conclui de verdade, e o ciclo
/// "gravar sessão → reabrir o app → restaurar sessão" passa a ser
/// testado de ponta a ponta, em vez de ser injetado por atalho.
class ArmazenamentoFalso {
  final Map<String, String> _dados = <String, String>{};

  /// Instala o dublê no canal de plataforma.
  void instalar() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(canalArmazenamentoSeguro, _responder);
  }

  /// Remove o dublê e descarta o conteúdo.
  void remover() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(canalArmazenamentoSeguro, null);
    _dados.clear();
  }

  Future<Object?> _responder(MethodCall chamada) async {
    final argumentos = (chamada.arguments as Map?)?.cast<String, Object?>() ??
        <String, Object?>{};

    switch (chamada.method) {
      case 'write':
        _dados[argumentos['key'] as String] = argumentos['value'] as String;
        return null;
      case 'read':
        return _dados[argumentos['key'] as String];
      case 'containsKey':
        return _dados.containsKey(argumentos['key'] as String);
      case 'delete':
        _dados.remove(argumentos['key'] as String);
        return null;
      case 'deleteAll':
        _dados.clear();
        return null;
      case 'readAll':
        return _dados.entries
            .map((e) => <String, String>{'key': e.key, 'value': e.value})
            .toList();
      default:
        return null;
    }
  }
}

/// Simula o app sendo fechado com uma sessão ativa.
///
/// Usa um [SessaoService] de verdade para gravar, de modo que as chaves
/// do armazenamento são as mesmas que o app usa. Depois disso, um novo
/// [SessaoService.init] no teste encontra a sessão e restaura.
Future<void> gravarSessaoSalva(UsuarioModel usuario) async {
  final sessaoAnterior = SessaoService();
  await sessaoAnterior.salvar(
    token: 'token-salvo-no-disco',
    refreshToken: 'refresh-salvo-no-disco',
    usuario: usuario,
  );
}

/// Monta uma sessão válida **em memória**, sem passar pelo disco.
///
/// Útil para exercitar o roteamento por role sem simular o fechamento
/// do app.
void loginEmMemoria(SessaoService sessao, UsuarioModel usuario) {
  sessao.token.value = 'token-de-teste';
  sessao.refreshToken.value = 'refresh-de-teste';
  sessao.usuario.value = usuario;
}

UsuarioModel adminDeTeste() => UsuarioModel(
      id: 1,
      nome: 'Coordenador Geral',
      email: 'admin@admin.com',
      role: 'admin',
    );

UsuarioModel professorDeTeste() => UsuarioModel(
      id: 2,
      nome: 'Prof. Carlos Drummond',
      email: 'professor@escola.com',
      role: 'professor',
    );
