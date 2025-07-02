import 'package:flutter/material.dart';

/// Tema personalizado para o sistema de sincronização
/// 
/// Esta classe define todas as cores, estilos de texto e configurações visuais
/// usadas pelos widgets de sincronização, garantindo independência do tema
/// principal da aplicação.
class SyncTheme {
  // ========== CORES PRINCIPAIS ==========
  
  /// Cor primária do sistema de sincronização
  final Color primary;
  
  /// Cor de sucesso
  final Color success;
  
  /// Cor de erro
  final Color error;
  
  /// Cor de aviso/warning
  final Color warning;
  
  /// Cor de texto secundário
  final Color textSecondary;
  
  /// Cor de texto primário
  final Color textPrimary;
  
  /// Cor de fundo
  final Color background;
  
  /// Cor de superfície
  final Color surface;
  
  // ========== ESTILOS DE TEXTO ==========
  
  /// Estilo para títulos
  final TextStyle titleStyle;
  
  /// Estilo para subtítulos
  final TextStyle subtitleStyle;
  
  /// Estilo para corpo de texto
  final TextStyle bodyStyle;
  
  /// Estilo para texto de botões
  final TextStyle buttonStyle;
  
  /// Estilo para texto pequeno/caption
  final TextStyle captionStyle;
  
  // ========== CONFIGURAÇÕES DE LAYOUT ==========
  
  /// Raio de borda padrão
  final double borderRadius;
  
  /// Espaçamento padrão
  final double spacing;
  
  /// Espaçamento pequeno
  final double spacingSmall;
  
  /// Espaçamento grande
  final double spacingLarge;
  
  const SyncTheme({
    required this.primary,
    required this.success,
    required this.error,
    required this.warning,
    required this.textSecondary,
    required this.textPrimary,
    required this.background,
    required this.surface,
    required this.titleStyle,
    required this.subtitleStyle,
    required this.bodyStyle,
    required this.buttonStyle,
    required this.captionStyle,
    this.borderRadius = 8.0,
    this.spacing = 16.0,
    this.spacingSmall = 8.0,
    this.spacingLarge = 24.0,
  });
  
  /// Tema padrão claro
  static const SyncTheme light = SyncTheme(
    primary: Color(0xFF2196F3), // Azul
    success: Color(0xFF4CAF50), // Verde
    error: Color(0xFFF44336), // Vermelho
    warning: Color(0xFFFF9800), // Laranja
    textSecondary: Color(0xFF757575), // Cinza
    textPrimary: Color(0xFF212121), // Preto
    background: Color(0xFFFFFFFF), // Branco
    surface: Color(0xFFF5F5F5), // Cinza claro
    titleStyle: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.bold,
      color: Color(0xFF212121),
    ),
    subtitleStyle: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: Color(0xFF212121),
    ),
    bodyStyle: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.normal,
      color: Color(0xFF212121),
    ),
    buttonStyle: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: Color(0xFFFFFFFF),
    ),
    captionStyle: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.normal,
      color: Color(0xFF757575),
    ),
  );
  
  /// Tema padrão escuro
  static const SyncTheme dark = SyncTheme(
    primary: Color(0xFF64B5F6), // Azul claro
    success: Color(0xFF81C784), // Verde claro
    error: Color(0xFFE57373), // Vermelho claro
    warning: Color(0xFFFFB74D), // Laranja claro
    textSecondary: Color(0xFFBDBDBD), // Cinza claro
    textPrimary: Color(0xFFFFFFFF), // Branco
    background: Color(0xFF121212), // Preto
    surface: Color(0xFF1E1E1E), // Cinza escuro
    titleStyle: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.bold,
      color: Color(0xFFFFFFFF),
    ),
    subtitleStyle: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: Color(0xFFFFFFFF),
    ),
    bodyStyle: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.normal,
      color: Color(0xFFFFFFFF),
    ),
    buttonStyle: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: Color(0xFF121212),
    ),
    captionStyle: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.normal,
      color: Color(0xFFBDBDBD),
    ),
  );
  
  /// Cria uma cópia do tema com valores alterados
  SyncTheme copyWith({
    Color? primary,
    Color? success,
    Color? error,
    Color? warning,
    Color? textSecondary,
    Color? textPrimary,
    Color? background,
    Color? surface,
    TextStyle? titleStyle,
    TextStyle? subtitleStyle,
    TextStyle? bodyStyle,
    TextStyle? buttonStyle,
    TextStyle? captionStyle,
    double? borderRadius,
    double? spacing,
    double? spacingSmall,
    double? spacingLarge,
  }) {
    return SyncTheme(
      primary: primary ?? this.primary,
      success: success ?? this.success,
      error: error ?? this.error,
      warning: warning ?? this.warning,
      textSecondary: textSecondary ?? this.textSecondary,
      textPrimary: textPrimary ?? this.textPrimary,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      titleStyle: titleStyle ?? this.titleStyle,
      subtitleStyle: subtitleStyle ?? this.subtitleStyle,
      bodyStyle: bodyStyle ?? this.bodyStyle,
      buttonStyle: buttonStyle ?? this.buttonStyle,
      captionStyle: captionStyle ?? this.captionStyle,
      borderRadius: borderRadius ?? this.borderRadius,
      spacing: spacing ?? this.spacing,
      spacingSmall: spacingSmall ?? this.spacingSmall,
      spacingLarge: spacingLarge ?? this.spacingLarge,
    );
  }
}

/// Provider para o tema do sync
/// 
/// Esta classe gerencia o tema atual e permite alterações dinâmicas
class SyncThemeProvider {
  static SyncTheme _currentTheme = SyncTheme.light;
  
  /// Tema atual
  static SyncTheme get current => _currentTheme;
  
  /// Define um novo tema
  static void setTheme(SyncTheme theme) {
    _currentTheme = theme;
  }
  
  /// Define o tema baseado no brilho
  static void setThemeByBrightness(Brightness brightness) {
    _currentTheme = brightness == Brightness.dark 
        ? SyncTheme.dark 
        : SyncTheme.light;
  }
}