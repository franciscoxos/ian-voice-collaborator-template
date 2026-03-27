# Plan de Hardening — Lead Magnet Template

**Fecha:** 2026-03-27
**Restore point:** `pre-lead-magnet-hardening`
**Estado inicial:** 70% listo — funcional pero necesita hardening
**Estado final:** 100% — todos los fixes aplicados

---

## Bloque 1: Seguridad + Info Personal (ALTA)

| Tarea | Archivo | Acción | Estado |
|-------|---------|--------|--------|
| Teléfono personal | README.md | Cambiado a WhatsApp de negocio | Hecho |
| Scan completo | Todos | Verificar 0 leaks de info personal/secrets | Hecho |

## Bloque 2: Hardening del Código — 16 fixes (ALTA)

### Críticos (#1-6)

| # | Archivo | Acción | Estado |
|---|---------|--------|--------|
| 1 | setup.sh:283,288,315 | Error handling en `supabase link`, `db push`, `secrets set` | Hecho |
| 2 | setup.sh:215 | Tildes en prompt: español, robóticas, mañana (14 correcciones) | Hecho |
| 3 | vapi-webhook:30-42 | Validar `VAPI_AUTH_TOKEN` si existe (opcional, backward-compatible) | Hecho |
| 4 | vapi-webhook:111-122 | Incluir `contact_id` en INSERT nuevos (desde metadata) | Hecho |
| 5 | initial.sql | RLS policies en 3 tablas (service_role full, authenticated read) | Hecho |
| 6 | make-call:37 | "miércoles", "sábado", "mañana" — tildes corregidas | Hecho |

### Altos (#7-11)

| # | Archivo | Acción | Estado |
|---|---------|--------|--------|
| 7 | make-call:6-10 | `!` → `?? ""` + validación con mensaje claro (500) | Hecho |
| 8 | make-call | CORS headers + OPTIONS handler en 9 responses | Hecho |
| 9 | vapi-webhook:74-97 | `.error` chequeado en 5 operaciones DB (log, no throw) | Hecho |
| 10 | make-call:133 | `call_count` batch → `(contact.call_count ?? 0) + 1` | Hecho |
| 11 | README:29 | Nota: "reemplaza franciscoxos con tu usuario si clonaste" | Hecho |

### Medios (#12-16)

| # | Archivo | Acción | Estado |
|---|---------|--------|--------|
| 12 | src/config.ts | Documentado como referencia, voice_id actualizado a ElevenLabs ID | Hecho |
| 13 | initial.sql | 5 índices: contacts.status, contacts.phone, call_logs.contact_id/vapi_call_id/status | Hecho |
| 14 | manual-instalacion.md | Nuevo Paso 7: configurar webhook en Vapi dashboard | Hecho |
| 15 | .env.example | Variables marcadas REQUERIDO / AUTO-GENERADO | Hecho |
| 16 | README | Sección "Después de la instalación" con curl examples | Hecho |

## Bloque 3: Documentación Actualizada (ALTA)

| Tarea | Archivo | Acción | Estado |
|-------|---------|--------|--------|
| Dual provider | manual-instalacion.md | Nota: España=Telnyx, LATAM/USA=Vapi+Twilio | Hecho |
| APIs necesarias | apis-necesarias.md | Telnyx como sección opcional para España | Hecho |
| Script ejemplo | script-ejemplo.md | Formato hora real: "10 de la mañana", "3 y 30 de la tarde" | Hecho |

## Bloque 4: Migración DB (absorbido en Bloque 2 #5 y #13) — Hecho

## Bloque 5: Análisis UX del Lead (MEDIA)

| Tarea | Entregable | Estado |
|-------|------------|--------|
| Mapear fricción | Dónde se atora el lead no-técnico | Hecho |
| Punto de venta | Momento exacto donde vendemos instalación | Hecho |

### Puntos de fricción detectados:
1. Crear cuenta Supabase (fácil)
2. Crear cuenta Vapi (fácil)
3. **Obtener credenciales de 2-3 dashboards** (aquí se complica)
4. **Ejecutar comando en terminal** (aquí se pierden los no-técnicos)
5. **Si es España → Telnyx además de Vapi** (3 dashboards)

**Punto de venta natural:** "¿No quieres lidiar con esto? Nosotros lo configuramos por ti."

---

## Rollback
```bash
git checkout pre-lead-magnet-hardening -- .
```
