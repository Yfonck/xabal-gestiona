# Convenciones de Código y UI

## Convenciones de nomenclatura

| Tipo | Convención | Ejemplo |
|------|------------|---------|
| Clases de dominio | PascalCase, español | `SolicitudBaja`, `EstadoSolicitud` |
| Clases técnicas | PascalCase, inglés | `ApiClient`, `AuthProvider` |
| Variables/métodos | camelCase, español (dominio) | `cargarSolicitudes()`, `estadoActual` |
| Constantes | UPPER_SNAKE_CASE | `API_BASE_URL`, `TIMEOUT_SECONDS` |
| Archivos | snake_case | `solicitud_baja.dart`, `auth_provider.dart` |

## Reglas de código Flutter

1. **Usar `const`**: Siempre que sea posible, usar constructores `const` para reducir reconstrucciones.
2. **Separación de capas**: `screens/` no llama directamente a `services/`, debe pasar por `providers/`.
3. **Manejo de errores**: Todos los métodos de Provider capturan excepciones y establecen `errorMessage`, la UI lo muestra a través de SnackBar o widget de error.
4. **Estados de carga**: Toda pantalla que obtiene datos de forma asíncrona debe manejar tres estados: loading, error, data.
5. **Nunca hardcodear URLs**: Todas las URL base provienen de `config/api_config.dart`.

## Convenciones de UI

| Elemento | Regla |
|----------|-------|
| Color principal | Rojo XABAL `#C8102E` |
| Color de fondo | Blanco `#FFFFFF` |
| Tarjetas | `Card` + `elevation: 0`, borde sutil `Border.all(color: Colors.grey.shade200)` |
| Badge de estado | Usar color de `EstadoSolicitud.color` (Iniciada=azul, En Trámite=naranja, Finalizada=verde, Baja=rojo) |
| Botones | `ElevatedButton` con `minimumSize: Size(double.infinity, 48)` |
| Fuente | Tamaño predeterminado del sistema, títulos con `fontWeight: FontWeight.w600` |

## Reglas específicas de OpenCode

- No usar el paquete `http`, usar siempre `Dio` a través de `ApiClient`.
- No modificar `pubspec.yaml` sin confirmación.
- Antes de crear una nueva pantalla, verificar si ya existe un Widget similar en `widgets/`.