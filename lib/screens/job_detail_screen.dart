import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/job.dart';
import '../models/user_profile.dart';
import '../providers/app_state.dart';
import '../widgets/reserved_timer.dart';
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

    return Scaffold(
      appBar: AppBar(title: Text(job.title)),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // -------- CANCEL BANNER (additiv UI — chat-meldinger uendret) --------
                if (job.cancelRequestedByUserId != null &&
                    (isOwner || isWorker))
                  _CancelBanner(
                    job: job,
                    currentUser: currentUser,
                    requester: appState
                        .getUserById(job.cancelRequestedByUserId!),
                    onApprove: () => _runAction(() async {
                      await appState.approveCancel(job.id);
                      _reload(job.id);
                    }),
                    onReject: () => _runAction(() async {
                      await appState.rejectCancel(job.id);
                      _reload(job.id);
                    }),
                    onWithdraw: () => _runAction(() async {
                      await appState.withdrawCancelRequest(job.id);
                      _reload(job.id);
                    }),
                  ),

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

                _priceSection(job, isOwner),

                const SizedBox(height: 20),
                Text('Status: ${job.status.name}'),

                // -------- RESERVASJONS-NEDTELLING --------
                if (job.status == JobStatus.reserved &&
                    job.reservedUntil != null) ...[
                  const SizedBox(height: 12),
                  ReservedTimer(
                    jobId: job.id,
                    reservedUntil: job.reservedUntil!,
                  ),
                ],
              ],
            ),
          ),

          _actionButtons(job, isOwner, isWorker),
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

            // -------- AVBRYT / SLETT --------
            // OPEN eier ser "Slett oppdrag" (direkte sletting).
            // OPEN jobber har ingen arbeider ennå, så ikke noe to-parts flow.
            // RESERVED/INPROGRESS ser "Avbryt oppdrag" (utløser riktig flow).
            if (!_isLoading &&
                isOwner &&
                job.status == JobStatus.open)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _confirmDelete(job.id),
                  child: const Text('Slett oppdrag'),
                ),
              ),

            if (!_isLoading &&
                (isOwner || isWorker) &&
                job.status != JobStatus.completed &&
                job.status != JobStatus.open)
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

  Future<void> _confirmDelete(String jobId) async {
    final appState = context.read<AppState>();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Slett oppdrag'),
        content: const Text(
          'Vil du slette oppdraget? Det er ikke reservert av noen '
          'ennå, så det forsvinner helt.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Nei'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Slett'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await _runAction(() async {
      final ok = await appState.deleteOwnJob(jobId);
      if (!mounted) return;
      if (ok) {
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kunne ikke slette oppdraget.')),
        );
      }
    });
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

// ============================================================
// 🔥 CANCEL BANNER (additiv UI — speiler AppState cancel-flyt)
// ============================================================

class _CancelBanner extends StatelessWidget {
  final Job job;
  final UserProfile currentUser;
  final UserProfile? requester;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onWithdraw;

  const _CancelBanner({
    required this.job,
    required this.currentUser,
    required this.requester,
    required this.onApprove,
    required this.onReject,
    required this.onWithdraw,
  });

  @override
  Widget build(BuildContext context) {
    final requesterId = job.cancelRequestedByUserId;
    if (requesterId == null) return const SizedBox.shrink();

    final isMine = requesterId == currentUser.id;
    final requesterName = requester?.firstName ?? 'Den andre parten';

    final bg = isMine
        ? const Color(0xFFFFF4E5)
        : const Color(0xFFFFEBEE);
    final border = isMine ? Colors.orange : Colors.red;
    final icon = isMine ? Icons.hourglass_top : Icons.report_gmailerrorred;

    final title = isMine
        ? 'Du har bedt om å avbryte oppdraget'
        : '$requesterName har bedt om å avbryte oppdraget';

    final subtitle = isMine
        ? 'Venter på at den andre parten godkjenner. Oppdraget fortsetter inntil begge parter har godkjent.'
        : 'Begge parter må godkjenne før oppdraget kanselleres. Velg om du vil godkjenne eller avslå forespørselen.';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border.withOpacity(0.35), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: border, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: border.shade900,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 32),
            child: Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF4A4A4A),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (isMine)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onWithdraw,
                icon: const Icon(Icons.undo),
                label: const Text('Trekk tilbake forespørselen'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange.shade900,
                ),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.check),
                    label: const Text('Godkjenn'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close),
                    label: const Text('Avslå'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade900,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
