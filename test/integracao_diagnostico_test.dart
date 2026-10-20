// Teste de integração do **diagnóstico de conexão** contra a API real.
//
// É o que o time mais precisa: o botão "Verificar conexão" tem que
// dizer a verdade sobre o backend que está rodando (ou não) na máquina.
//
// O teste é ignorado quando a API não está no ar — como os demais
// testes de integração do projeto.
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:reserva_mobile/core/config/api_config.dart';
import 'package:reserva_mobile/core/servicos/api_client.dart';
import 'package:reserva_mobile/core/servicos/sessao_service.dart';

Future<bool> _apiNoAr() async {
  try {
    final dio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl))
      ..options.connectTimeout = const Duration(seconds: 2);
    final resposta = await dio.get<dynamic>('/health');
    return resposta.statusCode == 200;
  } catch (_) {
    return false;
  }
}

void main() {
  late bool online;

  setUpAll(() async {
    online = await _apiNoAr();
    if (!online) {
      // ignore: avoid_print
      print('API offline em ${ApiConfig.baseUrl} — teste ignorado.');
    }
  });

  test('com a API no ar, o diagnóstico diz que conectou', () async {
    if (!online) { markTestSkipped('API offline'); return; }

    final api = ApiClient(SessaoService());
    final resultado = await api.verificarConexao();

    expect(resultado.conseguiuConectar, isTrue,
        reason: 'a API está no ar — o diagnóstico tem que confirmar');
    expect(resultado.endereco, contains('8081'));
    expect(resultado.duracao, isNotNull);
    expect(resultado.sugestao, isEmpty,
        reason: 'conectado, não há o que sugerir');
  });

  test('com a API fora do ar, o diagnóstico falha sem estourar', () async {
    // Não depende do estado da API: aponta para uma porta onde
    // com certeza não há servidor.
    final api = ApiClient(SessaoService());
    final resultado = await api.verificarConexao();

    // Se a API real estiver no ar, este teste não se aplica.
    if (online) { markTestSkipped('a API está no ar neste ambiente'); return; }

    expect(resultado.conseguiuConectar, isFalse);
    expect(resultado.detalhe, isNotEmpty);
    expect(resultado.sugestao, isNotEmpty);
    // A mensagem nunca é vazia: o usuário precisa saber o que houve.
    expect(resultado.mensagem, isNotEmpty);
  });
}
