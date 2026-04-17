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
  void initState() {
    super.initState();
    // Sørg for at eventuelle bilder lastes når detaljsiden åpnes.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AppState>().loadImages(widget.job.id);
    });
  }

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
                Text(
                  job.title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(job.description),
                const SizedBox(height: 20),

                // -------- CANCEL-BANNER --------
                _cancelBanner(job, isOwner, isWorker, currentUser.id),

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
                                child: Image.network(
                                  url,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 200,
                                    color: Colors.grey.shade200,
                                    child: const Center(
                                      child: Icon(
                                        Icons.broken_image_outlined,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                ),
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
                Text('Status: ${_statusLabel(job)}'),

                const SizedBox(height: 4),
                Text(
                  'Sted: ${job.locationName}',
                  style: const TextStyle(
                    color: Color(0xFF6E7A90),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          _actionButtons(job, isOwner, isWorker, currentUser.id),
        ],
      ),
    );
  }

  // ---------------- CANCEL BANNER ----------------

  Widget _cancelBanner(
    Job job,
    bool isOwner,
    bool isWorker,
    String currentUserId,
  ) {
    final requestedBy = job.cancelRequestedByUserId;
    if (requestedBy == null) return const SizedBox.shrink();

    // Vi viser banner kun for relevante parter
    if (!isOwner && !isWorker) return const SizedBox.shrink();

    final iRequested = requestedBy == currentUserId;

    // Under open-status: eier kan ha markert "avbrutt" på egen åpen jobb
    // – da viser vi det som informasjon (ikke som approve/reject).
    if (job.status == JobStatus.open) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.orange.shade300),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.orange),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Oppdraget er markert som avbrutt av eier.',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );
    }

    // Under inProgress: approve/reject-flyt
    final title = iRequested
        ? 'Du har bedt om å avbryte oppdraget'
        : 'Motparten har bedt om å avbryte oppdraget';

    final description = iRequested
        ? 'Motparten må godkjenne før oppdraget kan avbrytes. Du kan trekke tilbake forespørselen så lenge motparten ikke har svart.'
        : 'Godkjenner du, åpnes oppdraget igjen. Avslår du, fortsetter oppdraget som før.';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.orange),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF172033),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              color: Color(0xFF6E7A90),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          if (iRequested)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _confirmWithdraw(job.id),
                icon: const Icon(Icons.undo),
                label: const Text('Trekk tilbake forespørsel'),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _confirmApproveCancel(job.id),
                    icon: const Icon(Icons.check),
                    label: const Text('Godkjenn avbrytelse'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmRejectCancel(job.id),
                    icon: const Icon(Icons.close),
                    label: const Text('Avslå'),
                  ),
                ),
              ],
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
        const Text(
          'Betaling',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (isOwner) ...[
          Text('Oppdrag: ${job.price} kr'),
          Text(
            'Plattformavgift: ${job.platformFee.toStringAsFixed(0)} kr inkl. mva',
          ),
          Text(
            'Totalt å betale: ${job.totalPrice.toStringAsFixed(0)} kr',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFF2356E8),
            ),
          ),
        ] else ...[
          Text(
            'Du tjener: ${job.payout.toStringAsFixed(0)} kr',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFF18B7A6),
            ),
          ),
        ],
      ],
    );
  }

  // ---------------- ACTIONS ----------------

  Widget _actionButtons(
    Job job,
    bool isOwner,
    bool isWorker,
    String currentUserId,
  ) {
    final appState = context.read<AppState>();
    final cancelRequested = job.cancelRequestedByUserId != null;
    final iRequestedCancel = job.cancelRequestedByUserId == currentUserId;

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
                  if (!ok) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Kunne ikke reservere oppdraget.'),
                        ),
                      );
                    }
                    return;
                  }
                  _reload(job.id);
                });
              }),

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

            // -------- GODKJENN OG BETAL UT --------
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

            // -------- AVBRYT OPPDRAG --------
            // Vises når:
            //   - du er involvert (eier eller arbeider)
            //   - jobben ikke er fullført
            //   - det ikke allerede foreligger en cancel-forespørsel fra deg
            //     (du har da "Trekk tilbake"-knappen i banneret i stedet)
            if (!_isLoading &&
                (isOwner || isWorker) &&
                job.status != JobStatus.completed &&
                !(cancelRequested && iRequestedCancel))
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => _confirmCancel(job),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                    child: const Text('Avbryt oppdrag'),
                  ),
                ),
              ),

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

  // ---------------- CONFIRM DIALOGS ----------------

  Future<void> _confirmCancel(Job job) async {
    final appState = context.read<AppState>();
    final currentUserId = appState.currentUser.id;
    final isOwner = job.createdByUserId == currentUserId;
    final isWorker = job.acceptedByUserId == currentUserId;

    String title;
    String body;
    String confirmLabel;

    switch (job.status) {
      case JobStatus.open:
        if (!isOwner) {
          // Worker skal aldri komme hit for open-jobb, men vi er defensive
          return;
        }
        title = 'Slette oppdrag';
        body =
            'Oppdraget er ikke tatt enda. Vil du slette det permanent? Dette kan ikke angres.';
        confirmLabel = 'Slett';
        break;

      case JobStatus.reserved:
        title = 'Avbryt reservasjon';
        body =
            'Reservasjonen vil oppheves og oppdraget blir åpent igjen. Er du sikker?';
        confirmLabel = 'Avbryt reservasjon';
        break;

      case JobStatus.inProgress:
        title = 'Be om å avbryte';
        body =
            'Oppdraget er i gang. Motparten må godkjenne før oppdraget kan avbrytes. Vil du sende en forespørsel?';
        confirmLabel = 'Send forespørsel';
        break;

      case JobStatus.completed:
        return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Nei'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    // open + eier → slett helt
    if (job.status == JobStatus.open && isOwner) {
      await _runAction(() async {
        final ok = await appState.deleteOwnJob(job.id);
        if (!mounted) return;
        if (ok) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Oppdraget ble slettet.')),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kunne ikke slette oppdraget.')),
          );
        }
      });
      return;
    }

    // reserved → direkte release, inProgress → request via cancelJob
    await _runAction(() async {
      await appState.cancelJob(job.id);
      if (!mounted) return;
      _reload(job.id);
      if (!mounted) return;
      final updated = appState.getJobById(job.id);
      final becameOpen = updated?.status == JobStatus.open;
      final msg = becameOpen
          ? 'Reservasjonen ble opphevet. Oppdraget er åpent igjen.'
          : (isOwner || isWorker)
              ? 'Forespørsel om avbrytelse ble sendt.'
              : 'Oppdatert.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    });
  }

  Future<void> _confirmApproveCancel(String jobId) async {
    final appState = context.read<AppState>();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Godkjenn avbrytelse'),
        content: const Text(
          'Er du sikker på at du vil godkjenne avbrytelsen? Oppdraget blir åpnet igjen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Nei'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Ja, godkjenn'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    await _runAction(() async {
      await appState.approveCancel(jobId);
      _reload(jobId);
    });
  }

  Future<void> _confirmRejectCancel(String jobId) async {
    final appState = context.read<AppState>();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Avslå forespørsel'),
        content: const Text(
          'Vil du avslå forespørselen om avbrytelse? Oppdraget fortsetter som før.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Avbryt'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Avslå'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    await _runAction(() async {
      await appState.rejectCancel(jobId);
      _reload(jobId);
    });
  }

  Future<void> _confirmWithdraw(String jobId) async {
    final appState = context.read<AppState>();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Trekk tilbake forespørsel'),
        content: const Text(
          'Vil du trekke tilbake forespørselen om å avbryte? Oppdraget fortsetter som før.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Nei'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ja, trekk tilbake'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    await _runAction(() async {
      await appState.withdrawCancelRequest(jobId);
      _reload(jobId);
    });
  }

  // ---------------- HELPERS ----------------

  Future<void> _runAction(Future<void> Function() fn) async {
    setState(() => _isLoading = true);
    try {
      await fn();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _reload(String id) {
    if (!mounted) return;
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

  String _statusLabel(Job job) {
    switch (job.status) {
      case JobStatus.open:
        return 'Åpent';
      case JobStatus.reserved:
        return 'Reservert';
      case JobStatus.inProgress:
        return job.isCompletedByWorker
            ? 'Venter på godkjenning'
            : 'Pågår';
      case JobStatus.completed:
        return job.isApprovedByOwner ? 'Fullført' : 'Fullført (ikke godkjent)';
    }
  }
}
