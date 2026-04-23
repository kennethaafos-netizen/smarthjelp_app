import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
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
    // FASE 3: bottom-nav lytter på AppState for å få live badge-oppdatering
    // på chat-knappen. Provider i main.dart gir oss tilgangen.
    final chatBadge = context.watch<AppState>().unreadChatNotificationCount;

    return Scaffold(
      extendBody: true,
      body: _buildScreen(),
      bottomNavigationBar: SizedBox(
        height: 108,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 14),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 22,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavItem(
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home_rounded,
                    label: 'Hjem',
                    isActive: _index == 0,
                    onTap: () => _onNavigate(0),
                  ),
                  _NavItem(
                    icon: Icons.work_outline_rounded,
                    activeIcon: Icons.work_rounded,
                    label: 'Oppdrag',
                    isActive: _index == 1,
                    onTap: () => _onNavigate(1),
                  ),
                  const SizedBox(width: 66),
                  _NavItem(
                    icon: Icons.chat_bubble_outline_rounded,
                    activeIcon: Icons.chat_bubble_rounded,
                    label: 'Chat',
                    isActive: _index == 3,
                    onTap: () => _onNavigate(3),
                    badgeCount: chatBadge,
                  ),
                  _NavItem(
                    icon: Icons.person_outline_rounded,
                    activeIcon: Icons.person_rounded,
                    label: 'Profil',
                    isActive: _index == 4,
                    onTap: () => _onNavigate(4),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 30,
              child: GestureDetector(
                onTap: () => _onNavigate(2),
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF4F7BFF),
                        Color(0xFF18B7A6),
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4F7BFF).withOpacity(0.45),
                        blurRadius: 22,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: Colors.white.withOpacity(0.9),
                        blurRadius: 0,
                        spreadRadius: 3,
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
            ),
          ],
        ),
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

  // FASE 3: badgeCount > 0 tegner rød badge over ikonet.
  final int badgeCount;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        isActive ? const Color(0xFF2356E8) : const Color(0xFF9AA4B2);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 62,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isActive ? activeIcon : icon,
                  color: color,
                  size: 22,
                ),
                if (badgeCount > 0)
                  Positioned(
                    right: -8,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        badgeCount > 9 ? '9+' : '$badgeCount',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
