# HU03 — Crear solicitud de baja

## Historia
**Como** administrador, **quiero** crear una solicitud de baja, **para** iniciar el proceso de baja de un empleado.

## Rol
Administrador

## Prioridad
Alta

## Criterios de Aceptación
1. Desde la lista de solicitudes, hay un botón "Crear solicitud de baja".
2. Al presionarlo, se abre una ventana modal con una barra de progreso de 2 pasos:
   - **Paso 1:** Desplegable "Tipo de baja", desplegable "Causa de baja" (dependiente del tipo), un switch para "Estado activo" y botón "Siguiente".
   - **Paso 2:** Buscador de empleados (por nombre/CI) y botón "Guardar solicitud".
3. Al hacer clic en "Guardar", la solicitud se crea con estado "Iniciada" (ID=1).
4. Se cierra el modal, se recarga la lista y se muestra un mensaje de éxito (`HU03-guardar-exito.png`).
5. Solo se permiten empleados con estado "Activo".

## Diseño Figma
- Paso 1: `docs/figma/screens/HU03-crear-paso1.png`
- Paso 2: `docs/figma/screens/HU03-crear-paso2.png`
- Éxito: `docs/figma/screens/HU03-guardar-exito.png`

## Notas de implementación
- Endpoint: `POST /api/bajas/`
- Endpoint: `GET /api/personas/?search=...`
- Usar `showModalBottomSheet` o un `Dialog` de pantalla completa para el flujo.