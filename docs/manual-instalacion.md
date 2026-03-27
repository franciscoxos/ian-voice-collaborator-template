# Manual de Instalacion — Colaborador Digital de Voz

Guia paso a paso para instalar y configurar tu Colaborador Digital de Voz.

---

## Requisitos previos

- **Node.js** v18 o superior ([descargar](https://nodejs.org))
- **Git** instalado
- **Terminal / linea de comandos** (Terminal en Mac, CMD o PowerShell en Windows)
- Cuentas creadas segun tu region (ver [apis-necesarias.md](apis-necesarias.md))

---

## Elige tu region

Tu region determina que proveedor de telefonia usaras. Elige antes de empezar:

| | Espana (+34) | LATAM / USA |
|---|---|---|
| **Proveedor** | Telnyx | Vapi + Twilio |
| **Numero** | Fijo local Madrid | Cualquier pais |
| **Regulacion** | Cumple ley espanola 2025 | Sin restricciones |
| **Aprobacion** | 2-5 dias (numero espanol) | Inmediato |
| **IA de voz** | Claude Haiku 4.5 | GPT-4o-mini |
| **Cuentas necesarias** | Supabase + Telnyx | Supabase + Vapi |

> **No sabes cual elegir?** Si tus contactos tienen numeros +34, ve por Espana. Para cualquier otro pais, ve por LATAM/USA.

---

## Pasos comunes (todos los usuarios)

### Paso 1 — Clonar el proyecto

```bash
git clone https://github.com/franciscoxos/ian-voice-collaborator-template.git
cd ian-voice-collaborator-template
npm install
```

### Paso 2 — Crear proyecto en Supabase

1. Ve a [supabase.com/dashboard](https://supabase.com/dashboard)
2. Click en **New Project**
3. Elige un nombre y una region cercana a ti
4. **Guarda el password de la base de datos** (lo necesitaras para conectar la CLI)
5. Espera a que el proyecto termine de crearse (~2 minutos)

### Paso 3 — Conectar con Supabase CLI

Inicia sesion en la CLI de Supabase:

```bash
npx supabase login
```

Esto abrira tu navegador para generar un access token. Pegalo en la terminal.

Luego conecta tu proyecto (reemplaza `TU_PROJECT_REF` con el Reference ID de tu proyecto):

```bash
npx supabase link --project-ref TU_PROJECT_REF
```

Te pedira el password de la base de datos que guardaste en el paso anterior.

> **Donde encuentro el Project Ref?** En el dashboard de Supabase: Settings > General > Reference ID

### Paso 4 — Crear las tablas

Ejecuta la migracion para crear las tablas necesarias:

```bash
npx supabase db push
```

Esto creara 3 tablas en tu base de datos:
- **contacts** — los contactos a los que el colaborador llamara
- **call_logs** — registro detallado de cada llamada realizada
- **config** — configuracion del colaborador (nombre del negocio, etc.)

### Paso 5 — Configurar variables de entorno

Copia el archivo de ejemplo:

```bash
cp .env.example .env
```

Edita el archivo `.env` y llena primero las variables de Supabase (las encuentras en Settings > API):

```env
# Supabase (REQUERIDO para todos)
SUPABASE_URL=https://tu-proyecto.supabase.co
SUPABASE_SERVICE_ROLE_KEY=tu-service-role-key
```

Ahora sigue con el path de tu region.

---

## Path A: Espana (Telnyx)

> Sigue estos pasos si tus contactos estan en Espana (+34).

### Paso 6A — Crear cuenta en Telnyx

1. Registrate en [telnyx.com](https://telnyx.com) (cuenta gratuita)
2. Ve a **Mission Control > Auth > API Keys** y copia tu API Key
3. Solicita un numero fijo espanol (+34):
   - Ve a **Numbers > Search & Buy > Spain**
   - Selecciona **Fixed line** (obligatorio para llamadas comerciales en Espana)
   - Completa la solicitud de aprobacion
   - **IMPORTANTE:** La aprobacion del numero puede tomar 2-5 dias laborales. No puedes hacer llamadas hasta que se apruebe.
4. Crea un AI Assistant:
   - Ve a **AI > Assistants > Create**
   - LLM: Claude Haiku 4.5
   - STT: Deepgram nova-3, idioma espanol
   - TTS: AWS Polly Lucia-Neural (es-ES)
   - Copia el **Assistant ID**
5. Crea una TeXML Application:
   - Ve a **Voice > TeXML > Applications > Add new**
   - Copia el **TeXML App ID**

### Paso 7A — Configurar .env (Espana)

Agrega estas variables a tu archivo `.env`:

```env
# Espana: Telnyx
TELNYX_API_KEY=tu-api-key
TELNYX_TEXML_APP_ID=tu-texml-app-id
TELNYX_ASSISTANT_ID=tu-assistant-id
TELNYX_FROM_NUMBER=+34XXXXXXXXX
```

> Deja las variables de Vapi vacias — no las necesitas.

### Paso 8A — Configurar secrets en Supabase

```bash
npx supabase secrets set \
  TELNYX_API_KEY=tu-api-key \
  TELNYX_TEXML_APP_ID=tu-texml-app-id \
  TELNYX_ASSISTANT_ID=tu-assistant-id \
  TELNYX_FROM_NUMBER=+34XXXXXXXXX
```

Ahora salta al **Paso 9** (pasos finales).

---

## Path B: LATAM / USA (Vapi)

> Sigue estos pasos si tus contactos estan en Mexico, Argentina, Colombia, USA o cualquier pais fuera de Espana.

### Paso 6B — Crear cuenta en Vapi

1. Registrate en [vapi.ai](https://vapi.ai) (incluye creditos de prueba)
2. Ve a **Organization > API Keys** y copia tu API Key
3. En **Phone Numbers**, compra o importa un numero de Twilio
4. Copia el **Phone Number ID** (es el UUID que aparece debajo del nombre del numero)

> El assistant se crea automaticamente con `setup.sh`, o puedes crearlo manualmente en el dashboard: Assistants > Create > modelo gpt-4o-mini, voz ElevenLabs "paula".

### Paso 7B — Configurar .env (LATAM/USA)

Agrega estas variables a tu archivo `.env`:

```env
# LATAM / USA: Vapi
VAPI_API_KEY=tu-api-key-de-vapi
VAPI_PHONE_NUMBER_ID=uuid-del-numero
VAPI_ASSISTANT_ID=se-genera-automaticamente
```

> Deja las variables de Telnyx vacias — no las necesitas.

### Paso 8B — Configurar secrets en Supabase

```bash
npx supabase secrets set \
  VAPI_API_KEY=tu-api-key \
  VAPI_PHONE_NUMBER_ID=uuid-del-numero
```

### Paso 8B.2 — Configurar Webhook en Vapi

1. Ve a [dashboard.vapi.ai](https://dashboard.vapi.ai) y selecciona tu Assistant
2. En la seccion "Server URL" o "Webhook", pega esta URL:
   ```
   https://TU-PROJECT-REF.supabase.co/functions/v1/vapi-webhook
   ```
3. Reemplaza `TU-PROJECT-REF` con el Project Ref de tu proyecto Supabase
4. Guarda los cambios

> Sin esto, las llamadas se haran pero no recibiras los resultados (confirmado, reagendo, cancelo).

Ahora sigue con el **Paso 9**.

---

## Pasos finales (todos los usuarios)

### Paso 9 — Desplegar Edge Functions

Despliega las funciones en Supabase:

```bash
npx supabase functions deploy make-call --no-verify-jwt
npx supabase functions deploy vapi-webhook --no-verify-jwt
```

### Paso 10 — Configurar el nombre de tu negocio

Inserta el nombre de tu negocio en la tabla `config`. Puedes hacerlo desde el Table Editor de Supabase o con SQL:

```sql
INSERT INTO config (key, value) VALUES ('business_name', 'Tu Nombre de Negocio');
```

### Paso 11 — Agregar un contacto de prueba

Agrega un contacto de prueba para verificar que todo funciona:

```sql
INSERT INTO contacts (name, phone, appointment_date, status)
VALUES (
  'Juan Perez',
  '+521234567890',
  '2026-04-01 10:00:00-06',
  'pending'
);
```

> **Formato del telefono:** debe incluir codigo de pais. Ejemplo: `+34612345678` para Espana, `+521234567890` para Mexico, `+11234567890` para USA.

### Paso 12 — Hacer tu primera llamada de prueba

Llama a la Edge Function para disparar una llamada. Reemplaza `CONTACT_ID` con el ID del contacto que creaste:

```bash
curl -X POST https://TU_PROYECTO.supabase.co/functions/v1/make-call \
  -H "Content-Type: application/json" \
  -d '{"contact_id": "CONTACT_ID"}'
```

O para llamar a todos los contactos pendientes:

```bash
curl -X POST https://TU_PROYECTO.supabase.co/functions/v1/make-call \
  -H "Content-Type: application/json" \
  -d '{"batch": true}'
```

---

## Verificar que funciona

1. **Revisa la tabla `call_logs`** en Supabase — deberia aparecer un registro con status `in_progress`
2. **Recibiras la llamada** en el numero del contacto de prueba
3. **Despues de la llamada**, el registro se actualizara con la transcripcion, duracion y resultado
4. **La tabla `contacts`** se actualizara con el nuevo status (`confirmed`, `rescheduled`, `cancelled`)

---

## Solucion de problemas

### Problemas comunes (todos los usuarios)

**"No hay contactos pendientes"**
- Verifica que tienes contactos con `status = 'pending'` en la tabla `contacts`

**Error de autenticacion con Supabase**
- Verifica que `SUPABASE_SERVICE_ROLE_KEY` sea el service_role key (NO el anon key)
- El service_role key empieza con `eyJ...`

**La llamada se realiza pero no se registra el resultado**
- Revisa los logs en Supabase: Dashboard > Edge Functions > Logs
- Verifica que los secrets esten configurados correctamente con `npx supabase secrets list`

### Problemas con Telnyx (Espana)

**La llamada no se realiza**
- Verifica que tu numero espanol este aprobado y activo (Numbers > My Numbers)
- Verifica que `TELNYX_API_KEY` sea correcta
- Verifica que el `TELNYX_TEXML_APP_ID` corresponda a tu aplicacion TeXML
- El AI Assistant debe tener STT en espanol (Deepgram nova-3)

**El numero sigue "pendiente de aprobacion"**
- Los numeros fijos espanoles requieren validacion regulatoria (2-5 dias)
- Revisa el estado en Numbers > My Numbers > Regulatory Requirements
- Si llevas mas de 5 dias, contacta soporte de Telnyx

### Problemas con Vapi (LATAM/USA)

**La llamada no se realiza**
- Verifica que tu `VAPI_API_KEY` sea correcta
- Verifica que el numero telefonico este activo en Vapi
- Revisa los logs en Supabase: Dashboard > Edge Functions > make-call > Logs

**La llamada se realiza pero no se registra el resultado**
- Verifica que la webhook URL este configurada en el assistant de Vapi
- La URL debe ser: `https://tu-proyecto.supabase.co/functions/v1/vapi-webhook`
- Revisa los logs en Supabase: Dashboard > Edge Functions > vapi-webhook > Logs

---

## Siguiente paso

Tu Colaborador Digital de Voz esta listo. Para mas detalle sobre las APIs y cuentas necesarias, consulta [apis-necesarias.md](apis-necesarias.md).
