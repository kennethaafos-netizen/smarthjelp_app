import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import 'job_detail_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    final active = appState.activeTakenJobs;
    final completed = appState.completedTakenJobs;

    return Scaffold(
      appBar: AppBar(title: const Text("Min side")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 🔥 HEADER
          Text(
            appState.currentUser.firstName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text("⭐ ${appState.currentUser.rating.toStringAsFixed(1)}"),

          const SizedBox(height: 20),

          // 🔥 PUSH TOGGLE (det du ba om)
          SwitchListTile(
            value: appState.currentUser.pushNotificationsEnabled,
            title: const Text("Få oppdrag (push)"),
            onChanged: (v) {
              appState.setPushNotifications(v);
            },
          ),

          const SizedBox(height: 20),

          // 🔥 AKTIVE
          const Text(
            "Aktive oppdrag",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),

          ...active.map((job) => ListTile(
                title: Text(job.title),
                subtitle: Text("${job.price} kr"),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => JobDetailScreen(job: job),
                    ),
                  );
                },
              )),

          const SizedBox(height: 20),

          // 🔥 HISTORIKK
          const Text(
            "Historikk",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),

          ...completed.map((job) => ListTile(
                title: Text(job.title),
                subtitle: Text("${job.price} kr"),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => JobDetailScreen(job: job),
                    ),
                  );
                },
              )),
        ],
      ),
    );
  }
}