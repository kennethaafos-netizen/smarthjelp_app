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

      // 🔥 NY PREMIUM BOTTOM BAR
      bottomNavigationBar: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home,
                  label: "Hjem",
                  isActive: _index == 0,
                  onTap: () => _onNavigate(0),
                ),
                _NavItem(
                  icon: Icons.work_outline,
                  activeIcon: Icons.work,
                  label: "Oppdrag",
                  isActive: _index == 1,
                  onTap: () => _onNavigate(1),
                ),

                const SizedBox(width: 60), // plass til FAB

                _NavItem(
                  icon: Icons.chat_bubble_outline,
                  activeIcon: Icons.chat_bubble,
                  label: "Chat",
                  isActive: _index == 3,
                  onTap: () => _onNavigate(3),
                ),
                _NavItem(
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  label: "Profil",
                  isActive: _index == 4,
                  onTap: () => _onNavigate(4),
                ),
              ],
            ),
          ),

          // 🔥 STOR + KNAPP
          Positioned(
            bottom: 20,
            child: GestureDetector(
              onTap: () => _onNavigate(2),
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF4F7BFF),
                      Color(0xFF18B7A6),
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4F7BFF).withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        isActive ? const Color(0xFF2356E8) : const Color(0xFF9AA4B2);

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: color,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}