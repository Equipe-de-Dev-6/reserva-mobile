import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;

import '../config/api_config.dart';
import '../utils/api_erros.dart';
import '../utils/app_exception.dart';
import '../../models/resultado_diagnostico.dart';
import 'sessao_service.dart';

/// Callback disparado quando a sessão não pode mais ser renovada.
/// Registrado em `app/bindings.dart` para evitar acoplamento de
/// dependência entre a camada de rede e a de navegação.
typedef RedirecionarParaLogin = void Function();

/// Cliente HTTP único do aplicativo (camada Model → Controller).
///
/// Responsabilidades:
///  * injetar `Authorization: Bearer <token>` em toda rota protegida
///    (RNF03);
///  * renovar o access token uma única vez quando a API responde
///    `401 Unauthorized`, transparente para quem chamou;
///  * converter falhas de rede em [AppException] com texto amigável.
class ApiClient extends GetxService {
  ApiClient(this._sessao);

  final SessaoService _sessao;

  /// Acesso à sessão usada por este cliente.
  /// Exposto para diagnóstico e para os testes de integração.
  SessaoService get sessao => _sessao;

  /// Registrado pelo app para redirecionar à tela de login.
  static RedirecionarParaLogin? aoExpirarSessao;

  /// Cliente usado nas chamadas de autenticação que **não** recebem
  /// o interceptor de token (login, refresh, recuperação de senha).
  ///
  /// O `validateStatus` fica no padrão do Dio (2xx apenas). Assim um
  /// 400/401/403/404 vira `DioException` e passa por `mensagemDeErro`.
  final Dio dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.timeout,
      receiveTimeout: ApiConfig.timeout,
      sendTimeout: ApiConfig.timeout,
      headers: {'Content-Type': 'application/json'},
    ),
  );

  /// Cliente cru: usado apenas na renovação do token. Não leva
  /// interceptors, o que impede um laço infinito de renovação.
  final Dio _dioCru = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.timeout,
      receiveTimeout: ApiConfig.timeout,
      headers: {'Content-Type': 'application/json'},
    ),
  );

  /// Trava de reentrância: garante que apenas uma renovação ocorra por
  /// vez quando várias requisições falham simultaneamente.
  Future<bool>? _renovando;

  @override
  void onInit() {
    super.onInit();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _adicionarToken,
        onError: _tratarErro,
      ),
    );
  }

  // -------------------------------------------------------------------------
  // INTERCEPTOR 1 — cabeçalho de autorização (RNF03)
  // -------------------------------------------------------------------------
  void _adicionarToken(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    final token = _sessao.token.value;
    final ehPublica = options.extra['ignorarAuth'] == true;

    if (token.isNotEmpty && !ehPublica) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  // -------------------------------------------------------------------------
  // INTERCEPTOR 2 — renovação automática do token
  // -------------------------------------------------------------------------
  Future<void> _tratarErro(
    DioException erro,
    ErrorInterceptorHandler handler,
  ) async {
    final status = erro.response?.statusCode;
    final podeRenovar = status == 401 &&
        _sessao.refreshToken.value.isNotEmpty &&
        _sessao.token.value.isNotEmpty;

    if (!podeRenovar) {
      handler.next(erro);
      return;
    }

    try {
      await (_renovando ??= _renovarToken());
      _renovando = null;

      // Reprocessa a requisição original já com o token novo.
      final op = erro.requestOptions;
      op.headers['Authorization'] = 'Bearer ${_sessao.token.value}';
      final resposta = await dio.fetch<dynamic>(op);
      handler.resolve(resposta);
    } catch (_) {
      _renovando = null;
      // Token irrecuperável: encerra a sessão e volta para o login.
      await _sessao.limpar();
      aoExpirarSessao?.call();
      handler.next(erro);
    }
  }

  /// POST /auth/refresh — troca o refresh token por um access token novo.
  Future<bool> _renovarToken() async {
    final resposta = await _dioCru.post<dynamic>(
      '/auth/refresh',
      data: {'refreshToken': _sessao.refreshToken.value},
    );

    if (resposta.statusCode != 200 || resposta.data is! Map) return false;

    final novoToken = (resposta.data['token'] ??
            resposta.data['access_token'] ??
            '')
        .toString();
    if (novoToken.isEmpty) return false;

    final novoRefresh = (resposta.data['refreshToken'] ??
            resposta.data['refresh_token'] ??
            '')
        .toString();

    await _sessao.atualizarToken(novoToken);
    if (novoRefresh.isNotEmpty) {
      await _sessao.salvar(
        token: novoToken,
        refreshToken: novoRefresh,
        usuario: _sessao.usuario.value!,
      );
    }
    return true;
  }

  // -------------------------------------------------------------------------
  // Helpers usados pelos Services
  // -------------------------------------------------------------------------

  /// GET protegido.
  Future<Map<String, dynamic>> get(String caminho,
      {Map<String, dynamic>? query}) async {
    final resposta = await chamar(
      () => dio.get<dynamic>(caminho, queryParameters: query),
    );
    return _corpo(resposta);
  }

  // -------------------------------------------------------------------------
  // Diagnóstico de conexão
  // -------------------------------------------------------------------------

  /// Verifica se a API está de pé, chamando `GET /health`.
  ///
  /// Não usa o [dio] com interceptors (não precisa de token) e **não**
  /// joga exceção: devolve um [ResultadoDiagnostico] com o endereço
  /// usado, para que a tela de login possa mostrar exatamente onde o
  /// app está tentando chegar.
  ///
  /// É a ferramenta de diagnóstico do projeto: cada pessoa precisa do
  /// `api.exe` rodando na própria máquina, e o endereço muda conforme o
  /// dispositivo.
  Future<ResultadoDiagnostico> verificarConexao() async {
    final endereco = ApiConfig.baseUrl;
    final inicio = DateTime.now();

    try {
      // Usa o método `get` (e não o cliente cru) para que o dublê de
      // teste consiga responder a esta chamada, como responde às outras.
      final resposta = await get('/health');

      return ResultadoDiagnostico(
        endereco: endereco,
        conseguiuConectar: true,
        detalhe: resposta['message']?.toString() ?? 'API operacional.',
        duracao: DateTime.now().difference(inicio),
      );
    } on AppException catch (e) {
      // `statusCode` nulo = a requisição nem chegou ao servidor
      // (API fora do ar, endereço errado, firewall).
      return ResultadoDiagnostico(
        endereco: endereco,
        conseguiuConectar: false,
        detalhe: e.statusCode == null
            ? 'Não foi possível abrir conexão com $endereco.'
            : 'A API respondeu ${e.statusCode}: ${e.mensagem}',
        duracao: DateTime.now().difference(inicio),
      );
    } catch (e) {
      return ResultadoDiagnostico(
        endereco: endereco,
        conseguiuConectar: false,
        detalhe: 'Falha inesperada: $e',
        duracao: DateTime.now().difference(inicio),
      );
    }
  }

  /// Endereço base em uso — exposto para as mensagens de erro.
  String get enderecoBase => ApiConfig.baseUrl;

  /// POST.
  Future<Map<String, dynamic>> post(String caminho,
      {Object? body, bool autenticado = true}) async {
    final resposta = await chamar(
      () => dio.post<dynamic>(
        caminho,
        data: body,
        options: autenticado
            ? null
            : Options(extra: {'ignorarAuth': true}),
      ),
    );
    return _corpo(resposta);
  }

  /// PUT.
  Future<Map<String, dynamic>> put(String caminho, {Object? body}) async {
    final resposta =
        await chamar(() => dio.put<dynamic>(caminho, data: body));
    return _corpo(resposta);
  }

  /// PATCH.
  Future<Map<String, dynamic>> patch(String caminho, {Object? body}) async {
    final resposta =
        await chamar(() => dio.patch<dynamic>(caminho, data: body));
    return _corpo(resposta);
  }

  /// DELETE.
  Future<Map<String, dynamic>> delete(String caminho) async {
    final resposta = await chamar(() => dio.delete<dynamic>(caminho));
    return _corpo(resposta);
  }

  /// Garante que a resposta seja um objeto JSON utilizável.
  Map<String, dynamic> _corpo(Response<dynamic> resposta) {
    if (resposta.data is Map) {
      return Map<String, dynamic>.from(resposta.data as Map);
    }
    return const <String, dynamic>{};
  }
}
