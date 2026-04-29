import 'package:flutter/material.dart';

import '../models/user_profile.dart';

/// TrustBadges — Sprint 5.
///
/// Viser små "trust"-pills for en bruker basert på flere kriterier i stedet
/// for én "Verifisert"-pille som tidligere kunne gi falsk trygghet.
///
/// Kriterier (alle uavhengige, MVP — uten BankID/SMS):
///   * E-post bekreftet
///   * Profil utfylt (telefon + område)
///   * 1+ fullført oppdrag (regnes opp av AppState og sendes inn her)
///
/// Hvis ALLE tre er oppfylt, vises en ekstra grønn "Pålitelig bruker"-pille
/// som premium-signal.
///
/// Layout: Wrap-rad med små chips. Wrap er bevisst valgt så pill-ene flyter
/// til neste linje på smale skjermer i stedet for å overflowe — samme mønster
/// som i profile_screen header rating-rad.
///
/// Widgeten er rent visuell og endrer ingen state. Den kan brukes både i
/// hvite kort (default) og over mørk/gradient-bakgrunn (sett `onDarkBackground:
/// true` så fargene tilpasses).
class TrustBadges extends StatelessWidget {
  final UserProfile user;
  final int completedJobCount;
  final bool onDarkBackground;
  final bool showNewUserPill;

  /// [showNewUserPill]: Når true vises en grå "Ny bruker"-pille hvis IKKE
  /// noen av de tre kriteriene er oppfylt. Default true. Sett false hvis
  /// callsite ikke vil vise noe når brukeren er helt fersk (f.eks. headeren
  /// til egen profil der vi heller har "Klar for oppdrag"-pill ved siden av).
  const TrustBadges({
    super.key,
    required this.user,
    required this.completedJobCount,
    this.onDarkBackground = false,
    this.showNewUserPill = true,
  });

  static const Color _primary = Color(0xFF2356E8);
  static const Color _accent = Color(0xFF18B7A6);
  static const Color _safeGreen = Color(0xFF0EA877);
  static const Color _muted = Color(0xFF6E7A90);
  static const Color _textPrimary = Color(0xFF0F1E3A);

  @override
  Widget build(BuildContext context) {
    final emailOk = user.hasEmailVerified;
    final profileOk = user.hasCompleteProfile;
    final hasJob = completedJobCount > 0;

    final allOk = emailOk && profileOk && hasJob;
    final anyOk = emailOk || profileOk || hasJob;

    final pills = <Widget>[];

    if (emailOk) {
      pills.add(
        _pill(
          icon: Icons.mark_email_read_outlined,
          label: 'E-post bekreftet',
          color: _primary,
        ),
      );
    }
    if (profileOk) {
      pills.add(
        _pill(
          icon: Icons.badge_outlined,
          label: 'Profil utfylt',
          color: _accent,
        ),
      );
    }
    if (hasJob) {
      pills.add(
        _pill(
          icon: Icons.task_alt_rounded,
          label: completedJobCount == 1
              ? '1+ fullført'
              : '$completedJobCount fullførte',
          color: _safeGreen,
        ),
      );
    }
    if (allOk) {
      pills.add(
        _pill(
          icon: Icons.verified_rounded,
          label: 'Pålitelig bruker',
          color: _safeGreen,
          filled: true,
        ),
      );
    }

    if (!anyOk) {
      if (!showNewUserPill) return const SizedBox.shrink();
      pills.add(
        _pill(
          icon: Icons.person_outline_rounded,
          label: 'Ny bruker',
          color: _muted,
        ),
      );
    }

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: pills,
    );
  }

  Widget _pill({
    required IconData icon,
    required String label,
    required Color color,
    bool filled = false,
  }) {
    final bg = onDarkBackground
        ? (filled
            ? color.withOpacity(0.95)
            : Colors.white.withOpacity(0.18))
        : (filled ? color.withOpacity(0.95) : color.withOpacity(0.10));

    final iconColor = onDarkBackground
        ? (filled ? Colors.white : Colors.white)
        : (filled ? Colors.white : color);

    final textColor = onDarkBackground
        ? (filled ? Colors.white : Colors.white)
        : (filled ? Colors.white : color);

    final borderColor = onDarkBackground
        ? Colors.white.withOpacity(0.30)
        : (filled ? color.withOpacity(0.95) : color.withOpacity(0.22));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: iconColor),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w800,
              fontSize: 11,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}