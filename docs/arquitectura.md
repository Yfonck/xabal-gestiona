# Arquitectura del Proyecto: XABAL GESTIONA Móvil

## Visión general

App Flutter (Android) que consume el backend Django + DRF del sistema XABAL GESTIONA.
Funcionalidad principal: gestión de procesos de baja de personal (solicitudes, estados, notificaciones).

## Estructura de directorios Flutter
lib/
├── config/
│ ├── api_config.dart # URL base, timeouts
│ ├── theme.dart # Colores XABAL, tipografía
│ └── routes.dart # Definición de rutas (go_router)
├── models/ # Modelos de dominio + json_serializable
│ ├── persona.dart
│ ├── solicitud_baja.dart
│ ├── estado_solicitud.dart # Enum: 1=Iniciada, 2=En Trámite, 3=Finalizada, 4=Baja
│ ├── tipo_baja.dart
│ ├── causa_baja.dart
│ └── notificacion.dart
├── services/ # Capa de llamadas HTTP
│ ├── api_client.dart # Dio + interceptores JWT
│ ├── auth_service.dart # /api/auth/
│ ├── persona_service.dart # /api/personas/
│ ├── baja_service.dart # /api/bajas/
│ └── notificacion_service.dart
├── providers/ # ChangeNotifier
│ ├── auth_provider.dart
│ ├── solicitud_provider.dart
│ └── notificacion_provider.dart
├── screens/ # Pantallas
│ ├── auth/login_screen.dart
│ ├── dashboard/panel_screen.dart
│ ├── solicitudes/
│ │ ├── lista_screen.dart
│ │ ├── crear_screen.dart
│ │ └── detalle_screen.dart
│ ├── personas/buscar_screen.dart
│ └── notificaciones/lista_screen.dart
├── widgets/ # Widgets reutilizables
│ ├── indicador_card.dart
│ ├── solicitud_card.dart
│ └── estado_badge.dart
└── utils/ # Validadores, constantes

text

## Decisiones arquitectónicas clave

| Decisión | Elección | Razón |
|----------|----------|-------|
| Gestión de estado | Provider + ChangeNotifier | Sencillo y directo, suficiente para el tamaño del proyecto |
| HTTP | Dio + interceptores | Manejo unificado de JWT y refresco 401 |
| Almacenamiento seguro | flutter_secure_storage | JWT no debe almacenarse en SharedPreferences |
| Modelos | json_serializable | Reduce el código repetitivo de serialización manual |
| Navegación | go_router | Gestión declarativa de rutas, facilita redirecciones post-login |

## Capa de integración con el backend

Todas las solicitudes pasan por `ApiClient`:
1. Adjuntar automáticamente `Authorization: Bearer <access_token>`
2. Al recibir 401, usar refresh_token para renovar
3. Si el refresco falla, limpiar tokens y notificar a AuthProvider para redirigir al login