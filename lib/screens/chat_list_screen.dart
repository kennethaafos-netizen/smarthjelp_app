// UI UPGRADE: premium polish, hierarchy, spacing, and clearer navigation
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import '../models/job.dart';
import 'chat_screen.dart';

const Color _primary = Color(0xFF2356E8);
const Color _accent = Color(0xFF18B7A6);
const Color _bg = Color(0xFFF4F7FC);
const Color _textPrimary = Color(0xFF0F1E3A);
const Color _textMuted = Color(0xFF6E7A90);
const Color _danger = Color(0xFFDC2626);

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    // Sprint 5: kopierer chatJobs for å kunne sortere uten å mutere
    // den originale (immutable list fra AppState). Sekundær sortering
    // er createdAt desc — samme som chatJobs allerede leverer. Primær
    // er ulest-status, så uleste chatter alltid havner øverst.
    final jobs = [...appState.chatJobs]..sort((a, b) {
        final aUnread = appState.hasUnreadMessagesForJob(a.id);
        final bUnread = appState.hasUnreadMessagesForJob(b.id);
        if (aUnread != bUnread) return aUnread ? -1 : 1;
        return b.createdAt.compareTo(a.createdAt);
      });

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Chat',
          style: TextStyle(
            color: _textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 22,
          ),
        ),
        iconTheme: const IconThemeData(color: _textPrimary),
      ),
      body: jobs.isEmpty
          ? _emptyState()
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: jobs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _chatItem(context, appState, jobs[i]),
            ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4F7BFF), _accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: _primary.withOpacity(0.25),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.chat_bubble_outline_rounded,
                  color: Colors.white, size: 34),
            ),
            const SizedBox(height: 18),
            const Text(
              'Ingen samtaler ennå',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Chatter dukker opp her når du tar eller legger ut et oppdrag.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _textMuted,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chatItem(BuildContext context, AppState appState, Job job) {
    final initial = job.title.isNotEmpty ? job.title[0].toUpperCase() : '?';

    // Sprint 5: ulest-state per chat. unreadCount=0 → standard kort.
    // unreadCount>0 → subtilt blått tint på kortet, blå venstre-stripe,
    // og rød count-badge til høyre. "Ny" når akkurat 1, ellers tallet.
    final unreadCount = appState.unreadMessageCountForJob(job.id);
    final hasUnread = unreadCount > 0;
    final cardColor = hasUnread ? const Color(0xFFF1F5FF) : Colors.white;
    final borderColor = hasUnread
        ? _primary.withOpacity(0.28)
        : Colors.black.withOpacity(0.04);
    final badgeText = unreadCount == 1 ? 'Ny' : '$unreadCount';

    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatScreen(job: job),
            ),
          );
        },
        child: Ink(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(18),
            border: hasUnread
                ? Border.all(color: _primary.withOpacity(0.30), width: 1)
                : null,
            boxShadow: [
              BoxShadow(
                color: borderColor,
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4F7BFF), _accent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  if (hasUnread)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _danger,
                          shape: BoxShape.circle,
                          border: Border.all(color: cardColor, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: _textPrimary,
                        letterSpacing: -0.1,
                        height: 1.2,
                        decoration: TextDecoration.none,
                        decorationColor: hasUnread ? _primary : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (hasUnread) ...[
                          const Icon(
                            Icons.mark_chat_unread_rounded,
                            size: 13,
                            color: _primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            unreadCount == 1
                                ? 'Ny melding'
                                : '$unreadCount nye meldinger',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _primary,
                              fontWeight: FontWeight.w800,
                              fontSize: 12.5,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ] else ...[
                          const Icon(Icons.place_outlined,
                              size: 14, color: _textMuted),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              job.locationName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _textMuted,
                                fontWeight: FontWeight.w600,
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (hasUnread)
                Container(
                  constraints: const BoxConstraints(minWidth: 26, minHeight: 22),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _danger,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: _danger.withOpacity(0.30),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    badgeText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 11.5,
                      letterSpacing: 0.2,
                    ),
                  ),
                )
              else
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _bg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.chevron_right_rounded,
                      color: _primary, size: 20),
                ),
            ],
          ),
        ),
      ),
    );
  }
}