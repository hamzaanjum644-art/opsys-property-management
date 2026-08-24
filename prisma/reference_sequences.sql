-- Opsys Pro — display reference generation (Decision 7)
--
-- Why sequences instead of count()+1: two tenants created at the same moment
-- would both read the same count and generate the same reference. Postgres
-- sequences are atomic and never hand out the same value twice.
--
-- Run this ONCE after `prisma migrate dev`, in the Supabase SQL Editor.

CREATE SEQUENCE IF NOT EXISTS property_ref_seq START 1;
CREATE SEQUENCE IF NOT EXISTS unit_ref_seq     START 1;
CREATE SEQUENCE IF NOT EXISTS tenant_ref_seq   START 1;

-- Helper: next_reference('PRP', 'property_ref_seq') -> 'PRP-0001'
CREATE OR REPLACE FUNCTION next_reference(prefix TEXT, seq_name TEXT)
RETURNS TEXT AS $$
DECLARE
  n BIGINT;
BEGIN
  EXECUTE format('SELECT nextval(%L)', seq_name) INTO n;
  RETURN prefix || '-' || LPAD(n::TEXT, 4, '0');
END;
$$ LANGUAGE plpgsql;