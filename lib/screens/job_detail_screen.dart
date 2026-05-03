import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/job.dart';
import '../models/user_profile.dart';
import '../providers/app_state.dart';
import '../widgets/rating_dialog.dart';
import '../widgets/trust_badges.dart';
import 'chat_screen.dart';
import 'image_viewer_screen.dart';
import 'post_job_screen.dart';

const Color _primary = Color(0xFF2356E8);
const Color _accent = Color(0xFF18B7A6);
const Color _warning = Color(0xFFE08A00);
const Color _safeGreen = Color(0xFF0EA877);
const Color _bg = Color(0xFFF4F7FC);
const Color _textPrimary = Color(0xFF0F1E3A);
const Color _textMuted = Color(0xFF6E7A90);
const Color _danger = Color(0xFFDC2626);

class JobDetailScreen extends StatefulWidget {
  final Job job;

  /// Sprint 7 nav-fix: settes til true når JobDetailScreen pushes ovenpå
  /// en ChatScreen for SAMME jobb. Da skal "Åpne chat" pop'e tilbake til
  /// den eksisterende ChatScreen i stedet for å pushe en ny — bryter
  /// JobDetail↔Chat-loopen. Default false bevarer eksisterende oppførsel
  /// for alle andre entry-points (HomeScreen, JobsScreen, NotificationScreen
  /// osv).
  final bool fromChat;

  const JobDetailScreen({
    super.key,
    required this.job,
    this.fromChat = false,
  });

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
        actions: [
          // FASE 3 FIX: snarvei tilbake til Hjem (popper hele navigator-stacken
          // tilbake til AppShell-rot, uavhengig av om man kom via Chat, Jobs, etc).
          IconButton(
            tooltip: 'Til Hjem',
            icon: const Icon(Icons.home_rounded, color: _primary),
            onPressed: () {
              Navigator.of(context).popUntil((r) => r.isFirst);
            },
          ),
          const SizedBox(width: 4),
        ],
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

                if (job.status == JobStatus.inProgress &&
                    job.isCompletedByWorker &&
                    !job.isApprovedByOwner &&
                    (isOwner || isWorker))
                  _ApprovalBanner(
                    isOwner: isOwner,
                    onApprove: () => _runAction(() async {
                      await appState.approveAndReleasePayment(job.id);
                      _reload(job.id);
                    }),
                  ),

                if (job.status == JobStatus.inProgress &&
                    !job.isCompletedByWorker &&
                    (isOwner || isWorker))
                  _PrivacyBanner(
                    title: 'Oppdraget pågår',
                    message: isOwner
                        ? 'Oppdragstaker jobber med oppdraget nå. Kun dere to ser oppdraget inntil det er fullført.'
                        : 'Du er i gang. Husk å trykke «Fullfør» når jobben er ferdig — da må oppdragsgiver godkjenne for utbetaling.',
                  ),

                // Sprint 6 UX: rating-banner ligger ØVERST som premium
                // CTA rett etter status-bannerene, slik at brukeren ser
                // den uten scroll. Banneret er det første som møter
                // øyet på et nettopp fullført + godkjent oppdrag.
                // Returneres tom når ikke aktuelt (ikke completed+
                // approved, ikke involvert, allerede ratet, eller
                // counterparty mangler), så ingen ekstra gating trengs.
                // Backup-knapp ligger også i bottom action area —
                // begge punkter kaller samme _openRatingDialog og
                // forsvinner samtidig via hasRatedJob.
                _ratingBanner(appState, job, isOwner, isWorker),

                if (images.isNotEmpty) _heroGallery(images),
                const SizedBox(height: 16),
                _titleCard(job),
                const SizedBox(height: 14),

                _trustCard(appState, job, isOwner, isWorker),

                _descriptionCard(job),
                const SizedBox(height: 14),
                _paymentCard(job, isOwner, isWorker),
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
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
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
              _statusBadge(job),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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

