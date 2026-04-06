import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        'Hvordan legger jeg ut et oppdrag?',
        'Gå til "Legg ut jobb" og fyll inn informasjonen.'
      ),
      (
        'Hvordan tar jeg en jobb?',
        'Gå til oppdrag og trykk "Ta oppdrag".'
      ),
      (
        'Hvordan fungerer betaling?',
        'Dette kommer i senere versjon.'
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hjelp'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (_, index) {
          final item = items[index];

          return Card(
            child: ExpansionTile(
              title: Text(item.$1),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(item.$2),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}