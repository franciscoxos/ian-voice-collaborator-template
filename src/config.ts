// ─────────────────────────────────────────────────────────────
// Default configuration reference.
// These values are used as defaults by setup.sh when creating
// the Vapi assistant. Override at runtime via the `config` table
// in Supabase (key-value pairs).
//
// NOTE: This file is NOT imported by Edge Functions.
// Edge Functions read from the `config` table directly.
// ─────────────────────────────────────────────────────────────

export const DEFAULT_CONFIG = {
  // Nombre del negocio (se sobreescribe con config.business_name)
  business_name: "nuestro negocio",

  // Duración máxima de llamada en segundos
  max_duration_seconds: 120,

  // Idioma
  language: "es",

  // Voz del assistant (ElevenLabs)
  voice_provider: "11labs",
  voice_id: "pFZP5JQG7iQjIQuC4Bku", // ElevenLabs "Paula" (es-ES, female)

  // Modelo de LLM
  llm_provider: "openai",
  llm_model: "gpt-4o-mini",
} as const;

// Keys válidas para la tabla config
export type ConfigKey = keyof typeof DEFAULT_CONFIG;
