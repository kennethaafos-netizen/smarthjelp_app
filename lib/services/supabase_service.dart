import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/chat_message.dart';
import '../models/job.dart';
import '../models/user_profile.dart';

/// SupabaseService — server-first data-layer for SmartHjelp.
///
/// Kontrakt:
/// * Metoder som MÅ lykkes (createJob, insertMessage, insertNotification,
///   upsertProfile) KASTER ved feil. Kaller bruker try/catch og får
///   dermed ekte feilmelding.
/// * Metoder der "ingen rad" er et lovlig utfall (updateJob,
///   reserveJobAtomic, fetchProfile) returnerer null og kaster kun
///   ved uventede feil.
class SupabaseService {
  SupabaseService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  final Uuid _uuid = const Uuid();

  static const String jobImagesBucket = 'job-images';
  static const String _chatImagePrefix = 'chat';

  // =============================================================
  // JOBS
  // =============================================================

  Future<List<Job>> fetchJobs() async {
    final response = await _client
        .from('jobs')
        .select()
        .order('created_at', ascending: false);

    return (response as List<dynamic>)
        .map((row) => Job.fromSupabase(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<Job?> fetchJobById(String id) async {
    final response = await _client
        .from('jobs')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return Job.fromSupabase(Map<String, dynamic>.from(response));
  }

  Future<Job> createJob(Job job) async {
    final payload = Map<String, dynamic>.from(job.toSupabaseInsert());

    final response = await _client
        .from('jobs')
        .insert(payload)
        .select()
        .maybeSingle();

    if (response == null) {
      throw StateError(
        'Supabase insert returnerte ingen rad. Sjekk RLS-policy '
        '(authenticated må ha INSERT + SELECT på "jobs").',
      );
    }

    return Job.fromSupabase(Map<String, dynamic>.from(response));
  }

  Future<Job?> updateJob(Job job) async {
    final response = await _client
        .from('jobs')
        .update(job.toSupabaseUpdate())
        .eq('id', job.id)
        .select()
        .maybeSingle();

    if (response == null) return null;
    return Job.fromSupabase(Map<String, dynamic>.from(response));
  }

  Future<Job?> reserveJobAtomic({
    required String jobId,
    required String workerUserId,
    required DateTime reservedAt,
  }) async {
    final reservedAtIso = reservedAt.toIso8601String();

    final response = await _client
        .from('jobs')
        .update({
          'status': 'reserved',
          'accepted_by_user_id': workerUserId,
          'reserved_at': reservedAtIso,
          'is_payment_reserved': true,
          'payment_reserved_at': reservedAtIso,
          'is_paid_out': false,
          'is_completed_by_worker': false,
          'is_approved_by_owner': false,
          'cancel_requested_by_user_id': null,
        })
        .eq('id', jobId)
        .eq('status', 'open')
        .filter('accepted_by_user_id', 'is', null)
        .select()
        .maybeSingle();

    if (response == null) return null;
    return Job.fromSupabase(Map<String, dynamic>.from(response));
  }

  Future<void> deleteJob(String jobId) async {
    try {
      await _client.from('job_images').delete().eq('job_id', jobId);
    } catch (error) {
      debugPrint('SmartHjelp delete job_images warning: $error');
    }
    await _client.from('jobs').delete().eq('id', jobId);
  }

  // =============================================================
  // JOB IMAGES
  // =============================================================

  Future<List<String>> fetchJobImages(String jobId) async {
    try {
      final response = await _client
          .from('job_images')
          .select('image_url')
          .eq('job_id', jobId)
          .order('created_at', ascending: true);

      return (response as List<dynamic>)
          .map((row) => (row['image_url'] ?? '').toString())
          .where((url) => url.isNotEmpty)
          .toList();
    } catch (error) {
      debugPrint('SmartHjelp fetchJobImages error: $error');
      return [];
    }
  }

  Future<void> addJobImages({
    required String jobId,
    required List<String> urls,
  }) async {
    if (urls.isEmpty) return;
    final rows = urls
        .map((url) => {'job_id': jobId, 'image_url': url})
        .toList();
    try {
      await _client.from('job_images').insert(rows);
    } catch (error) {
      debugPrint('SmartHjelp addJobImages error: $error');
    }
  }

  Future<String?> uploadJobImage({
    required Uint8List bytes,
    required String originalFileName,
  }) async {
    return _uploadImage(
      bytes: bytes,
      originalFileName: originalFileName,
      prefix: 'jobs',
    );
  }

  Future<String?> uploadChatImage({
    required Uint8List bytes,
    required String originalFileName,
  }) async {
    return _uploadImage(
      bytes: bytes,
      originalFileName: originalFileName,
      prefix: _chatImagePrefix,
    );
  }

  Future<String?> _uploadImage({
    required Uint8List bytes,
    required String originalFileName,
    required String prefix,
  }) async {
    try {
      final safeName = _sanitizeFileName(originalFileName);
      final ext = _extensionFromFileName(safeName);
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${_uuid.v4()}$ext';
      final path = '$prefix/$fileName';

      await _client.storage.from(jobImagesBucket).uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              cacheControl: '3600',
              upsert: false,
              contentType: _contentTypeFromExtension(ext),
            ),
          );
      return _client.storage.from(jobImagesBucket).getPublicUrl(path);
    } catch (error) {
      debugPrint('SmartHjelp uploadImage error: $error');
      return null;
    }
  }

  // =============================================================
  // PROFILES
  // =============================================================

  Future<UserProfile?> fetchProfile(String id) async {
    if (id.isEmpty) return null;
    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', id)
          .maybeSingle();
      if (response == null) return null;
      return UserProfile.fromSupabase(Map<String, dynamic>.from(response));
    } catch (error) {
      debugPrint('SmartHjelp fetchProfile error: $error');
      return null;
    }
  }

