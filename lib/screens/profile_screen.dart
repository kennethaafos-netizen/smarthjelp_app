// Profile som navigasjonshub — premium header, trust card, completion banner,
// phone quick-edit, og Live status koblet til JobsScreen(initialFilter: ...).
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user_profile.dart';
import '../providers/app_state.dart';
import '../widgets/trust_badges.dart';
import 'account_screen.dart';
import 'export_screen.dart';
import 'jobs_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  // Design tokens
  static const _primary = Color(0xFF2356E8);
  static const _accent = Color(0xFF18B7A6);
  static const _bg = Color(0xFFF4F7FC);
  static const _text = Color(0xFF172033);
  static const _textDark = Color(0xFF0F1E3A);
  static const _muted = Color(0xFF6E7A90);
  static const _safeGreen = Color(0xFF0EA877);
  static const _warn = Color(0xFFF5B301);
  static const _danger = Color(0xFFDC2626);
  static const _borderSoft = Color(0xFFE4E9F2);

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final user = appState.currentUser;

    final activeTaken = appState.activeTakenJobs;
    final completedTaken = appState.completedTakenJobs;
    final activePosted = appState.activePostedJobs;
    final completedPosted = appState.completedPostedJobs;

    final needsCompletion = user.phone.isEmpty || user.preferredArea.isEmpty;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            children: [
              _header(
                context,
                user,
                completedCount: completedTaken.length,
                activeCount: activeTaken.length,
              ),
              if (needsCompletion) ...[
                const SizedBox(height: 12),
                _completionBanner(context),
              ],
              const SizedBox(height: 16),
              _trustCard(
                user: user,
                completedCount: completedTaken.length,
                activeCount: activeTaken.length,
              ),
              const SizedBox(height: 16),
              _earningsCard(
                earned: appState.moneyEarned,
                spent: appState.moneySpent,
                completed: completedTaken.length,
              ),
              const SizedBox(height: 16),
              // Push-varsler administreres kun i Innstillinger. Her viser vi
              // en read-only status-rad som navigerer dit ved trykk, så det
              // ikke finnes to kilder til samme tilstand i UI-et.
              _notificationsRow(context, user.pushNotificationsEnabled),
              const SizedBox(height: 16),
              _section(
                title: 'Live status',
                subtitle: 'Trykk for å se oppdragene',
                child: Column(
                  children: [
                    _PressableStatusRow(
                      label: 'Oppdrag jeg tar',
                      value: activeTaken.length,
                      accent: _primary,
                      onTap: () =>
                          _openJobs(context, JobsFilter.takenActive),
                    ),
                    const SizedBox(height: 8),
                    _PressableStatusRow(
                      label: 'Mine aktive oppdrag',
                      value: activePosted.length,
                      accent: const Color(0xFF8B5CF6),
                      onTap: () =>
                          _openJobs(context, JobsFilter.postedActive),
                    ),
                    const SizedBox(height: 8),
                    _PressableStatusRow(
                      label: 'Fullført av meg',
                      value: completedTaken.length,
                      accent: _safeGreen,
                      onTap: () =>
                          _openJobs(context, JobsFilter.takenCompleted),
                    ),
                    const SizedBox(height: 8),
                    _PressableStatusRow(
                      label: 'Mine fullførte oppdrag',
                      value: completedPosted.length,
                      accent: _muted,
                      onTap: () =>
                          _openJobs(context, JobsFilter.postedCompleted),
                      isLast: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _profileInfo(context, user),
              const SizedBox(height: 16),
              _primaryActionButton(
                icon: Icons.file_download_outlined,
                label: 'Eksporter rapport',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ExportScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _primaryActionButton(
                icon: Icons.settings_outlined,
                label: 'Rediger konto',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AccountScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _logoutButton(context),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- NAV HELPERS ----------
  void _openJobs(BuildContext context, JobsFilter filter) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => JobsScreen(initialFilter: filter),
      ),
    );
  }

  void _openPhoneSheet(BuildContext context, UserProfile user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _PhoneEditSheet(user: user),
    );
  }

  // ---------- HEADER ----------
  Widget _header(
    BuildContext context,
    UserProfile user, {
    required int completedCount,
    required int activeCount,
  }) {
    // Sprint 5: bug-fix på tvers av profil-skjermen.
    // Tidligere brukte vi `user.email.isNotEmpty` som proxy for "verifisert".
    // Det var feil — alle innloggede brukere har e-post-attributt, men ikke
    // alle har bekreftet den. Bruk det reelle server-flagget i stedet.
    // Vi viser nå differensiert trust via TrustBadges, ikke en enkel
    // "Verifisert"-pille.
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_primary, _accent],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.22),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 76,
                height: 76,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.35),
                    width: 1.5,
                  ),
                ),
                child: Text(
                  user.firstName.isNotEmpty
                      ? user.firstName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.firstName.isEmpty ? 'Gjest' : user.firstName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _statusPill(
                      user.wantsToWork ? 'Klar for oppdrag' : 'Søker hjelp',
                    ),
                    const SizedBox(height: 8),
                    // Wrap lar innholdet flyte til neste linje på smale
                    // skjermer i stedet for å overflowe (RenderFlex
                    // RIGHT OVERFLOWED indikator i debug-mode).
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: Color(0xFFFFD166),
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              user.ratingCount == 0
                                  ? '${user.rating.toStringAsFixed(1)}  ·  Ny'
                                  : '${user.rating.toStringAsFixed(1)} (${user.ratingCount})',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5,
                              ),
                            ),
                          ],
                        ),
                        // Sprint 5: differensiert trust i stedet for én
                        // upresis "Verifisert"-pille. Beholder _verifiedPill
                        // som privat helper i fila for bakoverkompatibilitet,
                        // men bruker den ikke fra UI-en lenger.
                        TrustBadges(
                          user: user,
                          completedJobCount: completedCount,
                          onDarkBackground: true,
                          showNewUserPill: false,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _editChip(context),
            ],
          ),
          const SizedBox(height: 16),
          _headerStatsRow(
            completed: completedCount,
            active: activeCount,
          ),
        ],
      ),
    );
  }

  Widget _statusPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.30), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: Color(0xFF6EE7B7),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _editChip(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const AccountScreen(),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.22),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: Colors.white.withOpacity(0.35),
            width: 1,
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.edit_outlined, color: Colors.white, size: 14),
            SizedBox(width: 5),
            Text(
              'Rediger',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _verifiedPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.22),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_rounded, color: Colors.white, size: 13),
          SizedBox(width: 4),
          Text(
            'Verifisert',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerStatsRow({required int completed, required int active}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.20), width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: _headerMiniStat(
              icon: Icons.task_alt_rounded,
              label: 'Fullført',
              value: '$completed',
            ),
          ),
          Container(
            width: 1,
            height: 28,
            color: Colors.white.withOpacity(0.22),
          ),
          Expanded(
            child: _headerMiniStat(
              icon: Icons.autorenew_rounded,
              label: 'Aktive',
              value: '$active',
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerMiniStat({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.95), size: 16),
        const SizedBox(width: 8),
        Text(
          '$value ',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.88),
            fontWeight: FontWeight.w600,
            fontSize: 12.5,
          ),
        ),
      ],
    );
  }

  // ---------- COMPLETION BANNER ----------
  Widget _completionBanner(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const AccountScreen(),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _warn.withOpacity(0.10),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _warn.withOpacity(0.35), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _warn.withOpacity(0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.info_outline_rounded,
                color: _warn,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fullfør profilen din',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: _textDark,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Legg til telefonnummer og område for å få full tilgang.',
                    style: TextStyle(
                      color: _muted,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: _muted),
          ],
        ),
      ),
    );
  }

  // ---------- TRUST CARD ----------
  Widget _trustCard({
    required UserProfile user,
    required int completedCount,
    required int activeCount,
  }) {
    // Sprint 5: bug-fix. Bruker det reelle server-flagget i stedet for
    // `user.email.isNotEmpty`. Dette kortet viser fortsatt 4 numeriske
    // tiles, men nederst legger vi til TrustBadges-rad som differensierer
    // mellom e-post-bekreftet, profil-utfylt og fullført-oppdrag —
    // pluss en grønn "Pålitelig bruker"-pille når alle tre er oppfylt.
    final isEmailVerified = user.isVerified;
    return _section(
      title: 'Trust',
      subtitle: 'Dine tall som bygger tillit hos andre brukere',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _trustTile(
                  icon: Icons.star_rounded,
                  accent: _warn,
                  label: 'Rating',
                  value: user.rating.toStringAsFixed(1),
                  sub: user.ratingCount == 0
                      ? 'Ingen vurderinger enda'
                      : '${user.ratingCount} vurderinger',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _trustTile(
                  icon: Icons.mark_email_read_outlined,
                  accent: _primary,
                  label: 'E-post',
                  value: isEmailVerified ? 'Bekreftet' : 'Ikke bekreftet',
                  sub: isEmailVerified
                      ? 'Brukeren har bekreftet e-post'
                      : 'Be brukeren bekrefte e-post',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _trustTile(
                  icon: Icons.task_alt_rounded,
                  accent: _safeGreen,
                  label: 'Fullførte oppdrag',
                  value: '$completedCount',
                  sub: 'Totalt fullført',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _trustTile(
                  icon: Icons.autorenew_rounded,
                  accent: _accent,
                  label: 'Aktive oppdrag',
                  value: '$activeCount',
                  sub: 'Pågående akkurat nå',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Sprint 5: differensiert trust-rad. Wrap så pill-ene flyter til
          // neste linje på smale skjermer. "Pålitelig bruker"-pille dukker
          // opp som ekstra grønn pille når alle tre kriterier er oppfylt.
          TrustBadges(
            user: user,
            completedJobCount: completedCount,
          ),
        ],
      ),
    );
  }

  Widget _trustTile({
    required IconData icon,
    required Color accent,
    required String label,
    required String value,
    String? sub,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withOpacity(0.18), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accent, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10.5,
              color: accent,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: _textDark,
              letterSpacing: -0.4,
            ),
          ),
          if (sub != null) ...[
            const SizedBox(height: 2),
            Text(
              sub,
              style: const TextStyle(
                color: _muted,
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ---------- EARNINGS / STATS ----------
  Widget _earningsCard({
    required double earned,
    required double spent,
    required int completed,
  }) {
    return _section(
      title: 'Oversikt',
      child: Row(
        children: [
          Expanded(
            child: _miniStat(
              'Tjent',
              '${earned.toStringAsFixed(0)} kr',
              color: _safeGreen,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _miniStat(
              'Brukt',
              '${spent.toStringAsFixed(0)} kr',
              color: _primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _miniStat(
              'Fullført',
              '$completed',
              color: _accent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value, {required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10.5,
              color: color,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: _textDark,
                letterSpacing: -0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- NOTIFICATIONS ROW (navigerer til Innstillinger) ----------
  // Erstatter det gamle _switchCard. Én kilde til push-tilstand = Innstillinger.
  // Her vises status som pille, og raden pusher til SettingsScreen ved trykk.
  Widget _notificationsRow(BuildContext context, bool enabled) {
    return _section(
      title: 'Varsler',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          );
        },
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _primary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.notifications_active_outlined,
                color: _primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Push-varsler',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14.5,
                      color: _text,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Administreres i Innstillinger',
                    style: TextStyle(
                      color: _muted,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: enabled
                    ? _safeGreen.withOpacity(0.12)
                    : _muted.withOpacity(0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                enabled ? 'På' : 'Av',
                style: TextStyle(
                  color: enabled ? _safeGreen : _muted,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.chevron_right_rounded,
              color: _muted.withOpacity(0.8),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- PROFILE INFO ----------
  Widget _profileInfo(BuildContext context, UserProfile user) {
    return _section(
      title: 'Profil',
      child: Column(
        children: [
          _infoRow('Navn', user.firstName.isEmpty ? 'Ikke satt' : user.firstName),
          _infoRow('E-post', user.email.isEmpty ? 'Ikke satt' : user.email),
          if (user.phone.isEmpty)
            _addPhoneRow(context, user)
          else
            _infoRow('Telefon', user.phone),
          if (user.preferredArea.isNotEmpty) _infoRow('Område', user.preferredArea),
          _infoRow(
            'Vil ta oppdrag',
            user.wantsToWork ? 'Ja' : 'Nei',
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(top: 10, bottom: isLast ? 0 : 10),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: _muted,
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                  ),
                ),
              ),
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: _text,
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                ),
              ),
            ],
          ),
          if (!isLast) ...[
            const SizedBox(height: 10),
            Divider(
              height: 1,
              thickness: 1,
              color: _muted.withOpacity(0.10),
            ),
          ],
        ],
      ),
    );
  }

  Widget _addPhoneRow(BuildContext context, UserProfile user) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 10),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Telefon',
                  style: TextStyle(
                    color: _muted,
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => _openPhoneSheet(context, user),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: _primary.withOpacity(0.25),
                      width: 1,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, color: _primary, size: 15),
                      SizedBox(width: 4),
                      Text(
                        'Legg til telefonnummer',
                        style: TextStyle(
                          color: _primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(
            height: 1,
            thickness: 1,
            color: _muted.withOpacity(0.10),
          ),
        ],
      ),
    );
  }

  // ---------- ACTION BUTTONS ----------
  Widget _primaryActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_primary, _accent],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _primary.withOpacity(0.24),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  Widget _logoutButton(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await context.read<AppState>().logout();
      },
      child: Container(
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _danger.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _danger.withOpacity(0.30),
            width: 1.2,
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, color: _danger, size: 18),
            SizedBox(width: 8),
            Text(
              'Logg ut',
              style: TextStyle(
                color: _danger,
                fontWeight: FontWeight.w800,
                fontSize: 14.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- SECTION WRAPPER ----------
  Widget _section({
    required String title,
    String? subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: _textDark,
              letterSpacing: -0.2,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: _muted,
              ),
            ),
          ],
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

// ---------- PRESSABLE STATUS ROW ----------
class _PressableStatusRow extends StatefulWidget {
  final String label;
  final int value;
  final Color accent;
  final VoidCallback onTap;
  final bool isLast;

  const _PressableStatusRow({
    required this.label,
    required this.value,
    required this.accent,
    required this.onTap,
    this.isLast = false,
  });

  @override
  State<_PressableStatusRow> createState() => _PressableStatusRowState();
}

class _PressableStatusRowState extends State<_PressableStatusRow> {
  static const _text = Color(0xFF172033);
  static const _muted = Color(0xFF6E7A90);

  bool _pressed = false;

  void _setPressed(bool v) {
    if (_pressed == v) return;
    setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: widget.accent.withOpacity(_pressed ? 0.16 : 0.09),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.accent.withOpacity(_pressed ? 0.32 : 0.18),
              width: 1,
            ),
            boxShadow: _pressed
                ? []
                : [
                    BoxShadow(
                      color: widget.accent.withOpacity(0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: widget.accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: _text,
                    fontSize: 14,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.accent.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${widget.value}',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: widget.accent,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.chevron_right_rounded,
                color: _muted.withOpacity(0.8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------- PHONE EDIT SHEET ----------
class _PhoneEditSheet extends StatefulWidget {
  final UserProfile user;

  const _PhoneEditSheet({required this.user});

  @override
  State<_PhoneEditSheet> createState() => _PhoneEditSheetState();
}

class _PhoneEditSheetState extends State<_PhoneEditSheet> {
  late final TextEditingController _ctrl;

  static const _primary = Color(0xFF2356E8);
  static const _textDark = Color(0xFF0F1E3A);
  static const _muted = Color(0xFF6E7A90);
  static const _bg = Color(0xFFF4F7FC);

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.user.phone);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final phone = _ctrl.text.trim();
    final appState = context.read<AppState>();
    appState.updateBasicProfile(
      firstName: widget.user.firstName,
      phone: phone,
    );
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Telefonnummer lagret'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: _muted.withOpacity(0.25),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const Text(
            'Legg til telefonnummer',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: _textDark,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Telefonnummeret vises kun til brukere du har aktive oppdrag med.',
            style: TextStyle(
              color: _muted,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _ctrl,
            autofocus: true,
            keyboardType: TextInputType.phone,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: _textDark,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: _bg,
              prefixIcon: const Icon(Icons.phone_outlined, color: _primary),
              hintText: 'f.eks. 404 12 345',
              hintStyle: const TextStyle(
                color: _muted,
                fontWeight: FontWeight.w500,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _primary, width: 1.4),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              child: const Text('Lagre'),
            ),
          ),
        ],
      ),
    );
  }
}