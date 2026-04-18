// lib/screens/job_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/job.dart';
import '../providers/app_state.dart';
import 'chat_screen.dart';
import 'image_viewer_screen.dart';

class JobDetailScreen extends StatefulWidget {
  final Job job;

  const JobDetailScreen({super.key, required this.job});

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final job = appState.getJobById(widget.job.id) ?? widget.job;

    final currentUser = appState.currentUser;
    final isOwner = job.createdByUserId == currentUser.id;
    final isWorker = job.acceptedByUserId == currentUser.id;

    final images = appState.getImages(job.id);

    // 🔥 EXACT vs APPROX (prepares "unlock address after accept")
    final double viewLat =
        isWorker ? job.visibleLatForReservedWorker : job.lat;
    final double viewLng =
        isWorker ? job.visibleLngForReservedWorker : job.lng;

    return Scaffold(
      appBar: AppBar(title: Text(job.title)),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(job.title,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text(job.description),
                const SizedBox(height: 20),

                // -------- BILDER --------
                if (images.isNotEmpty)
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: images.length,
                      itemBuilder: (_, i) {
                        final url = images[i];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ImageViewerScreen(
                                  imageUrls: images,
                                  initialIndex: i,
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Hero(
                              tag: url,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(url),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                const SizedBox(height: 20),

                _locationSection(job, isWorker, viewLat, viewLng),

                const SizedBox(height: 20),

                _priceSection(job, isOwner),

                const SizedBox(height: 20),
                Text('Status: ${job.status.name}'),
              ],
            ),
          ),

          _actionButtons(job, isOwner, isWorker),
        ],
      ),
    );
  }

  // ---------------- STED ----------------

  Widget _locationSection(
    Job job,
    bool isWorker,
    double viewLat,
    double viewLng,
  ) {
    final subtitle = isWorker
        ? 'Eksakt sted synlig for deg'
        : 'Omtrentlig sted før du tar oppdraget';

    return Semantics(
      label: 'Koordinater $viewLat, $viewLng',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.place_outlined, size: 18, color: Color(0xFF2356E8)),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  job.locationName,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6E7A90),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- PRIS ----------------

  Widget _priceSection(Job job, bool isOwner) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Betaling',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (isOwner) ...[
          Text('Oppdrag: ${job.price} kr'),
          Text('Plattformavgift: ${job.platformFee.toStringAsFixed(0)} kr'),
          Text('Totalt: ${job.totalPrice.toStringAsFixed(0)} kr'),
        ] else ...[
          Text('Du tjener: ${job.payout.toStringAsFixed(0)} kr'),
        ],
      ],
    );
  }

  // ---------------- ACTIONS ----------------

  Widget _actionButtons(Job job, bool isOwner, bool isWorker) {
    final appState = context.read<AppState>();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isLoading) const CircularProgressIndicator(),

            // -------- TA JOBB --------
            if (!_isLoading && job.status == JobStatus.open && !isOwner)
              _mainButton('Ta jobb', () async {
                await _runAction(() async {
                  final ok = await appState.reserveJob(job.id);
                  if (!ok) return;
                  _reload(job.id);
                });
              }),

            // -------- AVBRYT (NY LOGIKK) --------
            if (!_isLoading &&
                (isOwner || isWorker) &&
                job.status != JobStatus.completed)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _confirmCancel(job.id),
                  child: const Text('Avbryt oppdrag'),
                ),
              ),

            // -------- START --------
            if (!_isLoading &&
                job.status == JobStatus.reserved &&
                isWorker)
              _mainButton('Start jobb', () async {
                await _runAction(() async {
                  await appState.startJob(job.id);
                  _reload(job.id);
                });
              }),

            // -------- FULLFØR --------
            if (!_isLoading &&
                job.status == JobStatus.inProgress &&
                isWorker &&
                !job.isCompletedByWorker)
              _mainButton('Fullfør', () async {
                await _runAction(() async {
                  await appState.completeJobByWorker(job.id);
                  _reload(job.id);
                });
              }),

            // -------- GODKJENN --------
            if (!_isLoading &&
                job.status == JobStatus.inProgress &&
                isOwner &&
                job.isCompletedByWorker)
              _mainButton('Godkjenn og betal ut', () async {
                await _runAction(() async {
                  await appState.approveAndReleasePayment(job.id);
                  _reload(job.id);
                });
              }),

            const SizedBox(height: 10),

            // -------- CHAT --------
            if (job.acceptedByUserId != null)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Åpne chat'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(job: job),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ---------------- CONFIRM DIALOG ----------------

  Future<void> _confirmCancel(String jobId) async {
    final appState = context.read<AppState>();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Avbryt oppdrag'),
        content: const Text('Er du sikker på at du vil avbryte?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Nei'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ja'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _runAction(() async {
        await appState.cancelJob(jobId);
        _reload(jobId);
      });
    }
  }

  // ---------------- HELPERS ----------------

  Future<void> _runAction(Future<void> Function() fn) async {
    setState(() => _isLoading = true);
    await fn();
    if (mounted) setState(() => _isLoading = false);
  }

  void _reload(String id) {
    final updated = context.read<AppState>().getJobById(id);
    if (updated != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => JobDetailScreen(job: updated),
        ),
      );
    }
  }

  Widget _mainButton(String text, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        child: Text(text),
      ),
    );
  }
}
