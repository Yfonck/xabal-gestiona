# Reglas del Proyecto: XABAL GESTIONA Móvil

## Contexto del proyecto

App Flutter (Android) que consume el backend Django + DRF del sistema XABAL GESTIONA.
Objetivo: gestionar procesos de baja de personal (solicitudes, estados, notificaciones).

## Stack tecnológico

- **Frontend**: Flutter (Dart), gestión de estado con Provider, HTTP con Dio
- **Backend**: Django 5.2 + DRF, JWT (simplejwt), PostgreSQL
- **Autenticación**: JWT con header `Authorization: Bearer <token>`

## Comandos frecuentes

```bash
# Flutter
flutter pub get
flutter run -d emulator-5554
flutter analyze
flutter test

# Backend (si trabajas en él)
python manage.py runserver 0.0.0.0:8000
python manage.py test tests.unit

### Estructura de archivos recomendada ###

APP XABAL/
├── AGENTS.md                          # Reglas globales del proyecto (el más importante)
├── opencode.json                      # Configuración de OpenCode (plugins, instrucciones externas)
├── .opencode/
│   ├── commands/                      # Comandos personalizados (/flutter-screen, /api-check, etc.)
│   │   ├── flutter-screen.md
│   │   ├── flutter-state.md
│   │   └── backend-endpoint.md
│   └── agents/                        # Subagentes especializados
│       ├── flutter-ui.md
│       └── django-api.md
├── docs/
│   ├── arquitectura.md                # Decisiones de arquitectura (referenciado desde AGENTS.md)
│   ├── convenciones.md                # Convenciones de código (referenciado desde AGENTS.md)
│   ├── base-datos.md
│   └── api-endpoints.md               # Resumen de endpoints del backend (referenciado desde AGENTS.md)
└── (código fuente Flutter y Django)

## Reglas de código

Idioma: nombres de variables, clases y funciones en español cuando representen conceptos del dominio (ej. SolicitudBaja, EstadoSolicitud, causaBaja). Términos técnicos universales (ej. ApiClient, AuthProvider) en inglés.

Arquitectura Flutter: separación estricta en capas: models/ → services/ → providers/ → screens/ → widgets/.

Manejo de estado: usar ChangeNotifier + Provider. No usar setState para estado compartido entre pantallas.

HTTP: todas las peticiones pasan por ApiClient (Dio con interceptores JWT). Nunca llamar a Dio directamente desde un Provider o Screen.

Seguridad: tokens JWT se almacenan exclusivamente con flutter_secure_storage. Nunca en SharedPreferences.

Estados de solicitud: usar el enum EstadoSolicitud (1=Iniciada, 2=En Trámite, 3=Finalizada, 4=Baja) definido en models/estado_solicitud.dart.

Paginación: todos los listados usan PaginatedResponse<T> y scroll infinito.

## Configuración Dinámica de URL (Desarrollo)

- La URL del backend (`baseUrl`) NO debe estar hardcodeada en el código.
- Debe existir un `ConfigService` (o similar) que lea la URL desde `SharedPreferences`.
- Si no hay URL guardada, se usa la por defecto: `http://10.0.2.2:8000/api/`.
- El `ApiClient` (Dio) debe obtener la URL desde este servicio antes de configurar su `BaseOptions`.

##Flujo de trabajo

Planificar primero: usa el agente Plan para analizar y proponer cambios antes de editar.

Una HU a la vez: implementa una historia de usuario completa (modelo + servicio + provider + pantalla + test) antes de pasar a la siguiente.

Validación obligatoria: después de cada cambio, ejecutar flutter analyze y corregir warnings antes de continuar.

No modificar el backend sin confirmación explícita.

## Flujo de Trabajo con Historias de Usuario (HU)

1. **Lectura obligatoria:** Antes de escribir cualquier línea de código para una tarea, lee el archivo `.md` correspondiente en `docs/historias/`.
2. **Fidelidad Visual:** Abre y analiza la imagen referenciada en la sección "Diseño Figma" de la HU.
3. **Cumplimiento:** Asegúrate de implementar TODOS los criterios de aceptación.
4. **Borradores:** Si la HU tiene la etiqueta "⚠️ Estado: BORRADOR", implementa solo lo mínimo necesario y deja comentarios `// TODO: Validar con PO`.