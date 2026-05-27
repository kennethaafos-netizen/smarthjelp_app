-- SmartHjelp: atomisk view-count-økning
-- Erstatter den gamle praksisen der klienten bumpet view_count via en
-- full-rad-update (som kunne overskrive samtidige endringer i status,
-- accepted_by_user_id, reserved_at osv. med utdatert lokal state).
--
-- Funksjonen gjør en server-side inkrement på KUN view_count, atomisk, så
-- ingen andre felter berøres og samtidige visninger ikke mister tellinger.
--
-- Trygt/reverserbart og additivt:
--  * CREATE OR REPLACE er idempotent (trygt å kjøre på nytt).
--  * SECURITY INVOKER (default) → kjører med kallerens rettigheter, slik at
--    eksisterende RLS på jobs fortsatt gjelder. Ingen privilegie-eskalering.
--  * Klienten har en Dart-fallback (målrettet view_count-kolonne-update),
--    så appen fungerer korrekt OGSÅ hvis denne migrasjonen ikke er kjørt.
--    IKKE anta at den er kjørt.

CREATE OR REPLACE FUNCTION public.increment_job_view_count(job_id uuid)
RETURNS void
LANGUAGE sql
AS $$
  UPDATE public.jobs
  SET view_count = COALESCE(view_count, 0) + 1
  WHERE id = job_id;
$$;

-- La innloggede brukere kalle funksjonen (samme målgruppe som tidligere
-- kunne oppdatere jobs fra klienten). Idempotent å re-kjøre.
GRANT EXECUTE ON FUNCTION public.increment_job_view_count(uuid) TO authenticated;

-- Rollback (manuelt ved behov):
--   DROP FUNCTION IF EXISTS public.increment_job_view_count(uuid);
