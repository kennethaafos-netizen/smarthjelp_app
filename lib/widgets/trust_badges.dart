import 'package:flutter/material.dart';

import '../models/user_profile.dart';

/// TrustBadges — roligere, ærlig profil-/identitets-rad.
///
/// V1-prinsipp:
///   * Full "Verifisert bruker" finnes IKKE før BankID er på plass. Vi
///     prøver derfor IKKE å sette sammen flere flagg til en
///     "Pålitelig bruker"-pille — det ville feilkommunisert identitets-
///     verifisering.
///   * "Fullførte oppdrag" er en statistikk, ikke et identitets-signal,
///     og blir vist i statistikk-fliser andre steder. Den hører ikke
///     hjemme i denne raden.
///   * "BankID kommer" vises alltid som en dempet markør slik at
///     brukeren forstår at en fullstendig verifisering er på vei, men
///     ikke aktiv ennå.
///
/// Innhold:
///   * Valgfri: «E-post bekreftet» når [UserProfile.hasEmailVerified].
///   * Valgfri: «Profil utfylt» når [UserProfile.hasCompleteProfile]
///     (telefon + område).
///   * Alltid: «BankID kommer» i en rolig nøytral stil.
///
/// Widgeten er rent visuell og endrer ingen state. Den fungerer både i
/// hvite kort (default) og over mørk/gradient-bakgrunn (sett
/// `onDarkBackground: true` så fargene tilpasses).
class TrustBadges extends StatelessWidget {
  final UserProfile user;
  final bool onDarkBackground;

  const TrustBadges({
    super.key,
    required this.user,
    this.onDarkBackground = false,
  });

  static const Color _primary = Color(0xFF2356E8);
  static const Color _accent = Color(0xFF18B7A6);
  static const Color _muted = Color(0xFF6E7A90);

  @override
  Widget build(BuildContext context) {
    final emailOk = user.hasEmailVerified;
    final profileOk = user.hasCompleteProfile;

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
    // Alltid synlig dempet markør. Signaliserer at full identitets-
    // verifisering kommer (BankID), uten å påstå at den er aktiv.
    pills.add(
      _pill(
        icon: Icons.fingerprint_rounded,
        label: 'BankID kommer',
        color: _muted,
        pending: true,
      ),
    );

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
    bool pending = false,
  }) {
    // Pending = BankID kommer: dempet, ingen sterk farge. Ellers en
    // rolig kulør-tonet pille som matcher resten av appen.
    final bg = onDarkBackground
        ? Colors.white.withValues(alpha: pending ? 0.10 : 0.18)
        : color.withValues(alpha: pending ? 0.06 : 0.10);

    final iconColor = onDarkBackground
        ? Colors.white.withValues(alpha: pending ? 0.75 : 1.0)
        : (pending ? color.withValues(alpha: 0.75) : color);

    final textColor = onDarkBackground
        ? Colors.white.withValues(alpha: pending ? 0.80 : 1.0)
        : (pending ? color.withValues(alpha: 0.85) : color);

    final borderColor = onDarkBackground
        ? Colors.white.withValues(alpha: pending ? 0.18 : 0.30)
        : color.withValues(alpha: pending ? 0.14 : 0.22);

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
