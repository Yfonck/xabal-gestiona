# Endpoints del Backend Gestiona (contrato real)

> Verificado contra el backend local `backend-gestiona-dev` y `/api/schema/`
> (drf-spectacular). Sustituye la versión anterior basada en supuestos.

## URL base

| Entorno | URL |
|---|---|
| Emulador Android | `http://10.0.2.2:8000/api/` |
| Dispositivo físico | `http://<IP_LAN>:8000/api/` |
| Host local | `http://127.0.0.1:8000/api/` |
| Swagger | `http://<host>:8000/api/docs/` |
| Esquema OpenAPI | `http://<host>:8000/api/schema/` |

En Flutter la URL se configura con:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.20:8000/api/
```

Sin `--dart-define` se usa `10.0.2.2` en Android y `127.0.0.1` en escritorio
(`lib/config/api_config.dart`).

El backend debe arrancar con `10.0.2.2` en `ALLOWED_HOSTS` para el emulador:

```powershell
$env:ALLOWED_HOSTS="localhost,127.0.0.1,0.0.0.0,10.0.2.2"
.\.venv\Scripts\python.exe manage.py runserver 0.0.0.0:8000
```

## Formato de respuesta

Éxito:

```json
{ "success": true, "data": { }, "meta": { } }
```

Error:

```json
{ "success": false, "error": { "code": "UNAUTHORIZED", "message": "Credenciales inválidas" } }
```

**Excepción:** el refresh de simplejwt (`/auth/refresh/`) responde sin sobre:
`{ "access": "...", "refresh": "..." }`.

## Autenticación

| Endpoint | Método | Descripción |
|---|---|---|
| `/api/auth/login/` | POST | `{username, password}` → `{user, access, refresh}` |
| `/api/auth/refresh/` | POST | `{refresh}` → `{access, refresh}` (rota y hace blacklist) |
| `/api/auth/me/` | GET | Datos del usuario autenticado |
| `/api/auth/logout/` | POST | `{refresh}`; idempotente, siempre 200 |

- El **dominio UCI no se envía**; es solo informativo en la UI.
- `user` incluye: `username`, `is_admin`, `is_directivo`, `permiso_rrhh`,
  `en_baja`, `foto_base64`, `id_persona`, nombres/apellidos, `carnet_identidad`,
  `id_estructura`, `nombre_estructura`, `nombre_responsabilidad`, `estructuras`.
- **Sesión única**: cada login invalida los tokens anteriores
  (`session_version`). Un `401` con sesión revocada obliga a volver al login.
- Rate limit del login: 5/min por IP (429 con `retry-after`).

## Personas

| Endpoint | Método | Descripción |
|---|---|---|
| `/api/personas/` | GET | Listado paginado; `?search=`, `?page=`, `?page_size=`, `?id_estructura=`, `?baja=` |
| `/api/personas/{id}/` | GET | Detalle de una persona |
| `/api/personas/filters/` | GET | `estructuras`, `roles`, `cargos`, `estados_baja` |

No existe creación ni edición de personas (`POST` → 405) ni `PATCH`.

## Bajas

| Endpoint | Método | Descripción |
|---|---|---|
| `/api/bajas/` | GET | Listado paginado con filtros |
| `/api/bajas/` | POST | Crear solicitud |
| `/api/bajas/{id}/` | GET | Detalle; `PUT` responde "no implementado"; **no hay PATCH ni DELETE** |
| `/api/bajas/pendientes/` | GET | Bajas en trámite (estado 2) |
| `/api/bajas/estadisticas/` | GET | Métricas del panel |
| `/api/bajas/filters/` | GET | `estados`, `tipos_baja`, `causas_baja`, `estructuras` (`{value,label}`) |
| `/api/bajas/tiene-pendientes/` | GET | Indicador para directivos |
| `/api/bajas/{id}/confirmar/` | POST | Confirmación de un área |
| `/api/bajas/{id}/cerrar/` | POST | Cierra la baja (estado 3 → 4) |
| `/api/bajas/{id}/cerrar-legacy/` | POST | Cierre desde estado 1 o 3 |
| `/api/bajas/{id}/cancelar/` | POST | Cancela la solicitud |
| `/api/bajas/{id}/areas-confirmacion/` | GET | Áreas y su estado de confirmación |
| `/api/bajas/{id}/pdf/` | GET | PDF de la solicitud |
| `/api/bajas/exportar-excel/` | GET | Exportación Excel |

### Crear solicitud

```json
{ "id_persona": "123", "id_tipo_baja": 1, "id_causa_baja": 2 }
```

La solicitud se crea directamente en estado **2 (En Trámite)**, no en 1.

### Paginación de listados

`data` contiene
`{count, page, page_size, total_pages, next, previous, results}`.
`next`/`previous` son query strings relativos (`?page=2&page_size=20`).

### Estadísticas

`GET /api/bajas/estadisticas/` devuelve `por_estado`, `por_tipo`, `por_causa`,
`total_solicitudes`, `personas_en_baja` y filtros por `fecha_desde`,
`fecha_hasta`, `id_estructura`.

## Notificaciones

| Endpoint | Método | Descripción |
|---|---|---|
| `/api/notificaciones/` | GET | Notificaciones del usuario (máx. 50, **sin paginación**) |
| `/api/notificaciones/{id}/leer/` | POST | Marcar como leída |
| `/api/notificaciones/{id}/` | DELETE | Eliminar una notificación |
| `/api/notificaciones/limpiar-todas/` | DELETE | Eliminar todas las del usuario |

Campos: `id`, `id_usuario`, `titulo`, `mensaje`, `leida`, `fecha_creacion`, `link`.

## Catálogos (solo administradores)

| Endpoint | Método |
|---|---|
| `/api/admin/tipos-baja/` | GET / POST |
| `/api/admin/tipos-baja/{id}/` | GET / PUT / PATCH / DELETE |
| `/api/admin/causas-baja/` | GET / POST |
| `/api/admin/causas-baja/{id}/` | GET / PUT / PATCH / DELETE |
| `/api/admin/areas-baja/` | GET / POST |
| `/api/admin/areas-baja/{id}/` | GET / PUT / PATCH / DELETE |
| `/api/admin/categorias-causas/` | GET |

Para el formulario de creación se usa `/api/bajas/filters/` (disponible para
cualquier usuario autenticado) en lugar de los catálogos de administración.

## Estados de solicitud

| ID | Nombre | Enum Flutter |
|---|---|---|
| 1 | Iniciada | `EstadoSolicitud.iniciada` |
| 2 | En Trámite | `EstadoSolicitud.enTramite` |
| 3 | Finalizada | `EstadoSolicitud.finalizada` |
| 4 | Baja | `EstadoSolicitud.baja` |
| 5 | Cancelada | `EstadoSolicitud.cancelada` |
| 6 | Expirada | `EstadoSolicitud.expirada` |

Los estados 5 y 6 existen en el backend aunque no estén en las HU originales.

## Pendientes conocidos

- **HU09 (editar/eliminar)** no tiene soporte backend: no existen `PATCH` ni
  `DELETE` para bajas. Diferida hasta que el backend los implemente.
- HU07/HU08 son borradores: se implementan con las transiciones reales
  (`confirmar`, `cerrar`, `cerrar-legacy`, `cancelar`).
- No existe relación tipo→causa; las causas se agrupan por categoría.
