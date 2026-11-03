# HU02 — Acceder al panel de administración

## Historia
**Como** administrador, **quiero** acceder al panel de administración, **para** visualizar y gestionar la información del sistema.

## Rol
Administrador

## Prioridad
Alta

## Criterios de Aceptación
1. Se muestra el nombre del sistema ("XABAL Gestiona") y el perfil del usuario autenticado.
2. El panel muestra 6 tarjetas indicadoras con los totales de:
   - Solicitudes de baja
   - Bajas pendientes
   - Finalizaciones de baja
   - Tipos y causas de baja
   - Notificaciones generadas
3. Los filtros incluyen al menos: Área (Dirección de Informatización / Tecnologías) y un botón de filtro avanzado.
4. El usuario puede acceder a las diferentes secciones desde este panel.

## Diseño Figma
- `docs/figma/screens/HU02-panel.png`

## Notas de implementación
- Endpoint: `GET /api/gestiona/` (verificar en Swagger).
- Crear un widget reutilizable `IndicadorCard` que reciba título, número, ícono y color.
- Usar un `GridView` de 2 columnas para el layout.