# HU01 — Iniciar sesión

## Historia
**Como** usuario del sistema XABAL GESTIONA, **quiero** iniciar sesión con mis credenciales, **para** acceder a las funcionalidades según mi rol.

## Rol
Todos (Administrador, Gestor, Visitante)

## Prioridad
Alta

## Criterios de Aceptación
1. La pantalla principal muestra el formulario de inicio de sesión con:
   - Usuario (campo de texto obligatorio)
   - Contraseña (campo de texto con caracteres ocultos y obligatorio)
   - Dominio UCI (campo de texto predefinido con el valor `gestiona.uci.cu`, no editable).
2. El botón "Iniciar Sesión" está habilitado únicamente cuando todos los campos requeridos están completos.
3. Si las credenciales son incorrectas, muestra el mensaje: "Usuario o contraseña incorrectos. Intente nuevamente."
4. Si es correcto, guarda el token JWT de forma segura y redirige al panel principal.
5. La sesión se mantiene activa (manejo de refresh token) mientras el usuario no cierre sesión.

## Diseño Figma
- `docs/figma/screens/HU01-login.png`

## Notas de implementación
- Endpoint: `POST /api/auth/token/`
- Almacenar tokens con `flutter_secure_storage`.