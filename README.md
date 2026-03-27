# Colaborador Digital de Voz

Colaborador digital de IA & Negocios que hace llamadas telefónicas automatizadas para confirmación y seguimiento de citas.

## Qué hace

1. Llama automáticamente a una lista de contactos
2. Confirma citas programadas usando IA conversacional
3. Registra la respuesta de cada llamada (confirmada, reprogramada, cancelada)
4. Actualiza el estado del contacto en la base de datos

## Stack

| Componente | España | LATAM / USA |
|---|---|---|
| Telefonía + IA | [Telnyx AI](https://telnyx.com) | [Vapi.ai](https://vapi.ai) |
| Backend / API | Supabase Edge Functions (Deno) | Supabase Edge Functions (Deno) |
| Base de datos | Supabase PostgreSQL | Supabase PostgreSQL |
| LLM | Claude Haiku 4.5 (via Telnyx) | OpenAI gpt-4o-mini (via Vapi) |
| Voz | AWS Polly Lucia (via Telnyx) | ElevenLabs Paula (via Vapi) |
| Número telefónico | Fijo local +34 (Madrid) | Twilio (importado en Vapi) |

## Instalación

El instalador te preguntará tu región al inicio y configurará todo automáticamente:

- **España** → configura Telnyx (número fijo local, regulación española)
- **LATAM / USA** → configura Vapi + Twilio
- **Ambos** → configura los dos proveedores

### Opción 1 — Instalación asistida (recomendada)

Abre tu terminal, pega esta línea y sigue las instrucciones en pantalla:

```bash
curl -fsSL https://raw.githubusercontent.com/franciscoxos/ian-voice-collaborator-template/main/setup.sh | bash
```

> **Nota:** Si clonaste este repositorio a tu cuenta, reemplaza `franciscoxos` con tu usuario de GitHub.

El script te guía paso a paso: pide tus credenciales, crea el assistant, despliega las tablas y las funciones. En menos de 10 minutos tienes todo funcionando.

### Opción 2 — Instalación manual

```bash
# 1. Clonar e instalar
git clone https://github.com/franciscoxos/ian-voice-collaborator-template.git
cd ian-voice-collaborator-template
npm install

# 2. Conectar con Supabase
npx supabase login
npx supabase link --project-ref TU_PROJECT_REF

# 3. Crear tablas
npx supabase db push

# 4. Configurar variables de entorno
cp .env.example .env
# Edita .env con tus credenciales

# 5. Desplegar funciones
npx supabase functions deploy make-call --no-verify-jwt
npx supabase functions deploy vapi-webhook --no-verify-jwt
```

Para la guía completa paso a paso, lee [docs/manual-instalacion.md](docs/manual-instalacion.md).

## Uso

### Llamar a un contacto específico

```bash
curl -X POST https://TU_PROYECTO.supabase.co/functions/v1/make-call \
  -H "Content-Type: application/json" \
  -d '{"contact_id": "uuid-del-contacto"}'
```

### Llamar a todos los contactos pendientes

```bash
curl -X POST https://TU_PROYECTO.supabase.co/functions/v1/make-call \
  -H "Content-Type: application/json" \
  -d '{"batch": true}'
```

## Estructura del proyecto

```
ian-voice-collaborator/
├── supabase/
│   ├── functions/
│   │   ├── make-call/index.ts      # Dispara llamada via Telnyx o Vapi
│   │   └── vapi-webhook/index.ts   # Recibe resultado de Vapi
│   └── migrations/
│       └── 001_initial.sql         # Tablas: contacts, call_logs, config
├── src/
│   ├── call-script.ts              # Script de conversación configurable
│   └── config.ts                   # Configuración del colaborador
├── integration/                    # Acoplamiento al Centro de Mando (fase 2)
├── docs/
│   ├── manual-instalacion.md       # Guía paso a paso
│   ├── apis-necesarias.md          # Cuentas y API keys necesarias
│   └── script-ejemplo.md          # Ejemplo de conversación
└── .env.example
```

## Documentación

- [Manual de instalación](docs/manual-instalacion.md) — guía paso a paso
- [APIs necesarias](docs/apis-necesarias.md) — qué cuentas crear y qué datos obtener
- [Script de ejemplo](docs/script-ejemplo.md) — cómo funciona y cómo personalizar la conversación

## Después de la instalación

### Agregar contactos

```bash
curl -X POST "TU_SUPABASE_URL/rest/v1/contacts" \
  -H "apikey: TU_SERVICE_ROLE_KEY" \
  -H "Authorization: Bearer TU_SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Juan Pérez",
    "phone": "+521234567890",
    "appointment_date": "2026-04-01T10:00:00Z"
  }'
```

### Hacer una llamada

```bash
curl -X POST "TU_SUPABASE_URL/functions/v1/make-call" \
  -H "Content-Type: application/json" \
  -d '{"contact_id": "UUID-DEL-CONTACTO"}'
```

### Llamar a todos los contactos pendientes

```bash
curl -X POST "TU_SUPABASE_URL/functions/v1/make-call" \
  -H "Content-Type: application/json" \
  -d '{"batch": true}'
```

### Ver resultados

Ve a tu proyecto en [supabase.com](https://supabase.com) → Table Editor → `call_logs` para ver transcripciones y resultados.

## Producto de IA & Negocios

Este colaborador es un producto standalone que funciona de manera independiente. Su verdadero potencial se activa cuando se acopla al [Centro de Mando Inteligente](https://iaynegocios.net) — automatización completa del ciclo de ventas y atención.

¿Necesitas ayuda con la instalación? [Escríbenos por WhatsApp](https://wa.me/34610842736?text=Hola!%20Ya%20tengo%20el%20colaborador%20digital%20de%20voz%20y%20quiero%20que%20me%20ayuden%20con%20la%20instalaci%C3%B3n.)
