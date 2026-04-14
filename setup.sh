#!/bin/bash
# =============================================================
# COLABORADOR DIGITAL DE VOZ — Script de instalación asistida
# Template open-source para tu propio colaborador digital
# =============================================================

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Helpers
ok()   { echo -e "${GREEN}✓${NC} $1"; }
info() { echo -e "${BLUE}→${NC} $1"; }
warn() { echo -e "${YELLOW}⚠${NC}  $1"; }
err()  { echo -e "${RED}✗${NC} $1"; }
ask()  { echo -e "${CYAN}?${NC}  $1"; }

header() {
  echo ""
  echo -e "${BOLD}${BLUE}══════════════════════════════════════════${NC}"
  echo -e "${BOLD}${BLUE}  $1${NC}"
  echo -e "${BOLD}${BLUE}══════════════════════════════════════════${NC}"
  echo ""
}

# =============================================================
# BIENVENIDA
# =============================================================

clear
echo ""
echo -e "${BOLD}╔════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║   COLABORADOR DIGITAL DE VOZ               ║${NC}"
echo -e "${BOLD}║   Instalación asistida                     ║${NC}"
echo -e "${BOLD}╚════════════════════════════════════════════╝${NC}"
echo ""
echo "Este script te guiará paso a paso para instalar y configurar"
echo "tu colaborador digital de voz en menos de 10 minutos."
echo ""

# =============================================================
# SELECCIÓN DE REGIÓN
# =============================================================

echo -e "${BOLD}¿Dónde están tus contactos?${NC}"
echo ""
echo "  1. ${BOLD}España${NC} (+34) — usa Telnyx (número fijo local, cumple regulación)"
echo "  2. ${BOLD}LATAM / USA${NC} — usa Vapi + Twilio"
echo "  3. ${BOLD}Ambos${NC} — configura los dos proveedores"
echo ""
read -p "Elige una opción (1/2/3): " REGION

case "$REGION" in
  1) REGION_NAME="España"; USE_TELNYX=true; USE_VAPI=false ;;
  2) REGION_NAME="LATAM / USA"; USE_TELNYX=false; USE_VAPI=true ;;
  3) REGION_NAME="Ambos"; USE_TELNYX=true; USE_VAPI=true ;;
  *) err "Opción no válida"; exit 1 ;;
esac

ok "Región seleccionada: $REGION_NAME"

echo ""
echo -e "${YELLOW}Antes de empezar necesitas tener creadas las cuentas en:${NC}"
echo "  1. Supabase  → https://supabase.com  (gratis)"
if [ "$USE_TELNYX" = true ]; then
  echo "  2. Telnyx    → https://telnyx.com    (registro gratuito)"
fi
if [ "$USE_VAPI" = true ]; then
  echo "  2. Vapi.ai   → https://vapi.ai       (tiene plan gratuito)"
fi
echo ""
read -p "¿Ya tienes las cuentas creadas? (s/n): " READY
if [[ "$READY" != "s" && "$READY" != "S" ]]; then
  echo ""
  echo "Perfecto. Crea las cuentas primero y luego vuelve a ejecutar este script."
  echo "Lee docs/apis-necesarias.md para saber exactamente qué necesitas."
  exit 0
fi

# =============================================================
# PASO 1 — VERIFICAR DEPENDENCIAS
# =============================================================

header "PASO 1 — Verificando dependencias"

if command -v node &>/dev/null; then
  NODE_VERSION=$(node -v)
  ok "Node.js $NODE_VERSION encontrado"
else
  err "Node.js no encontrado. Instálalo desde https://nodejs.org (versión 18 o superior)"
  exit 1
fi

if command -v npm &>/dev/null; then
  ok "npm encontrado"
else
  err "npm no encontrado. Se instala junto con Node.js"
  exit 1
fi

if command -v git &>/dev/null; then
  ok "Git encontrado"
else
  err "Git no encontrado. Instálalo desde https://git-scm.com"
  exit 1
fi

if command -v curl &>/dev/null; then
  ok "curl encontrado"
else
  err "curl no encontrado. Es necesario para la instalación."
  exit 1
fi

echo ""
ok "Todas las dependencias están instaladas"

