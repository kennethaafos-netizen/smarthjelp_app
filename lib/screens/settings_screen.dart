import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/app_state.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const Color _primary = Color(0xFF2356E8);
  static const Color _bg = Color(0xFFF4F7FC);
  static const Color _textPrimary = Color(0xFF0F1E3A);
  static const Color _textMuted = Color(0xFF6E7A90);
  static const Color _danger = Color(0xFFDC2626);

  // Push-varsler lever på serveren (`profiles.push_notifications_enabled`) og
  // styres via AppState.setPushNotifications. Denne skjermen er ett eneste
  // hovedsted; profile_screen viser bare status og navigerer hit.
  // Lyd-toggelen har ingen server-motpart ennå, så den beholder SharedPreferences.
  static const String _prefSoundEnabled = 'settings_sound_enabled';

  bool _loading = true;
  bool _soundEnabled = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _soundEnabled = prefs.getBool(_prefSoundEnabled) ?? true;
      _loading = false;
    });
  }

  void _setPush(bool value) {
    context.read<AppState>().setPushNotifications(value);
  }

  Future<void> _setSound(bool value) async {
    setState(() => _soundEnabled = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefSoundEnabled, value);
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Logg ut?',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'Du må logge inn på nytt for å bruke SmartHjelp.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Avbryt'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _danger),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Logg ut'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _logout();
  }

  Future<void> _logout() async {
    // Kaller AppState.logout() og lar BootstrapGate bytte til OnboardingScreen
    // automatisk via isAuthenticated-endring. popUntil rydder bort denne
    // pushede skjermen over AppShell.
    final navigator = Navigator.of(context);
    final appState = context.read<AppState>();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('onboarding_done');
    await appState.logout();
    if (!mounted) return;
    navigator.popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final user = appState.currentUser;
    final hasProfile = user.id.isNotEmpty;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        foregroundColor: _textPrimary,
        title: const Text(
          'Innstillinger',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: _textPrimary,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Til hjem',
            icon: const Icon(Icons.home_rounded),
            onPressed: () =>
                Navigator.of(context).popUntil((r) => r.isFirst),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                _sectionLabel('Konto'),
                _card(
                  children: [
                    _infoRow(
                      'Navn',
                      hasProfile && user.firstName.isNotEmpty
                          ? user.firstName
                          : '—',
                    ),
                    _divider(),
                    _infoRow(
                      'E-post',
                      hasProfile && user.email.isNotEmpty ? user.email : '—',
                    ),
                    _divider(),
                    // Sprint 5: presisering. Tidligere stod det "Verifisert"
                    // her, men flagget er reelt sett "e-post bekreftet" og
                    // betyr ikke mer enn det. Differensiert trust vises nå
                    // i Profil/job_detail via TrustBadges.
                    _infoRow(
                      'E-post bekreftet',
                      user.isVerified ? 'Ja' : 'Nei',
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _sectionLabel('Varsler'),
                _card(
                  children: [
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Push-varsler',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: _textPrimary,
                        ),
                      ),
                      subtitle: const Text(
                        'Få varsler om nye meldinger og oppdrag',
                        style: TextStyle(color: _textMuted, fontSize: 12.5),
                      ),
                      value: user.pushNotificationsEnabled,
                      activeColor: _primary,
                      onChanged: hasProfile ? _setPush : null,
                    ),
                    _divider(),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Lyd ved varsel',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: _textPrimary,
                        ),
                      ),
                      subtitle: const Text(
                        'Spill av lyd når det kommer et varsel',
                        style: TextStyle(color: _textMuted, fontSize: 12.5),
                      ),
                      value: _soundEnabled,
                      activeColor: _primary,
                      onChanged: _setSound,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _sectionLabel('Om SmartHjelp'),
                _card(
                  children: [
                    _infoRow('Versjon', '1.0.0 (MVP)'),
                    _divider(),
                    _infoRow('Bygg', 'Sprint 4'),
                  ],
                ),
                const SizedBox(height: 28),
                _dangerButton(
                  icon: Icons.logout_rounded,
                  label: 'Logg ut',
                  onPressed: _confirmLogout,
                ),
                const SizedBox(height: 16),
              ],
            ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 10, 6, 8),
      child: Text(
        text,
        style: const TextStyle(
          color: _textMuted,
          fontWeight: FontWeight.w700,
          fontSize: 12,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _card({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _textMuted.withOpacity(0.12)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(children: children),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: _textMuted,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: _textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: _textMuted.withOpacity(0.12),
    );
  }

  Widget _dangerButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: _danger),
        label: Text(
          label,
          style: const TextStyle(
            color: _danger,
            fontWeight: FontWeight.w800,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: BorderSide(color: _danger.withOpacity(0.5)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}