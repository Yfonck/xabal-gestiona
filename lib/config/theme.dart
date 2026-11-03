import 'package:flutter/material.dart';

/// Paleta corporativa de XABAL Gestiona.
///
/// Los valores provienen de la guía visual del producto (capturas de Figma).
/// Cualquier color nuevo debe declararse aquí y no dentro de las pantallas o
/// widgets, para mantener una única fuente de verdad.
abstract final class AppPalette {
  // Marca
  static const Color primary = Color(0xFFF24E4E); // Rojo principal / CTA
  static const Color cta = Color(
    0xFFEF4444,
  ); // Rojo del botón de acceso (login)
  static const Color secondary = Color(0xFF2A3B68); // Azul corporativo / logo
  static const Color tertiary = Color(0xFF5263FF); // Azul interactivo
  static const Color warning = Color(0xFFF1A80A); // Acciones de cancelación
  static const Color success = Color(0xFF2ECC71); // Confirmaciones
  static const Color error = Color(0xFFE53935); // Errores de validación

  // Superficies
  static const Color surface = Color(0xFFFFFFFF);
  static const Color inputFill = Color(0xFFF0F0F0);
  static const Color outline = Color(0xFFE4E7EB);
  static const Color outlineSoft = Color(0xFFF2F4F7);
  static const Color scrim = Color(0xFF9EA6B2); // Fondo traslúcido de modales

  // Texto
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF5B6472);

  // Derivados
  static const Color primarySoft = Color(0xFFFDE9E9);
  static const Color primaryDark = Color(0xFFD13B3B);
  static const Color secondarySoft = Color(0xFFE7EAF2);
  static const Color warningSoft = Color(0xFFFDF3DB);
  static const Color successSoft = Color(0xFFE6F9EF);
  static const Color errorSoft = Color(0xFFFDEAEA);
}

/// Colores semánticos que `ColorScheme` no cubre (éxito y advertencia).
///
/// Se exponen como [ThemeExtension] para que estén disponibles en cualquier
/// widget mediante `Theme.of(context).extension<AppColors>()!`.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.warning,
    required this.onWarning,
    required this.warningContainer,
    required this.success,
    required this.onSuccess,
    required this.successContainer,
    required this.scrim,
  });

  final Color warning;
  final Color onWarning;
  final Color warningContainer;
  final Color success;
  final Color onSuccess;
  final Color successContainer;
  final Color scrim;

  static const AppColors light = AppColors(
    warning: AppPalette.warning,
    onWarning: Color(0xFF3D2A00),
    warningContainer: AppPalette.warningSoft,
    success: AppPalette.success,
    onSuccess: Color(0xFF0B3B22),
    successContainer: AppPalette.successSoft,
    scrim: AppPalette.scrim,
  );

  @override
  AppColors copyWith({
    Color? warning,
    Color? onWarning,
    Color? warningContainer,
    Color? success,
    Color? onSuccess,
    Color? successContainer,
    Color? scrim,
  }) {
    return AppColors(
      warning: warning ?? this.warning,
      onWarning: onWarning ?? this.onWarning,
      warningContainer: warningContainer ?? this.warningContainer,
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      successContainer: successContainer ?? this.successContainer,
      scrim: scrim ?? this.scrim,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      warning: Color.lerp(warning, other.warning, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      warningContainer: Color.lerp(
        warningContainer,
        other.warningContainer,
        t,
      )!,
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      successContainer: Color.lerp(
        successContainer,
        other.successContainer,
        t,
      )!,
      scrim: Color.lerp(scrim, other.scrim, t)!,
    );
  }
}

/// Acceso rápido a los colores semánticos desde cualquier `BuildContext`.
extension AppColorsX on BuildContext {
  AppColors get appColors => Theme.of(this).extension<AppColors>()!;
}

/// Tema único de la aplicación (solo modo claro).
abstract final class AppTheme {
  /// Radio usado en tarjetas, inputs y modales según el diseño.
  static const double radiusMd = 12;
  static const double radiusLg = 16;

