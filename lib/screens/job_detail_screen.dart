import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/job.dart';
import '../models/user_profile.dart';
import '../providers/app_state.dart';
import '../widgets/rating_dialog.dart';
import '../widgets/reserved_timer.dart';
import 'chat_screen.dart';

class JobDetailScreen extends StatelessWidget {
  final Job job;

  const JobDetailScreen({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    appState.checkExpiredReservations();

    final currentJob =
        appState.jobs.firstWhere((j) => j.id == job.id, orElse: () => job);

    final owner = appState.getJobOwner(currentJob);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      body: Stack(
        children: [
          _headerImage(currentJob),
          _content(context, currentJob, owner),
          _topBar(context),
          _bottomCTA(context, currentJob, appState, owner),
        ],
      ),
    );
  }

  Widget _headerImage(Job currentJob) {
    if (currentJob.imageUrl != null && currentJob.imageUrl!.isNotEmpty) {
      if (currentJob.imageUrl!.startsWith("http")) {
        return Image.network(
          currentJob.imageUrl!,
          height: 280,
          width: double.infinity,
          fit: BoxFit.cover,
        );
      } else {
        return Image.file(
          File(currentJob.imageUrl!),
          height: 280,
          width: double.infinity,
          fit: BoxFit.cover,
        );
      }
    }

    return Container(
      height: 280,
      color: Colors.blue.withOpacity(0.2),
      child: const Center(
        child: Icon(Icons.work, size: 80, color: Colors.blue),
      ),
    );
  }

  Widget _content(BuildContext context, Job currentJob, UserProfile owner) {
    return Positioned.fill(
      top: 240,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Color(0xFFF6F8FC),
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: ListView(
          children: [
            _titlePrice(currentJob),
            const SizedBox(height: 12),
            _location(currentJob),
            const SizedBox(height: 12),
            if (currentJob.status == JobStatus.reserved &&
                currentJob.reservedUntil != null)
              Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ReservedTimer(job: currentJob),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            _userCard(owner),
            const SizedBox(height: 16),
            _description(currentJob),
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  Widget _titlePrice(Job currentJob) {
    return Row(
      children: [
        Expanded(
          child: Text(
            currentJob.title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF18B7A6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            "${currentJob.price} kr",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        )
      ],
    );
  }

  Widget _location(Job currentJob) {
    return Row(
      children: [
        const Icon(Icons.location_on, color: Colors.blue),
        const SizedBox(width: 6),
        Text(currentJob.locationName),
      ],
    );
  }

  Widget _userCard(UserProfile owner) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const CircleAvatar(radius: 24, child: Icon(Icons.person)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(owner.firstName),
              Text("⭐ ${owner.rating.toStringAsFixed(1)}"),
            ],
          )
        ],
      ),
    );
  }

  Widget _description(Job currentJob) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(currentJob.description),
    );
  }

  Widget _topBar(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            _circleBtn(Icons.arrow_back, () => Navigator.pop(context)),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Icon(icon),
      ),
    );
  }

  Widget _bottomCTA(
    BuildContext context,
    Job currentJob,
    AppState appState,
    UserProfile owner,
  ) {
    final canQuickTake = currentJob.status == JobStatus.open;
    final canAskFirst = currentJob.status == JobStatus.open ||
        currentJob.status == JobStatus.reserved ||
        currentJob.status == JobStatus.inProgress;

    final canComplete =
        currentJob.status == JobStatus.inProgress &&
        currentJob.acceptedByUserId == appState.currentUser.id;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(16),
        color: Colors.white,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: canAskFirst
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(job: currentJob),
                          ),
                        );
                      }
                    : null,
                child: const Text("Start chat"),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: canComplete
                    ? () async {
                        final rating = await showDialog<double>(
                          context: context,
                          builder: (_) => const RatingDialog(),
                        );

                        if (rating != null) {
                          appState.rateUser(
                            userId: owner.id,
                            newRating: rating,
                          );
                          appState.completeJob(currentJob.id);
                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                        }
                      }
                    : canQuickTake
                        ? () {
                            appState.reserveJob(currentJob.id);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatScreen(job: currentJob),
                              ),
                            );
                          }
                        : null,
                child: Text(
                  canComplete
                      ? "Fullfør jobben"
                      : canQuickTake
                          ? "Ta oppdrag"
                          : "Ikke tilgjengelig",
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}