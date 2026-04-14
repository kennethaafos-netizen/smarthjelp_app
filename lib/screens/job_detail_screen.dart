import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/job.dart';
import '../providers/app_state.dart';
import 'chat_screen.dart';

class JobDetailScreen extends StatelessWidget {
  final Job job;

  const JobDetailScreen({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final currentJob = appState.jobs.firstWhere((j) => j.id == job.id);

    final isOwner = currentJob.createdByUserId == appState.currentUser.id;
    final isWorker = currentJob.acceptedByUserId == appState.currentUser.id;
    final cancelRequestedByOther =
        currentJob.cancelRequestedByUserId != null &&
            currentJob.cancelRequestedByUserId != appState.currentUser.id;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      body: SafeArea(
        child: Column(
          children: [
            _header(context, currentJob),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _infoCard(currentJob),
                  const SizedBox(height: 16),
                  _paymentCard(currentJob, isOwner),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            _bottomActions(
              context,
              currentJob,
              isOwner,
              isWorker,
              cancelRequestedByOther,
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context, Job job) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
          ),
          Expanded(
            child: Text(
              job.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            "${job.price} kr",
            style: const TextStyle(
              color: Color(0xFF18B7A6),
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(Job job) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            job.category,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(job.description),
          const SizedBox(height: 10),
          Text(job.locationName, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _paymentCard(Job job, bool isOwner) {
    final statusText = !job.isPaymentReserved
        ? "Venter på start"
        : !job.isCompletedByWorker
            ? "Jobb pågår"
            : !job.isApprovedByOwner
                ? "Venter på godkjenning"
                : "Fullført";

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Betaling",
              style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          if (isOwner) ...[
            Text("Du betaler: ${job.totalPrice.toStringAsFixed(0)} kr"),
            Text("Gebyr: ${job.fee.toStringAsFixed(0)} kr"),
            Text("Utbetaling: ${job.payout.toStringAsFixed(0)} kr"),
          ] else ...[
            Text("Du får: ${job.payout.toStringAsFixed(0)} kr"),
          ],
          const SizedBox(height: 8),
          Text(
            statusText,
            style: TextStyle(
              color: job.isApprovedByOwner ? Colors.green : Colors.orange,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomActions(
    BuildContext context,
    Job job,
    bool isOwner,
    bool isWorker,
    bool cancelRequestedByOther,
  ) {
    final appState = context.read<AppState>();

    // 🔥 KEY FIX
    final showChat = job.acceptedByUserId != null;

    Widget chatButton = Expanded(
      child: OutlinedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatScreen(job: job),
            ),
          );
        },
        icon: const Icon(Icons.chat_bubble_outline),
        label: const Text("Chat"),
      ),
    );

    Widget mainWithChat(String text, VoidCallback onTap) {
      if (!showChat) {
        return _mainButton(text, onTap);
      }

      return Row(
        children: [
          chatButton,
          const SizedBox(width: 10),
          Expanded(child: _mainButton(text, onTap)),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          // 🔵 OPEN
          if (job.status == JobStatus.open)
            _mainButton(
              "Ta jobb",
              () => appState.reserveJob(job.id),
            ),

          // 🟠 RESERVED
          if (job.status == JobStatus.reserved && isWorker) ...[
            mainWithChat(
              "Start jobb",
              () => appState.startJob(job.id),
            ),
            const SizedBox(height: 10),
            _dangerButton(
              "Avbryt",
              () => _cancelDialog(context, job),
            ),
          ],

          // 🔵 IN PROGRESS
          if (job.status == JobStatus.inProgress &&
              isWorker &&
              !job.isCompletedByWorker) ...[
            mainWithChat(
              "Fullfør",
              () => appState.completeJobByWorker(job.id),
            ),
            const SizedBox(height: 10),
            _dangerButton(
              cancelRequestedByOther
                  ? "Godkjenn avbrytelse"
                  : "Be om avbrytelse",
              () {
                if (cancelRequestedByOther) {
                  appState.approveCancel(job.id);
                } else {
                  _cancelDialog(context, job);
                }
              },
            ),
          ],

          // 🟢 OWNER
          if (job.status == JobStatus.inProgress &&
              job.isCompletedByWorker &&
              isOwner) ...[
            mainWithChat(
              "Godkjenn betaling",
              () async {
                appState.approveAndReleasePayment(job.id);
                await _showRatingPopup(context, job.acceptedByUserId);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _mainButton(String text, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(onPressed: onTap, child: Text(text)),
    );
  }

  Widget _dangerButton(String text, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
        child: Text(text),
      ),
    );
  }

  void _cancelDialog(BuildContext context, Job job) {
    final appState = context.read<AppState>();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Avbryt oppdrag"),
        content: const Text("Er du sikker?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Nei")),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              appState.cancelJob(job.id);
            },
            child: const Text("Ja"),
          ),
        ],
      ),
    );
  }

  Future<void> _showRatingPopup(
      BuildContext context, String? userId) async {
    if (userId == null) return;

    double rating = 5;

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setLocalState) {
          return AlertDialog(
            title: const Text("Gi vurdering"),
            content: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final star = index + 1;
                return IconButton(
                  onPressed: () {
                    setLocalState(() => rating = star.toDouble());
                  },
                  icon: Icon(
                    Icons.star,
                    color: star <= rating ? Colors.orange : Colors.grey,
                  ),
                );
              }),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Senere"),
              ),
              FilledButton(
                onPressed: () {
                  context.read<AppState>().rateUser(
                        userId: userId,
                        newRating: rating,
                      );
                  Navigator.pop(context);
                },
                child: const Text("Send"),
              ),
            ],
          );
        },
      ),
    );
  }
}