# =============================================================
# PASO 2 — INSTALAR DEPENDENCIAS DEL PROYECTO
# =============================================================

header "PASO 2 — Instalando dependencias del proyecto"

if [ ! -f "package.json" ]; then
  err "No se encontró package.json. Ejecuta este script desde la raíz del proyecto."
  exit 1
fi

info "Instalando dependencias (puede tomar 30-60 segundos)..."
npm install --silent
ok "Dependencias instaladas"

# =============================================================
# PASO 3 — CREDENCIALES DE SUPABASE
# =============================================================

header "PASO 3 — Configuración de Supabase"

echo "Abre tu proyecto en https://supabase.com/dashboard"
echo ""
echo -e "${YELLOW}Necesitas 3 datos:${NC}"
echo "  • Project URL      → Settings > API > Project URL"
echo "  • Service Role Key → Settings > API > service_role (clave secreta)"
echo "  • Access Token     → supabase.com > Account > Access Tokens"
echo ""

ask "Pega tu Supabase Project URL (ej: https://abcdefgh.supabase.co):"
read -r SUPABASE_URL
SUPABASE_URL=$(echo "$SUPABASE_URL" | xargs)

if [[ ! "$SUPABASE_URL" =~ ^https://.*\.supabase\.co$ ]]; then
  warn "La URL no parece correcta. Debe tener el formato: https://xxxxxxxx.supabase.co"
  ask "¿Continuar de todas formas? (s/n):"
  read -r CONTINUE
  if [[ "$CONTINUE" != "s" && "$CONTINUE" != "S" ]]; then exit 1; fi
fi

PROJECT_REF=$(echo "$SUPABASE_URL" | sed 's/https:\/\///' | sed 's/\.supabase\.co//')
ok "Project ref detectado: $PROJECT_REF"

ask "Pega tu Supabase Service Role Key (empieza con eyJ...):"
read -r SUPABASE_SERVICE_ROLE_KEY
SUPABASE_SERVICE_ROLE_KEY=$(echo "$SUPABASE_SERVICE_ROLE_KEY" | xargs)

if [[ ! "$SUPABASE_SERVICE_ROLE_KEY" =~ ^eyJ ]]; then
  warn "Asegúrate de copiar la 'service_role', no la 'anon key'."
fi

ask "Pega tu Supabase Access Token (para el CLI):"
read -r SUPABASE_ACCESS_TOKEN
SUPABASE_ACCESS_TOKEN=$(echo "$SUPABASE_ACCESS_TOKEN" | xargs)

ask "Pega el password de tu base de datos Supabase:"
read -rs SUPABASE_DB_PASSWORD
echo ""

ok "Credenciales de Supabase guardadas"

# =============================================================
# PASO 4 — CREDENCIALES DE PROVEEDOR DE VOZ
# =============================================================

if [ "$USE_TELNYX" = true ]; then
  header "PASO 4 — Configuración de Telnyx (España)"

  echo "Abre tu cuenta en https://telnyx.com > Mission Control"
  echo ""
  echo -e "${YELLOW}Necesitas 4 datos:${NC}"
  echo "  • API Key           → Auth > API Keys"
  echo "  • TeXML App ID      → Voice > TeXML > Applications > tu app > ID"
  echo "  • AI Assistant ID   → AI > Assistants > tu assistant > ID"
  echo "  • Número español    → Numbers > tu número aprobado (+34...)"
  echo ""

  ask "Pega tu Telnyx API Key:"
  read -r TELNYX_API_KEY
  TELNYX_API_KEY=$(echo "$TELNYX_API_KEY" | xargs)

  ask "Pega tu TeXML App ID:"
  read -r TELNYX_TEXML_APP_ID
  TELNYX_TEXML_APP_ID=$(echo "$TELNYX_TEXML_APP_ID" | xargs)

  ask "Pega tu AI Assistant ID de Telnyx:"
  read -r TELNYX_ASSISTANT_ID
  TELNYX_ASSISTANT_ID=$(echo "$TELNYX_ASSISTANT_ID" | xargs)

  ask "Pega tu número fijo español (ej: +34910XXXXXX):"
  read -r TELNYX_FROM_NUMBER
  TELNYX_FROM_NUMBER=$(echo "$TELNYX_FROM_NUMBER" | xargs)

  ok "Credenciales de Telnyx guardadas"
fi

if [ "$USE_VAPI" = true ]; then
  header "PASO 4 — Configuración de Vapi (LATAM/USA)"

  echo "Abre tu cuenta en https://dashboard.vapi.ai"
  echo ""
  echo -e "${YELLOW}Necesitas 2 datos (el assistant se crea automáticamente):${NC}"
  echo "  • API Key          → Organization > API Keys"
  echo "  • Phone Number ID  → Phone Numbers > tu número > UUID"
  echo ""

  ask "Pega tu Vapi API Key:"
  read -r VAPI_API_KEY
  VAPI_API_KEY=$(echo "$VAPI_API_KEY" | xargs)

  ask "Pega el Phone Number ID de Vapi (UUID del número):"
  read -r VAPI_PHONE_NUMBER_ID
  VAPI_PHONE_NUMBER_ID=$(echo "$VAPI_PHONE_NUMBER_ID" | xargs)

  ok "Credenciales de Vapi guardadas"
fi

# =============================================================
# PASO 5 — NOMBRE DEL NEGOCIO
# =============================================================

header "PASO 5 — Configuración del negocio"

ask "¿Cómo se llama tu negocio? (el asistente se presentará con este nombre):"
read -r BUSINESS_NAME
BUSINESS_NAME=$(echo "$BUSINESS_NAME" | xargs)

ok "Nombre del negocio: $BUSINESS_NAME"

# =============================================================
# PASO 6 — CREAR ASSISTANT EN VAPI (solo si USA/LATAM)
# =============================================================

if [ "$USE_VAPI" = true ]; then
  header "PASO 6 — Creando el assistant en Vapi"

  info "Creando assistant 'Confirmacion de Citas' en tu cuenta de Vapi..."

  WEBHOOK_URL="${SUPABASE_URL}/functions/v1/vapi-webhook"

  VAPI_RESPONSE=$(curl -s -X POST "https://api.vapi.ai/assistant" \
    -H "Authorization: Bearer $VAPI_API_KEY" \
    -H "Content-Type: application/json" \
    -d "{
      \"name\": \"Confirmacion de Citas\",
      \"model\": {
        \"provider\": \"openai\",
        \"model\": \"gpt-4o-mini\",
        \"temperature\": 0.3,
        \"maxTokens\": 100,
        \"messages\": [{
          \"role\": \"system\",
          \"content\": \"Eres un colaborador digital profesional que llama en nombre de {{business_name}} para confirmar citas programadas. INSTRUCCIONES: Habla siempre en español. Preséntate como colaborador de {{business_name}}. Confirma la cita: fecha {{appointment_date}} a las {{appointment_time}}. Si el contacto confirma: agradece y despídete cordialmente. Si quiere reprogramar: pregunta nueva fecha y hora preferida. Si cancela: pregunta brevemente el motivo y despídete. Tono profesional, natural, sin frases robóticas. Sé conciso, la llamada no debe durar más de 2 minutos. El nombre del contacto es {{contact_name}}. EJEMPLO DE INICIO: Hola {{contact_name}}, le llamo de parte de {{business_name}}. Le contacto para confirmar su cita programada para el {{appointment_date}} a las {{appointment_time}}. ¿Podemos confirmar esta cita? REGLAS DE CONVERSACIÓN: 1. Si confirma: Perfecto, queda confirmada su cita para el {{appointment_date}} a las {{appointment_time}}. Muchas gracias y que tenga excelente día. 2. Si quiere reprogramar: ¿Qué fecha y hora le funcionaría mejor? Tomaré nota de su preferencia. Nos pondremos en contacto para confirmar la nueva fecha. 3. Si cancela: Entiendo. ¿Me podría compartir brevemente el motivo? Agradezco su tiempo. Si en el futuro desea agendar nuevamente, no dude en contactarnos. 4. Si no entiende o está confundido: aclara quién llama y el propósito de la llamada. 5. Si pide hablar con alguien más: Con gusto, le pediremos a alguien del equipo que se comunique con usted.\"
        }]
      },
      \"voice\": {
        \"provider\": \"11labs\",
        \"voiceId\": \"pFZP5JQG7iQjIQuC4Bku\",
        \"language\": \"es\",
        \"optimizeStreamingLatency\": 4,
        \"stability\": 0.5,
        \"similarityBoost\": 0.75
      },
      \"transcriber\": {
        \"provider\": \"deepgram\",
        \"model\": \"nova-3\",
        \"language\": \"es\",
        \"endpointing\": 200
      },
      \"serverUrl\": \"$WEBHOOK_URL\",
      \"responseDelaySeconds\": 0.2,
      \"llmRequestDelaySeconds\": 0.1,
      \"silenceTimeoutSeconds\": 15,
      \"maxDurationSeconds\": 120,
      \"numWordsToInterruptAssistant\": 1,
      \"backgroundDenoisingEnabled\": true
    }")

  VAPI_ASSISTANT_ID=$(echo "$VAPI_RESPONSE" | grep -o '"id":"[^"]*"' | head -1 | sed 's/"id":"//;s/"//')

  if [ -z "$VAPI_ASSISTANT_ID" ]; then
    err "No se pudo crear el assistant en Vapi."
    echo "Respuesta de Vapi: $VAPI_RESPONSE"
    echo ""
    warn "Crea el assistant manualmente en https://dashboard.vapi.ai y pega el ID aquí:"
    read -r VAPI_ASSISTANT_ID
  else
    ok "Assistant creado: $VAPI_ASSISTANT_ID"
  fi
