# AGENTS.md — Colaborador Digital de Voz (Template)

> Guía para agentes IA (Codex, Cursor, Aider, Devin, Copilot, Claude Code) trabajando en este template.
> Para humanos: ver `README.md`.

## Project Overview

Template open-source de colaborador telefónico automatizado:
- **España:** Telnyx AI (número fijo local +34)
- **LATAM/USA:** Vapi + Twilio
- Stack: Supabase (Postgres + Edge Functions Deno) + Next.js dashboard

Empleado virtual 24/7 para confirmación de citas y seguimiento de leads.

## Setup commands

```bash
# Instalación interactiva (recomendado primera vez)
./setup.sh

# Manual:
npm install
cp .env.example .env.local   # rellenar credenciales

# Migraciones Supabase
npm run db:migrate

# Deploy edge functions
npm run functions:deploy:make-call
npm run functions:deploy:vapi-webhook

# Dev local (frontend)
npm run dev

# Tests
npm run test
```

## Stack

| Capa | Tecnología |
|---|---|
| Frontend | Next.js + TypeScript + Tailwind CSS |
| Backend | Supabase Edge Functions (Deno runtime) |
| DB | Supabase PostgreSQL |
| Auth | Supabase Auth (email/password) |
| Telefonía España | Telnyx AI Assistant |
| Telefonía LATAM/USA | Vapi.ai |
| SMS | Twilio |
| LLM call (ES) | Anthropic Claude Haiku 4.5 vía Telnyx |
| LLM call (LATAM) | OpenAI gpt-4o-mini vía Vapi |
| LLM extraction | OpenAI gpt-4o-mini |

## Code style

- **TypeScript estricto** — sin `any` implícito
- **ESLint + Prettier** — `npm run lint` antes de PR
- **Edge Functions Deno** — no Node-specific APIs
- **Supabase queries**: usar `.maybeSingle()` NO `.single()` (evita 406)
- **No usar `.catch()` en PostgrestBuilder** — envolver con `Promise.resolve()` primero
- **Naming**: tablas `snake_case`, funciones `kebab-case`, components `PascalCase`
- **No emojis en código** (sí en docs/UI si el cliente los pide)

## Testing instructions

```bash
# Unit tests
npm run test

# E2E tests (si existen)
npm run test:e2e

# Smoke test edge function localmente
npm run functions:serve
curl -X POST http://localhost:54321/functions/v1/make-call -H "Content-Type: application/json" -d '{"phone":"+34..."}'
```

## Deploy

```bash
# Dashboard a Vercel (auto-deploy en push a main si conectado)
vercel deploy --prod

# Edge functions a Supabase
npx supabase functions deploy --no-verify-jwt --project-ref YOUR_PROJECT_REF

# Migraciones DB
npx supabase db push --project-ref YOUR_PROJECT_REF

# Secrets (NO commitear)
npx supabase secrets set KEY=value --project-ref YOUR_PROJECT_REF
```

## Environment variables

Ver `.env.example` para lista completa. Credenciales mínimas:

```
SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co
SUPABASE_ANON_KEY=...
SUPABASE_SERVICE_ROLE_KEY=...

# Telnyx (España)
TELNYX_API_KEY=...
TELNYX_ASSISTANT_ID=...
TELNYX_FROM_NUMBER=+34...

# Vapi (LATAM/USA)
VAPI_API_KEY=...
VAPI_ASSISTANT_ID=...
VAPI_PHONE_NUMBER_ID=...

# SMS
TWILIO_ACCOUNT_SID=...
TWILIO_AUTH_TOKEN=...
TWILIO_FROM_NUMBER=...

# LLM extraction
OPENAI_API_KEY=...
```

## Security considerations

1. **NUNCA commitear `.env*`** — verificar `.gitignore` antes de cada push
2. **service_role_key NUNCA al frontend** — solo en edge functions (Deno secrets)
3. **RLS habilitada por defecto** en todas las tablas — confirmar antes de poner en prod
4. **Webhooks públicos requieren rate-limit + token validation**
5. **Telnyx AI Assistant solo con modelos NON-thinking** — modelos thinking devuelven `content` vacío en producción
6. **Telnyx `dynamic_variables` debe tener fallbacks estáticos** para cada placeholder — sin esto, webhook timeout deja el agente mudo

## PR instructions

1. Crear branch desde `main`: `feature/<descripción-corta>`
2. Commit messages estilo: `feat: add X`, `fix: resolve Y`, `docs: update Z`
3. PR title: `<type>: <descripción corta>` (under 70 chars)
4. PR body: Summary (3 bullets max) + Test plan
5. Antes de pedir review: `npm run lint && npm run test` pasan
6. Revisor verifica: no .env tracked, no secrets en código, RLS preservada

## Architecture overview

```
INBOUND CALL
  → Telnyx (España) o Vapi (LATAM) detecta llamada entrante
  → AI Assistant procesa con prompt configurado
  → poll-results function detecta conversación nueva
  → LLM extraction (datos estructurados)
  → Telegram/SMS notificación
  → Dashboard refleja en call_logs

OUTBOUND CALL
  → make-call edge function (o frontend trigger)
  → Telnyx/Vapi inicia llamada
  → AI conversa según prompt
  → poll-results extrae datos + clasifica resultado
  → Retry si no_answer (max 3, +2h, +24h)
  → Notificación final
```

## Key files

- `supabase/functions/make-call/` — inicia llamadas outbound
- `supabase/functions/poll-results/` — procesa llamadas completadas
- `supabase/functions/vapi-webhook/` — recibe resultados Vapi
- `supabase/migrations/` — schema DB versionado
- `src/` — frontend Next.js dashboard
- `docs/` — documentación funcional
- `setup.sh` — script instalación interactivo

## Conventions specific to this codebase

1. **Calling hours hardcoded** 8AM-9PM Madrid time — fuera de ese rango, SMS + mark pending
2. **Retries**: max 3 attempts, delays `[+2h, +24h]`, solo si `last_call_result = 'no_answer'`
3. **Provider routing**: phone starts with `+34` → Telnyx, otros → Vapi
4. **Call types**: `outbound_call`, `inbound_call`, `scheduled_callback`
5. **Status flow**: `pending → in_progress → completed/no_answer/cancelled`

## See also

- `README.md` — overview funcional para humanos
- `docs/` — documentación adicional
- `setup.sh` — instalador con prompts

## graphify

This project has a knowledge graph at graphify-out/ with god nodes, community structure, and cross-file relationships.

Rules:
- For codebase questions, first run `graphify query "<question>"` when graphify-out/graph.json exists. Use `graphify path "<A>" "<B>"` for relationships and `graphify explain "<concept>"` for focused concepts. These return a scoped subgraph, usually much smaller than GRAPH_REPORT.md or raw grep output.
- If graphify-out/wiki/index.md exists, use it for broad navigation instead of raw source browsing.
- Read graphify-out/GRAPH_REPORT.md only for broad architecture review or when query/path/explain do not surface enough context.
- After modifying code, run `graphify update .` to keep the graph current (AST-only, no API cost).
