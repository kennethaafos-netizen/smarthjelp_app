import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/job.dart';
import '../providers/app_state.dart';
import '../widgets/job_card.dart';
import '../widgets/reserved_timer.dart';
import 'job_detail_screen.dart';

class MyJobsScreen extends StatelessWidget {
  const MyJobsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    final activeTaken = appState.activeTakenJobs;
    final completedTaken = appState.completedTakenJobs;
    final activePosted = appState.activePostedJobs;
    final completedPosted = appState.completedPostedJobs;

    return Scaffold(
      appBar: AppBar(title: const Text("Mine oppdrag")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle("📥 Oppdrag jeg tar"),
          _jobList(
            context,
            activeTaken,
            appState,
            allowComplete: true,
            allowCancelReservation: true,
          ),

          _sectionTitle("✅ Fullført (jeg gjorde)"),
          _jobList(context, completedTaken, appState),

          _sectionTitle("📤 Mine oppdrag"),
          _jobList(
            context,
            activePosted,
            appState,
            allowReopen: true,
          ),

          _sectionTitle("🏁 Fullført (mine)"),
          _jobList(context, completedPosted, appState),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _jobList(
    BuildContext context,
    List<Job> jobs,
    AppState appState, {
    bool allowComplete = false,
    bool allowReopen = false,
    bool allowCancelReservation = false,
  }) {
    if (jobs.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Text("Ingen oppdrag"),
      );
    }

    return Column(
      children: jobs.map((job) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// 🔥 JOB CARD + BADGE
            Stack(
              children: [
                JobCard(
                  job: job,
                  distanceText: job.locationName,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => JobDetailScreen(job: job),
                      ),
                    );
                  },
                ),

                if (job.status == JobStatus.reserved)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        "Reservert",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            /// 🔥 TIMER (FULL FIX)
            if (job.status == JobStatus.reserved &&
                job.reservedUntil != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ReservedTimer(
                  jobId: job.id,
                  reservedUntil: job.reservedUntil!,
                ),
              ),

            /// 🔥 ACTION BUTTONS
            Row(
              children: [
                if (allowComplete &&
                    job.status == JobStatus.inProgress)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        appState.completeJob(job.id);
                      },
                      child: const Text("Fullfør"),
                    ),
                  ),

                if (allowCancelReservation &&
                    job.status == JobStatus.reserved)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        appState.releaseJob(job.id);
                      },
                      child: const Text("Avbryt"),
                    ),
                  ),

                if (allowReopen &&
                    job.status == JobStatus.completed)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        appState.addJob(
                          title: job.title,
                          description: job.description,
                          price: job.price,
                          category: job.category,
                          locationName: job.locationName,
                          lat: job.lat,
                          lng: job.lng,
                          imageUrl: job.imageUrl,
                        );
                      },
                      child: const Text("Publiser igjen"),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),
          ],
        );
      }).toList(),
    );
  }
}