// UI UPGRADE: premium polish, hierarchy, spacing, and clearer navigation
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/job.dart';
import '../providers/app_state.dart';
import '../widgets/job_card.dart';
import '../widgets/reserved_timer.dart';
import 'job_detail_screen.dart';

const Color _primary = Color(0xFF2356E8);
const Color _accent = Color(0xFF18B7A6);
const Color _bg = Color(0xFFF4F7FC);
const Color _textPrimary = Color(0xFF0F1E3A);
const Color _textMuted = Color(0xFF6E7A90);

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
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Mine oppdrag',
          style: TextStyle(
            color: _textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 22,
          ),
        ),
        iconTheme: const IconThemeData(color: _textPrimary),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          _sectionHeader('Oppdrag jeg tar', Icons.download_rounded,
              count: activeTaken.length),
          const SizedBox(height: 12),
          _jobList(
            context,
            activeTaken,
            appState,
            allowComplete: true,
            allowCancelReservation: true,
          ),
          const SizedBox(height: 24),
          _sectionHeader('Fullført (jeg gjorde)', Icons.check_circle_outline,
              count: completedTaken.length),
          const SizedBox(height: 12),
          _jobList(context, completedTaken, appState),
          const SizedBox(height: 24),
          _sectionHeader('Mine oppdrag', Icons.upload_rounded,
              count: activePosted.length),
          const SizedBox(height: 12),
          _jobList(
            context,
            activePosted,
            appState,
            allowReopen: true,
          ),
          const SizedBox(height: 24),
          _sectionHeader('Fullført (mine)', Icons.flag_outlined,
              count: completedPosted.length),
          const SizedBox(height: 12),
          _jobList(context, completedPosted, appState),
        ],
      ),
    );
  }

  Widget _sectionHeader(String text, IconData icon, {int? count}) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4F7BFF), _accent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: _textPrimary,
              letterSpacing: -0.2,
            ),
          ),
        ),
        if (count != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: _primary,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _emptyBox(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _bg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.inbox_outlined,
                color: _textMuted, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: _textMuted,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),
        ],
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
      return _emptyBox('Ingen oppdrag her akkurat nå.');
    }

    return Column(
      children: jobs.map((job) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
              if (job.status == JobStatus.reserved &&
                  job.reservedUntil != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: ReservedTimer(
                    jobId: job.id,
                    reservedUntil: job.reservedUntil!,
                  ),
                ),
              if (_hasAction(
                job,
                allowComplete: allowComplete,
                allowReopen: allowReopen,
                allowCancelReservation: allowCancelReservation,
              ))
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Row(
                    children: [
                      if (allowComplete &&
                          job.status == JobStatus.inProgress &&
                          !job.isCompletedByWorker)
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              appState.completeJob(job.id);
                            },
                            icon: const Icon(Icons.check_rounded, size: 18),
                            label: const Text('Fullfør'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                      if (allowCancelReservation &&
                          job.status == JobStatus.reserved)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              appState.releaseJob(job.id);
                            },
                            icon: const Icon(Icons.close_rounded, size: 18),
                            label: const Text('Avbryt'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFDC2626),
                              side: const BorderSide(
                                  color: Color(0x55DC2626)),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              textStyle: const TextStyle(
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      if (allowReopen && job.status == JobStatus.completed)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final ok = await appState.addJob(
                                title: job.title,
                                description: job.description,
                                price: job.price,
                                category: job.category,
                                locationName: job.locationName,
                                lat: job.lat,
                                lng: job.lng,
                                imageUrl: job.imageUrl,
                              );
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    ok
                                        ? 'Oppdraget ble publisert på nytt.'
                                        : 'Kunne ikke publisere oppdraget på nytt.',
                                  ),
                                ),
                              );
                            },
                            icon:
                                const Icon(Icons.refresh_rounded, size: 18),
                            label: const Text('Publiser igjen'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _primary,
                              side: BorderSide(
                                  color: _primary.withOpacity(0.35)),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              textStyle: const TextStyle(
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  bool _hasAction(
    Job job, {
    required bool allowComplete,
    required bool allowReopen,
    required bool allowCancelReservation,
  }) {
    if (allowComplete &&
        job.status == JobStatus.inProgress &&
        !job.isCompletedByWorker) {
      return true;
    }
    if (allowCancelReservation && job.status == JobStatus.reserved) {
      return true;
    }
    if (allowReopen && job.status == JobStatus.completed) {
      return true;
    }
    return false;
  }
}
