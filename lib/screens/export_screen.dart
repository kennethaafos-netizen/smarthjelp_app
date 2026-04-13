import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import '../models/job.dart';

class ExportScreen extends StatelessWidget {
  const ExportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    final earnedJobs = appState.completedTakenJobs;
    final spentJobs = appState.completedPostedJobs;

    final totalEarned =
        earnedJobs.fold<double>(0, (sum, j) => sum + j.price);
    final totalSpent =
        spentJobs.fold<double>(0, (sum, j) => sum + j.price);

    return Scaffold(
      appBar: AppBar(title: const Text("Skatterapport")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _summaryCard(totalEarned, totalSpent),

            const SizedBox(height: 20),

            Expanded(
              child: ListView(
                children: [
                  _section("📥 Inntekt", earnedJobs),
                  const SizedBox(height: 20),
                  _section("📤 Kostnader", spentJobs),
                ],
              ),
            ),

            const SizedBox(height: 12),

            FilledButton(
              onPressed: () {
                _exportText(context, earnedJobs, spentJobs);
              },
              child: const Text("Eksporter (kopier)"),
            )
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(double earned, double spent) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _stat("Tjent", "${earned.toStringAsFixed(0)} kr"),
          _stat("Brukt", "${spent.toStringAsFixed(0)} kr"),
          _stat("Resultat", "${(earned - spent).toStringAsFixed(0)} kr"),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label),
      ],
    );
  }

  Widget _section(String title, List<Job> jobs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 10),
        ...jobs.map((j) => ListTile(
              title: Text(j.title),
              subtitle: Text(j.locationName),
              trailing: Text("${j.price} kr"),
            )),
      ],
    );
  }

  void _exportText(
      BuildContext context, List<Job> earned, List<Job> spent) {
    final buffer = StringBuffer();

    buffer.writeln("SMART HJELP RAPPORT");
    buffer.writeln("");

    buffer.writeln("INNTEKT:");
    for (var j in earned) {
      buffer.writeln("${j.title} - ${j.price} kr");
    }

    buffer.writeln("");
    buffer.writeln("KOSTNADER:");
    for (var j in spent) {
      buffer.writeln("${j.title} - ${j.price} kr");
    }

    buffer.writeln("");
    buffer.writeln("TOTALT TJENT: ${earned.fold(0, (s, j) => s + j.price)} kr");
    buffer.writeln("TOTALT BRUKT: ${spent.fold(0, (s, j) => s + j.price)} kr");

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Kopier rapport"),
        content: SingleChildScrollView(
          child: Text(buffer.toString()),
        ),
      ),
    );
  }
}