else
  info "Usando Telnyx AI Assistant (ya configurado en tu cuenta de Telnyx)"
  VAPI_ASSISTANT_ID=""
  WEBHOOK_URL=""
fi

# =============================================================
# PASO 7 — CREAR ARCHIVO .env
# =============================================================

header "PASO 7 — Creando archivo .env"

cat > .env << EOF
# Generado por setup.sh — $(date)
# Región: $REGION_NAME

SUPABASE_URL=$SUPABASE_URL
SUPABASE_SERVICE_ROLE_KEY=$SUPABASE_SERVICE_ROLE_KEY
EOF

if [ "$USE_TELNYX" = true ]; then
  cat >> .env << EOF

# España (Telnyx)
TELNYX_API_KEY=$TELNYX_API_KEY
TELNYX_TEXML_APP_ID=$TELNYX_TEXML_APP_ID
TELNYX_ASSISTANT_ID=$TELNYX_ASSISTANT_ID
TELNYX_FROM_NUMBER=$TELNYX_FROM_NUMBER
EOF
fi

if [ "$USE_VAPI" = true ]; then
  cat >> .env << EOF

# LATAM / USA (Vapi)
VAPI_API_KEY=$VAPI_API_KEY
VAPI_PHONE_NUMBER_ID=$VAPI_PHONE_NUMBER_ID
VAPI_ASSISTANT_ID=$VAPI_ASSISTANT_ID
WEBHOOK_URL=$WEBHOOK_URL
EOF
fi

