import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/dummy_data.dart';
import '../providers/app_state.dart';

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

  bool _isLoginMode = false;
  bool _isSubmitting = false;

  bool wantsToWork = true;
  late String selectedLocation = kLocations.first;

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Hvis vi havner her mens en gammel session fortsatt finnes, logg ut.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final app = context.read<AppState>();
      if (app.isAuthenticated) {
        app.logout();
      }
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitRegister() async {
    FocusScope.of(context).unfocus();
    setState(() => _isSubmitting = true);

    final error = await context.read<AppState>().register(
          email: _emailCtrl.text,
          password: _passwordCtrl.text,
          name: _nameCtrl.text,
          wantsToWork: wantsToWork,
          preferredArea: selectedLocation,
        );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (error != null) {
      _showMessage(error);
      return;
    }
    // BootstrapGate bytter til AppShell automatisk når isAuthenticated=true.
  }

  Future<void> _submitLogin() async {
    FocusScope.of(context).unfocus();
    setState(() => _isSubmitting = true);

    final error = await context.read<AppState>().login(
          email: _emailCtrl.text,
          password: _passwordCtrl.text,
        );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (error != null) {
      _showMessage(error);
      return;
    }
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _next() async {
    if (_isLoginMode) {
      await _submitLogin();
      return;
    }

    if (step < 3) {
      if (step == 2 && selectedLocation.trim().isEmpty) {
        _showMessage('Velg sted først');
        return;
      }
      setState(() => step++);
      return;
    }

    await _submitRegister();
  }

  void _enterLoginMode() {
    setState(() {
      _isLoginMode = true;
      step = 0;
    });
  }

  void _exitLoginMode() {
    setState(() {
      _isLoginMode = false;
      step = 0;
    });
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
              Expanded(
                flex: 10,
                child: SingleChildScrollView(
                  child: _isLoginMode ? _loginContent() : _registerContent(),
                ),
              ),
              const Spacer(),
              _nextButton(),
              const SizedBox(height: 10),
              _modeToggle(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _registerContent() {
    switch (step) {
      case 0:
        return _welcomeContent();
      case 1:
        return _workChoiceContent();
      case 2:
        return _locationContent();
      case 3:
        return _accountContent();
      default:
        return const SizedBox();
    }
  }

  Widget _welcomeContent() {
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
  }

  Widget _workChoiceContent() {
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
  }

  Widget _locationContent() {
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
          'Velg sted. Du kan endre dette senere.',
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
  }

  Widget _accountContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Opprett konto',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: _textPrimary,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Vi bruker kontoen for innlogging og sikker betaling.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 18),
        _textField(
          controller: _nameCtrl,
          hint: 'Navn',
          icon: Icons.person_outline_rounded,
        ),
        const SizedBox(height: 10),
        _textField(
          controller: _emailCtrl,
          hint: 'E-post',
          icon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 10),
        _textField(
          controller: _passwordCtrl,
          hint: 'Passord (minst 6 tegn)',
          icon: Icons.lock_outline_rounded,
          isPassword: true,
        ),
      ],
    );
  }

  Widget _loginContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: _primary.withOpacity(0.10),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.lock_outline_rounded,
            size: 34,
            color: _primary,
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Logg inn',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: _textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Skriv inn e-post og passord for å fortsette.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 18),
        _textField(
          controller: _emailCtrl,
          hint: 'E-post',
          icon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 10),
        _textField(
          controller: _passwordCtrl,
          hint: 'Passord',
          icon: Icons.lock_outline_rounded,
          isPassword: true,
        ),
      ],
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borderSoft, width: 1),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboardType,
        autocorrect: false,
        enableSuggestions: !isPassword,
        style: const TextStyle(
          color: _textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 14.5,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            color: _textMuted,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(icon, color: _primary, size: 20),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 14,
          ),
        ),
      ),
    );
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
    final String label;
    if (_isLoginMode) {
      label = 'Logg inn';
    } else if (step == 3) {
      label = 'Opprett konto';
    } else {
      label = 'Neste';
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _next,
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
        child: _isSubmitting
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(label),
      ),
    );
  }

  Widget _modeToggle() {
    if (_isLoginMode) {
      return TextButton(
        onPressed: _isSubmitting ? null : _exitLoginMode,
        child: const Text(
          'Ny her? Opprett konto',
          style: TextStyle(
            color: _primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }
    return TextButton(
      onPressed: _isSubmitting ? null : _enterLoginMode,
      child: const Text(
        'Har du allerede konto? Logg inn',
        style: TextStyle(
          color: _primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
