// UI UPGRADE: premium polish, hierarchy, spacing, and clearer navigation
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/job.dart';
import '../models/user_profile.dart';
import '../providers/app_state.dart';
import '../widgets/reserved_timer.dart';
import 'chat_screen.dart';
import 'image_viewer_screen.dart';

const Color _primary = Color(0xFF2356E8);
const Color _accent = Color(0xFF18B7A6);
const Color _bg = Color(0xFFF4F7FC);
const Color _textPrimary = Color(0xFF0F1E3A);
const Color _textMuted = Color(0xFF6E7A90);
const Color _danger = Color(0xFFDC2626);

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
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: _textPrimary),
        title: const Text(
          'Oppdragsdetaljer',
          style: TextStyle(
            color: _textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              children: [
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
                if (images.isNotEmpty) _heroGallery(images),
                const SizedBox(height: 16),
                _titleCard(job),
                const SizedBox(height: 14),
                if (job.status == JobStatus.reserved &&
                    job.reservedUntil != null) ...[
                  ReservedTimer(
                    jobId: job.id,
                    reservedUntil: job.reservedUntil!,
                  ),
                  const SizedBox(height: 14),
                ],
                _descriptionCard(job),
                const SizedBox(height: 14),
                _paymentCard(job, isOwner),
                const SizedBox(height: 14),
                _infoCard(job),
              ],
            ),
          ),
          _actionButtons(job, isOwner, isWorker),
        ],
      ),
    );
  }

  Widget _heroGallery(List<String> images) {
    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
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
            child: Hero(
              tag: url,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 260,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Image.network(
                    url,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: _bg,
                      alignment: Alignment.center,
                      child: const Icon(Icons.broken_image,
                          color: _textMuted, size: 36),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _titleCard(Job job) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  job.title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: _textPrimary,
                    letterSpacing: -0.3,
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _statusBadge(job.status),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.place_outlined,
                  size: 16, color: _textMuted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  job.locationName,
                  style: const TextStyle(
                    color: _textMuted,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _bg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.category_outlined,
                        size: 13, color: _primary),
                    const SizedBox(width: 4),
                    Text(
                      job.category,
                      style: const TextStyle(
                        color: _primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(JobStatus status) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case JobStatus.open:
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF166534);
        label = 'Åpen';
        break;
      case JobStatus.reserved:
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFB45309);
        label = 'Reservert';
        break;
      case JobStatus.inProgress:
        bg = const Color(0xFFDBEAFE);
        fg = const Color(0xFF1E40AF);
        label = 'Pågår';
        break;
      case JobStatus.completed:
        bg = const Color(0xFFE9D5FF);
        fg = const Color(0xFF6B21A8);
        label = 'Fullført';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w800,
          fontSize: 11.5,
        ),
      ),
    );
  }

  Widget _descriptionCard(Job job) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeading('Beskrivelse', Icons.description_outlined),
          const SizedBox(height: 10),
          Text(
            job.description,
            style: const TextStyle(
              color: _textPrimary,
              fontSize: 14.5,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentCard(Job job, bool isOwner) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeading('Betaling', Icons.payments_outlined),
          const SizedBox(height: 12),
          if (isOwner) ...[
            _priceRow('Oppdrag', '${job.price} kr'),
            const SizedBox(height: 6),
            _priceRow('Plattformavgift',
                '${job.platformFee.toStringAsFixed(0)} kr'),
            const SizedBox(height: 10),
            Container(height: 1, color: _bg),
            const SizedBox(height: 10),
            _priceRow('Totalt',
                '${job.totalPrice.toStringAsFixed(0)} kr',
                isBold: true),
          ] else ...[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.account_balance_wallet_outlined,
                      color: _accent, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Du tjener',
                        style: TextStyle(
                          color: _textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${job.payout.toStringAsFixed(0)} kr',
                        style: const TextStyle(
                          color: _textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _priceRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isBold ? _textPrimary : _textMuted,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
            fontSize: 13.5,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: _textPrimary,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w700,
            fontSize: isBold ? 16 : 14,
          ),
        ),
      ],
    );
  }

  Widget _infoCard(Job job) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeading('Info', Icons.info_outline_rounded),
          const SizedBox(height: 12),
          _infoRow(Icons.visibility_outlined, 'Visninger',
              '${job.viewCount}'),
          const SizedBox(height: 8),
          _infoRow(Icons.tag_outlined, 'Kategori', job.category),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: _textMuted),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: _textMuted,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            color: _textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 13.5,
          ),
        ),
      ],
    );
  }

  Widget _cardHeading(String text, IconData icon) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: _primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 16, color: _primary),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: _textPrimary,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _actionButtons(Job job, bool isOwner, bool isWorker) {
    final appState = context.read<AppState>();

    final children = <Widget>[];

    if (_isLoading) {
      children.add(const Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Center(child: CircularProgressIndicator()),
      ));
    }

    if (!_isLoading && job.status == JobStatus.open && !isOwner) {
      children.add(_primaryButton('Ta jobb', Icons.flash_on_rounded, () async {
        await _runAction(() async {
          final ok = await appState.reserveJob(job.id);
          if (!ok) return;
          _reload(job.id);
        });
      }));
    }

    if (!_isLoading && isOwner && job.status == JobStatus.open) {
      children.add(_outlinedButton(
        'Slett oppdrag',
        Icons.delete_outline_rounded,
        () => _confirmDelete(job.id),
        isDanger: true,
      ));
    }

    if (!_isLoading &&
        (isOwner || isWorker) &&
        job.status != JobStatus.completed &&
        job.status != JobStatus.open) {
      children.add(_outlinedButton(
        'Avbryt oppdrag',
        Icons.cancel_outlined,
        () => _confirmCancel(job.id),
        isDanger: true,
      ));
    }

    if (!_isLoading && job.status == JobStatus.reserved && isWorker) {
      children.add(_primaryButton('Start jobb',
          Icons.play_arrow_rounded, () async {
        await _runAction(() async {
          await appState.startJob(job.id);
          _reload(job.id);
        });
      }));
    }

    if (!_isLoading &&
        job.status == JobStatus.inProgress &&
        isWorker &&
        !job.isCompletedByWorker) {
      children.add(_primaryButton('Fullfør', Icons.check_rounded, () async {
        await _runAction(() async {
          await appState.completeJobByWorker(job.id);
          _reload(job.id);
        });
      }));
    }

    if (!_isLoading &&
        job.status == JobStatus.inProgress &&
        isOwner &&
        job.isCompletedByWorker) {
      children.add(_primaryButton(
        'Godkjenn og betal ut',
        Icons.verified_rounded,
        () async {
          await _runAction(() async {
            await appState.approveAndReleasePayment(job.id);
            _reload(job.id);
          });
        },
      ));
    }

    if (job.acceptedByUserId != null) {
      if (children.isNotEmpty) children.add(const SizedBox(height: 10));
      children.add(_outlinedButton(
        'Åpne chat',
        Icons.chat_bubble_outline_rounded,
        () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatScreen(job: job),
            ),
          );
        },
      ));
    }

    if (children.isEmpty) {
      return const SafeArea(child: SizedBox.shrink());
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _interleaveSpacing(children, 10),
          ),
        ),
      ),
    );
  }

  List<Widget> _interleaveSpacing(List<Widget> items, double gap) {
    final result = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      result.add(items[i]);
      if (i < items.length - 1) {
        result.add(SizedBox(height: gap));
      }
    }
    return result;
  }

  Widget _primaryButton(String text, IconData icon, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 20),
        label: Text(text),
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 15,
            letterSpacing: 0.1,
          ),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _outlinedButton(String text, IconData icon, VoidCallback onTap,
      {bool isDanger = false}) {
    final color = isDanger ? _danger : _primary;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(text),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withOpacity(0.35)),
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Future<void> _confirmCancel(String jobId) async {
    final appState = context.read<AppState>();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Avbryt oppdrag'),
        content: const Text('Er du sikker på at du vil avbryte?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Nei'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _danger),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
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
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _danger),
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
}

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
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border.withOpacity(0.35), width: 1),
        boxShadow: [
          BoxShadow(
            color: border.withOpacity(0.1),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: border.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: border, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: border.shade900,
                    fontSize: 14,
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 42),
            child: Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12.5,
                color: Color(0xFF4A4A4A),
                fontWeight: FontWeight.w500,
                height: 1.45,
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (isMine)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onWithdraw,
                icon: const Icon(Icons.undo_rounded, size: 18),
                label: const Text('Trekk tilbake forespørselen'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange.shade900,
                  side: BorderSide(color: Colors.orange.shade700
                      .withOpacity(0.45)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                  textStyle: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Godkjenn'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                      textStyle: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: const Text('Avslå'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade900,
                      side: BorderSide(
                          color: Colors.red.shade700.withOpacity(0.45)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                      textStyle: const TextStyle(fontWeight: FontWeight.w700),
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
