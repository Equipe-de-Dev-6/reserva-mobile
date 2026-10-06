import 'package:flutter/material.dart';

/// Identidade visual do aplicativo.
///
/// Centralizar as cores e os estilos aqui evita "números mágicos"
/// espalhados pelas Views e garante consistência entre telas.
class Tema {
  Tema._();

  static const Color vermelhoPrimario = Color(0xFFC0392B);
  static const Color vermelhoEscuro = Color(0xFF962D1E);
  static const Color fundo = Color(0xFFFEF5F5);
  static const Color sucesso = Color(0xFF1B8A5A);
  static const Color alerta = Color(0xFFD9822B);
  static const Color perigo = Color(0xFFC0392B);

  static ThemeData get claro {
    final esquema = ColorScheme.fromSeed(
      seedColor: vermelhoPrimario,
      primary: vermelhoPrimario,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: esquema,
      scaffoldBackgroundColor: fundo,
      appBarTheme: const AppBarTheme(
        backgroundColor: vermelhoPrimario,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
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
          borderSide: const BorderSide(color: Color(0xFFE8D5D5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE8D5D5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: vermelhoPrimario, width: 1.6),
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
          side: const BorderSide(color: Color(0xFFE8D5D5)),
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
