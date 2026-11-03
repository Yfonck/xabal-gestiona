# HU10 — Listar notificaciones

## Historia
**Como** administrador, **quiero** ver las notificaciones, **para** estar al tanto de los cambios.

## Rol
Administrador

## Prioridad
Media

## Criterios de Aceptación
1. Ícono de campana en el AppBar con un badge de conteo (si hay no leídas).
2. Al hacer clic, se abre el "Centro de notificaciones".
3. Muestra emisor, mensaje y fecha.
4. Menú de acciones por notificación: "Marcar como leído" y "Eliminar" (usa el mismo diálogo de HU09).

## Diseño Figma
- `docs/figma/screens/HU10-notificaciones.png`

## Notas de implementación
- Endpoint: Pendiente de confirmar en Swagger (usualmente `/api/notificaciones/`).