ok "Archivo .env creado"

# =============================================================
# PASO 8 — DESPLEGAR TABLAS EN SUPABASE
# =============================================================

header "PASO 8 — Creando tablas en Supabase"

info "Conectando con Supabase (puede tomar 15-30 segundos)..."
set +e
LINK_OUTPUT=$(SUPABASE_ACCESS_TOKEN=$SUPABASE_ACCESS_TOKEN \
SUPABASE_DB_PASSWORD=$SUPABASE_DB_PASSWORD \
npx supabase link --project-ref "$PROJECT_REF" 2>&1)
LINK_EXIT=$?
set -e

echo "$LINK_OUTPUT" | grep -v "^$"

if [ $LINK_EXIT -ne 0 ]; then
  echo ""
  echo "❌ Error al conectar con Supabase. Verifica:"
  echo "   - Que el Project Ref es correcto"
  echo "   - Que el Access Token es válido"
  echo "   - Que el DB Password es correcto"
  exit 1
fi

info "Ejecutando migración (puede tomar 15-30 segundos)..."
set +e
SUPABASE_ACCESS_TOKEN=$SUPABASE_ACCESS_TOKEN \
SUPABASE_DB_PASSWORD=$SUPABASE_DB_PASSWORD \
npx supabase db push 2>&1
DB_EXIT=$?
set -e

