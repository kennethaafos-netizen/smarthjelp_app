import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';

class ExportScreen extends StatelessWidget {
  const ExportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: const Text('Eksporter regnskap')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Regnskapsoversikt',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text('Penger tjent: ${appState.moneyEarned.toStringAsFixed(0)} kr'),
                const SizedBox(height: 8),
                Text('Penger brukt: ${appState.moneySpent.toStringAsFixed(0)} kr'),
                const SizedBox(height: 8),
                Text('Utførte oppdrag: ${appState.completedTakenJobs.length}'),
                const Spacer(),
                FilledButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Eksport kommer i neste steg'),
                      ),
                    );
                  },
                  child: const Text('Eksporter'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}