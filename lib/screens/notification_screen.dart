import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AppState>().markAllNotificationsRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final items = app.notifications;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0F1E3A)),
        title: const Text(
          'Varsler',
          style: TextStyle(
            color: Color(0xFF0F1E3A),
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        actions: [
          if (items.isNotEmpty)
            TextButton(
              onPressed: () => _confirmClear(context),
              child: const Text(
                'Tøm alle',
                style: TextStyle(
                  color: Color(0xFF2356E8),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
      body: items.isEmpty ? _buildEmpty() : _buildList(items),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: const Color(0xFF2356E8).withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                color: Color(0xFF2356E8),
                size: 44,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Ingen varsler ennå',
              style: TextStyle(
                color: Color(0xFF0F1E3A),
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Når noe skjer i oppdragene dine — meldinger, reservasjoner, fullføring eller betaling — dukker det opp her.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF6E7A90),
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<AppNotification> items) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _NotificationTile(item: items[i]),
    );
  }

  void _confirmClear(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Tøm alle varsler?',
            style: TextStyle(
              color: Color(0xFF0F1E3A),
              fontWeight: FontWeight.w800,
            ),
          ),
          content: const Text(
            'Alle varsler vil fjernes. Dette kan ikke angres.',
            style: TextStyle(color: Color(0xFF6E7A90), fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text(
                'Avbryt',
                style: TextStyle(color: Color(0xFF6E7A90)),
              ),
            ),
            TextButton(
              onPressed: () {
                context.read<AppState>().clearAllNotifications();
                Navigator.of(dialogCtx).pop();
              },
              child: const Text(
                'Tøm',
                style: TextStyle(
                  color: Color(0xFFDC2626),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item});

  final AppNotification item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6EAF2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFF2356E8).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_rounded,
              color: Color(0xFF2356E8),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.text,
                  style: const TextStyle(
                    color: Color(0xFF172033),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _relativeTime(item.createdAt),
                  style: const TextStyle(
                    color: Color(0xFF6E7A90),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _relativeTime(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inSeconds < 60) return 'nå nettopp';
    if (diff.inMinutes < 60) return 'for ${diff.inMinutes} min siden';
    if (diff.inHours < 24) return 'for ${diff.inHours} t siden';
    if (diff.inDays < 7) return 'for ${diff.inDays} d siden';
    return '${t.day.toString().padLeft(2, '0')}.${t.month.toString().padLeft(2, '0')}.${t.year}';
  }
}
