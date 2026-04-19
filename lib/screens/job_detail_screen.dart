// UI UPGRADE: premium polish, hierarchy, spacing, and clearer navigation
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/job.dart';
import '../models/user_profile.dart';
import '../providers/app_state.dart';
import '../widgets/rating_dialog.dart';
import '../widgets/reserved_timer.dart';
import 'chat_screen.dart';
import 'image_viewer_screen.dart';

const Color _primary = Color(0xFF2356E8);
const Color _accent = Color(0xFF18B7A6);
const Color _bg = Color(0xFFF4F7FC);
const Color _textPrimary = Color(0xFF0F1E3A);
const Color _textMuted = Color(0xFF6E7A90);
const Color _danger = Color(0xFFDC2626);
const Color _safeGreen = Color(0xFF0EA877);

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
    final owner = appState.getUserById(job.createdByUserId);
    final worker = job.acceptedByUserId == null
        ? null
        : appState.getUserById(job.acceptedByUserId!);

    // Vis rating-CTA til riktig part når oppdraget er fullført.
    final counterparty = isOwner ? worker : owner;

    final isNew =
        DateTime.now().difference(job.createdAt) < const Duration(hours: 24);

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
                _heroSection(job, images, isNew),
                const SizedBox(height: 14),
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
                _ownerTrustCard(appState, job, owner, isOwner),
                const SizedBox(height: 14),
                _descriptionCard(job),
                const SizedBox(height: 14),
                _paymentCard(job, isOwner),
                const SizedBox(height: 14),
                _lockInNote(),
                const SizedBox(height: 10),
                _problemButton(job),
                const SizedBox(height: 14),
                _infoCard(job),
              ],
            ),
          ),
          _actionButtons(job, isOwner, isWorker, counterparty),
        ],
      ),
    );
  }

  // ====================================================================
  // HERO
  // ====================================================================

  Widget _heroSection(Job job, List<String> images, bool isNew) {
    final palette = _pastelForCategory(job.category);
    const double heroHeight = 240;

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: SizedBox(
        height: heroHeight,
        child: Stack(
          children: [
            // Pastell-bakgrunn
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [palette.start, palette.end],
                  ),
                ),
              ),
            ),
            // Soft shapes
            Positioned(
              right: -40,
              top: -30,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.22),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              left: -20,
              bottom: -40,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(40),
                ),
              ),
            ),
            // Bildegalleri (lagt oppå pastell)
            if (images.isNotEmpty)
              Positioned.fill(
                child: PageView.builder(
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
                      child: Hero(
                        tag: url,
                        child: Image.network(
                          url,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        ),
                      ),
                    );
                  },
                ),
              )
            else
              Center(
                child: Icon(
                  palette.icon,
                  size: 68,
                  color: Colors.white.withOpacity(0.85),
                ),
              ),

            // Chip-rad nederst (NY · Kategori · Sted)
            Positioned(
              left: 14,
              right: 14,
              bottom: 14,
              child: Row(
                children: [
                  if (isNew)
                    _heroChip(
                      text: 'NY',
                      bg: _accent,
                      fg: Colors.white,
                      leadingDot: true,
                    ),
                  if (isNew) const SizedBox(width: 6),
                  _heroChip(
                    text: job.category,
                    bg: Colors.white,
                    fg: _primary,
                  ),
                  const SizedBox(width: 6),
                  _heroChip(
                    text: job.locationName,
                    bg: Colors.white,
                    fg: _textPrimary,
                    icon: Icons.place_outlined,
                  ),
                  const Spacer(),
                  if (images.length > 1)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.45),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.photo_library_outlined,
                              color: Colors.white, size: 13),
                          const SizedBox(width: 4),
                          Text(
                            '${images.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroChip({
    required String text,
    required Color bg,
    required Color fg,
    IconData? icon,
    bool leadingDot = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leadingDot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
          ],
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w800,
              fontSize: 11.5,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  // ====================================================================
  // TITLE CARD
  // ====================================================================

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
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${job.price}',
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: _primary,
                  letterSpacing: -0.5,
                  height: 1,
                ),
              ),
              const SizedBox(width: 4),
              const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Text(
                  'kr',
                  style: TextStyle(
                    color: _primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: Text(
                  '· fastpris',
                  style: TextStyle(
                    color: _textMuted,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: fg,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w800,
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }

  // ====================================================================
  // OWNER / TRUST CARD
  // ====================================================================

  Widget _ownerTrustCard(
    AppState appState,
    Job job,
    UserProfile? owner,
    bool isOwner,
  ) {
    final name = owner?.firstName ?? 'Bruker';
    final rating = owner?.rating ?? 5.0;
    final ratingCount = owner?.ratingCount ?? 0;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    // Trust-tall beregnes UI-side fra AppState – ingen modell-endringer.
    final completedAsWorker = appState.jobs
        .where((j) =>
            j.acceptedByUserId == owner?.id &&
            j.status == JobStatus.completed &&
            j.isApprovedByOwner)
        .length;

    final completedAsOwner = appState.jobs
        .where((j) =>
            j.createdByUserId == owner?.id &&
            j.status == JobStatus.completed &&
            j.isApprovedByOwner)
        .length;

    final jobsCount = completedAsOwner + completedAsWorker;
    final isVerified = (owner?.email.isNotEmpty ?? false) ||
        (owner?.phone.isNotEmpty ?? false) ||
        ratingCount > 0;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4F7BFF), _accent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _primary.withOpacity(0.20),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: _textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 15.5,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            color: Color(0xFFFFB020), size: 14),
                        const SizedBox(width: 3),
                        Text(
                          '${rating.toStringAsFixed(1)} · $jobsCount oppdrag',
                          style: const TextStyle(
                            color: _textMuted,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                        if (isVerified) ...[
                          const SizedBox(width: 8),
                          _verifiedPill(),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (job.acceptedByUserId != null && !isOwner)
                Material(
                  color: _bg,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(job: job),
                        ),
                      );
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(10),
                      child: Icon(Icons.chat_bubble_outline_rounded,
                          color: _primary, size: 20),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (isVerified)
                _trustChip(
                  text: 'Verifisert',
                  icon: Icons.verified_rounded,
                  bg: const Color(0xFFE7F6EC),
                  fg: const Color(0xFF2E9757),
                ),
              if (jobsCount >= 5)
                _trustChip(
                  text: '5+ oppdrag',
                  icon: Icons.workspace_premium_rounded,
                  bg: const Color(0xFFE0EBFF),
                  fg: _primary,
                ),
              _trustChip(
                text: 'Svarer raskt',
                icon: Icons.bolt_rounded,
                bg: const Color(0xFFFFF4E5),
                fg: const Color(0xFFE08A00),
              ),
              if (ratingCount > 0)
                _trustChip(
                  text: '100% fullført',
                  icon: Icons.check_circle_outline_rounded,
                  bg: const Color(0xFFEAE6FF),
                  fg: const Color(0xFF6B21A8),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _verifiedPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _safeGreen.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.verified_rounded, size: 11, color: _safeGreen),
          SizedBox(width: 3),
          Text(
            'Verifisert',
            style: TextStyle(
              color: _safeGreen,
              fontWeight: FontWeight.w800,
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _trustChip({
    required String text,
    required IconData icon,
    required Color bg,
    required Color fg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w800,
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }

  // ====================================================================
  // DESCRIPTION
  // ====================================================================

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

  // ====================================================================
  // SAFE-PAYMENT CARD
  // ====================================================================

  Widget _paymentCard(Job job, bool isOwner) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _safeGreen.withOpacity(0.10),
            _accent.withOpacity(0.12),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _safeGreen.withOpacity(0.22),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _safeGreen.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.verified_user_rounded,
                    color: _safeGreen, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trygg betaling via SmartHjelp',
                      style: TextStyle(
                        color: _safeGreen,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        letterSpacing: -0.2,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Pengene holdes på en sikker konto til jobben er godkjent. '
                      'Ingen risiko for noen av partene.',
                      style: TextStyle(
                        color: Color(0xFF0F5C46),
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.6),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _paymentColumn(
                    label: isOwner ? 'DU BETALER' : 'KUNDE BETALER',
                    value: '${job.totalPrice.toStringAsFixed(0)} kr',
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: _safeGreen.withOpacity(0.18),
                ),
                Expanded(
                  child: _paymentColumn(
                    label: 'HOLDES TRYGT',
                    value: 'Til godkjent',
                    isText: true,
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: _safeGreen.withOpacity(0.18),
                ),
                Expanded(
                  child: _paymentColumn(
                    label: isOwner ? 'PLATTFORMFEE' : 'DU TJENER',
                    value: isOwner
                        ? '${job.platformFee.toStringAsFixed(0)} kr'
                        : '${job.payout.toStringAsFixed(0)} kr',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentColumn({
    required String label,
    required String value,
    bool isText = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F5C46),
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isText ? 13 : 15,
            fontWeight: FontWeight.w900,
            color: _safeGreen,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
  // ====================================================================
  // LOCK-IN NOTE (fullfør i app)
  // ====================================================================

  Widget _lockInNote() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEEEAFE),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF6B57E3).withOpacity(0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.shield_rounded,
                color: Color(0xFF4C3BBE), size: 18),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Fullfør i app ',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF3A2F9E),
                      fontSize: 13,
                    ),
                  ),
                  TextSpan(
                    text: 'for rating, trygg betaling og forsikring. '
                        'Avtaler utenfor SmartHjelp dekkes ikke.',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4C3BBE),
                      fontSize: 12.5,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ====================================================================
  // PROBLEM-RAPPORTERING (kun UI + snackbar + chat-melding)
  // ====================================================================

  Widget _problemButton(Job job) {
    return Material(
      color: const Color(0xFFFDECEC),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openProblemSheet(job),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _danger.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.report_gmailerrorred_rounded,
                    color: _danger, size: 18),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Problem med oppdrag?',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: _danger,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Rapportér og pause betalingen',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF7F1D1D),
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: _danger, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openProblemSheet(Job job) async {
    final options = <_ProblemOption>[
      _ProblemOption('Ikke møtt opp', Icons.person_off_rounded),
      _ProblemOption('Dårlig utført', Icons.thumb_down_alt_outlined),
      _ProblemOption('Skade eller mangel', Icons.warning_amber_rounded),
      _ProblemOption('Annet', Icons.more_horiz_rounded),
    ];

    final chosen = await showModalBottomSheet<_ProblemOption>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE4E9F2),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const Text(
                  'Problem med oppdrag?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Vi pauser betalingen og support følger opp. Velg grunn:',
                  style: TextStyle(
                    color: _textMuted,
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                ...options.map(
                  (o) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: _bg,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => Navigator.pop(context, o),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: _danger.withOpacity(0.10),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(o.icon,
                                    color: _danger, size: 18),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  o.label,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: _textPrimary,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded,
                                  color: _textMuted, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (chosen == null || !mounted) return;

    // Kun UI-lag: logg problem som melding i chatten (ingen AppState-endringer).
    context.read<AppState>().sendMessage(
          jobId: job.id,
          text: '⚠️ Problem rapportert: ${chosen.label}. '
              'Betalingen er satt på pause. Support følger opp.',
        );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: _danger,
        content: Text(
          'Sak registrert: ${chosen.label}. Support følger opp.',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  // ====================================================================
  // INFO CARD
  // ====================================================================

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
          const SizedBox(height: 8),
          _infoRow(Icons.place_outlined, 'Sted', job.locationName),
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

  // ====================================================================
  // STATUS CTA + STICKY BOTTOM BAR
  // ====================================================================

  Widget _actionButtons(
    Job job,
    bool isOwner,
    bool isWorker,
    UserProfile? counterparty,
  ) {
    final appState = context.read<AppState>();

    final children = <Widget>[];

    if (_isLoading) {
      children.add(const Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Center(child: CircularProgressIndicator()),
      ));
    }

    // Rediger + Slett når eier + open
    if (!_isLoading && isOwner && job.status == JobStatus.open) {
      children.add(Row(
        children: [
          Expanded(
            child: _outlinedButton(
              'Rediger',
              Icons.edit_outlined,
              () => _showEditDialog(job),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _outlinedButton(
              'Slett',
              Icons.delete_outline_rounded,
              () => _confirmDelete(job.id),
              isDanger: true,
            ),
          ),
        ],
      ));
    }

    // Avbryt for aktive oppdrag (ikke completed, ikke open)
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

    // Primær status-CTA (gradient)
    final primary = _buildStatusCta(job, isOwner, isWorker, appState);
    if (!_isLoading && primary != null) {
      children.add(primary);
    }

    // Gi rating når fullført
    if (!_isLoading &&
        job.status == JobStatus.completed &&
        job.isApprovedByOwner &&
        counterparty != null) {
      children.add(_gradientCta(
        label: 'Gi rating',
        subLabel: 'Hjelp neste person',
        icon: Icons.star_rounded,
        gradientColors: const [_accent, _primary],
        onTap: () => _openRating(counterparty),
      ));
    }

    if (children.isEmpty) {
      return const SafeArea(child: SizedBox.shrink());
    }

    // Chat-knapp til venstre (hvis motpart finnes)
    final showChat = job.acceptedByUserId != null;

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
            children: [
              ..._interleaveSpacing(children, 10),
              if (showChat) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(job: job),
                        ),
                      );
                    },
                    icon: const Icon(Icons.chat_bubble_outline_rounded,
                        size: 18),
                    label: const Text('Åpne chat'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _primary,
                      side: BorderSide(color: _primary.withOpacity(0.35)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget? _buildStatusCta(
    Job job,
    bool isOwner,
    bool isWorker,
    AppState appState,
  ) {
    // Åpen → Ta jobb (viser pris)
    if (job.status == JobStatus.open && !isOwner) {
      return _gradientCta(
        label: 'Ta jobb',
        subLabel: '${job.price} kr',
        icon: Icons.bolt_rounded,
        gradientColors: const [Color(0xFF3E6BFF), _primary],
        onTap: () => _runAction(() async {
          final ok = await appState.reserveJob(job.id);
          if (!ok) return;
          _reload(job.id);
        }),
      );
    }

    // Reservert → Start jobb
    if (job.status == JobStatus.reserved && isWorker) {
      return _gradientCta(
        label: 'Start jobb',
        subLabel: 'Marker oppmøte',
        icon: Icons.play_arrow_rounded,
        gradientColors: const [_accent, _primary],
        onTap: () => _runAction(() async {
          await appState.startJob(job.id);
          _reload(job.id);
        }),
      );
    }

    // Pågår + worker → Fullfør oppdrag
    if (job.status == JobStatus.inProgress &&
        isWorker &&
        !job.isCompletedByWorker) {
      return _gradientCta(
        label: 'Fullfør oppdrag',
        subLabel: 'Marker som ferdig',
        icon: Icons.check_rounded,
        gradientColors: const [Color(0xFF3E6BFF), _primary],
        onTap: () => _runAction(() async {
          await appState.completeJobByWorker(job.id);
          _reload(job.id);
        }),
      );
    }

    // Pågår + owner + worker ferdig → Godkjenn og betal ut
    if (job.status == JobStatus.inProgress &&
        isOwner &&
        job.isCompletedByWorker) {
      return _gradientCta(
        label: 'Godkjenn og betal ut',
        subLabel: 'Frigi escrow',
        icon: Icons.verified_rounded,
        gradientColors: const [_accent, _primary],
        onTap: () => _runAction(() async {
          await appState.approveAndReleasePayment(job.id);
          _reload(job.id);
        }),
      );
    }

    return null;
  }

  Widget _gradientCta({
    required String label,
    required String subLabel,
    required IconData icon,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: gradientColors.last.withOpacity(0.32),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: [
                  Icon(icon, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 15.5,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    subLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _outlinedButton(
    String text,
    IconData icon,
    VoidCallback onTap, {
    bool isDanger = false,
  }) {
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

  List<Widget> _interleaveSpacing(List<Widget> items, double gap) {
    final result = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      result.add(items[i]);
      if (i < items.length - 1) result.add(SizedBox(height: gap));
    }
    return result;
  }

  // ====================================================================
  // RATING
  // ====================================================================

  Future<void> _openRating(UserProfile counterparty) async {
    final rating = await showDialog<double>(
      context: context,
      builder: (_) => const RatingDialog(),
    );

    if (rating == null || !mounted) return;

    context
        .read<AppState>()
        .rateUser(userId: counterparty.id, newRating: rating);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: _primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        content: Text(
          'Takk! Du ga ${counterparty.firstName} ${rating.toStringAsFixed(1)} ⭐',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  // ====================================================================
  // EDIT DIALOG (eier + open)
  // ====================================================================

  Future<void> _showEditDialog(Job job) async {
    final titleCtrl = TextEditingController(text: job.title);
    final descCtrl = TextEditingController(text: job.description);
    final priceCtrl = TextEditingController(text: job.price.toString());
    final categoryCtrl = TextEditingController(text: job.category);
    final locationCtrl = TextEditingController(text: job.locationName);
    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              'Rediger oppdrag',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: _textPrimary,
              ),
            ),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(labelText: 'Tittel'),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Skriv tittel'
                          : null,
                    ),
                    TextFormField(
                      controller: descCtrl,
                      decoration:
                          const InputDecoration(labelText: 'Beskrivelse'),
                      maxLines: 3,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Skriv beskrivelse'
                          : null,
                    ),
                    TextFormField(
                      controller: priceCtrl,
                      decoration: const InputDecoration(labelText: 'Pris'),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        final parsed = int.tryParse((v ?? '').trim());
                        if (parsed == null || parsed <= 0) {
                          return 'Ugyldig pris';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: categoryCtrl,
                      decoration:
                          const InputDecoration(labelText: 'Kategori'),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Skriv kategori'
                          : null,
                    ),
                    TextFormField(
                      controller: locationCtrl,
                      decoration: const InputDecoration(labelText: 'Sted'),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Skriv sted'
                          : null,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Avbryt'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: _primary),
                onPressed: () {
                  if (formKey.currentState?.validate() != true) return;
                  Navigator.pop(context, true);
                },
                child: const Text('Lagre'),
              ),
            ],
          ),
        ) ??
        false;

    if (!saved || !mounted) return;

    final ok = await context.read<AppState>().updateOwnJob(
          jobId: job.id,
          title: titleCtrl.text.trim(),
          description: descCtrl.text.trim(),
          price: int.parse(priceCtrl.text.trim()),
          category: categoryCtrl.text.trim(),
          locationName: locationCtrl.text.trim(),
          lat: job.lat,
          lng: job.lng,
        );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Oppdraget ble oppdatert.'
              : 'Kunne ikke oppdatere oppdraget.',
        ),
      ),
    );

    if (ok) _reload(job.id);
  }

  // ====================================================================
  // CANCEL + DELETE CONFIRMATIONS
  // ====================================================================

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
    if (updated != null && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => JobDetailScreen(job: updated),
        ),
      );
    }
  }

  // ====================================================================
  // PASTELL (matcher JobCard)
  // ====================================================================

  _CategoryPalette _pastelForCategory(String category) {
    final key = category.toLowerCase().trim();
    switch (key) {
      case 'flytting':
        return const _CategoryPalette(
          start: Color(0xFFFFD6B8),
          end: Color(0xFFFFBFA0),
          icon: Icons.local_shipping_rounded,
        );
      case 'rengjøring':
      case 'rengjoring':
        return const _CategoryPalette(
          start: Color(0xFFE0DBFF),
          end: Color(0xFFC9BEFF),
          icon: Icons.cleaning_services_rounded,
        );
      case 'hage':
        return const _CategoryPalette(
          start: Color(0xFFC5EBD3),
          end: Color(0xFF9FDCB6),
          icon: Icons.yard_rounded,
        );
      case 'montering':
        return const _CategoryPalette(
          start: Color(0xFFCDEEE8),
          end: Color(0xFFA2DDD3),
          icon: Icons.handyman_rounded,
        );
      case 'bygg':
      case 'handyman':
        return const _CategoryPalette(
          start: Color(0xFFFFE7B5),
          end: Color(0xFFFFD38A),
          icon: Icons.construction_rounded,
        );
      case 'transport':
        return const _CategoryPalette(
          start: Color(0xFFD0E2FF),
          end: Color(0xFFA7C5FF),
          icon: Icons.directions_car_rounded,
        );
      default:
        return const _CategoryPalette(
          start: Color(0xFFDCE7FF),
          end: Color(0xFFB8CCFF),
          icon: Icons.work_rounded,
        );
    }
  }
}

// =====================================================================
// PRIVATE TYPES
// =====================================================================

class _ProblemOption {
  final String label;
  final IconData icon;
  const _ProblemOption(this.label, this.icon);
}

class _CategoryPalette {
  final Color start;
  final Color end;
  final IconData icon;

  const _CategoryPalette({
    required this.start,
    required this.end,
    required this.icon,
  });
}

// =====================================================================
// CANCEL BANNER (uendret funksjonalitet, beholdt premium-stil)
// =====================================================================

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

    final bg =
        isMine ? const Color(0xFFFFF4E5) : const Color(0xFFFFEBEE);
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
                  side: BorderSide(
                    color: Colors.orange.shade700.withOpacity(0.45),
                  ),
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
                      textStyle:
                          const TextStyle(fontWeight: FontWeight.w800),
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
                        color: Colors.red.shade700.withOpacity(0.45),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                      textStyle:
                          const TextStyle(fontWeight: FontWeight.w700),
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


