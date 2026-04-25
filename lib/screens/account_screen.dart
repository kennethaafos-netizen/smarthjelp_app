import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _areaCtrl;

  late bool _wantsToWork;

  @override
  void initState() {
    super.initState();

    final user = context.read<AppState>().currentUser;

    _nameCtrl = TextEditingController(text: user.firstName);
    _emailCtrl = TextEditingController(text: user.email);
    _phoneCtrl = TextEditingController(text: user.phone);
    _areaCtrl = TextEditingController(text: user.preferredArea);

    _wantsToWork = user.wantsToWork;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _areaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();

    return Scaffold(
      appBar: AppBar(title: const Text('Min konto')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Navn'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _emailCtrl,
            decoration: const InputDecoration(labelText: 'E-post'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phoneCtrl,
            decoration: const InputDecoration(labelText: 'Telefon'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _areaCtrl,
            decoration: const InputDecoration(labelText: 'Område'),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            value: _wantsToWork,
            title: const Text('Jeg vil ta oppdrag'),
            onChanged: (value) {
              setState(() => _wantsToWork = value);
            },
          ),
          // Push-varsler flyttet til Innstillinger for å ha én kilde til
          // samme tilstand. Denne siden gjelder kun kontodata.
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () {
              appState.updateProfile(
                firstName: _nameCtrl.text.trim(),
                email: _emailCtrl.text.trim(),
                phone: _phoneCtrl.text.trim(),
                wantsToWork: _wantsToWork,
                preferredArea: _areaCtrl.text.trim(),
              );

              Navigator.pop(context);
            },
            child: const Text('Lagre'),
          ),
        ],
      ),
    );
  }
}