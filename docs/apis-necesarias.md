# APIs y Cuentas Necesarias

Para instalar el Colaborador Digital de Voz necesitas cuentas en **dos servicios**: Supabase (todos) + un proveedor de telefonia segun tu region.

---

## Elige tu region primero

| | Espana (+34) | LATAM / USA |
|---|---|---|
| **Cuentas necesarias** | Supabase + Telnyx | Supabase + Vapi |
| **Costo minimo** | ~$1/mes (numero) + ~$0.02/min | Creditos de prueba incluidos |
| **Tiempo de setup** | 2-5 dias (aprobacion numero) | Inmediato |

---

## 1. Supabase — Base de datos + Backend (todos los usuarios)

Supabase es la plataforma que almacena tus contactos, registra las llamadas y ejecuta la logica del colaborador.

### Crear cuenta

1. Ve a [supabase.com](https://supabase.com) y crea una cuenta gratuita
2. Crea un **nuevo proyecto** (NO uses un proyecto existente)
   - Nombre sugerido: `colaborador-voz` o el nombre de tu negocio
   - Region: selecciona la mas cercana a tu ubicacion
   - **Guarda el password de la base de datos** — lo necesitaras para las migraciones

### Datos que necesitas obtener

| Dato | Donde encontrarlo | Variable en `.env` |
|---|---|---|
| **Project URL** | Settings > API > Project URL | `SUPABASE_URL` |
| **Service Role Key** | Settings > API > service_role (secret) | `SUPABASE_SERVICE_ROLE_KEY` |
| **Project Ref** | Settings > General > Reference ID | Se usa para `supabase link` |

### Costo

- **Plan gratuito:** suficiente para empezar (500 MB de base de datos, 500K invocaciones de Edge Functions al mes)
- **Plan Pro ($25/mes):** recomendado si manejas mas de 100 contactos o necesitas backups automaticos

---

## 2. Telnyx — Telefonia para Espana (+34)

> Solo necesitas Telnyx si tus contactos estan en Espana. Si no, salta a la seccion 3 (Vapi).

Telnyx proporciona numeros fijos espanoles y un AI Assistant nativo con Claude Haiku 4.5, Deepgram y AWS Polly. Cumple la regulacion espanola 2025 para llamadas comerciales.

### Crear cuenta

1. Ve a [telnyx.com](https://telnyx.com) y registrate (cuenta gratuita)
2. Completa la verificacion de identidad (obligatoria para solicitar numeros)

### Obtener un numero espanol

1. Ve a **Numbers > Search & Buy > Spain**
2. Selecciona **Fixed line** (obligatorio — Espana no permite llamadas comerciales desde moviles)
3. Completa la solicitud de aprobacion regulatoria
4. **Tiempo de aprobacion:** 2-5 dias laborales. No puedes hacer llamadas hasta que se apruebe.

### Crear el AI Assistant

1. Ve a **AI > Assistants > Create**
2. Configura:
   - **LLM:** Claude Haiku 4.5
   - **STT:** Deepgram nova-3, idioma espanol
   - **TTS:** AWS Polly Lucia-Neural (es-ES)
3. Copia el **Assistant ID**

### Crear la TeXML Application

1. Ve a **Voice > TeXML > Applications > Add new**
2. Configura la aplicacion con tu numero espanol
3. Copia el **TeXML App ID**

### Datos que necesitas obtener

| Dato | Donde encontrarlo | Variable en `.env` |
|---|---|---|
| **API Key** | Mission Control > Auth > API Keys | `TELNYX_API_KEY` |
| **TeXML App ID** | Voice > TeXML > Applications > tu app | `TELNYX_TEXML_APP_ID` |
| **Assistant ID** | AI > Assistants > tu assistant | `TELNYX_ASSISTANT_ID` |
| **Numero espanol** | Numbers > My Numbers | `TELNYX_FROM_NUMBER` |

### Costo

- **Numero fijo espanol:** ~$1/mes
- **Llamadas:** ~$0.02/min (incluye terminacion en Espana)
- **AI Assistant:** uso de LLM + STT + TTS incluido en tarifa Telnyx
- **Estimado por llamada de 2 min:** ~$0.05-0.08 USD

---

## 3. Vapi — Telefonia para LATAM / USA

> Solo necesitas Vapi si tus contactos estan fuera de Espana. Si ya configuraste Telnyx, salta esta seccion.

Vapi es una plataforma de llamadas con IA que funciona con numeros Twilio. Ideal para Mexico, Argentina, Colombia, USA y cualquier pais fuera de Espana.

### Crear cuenta

1. Ve a [vapi.ai](https://vapi.ai) y crea una cuenta
2. Al registrarte recibes creditos de prueba para hacer tus primeras llamadas

### Configurar numero telefonico

1. Ve a **Phone Numbers** en el dashboard de Vapi
2. Compra un numero o importa uno existente de Twilio
3. Copia el **Phone Number ID** (es un UUID, no el numero telefonico)

### Crear el Assistant

El assistant se crea automaticamente con `setup.sh`. Si necesitas crearlo manualmente:

1. Ve a **Assistants** en el dashboard
2. Crea uno nuevo con el nombre "Confirmacion de Citas"
3. Modelo: OpenAI gpt-4o-mini
4. Voz: ElevenLabs, voz "paula"
5. Copia el **Assistant ID**

### Datos que necesitas obtener

| Dato | Donde encontrarlo | Variable en `.env` |
|---|---|---|
| **API Key** | Organization > API Keys | `VAPI_API_KEY` |
| **Phone Number ID** | Phone Numbers > tu numero > UUID | `VAPI_PHONE_NUMBER_ID` |
| **Assistant ID** | Assistants > tu assistant > ID | `VAPI_ASSISTANT_ID` |

### Costo

- **Creditos iniciales:** Vapi incluye creditos de prueba al registrarte
- **Estimado por llamada de 2 min:** ~$0.10-0.15 USD (incluye telefonia + LLM + voz)
- Consulta precios actualizados en [vapi.ai/pricing](https://vapi.ai/pricing)

---

## 4. OpenAI — NO necesitas cuenta separada

No necesitas crear una cuenta de OpenAI ni obtener API keys aparte:

- **Con Telnyx:** el AI Assistant usa Claude Haiku 4.5 directamente (incluido en Telnyx)
- **Con Vapi:** usa GPT-4o-mini internamente (incluido en el precio de Vapi)

---

## Resumen por region

### Espana (+34)

| Servicio | Cuenta necesaria | Costo minimo |
|---|---|---|
| Supabase | Si, proyecto nuevo | Gratis |
| Telnyx | Si | ~$1/mes + ~$0.02/min |
| Vapi | No | — |
| OpenAI | No (incluido en Telnyx) | — |

### LATAM / USA

| Servicio | Cuenta necesaria | Costo minimo |
|---|---|---|
| Supabase | Si, proyecto nuevo | Gratis |
| Vapi | Si | Creditos de prueba incluidos |
| Telnyx | No | — |
| OpenAI | No (incluido en Vapi) | — |

---

## Variables de entorno completas

Tu archivo `.env` solo necesita las variables de tu region. Deja vacias las del otro proveedor.

### Espana (Telnyx)

```env
# Supabase (REQUERIDO)
SUPABASE_URL=https://tu-proyecto.supabase.co
SUPABASE_SERVICE_ROLE_KEY=tu-service-role-key

# Telnyx (Espana)
TELNYX_API_KEY=tu-api-key
TELNYX_TEXML_APP_ID=tu-texml-app-id
TELNYX_ASSISTANT_ID=tu-assistant-id
TELNYX_FROM_NUMBER=+34XXXXXXXXX
```

### LATAM / USA (Vapi)

```env
# Supabase (REQUERIDO)
SUPABASE_URL=https://tu-proyecto.supabase.co
SUPABASE_SERVICE_ROLE_KEY=tu-service-role-key

# Vapi (LATAM/USA)
VAPI_API_KEY=tu-api-key-de-vapi
VAPI_PHONE_NUMBER_ID=uuid-del-numero-telefonico
VAPI_ASSISTANT_ID=uuid-del-assistant

# Webhook (se genera automaticamente)
WEBHOOK_URL=https://tu-proyecto.supabase.co/functions/v1/vapi-webhook
```
