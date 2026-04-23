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
          'beskrivelse, pris og adresse, og trykk «Legg ut». Oppdraget '
          'blir umiddelbart synlig for andre brukere i nærheten.',
    ),
    _FaqItem(
      question: 'Hvordan tar jeg et oppdrag?',
      answer:
          'Gå til fanen «Oppdrag», velg et åpent oppdrag og trykk på '
          '«Ta oppdraget». Når du har tatt et oppdrag får du tilgang '
          'til chat med oppdragsgiver.',
    ),
    _FaqItem(
      question: 'Når får jeg betalt?',
      answer:
          'Betaling utløses når oppdragsgiver har godkjent utført '
          'arbeid. Du vil se status på betaling i oppdragsdetaljene.',
    ),
    _FaqItem(
      question: 'Kan jeg avbryte et oppdrag jeg har tatt?',
      answer:
          'Ja. Gå til oppdraget og trykk «Avbryt reservasjon». '
          'Oppdraget blir da åpnet igjen for andre hjelpere.',
    ),
    _FaqItem(
      question: 'Hvordan fungerer rating?',
      answer:
          'Etter et fullført oppdrag kan oppdragsgiver og hjelper '
          'vurdere hverandre med 1–5 stjerner. Gjennomsnittet vises '
          'på profilen din.',
    ),
    _FaqItem(
      question: 'Hva betyr «Verifisert»-merket?',
      answer:
          'Verifiserte brukere har bekreftet identiteten sin. Dette '
          'gir økt tillit i markedsplassen. Verifisering gjøres av '
          'SmartHjelp-teamet.',
    ),
    _FaqItem(
      question: 'Er chatten privat?',
      answer:
          'Ja. Meldinger mellom deg og motparten er kun synlige for '
          'dere to og er knyttet til det spesifikke oppdraget.',
    ),
    _FaqItem(
      question: 'Hvordan kontakter jeg support?',
      answer:
          'Gå til «Kontakt oss» i menyen under avataren din øverst '
          'til høyre. Der finner du e-postadressen vår.',
    ),
  ];

  final Set<int> _expanded = {};

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
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
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
