import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import '../models/job.dart';
import 'job_detail_screen.dart';
import 'account_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final user = appState.currentUser;

    final activeTaken = appState.activeTakenJobs;
    final completedTaken = appState.completedTakenJobs;
    final activePosted = appState.activePostedJobs;
    final completedPosted = appState.completedPostedJobs;

    final reservedJobs =
        activeTaken.where((j) => j.status == JobStatus.reserved).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _header(user),

              const SizedBox(height: 20),

              // ================= PUSH TOGGLE =================

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: SwitchListTile(
                  value: user.pushNotificationsEnabled,
                  title: const Text("Få oppdrag (push varsler)"),
                  subtitle: const Text("Slå av/på varsler"),
                  onChanged: (v) {
                    appState.setPushNotifications(v);
                  },
                ),
              ),

              const SizedBox(height: 20),

              // ================= STATS =================

              Row(
                children: [
                  _statBox(
                    "Utført",
                    completedTaken.length.toString(),
                  ),
                  _statBox(
                    "Tjent",
                    "${appState.moneyEarned.toStringAsFixed(0)} kr",
                  ),
                  _statBox(
                    "Brukt",
                    "${appState.moneySpent.toStringAsFixed(0)} kr",
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ================= LIVE STATUS =================

              _statusCard(
                context,
                activeTaken: activeTaken,
                completedTaken: completedTaken,
                activePosted: activePosted,
                completedPosted: completedPosted,
                reserved: reservedJobs,
              ),

              const SizedBox(height: 20),

              // ================= INFO =================

              _infoCard(
                title: "Oppdrag",
                items: [
                  "Aktive oppdrag: ${activeTaken.length}",
                  "Fullførte oppdrag: ${completedTaken.length}",
                  "Mine aktive jobber: ${activePosted.length}",
                  "Mine fullførte jobber: ${completedPosted.length}",
                ],
              ),

              const SizedBox(height: 20),

              _settingsButton(context),
            ],
          ),
        ),
      ),
    );
  }

  // ================= HEADER =================

  Widget _header(user) {
    return Column(
      children: [
        const CircleAvatar(
          radius: 42,
          child: Icon(Icons.person, size: 40),
        ),
        const SizedBox(height: 10),

        // 🔥 NAVN
        Text(
          user.firstName,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        // 🔥 NY STATUS (HER SKAL DEN VÆRE)
        Text(
          user.wantsToWork
              ? "🟢 Klar for oppdrag"
              : "🔴 Søker hjelp",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),

        // ⭐ RATING
        Text(
          "⭐ ${user.rating.toStringAsFixed(1)} (${user.ratingCount})",
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  // ================= STAT BOX =================

  Widget _statBox(String title, String value) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  // ================= LIVE STATUS =================

  Widget _statusCard(
    BuildContext context, {
    required List<Job> activeTaken,
    required List<Job> completedTaken,
    required List<Job> activePosted,
    required List<Job> completedPosted,
    required int reserved,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Live status",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),

          _statusRow(
            context,
            icon: Icons.timer,
            color: Colors.orange,
            text: "Reserverte oppdrag",
            jobs: activeTaken
                .where((j) => j.status == JobStatus.reserved)
                .toList(),
          ),

          _statusRow(
            context,
            icon: Icons.work,
            color: Colors.blue,
            text: "Aktive oppdrag",
            jobs: activeTaken,
          ),

          _statusRow(
            context,
            icon: Icons.upload,
            color: Colors.green,
            text: "Mine aktive jobber",
            jobs: activePosted,
          ),

          _statusRow(
            context,
            icon: Icons.history,
            color: Colors.grey,
            text: "Historikk",
            jobs: completedTaken,
          ),
        ],
      ),
    );
  }

  Widget _statusRow(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String text,
    required List<Job> jobs,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => _JobListScreen(
              title: text,
              jobs: jobs,
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Expanded(child: Text(text)),
            Text(
              jobs.length.toString(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }

  // ================= INFO =================

  Widget _infoCard({
    required String title,
    required List<String> items,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          ...items.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(e),
              )),
        ],
      ),
    );
  }

  // ================= SETTINGS =================

  Widget _settingsButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AccountScreen(),
            ),
          );
        },
        child: const Text("Innstillinger"),
      ),
    );
  }
}

// ================= JOB LIST SCREEN =================

class _JobListScreen extends StatelessWidget {
  final String title;
  final List<Job> jobs;

  const _JobListScreen({
    required this.title,
    required this.jobs,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: jobs.isEmpty
          ? const Center(child: Text("Ingen oppdrag"))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: jobs.length,
              itemBuilder: (_, i) {
                final job = jobs[i];

                return ListTile(
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
                );
              },
            ),
    );
  }
}