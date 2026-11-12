import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'config/router.dart';
import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/bajas_pendientes_provider.dart';
import 'providers/detalle_solicitud_provider.dart';
import 'providers/notificacion_provider.dart';
import 'providers/panel_provider.dart';
import 'providers/solicitud_provider.dart';
import 'services/api_client.dart';
import 'services/config_service.dart';
import 'widgets/inactividad_listener.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ConfigService.instance.inicializar();
  await ApiClient.instance.inicializar();
  runApp(const XabalGestionaApp());
}

/// Raíz de la aplicación XABAL Gestiona.
class XabalGestionaApp extends StatefulWidget {
  const XabalGestionaApp({super.key});

  @override
  State<XabalGestionaApp> createState() => _XabalGestionaAppState();
}

class _XabalGestionaAppState extends State<XabalGestionaApp> {
  late final AuthProvider _auth;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _auth = AuthProvider();
    _router = crearRouter(_auth);
    _auth.restaurarSesion();
  }

  @override
  void dispose() {
    _router.dispose();
    _auth.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: _auth),
        ChangeNotifierProvider<PanelProvider>(create: (_) => PanelProvider()),
        ChangeNotifierProvider<NotificacionProvider>(
          create: (_) => NotificacionProvider(),
        ),
        ChangeNotifierProvider<SolicitudProvider>(
          create: (_) => SolicitudProvider(),
        ),
        ChangeNotifierProvider<BajasPendientesProvider>(
          create: (_) => BajasPendientesProvider(),
        ),
        ChangeNotifierProvider<DetalleSolicitudProvider>(
          create: (_) => DetalleSolicitudProvider(),
        ),
      ],
      child: InactividadListener(
        child: MaterialApp.router(
          title: 'XABAL Gestiona',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          routerConfig: _router,
        ),
      ),
    );
  }
}
