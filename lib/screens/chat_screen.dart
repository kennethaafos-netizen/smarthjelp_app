// UI UPGRADE: premium polish, hierarchy, spacing, and clearer navigation
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/chat_message.dart';
import '../models/job.dart';
import '../models/user_profile.dart';
import '../providers/app_state.dart';
import '../services/supabase_service.dart';
import 'job_detail_screen.dart';

const Color _primary = Color(0xFF2356E8);
const Color _accent = Color(0xFF18B7A6);
const Color _bg = Color(0xFFF4F7FC);
const Color _textPrimary = Color(0xFF0F1E3A);
const Color _textMuted = Color(0xFF6E7A90);
const Color _online = Color(0xFF0EA877);

class ChatScreen extends StatefulWidget {
  final Job job;

  const ChatScreen({super.key, required this.job});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _ctrl = TextEditingController();
  final ScrollController _listCtrl = ScrollController();
  final SupabaseService _supabase = SupabaseService();
  final ImagePicker _imagePicker = ImagePicker();

  ChatMessage? _replyTo;
  bool _summaryExpanded = true;
  bool _hasText = false;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() {
      final has = _ctrl.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().loadMessagesForJob(widget.job.id);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _listCtrl.dispose();
    super.dispose();
  }

  String _statusLabel(JobStatus s) {
    switch (s) {
      case JobStatus.open:
        return 'Åpen';
      case JobStatus.reserved:
        return 'Reservert';
      case JobStatus.inProgress:
        return 'Pågår';
      case JobStatus.completed:
        return 'Fullført';
    }
  }

  Color _statusColor(JobStatus s) {
    switch (s) {
      case JobStatus.open:
        return _primary;
      case JobStatus.reserved:
        return const Color(0xFFF59E0B);
      case JobStatus.inProgress:
        return _accent;
      case JobStatus.completed:
        return _online;
    }
  }

