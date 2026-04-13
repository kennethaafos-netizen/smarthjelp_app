import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/job.dart';
import '../providers/app_state.dart';
import 'account_screen.dart';
import 'job_detail_screen.dart';

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
      backgroundColor: const Color(0xFFF4F7FC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            children: [
              _header(context, user),
              const SizedBox(height: 16),
              _earningsCard(
                earned: appState.moneyEarned,
                spent: appState.moneySpent,
                completed: completedTaken.length,
              ),
              const SizedBox(height: 16),
              _switchCard(
                value: user.pushNotificationsEnabled,
                onChanged: (v) => appState.setPushNotifications(v),
              ),
              const SizedBox(height: 16),
              _section(
                title: "Live status",
                child: Column(
                  children: [
                    _statusRow(
                      context,
                      label: "Reserverte oppdrag",
                      value: reservedJobs,
                      jobs: activeTaken
                          .where((j) => j.status == JobStatus.reserved)
                          .toList(),
                      color: Colors.orange.shade50,
                    ),
                    _statusRow(
                      context,
                      label: "Oppdrag jeg tar",
                      value: activeTaken.length,
                      jobs: activeTaken,
                      color: Colors.blue.shade50,
                    ),
                    _statusRow(
                      context,
                      label: "Fullført av meg",
                      value: completedTaken.length,
                      jobs: completedTaken,
                      color: Colors.green.shade50,
                    ),
                    _statusRow(
                      context,
                      label: "Mine aktive oppdrag",
                      value: activePosted.length,
                      jobs: activePosted,
                      color: Colors.purple.shade50,
                    ),
                    _statusRow(
                      context,
                      label: "Mine fullførte oppdrag",
                      value: completedPosted.length,
                      jobs: completedPosted,
                      color: Colors.grey.shade200,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _section(
                title: "Profil",
                child: Column(
                  children: [
                    _infoRow("Navn", user.firstName),
                    _infoRow("E-post", user.email.isEmpty ? "Ikke satt" : user.email),
                    _infoRow("Telefon", user.phone.isEmpty ? "Ikke satt" : user.phone),
                    _infoRow("Område", user.preferredArea),
                    _infoRow(
                      "Vil ta oppdrag",
                      user.wantsToWork ? "Ja" : "Nei",
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 🔥 EXPORT KNAPP
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _showExportDialog(context, appState),
                  icon: const Icon(Icons.file_download_outlined),
                  label: const Text("Eksporter rapport"),
                ),
              ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AccountScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.settings_outlined),
                  label: const Text("Rediger konto"),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    context.read<AppState>().switchUser();
                  },
                  child: const Text("Bytt bruker (test)"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🔥 FIXED EXPORT (kun én versjon)
  void _showExportDialog(BuildContext context, AppState appState) {
    final now = DateTime.now();
    int selectedYear = now.year;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            final earned = appState.completedTakenJobs
                .where((j) => j.createdAt.year == selectedYear)
                .toList();

            final spent = appState.completedPostedJobs
                .where((j) => j.createdAt.year == selectedYear)
                .toList();

            final totalEarned =
                earned.fold(0, (sum, j) => sum + j.price);
            final totalSpent =
                spent.fold(0, (sum, j) => sum + j.price);

            String formatDate(DateTime d) =>
                "${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}";

            final csv = StringBuffer();

            csv.writeln("Type,Dato,Tittel,Beløp");

            for (var j in earned) {
              csv.writeln(
                  "Inntekt,${formatDate(j.createdAt)},${j.title},${j.price}");
            }

            for (var j in spent) {
              csv.writeln(
                  "Kostnad,${formatDate(j.createdAt)},${j.title},-${j.price}");
            }

            return AlertDialog(
              title: const Text("Eksporter rapport"),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButton<int>(
                      value: selectedYear,
                      items: List.generate(5, (i) => now.year - i)
                          .map((year) => DropdownMenuItem(
                                value: year,
                                child: Text("$year"),
                              ))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => selectedYear = v);
                      },
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Tjent: $totalEarned kr\nBrukt: $totalSpent kr",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "CSV (kopier til Excel/regnskapsfører):",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      height: 200,
                      child: SingleChildScrollView(
                        child: Text(
                          csv.toString(),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Lukk"),
                ),
              ],
            );
          },
        );
      },
    );
  }


  Widget _statusRow(
    BuildContext context, {
    required String label,
    required int value,
    required List<Job> jobs,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => _JobListScreen(title: label, jobs: jobs),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF172033),
                  ),
                ),
              ),
              Text(
                "$value",
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2356E8),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context, dynamic user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2356E8), Color(0xFF18B7A6)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2356E8).withOpacity(0.16),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 36),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.firstName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.wantsToWork ? "Klar for oppdrag" : "Søker hjelp",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.92),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        color: Colors.orange, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      "${user.rating.toStringAsFixed(1)} (${user.ratingCount})",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _earningsCard({
    required double earned,
    required double spent,
    required int completed,
  }) {
    return _section(
      title: "Oversikt",
      child: Row(
        children: [
          Expanded(child: _miniStat("Tjent", "${earned.toStringAsFixed(0)} kr")),
          const SizedBox(width: 10),
          Expanded(child: _miniStat("Brukt", "${spent.toStringAsFixed(0)} kr")),
          const SizedBox(width: 10),
          Expanded(child: _miniStat("Fullført", "$completed")),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FD),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF172033),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6E7A90),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _switchCard({
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return _section(
      title: "Varsler",
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        value: value,
        title: const Text(
          "Push-varsler",
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: const Text("Få beskjed når nye oppdrag dukker opp"),
        onChanged: onChanged,
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF6E7A90),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Color(0xFF172033),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section({
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF172033),
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

// 🔥 PREMIUM JOB LIST + BADGE
class _JobListScreen extends StatelessWidget {
  final String title;
  final List<Job> jobs;

  const _JobListScreen({
    required this.title,
    required this.jobs,
  });

  Widget _statusBadge(JobStatus status) {
    Color color;
    String text;

    switch (status) {
      case JobStatus.reserved:
        color = Colors.orange;
        text = "Reservert";
        break;
      case JobStatus.inProgress:
        color = Colors.blue;
        text = "Pågår";
        break;
      case JobStatus.completed:
        color = Colors.green;
        text = "Fullført";
        break;
      default:
        color = Colors.grey;
        text = "Åpen";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(title: Text(title)),
      body: jobs.isEmpty
          ? const Center(child: Text("Ingen oppdrag"))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: jobs.length,
              itemBuilder: (_, i) {
                final job = jobs[i];

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                      )
                    ],
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => JobDetailScreen(job: job),
                        ),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                job.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            _statusBadge(job.status),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(job.locationName),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("${job.price} kr"),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}