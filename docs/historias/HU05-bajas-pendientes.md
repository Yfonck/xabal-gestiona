# HU05 — Visualizar Bajas Pendientes por Área

## Historia
**Como** administrador, **quiero** ver un resumen visual de las bajas pendientes agrupadas por área, **para** priorizar el trabajo.

## Rol
Administrador

## Prioridad
Alta

## Criterios de Aceptación
1. Pantalla con título "Bajas pendientes" y filtros superiores (Área).
2. Tarjeta principal con el nombre del área y un gráfico circular (Donut Chart) mostrando proporciones (Iniciada, En Trámite, Finalizada).
3. El total de "Bajas pendientes" en texto grande debajo del gráfico.
4. Listado de empleados pendientes (Foto, Solicitante, Acciones).
5. Los filtros y el listado se actualizan dinámicamente.

## Diseño Figma
- `docs/figma/screens/HU05-bajas-pendientes.png`

## Notas de implementación
- Usar el paquete `fl_chart` para el gráfico de dona.
- Endpoint: `GET /api/bajas/?estado=pendiente` (verificar query params en Swagger).