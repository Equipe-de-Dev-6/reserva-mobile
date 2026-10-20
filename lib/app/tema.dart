import 'package:flutter/material.dart';

/// Identidade visual do aplicativo.
///
/// Centralizar as cores e os estilos aqui evita "n├║meros m├ígicos"
/// espalhados pelas Views e garante consist├¬ncia entre telas.
class Tema {
  Tema._();

  static const Color azulPrimario = Color(0xFF1B4DB1);
  static const Color azulEscuro = Color(0xFF0F2E6B);
  static const Color fundo = Color(0xFFF4F6FB);
  static const Color sucesso = Color(0xFF1B8A5A);
  static const Color alerta = Color(0xFFD9822B);
  static const Color perigo = Color(0xFFC0392B);

  static ThemeData get claro {
    final esquema = ColorScheme.fromSeed(
      seedColor: azulPrimario,
      primary: azulPrimario,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: esquema,
      // A Roboto vem empacotada em `assets/fonts/` (ver `pubspec.yaml`).
      // Declarar a família aqui garante a mesma tipografia em todas as
      // plataformas — e faz o app bater com os prints do README.
      fontFamily: 'Roboto',
      scaffoldBackgroundColor: fundo,
      appBarTheme: const AppBarTheme(
        backgroundColor: azulPrimario,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        // O `fontFamily` precisa ser declarado aqui tambem: um
        // `TextStyle` montado a mao **nao** herda a familia do tema, e
        // o titulo da AppBar sairia com a fonte padrao do sistema.
        titleTextStyle: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDDE3EE)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDDE3EE)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: azulPrimario, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: perigo),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: perigo, width: 1.6),
        ),
        errorStyle: const TextStyle(color: perigo, fontSize: 12.5),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE8EDF6)),
        ),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(fontWeight: FontWeight.w700, fontSize: 22),
        titleMedium: TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
        bodyMedium: TextStyle(fontSize: 15, height: 1.45),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
