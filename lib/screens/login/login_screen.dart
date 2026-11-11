import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_client.dart';
import '../../services/config_service.dart';
import '../../widgets/decoracion_superior.dart';
import '../../widgets/marca_xabal.dart';

/// HU01 — Pantalla de inicio de sesión.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usuarioCtrl = TextEditingController();
  final _claveCtrl = TextEditingController();
  final _dominioCtrl = TextEditingController();

  bool _ocultarClave = true;
  bool _puedeEnviar = false;

  @override
  void initState() {
    super.initState();
    _usuarioCtrl.addListener(_actualizarBoton);
    _claveCtrl.addListener(_actualizarBoton);
    _dominioCtrl.addListener(_actualizarBoton);
    _dominioCtrl.text = ConfigService.instance.obtenerUrl();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.sesionExpirada && mounted) {
        auth.reconocerSesionExpirada();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Su sesión finalizó. Inicie sesión nuevamente.'),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _usuarioCtrl.dispose();
    _claveCtrl.dispose();
    _dominioCtrl.dispose();
    super.dispose();
  }

  void _actualizarBoton() {
    final habilitado =
        _usuarioCtrl.text.trim().isNotEmpty &&
        _claveCtrl.text.isNotEmpty &&
        _dominioCtrl.text.trim().isNotEmpty;
    if (habilitado != _puedeEnviar) {
      setState(() => _puedeEnviar = habilitado);
    }
  }

  Future<void> _enviar() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final url = _dominioCtrl.text.trim();
    if (!Uri.parse(url).isAbsolute || !url.endsWith('/')) {
      _avisar('La URL del backend no es válida.');
      return;
    }

    try {
      await ConfigService.instance.guardarUrl(url);
      await ApiClient.instance.inicializar();
    } catch (_) {
      if (!mounted) return;
      _avisar('No se pudo guardar la configuración del servidor.');
      return;
    }

    if (!mounted) return;
    await context.read<AuthProvider>().iniciarSesion(
      usuario: _usuarioCtrl.text,
      contrasena: _claveCtrl.text,
    );
    // La redirección al panel la resuelve el router al cambiar el estado.
  }

  void _avisar(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensaje)));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppPalette.surface,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const DecoracionSuperior(altura: 190),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const MarcaXabal(),
                      const SizedBox(height: 48),
                      _Etiqueta('Usuario'),
                      const SizedBox(height: 8),
                      _CampoLogin(
                        controller: _usuarioCtrl,
                        hint: 'Ingrese su usuario',
                        icono: Icons.person_outline,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.username],
                        validator: (valor) {
                          if (valor == null || valor.trim().isEmpty) {
                            return 'El usuario es obligatorio';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      _Etiqueta('Contraseña'),
                      const SizedBox(height: 8),
                      _CampoLogin(
                        controller: _claveCtrl,
                        hint: 'Ingrese su contraseña',
                        icono: Icons.lock_outline,
                        obscureText: _ocultarClave,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        onSubmitted: (_) => _puedeEnviar ? _enviar() : null,
                        sufijo: IconButton(
                          tooltip: _ocultarClave
                              ? 'Mostrar contraseña'
                              : 'Ocultar contraseña',
                          icon: Icon(
                            _ocultarClave
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            size: 20,
                          ),
                          onPressed: () =>
                              setState(() => _ocultarClave = !_ocultarClave),
                        ),
                        validator: (valor) {
                          if (valor == null || valor.isEmpty) {
                            return 'La contraseña es obligatoria';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      _Etiqueta('Dominio'),
                      const SizedBox(height: 8),
                      _CampoLogin(
                        controller: _dominioCtrl,
                        hint: 'https://ejemplo.com/api/',
                        icono: Icons.language_outlined,
                        textInputAction: TextInputAction.done,
                        validator: (valor) {
                          if (valor == null || valor.trim().isEmpty) {
                            return 'El dominio es obligatorio';
                          }
                          try {
                            final uri = Uri.parse(valor.trim());
                            if (!uri.isAbsolute) {
                              return 'Ingrese una URL válida.';
                            }
                          } catch (_) {
                            return 'Ingrese una URL válida.';
                          }
                          return null;
                        },
                      ),
                      if (auth.errorMessage != null) ...[
                        const SizedBox(height: 20),
                        _MensajeError(mensaje: auth.errorMessage!),
                      ],
                      const SizedBox(height: 48),
                      ElevatedButton(
                        style: ButtonStyle(
                          backgroundColor: WidgetStateProperty.resolveWith(
                            (estados) => estados.contains(WidgetState.disabled)
                                ? AppPalette.outline
                                : AppPalette.cta,
                          ),
                          foregroundColor: WidgetStateProperty.resolveWith(
                            (estados) => estados.contains(WidgetState.disabled)
                                ? AppPalette.textSecondary
                                : Colors.white,
                          ),
                        ),
                        onPressed: (_puedeEnviar && !auth.cargando)
                            ? _enviar
                            : null,
                        child: auth.cargando
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text('Iniciar Sesión'),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          'Universidad de las Ciencias Informáticas.\n'
                          'XABAL. GESTIONA Todos los derechos reservados.\n'
                          'Producto desarrollado por: Dirección de Informatización.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Etiqueta extends StatelessWidget {
  const _Etiqueta(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: AppPalette.textPrimary,
      ),
    );
  }
}

class _CampoLogin extends StatelessWidget {
  const _CampoLogin({
    required this.controller,
    required this.hint,
    required this.icono,
    this.obscureText = false,
    this.sufijo,
    this.validator,
    this.textInputAction,
    this.autofillHints,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icono;
  final bool obscureText;
  final Widget? sufijo;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      textInputAction: textInputAction,
      autofillHints: autofillHints,
      onFieldSubmitted: onSubmitted,
      inputFormatters: [
        if (!obscureText) FilteringTextInputFormatter.deny(RegExp(r'\s')),
      ],
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icono, size: 20),
        suffixIcon: sufijo,
        // En el login los campos son blancos con borde gris.
        fillColor: AppPalette.surface,
      ),
    );
  }
}

class _MensajeError extends StatelessWidget {
  const _MensajeError({required this.mensaje});

  final String mensaje;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppPalette.errorSoft,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppPalette.error.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppPalette.error, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              mensaje,
              style: const TextStyle(
                color: AppPalette.error,
                fontSize: 13.5,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
