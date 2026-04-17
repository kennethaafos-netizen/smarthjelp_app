import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/job.dart';

class SupabaseService {
  SupabaseService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  final Uuid _uuid = const Uuid();

  static const String jobImagesBucket = 'job-images';

  Future<List<Job>> fetchJobs() async {
    final response = await _client
        .from('jobs')
        .select()
        .order('created_at', ascending: false);

    return (response as List<dynamic>)
        .map((row) => Job.fromSupabase(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<Job?> createJob(Job job) async {
    try {
      final payload = Map<String, dynamic>.from(job.toSupabaseInsert());

      final response = await _client
          .from('jobs')
          .insert(payload)
          .select()
          .maybeSingle();

      if (response == null) {
        debugPrint('SmartHjelp createJob: insert returnerte null');
        return null;
      }

      return Job.fromSupabase(Map<String, dynamic>.from(response));
    } catch (error) {
      debugPrint('SmartHjelp createJob error: $error');
      return null;
    }
  }

  Future<Job?> updateJob(Job job) async {
    try {
      final response = await _client
          .from('jobs')
          .update(job.toSupabaseUpdate())
          .eq('id', job.id)
          .select()
          .maybeSingle();

      if (response == null) {
        return job;
      }

      return Job.fromSupabase(Map<String, dynamic>.from(response));
    } catch (error) {
      debugPrint('SmartHjelp updateJob error: $error');
      return null;
    }
  }

  Future<void> deleteJob(String jobId) async {
    try {
      await _client.from('job_images').delete().eq('job_id', jobId);
    } catch (error) {
      debugPrint('SmartHjelp delete job_images warning: $error');
    }

    await _client.from('jobs').delete().eq('id', jobId);
  }

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
        .map(
          (url) => {
            'job_id': jobId,
            'image_url': url,
          },
        )
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
    try {
      final safeName = _sanitizeFileName(originalFileName);
      final ext = _extensionFromFileName(safeName);

      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${_uuid.v4()}$ext';

      final path = 'jobs/$fileName';

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
      debugPrint('SmartHjelp uploadJobImage error: $error');
      return null;
    }
  }

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