  UserProfile? _counterparty(AppState app, Job job) {
    final me = app.currentUser.id;
    if (job.createdByUserId == me) {
      final taker = job.acceptedByUserId;
      if (taker == null) return null;
      return app.getUserById(taker);
    }
    return app.getUserById(job.createdByUserId);
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    // Bruk alltid siste versjon av jobben fra state (realtime-oppdateringer).
    final liveJob = appState.getJobById(widget.job.id) ?? widget.job;
    final messages = appState.getMessagesForJob(liveJob.id);
    final currentUser = appState.currentUser;
    final counter = _counterparty(appState, liveJob);
    final counterName = counter?.firstName ?? 'Bruker';
    final initials = counterName.isNotEmpty ? counterName[0].toUpperCase() : '?';

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: _textPrimary),
        titleSpacing: 0,
        title: Row(
          children: [
            _avatarWithPresence(initials, online: counter != null),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    counterName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 1),
                  if (counter != null)
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 13, color: Color(0xFFF5B301)),
                        const SizedBox(width: 3),
                        Text(
                          counter.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            color: _textMuted,
                            fontWeight: FontWeight.w700,
                            fontSize: 11.5,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: _online,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Text(
                          'Aktiv nå',
                          style: TextStyle(
                            color: _online,
                            fontWeight: FontWeight.w700,
                            fontSize: 11.5,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Gå til oppdrag',
            icon: const Icon(Icons.assignment_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => JobDetailScreen(job: liveJob),
                ),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          _jobSummaryCard(liveJob),
          Expanded(
            child: messages.isEmpty
                ? _emptyChat()
                : ListView.builder(
                    controller: _listCtrl,
                    reverse: true,
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    itemCount: messages.length,
                    itemBuilder: (_, i) {
                      final msg = messages[messages.length - 1 - i];
                      final isMe = msg.senderId == currentUser.id;
                      final sender = appState
                              .getUserById(msg.senderId)
                              ?.firstName ??
                          (msg.senderId == 'system' ? 'System' : 'Bruker');

                      return GestureDetector(
                        onLongPress: () {
                          if (!msg.isSystem) {
                            setState(() => _replyTo = msg);
                          }
                        },
                        onTap: () {
                          if (!msg.isSystem) {
                            appState.toggleReaction(msg.id, '❤️');
                          }
                        },
                        child: _buildBubble(msg, isMe, sender),
                      );
                    },
                  ),
          ),
          if (_replyTo != null) _replyPreview(),
          if (_isUploadingImage) _uploadingStrip(),
          _inputBar(),
        ],
      ),
    );
  }

  Widget _uploadingStrip() {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: const [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 10),
          Text(
            'Laster opp bilde…',
            style: TextStyle(
              color: _textMuted,
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarWithPresence(String initials, {required bool online}) {
    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _primary,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ),
          if (online)
            Positioned(
              right: -1,
              bottom: -1,
              child: Container(
                width: 13,
                height: 13,
                decoration: BoxDecoration(
                  color: _online,
                  shape: BoxShape.circle,
                  border: Border.all(color: _bg, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _jobSummaryCard(Job job) {
    final statusColor = _statusColor(job.status);
    final price = NumberFormat.decimalPattern('nb_NO').format(job.price);

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 4, 14, 6),
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'OM OPPDRAGET',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: _primary,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _statusLabel(job.status),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: statusColor,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              InkResponse(
                radius: 20,
                onTap: () =>
                    setState(() => _summaryExpanded = !_summaryExpanded),
                child: AnimatedRotation(
                  duration: const Duration(milliseconds: 180),
                  turns: _summaryExpanded ? 0.5 : 0,
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: _textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            job.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
              color: _textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          if (_summaryExpanded) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.place_outlined,
                    size: 15, color: _textMuted),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    job.locationName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: _textMuted,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: _primary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$price kr',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: _primary.withOpacity(0.4)),
                foregroundColor: _primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => JobDetailScreen(job: job),
                  ),
                );
              },
              icon: const Icon(Icons.open_in_new_rounded, size: 18),
              label: const Text(
                'Gå til oppdrag',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _replyPreview() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: const Border(
          left: BorderSide(color: _primary, width: 3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.reply_rounded, size: 18, color: _primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Svarer på',
                  style: TextStyle(
                    color: _primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _replyTo!.text.isEmpty ? '📎 Bilde' : _replyTo!.text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.close_rounded,
                color: _textMuted, size: 20),
            onPressed: () => setState(() => _replyTo = null),
          ),
        ],
      ),
    );
  }

  Widget _emptyChat() {
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 14,
                  ),
                ],
              ),
              child: const Icon(Icons.forum_outlined,
                  color: _primary, size: 34),
            ),
            const SizedBox(height: 14),
            const Text(
              'Start samtalen',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Skriv en melding for å avtale detaljer om oppdraget.',
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

  Widget _buildBubble(ChatMessage msg, bool isMe, String name) {
    final time = DateFormat.Hm().format(msg.createdAt);
    final isSystem = msg.isSystem;

    if (isSystem) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF4E5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFF59E0B).withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.info_outline_rounded,
                  size: 14, color: Color(0xFFB45309)),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  msg.text,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFB45309),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final textColor = isMe ? Colors.white : _textPrimary;
    final timeColor = isMe ? Colors.white.withOpacity(0.85) : _textMuted;
    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: Radius.circular(isMe ? 18 : 4),
      bottomRight: Radius.circular(isMe ? 4 : 18),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: _primary,
                borderRadius: BorderRadius.circular(9),
              ),
              alignment: Alignment.center,
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 2),
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _textMuted,
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  constraints: const BoxConstraints(maxWidth: 280),
                  decoration: BoxDecoration(
                    color: isMe ? _primary : Colors.white,
                    borderRadius: borderRadius,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (msg.replyToText != null &&
                          msg.replyToText!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: isMe
                                ? Colors.white.withOpacity(0.18)
                                : _bg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border(
                              left: BorderSide(
                                color: isMe ? Colors.white70 : _primary,
                                width: 3,
                              ),
                            ),
                          ),
                          child: Text(
                            msg.replyToText!,
                            style: TextStyle(
                              fontSize: 12,
                              color: isMe
                                  ? Colors.white.withOpacity(0.9)
                                  : _textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      if (msg.imageUrl != null &&
                          msg.imageUrl!.startsWith('http')) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            msg.imageUrl!,
                            height: 160,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) {
                              return Container(
                                height: 160,
                                width: double.infinity,
                                color: _bg,
                                alignment: Alignment.center,
                                child: const Icon(Icons.broken_image,
                                    color: _textMuted),
                              );
                            },
                          ),
                        ),
                        if (msg.text.isNotEmpty) const SizedBox(height: 8),
                      ],
                      if (msg.text.isNotEmpty)
                        Text(
                          msg.text,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 14.5,
                            height: 1.35,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (msg.reaction != null) ...[
                            Text(
                              msg.reaction!,
                              style: const TextStyle(fontSize: 13),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            time,
                            style: TextStyle(
                              fontSize: 10.5,
                              color: timeColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (isMe) ...[
                            const SizedBox(width: 4),
                            Icon(
                              Icons.done_all_rounded,
                              size: 14,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputBar() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
        decoration: const BoxDecoration(color: _bg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _attachButton(),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _ctrl,
                        textInputAction: TextInputAction.send,
                        minLines: 1,
                        maxLines: 5,
                        onSubmitted: (_) => _handleSend(),
                        style: const TextStyle(
                          color: _textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Skriv en melding…',
                          hintStyle: TextStyle(
                            color: _textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                    InkResponse(
                      radius: 22,
                      onTap: _isUploadingImage ? null : _pickFromCamera,
                      child: const Padding(
                        padding: EdgeInsets.fromLTRB(4, 10, 12, 10),
                        child: Icon(
                          Icons.camera_alt_outlined,
                          color: _textMuted,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            _sendButton(),
          ],
        ),
      ),
    );
  }

  Widget _attachButton() {
    return InkResponse(
      radius: 24,
      onTap: _isUploadingImage ? null : _showAttachmentSheet,
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Icon(
          Icons.add_rounded,
          color: _primary,
          size: 24,
        ),
      ),
    );
  }

  Widget _sendButton() {
    final enabled = _hasText && !_isUploadingImage;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: enabled ? 1.0 : 0.55,
      child: GestureDetector(
        onTap: enabled ? _handleSend : null,
        child: Container(
          width: 46,
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _primary,
            borderRadius: BorderRadius.circular(22),
          ),
          child: const Icon(Icons.send_rounded,
              color: Colors.white, size: 20),
        ),
      ),
    );
  }

  void _showAttachmentSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _textMuted.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Legg til',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: _textPrimary,
                  ),
                ),
                const SizedBox(height: 14),
                _attachTile(
                  icon: Icons.photo_library_outlined,
                  color: _primary,
                  title: 'Bilde fra galleri',
                  subtitle: 'Del et bilde av stedet',
                  onTap: () {
                    Navigator.pop(context);
                    _pickFromGallery();
                  },
                ),
                _attachTile(
                  icon: Icons.camera_alt_outlined,
                  color: _accent,
                  title: 'Ta et nytt bilde',
                  subtitle: 'Åpne kamera',
                  onTap: () {
                    Navigator.pop(context);
                    _pickFromCamera();
                  },
                ),
                _attachTile(
                  icon: Icons.assignment_outlined,
                  color: const Color(0xFFF59E0B),
                  title: 'Gå til oppdrag',
                  subtitle: 'Åpne detaljer om oppdraget',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => JobDetailScreen(job: widget.job),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _attachTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withOpacity(0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: _textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: _textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: _textMuted),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFromCamera() async {
    if (_isUploadingImage) return;
    if (kIsWeb) {
      // image_picker.source.camera støttes ikke på web — fall tilbake til gallery.
      await _pickFromGallery();
      return;
    }
    try {
      final img = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (img == null) return;
      final bytes = await img.readAsBytes();
      await _uploadAndSend(bytes, img.name);
    } catch (e) {
      debugPrint('camera error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kunne ikke åpne kamera.')),
      );
    }
  }

  Future<void> _pickFromGallery() async {
    if (_isUploadingImage) return;
    try {
      if (kIsWeb) {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          withData: true,
        );
        if (result == null || result.files.isEmpty) return;
        final file = result.files.first;
        final bytes = file.bytes;
        if (bytes == null) return;
        await _uploadAndSend(bytes, file.name);
      } else {
        final img = await _imagePicker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 85,
        );
        if (img == null) return;
        final bytes = await img.readAsBytes();
        await _uploadAndSend(bytes, img.name);
      }
    } catch (e) {
      debugPrint('gallery error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kunne ikke velge bilde.')),
      );
    }
  }

  Future<void> _uploadAndSend(Uint8List bytes, String fileName) async {
    setState(() => _isUploadingImage = true);
    try {
      final url = await _supabase.uploadChatImage(
        bytes: bytes,
        originalFileName: fileName,
      );
      if (url == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kunne ikke laste opp bilde.')),
        );
        return;
      }
      if (!mounted) return;
      context.read<AppState>().sendMessage(
            jobId: widget.job.id,
            text: _ctrl.text.trim(),
            imageUrl: url,
            replyToMessageId: _replyTo?.id,
            replyToText: _replyTo?.text,
          );
      _ctrl.clear();
      setState(() {
        _replyTo = null;
        _hasText = false;
      });
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  void _handleSend() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;

    final replyTo = _replyTo;

    context.read<AppState>().sendMessage(
          jobId: widget.job.id,
          text: text,
          replyToMessageId: replyTo?.id,
          replyToText: replyTo?.text,
        );

    _ctrl.clear();
    if (mounted) {
      setState(() {
        _replyTo = null;
        _hasText = false;
      });
    }
  }
}
