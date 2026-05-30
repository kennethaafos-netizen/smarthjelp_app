import 'package:flutter/material.dart';

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  static const Color _primary = Color(0xFF2356E8);
  static const Color _bg = Color(0xFFF4F7FC);
  static const Color _textPrimary = Color(0xFF0F1E3A);
  static const Color _textMuted = Color(0xFF6E7A90);

  static const List<_FaqItem> _items = [
    _FaqItem(
      question: 'Hvordan legger jeg ut et oppdrag?',
      answer:
          'Trykk på plussknappen nederst i menyen. Fyll inn tittel, '
          'beskrivelse, pris, kategori og postnummer/kommune, og velg '
          'reservasjonstid (Vanlig 30 min eller Haste 10 min). Trykk '
          '«Publiser» — oppdraget er umiddelbart synlig for andre brukere '
          'i området.',
    ),
    _FaqItem(
      question: 'Hvordan tar jeg et oppdrag?',
      answer:
          'Gå til fanen «Oppdrag», velg et åpent oppdrag og trykk på '
          '«Ta jobb». Oppdraget blir låst til deg i reservasjonstiden, '
          'og du får tilgang til chat med oppdragsgiver.',
    ),
    _FaqItem(
      question: 'Hva betyr «Vanlig» og «Haste» reservasjonstid?',
      answer:
          'Reservasjonstiden bestemmer hvor lenge oppdraget er låst til '
          'den som tar det. «Vanlig» = 30 minutter, «Haste» = 10 minutter. '
          'Det er ikke en frist for å fullføre selve jobben — kun en frist '
          'for å bekrefte oppdraget før det åpnes igjen for andre.',
    ),
    _FaqItem(
      question: 'Når får jeg betalt?',
      answer:
          'Beløpet holdes trygt av SmartHjelp etter at oppdraget er '
          'reservert. Utbetaling utløses når oppdragsgiver har godkjent '
          'utført arbeid. Status vises i oppdragsdetaljene.',
    ),
    _FaqItem(
      question: 'Hvordan håndteres betaling og plattformavgift?',
      answer:
          'Som oppdragsgiver betaler du oppdragsprisen + 10 % '
          'plattformavgift (inkl. mva). Som utfører får du hele '
          'oppdragsprisen — du betaler ikke plattformavgift selv. '
          'Beløpet holdes trygt til oppdragsgiver godkjenner utført '
          'arbeid.',
    ),
    _FaqItem(
      question: 'Kan jeg avbryte et oppdrag jeg har tatt?',
      answer:
          'Ja. Gå til oppdraget og trykk «Avbryt reservasjon». '
          'Oppdraget blir da åpnet igjen for andre. Etter at oppdraget '
          'er bekreftet, må begge parter godkjenne avbrytelsen.',
    ),
    _FaqItem(
      question: 'Hvordan fungerer rating?',
      answer:
          'Etter et fullført og godkjent oppdrag kan oppdragsgiver og '
          'utfører vurdere hverandre med 1–5 stjerner. Gjennomsnittet '
          'vises på profilen.',
    ),
    _FaqItem(
      question: 'Hva betyr «Verifisert» i appen i dag?',
      answer:
          'I dag betyr «Verifisert» / «E-post bekreftet» kun at brukeren '
          'har bekreftet e-postadressen sin. Det er ikke en '
          'identitetsverifisering. BankID-verifisering er ikke aktivert '
          'ennå — vi sier ifra i appen når funksjonen er klar.',
    ),
    _FaqItem(
      question: 'Hva er Trust-merkene mine?',
      answer:
          'Trust-merkene er små pills på profilen som viser hva som er '
          'oppfylt: «E-post bekreftet», «Profil utfylt» (telefon + '
          'område) og antall fullførte oppdrag. Når alle tre er oppfylt '
          'vises en ekstra grønn «Pålitelig bruker»-pille.',
    ),
    _FaqItem(
      question: 'Når kommer BankID-verifisering?',
      answer:
          'BankID-verifisering er planlagt, men ikke aktivert ennå. Når '
          'den lanseres kan du bekrefte identiteten din via BankID. '
          'Inntil videre betyr «Verifisert» kun e-post-bekreftelse.',
    ),
    _FaqItem(
      question: 'Hvor finner jeg skatterapporten min?',
      answer:
          'Gå til «Min side» → «Eksporter rapport». Velg år og last ned '
          'en Excel-fil med oversikt over inntekter, utgifter og '
          'plattformavgift fra fullførte og godkjente oppdrag i '
          'SmartHjelp.',
    ),
    _FaqItem(
      question: 'Er SmartHjelp ansvarlig for skatt eller rapportering?',
      answer:
          'Nei. SmartHjelp er en plattform som kobler oppdragsgivere og '
          'utførere. Vi rapporterer ikke inntekt, utgifter eller skatt på '
          'dine vegne, og gir ikke skatte-, juridisk eller '
          'regnskapsmessig rådgivning. Du er selv ansvarlig for '
          'skattemelding og rapportering. Sjekk Skatteetaten eller '
          'kontakt regnskapsfører ved tvil.',
    ),
    _FaqItem(
      question: 'Småjobb-regelen / 6 000 kr-grensen?',
      answer:
          'Småjobber i private hjem/fritidsbolig kan være skattefrie '
          'inntil 6 000 kr per kalenderår fra samme oppdragsgiver/'
          'husstand til samme person, hvis vilkårene er oppfylt. Hvis '
          'grensen overskrides, kan hele beløpet fra den oppdragsgiveren '
          'bli skattepliktig. Dette er ikke skatterådgivning — '
          'kontroller hos Skatteetaten.',
    ),
    _FaqItem(
      question: 'Er chatten privat?',
      answer:
          'Ja. Meldinger mellom deg og motparten er knyttet til ett '
          'spesifikt oppdrag og er kun synlige for dere to.',
    ),
    _FaqItem(
      question: 'Hvordan slette konto eller hente ut data?',
      answer:
          'Send en henvendelse via «Kontakt oss». Vi behandler '
          'forespørselen så snart som mulig.',
    ),
    _FaqItem(
      question: 'Hvordan kontakter jeg support?',
      answer:
          'Trykk på avataren din øverst til høyre på Hjem-skjermen og '
          'velg «Kontakt oss». Du kan også finne «Hjelp & info» nederst '
          'på «Min side».',
    ),
  ];

  final Set<int> _expanded = {};

  // Rolig info-callout øverst på FAQ. Gjør ansvarsforholdet tydelig
  // før brukeren scroller gjennom spørsmålene. Ingen tax/legal-råd.
  Widget _callout() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _primary.withValues(alpha: 0.22), width: 1),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: _primary, size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'SmartHjelp er en plattform som kobler oppdragsgivere og '
              'utførere. Vi gir ikke skatte- eller juridisk rådgivning. '
              'Du er selv ansvarlig for skattemelding og rapportering.',
              style: TextStyle(
                color: _textPrimary,
                fontWeight: FontWeight.w600,
                height: 1.35,
                fontSize: 12.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        foregroundColor: _textPrimary,
        title: const Text(
          'Ofte stilte spørsmål',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: _textPrimary,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Til hjem',
            icon: const Icon(Icons.home_rounded),
            onPressed: () =>
                Navigator.of(context).popUntil((r) => r.isFirst),
          ),
        ],
      ),
      body: Column(
        children: [
          _callout(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                final isOpen = _expanded.contains(index);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _FaqCard(
                    item: item,
                    isOpen: isOpen,
                    onToggle: () {
                      setState(() {
                        if (isOpen) {
                          _expanded.remove(index);
                        } else {
                          _expanded.add(index);
                        }
                      });
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqItem {
  final String question;
  final String answer;
  const _FaqItem({required this.question, required this.answer});
}

class _FaqCard extends StatelessWidget {
  final _FaqItem item;
  final bool isOpen;
  final VoidCallback onToggle;

  const _FaqCard({
    required this.item,
    required this.isOpen,
    required this.onToggle,
  });

  static const Color _primary = Color(0xFF2356E8);
  static const Color _textPrimary = Color(0xFF0F1E3A);
  static const Color _textMuted = Color(0xFF6E7A90);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onToggle,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _textMuted.withOpacity(0.12)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.question,
                      style: const TextStyle(
                        color: _textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 14.5,
                        height: 1.35,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: isOpen ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: const Icon(
                      Icons.expand_more_rounded,
                      color: _primary,
                    ),
                  ),
                ],
              ),
              AnimatedCrossFade(
                crossFadeState: isOpen
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 180),
                firstChild: const SizedBox(width: double.infinity),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: 10, right: 6),
                  child: Text(
                    item.answer,
                    style: const TextStyle(
                      color: _textMuted,
                      fontWeight: FontWeight.w500,
                      fontSize: 13.5,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
