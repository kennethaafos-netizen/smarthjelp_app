-- SmartHjelp: persistert postnummer på jobs.
--
-- Bakgrunn: PostJobScreen samler i dag inn postnummer for å derive
-- kommunen lokalt (range-tabell 3700-3999 → Skien/Siljan/Porsgrunn/
-- Bamble), men selve postnummeret kastes etter beregning. UI viser
-- derfor bare kommune ("Skien") og ikke "3724 Skien". Ved å persistere
-- postnummeret kan både jobbkort og detaljskjerm vise nøyaktig sted
-- uten geocoding eller ekstra avhengigheter.
--
-- Trygt/reverserbart og additivt:
--  * IF NOT EXISTS gjør at re-kjøring ikke feiler.
--  * Ingen NOT NULL og ingen default → eksisterende jobber får NULL og
--    oppfører seg nøyaktig som før. Klienten faller tilbake til kun
--    kommune-navn for NULL/tomt postnummer.
--  * Ingen RLS-, FK- eller policy-endringer. Klient-koden trenger
--    INSERT/UPDATE-rettighet på `jobs` allerede; den nye kolonnen er
--    automatisk dekket av eksisterende policies.
--  * MÅ kjøres FØR (eller samtidig med) at den nye klienten distribueres
--    siden klienten begynner å sende `postal_code` i insert/update.
--    Klienten er bakoverkompatibel hvis migrasjonen ikke er kjørt:
--    Job-modellen behandler manglende kolonne som NULL.

ALTER TABLE public.jobs
  ADD COLUMN IF NOT EXISTS postal_code text NULL;

-- Rollback (manuelt ved behov):
--   ALTER TABLE public.jobs DROP COLUMN IF EXISTS postal_code;
