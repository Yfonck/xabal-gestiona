import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../screens/bajas_pendientes/bajas_pendientes_screen.dart';
import '../screens/login/login_screen.dart';
import '../screens/notificaciones/notificaciones_screen.dart';
import '../screens/panel/panel_screen.dart';
import '../screens/personas/personas_screen.dart';
import '../screens/solicitudes/detalle_solicitud_screen.dart';
import '../screens/solicitudes/solicitudes_screen.dart';
import '../screens/splash/splash_screen.dart';
import 'routes.dart';

/// Construye el router de la aplicación con el guard de autenticación.
///
/// - Mientras se restaura la sesión se muestra el splash.
/// - Sin sesión solo es accesible el login.
/// - Con sesión, el login y el splash redirigen al panel.
GoRouter crearRouter(AuthProvider auth) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.inicio,
    refreshListenable: auth,
    redirect: (context, state) {
      final ubicacion = state.matchedLocation;
      final enLogin = ubicacion == AppRoutes.login;
      final enSplash = ubicacion == AppRoutes.inicio;

      switch (auth.estado) {
        case EstadoAuth.inicializando:
          return enSplash ? null : AppRoutes.inicio;
        case EstadoAuth.noAutenticado:
          return enLogin ? null : AppRoutes.login;
        case EstadoAuth.autenticado:
          return (enLogin || enSplash) ? AppRoutes.panel : null;
      }
    },
    routes: [
      GoRoute(
        path: AppRoutes.inicio,
        name: AppRouteNames.inicio,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: AppRouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.panel,
        name: AppRouteNames.panel,
        builder: (context, state) => const PanelScreen(),
      ),
      GoRoute(
        path: AppRoutes.solicitudes,
        name: AppRouteNames.solicitudes,
        builder: (context, state) => const SolicitudesScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.solicitudes}/:id',
        name: AppRouteNames.detalleSolicitud,
        builder: (context, state) => DetalleSolicitudScreen(
          idSolicitud: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
        ),
      ),
      GoRoute(
        path: AppRoutes.bajasPendientes,
        name: AppRouteNames.bajasPendientes,
        builder: (context, state) => const BajasPendientesScreen(),
      ),
      GoRoute(
        path: AppRoutes.personas,
        name: AppRouteNames.personas,
        builder: (context, state) => const PersonasScreen(),
      ),
      GoRoute(
        path: AppRoutes.notificaciones,
        name: AppRouteNames.notificaciones,
        builder: (context, state) => const NotificacionesScreen(),
      ),
    ],
  );
}
