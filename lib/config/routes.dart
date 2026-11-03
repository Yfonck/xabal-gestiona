import 'package:flutter/widgets.dart';

/// Rutas de la aplicación.
///
/// Se centralizan aquí para evitar cadenas mágicas en las pantallas.
abstract final class AppRoutes {
  static const String inicio = '/';
  static const String login = '/login';
  static const String panel = '/panel';
  static const String solicitudes = '/solicitudes';
  static const String crearSolicitud = '/solicitudes/crear';
  static String detalleSolicitud(String id) => '/solicitudes/$id';
  static const String bajasPendientes = '/bajas-pendientes';
  static const String personas = '/personas';
  static const String notificaciones = '/notificaciones';
}

/// Nombres de ruta (para `context.goNamed`).
abstract final class AppRouteNames {
  static const String inicio = 'inicio';
  static const String login = 'login';
  static const String panel = 'panel';
  static const String solicitudes = 'solicitudes';
  static const String crearSolicitud = 'crearSolicitud';
  static const String detalleSolicitud = 'detalleSolicitud';
  static const String bajasPendientes = 'bajasPendientes';
  static const String personas = 'personas';
  static const String notificaciones = 'notificaciones';
}

/// Clave del `Navigator` raíz, necesaria para navegar desde providers.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