if [ $DB_EXIT -ne 0 ]; then
  echo ""
  echo "❌ Error al crear las tablas. Verifica tu conexión a Supabase."
  exit 1
fi

ok "Tablas creadas: contacts, call_logs, config"

# =============================================================
# PASO 9 — DESPLEGAR EDGE FUNCTIONS
# =============================================================

header "PASO 9 — Desplegando Edge Functions"

info "Desplegando make-call (puede tomar 20-40 segundos)..."
set +e
DEPLOY_OUTPUT=$(SUPABASE_ACCESS_TOKEN=$SUPABASE_ACCESS_TOKEN \
npx supabase functions deploy make-call --no-verify-jwt 2>&1)
DEPLOY_EXIT=$?
set -e
echo "$DEPLOY_OUTPUT" | tail -3
if [ $DEPLOY_EXIT -ne 0 ]; then
  err "No se pudo desplegar make-call. Verifica tu Access Token."
  exit 1
fi

info "Desplegando vapi-webhook (puede tomar 20-40 segundos)..."
set +e
DEPLOY_OUTPUT=$(SUPABASE_ACCESS_TOKEN=$SUPABASE_ACCESS_TOKEN \
npx supabase functions deploy vapi-webhook --no-verify-jwt 2>&1)
DEPLOY_EXIT=$?
set -e
echo "$DEPLOY_OUTPUT" | tail -3
if [ $DEPLOY_EXIT -ne 0 ]; then
  err "No se pudo desplegar vapi-webhook. Verifica tu Access Token."
  exit 1
fi

ok "Edge Functions desplegadas"

# =============================================================
# PASO 10 — CONFIGURAR SECRETS EN SUPABASE
# =============================================================

header "PASO 10 — Configurando secrets en Supabase"

SECRETS_CMD="SUPABASE_URL=$SUPABASE_URL SUPABASE_SERVICE_ROLE_KEY=$SUPABASE_SERVICE_ROLE_KEY"

if [ "$USE_TELNYX" = true ]; then
  SECRETS_CMD="$SECRETS_CMD TELNYX_API_KEY=$TELNYX_API_KEY TELNYX_TEXML_APP_ID=$TELNYX_TEXML_APP_ID TELNYX_ASSISTANT_ID=$TELNYX_ASSISTANT_ID TELNYX_FROM_NUMBER=$TELNYX_FROM_NUMBER"
fi

if [ "$USE_VAPI" = true ]; then
  SECRETS_CMD="$SECRETS_CMD VAPI_API_KEY=$VAPI_API_KEY VAPI_PHONE_NUMBER_ID=$VAPI_PHONE_NUMBER_ID VAPI_ASSISTANT_ID=$VAPI_ASSISTANT_ID"
fi

set +e
eval SUPABASE_ACCESS_TOKEN=$SUPABASE_ACCESS_TOKEN npx supabase secrets set $SECRETS_CMD 2>&1
SECRETS_EXIT=$?
set -e

if [ $SECRETS_EXIT -ne 0 ]; then
  echo ""
  echo "❌ Error al configurar secrets. Verifica tu Access Token."
  exit 1
fi

ok "Secrets configurados"

# =============================================================
# PASO 11 — NOMBRE DEL NEGOCIO EN BASE DE DATOS
# =============================================================

header "PASO 11 — Configurando nombre del negocio"

CONFIG_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -X POST "${SUPABASE_URL}/rest/v1/config" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json" \
  -H "apikey: $SUPABASE_SERVICE_ROLE_KEY" \
  -d "$(printf '{"key": "business_name", "value": "%s"}' "$BUSINESS_NAME")")

if [ "$CONFIG_RESPONSE" = "201" ] || [ "$CONFIG_RESPONSE" = "200" ]; then
  ok "Nombre '$BUSINESS_NAME' guardado en la base de datos"
else
  warn "No se pudo guardar el nombre del negocio (HTTP $CONFIG_RESPONSE)"
