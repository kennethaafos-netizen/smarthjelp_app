import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/dummy_data.dart';
import '../providers/app_state.dart';
import '../widgets/app_shell.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int step = 0;
  bool wantsToWork = true;
  String selectedLocation = kLocations.first;
  bool _isFinishing = false;

  Future<void> _next() async {
    if (step < 2) {
      setState(() => step++);
      return;
    }

    if (_isFinishing) return;
    setState(() => _isFinishing = true);

    // 🔒 Koble onboarding til faktisk state (ikke bare kosmetikk).
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
      backgroundColor: const Color(0xFFF4F7FC),
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
          children: const [
            Icon(Icons.handyman_rounded, size: 80, color: Color(0xFF2356E8)),
            SizedBox(height: 20),
            Text(
              'Velkommen til SmartHjelp',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F1E3A),
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Finn hjelp eller tjen penger på småjobber i nærheten.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF6E7A90),
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
        );

      case 1:
        return Column(
          children: [
            const Text(
              'Hva vil du gjøre?',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F1E3A),
              ),
            ),
            const SizedBox(height: 20),
            _choiceCard(
              'Tjene penger',
              wantsToWork,
              () => setState(() => wantsToWork = true),
            ),
            const SizedBox(height: 12),
            _choiceCard(
              'Få hjelp',
              !wantsToWork,
              () => setState(() => wantsToWork = false),
            ),
          ],
        );

      case 2:
        return Column(
          children: [
            const Text(
              'Hvor bor du?',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F1E3A),
              ),
            ),
            const SizedBox(height: 20),
            ...kLocations.map(_locationTile),
          ],
        );

      default:
        return const SizedBox();
    }
  }

  Widget _choiceCard(String text, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF2356E8) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? const Color(0xFF2356E8)
                : const Color(0xFFE6EAF2),
            width: 1.2,
          ),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF0F1E3A),
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _locationTile(String loc) {
    final selected = loc == selectedLocation;

    return GestureDetector(
      onTap: () => setState(() => selectedLocation = loc),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF2356E8) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? const Color(0xFF2356E8)
                : const Color(0xFFE6EAF2),
            width: 1.2,
          ),
        ),
        child: Text(
          loc,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF0F1E3A),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _nextButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isFinishing ? null : _next,
        child: _isFinishing
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(step == 2 ? 'Start' : 'Neste'),
      ),
    );
  }
}
