# IA&N — Colaborador Digital de Voz

## Qué es este proyecto

Producto standalone de IA & Negocios: un colaborador digital de voz que hace llamadas telefónicas automatizadas para confirmación y seguimiento de citas. Es el primer producto del ecosistema de colaboradores digitales y funciona como lead magnet del Centro de Mando Inteligente.

**Nombre comercial:** Colaborador Digital de Voz
**Nombre técnico:** ian-voice-collaborator
**Plataforma de telefonía:** Vapi.ai
**Runtime:** Deno (Supabase Edge Functions)
**Base de datos:** Supabase (proyecto propio, separado del Centro de Mando)

## Regla arquitectónica fundamental

Este proyecto es **standalone**. No depende del Centro de Mando Inteligente.

- Funciona independientemente
- Usa cuentas y API keys del cliente
- Tiene su propia base de datos, configuración y documentación

## Caso de uso

**Confirmación y seguimiento de citas.** Nada más por ahora.

## Stack técnico

| Componente | Tecnología |
|---|---|
| Telefonía + IA conversacional | Vapi.ai |
| Backend / API | Supabase Edge Functions (Deno) |
| Base de datos | Supabase PostgreSQL |
| LLM para conversación | OpenAI gpt-4o-mini (via Vapi) |
| Voz | ElevenLabs, voz "paula" (via Vapi) |

## Estructura del proyecto

```
ian-voice-collaborator/
├── supabase/
│   ├── functions/
│   │   ├── make-call/index.ts      # Dispara llamada via Vapi API
│   │   └── vapi-webhook/index.ts   # Recibe resultado de Vapi al terminar
│   └── migrations/
│       └── 20260318000001_initial.sql  # Tablas: contacts, call_logs, config
├── src/
│   ├── call-script.ts              # Prompt/script de conversación
│   └── config.ts                   # Configuración del colaborador
├── integration/                    # Módulo de acoplamiento (fase 2)
│   └── README.md
├── docs/
│   ├── manual-instalacion.md       # Paso a paso para el cliente
│   ├── apis-necesarias.md          # Qué cuentas crear
│   └── script-ejemplo.md          # Ejemplo de conversación
├── .env.example
└── README.md
```

## Base de datos

```sql
CREATE TABLE contacts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  phone TEXT NOT NULL,
  email TEXT,
  company TEXT,
  appointment_date TIMESTAMPTZ,
  status TEXT NOT NULL DEFAULT 'pending',
  last_called_at TIMESTAMPTZ,
  call_count INTEGER DEFAULT 0,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE call_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  contact_id UUID REFERENCES contacts(id) ON DELETE CASCADE,
  vapi_call_id TEXT,
  started_at TIMESTAMPTZ,
  ended_at TIMESTAMPTZ,
  duration_seconds INTEGER,
  status TEXT NOT NULL,
  transcript TEXT,
  summary TEXT,
  result TEXT,
  sentiment TEXT,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE config (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT now()
);
```

## Configuración del assistant en Vapi (ya optimizada)

- **Modelo:** OpenAI gpt-4o-mini, temperatura 0.3, max 100 tokens
- **Transcriber:** Deepgram nova-3, idioma español, endpointing 200ms
- **Voz:** ElevenLabs "paula", streaming latency 4
- **Duración máxima:** 2 minutos

## Reglas de desarrollo

- **Nunca usar `.single()`** — usar `.maybeSingle()`
- **Deploy:** `npx supabase functions deploy <nombre> --no-verify-jwt`
- **Todo en español** — código en inglés, comentarios y docs en español
- **No sobre-ingeniería** — MVP funcional, no sistema enterprise
- **Actualizar CONTEXT.md** al final de cada sesión de trabajo
- **Prompt sincronizado** — el prompt en `setup.sh` y `src/call-script.ts` deben ser equivalentes. Si cambias uno, cambia el otro.
- **No hardcodear secrets** — nunca poner API keys, tokens, o project IDs en archivos trackeados por git
- **`.claude/settings.json` es local** — está en `.gitignore`, nunca debe subirse a git

## Security Hardening (2026-03-27)

### Cambios aplicados
1. **`.claude/settings.json` limpiado** — tokens de Vapi, Supabase y JWT eliminados, archivo sacado de git tracking
2. **`.gitignore` actualizado** — agregado `.claude/`, `.env.local`, `*.local`, editor files
3. **Prompt de setup.sh sincronizado** con `src/call-script.ts` (eran diferentes)
4. **CONTEXT.md actualizado** con estado real del proyecto

### Rollback
```bash
git revert HEAD
```

### Credenciales a rotar
- **Vapi API Key:** rotar en dashboard.vapi.ai > Organization > API Keys
- **Supabase Access Token:** rotar en supabase.com > Account > Access Tokens
- **Supabase DB Password:** cambiar en proyecto > Settings > Database
- **Supabase JWT (service_role):** se regenera al cambiar el DB password
