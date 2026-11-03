# HU08 — Dar baja definitiva (Borrador inferido)

## ⚠️ Estado: BORRADOR
Inferido de RF.8.

## Historia
**Como** administrador, **quiero** cerrar definitivamente una solicitud, **para** completar el proceso.

## Criterios de Aceptación
1. Solo solicitudes "Finalizadas" pueden darse de baja.
2. Al dar de baja, el estado pasa a "Baja" (ID=4) y se registra la fecha.
3. Desaparece de los listados de pendientes.
4. Se pide confirmación antes de la acción irreversible.

## Notas de implementación
- Endpoint: `PATCH /api/bajas/{id}/` con `estado=4` y `fecha_baja`.