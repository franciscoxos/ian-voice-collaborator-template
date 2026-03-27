# CONTEXT.md — Estado del Proyecto

Última actualización: 2026-03-27

---

## Estado actual

**Template listo para distribución.** El cliente ejecuta `setup.sh` o sigue `docs/manual-instalacion.md`.

| Paso | Descripción | Estado |
|---|---|---|
| Paso 1 | Scaffold (este repo) | Completo |
| Paso 2 | Base de datos (migration SQL) | Completo |
| Paso 3 | Edge Function make-call | Completo |
| Paso 4 | Edge Function vapi-webhook | Completo |
| Paso 5 | Script de conversación | Completo |
| Paso 6 | setup.sh (instalación asistida) | Completo |
| Paso 7 | Documentación (manual, APIs, script ejemplo) | Completo |

---

## Arquitectura

```
Cliente ejecuta setup.sh
  → Crea proyecto Supabase (tablas: contacts, call_logs, config)
  → Crea assistant en Vapi (prompt sincronizado con src/call-script.ts)
  → Despliega Edge Functions (make-call, vapi-webhook)
  → Configura secrets en Supabase
  → Crea contacto de prueba
  → Listo para hacer llamadas
```

### Flujo de una llamada

```
make-call (Edge Function)
  → Lee contacto de tabla contacts
  → Llama Vapi API con assistant + phone number + variables
  → Registra en call_logs (status: in_progress)
  → Vapi hace la llamada telefónica con IA
  → Al terminar → Vapi envía POST a vapi-webhook
  → vapi-webhook actualiza call_logs y contacts.status
```

---

## Dual provider (España vs LATAM/USA)

**IMPORTANTE:** Este template usa solo Vapi. El Centro de Mando Inteligente tiene dual provider:
- **+34 (España):** Telnyx AI con número de Madrid (+34 910 78 32 64)
- **Otros países:** Vapi con número Twilio

Este template es solo Vapi porque es el producto standalone para clientes. La lógica dual está en el Centro de Mando (repo ai-n-command-center).

---

## Archivos clave

| Archivo | Propósito |
|---------|-----------|
| `setup.sh` | Instalación asistida completa (12 pasos) |
| `src/call-script.ts` | Prompt/script de conversación (fuente de verdad) |
| `src/config.ts` | Configuración default del colaborador |
| `supabase/functions/make-call/index.ts` | Dispara llamada via Vapi API |
| `supabase/functions/vapi-webhook/index.ts` | Recibe resultado al terminar llamada |
| `supabase/migrations/20260318000001_initial.sql` | Tablas: contacts, call_logs, config |
| `docs/manual-instalacion.md` | Manual paso a paso para instalación manual |
| `docs/apis-necesarias.md` | Qué cuentas crear (Supabase, Vapi) |
| `docs/script-ejemplo.md` | Ejemplo de conversación telefónica |

---

## Security Hardening (2026-03-27)

- `.claude/settings.json` limpiado — tokens de desarrollo eliminados, archivo excluido de git
- `.gitignore` actualizado — incluye `.claude/`, `.env.local`, editor files
- Prompt de setup.sh sincronizado con `src/call-script.ts`
- Credenciales expuestas en git history — **rotar:** Vapi API key, Supabase access token, DB password

### Credenciales a rotar (estaban en git history)

| Servicio | Qué rotar |
|----------|-----------|
| Vapi | API Key en dashboard.vapi.ai > Organization > API Keys |
| Supabase | Access Token en supabase.com > Account > Access Tokens |
| Supabase | Database Password en proyecto > Settings > Database |

---

## Mis credenciales (llenar durante la instalación)

### Supabase
| Recurso | Valor |
|---|---|
| Project Ref | |
| URL | |
| Service Role Key | |

### Vapi
| Recurso | Valor |
|---|---|
| API Key | |
| Assistant ID | |
| Phone Number ID | |
| Número telefónico | |

---

## Pendientes

- [ ] Rotar credenciales expuestas (Vapi API key, Supabase tokens)
- [ ] Verificar que setup.sh funciona end-to-end con cuenta limpia

---

## Notas

- El prompt de setup.sh y src/call-script.ts están sincronizados (2026-03-27)
- make-call soporta modo batch ({batch: true}) y modo individual ({contact_id: "uuid"})
- vapi-webhook maneja: confirmed, rescheduled, cancelled, no_answer, busy, voicemail, completed, failed
