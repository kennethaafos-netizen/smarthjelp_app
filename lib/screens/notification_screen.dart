import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/job.dart';
import '../providers/app_state.dart';
import 'chat_screen.dart';
import 'job_detail_screen.dart';

const Color _primary = Color(0xFF2356E8);
const Color _accent = Color(0xFF18B7A6);
const Color _warning = Color(0xFFE08A00);
const Color _bg = Color(0xFFF4F7FC);
const Color _textPrimary = Color(0xFF0F1E3A);
const Color _textMuted = Color(0xFF6E7A90);

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final items = appState.notifications;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: _textPrimary),
        title: const Text(
          'Varsler',
          style: TextStyle(
            color: _textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        actions: [
          if (items.isNotEmpty)
            TextButton(
              onPressed: () {
                final count = appState.unreadNotificationCount;
                appState.markAllNotificationsRead();
                if (count > 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        count == 1
                            ? 'Merket 1 varsel som lest.'
                            : 'Merket $count varsler som lest.',
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: const Text(
                'Merk alle lest',
                style: TextStyle(
                  color: _primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          if (items.isNotEmpty)
            IconButton(
              tooltip: 'Tøm varsler',
              onPressed: () => _confirmClear(context),
              icon: const Icon(Icons.delete_outline_rounded, color: _primary),
            ),
        ],
      ),
      body: items.isEmpty
          ? _empty()
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _notificationCard(context, items[i]),
            ),
    );
  }

  Widget _empty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: _primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.notifications_none_rounded,
                  color: _primary, size: 34),
            ),
            const SizedBox(height: 16),
            const Text(
              'Ingen varsler ennå',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Du får varsel når noen reserverer, starter, fullfører eller sender deg melding.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _notificationCard(BuildContext context, AppNotification n) {
    final color = _colorForType(n.type);
    final icon = _iconForType(n.type);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _handleTap(context, n),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: n.isRead ? Colors.white : const Color(0xFFF1F5FF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: n.isRead
                  ? const Color(0xFFE4E9F2)
                  : _primary.withOpacity(0.25),
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      n.text,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _textPrimary,
                        fontWeight:
                            n.isRead ? FontWeight.w600 : FontWeight.w800,
                        fontSize: 13.5,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatRelative(n.createdAt),
                      style: const TextStyle(
                        color: _textMuted,
                        fontWeight: FontWeight.w600,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              if (!n.isRead)
                Container(
                  width: 9,
                  height: 9,
                  margin: const EdgeInsets.only(left: 8, top: 6),
                  decoration: const BoxDecoration(
                    color: _primary,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleTap(
    BuildContext context,
    AppNotification n,
  ) async {
    final appState = context.read<AppState>();
    appState.markNotificationRead(n.id);

    final jobId = n.jobId;
    if (jobId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Varselet har ingen tilknyttet sak.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final Job? job = appState.getJobById(jobId);
    if (job == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Oppdraget finnes ikke lenger.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (n.isMessage) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(job: job),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => JobDetailScreen(job: job),
        ),
      );
    }
  }

  Future<void> _confirmClear(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: const Text('Tøm varsler'),
        content: const Text('Vil du fjerne alle varsler?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Avbryt'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _primary),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Tøm'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      context.read<AppState>().clearNotifications();
    }
  }

  Color _colorForType(AppNotificationType t) {
    switch (t) {
      case AppNotificationType.message:
        return _primary;
      case AppNotificationType.reserved:
      case AppNotificationType.started:
        return _warning;
      case AppNotificationType.completed:
      case AppNotificationType.approved:
        return _accent;
      case AppNotificationType.cancelRequested:
      case AppNotificationType.cancelApproved:
      case AppNotificationType.cancelRejected:
      case AppNotificationType.reservationExpired:
      case AppNotificationType.reservationReleased:
        return _textMuted;
    }
  }

  IconData _iconForType(AppNotificationType t) {
    switch (t) {
      case AppNotificationType.message:
        return Icons.chat_bubble_outline_rounded;
      case AppNotificationType.reserved:
        return Icons.bookmark_added_outlined;
      case AppNotificationType.started:
        return Icons.play_circle_outline_rounded;
      case AppNotificationType.completed:
        return Icons.check_circle_outline_rounded;
      case AppNotificationType.approved:
        return Icons.verified_outlined;
      case AppNotificationType.cancelRequested:
        return Icons.hourglass_top_rounded;
      case AppNotificationType.cancelApproved:
        return Icons.undo_rounded;
      case AppNotificationType.cancelRejected:
        return Icons.block_rounded;
      case AppNotificationType.reservationExpired:
        return Icons.timer_off_outlined;
      case AppNotificationType.reservationReleased:
        return Icons.lock_open_rounded;
    }
  }

  String _formatRelative(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return 'Akkurat nå';
    if (diff.inMinutes < 60) return 'For ${diff.inMinutes} min siden';
    if (diff.inHours < 24) return 'For ${diff.inHours} t siden';
    if (diff.inDays < 7) return 'For ${diff.inDays} d siden';

    const months = [
      'jan', 'feb', 'mar', 'apr', 'mai', 'jun',
      'jul', 'aug', 'sep', 'okt', 'nov', 'des'
    ];
    return '${time.day}. ${months[time.month - 1]}';
  }
}