  Widget _statusBadge(Job job) {
    Color bg;
    Color fg;
    String label;

    switch (job.status) {
      case JobStatus.open:
        bg = _accent.withOpacity(0.14);
        fg = _accent;
        label = 'Åpen';
        break;
      case JobStatus.reserved:
        bg = const Color(0xFFFFF4E5);
        fg = _warning;
        label = 'Reservert';
        break;
      case JobStatus.inProgress:
        bg = _primary.withOpacity(0.10);
        fg = _primary;
        label = job.isCompletedByWorker ? 'Venter godkjenning' : 'Pågår';
        break;
      case JobStatus.completed:
        bg = _safeGreen.withOpacity(0.14);
        fg = _safeGreen;
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

  // FASE 2 PATCH: trust-kort viser nå faktisk antall fullførte oppdrag
  // beregnet fra _jobs, pluss verified-flagg.
  Widget _trustCard(
    AppState appState,
    Job job,
    bool isOwner,
    bool isWorker,
  ) {
    String? otherId;
    String label;

    if (isOwner && job.acceptedByUserId != null) {
      otherId = job.acceptedByUserId;
      label = 'Oppdragstaker';
    } else if (isWorker) {
      otherId = job.createdByUserId;
      label = 'Oppdragsgiver';
    } else {
      otherId = job.createdByUserId;
      label = 'Oppdragsgiver';
    }

    if (otherId == null || otherId.isEmpty) return const SizedBox.shrink();
    final other = appState.getUserById(otherId);
    if (other == null) {
      return const SizedBox(height: 14);
    }

    final completedCount = appState.completedJobCountForUser(otherId);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: _card(
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: _primary,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                other.firstName.isNotEmpty
                    ? other.firstName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: _textMuted,
                      fontWeight: FontWeight.w700,
                      fontSize: 11.5,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          other.firstName.isEmpty ? 'Bruker' : other.firstName,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      if (other.isVerified) ...[
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.verified_rounded,
                          color: _primary,
                          size: 16,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Sprint 5: rating + fullført-tall i én kompakt rad,
                  // og differensiert trust under via TrustBadges.
                  // Beholder Wrap her så pill-ene flyter til neste linje
                  // på smale skjermer (samme mønster som profilen).
                  Wrap(
                    spacing: 10,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded,
                              size: 14, color: Color(0xFFFFB020)),
                          const SizedBox(width: 2),
                          Text(
                            other.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 12.5,
                              color: _textPrimary,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.task_alt_rounded,
                              size: 13, color: _accent),
                          const SizedBox(width: 3),
                          Text(
                            completedCount == 1
                                ? '1 fullført oppdrag'
                                : '$completedCount fullførte oppdrag',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: _textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Differensiert trust-rad — erstatter den gamle enkelt-
                  // pillen "Verifisert" som gjaldt e-post alene.
                  TrustBadges(
                    user: other,
                    completedJobCount: completedCount,
                  ),
                ],
              ),
            ),
          ],
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

  Widget _paymentCard(Job job, bool isOwner, bool isWorker) {
    if (isOwner) return _paymentCardOwner(job);
    if (isWorker) return _paymentCardWorker(job);
    return _paymentCardPublic(job);
  }

  Widget _paymentCardOwner(Job job) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeading('Din betaling', Icons.payments_outlined),
          const SizedBox(height: 12),
          _priceRow('Til oppdragstaker', '${job.price} kr'),
          const SizedBox(height: 6),
          _priceRow(
            'Plattformavgift',
            '${job.platformFee.toStringAsFixed(0)} kr',
          ),
          const SizedBox(height: 10),
          Container(height: 1, color: _bg),
          const SizedBox(height: 10),
          _priceRow(
            'Du betaler totalt',
            '${job.totalPrice.toStringAsFixed(0)} kr',
            isBold: true,
          ),
          const SizedBox(height: 14),
          _safetyNote(
            icon: job.isPaidOut ? Icons.check_circle_outline_rounded : Icons.lock_rounded,
            color: _safeGreen,
            text: job.isPaidOut
                ? 'Utbetalingen er gjennomført. Takk for at du brukte SmartHjelp.'
                : 'Beløpet holdes trygt av SmartHjelp og utbetales først når du godkjenner fullført jobb.',
          ),
        ],
      ),
    );
  }

  // FASE 2 PATCH: worker-utbetalingskort er nå tilstandsbevisst.
  Widget _paymentCardWorker(Job job) {
    IconData icon;
    Color color;
    String text;

    if (job.status == JobStatus.completed && job.isPaidOut) {
      icon = Icons.check_circle_outline_rounded;
      color = _safeGreen;
      text =
          'Utbetalingen er gjennomført. Beløpet er frigitt til deg.';
    } else if (job.status == JobStatus.inProgress &&
        job.isCompletedByWorker) {
      icon = Icons.hourglass_top_rounded;
      color = _primary;
      text =
          'Du har markert jobben som fullført. Venter på at oppdragsgiver godkjenner for utbetaling.';
    } else if (job.status == JobStatus.inProgress) {
      icon = Icons.lock_rounded;
      color = _safeGreen;
      text =
          'Oppdraget er i gang. Beløpet er reservert av oppdragsgiver og utbetales etter at du har fullført og fått godkjenning.';
    } else if (job.status == JobStatus.reserved) {
      icon = Icons.bookmark_added_outlined;
      color = _warning;
      text =
          'Oppdraget er reservert til deg. Beløpet reserveres når du starter jobben. Utbetaling skjer etter godkjent fullføring.';
    } else {
      icon = Icons.hourglass_empty_rounded;
      color = _warning;
      text =
          'Beløpet reserveres når du starter jobben. Utbetaling skjer etter godkjent fullføring.';
    }

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeading(
              'Din utbetaling', Icons.account_balance_wallet_outlined),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: _accent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.isPaidOut ? 'Utbetalt' : 'Du får utbetalt',
                      style: const TextStyle(
                        color: _textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${job.payout.toStringAsFixed(0)} kr',
                      style: const TextStyle(
                        color: _textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _safetyNote(icon: icon, color: color, text: text),
        ],
      ),
    );
  }

  Widget _paymentCardPublic(Job job) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeading('Betaling', Icons.payments_outlined),
          const SizedBox(height: 12),
          _priceRow('Oppdragspris', '${job.price} kr', isBold: true),
          const SizedBox(height: 10),
          _safetyNote(
            icon: Icons.shield_outlined,
            color: _safeGreen,
            text:
                'Betaling går via SmartHjelp og utbetales etter godkjent fullføring.',
          ),
        ],
      ),
    );
  }

  Widget _safetyNote({
    required IconData icon,
    required Color color,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.09),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
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
          _infoRow(Icons.visibility_outlined, 'Visninger', '${job.viewCount}'),
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
            color: _primary.withOpacity(0.10),
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
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4E9F2)),
      ),
      child: child,
    );
  }

  // Sprint 6 UX: premium rating-banner som ligger ØVERST i job_detail
  // (rett etter status-bannerene, før hero-gallery). Erstatter det gamle
  // _ratingCard som lå mellom payment- og info-kortet og ble borte i
  // scroll. Visuelt: full gradient-stripe (_primary → _accent) med
  // hvit tekst, stjerne-ikon i glassboks, chevron til høyre — én
  // sammenhengende klikkflate så hele banneret er CTA-en.
  //
  // Vises kun når:
  //   * jobben er completed AND isApprovedByOwner (utbetaling klar)
  //   * bruker er involvert (eier eller worker)
  //   * counterparty finnes
  //   * bruker har IKKE ratet jobben ennå
  // Ellers returneres SizedBox.shrink() — ingen tomt kort, ingen ekstra
  // mellomrom. Banneret forsvinner uten refresh fordi rateForJob
  // optimistisk legger jobId i _ratedJobIds + notifyListeners(), og
  // build() leser hasRatedJob på nytt via context.watch.
  //
  // Backup-knapp finnes også i bottom action area (se _actionButtons)
  // for å fange tilfeller der brukeren scroller forbi eller åpner
  // skjermen igjen senere — begge bruker samme _openRatingDialog.
  Widget _ratingBanner(
    AppState appState,
    Job job,
    bool isOwner,
    bool isWorker,
  ) {
    if (job.status != JobStatus.completed) return const SizedBox.shrink();
    if (!job.isApprovedByOwner) return const SizedBox.shrink();
    if (!isOwner && !isWorker) return const SizedBox.shrink();
    if (appState.hasRatedJob(job.id)) return const SizedBox.shrink();

    final String? counterpartyId = isOwner
        ? job.acceptedByUserId
        : job.createdByUserId;
    if (counterpartyId == null || counterpartyId.isEmpty) {
      return const SizedBox.shrink();
    }
    final UserProfile? counterparty = appState.getUserById(counterpartyId);
    final String counterpartyName =
        (counterparty?.firstName.isNotEmpty ?? false)
            ? counterparty!.firstName
            : 'motparten';

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _openRatingDialog(
            appState,
            jobId: job.id,
            rateeUserId: counterpartyId,
            rateeName: counterpartyName,
          ),
          child: Ink(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_primary, _accent],
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: _primary.withOpacity(0.28),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.20),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.35),
                      width: 1,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.star_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Hvordan var $counterpartyName?',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 15.5,
                          letterSpacing: -0.1,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Gi en kjapp vurdering — det hjelper hele plattformen',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12.5,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openRatingDialog(
    AppState appState, {
    required String jobId,
    required String rateeUserId,
    required String rateeName,
  }) async {
    // Sprint 5.5: dialogen returnerer nå RatingResult (stars + tags),
    // ikke lenger bare double. Tags lagres på serversiden i ratings.tags
    // og brukes senere til topp-tags på trust-kort.
    final result = await showDialog<RatingResult>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const RatingDialog(),
    );
    if (result == null) return; // bruker avbrøt
    if (!mounted) return;

    final stars = result.stars.clamp(1, 5);
    final ok = await appState.rateForJob(
      jobId: jobId,
      rateeUserId: rateeUserId,
      stars: stars,
      tags: result.tags,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? 'Takk for vurderingen! ⭐ $stars'
            : 'Kunne ikke lagre vurderingen. Prøv igjen.'),
        duration: const Duration(seconds: 2),
      ),
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
        'Rediger oppdrag',
        Icons.edit_outlined,
        () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PostJobScreen(existingJob: job),
            ),
          );
        },
      ));
      children.add(_outlinedButton(
        'Slett oppdrag',
        Icons.delete_outline_rounded,
        () => _confirmDelete(job.id),
        isDanger: true,
      ));
    }

    if (!_isLoading && job.status == JobStatus.reserved && isWorker) {
      children.add(_primaryButton(
        'Start jobb',
        Icons.play_arrow_rounded,
        () async {
          await _runAction(() async {
            await appState.startJob(job.id);
            _reload(job.id);
          });
        },
      ));
      children.add(_outlinedButton(
        'Avbryt reservasjon',
        Icons.cancel_outlined,
        () => _confirmCancel(job.id, label: 'Avbryt reservasjon?'),
        color: _warning,
      ));
    }

    if (!_isLoading && job.status == JobStatus.reserved && isOwner) {
      children.add(_outlinedButton(
        'Avbryt reservasjon',
        Icons.cancel_outlined,
        () => _confirmCancel(job.id, label: 'Avbryt reservasjon?'),
        color: _warning,
      ));
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

    if (!_isLoading &&
        (isOwner || isWorker) &&
        job.status == JobStatus.inProgress) {
      children.add(_outlinedButton(
        'Avbryt oppdrag',
        Icons.cancel_outlined,
        () => _confirmCancel(job.id, label: 'Avbryt oppdrag?'),
        isDanger: true,
      ));
    }

    // Sprint 6 UX: backup "Gi vurdering"-knapp i bottom action area.
    // Top-banneret er primær CTA, men dersom brukeren scroller forbi
    // det eller åpner skjermen igjen senere, er denne knappen et fast
    // ankerpunkt nederst. Samme gating + samme _openRatingDialog som
    // banneret, og forsvinner samtidig via hasRatedJob etter rating.
    if (!_isLoading &&
        job.status == JobStatus.completed &&
        job.isApprovedByOwner &&
        (isOwner || isWorker) &&
        !appState.hasRatedJob(job.id)) {
      final String? counterpartyId =
          isOwner ? job.acceptedByUserId : job.createdByUserId;
      if (counterpartyId != null && counterpartyId.isNotEmpty) {
        final UserProfile? counterparty = appState.getUserById(counterpartyId);
        final String counterpartyName =
            (counterparty?.firstName.isNotEmpty ?? false)
                ? counterparty!.firstName
                : 'motparten';
        children.add(_primaryButton(
          'Gi vurdering',
          Icons.star_rounded,
          () => _openRatingDialog(
            appState,
            jobId: job.id,
            rateeUserId: counterpartyId,
            rateeName: counterpartyName,
          ),
        ));
      }
    }

    if (job.acceptedByUserId != null) {
      if (children.isNotEmpty) children.add(const SizedBox(height: 10));
      children.add(_outlinedButton(
        'Åpne chat',
        Icons.chat_bubble_outline_rounded,
        () => _openChat(job),
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
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, -3),
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

  Widget _outlinedButton(
    String text,
    IconData icon,
    VoidCallback onTap, {
    bool isDanger = false,
    Color? color,
  }) {
    final resolved = color ?? (isDanger ? _danger : _primary);
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(text),
        style: OutlinedButton.styleFrom(
          foregroundColor: resolved,
          side: BorderSide(color: resolved.withOpacity(0.35)),
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

  Future<void> _confirmCancel(String jobId, {String label = 'Avbryt oppdrag?'}) async {
    final appState = context.read<AppState>();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(label),
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

  /// Sprint 7 nav-fix: brukt av "Åpne chat"-knappen i bottom action area.
  /// Hvis denne JobDetailScreen ble pushet ovenpå en ChatScreen for samme
  /// jobb (widget.fromChat=true), pop'er vi bare tilbake til den
  /// eksisterende ChatScreen i stedet for å pushe en ny — bryter ping-pong-
  /// loopen JobDetail↔Chat. Ellers pushes en ny ChatScreen med
  /// fromJobDetail=true så loopen brytes også fra den andre siden.
  void _openChat(Job job) {
    if (widget.fromChat) {
      Navigator.pop(context);
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(job: job, fromJobDetail: true),
      ),
    );
  }
}

class _ApprovalBanner extends StatelessWidget {
  final bool isOwner;
  final VoidCallback onApprove;

  const _ApprovalBanner({
    required this.isOwner,
    required this.onApprove,
  });

  @override
  Widget build(BuildContext context) {
    final title = isOwner
        ? 'Oppdragstaker har meldt fra om fullført jobb'
        : 'Venter på godkjenning fra oppdragsgiver';
    final subtitle = isOwner
        ? 'Godkjenn for at utbetaling skal frigis til oppdragstakeren.'
        : 'Du har markert jobben som fullført. Oppdragsgiver må godkjenne før beløpet utbetales.';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _primary.withOpacity(0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _primary.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.verified_outlined,
                    color: _primary, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: _primary,
                        fontSize: 14,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: _textPrimary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isOwner) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onApprove,
                icon: const Icon(Icons.check_rounded, size: 18),
                label: const Text('Godkjenn og betal ut'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
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
    );
  }
}

class _PrivacyBanner extends StatelessWidget {
  final String title;
  final String message;

  const _PrivacyBanner({
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _accent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _accent.withOpacity(0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: _accent.withOpacity(0.18),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.shield_outlined,
                color: _accent, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: _accent,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: const TextStyle(
                    color: _textPrimary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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

    final accent = isMine ? _warning : _danger;
    final bg = isMine ? const Color(0xFFFFF4E5) : const Color(0xFFFDECEC);
    final icon = isMine ? Icons.hourglass_top : Icons.report_gmailerrorred;

    final title = isMine
        ? 'Du har bedt om å avbryte oppdraget'
        : '$requesterName har bedt om å avbryte oppdraget';

    final subtitle = isMine
        ? 'Venter på at den andre parten godkjenner. Oppdraget fortsetter inntil begge parter har godkjent.'
        : 'Begge parter må godkjenne før oppdraget kanselleres. Velg om du vil godkjenne eller avslå.';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withOpacity(0.35), width: 1),
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
                  color: accent.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accent, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: accent,
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
                color: _textPrimary,
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
                  foregroundColor: _warning,
                  side: BorderSide(color: _warning.withOpacity(0.45)),
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
                      backgroundColor: _danger,
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
                      foregroundColor: _danger,
                      side: BorderSide(color: _danger.withOpacity(0.45)),
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