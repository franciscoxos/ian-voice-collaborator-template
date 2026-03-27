// Edge Function: vapi-webhook
// Recibe resultado de Vapi al terminar llamada y actualiza la base de datos

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const VAPI_AUTH_TOKEN = Deno.env.get("VAPI_AUTH_TOKEN") ?? "";

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

// Mapear status de Vapi a nuestro status de contacto
function mapResultToContactStatus(result: string | null): string {
  switch (result) {
    case "confirmed": return "confirmed";
    case "rescheduled": return "rescheduled";
    case "cancelled": return "cancelled";
    default: return "pending";
  }
}

// Mapear end reason de Vapi a nuestro status de call_log
function mapEndReason(endedReason: string | null, status: string | null): string {
  if (endedReason === "customer-did-not-answer" || endedReason === "no-answer") return "no_answer";
  if (endedReason === "customer-busy" || endedReason === "busy") return "busy";
  if (endedReason === "voicemail") return "voicemail";
  if (status === "ended" || endedReason === "assistant-ended-call" || endedReason === "customer-ended-call") return "completed";
  return "failed";
}

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Método no permitido" }), { status: 405 });
  }

  // Optional webhook authentication — if VAPI_AUTH_TOKEN is set, validate it
  if (VAPI_AUTH_TOKEN) {
    const authHeader = req.headers.get("authorization") || "";
    const token = authHeader.replace("Bearer ", "");
    if (token !== VAPI_AUTH_TOKEN) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { "Content-Type": "application/json" },
      });
    }
  }

  try {
    const payload = await req.json();
    const messageType = payload.message?.type ?? payload.type;

    // Solo procesamos el evento de fin de llamada
    if (messageType !== "end-of-call-report") {
      return new Response(JSON.stringify({ message: "Evento ignorado", type: messageType }), { status: 200 });
    }

    const message = payload.message ?? payload;
    const vapiCallId = message.call?.id ?? message.callId;
    const endedReason = message.endedReason ?? message.call?.endedReason;
    const transcript = message.transcript ?? message.artifact?.transcript ?? null;
    const summary = message.summary ?? message.artifact?.summary ?? null;
    const startedAt = message.call?.startedAt ?? message.startedAt ?? null;
    const endedAt = message.call?.endedAt ?? message.endedAt ?? null;

    // Calcular duración
    let durationSeconds: number | null = null;
    if (startedAt && endedAt) {
      durationSeconds = Math.round((new Date(endedAt).getTime() - new Date(startedAt).getTime()) / 1000);
    }

    // Extraer resultado y sentimiento del analysis de Vapi
    const analysis = message.analysis ?? message.artifact?.analysis ?? {};
    const result = analysis.structuredData?.result ?? analysis.result ?? null;
    const sentiment = analysis.structuredData?.sentiment ?? analysis.sentiment ?? null;

    const callStatus = mapEndReason(endedReason, message.call?.status);

    // Buscar el call_log existente por vapi_call_id
    const { data: existingLog, error: fetchError } = await supabase
      .from("call_logs")
      .select("id, contact_id")
      .eq("vapi_call_id", vapiCallId)
      .maybeSingle();
    if (fetchError) console.error("[vapi-webhook] DB fetch error:", fetchError.message);

    if (existingLog) {
      // Actualizar call_log existente
      const { error: updateError } = await supabase
        .from("call_logs")
        .update({
          ended_at: endedAt,
          duration_seconds: durationSeconds,
          status: callStatus,
          transcript: transcript,
          summary: summary,
          result: result,
          sentiment: sentiment,
          metadata: message,
        })
        .eq("id", existingLog.id);
      if (updateError) console.error("[vapi-webhook] DB update error:", updateError.message);

      // Actualizar status del contacto si la llamada se completó con resultado
      if (result && existingLog.contact_id) {
        const { error: contactUpdateError } = await supabase
          .from("contacts")
          .update({
            status: mapResultToContactStatus(result),
            updated_at: new Date().toISOString(),
          })
          .eq("id", existingLog.contact_id);
        if (contactUpdateError) console.error("[vapi-webhook] Contact update error:", contactUpdateError.message);
      }

      // Si no hubo respuesta, marcar contacto como no_answer
      if (callStatus === "no_answer" && existingLog.contact_id) {
        const { error: noAnswerError } = await supabase
          .from("contacts")
          .update({
            status: "no_answer",
            updated_at: new Date().toISOString(),
          })
          .eq("id", existingLog.contact_id);
        if (noAnswerError) console.error("[vapi-webhook] No-answer update error:", noAnswerError.message);
      }
    } else {
      // No encontramos call_log previo — insertar nuevo registro
      // Try to find the contact from existing call_logs with same vapi_call_id pattern
      // or from the webhook payload metadata
      const contactId = message.call?.metadata?.contact_id
        ?? message.metadata?.contact_id
        ?? null;

      const { error: insertError } = await supabase.from("call_logs").insert({
        vapi_call_id: vapiCallId,
        contact_id: contactId,
        started_at: startedAt,
        ended_at: endedAt,
        duration_seconds: durationSeconds,
        status: callStatus,
        transcript: transcript,
        summary: summary,
        result: result,
        sentiment: sentiment,
        metadata: message,
      });
      if (insertError) console.error("[vapi-webhook] DB insert error:", insertError.message);
    }

    return new Response(JSON.stringify({ success: true, vapi_call_id: vapiCallId }), { status: 200 });
  } catch (err) {
    return new Response(JSON.stringify({ error: (err as Error).message }), { status: 500 });
  }
});
