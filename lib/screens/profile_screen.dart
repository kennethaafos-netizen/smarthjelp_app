import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/job.dart';
import '../models/user_profile.dart';
import '../providers/app_state.dart';
import 'account_screen.dart';
import 'export_screen.dart';
import 'job_detail_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const _primary = Color(0xFF2356E8);
  static const _accent = Color(0xFF18B7A6);
  static const _bg = Color(0xFFF4F7FC);
  static const _text = Color(0xFF172033);
  static const _textDark = Color(0xFF0F1E3A);
  static const _muted = Color(0xFF6E7A90);
  static const _safeGreen = Color(0xFF0EA877);

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final user = appState.currentUser;

    final activeTaken = appState.activeTakenJobs;
    final completedTaken = appState.completedTakenJobs;
    final activePosted = appState.activePostedJobs;
    final completedPosted = appState.completedPostedJobs;

    final reservedJobs =
        activeTaken.where((j) => j.status == JobStatus.reserved).length;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            children: [
              _header(context, user),
              const SizedBox(height: 16),
              _earningsCard(
                earned: appState.moneyEarned,
                spent: appState.moneySpent,
                completed: completedTaken.length,
              ),
              const SizedBox(height: 16),
              _switchCard(
                value: user.pushNotificationsEnabled,
                onChanged: (v) => appState.setPushNotifications(v),
              ),
              const SizedBox(height: 16),
              _section(
                title: 'Live status',
                child: Column(
                  children: [
                    _statusRow(
                      context,
                      label: 'Reserverte oppdrag',
                      value: reservedJobs,
                      jobs: activeTaken
                          .where((j) => j.status == JobStatus.reserved)
                          .toList(),
                      accent: const Color(0xFFF5B301),
                    ),
                    _statusRow(
                      context,
                      label: 'Oppdrag jeg tar',
                      value: activeTaken.length,
                      jobs: activeTaken,
                      accent: _primary,
                    ),
                    _statusRow(
                      context,
                      label: 'Fullført av meg',
                      value: completedTaken.length,
                      jobs: completedTaken,
                      accent: _safeGreen,
                    ),
                    _statusRow(
                      context,
                      label: 'Mine aktive oppdrag',
                      value: activePosted.length,
                      jobs: activePosted,
                      accent: const Color(0xFF8B5CF6),
                    ),
                    _statusRow(
                      context,
                      label: 'Mine fullførte oppdrag',
                      value: completedPosted.length,
                      jobs: completedPosted,
                      accent: _muted,
                      isLast: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _section(
                title: 'Profil',
                child: Column(
                  children: [
                    _infoRow('Navn', user.firstName),
                    _infoRow('E-post',
                        user.email.isEmpty ? 'Ikke satt' : user.email),
                    _infoRow('Telefon',
                        user.phone.isEmpty ? 'Ikke satt' : user.phone),
                    _infoRow('Område', user.preferredArea),
                    _infoRow(
                      'Vil ta oppdrag',
                      user.wantsToWork ? 'Ja' : 'Nei',
                      isLast: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _primaryActionButton(
                icon: Icons.file_download_outlined,
                label: 'Eksporter rapport',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ExportScreen()),
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
                    MaterialPageRoute(builder: (_) => const AccountScreen()),
                  );
                },
              ),
              // 🔒 Test-knappen er kun synlig i debug-builds.
              if (kDebugMode) ...[
                const SizedBox(height: 12),
                _outlinedActionButton(
                  label: 'Bytt bruker (test)',
                  onTap: () {
                    context.read<AppState>().switchUser();
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context, UserProfile user) {
    final isVerified = user.email.isNotEmpty && user.phone.isNotEmpty;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
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
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
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
                fontSize: 28,
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
                  user.firstName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.wantsToWork ? 'Klar for oppdrag' : 'Søker hjelp',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.92),
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: Color(0xFFFFD166),
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${user.rating.toStringAsFixed(1)} (${user.ratingCount})',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
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
          _editChip(context),
        ],
      ),
    );
  }

  Widget _editChip(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AccountScreen()),
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

  Widget _statusRow(
    BuildContext context, {
    required String label,
    required int value,
    required List<Job> jobs,
    required Color accent,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => _JobListScreen(title: label, jobs: jobs),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: accent.withOpacity(0.09),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: accent.withOpacity(0.18), width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: _text,
                    fontSize: 14,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$value',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: accent,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.chevron_right_rounded,
                  color: _muted.withOpacity(0.8)),
            ],
          ),
        ),
      ),
    );
  }

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
            child: _miniStat('Tjent', '${earned.toStringAsFixed(0)} kr',
                color: _safeGreen),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _miniStat('Brukt', '${spent.toStringAsFixed(0)} kr',
                color: _primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _miniStat('Fullført', '$completed', color: _accent),
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

  Widget _switchCard({
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return _section(
      title: 'Varsler',
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
                  'Få beskjed når nye oppdrag dukker opp',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: _primary,
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
            const Icon(Icons.chevron_right_rounded, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _outlinedActionButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _primary.withOpacity(0.25),
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: _primary,
            fontWeight: FontWeight.w800,
            fontSize: 14.5,
          ),
        ),
      ),
    );
  }

  Widget _section({required String title, required Widget child}) {
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
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _JobListScreen extends StatelessWidget {
  final String title;
  final List<Job> jobs;

  const _JobListScreen({required this.title, required this.jobs});

  Widget _statusBadge(JobStatus status) {
    Color color;
    String text;

    switch (status) {
      case JobStatus.reserved:
        color = Colors.orange;
        text = 'Reservert';
        break;
      case JobStatus.inProgress:
        color = Colors.blue;
        text = 'Pågår';
        break;
      case JobStatus.completed:
        color = Colors.green;
        text = 'Fullført';
        break;
      default:
        color = Colors.grey;
        text = 'Åpen';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(title: Text(title)),
      body: jobs.isEmpty
          ? const Center(child: Text('Ingen oppdrag'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: jobs.length,
              itemBuilder: (_, i) {
                final job = jobs[i];

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                      )
                    ],
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => JobDetailScreen(job: job),
                        ),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                job.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            _statusBadge(job.status),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(job.locationName),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${job.price} kr'),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
