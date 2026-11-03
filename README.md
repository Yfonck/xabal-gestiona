# XABAL GESTIONA — App Móvil

App Flutter (Android) para la gestión de procesos de baja de personal del sistema
**XABAL GESTIONA**: solicitudes, estados, confirmaciones por área y notificaciones.

## Stack

| Capa | Tecnología |
|------|------------|
| Frontend | Flutter (Dart), Provider (`ChangeNotifier`), Dio, go_router |
| Backend | Django 5.2 + DRF, JWT (simplejwt), PostgreSQL |
| Autenticación | JWT — `Authorization: Bearer <token>` |

## Estructura

```
lib/
├── config/      # Rutas, tema, configuración de API
├── models/      # Modelos de dominio (SolicitudBaja, EstadoSolicitud, ...)
├── services/    # ApiClient (Dio) y servicios por recurso
├── providers/   # Estado compartido (ChangeNotifier)
├── screens/     # Pantallas por HU
└── widgets/     # Componentes reutilizables
```

Capas estrictas: `screens/` → `providers/` → `services/` → `models/`.
Ninguna pantalla llama a Dio directamente; todo pasa por `ApiClient`.

## Requisitos

- Flutter 3.44+ / Dart 3.12+
- Android SDK (compileSdk 36)
- Backend XABAL GESTIONA accesible en red

## Ejecutar

```bash
flutter pub get

# Emulador Android (backend en el host)
flutter run -d emulator-5554

# Dispositivo físico: apuntar a la IP de la PC
flutter run --dart-define=API_BASE_URL=http://192.168.1.20:8000/api/
```

Sin `--dart-define` se usa `10.0.2.2` en Android y `127.0.0.1` en escritorio
(`lib/config/api_config.dart`).

## Compilar APK

```bash
flutter build apk --debug --dart-define=API_BASE_URL=http://192.168.1.20:8000/api/
```

Salida: `build/app/outputs/flutter-apk/app-debug.apk`

## Calidad

```bash
flutter analyze
flutter test
```

## Documentación

- `docs/arquitectura.md` — decisiones de arquitectura
- `docs/convenciones.md` — convenciones de código y UI
- `docs/api-endpoints.md` — contrato real del backend
- `docs/base-datos.md` — conexión PostgreSQL de desarrollo
- `docs/historias/` — historias de usuario (HU)

## Backend en desarrollo

El servidor debe escuchar en `0.0.0.0:8000` y permitir la IP del equipo cliente:

```powershell
$env:ALLOWED_HOSTS="localhost,127.0.0.1,0.0.0.0,10.0.2.2,192.168.1.20"
.\.venv\Scripts\python.exe manage.py runserver 0.0.0.0:8000
```

## Estado

| HU | Descripción | Estado |
|----|-------------|--------|
| HU02 | Panel principal | Implementada |
| HU03 | Lista de solicitudes | Implementada |
| HU04 | Búsqueda de personas | Implementada |
| HU05 | Bajas pendientes | Implementada |
| HU06 | Detalle de solicitud | Implementada |
| HU07–HU10 | Flujo de cierre / notificaciones | Parcial |

> HU09 (editar/eliminar solicitudes) está diferida: el backend no expone
> `PATCH` ni `DELETE` para bajas.
