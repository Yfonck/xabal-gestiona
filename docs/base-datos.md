# Base de Datos PostgreSQL

## Información de conexión (desarrollo)

| Propiedad | Valor |
|-----------|-------|
| Host | `10.11.2.217` |
| Puerto | `5432` |
| Usuario | `postgres` |
| Contraseña | `postgres` |
| Nombre de BD | `gestiona` (confirmar con `psql -l`) |

## Comandos de verificación

```bash
# Listar todas las bases de datos
PGPASSWORD=postgres psql -h 10.11.2.217 -U postgres -l

# Ver tablas de la BD de Gestiona
PGPASSWORD=postgres psql -h 10.11.2.217 -U postgres -d gestiona -c "\dt"

# Backup antes de operaciones riesgosas
PGPASSWORD=postgres pg_dump -h 10.11.2.217 -U postgres -d gestiona > backup_$(date +%Y%m%d).sql