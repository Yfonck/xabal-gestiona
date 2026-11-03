0# HU04 — Buscar persona

## Historia
**Como** administrador, **quiero** buscar una persona determinada dentro del sistema, **para** consultar su información o gestionar su baja.

## Rol
Administrador

## Prioridad
Media

## Criterios de Aceptación
1. Campo de búsqueda visible con placeholder "Nombre, Apellidos, CI, Solapín".
2. Al ingresar un término (con debounce de 300ms), muestra una lista paginada de resultados.
3. Cada resultado muestra foto, nombre completo, CI y acciones ("Ver detalles" y "Modificar").
4. Botón de filtro avanzado para seleccionar el criterio de búsqueda.

## Diseño Figma
- `docs/figma/screens/HU04-buscar-persona.png`

## Notas de implementación
- Endpoint: `GET /api/personas/?search=<término>`
- Crear widget `SearchableList<T>` reutilizable.