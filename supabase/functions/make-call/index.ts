// Edge Function: make-call
// Dispara llamada via Telnyx AI (España +34) o Vapi (LATAM/USA) para confirmación de citas

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

// --- Vapi ---
const VAPI_API_KEY = Deno.env.get("VAPI_API_KEY") ?? "";
const VAPI_PHONE_NUMBER_ID = Deno.env.get("VAPI_PHONE_NUMBER_ID") ?? "";
const VAPI_ASSISTANT_ID = Deno.env.get("VAPI_ASSISTANT_ID") ?? "";

// --- Telnyx ---
const TELNYX_API_KEY = Deno.env.get("TELNYX_API_KEY") ?? "";
const TELNYX_TEXML_APP_ID = Deno.env.get("TELNYX_TEXML_APP_ID") ?? "";
const TELNYX_ASSISTANT_ID = Deno.env.get("TELNYX_ASSISTANT_ID") ?? "";
const TELNYX_FROM_NUMBER = Deno.env.get("TELNYX_FROM_NUMBER") ?? "";

// --- Supabase ---
const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

interface Contact {
  id: string;
  name: string;
  phone: string;
  appointment_date: string | null;
  company: string | null;
}

// --- Phone normalization & provider routing ---

function toE164(phone: string): string {
  return phone.replace(/[\s\-\(\)]/g, "");
}

function getProvider(phone: string): "telnyx" | "vapi" {
  const clean = toE164(phone);
  if (clean.startsWith("+34") || clean.startsWith("0034")) return "telnyx";
  return "vapi";
}

// Leer nombre del negocio de la tabla config
async function getBusinessName(): Promise<string> {
  const { data } = await supabase
    .from("config")
    .select("value")
    .eq("key", "business_name")
    .maybeSingle();
  return data?.value ?? "nuestro negocio";
}

// Formatear fecha y hora en texto puro español (evita que el LLM lea numeros en ingles)
function formatAppointment(dateStr: string | null): { date: string; time: string } {
  if (!dateStr) return { date: "fecha por confirmar", time: "hora por confirmar" };
  const d = new Date(dateStr);

  const dias = ["domingo", "lunes", "martes", "miércoles", "jueves", "viernes", "sábado"];
  const meses = ["enero", "febrero", "marzo", "abril", "mayo", "junio",
    "julio", "agosto", "septiembre", "octubre", "noviembre", "diciembre"];

  const dia = dias[d.getUTCDay()];
  const num = d.getUTCDate();
  const mes = meses[d.getUTCMonth()];
  const date = `${dia} ${num} de ${mes}`;

  const hours = d.getUTCHours();
  const minutes = d.getUTCMinutes();
  const periodo = hours >= 12 ? "de la tarde" : "de la mañana";
  const hora12 = hours > 12 ? hours - 12 : hours === 0 ? 12 : hours;
  const time = minutes === 0
    ? `${hora12} ${periodo}`
    : `${hora12} y ${minutes} ${periodo}`;

  return { date, time };
}

// --- Provider-specific call functions ---

async function callVapi(contact: Contact, businessName: string): Promise<{ callId: string; provider: "vapi" }> {
  const { date, time } = formatAppointment(contact.appointment_date);

  const res = await fetch("https://api.vapi.ai/call", {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${VAPI_API_KEY}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      assistantId: VAPI_ASSISTANT_ID,
      phoneNumberId: VAPI_PHONE_NUMBER_ID,
      customer: {
        number: contact.phone,
        name: contact.name,
      },
      assistantOverrides: {
        variableValues: {
          business_name: businessName,
          contact_name: contact.name,
          appointment_date: date,
          appointment_time: time,
        },
      },
    }),
  });

  if (!res.ok) {
    const error = await res.text();
    throw new Error(`Vapi API error: ${res.status} - ${error}`);
  }

  const data = await res.json();
  return { callId: data.id, provider: "vapi" };
}