  Future<List<UserProfile>> fetchProfiles(Iterable<String> ids) async {
    final unique = ids.where((id) => id.isNotEmpty).toSet().toList();
    if (unique.isEmpty) return const [];

    try {
      final response = await _client
          .from('profiles')
          .select()
          .inFilter('id', unique);

      return (response as List<dynamic>)
          .map((row) =>
              UserProfile.fromSupabase(Map<String, dynamic>.from(row)))
          .toList();
    } catch (error) {
      debugPrint('SmartHjelp fetchProfiles error: $error');
      return const [];
    }
  }

  /// Upsert egen profil. RLS sikrer at `id = auth.uid()`.
  Future<UserProfile?> upsertProfile(UserProfile profile) async {
    try {
      final response = await _client
          .from('profiles')
          .upsert(profile.toSupabaseUpsert(), onConflict: 'id')
          .select()
          .maybeSingle();
      if (response == null) return profile;
      return UserProfile.fromSupabase(Map<String, dynamic>.from(response));
    } catch (error) {
      debugPrint('SmartHjelp upsertProfile error: $error');
      return null;
    }
  }

  // =============================================================
  // CHAT MESSAGES
  // =============================================================

  Future<List<ChatMessage>> fetchMessagesForJob(String jobId) async {
    try {
      final response = await _client
          .from('chat_messages')
          .select()
          .eq('job_id', jobId)
          .order('created_at', ascending: true);

      return (response as List<dynamic>)
          .map((row) =>
              ChatMessage.fromSupabase(Map<String, dynamic>.from(row)))
          .toList();
    } catch (error) {
      debugPrint('SmartHjelp fetchMessagesForJob error: $error');
      return const [];
    }
  }

  /// Insert av melding (vanlig eller system). Returnerer den
  /// persisterte raden, eller kaster ved feil.
  Future<ChatMessage> insertMessage(ChatMessage message) async {
    final response = await _client
        .from('chat_messages')
        .insert(message.toSupabaseInsert())
        .select()
        .maybeSingle();

    if (response == null) {
      throw StateError(
        'Supabase chat_messages insert returnerte ingen rad. '
        'Sjekk RLS-policy.',
      );
    }
    return ChatMessage.fromSupabase(Map<String, dynamic>.from(response));
  }

  Future<ChatMessage?> setMessageReaction({
    required String messageId,
    required String? reaction,
  }) async {
    try {
      final response = await _client
          .from('chat_messages')
          .update({'reaction': reaction})
          .eq('id', messageId)
          .select()
          .maybeSingle();
      if (response == null) return null;
      return ChatMessage.fromSupabase(Map<String, dynamic>.from(response));
    } catch (error) {
      debugPrint('SmartHjelp setMessageReaction error: $error');
      return null;
    }
  }

