import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/dummy_data.dart';
import '../providers/app_state.dart';
import '../widgets/app_shell.dart';

const Color _primary = Color(0xFF2356E8);
const Color _bg = Color(0xFFF4F7FC);
const Color _textPrimary = Color(0xFF0F1E3A);
const Color _textMuted = Color(0xFF6E7A90);
const Color _borderSoft = Color(0xFFE4E9F2);

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int step = 0;

  bool wantsToWork = true;
  late String selectedLocation = kLocations.first;

  Future<void> next() async {
    if (step < 2) {
      setState(() => step++);
      return;
    }

    if (selectedLocation.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Velg sted først'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    context.read<AppState>().applyOnboarding(
          wantsToWork: wantsToWork,
          preferredArea: selectedLocation,
        );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AppShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              _buildContent(),
              const Spacer(),
              _nextButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (step) {
      case 0:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: _primary.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.handyman_rounded,
                size: 46,
                color: _primary,
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'Velkommen til SmartHjelp',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: _textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Finn hjelp eller tjen penger på småjobber i nærheten.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _textMuted,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ],
        );

      case 1:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Hva vil du gjøre?',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: _textPrimary,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 20),
            _choiceCard(
              'Tjene penger',
              'Jeg vil ta oppdrag og jobbe for andre.',
              Icons.work_outline_rounded,
              wantsToWork,
              () => setState(() => wantsToWork = true),
            ),
            const SizedBox(height: 12),
            _choiceCard(
              'Få hjelp',
              'Jeg vil legge ut oppdrag og få hjelp.',
              Icons.volunteer_activism_outlined,
              !wantsToWork,
              () => setState(() => wantsToWork = false),
            ),
          ],
        );

      case 2:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Hvor bor du?',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: _textPrimary,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Velg kommunen din. Du kan endre dette senere.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 18),
            ...kLocations.map(_locationTile),
          ],
        );

      default:
        return const SizedBox();
    }
  }

  Widget _choiceCard(
    String title,
    String subtitle,
    IconData icon,
    bool selected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? _primary : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? _primary : _borderSoft,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withOpacity(0.18)
                    : _primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 20,
                color: selected ? Colors.white : _primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: selected ? Colors.white : _textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: selected
                          ? Colors.white.withOpacity(0.88)
                          : _textMuted,
                      fontWeight: FontWeight.w500,
                      fontSize: 12.5,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_rounded, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _locationTile(String loc) {
    final selected = loc == selectedLocation;

    return GestureDetector(
      onTap: () => setState(() => selectedLocation = loc),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? _primary : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? _primary : _borderSoft,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.place_outlined,
              size: 18,
              color: selected ? Colors.white : _primary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                loc,
                style: TextStyle(
                  color: selected ? Colors.white : _textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14.5,
                ),
              ),
            ),
            if (selected)
              const Icon(Icons.check_rounded, color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _nextButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: next,
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 15,
            letterSpacing: 0.1,
          ),
        ),
        child: Text(step == 2 ? 'Start' : 'Neste'),
      ),
    );
  }
}