  static ThemeData get light {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppPalette.primary,
      onPrimary: Colors.white,
      primaryContainer: AppPalette.primarySoft,
      onPrimaryContainer: AppPalette.primaryDark,
      secondary: AppPalette.secondary,
      onSecondary: Colors.white,
      secondaryContainer: AppPalette.secondarySoft,
      onSecondaryContainer: AppPalette.secondary,
      tertiary: AppPalette.tertiary,
      onTertiary: Colors.white,
      tertiaryContainer: Color(0xFFE8EAFF),
      onTertiaryContainer: AppPalette.tertiary,
      error: AppPalette.error,
      onError: Colors.white,
      errorContainer: AppPalette.errorSoft,
      onErrorContainer: AppPalette.error,
      surface: AppPalette.surface,
      onSurface: AppPalette.textPrimary,
      onSurfaceVariant: AppPalette.textSecondary,
      surfaceContainerHighest: AppPalette.inputFill,
      outline: AppPalette.outline,
      outlineVariant: AppPalette.outlineSoft,
      shadow: Color(0xFF1A1A1A),
      scrim: AppPalette.scrim,
      inverseSurface: AppPalette.secondary,
      onInverseSurface: Colors.white,
      inversePrimary: AppPalette.primarySoft,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppPalette.surface,
      splashFactory: InkSparkle.splashFactory,
      // TODO: Validar con PO si se debe incluir el asset de la fuente Inter.
      // Mientras no exista el .ttf en el proyecto se usa la fuente del sistema.
    );

    return base.copyWith(
      extensions: const <ThemeExtension<dynamic>>[AppColors.light],
      appBarTheme: const AppBarTheme(
        backgroundColor: AppPalette.surface,
        foregroundColor: AppPalette.secondary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppPalette.secondary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: AppPalette.secondary),
      ),
      cardTheme: const CardThemeData(
        color: AppPalette.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(radiusLg)),
          side: BorderSide(color: AppPalette.outline),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppPalette.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppPalette.outline,
          disabledForegroundColor: AppPalette.textSecondary,
          minimumSize: const Size(double.infinity, 48),
          elevation: 0,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(radiusMd)),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppPalette.tertiary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 48),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(radiusMd)),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppPalette.secondary,
          minimumSize: const Size(double.infinity, 48),
          side: const BorderSide(color: AppPalette.outline),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(radiusMd)),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppPalette.tertiary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppPalette.tertiary,
        foregroundColor: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppPalette.inputFill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        hintStyle: const TextStyle(color: AppPalette.textSecondary),
        labelStyle: const TextStyle(color: AppPalette.textSecondary),
        prefixIconColor: AppPalette.textSecondary,
        suffixIconColor: AppPalette.textSecondary,
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(radiusMd)),
          borderSide: BorderSide(color: AppPalette.outline),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(radiusMd)),
          borderSide: BorderSide(color: AppPalette.outline),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(radiusMd)),
          borderSide: BorderSide(color: AppPalette.tertiary, width: 1.5),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(radiusMd)),
          borderSide: BorderSide(color: AppPalette.error),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(radiusMd)),
          borderSide: BorderSide(color: AppPalette.error, width: 1.5),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.white
              : Colors.white,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppPalette.tertiary
              : AppPalette.outline,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppPalette.tertiary
              : AppPalette.outline,
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppPalette.tertiary,
        linearTrackColor: AppPalette.outlineSoft,
      ),
      dividerTheme: const DividerThemeData(
        color: AppPalette.outline,
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppPalette.inputFill,
        selectedColor: AppPalette.primarySoft,
        side: const BorderSide(color: AppPalette.outline),
        labelStyle: const TextStyle(color: AppPalette.textPrimary),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(24)),
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: AppPalette.surface,
        surfaceTintColor: Colors.transparent,
        barrierColor: Color(0x999EA6B2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(radiusLg)),
        ),
        titleTextStyle: TextStyle(
          color: AppPalette.secondary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: TextStyle(
          color: AppPalette.textPrimary,
          fontSize: 14,
          height: 1.4,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppPalette.surface,
        surfaceTintColor: Colors.transparent,
        modalBarrierColor: Color(0x999EA6B2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radiusLg)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppPalette.secondary,
        contentTextStyle: const TextStyle(color: Colors.white),
        actionTextColor: AppPalette.warning,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(radiusMd)),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: AppPalette.secondary,
        textColor: AppPalette.textPrimary,
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppPalette.secondary,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppPalette.textPrimary,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppPalette.textPrimary,
        ),
        bodyLarge: TextStyle(fontSize: 16, color: AppPalette.textPrimary),
        bodyMedium: TextStyle(fontSize: 14, color: AppPalette.textPrimary),
        bodySmall: TextStyle(fontSize: 12, color: AppPalette.textSecondary),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }
}
