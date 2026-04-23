import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  static const Color _primary = Color(0xFF2356E8);
  static const Color _accent = Color(0xFF18B7A6);
  static const Color _bg = Color(0xFFF4F7FC);
  static const Color _textPrimary = Color(0xFF0F1E3A);
  static const Color _textMuted = Color(0xFF6E7A90);

  static const String _supportEmail = 'support@smarthjelp.no';
  static const String _pressEmail = 'post@smarthjelp.no';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        foregroundColor: _textPrimary,
        title: const Text(
          'Kontakt oss',
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
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _heroCard(),
          const SizedBox(height: 18),
          _sectionLabel('E-post'),
          _contactTile(
            context: context,
            icon: Icons.support_agent_rounded,
            iconColor: _primary,
            title: 'Kundestøtte',
            value: _supportEmail,
            subtitle: 'Teknisk hjelp og spørsmål om appen',
          ),
          const SizedBox(height: 10),
          _contactTile(
            context: context,
            icon: Icons.business_center_rounded,
            iconColor: _accent,
            title: 'Generell henvendelse',
            value: _pressEmail,
            subtitle: 'Samarbeid, presse og annet',
          ),
          const SizedBox(height: 18),
          _sectionLabel('Svartid'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _textMuted.withOpacity(0.12)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.schedule_rounded,
                    color: _accent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Vi svarer normalt innen 24 timer på hverdager.',
                    style: TextStyle(
                      color: _textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4F7BFF), Color(0xFF18B7A6)],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.headset_mic_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vi er her for deg',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Send oss en e-post, så hører du fra oss snart.',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
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

  Widget _contactTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _textMuted.withOpacity(0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: _primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: _textMuted,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Kopier',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Kopierte $value'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(
              Icons.copy_rounded,
              size: 18,
              color: _textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
