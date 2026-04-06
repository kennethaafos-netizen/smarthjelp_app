import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/job.dart';
import '../providers/app_state.dart';
import 'job_detail_screen.dart';

class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  String selectedCategory = "Alle";

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    List<Job> jobs = appState.sortedOpenJobs;

    if (selectedCategory != "Alle") {
      jobs = jobs.where((j) => j.category == selectedCategory).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Oppdrag"),
      ),
      body: Column(
        children: [
          _categoryFilter(),
          Expanded(
            child: jobs.isEmpty
                ? const Center(child: Text("Ingen oppdrag tilgjengelig"))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: jobs.length,
                    itemBuilder: (_, i) => _jobCard(jobs[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _categoryFilter() {
    final cats = ["Alle", "Flyttehjelp", "Hagearbeid", "Rengjøring", "Annet"];

    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        children: cats.map((c) {
          final active = selectedCategory == c;

          return GestureDetector(
            onTap: () => setState(() => selectedCategory = c),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: active ? Colors.blue : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  c,
                  style: TextStyle(
                    color: active ? Colors.white : Colors.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _jobCard(Job job) {
    return GestureDetector(
      onTap: () {
        context.read<AppState>().incrementView(job.id);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => JobDetailScreen(job: job),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.work, color: Colors.blue),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(job.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(job.locationName,
                      style: TextStyle(color: Colors.grey.shade600)),
                  const SizedBox(height: 6),
                  Text("👁️ ${job.viewCount}",
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                ],
              ),
            ),
            Text("${job.price} kr",
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.green)),
          ],
        ),
      ),
    );
  }
}