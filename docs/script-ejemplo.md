# Ejemplo de Script de Conversación

Este documento muestra cómo funciona el script que el Colaborador Digital de Voz usa durante las llamadas, y cómo personalizarlo.

---

## Script por defecto

El colaborador usa el siguiente prompt para guiar la conversación con cada contacto:

### Mensaje inicial
> "Hola, le llamo de parte de **[nombre del negocio]**. ¿Me permite un momento?"

### Instrucciones del sistema
El colaborador sigue estas reglas durante la conversación:

1. **Habla siempre en español**
2. Se presenta como colaborador de tu negocio
3. Confirma la cita mencionando fecha y hora
4. Tono profesional, natural, sin frases robóticas
5. Máximo 2 minutos por llamada

---

## Flujos de conversación

### Flujo 1 — El contacto confirma

```
Colaborador: "Hola Juan, le llamo de parte de Clínica Dental Sonrisa.
              Le contacto para confirmar su cita programada para el
              jueves 20 de marzo de 2026 a las 10 de la mañana.
              ¿Podemos confirmar esta cita?"

Contacto:    "Sí, ahí estaré."

Colaborador: "Perfecto, queda confirmada su cita para el jueves 20 de marzo
              de 2026 a las 10 de la mañana. ¡Muchas gracias y que tenga
              excelente día!"
```

**Resultado registrado:** `confirmed`

---

### Flujo 2 — El contacto quiere reprogramar

```
Colaborador: "Hola María, le llamo de parte de Consultorio Legal Torres.
              Le contacto para confirmar su cita programada para el
              lunes 24 de marzo de 2026 a las 3 de la tarde.
              ¿Podemos confirmar esta cita?"

Contacto:    "Ese día no puedo, ¿se puede cambiar?"

Colaborador: "¡Claro! ¿Qué fecha y hora le funcionaría mejor?"

Contacto:    "El miércoles en la mañana, como a las 11."

Colaborador: "Tomaré nota de su preferencia para el miércoles por la mañana
              a las 11. Nos pondremos en contacto para confirmar la nueva
              fecha. ¡Gracias!"
```

**Resultado registrado:** `rescheduled`

---

### Flujo 3 — El contacto cancela

```
Colaborador: "Hola Carlos, le llamo de parte de Gimnasio FitPro.
              Le contacto para confirmar su cita de evaluación programada
              para el viernes 21 de marzo de 2026 a las 5 de la tarde.
              ¿Podemos confirmar esta cita?"

Contacto:    "No, ya no voy a poder ir. Cancélame por favor."

Colaborador: "Entiendo. ¿Me podría compartir brevemente el motivo?"

Contacto:    "Se me complicó con el trabajo."

Colaborador: "Agradezco su tiempo. Si en el futuro desea agendar
              nuevamente, no dude en contactarnos. ¡Que tenga buen día!"
```

**Resultado registrado:** `cancelled`

---

### Flujo 4 — No contesta / buzón de voz

Si el contacto no contesta la llamada, el sistema registra automáticamente:

**Resultado registrado:** `no_answer`

---

## Variables del script

El script usa 4 variables que se reemplazan automáticamente con los datos de cada contacto:

| Variable | Se reemplaza con | Ejemplo |
|---|---|---|
| `{{business_name}}` | Nombre del negocio (tabla `config`) | "Clínica Dental Sonrisa" |
| `{{contact_name}}` | Nombre del contacto | "Juan Pérez" |
| `{{appointment_date}}` | Fecha de la cita (formato largo) | "jueves 20 de marzo de 2026" |
| `{{appointment_time}}` | Hora de la cita (formato hablado) | "10 de la mañana", "3 y 30 de la tarde" |

---

## Personalizar el script

Para modificar el script de conversación, tienes dos opciones:

### Opción 1: Desde el código
Edita el archivo `src/call-script.ts` y modifica la constante `SYSTEM_PROMPT`. Luego redespliega las funciones.

### Opción 2: Desde Vapi Dashboard
1. Ve a [dashboard.vapi.ai](https://dashboard.vapi.ai)
2. Entra a **Assistants** > "Confirmacion de Citas"
3. Modifica el **System Prompt** directamente
4. Los cambios se aplican inmediatamente (no necesitas redesplegar)

---

## Consejos para personalizar

- **Mantén el tono natural** — evita frases como "soy un asistente virtual" o "soy una inteligencia artificial"
- **Sé breve** — las llamadas más efectivas duran menos de 2 minutos
- **Incluye el nombre del contacto** — genera confianza y reduce los cuelgues
- **No agregues demasiadas opciones** — el flujo debe ser simple: confirmar, reprogramar o cancelar
- **Prueba con tu propio número** antes de llamar a clientes reales
