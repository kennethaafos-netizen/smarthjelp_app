import 'package:flutter/material.dart';

import '../screens/chat_list_screen.dart';
import '../screens/home_screen.dart';
import '../screens/jobs_screen.dart';
import '../screens/post_job_screen.dart';
import '../screens/profile_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  void _onNavigate(int i) {
    setState(() => _index = i);
  }

  Widget _buildScreen() {
    switch (_index) {
      case 0:
        return HomeScreen(onNavigate: _onNavigate);
      case 1:
        return const JobsScreen();
      case 2:
        return const PostJobScreen();
      case 3:
        return const ChatListScreen();
      case 4:
        return const ProfileScreen();
      default:
        return HomeScreen(onNavigate: _onNavigate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildScreen(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _onNavigate,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Hjem',
          ),
          NavigationDestination(
            icon: Icon(Icons.work_outline),
            selectedIcon: Icon(Icons.work),
            label: 'Oppdrag',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            selectedIcon: Icon(Icons.add_circle),
            label: 'Legg ut',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Chat',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}