  /// Markerer alle uleste meldinger i en jobb som lest av currentUserId.
  /// Best-effort: feiler stille hvis RLS/nettverk svikter, slik at
  /// chat-skjermen ikke krasjer på lest-status. Realtime UPDATE-eventet
  /// (samme kanal som reaksjoner bruker) leverer endringen tilbake til
  /// avsender automatisk via _handleRemoteMessageUpsert i AppState.
  ///
  /// WHERE-klausul:
  ///   * job_id = jobId
  ///   * sender_id != currentUserId       (egne meldinger ekskluderes)
  ///   * sender_id IS NOT NULL            (system-meldinger ekskluderes)
  ///   * read_at IS NULL                  (idempotent, ingen rader berøres
  ///                                       hvis alt allerede er lest)
  ///
  /// RLS gates på serversiden at auth.uid() faktisk er involvert i jobben
  /// (eier eller worker) og ikke er senderen selv.
  Future<void> markMessagesReadForJob({
    required String jobId,
    required String currentUserId,
  }) async {
    if (jobId.isEmpty || currentUserId.isEmpty) return;
    try {
      await _client
          .from('chat_messages')
          .update({'read_at': DateTime.now().toUtc().toIso8601String()})
          .eq('job_id', jobId)
          .neq('sender_id', currentUserId)
          .filter('sender_id', 'not.is', null)
          .filter('read_at', 'is', null);
    } catch (error) {
      debugPrint('SmartHjelp markMessagesReadForJob error: $error');
    }
  }

  // =============================================================
  // NOTIFICATIONS
  // =============================================================

  Future<List<Map<String, dynamic>>> fetchNotifications(String userId) async {
    if (userId.isEmpty) return const [];
    try {
      final response = await _client
          .from('notifications')
          .select()
          .eq('recipient_user_id', userId)
          .order('created_at', ascending: false)
          .limit(200);

      return (response as List<dynamic>)
          .map((row) => Map<String, dynamic>.from(row))
          .toList();
    } catch (error) {
      debugPrint('SmartHjelp fetchNotifications error: $error');
      return const [];
    }
  }

  Future<Map<String, dynamic>?> insertNotification({
    required String id,
    required String recipientUserId,
    required String type,
    required String text,
    String? jobId,
    required DateTime createdAt,
  }) async {
    if (recipientUserId.isEmpty) return null;
    try {
      // VIKTIG: ikke bruk .select() etter insert her.
      // RLS SELECT-policy krever recipient_user_id = auth.uid(), og
      // avsender ER IKKE mottaker. Et `.select()` ville derfor returnert
      // 42501 ("new row violates row-level security policy") — ikke fra
      // selve INSERTEN, men fra PostgREST sitt returnerings-step. Vi
      // trenger heller ikke retur-raden: mottaker får den via realtime.
      await _client.from('notifications').insert({
        'id': id,
        'recipient_user_id': recipientUserId,
        'type': type,
        'text': text,
        'job_id': jobId,
        'is_read': false,
        'created_at': createdAt.toIso8601String(),
      });
      return <String, dynamic>{
        'id': id,
        'recipient_user_id': recipientUserId,
        'type': type,
        'text': text,
        'job_id': jobId,
        'is_read': false,
        'created_at': createdAt.toIso8601String(),
      };
    } catch (error) {
      debugPrint('SmartHjelp insertNotification error: $error');
      return null;
    }
  }

  Future<void> markNotificationReadRemote(String id) async {
    try {
      await _client
          .from('notifications')
          .update({'is_read': true})
          .eq('id', id);
    } catch (error) {
      debugPrint('SmartHjelp markNotificationRead error: $error');
    }
  }

  Future<void> markAllNotificationsReadRemote(String userId) async {
    if (userId.isEmpty) return;
    try {
      await _client
          .from('notifications')
          .update({'is_read': true})
          .eq('recipient_user_id', userId)
          .eq('is_read', false);
    } catch (error) {
      debugPrint('SmartHjelp markAllNotificationsRead error: $error');
    }
  }

  Future<void> deleteNotificationsForUser(String userId) async {
    if (userId.isEmpty) return;
    try {
      await _client
          .from('notifications')
          .delete()
          .eq('recipient_user_id', userId);
    } catch (error) {
      debugPrint('SmartHjelp deleteNotificationsForUser error: $error');
    }
  }

  // =============================================================
  // INTERNAL HELPERS
  // =============================================================

  String _sanitizeFileName(String fileName) {
    return fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
  }

  String _extensionFromFileName(String fileName) {
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex == -1) return '.jpg';
    return fileName.substring(dotIndex).toLowerCase();
  }

  String _contentTypeFromExtension(String extension) {
    switch (extension) {
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      case '.gif':
        return 'image/gif';
      case '.jpg':
      case '.jpeg':
      default:
        return 'image/jpeg';
    }
  }
}