async function callTelnyx(contact: Contact, businessName: string): Promise<{ callId: string; provider: "telnyx" }> {
  const { date, time } = formatAppointment(contact.appointment_date);

  const res = await fetch(`https://api.telnyx.com/v2/texml/ai_calls/${TELNYX_TEXML_APP_ID}`, {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${TELNYX_API_KEY}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      From: TELNYX_FROM_NUMBER,
      To: toE164(contact.phone),
      AIAssistantId: TELNYX_ASSISTANT_ID,
      AIAssistantDynamicVariables: {
        contact_name: contact.name.split(" ")[0],
        appointment_date: date,
        appointment_time: time,
        business_name: businessName,
      },
    }),
  });

  if (!res.ok) {
    const error = await res.text();
    throw new Error(`Telnyx AI error: ${res.status} — ${error}`);
  }

  const data = await res.json();
  const callSid = data.data?.call_sid ?? data.call_sid ?? data.data?.id ?? data.id;
  return { callId: callSid, provider: "telnyx" };
}

// --- Unified trigger ---

async function triggerCall(contact: Contact, businessName: string): Promise<{ callId: string; provider: "vapi" | "telnyx" }> {
  const provider = getProvider(contact.phone);
  if (provider === "telnyx" && TELNYX_API_KEY) {
    return callTelnyx(contact, businessName);
  }
  return callVapi(contact, businessName);
}

// --- Main handler ---

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Método no permitido" }), {
      status: 405, headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  // Validate that at least one provider is configured
  const hasVapi = !!(VAPI_API_KEY && VAPI_ASSISTANT_ID);
  const hasTelnyx = !!(TELNYX_API_KEY && TELNYX_TEXML_APP_ID && TELNYX_ASSISTANT_ID);

  if (!hasVapi && !hasTelnyx) {
    return new Response(JSON.stringify({ error: "Ningún proveedor de voz configurado. Configura VAPI_API_KEY o TELNYX_API_KEY con sus respectivos secrets." }), {
      status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
    return new Response(JSON.stringify({ error: "Secrets de Supabase no configurados. Ejecuta: npx supabase secrets set SUPABASE_URL=... SUPABASE_SERVICE_ROLE_KEY=..." }), {
      status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  try {
    const body = await req.json();
    const businessName = await getBusinessName();

    // Modo batch: llamar a todos los contactos pendientes
    if (body.batch === true) {
      const { data: contacts, error } = await supabase
        .from("contacts")
        .select("id, name, phone, appointment_date, company, call_count")
        .eq("status", "pending");

      if (error) throw error;
      if (!contacts || contacts.length === 0) {
        return new Response(JSON.stringify({ message: "No hay contactos pendientes" }), {
          status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      const results = [];
      for (const contact of contacts) {
        try {
          const result = await triggerCall(contact, businessName);

          // Registrar inicio en call_logs
          await supabase.from("call_logs").insert({
            contact_id: contact.id,
            vapi_call_id: result.callId,
            call_provider: result.provider,
            started_at: new Date().toISOString(),
            status: "in_progress",
          });

          // Actualizar contacto
          await supabase
            .from("contacts")
            .update({
              last_called_at: new Date().toISOString(),
              call_count: (contact.call_count ?? 0) + 1,
              updated_at: new Date().toISOString(),
            })
            .eq("id", contact.id);

          results.push({ contact_id: contact.id, call_id: result.callId, call_provider: result.provider, status: "initiated" });
        } catch (err) {
          results.push({ contact_id: contact.id, status: "failed", error: (err as Error).message });
        }
      }

      return new Response(JSON.stringify({ results }), {
        status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Modo individual: llamar a un contacto específico
    if (!body.contact_id) {
      return new Response(JSON.stringify({ error: "Se requiere contact_id o batch: true" }), {
        status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const { data: contact, error } = await supabase
      .from("contacts")
      .select("id, name, phone, appointment_date, company, call_count")
      .eq("id", body.contact_id)
      .maybeSingle();

    if (error) throw error;
    if (!contact) {
      return new Response(JSON.stringify({ error: "Contacto no encontrado" }), {
        status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const result = await triggerCall(contact, businessName);

    // Registrar inicio en call_logs
    await supabase.from("call_logs").insert({
      contact_id: contact.id,
      vapi_call_id: result.callId,
      call_provider: result.provider,
      started_at: new Date().toISOString(),
      status: "in_progress",
    });

    // Actualizar contacto
    await supabase
      .from("contacts")
      .update({
        last_called_at: new Date().toISOString(),
        call_count: (contact.call_count ?? 0) + 1,
        updated_at: new Date().toISOString(),
      })
      .eq("id", contact.id);

    return new Response(
      JSON.stringify({ contact_id: contact.id, call_id: result.callId, call_provider: result.provider, status: "initiated" }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err) {
    return new Response(
      JSON.stringify({ error: (err as Error).message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
