# HU06 — Ver detalles de la solicitud

## Historia
**Como** administrador, **quiero** visualizar todos los detalles de una solicitud de baja, **para** conocer su estado y la información de las áreas involucradas.

## Rol
Administrador

## Prioridad
Alta

## Criterios de Aceptación
1. Secciones "Solicitante" y "Responsable" con foto, categoría, nombre, CI, usuario, solapín, área, responsabilidad y fecha.
2. Detalles de la solicitud: Estado actual (con color), Causa, Tipo, Fecha de creación y Fecha de baja.
3. Sección "Áreas involucradas": listado con estado y fecha de cada área.
4. Botones de acción rápida: Editar (abre modal de HU09) y Eliminar (abre diálogo).

## Diseño Figma
- `docs/figma/screens/HU06-detalle-solicitud.png`

## Notas de implementación
- Endpoint: `GET /api/bajas/{id}/`
- Widget `EstadoBadge` para mostrar el estado con el color del enum `EstadoSolicitud`.