import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:reserva_mobile/app/middleware.dart';
import 'package:reserva_mobile/app/rotas.dart';
import 'package:reserva_mobile/app/tema.dart';
import 'package:reserva_mobile/core/servicos/sessao_service.dart';
import 'package:reserva_mobile/models/usuario_model.dart';
import 'package:reserva_mobile/widgets/estado_vazio.dart';
import 'package:reserva_mobile/widgets/mensagem_erro.dart';

/// Testes unitários das regras de negócio do módulo de autenticação.
///
/// Cobrem o que não depende de servidor: o roteamento por role (RBAC),
/// o estado da sessão e o comportamento dos widgets reutilizáveis.
void main() {
  group('UsuarioModel — RBAC', () {
    test('admin é reconhecido como admin e não como professor', () {
      final admin = UsuarioModel(
        id: 1,
        nome: 'Coordenador Geral',
        email: 'admin@admin.com',
        role: 'admin',
      );
      expect(admin.isAdmin, isTrue);
      expect(admin.isProfessor, isFalse);
    });

    test('professor é reconhecido como professor e não como admin', () {
      final professor = UsuarioModel(
        id: 2,
        nome: 'Prof. Carlos Drummond',
        email: 'professor@escola.com',
        role: 'professor',
      );
      expect(professor.isProfessor, isTrue);
      expect(professor.isAdmin, isFalse);
    });

    test('fromJson tolera campos ausentes e id como string', () {
      final usuario = UsuarioModel.fromJson({'id': '7', 'nome': 'Ana'});
      expect(usuario.id, 7);
      expect(usuario.email, '');
      expect(usuario.role, 'professor'); // padrão seguro: menor privilégio
    });

    test('iniciais são calculadas a partir do nome', () {
      // Primeiro e último termo: "Prof. Carlos Drummond" -> "PD"
      final usuario =
          UsuarioModel(nome: 'Prof. Carlos Drummond', email: 'c@d.com');
      expect(usuario.iniciais, 'PD');

      final nomeCompleto =
          UsuarioModel(nome: 'Coordenador Geral', email: 'c@d.com');
      expect(nomeCompleto.iniciais, 'CG');

      final nomeUnico = UsuarioModel(nome: 'Ana', email: 'a@d.com');
      expect(nomeUnico.iniciais, 'A');
    });
  });

  group('SessaoService — estado da sessão', () {
    late SessaoService sessao;

    setUp(() {
      sessao = SessaoService();
    });

    tearDown(Get.reset);

    test('começa sem sessão ativa', () {
      expect(sessao.autenticado, isFalse);
      expect(sessao.usuario.value, isNull);
    });

    test('salvar registra token, refresh token e perfil em memória', () async {
      await sessao.salvar(
        token: 'abc',
        refreshToken: 'def',
        usuario: UsuarioModel(
          id: 1,
          nome: 'Coordenador',
          email: 'admin@admin.com',
          role: 'admin',
        ),
      );
      expect(sessao.autenticado, isTrue);
      expect(sessao.token.value, 'abc');
      expect(sessao.refreshToken.value, 'def');
      expect(sessao.usuario.value!.role, 'admin');
    });

    test('token sem perfil não considera a sessão válida', () {
      sessao.token.value = 'orfao';
      expect(sessao.autenticado, isFalse);
    });

    test('limpar encerra a sessão (RF04)', () async {
      await sessao.salvar(
        token: 'abc',
        refreshToken: 'def',
        usuario: UsuarioModel(
          nome: 'Coord',
          email: 'a@b.com',
          role: 'admin',
        ),
      );
      await sessao.limpar();
      expect(sessao.autenticado, isFalse);
      expect(sessao.token.value, isEmpty);
      expect(sessao.refreshToken.value, isEmpty);
    });
  });

  group('Roteamento por role (RF01)', () {
    setUp(() {
      Get.put(SessaoService());
    });

    tearDown(Get.reset);

    test('admin é enviado ao painel administrativo', () {
      final sessao = Get.find<SessaoService>();
      sessao.usuario.value =
          UsuarioModel(nome: 'Coord', email: 'a@b.com', role: 'admin');
      expect(rotaPorSessao(sessao), Rotas.homeAdmin);
    });

    test('professor é enviado ao painel do docente', () {
      final sessao = Get.find<SessaoService>();
      sessao.usuario.value =
          UsuarioModel(nome: 'Prof', email: 'a@b.com', role: 'professor');
      expect(rotaPorSessao(sessao), Rotas.homeProfessor);
    });

    test('perfil desconhecido cai no painel do docente (menor privilégio)', () {
      final sessao = Get.find<SessaoService>();
      sessao.usuario.value =
          UsuarioModel(nome: 'X', email: 'a@b.com', role: 'outro');
      expect(rotaPorSessao(sessao), Rotas.homeProfessor);
    });
  });

  group('Widgets reutilizáveis', () {
    testWidgets('MensagemErro exibe o texto recebido', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: MensagemErro.erro('Falha de rede')),
        ),
      );
      expect(find.text('Falha de rede'), findsOneWidget);
    });

    testWidgets('EstadoVazio exibe título e descrição', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: Tema.claro,
          home: const Scaffold(
            body: EstadoVazio(
              titulo: 'Nenhum patrimônio',
              descricao: 'Você ainda não tem bens atribuídos.',
            ),
          ),
        ),
      );
      expect(find.text('Nenhum patrimônio'), findsOneWidget);
      expect(find.text('Você ainda não tem bens atribuídos.'), findsOneWidget);
    });
  });
}
