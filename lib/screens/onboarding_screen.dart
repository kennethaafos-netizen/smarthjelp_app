import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/dummy_data.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int step = 0;

  bool wantsToWork = true;
  String selectedLocation = kLocations.first;

  void next() async {
    if (step < 2) {
      setState(() => step++);
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_done', true);

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
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
            Icon(Icons.handyman, size: 80, color: Colors.blue),
            SizedBox(height: 20),
            Text(
              "Velkommen til SmartHjelp",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              "Finn hjelp eller tjen penger på småjobber i nærheten",
              textAlign: TextAlign.center,
            ),
          ],
        );

      case 1:
        return Column(
          children: [
            const Text(
              "Hva vil du gjøre?",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _choiceCard(
              "Tjene penger",
              wantsToWork,
              () => setState(() => wantsToWork = true),
            ),
            const SizedBox(height: 12),
            _choiceCard(
              "Få hjelp",
              !wantsToWork,
              () => setState(() => wantsToWork = false),
            ),
          ],
        );

      case 2:
        return Column(
          children: [
            const Text(
              "Hvor bor du?",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ...kLocations.map((loc) => _locationTile(loc)),
          ],
        );

      default:
        return const SizedBox();
    }
  }

  Widget _choiceCard(String text, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected ? Colors.blue : Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _locationTile(String loc) {
    final selected = loc == selectedLocation;

    return GestureDetector(
      onTap: () => setState(() => selectedLocation = loc),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? Colors.blue : Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          loc,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _nextButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: next,
        child: Text(step == 2 ? "Start" : "Neste"),
      ),
    );
  }
}