-- Migration: Tablas iniciales del Colaborador Digital de Voz

-- Contactos a llamar
CREATE TABLE contacts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  phone TEXT NOT NULL,
  email TEXT,
  company TEXT,
  appointment_date TIMESTAMPTZ,
  status TEXT NOT NULL DEFAULT 'pending',  -- pending, confirmed, rescheduled, no_answer, cancelled
  last_called_at TIMESTAMPTZ,
  call_count INTEGER DEFAULT 0,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Registro de cada llamada
CREATE TABLE call_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  contact_id UUID REFERENCES contacts(id) ON DELETE CASCADE,
  vapi_call_id TEXT,                -- ID de la llamada (Vapi o Telnyx)
  call_provider TEXT DEFAULT 'vapi', -- 'vapi' o 'telnyx'
  started_at TIMESTAMPTZ,
  ended_at TIMESTAMPTZ,
  duration_seconds INTEGER,
  status TEXT NOT NULL,          -- completed, no_answer, busy, failed, voicemail
  transcript TEXT,               -- transcripcion completa de Vapi
  summary TEXT,                  -- resumen generado por Vapi
  result TEXT,                   -- confirmed, rescheduled, cancelled, undecided
  sentiment TEXT,                -- positive, neutral, negative
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Configuracion del colaborador
CREATE TABLE config (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- ─────────────────────────────────────────────
-- RLS Policies
-- ─────────────────────────────────────────────
ALTER TABLE contacts ENABLE ROW LEVEL SECURITY;
ALTER TABLE call_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE config ENABLE ROW LEVEL SECURITY;

-- Service role has full access (Edge Functions use service_role key)
CREATE POLICY "service_role_all_contacts" ON contacts FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "service_role_all_call_logs" ON call_logs FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "service_role_all_config" ON config FOR ALL TO service_role USING (true) WITH CHECK (true);

-- Authenticated users can read their data (future: add user_id column for multi-tenant)
CREATE POLICY "authenticated_read_contacts" ON contacts FOR SELECT TO authenticated USING (true);
CREATE POLICY "authenticated_read_call_logs" ON call_logs FOR SELECT TO authenticated USING (true);
CREATE POLICY "authenticated_read_config" ON config FOR SELECT TO authenticated USING (true);

-- ─────────────────────────────────────────────
-- Indexes for common queries
-- ─────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_contacts_status ON contacts(status);
CREATE INDEX IF NOT EXISTS idx_contacts_phone ON contacts(phone);
CREATE INDEX IF NOT EXISTS idx_call_logs_contact_id ON call_logs(contact_id);
CREATE INDEX IF NOT EXISTS idx_call_logs_vapi_call_id ON call_logs(vapi_call_id);
CREATE INDEX IF NOT EXISTS idx_call_logs_status ON call_logs(status);
