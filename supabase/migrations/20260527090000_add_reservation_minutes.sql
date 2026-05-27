-- SmartHjelp: 10/30-min reservasjonskonsept
-- Legger til reservation_minutes på jobs. Eies av oppdragsgiver ved
-- publisering: 30 = vanlig (default), 10 = haste. Styrer hvor lenge et
-- oppdrag er låst til den som reserverer det (reserved_at + minutter),
-- IKKE hvor raskt jobben må gjøres.
--
-- Trygt/reverserbart og additivt:
--  * IF NOT EXISTS gjør at re-kjøring ikke feiler.
--  * NOT NULL DEFAULT 30 → alle eksisterende rader får 30, identisk med
--    dagens hardkodede oppførsel. Ingen backfill nødvendig.
--  * MÅ kjøres FØR den nye klienten distribueres, siden klienten begynner
--    å sende reservation_minutes i insert/update av jobber.

ALTER TABLE public.jobs
  ADD COLUMN IF NOT EXISTS reservation_minutes integer NOT NULL DEFAULT 30;

-- MVP: kun 10 eller 30 er gyldige verdier. NOT VALID gjør at constrainten
-- kun gjelder nye/endrede rader og ikke feiler på eventuell eksisterende
-- data. Kan valideres senere med:
--   ALTER TABLE public.jobs VALIDATE CONSTRAINT jobs_reservation_minutes_chk;
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'jobs_reservation_minutes_chk'
  ) THEN
    ALTER TABLE public.jobs
      ADD CONSTRAINT jobs_reservation_minutes_chk
      CHECK (reservation_minutes IN (10, 30)) NOT VALID;
  END IF;
END $$;

-- Rollback (manuelt ved behov):
--   ALTER TABLE public.jobs DROP CONSTRAINT IF EXISTS jobs_reservation_minutes_chk;
--   ALTER TABLE public.jobs DROP COLUMN IF EXISTS reservation_minutes;
