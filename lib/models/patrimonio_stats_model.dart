/// Indicadores do acervo escolar (RF05).
///
/// Corresponde ao schema `PatrimonioStatsResponse` do Swagger, devolvido
/// por `GET /admin/patrimonios/stats`.
///
/// O backend calcula tudo: o app não conta nada. Isso é deliberado — a
/// contagem no cliente repetiria a regra do servidor e poderia divergir
/// dela (por exemplo, um bem `baixado` que o cliente contaria como
/// "disponível" e o servidor não).
class PatrimonioStatsModel {
  const PatrimonioStatsModel({
    this.totalPatrimonios = 0,
    this.patrimoniosEmUso = 0,
    this.patrimoniosDisponiveis = 0,
    this.patrimoniosEmManutencao = 0,
    this.totalProfessores = 0,
    this.totalProfessoresComPatrimonios = 0,
    this.porCategoria = const {},
  });

  /// Total de bens do acervo.
  final int totalPatrimonios;

  /// Bens em uso — atribuídos a um docente (RN05).
  final int patrimoniosEmUso;

  /// Bens disponíveis no almoxarifado.
  final int patrimoniosDisponiveis;

  /// Bens em manutenção.
  final int patrimoniosEmManutencao;

  /// Docentes cadastrados na escola.
  final int totalProfessores;

  /// Docentes que já têm pelo menos um bem sob responsabilidade.
  final int totalProfessoresComPatrimonios;

  /// Distribuição por categoria: `{'Informática': 2, 'Audiovisual': 2}`.
  ///
  /// A chave é texto livre (o backend agrupa pelo valor exato gravado no
  /// cadastro), então a View não pode presumir um conjunto fixo.
  final Map<String, int> porCategoria;

  /// `true` quando a escola ainda não cadastrou nenhum bem.
  ///
  /// O dashboard usa isso para mostrar o estado vazio do RF05 em vez de
  /// um monte de zeros.
  bool get acervoVazio => totalPatrimonios == 0;

  /// Categorias ordenadas da maior para a menor — é a ordem em que um
  /// gestor lê "onde está concentrado o acervo".
  List<MapEntry<String, int>> get categoriasOrdenadas {
    final lista = porCategoria.entries.toList()
      ..sort((a, b) {
        final porTamanho = b.value.compareTo(a.value);
        // Empate: ordem alfabética, para o resultado ser estável entre
        // uma carga e outra (e testável).
        return porTamanho != 0 ? porTamanho : a.key.compareTo(b.key);
      });
    return lista;
  }

  /// Maior categoria — base da barra proporcional do dashboard.
  int get maiorCategoria => categoriasOrdenadas.isEmpty
      ? 0
      : categoriasOrdenadas.first.value;

  /// Percentual de participação de uma categoria no acervo.
  ///
  /// Devolve 0 quando o acervo está vazio (evita divisão por zero) e
  /// quando a categoria não existe.
  double percentualDe(String categoria) {
    final total = porCategoria[categoria];
    if (total == null || maiorCategoria == 0) return 0;
    return total / maiorCategoria;
  }

  factory PatrimonioStatsModel.fromJson(Map<String, dynamic> json) {
    final categorias = <String, int>{};
    final bruto = json['porCategoria'];
    if (bruto is Map) {
      bruto.forEach((chave, valor) {
        final quantidade = valor is num
            ? valor.toInt()
            : int.tryParse(valor?.toString() ?? '') ?? 0;
        categorias[chave.toString()] = quantidade;
      });
    }

    return PatrimonioStatsModel(
      totalPatrimonios: _int(json['totalPatrimonios']),
      patrimoniosEmUso: _int(json['patrimoniosEmUso']),
      patrimoniosDisponiveis: _int(json['patrimoniosDisponiveis']),
      patrimoniosEmManutencao: _int(json['patrimoniosEmManutencao']),
      totalProfessores: _int(json['totalProfessores']),
      totalProfessoresComPatrimonios:
          _int(json['totalProfessoresComPatrimonios']),
      porCategoria: categorias,
    );
  }

  static int _int(dynamic valor) {
    if (valor is int) return valor;
    if (valor is num) return valor.toInt();
    return int.tryParse(valor?.toString() ?? '') ?? 0;
  }
}
