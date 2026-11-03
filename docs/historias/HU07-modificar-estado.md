# HU07 — Modificar estado de la solicitud (Borrador inferido)

## ⚠️ Estado: BORRADOR
Inferido de RF.7 y RF.13.

## Historia
**Como** administrador, **quiero** modificar el estado de una solicitud, **para** reflejar su avance.

## Criterios de Aceptación
1. Desde el detalle, un menú permite cambiar el estado (Iniciada, En Trámite, Finalizada, Baja).
2. Solo se permiten transiciones lógicas (ej. no volver de Finalizada a Iniciada).
3. Se registra fecha y usuario del cambio.
4. Se notifica al DRH.

## Notas de implementación
- Endpoint: `PATCH /api/bajas/{id}/` enviando el nuevo `estado`.