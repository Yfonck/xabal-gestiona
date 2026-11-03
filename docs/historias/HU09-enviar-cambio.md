# HU09 — Enviar detalles del cambio y Editar/Eliminar

## Historia
**Como** administrador, **quiero** enviar los detalles del cambio de solicitud, **para** que el director lo apruebe o rechace.

## Rol
Administrador

## Prioridad
Alta

## Criterios de Aceptación
1. **Editar:** Al presionar el ícono de editar, se abre el modal "Modificación de solicitud" con un campo de texto multilínea "Por favor comente la causa de cambio de solicitud" y botón "Enviar" (azul).
2. Al enviar, el estado pasa a "Pendiente en aprobación" y se muestra un `SnackBar` de éxito.
3. **Eliminar:** Al presionar el ícono de eliminar, se muestra un `AlertDialog` de advertencia ("¿Está seguro que desea eliminar este registro? Esta acción no se puede deshacer") con botones "Cancelar" y "Eliminar" (rojo).

## Diseño Figma
- Editar: `docs/figma/screens/HU09-editar-solicitud.png`
- Eliminar: `docs/figma/screens/HU09-confirmar-eliminar.png`

## Notas de implementación
- Editar: `PATCH /api/bajas/{id}/` con campo `comentario_cambio`.
- Eliminar: `DELETE /api/bajas/{id}/` (verificar si es borrado lógico o físico en Swagger).
- Usar `AlertDialog` nativo de Flutter para la confirmación.