fi

# =============================================================
# PASO 12 — CONTACTO DE PRUEBA
# =============================================================

header "PASO 12 — Contacto de prueba"

echo "Para verificar que todo funciona, añadiremos un contacto de prueba."
echo ""
ask "Nombre del contacto de prueba:"
read -r TEST_NAME

echo ""
echo -e "${YELLOW}Formato del teléfono (con código de país):${NC}"
if [ "$USE_TELNYX" = true ]; then
  echo "  Ejemplo España: +34612345678"
fi
if [ "$USE_VAPI" = true ]; then
  echo "  Ejemplo México: +521234567890"
  echo "  Ejemplo USA: +11234567890"
fi
echo ""
ask "Teléfono:"
read -r TEST_PHONE

ask "Fecha de la cita (formato: 2026-04-01 10:00:00+00):"
read -r TEST_DATE

CONTACT_HTTP_CODE=$(curl -s -w "\n%{http_code}" -X POST "${SUPABASE_URL}/rest/v1/contacts" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json" \
  -H "apikey: $SUPABASE_SERVICE_ROLE_KEY" \
  -H "Prefer: return=representation" \
  -d "$(printf '{"name": "%s", "phone": "%s", "appointment_date": "%s", "status": "pending"}' "$TEST_NAME" "$TEST_PHONE" "$TEST_DATE")")

CONTACT_RESPONSE=$(echo "$CONTACT_HTTP_CODE" | sed '$d')
CONTACT_STATUS=$(echo "$CONTACT_HTTP_CODE" | tail -1)
CONTACT_ID=$(echo "$CONTACT_RESPONSE" | grep -o '"id":"[^"]*"' | head -1 | sed 's/"id":"//;s/"//')

if [ -n "$CONTACT_ID" ]; then
  ok "Contacto creado: $CONTACT_ID"
elif [ "$CONTACT_STATUS" = "201" ] || [ "$CONTACT_STATUS" = "200" ]; then
  warn "Contacto creado pero no se pudo extraer el ID. Verifica en Supabase Table Editor."
else
  warn "No se pudo crear el contacto (HTTP $CONTACT_STATUS). Créalo en Supabase Table Editor."
fi

# =============================================================
# RESUMEN FINAL
# =============================================================

header "¡INSTALACIÓN COMPLETADA!"

echo -e "${GREEN}${BOLD}Tu Colaborador Digital de Voz está listo.${NC}"
echo ""
echo -e "${BOLD}Resumen:${NC}"
echo "  • Región:     $REGION_NAME"
echo "  • Supabase:   $SUPABASE_URL"
if [ "$USE_TELNYX" = true ]; then
  echo "  • Telnyx:     $TELNYX_FROM_NUMBER (España)"
fi
if [ "$USE_VAPI" = true ]; then
  echo "  • Vapi:       $VAPI_ASSISTANT_ID"
  echo "  • Webhook:    $WEBHOOK_URL"
fi
echo "  • Negocio:    $BUSINESS_NAME"
echo ""

if [ -n "$CONTACT_ID" ]; then
  echo -e "${BOLD}Primera llamada de prueba:${NC}"
  echo ""
  echo "  curl -X POST ${SUPABASE_URL}/functions/v1/make-call \\"
  echo "    -H 'Content-Type: application/json' \\"
  echo "    -d '{\"contact_id\": \"$CONTACT_ID\"}'"
  echo ""
fi

echo -e "${BOLD}Comandos útiles:${NC}"
echo ""
echo "  # Llamar a todos los contactos pendientes:"
echo "  curl -X POST ${SUPABASE_URL}/functions/v1/make-call \\"
echo "    -H 'Content-Type: application/json' \\"
echo "    -d '{\"batch\": true}'"
echo ""
echo "  # Ver logs en tiempo real:"
echo "  npx supabase functions logs make-call --tail"
echo "  npx supabase functions logs vapi-webhook --tail"
echo ""
echo -e "${YELLOW}Cualquier duda: lee docs/manual-instalacion.md${NC}"
echo ""
echo -e "${BOLD}${GREEN}¡Tu colaborador ya puede hacer llamadas!${NC}"
echo ""
