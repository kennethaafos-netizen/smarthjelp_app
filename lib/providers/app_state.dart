import 'dart:math';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/chat_message.dart';
import '../models/job.dart';
import '../models/user_profile.dart';
import '../services/supabase_service.dart';

enum TaxTransactionType { income, expense }

class TaxReportEntry {
  final String id;
  final TaxTransactionType type;
  final DateTime date;
  final String jobTitle;
  final String category;
  final String locationName;
  final double amount;
  final String sourceJobId;

  const TaxReportEntry({
    required this.id,
    required this.type,
    required this.date,
    required this.jobTitle,
    required this.category,
    required this.locationName,
    required this.amount,
    required this.sourceJobId,
  });

  String get typeLabel =>
      type == TaxTransactionType.income ? 'Inntekt' : 'Kostnad';
  bool get isIncome => type == TaxTransactionType.income;
}

class TaxReportSummary {
  final int year;
  final List<TaxReportEntry> entries;
  final double totalIncome;
  final double totalExpenses;

  const TaxReportSummary({
    required this.year,
    required this.entries,
    required this.totalIncome,
    required this.totalExpenses,
  });

  double get net => totalIncome - totalExpenses;
  int get transactionCount => entries.length;
}

// 🔔 Lokal in-memory varsling (MVP).
class AppNotification {
  final String id;
  final String text;
  final DateTime createdAt;
  final String? jobId;

  const AppNotification({
    required this.id,
    required this.text,
    required this.createdAt,
    this.jobId,
  });
}

class AppState extends ChangeNotifier {
  AppState({SupabaseService? supabaseService})
      : _supabaseService = supabaseService ?? SupabaseService() {
    _seedUsers();
    _bootstrap();
  }

  final Uuid _uuid = const Uuid();
  final SupabaseService _supabaseService;

  late UserProfile _currentUser;

  final Map<String, UserProfile> _users = {};
  List<Job> _jobs = [];
  final List<ChatMessage> _messages = [];
  final Map<String, List<String>> _jobImages = {};

  bool _isLoadingJobs = false;
  bool _hasLoadedJobs = false;
  String? _jobsError;

  // 🔔 Notifications
  final List<AppNotification> _notifications = [];
  bool _hasUnreadNotifications = false;

  // 🔒 Truthfulness: siste addJob — synkronisert mot Supabase?
  bool _lastAddJobSyncedRemotely = false;

  // V2 foundation
  static const double _markerSpread = 0.006;
  double _userLat = 59.14;
  double _userLng = 9.65;
  final Set<String> _preferredCategories = <String>{};

  UserProfile get currentUser => _currentUser;
  List<Job> get jobs => List.unmodifiable(_jobs);
  bool get isLoadingJobs => _isLoadingJobs;
  bool get hasLoadedJobs => _hasLoadedJobs;
  String? get jobsError => _jobsError;
  bool get lastAddJobSyncedRemotely => _lastAddJobSyncedRemotely;

  // 🔔 Notification getters
  List<AppNotification> get notifications =>
      List.unmodifiable(_notifications.reversed);
  bool get hasUnreadNotifications => _hasUnreadNotifications;
  int get unreadNotificationCount =>
      _hasUnreadNotifications ? _notifications.length : 0;

  List<Job> get allJobsSortedByNewest {
    final copy = [..._jobs];
    copy.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return copy;
  }

  List<Job> get postedByCurrentUser =>
      _jobs.where((j) => j.createdByUserId == _currentUser.id).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  List<Job> get takenByCurrentUser =>
      _jobs.where((j) => j.acceptedByUserId == _currentUser.id).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  Future<void> _bootstrap() async {
    await ensureJobsLoaded();
  }

  Future<void> ensureJobsLoaded() async {
    if (_isLoadingJobs) return;

    _isLoadingJobs = true;
    _jobsError = null;
    notifyListeners();

    try {
      final remoteJobs = await _supabaseService.fetchJobs();
      _jobs = remoteJobs;
      _hasLoadedJobs = true;
    } catch (e) {
      debugPrint('Fallback til local jobs: $e');
      _jobs = _buildSeedJobs();
      _hasLoadedJobs = true;
      _jobsError = 'Viser lokale testdata fordi Supabase ikke svarte.';
    }

    _isLoadingJobs = false;
    notifyListeners();
  }

  Future<void> reloadJobs() async {
    _isLoadingJobs = true;
    _jobsError = null;
    notifyListeners();

    try {
      final remoteJobs = await _supabaseService.fetchJobs();
      _jobs = remoteJobs;
      _hasLoadedJobs = true;
    } catch (e) {
      debugPrint('reloadJobs error: $e');
      _jobsError = 'Kunne ikke oppdatere oppdrag akkurat nå.';
    }

    _isLoadingJobs = false;
    notifyListeners();
  }

  Job? getJobById(String id) {
    try {
      return _jobs.firstWhere((j) => j.id == id);
    } catch (_) {
      return null;
    }
  }

  UserProfile? getUserById(String id) => _users[id];

  List<String> getImages(String jobId) =>
      List.unmodifiable(_jobImages[jobId] ?? const []);

  List<ChatMessage> getMessagesForJob(String jobId) {
    final result = _messages.where((m) => m.jobId == jobId).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return result;
  }

  List<Job> get smartRankedJobs {
    final result = _jobs.where((j) {
      if (j.status == JobStatus.completed) return false;
      if (j.createdByUserId == _currentUser.id) return false;
      return true;
    }).toList()
      ..sort((a, b) {
        final scoreA =
            a.viewCount + a.createdAt.millisecondsSinceEpoch ~/ 10000000;
        final scoreB =
            b.viewCount + b.createdAt.millisecondsSinceEpoch ~/ 10000000;
        return scoreB.compareTo(scoreA);
      });
    return result;
  }

  List<Job> get chatJobs {
    return _jobs.where((job) {
      final involved = job.createdByUserId == _currentUser.id ||
          job.acceptedByUserId == _currentUser.id;
      return involved && job.acceptedByUserId != null;
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<Job> get activeTakenJobs => _jobs.where((j) {
        if (j.acceptedByUserId != _currentUser.id) return false;
        return j.status != JobStatus.completed;
      }).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  List<Job> get completedTakenJobs => _jobs.where((j) {
        if (j.acceptedByUserId != _currentUser.id) return false;
        return j.status == JobStatus.completed && j.isApprovedByOwner;
      }).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  List<Job> get activePostedJobs => _jobs.where((j) {
        if (j.createdByUserId != _currentUser.id) return false;
        return j.status != JobStatus.completed;
      }).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  List<Job> get completedPostedJobs => _jobs.where((j) {
        if (j.createdByUserId != _currentUser.id) return false;
        return j.status == JobStatus.completed && j.isApprovedByOwner;
      }).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  double get moneyEarned =>
      completedTakenJobs.fold(0.0, (sum, j) => sum + j.payout);

  double get moneySpent =>
      completedPostedJobs.fold(0.0, (sum, j) => sum + j.totalPrice);

  List<int> get availableTaxReportYears {
    final years = <int>{
      DateTime.now().year,
      ..._jobs.map((j) => j.createdAt.year),
    }.toList()
      ..sort((a, b) => b.compareTo(a));
    return years;
  }

  TaxReportSummary buildTaxReportForYear(int year) {
    final entries = <TaxReportEntry>[];

    for (final job
        in completedTakenJobs.where((j) => j.createdAt.year == year)) {
      entries.add(
        TaxReportEntry(
          id: 'income_${job.id}',
          type: TaxTransactionType.income,
          date: job.createdAt,
          jobTitle: job.title,
          category: job.category,
          locationName: job.locationName,
          amount: job.payout,
          sourceJobId: job.id,
        ),
      );
    }

    for (final job
        in completedPostedJobs.where((j) => j.createdAt.year == year)) {
      entries.add(
        TaxReportEntry(
          id: 'expense_${job.id}',
          type: TaxTransactionType.expense,
          date: job.createdAt,
          jobTitle: job.title,
          category: job.category,
          locationName: job.locationName,
          amount: job.totalPrice,
          sourceJobId: job.id,
        ),
      );
    }

    entries.sort((a, b) => b.date.compareTo(a.date));

    final totalIncome = entries
        .where((e) => e.isIncome)
        .fold<double>(0, (sum, e) => sum + e.amount);

    final totalExpenses = entries
        .where((e) => !e.isIncome)
        .fold<double>(0, (sum, e) => sum + e.amount);

    return TaxReportSummary(
      year: year,
      entries: entries,
      totalIncome: totalIncome,
      totalExpenses: totalExpenses,
    );
  }

  /// LOCAL-FIRST:
  /// `true` betyr at jobben er publisert i appen (lokalt).
  /// Supabase-sync-status ligger i [lastAddJobSyncedRemotely].
  /// Tidligere returnerte metoden false hvis Supabase feilet selv om
  /// jobben allerede var synlig lokalt — det skapte misvisende UI.
  Future<bool> addJob({
    required String title,
    required String description,
    required int price,
    required String category,
    required String locationName,
    required double lat,
    required double lng,
    String? imageUrl,
    List<String>? imageUrls,
  }) async {
    _lastAddJobSyncedRemotely = false;

    final job = Job(
      id: _uuid.v4(),
      title: title,
      description: description,
      price: price,
      category: category,
      locationName: locationName,
      lat: lat,
      lng: lng,
      imageUrl: imageUrl,
      createdByUserId: _currentUser.id,
      status: JobStatus.open,
      createdAt: DateTime.now(),
      viewCount: 0,
    );

    _jobs.insert(0, job);

    if (imageUrls != null && imageUrls.isNotEmpty) {
      _jobImages[job.id] = List<String>.from(imageUrls);
    } else if (imageUrl != null && imageUrl.isNotEmpty) {
      _jobImages[job.id] = [imageUrl];
    }

    notifyListeners();

    try {
      final saved = await _supabaseService.createJob(job);

      if (saved != null) {
        _replaceJobLocally(saved);
        _lastAddJobSyncedRemotely = true;

        if (imageUrls != null && imageUrls.isNotEmpty) {
          await _supabaseService.addJobImages(
            jobId: saved.id,
            urls: imageUrls,
          );
        }
      }
    } catch (e) {
      debugPrint('addJob Supabase error (lokalt bevart): $e');
    }

    notifyListeners();
    // Local insert lyktes → returner true. UI leser
    // lastAddJobSyncedRemotely for å si om remote gikk gjennom.
    return true;
  }

  Future<bool> updateOwnJob({
    required String jobId,
    required String title,
    required String description,
    required int price,
    required String category,
    required String locationName,
    required double lat,
    required double lng,
  }) async {
    final job = getJobById(jobId);
    if (job == null) return false;
    if (job.createdByUserId != _currentUser.id) return false;
    if (job.status != JobStatus.open) return false;

    final original = job;
    final updated = job.copyWith(
      title: title,
      description: description,
      price: price,
      category: category,
      locationName: locationName,
      lat: lat,
      lng: lng,
    );

    _replaceJobLocally(updated);
    notifyListeners();

    try {
      final saved = await _supabaseService.updateJob(updated);
      if (saved != null) {
        _replaceJobLocally(saved);
        notifyListeners();
        return true;
      }
      _replaceJobLocally(original);
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('updateOwnJob error: $e');
      _replaceJobLocally(original);
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteOwnJob(String jobId) async {
    final job = getJobById(jobId);
    if (job == null) return false;
    if (job.createdByUserId != _currentUser.id) return false;
    if (job.status != JobStatus.open) return false;

    final previousJobs = [..._jobs];
    _jobs.removeWhere((j) => j.id == jobId);
    _jobImages.remove(jobId);
    notifyListeners();

    try {
      await _supabaseService.deleteJob(jobId);
      return true;
    } catch (e) {
      debugPrint('deleteOwnJob error: $e');
      _jobs = previousJobs;
      notifyListeners();
      return false;
    }
  }

  Future<bool> reserveJob(String id) async {
    final job = getJobById(id);
    if (job == null) return false;
    if (job.status != JobStatus.open) return false;
    if (job.createdByUserId == _currentUser.id) return false;

    final updated = job.copyWith(
      status: JobStatus.reserved,
      acceptedByUserId: _currentUser.id,
      reservedAt: DateTime.now(),
      cancelRequestedByUserId: null,
      isPaymentReserved: false,
      isCompletedByWorker: false,
      isApprovedByOwner: false,
    );

    _replaceJobLocally(updated);
    _addSystemMessage(
      jobId: id,
      text: '${_currentUser.firstName} reserverte oppdraget.',
    );
    _addNotification(
      '${_currentUser.firstName} reserverte "${job.title}"',
      jobId: id,
    );
    notifyListeners();

    try {
      final saved = await _supabaseService.updateJob(updated);
      if (saved != null) {
        _replaceJobLocally(saved);
      }
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Reserve feilet: $e');
      return false;
    }
  }

  Future<void> cancelReservation(String id) async {
    await releaseJob(id);
  }

  Future<void> startJob(String id) async {
    final job = getJobById(id);
    if (job == null) return;
    if (job.status != JobStatus.reserved) return;
    if (job.acceptedByUserId != _currentUser.id) return;

    final updated = job.copyWith(
      status: JobStatus.inProgress,
      isPaymentReserved: true,
      cancelRequestedByUserId: null,
    );

    await _saveJobUpdate(
      updated,
      systemMessage: '${_currentUser.firstName} startet oppdraget.',
      notification:
          '${_currentUser.firstName} startet "${job.title}". Betalingen er reservert.',
    );
  }

  Future<void> completeJob(String id) async {
    await completeJobByWorker(id);
  }

  Future<void> completeJobByWorker(String id) async {
    final job = getJobById(id);
    if (job == null) return;
    if (job.status != JobStatus.inProgress) return;
    if (job.acceptedByUserId != _currentUser.id) return;
    if (job.isCompletedByWorker) return;

    final updated = job.copyWith(
      isCompletedByWorker: true,
      cancelRequestedByUserId: null,
    );

    await _saveJobUpdate(
      updated,
      systemMessage:
          '${_currentUser.firstName} markerte oppdraget som fullført. Venter på godkjenning fra oppdragsgiver.',
      notification: '"${job.title}" er markert som fullført — venter på godkjenning.',
    );
  }

  Future<void> approveAndReleasePayment(String id) async {
    final job = getJobById(id);
    if (job == null) return;
    if (job.createdByUserId != _currentUser.id) return;
    if (job.status != JobStatus.inProgress) return;
    if (!job.isCompletedByWorker) return;

    final updated = job.copyWith(
      status: JobStatus.completed,
      isApprovedByOwner: true,
      cancelRequestedByUserId: null,
    );

    await _saveJobUpdate(
      updated,
      systemMessage:
          '${_currentUser.firstName} godkjente oppdraget. Klar for utbetaling via escrow/Stripe senere.',
      notification: 'Betaling for "${job.title}" er godkjent og klar for utbetaling.',
    );
  }

  Future<void> releaseJob(String id) async {
    final job = getJobById(id);
    if (job == null) return;
    if (job.status != JobStatus.reserved) return;
    if (job.acceptedByUserId != _currentUser.id &&
        job.createdByUserId != _currentUser.id) {
      return;
    }

    final updated = job.copyWith(
      status: JobStatus.open,
      acceptedByUserId: null,
      reservedAt: null,
      isPaymentReserved: false,
      isCompletedByWorker: false,
      isApprovedByOwner: false,
      cancelRequestedByUserId: null,
    );

    await _saveJobUpdate(
      updated,
      systemMessage: 'Reservasjonen ble opphevet.',
      notification: 'Reservasjonen på "${job.title}" ble opphevet.',
    );
  }

  Future<void> expireReservation(String id) async {
    final job = getJobById(id);
    if (job == null) return;
    if (job.status != JobStatus.reserved) return;

    final reservedUntil = job.reservedUntil;
    if (reservedUntil == null || reservedUntil.isAfter(DateTime.now())) return;

    final updated = job.copyWith(
      status: JobStatus.open,
      acceptedByUserId: null,
      reservedAt: null,
      cancelRequestedByUserId: null,
      isPaymentReserved: false,
      isCompletedByWorker: false,
      isApprovedByOwner: false,
    );

    await _saveJobUpdate(
      updated,
      systemMessage: 'Reservasjonen utløp automatisk.',
      notification: 'Reservasjonen på "${job.title}" utløp automatisk.',
    );
  }

  Future<void> cancelJob(String id) async {
    final job = getJobById(id);
    if (job == null) return;

    final isOwner = job.createdByUserId == _currentUser.id;
    final isWorker = job.acceptedByUserId == _currentUser.id;
    if (!isOwner && !isWorker) return;

    if (job.status == JobStatus.open) {
      if (isOwner) {
        await deleteOwnJob(id);
      }
      return;
    }

    if (job.status == JobStatus.reserved) {
      await releaseJob(id);
      return;
    }

    if (job.status == JobStatus.inProgress) {
      if (job.cancelRequestedByUserId != null &&
          job.cancelRequestedByUserId != _currentUser.id) {
        await approveCancel(id);
        return;
      }

      final updated = job.copyWith(
        cancelRequestedByUserId: _currentUser.id,
      );

      await _saveJobUpdate(
        updated,
        systemMessage:
            '${_currentUser.firstName} ba om å avbryte oppdraget.',
        notification:
            '${_currentUser.firstName} ba om å avbryte "${job.title}".',
      );
    }
  }

  Future<void> approveCancel(String id) async {
    final job = getJobById(id);
    if (job == null) return;
    if (job.cancelRequestedByUserId == null) return;

    final canApprove = job.createdByUserId == _currentUser.id ||
        job.acceptedByUserId == _currentUser.id;
    if (!canApprove) return;
    if (job.cancelRequestedByUserId == _currentUser.id) return;

    final updated = job.copyWith(
      status: JobStatus.open,
      acceptedByUserId: null,
      reservedAt: null,
      isPaymentReserved: false,
      isCompletedByWorker: false,
      isApprovedByOwner: false,
      cancelRequestedByUserId: null,
    );

    await _saveJobUpdate(
      updated,
      systemMessage: 'Avbrytelsen ble godkjent. Oppdraget er åpnet igjen.',
      notification: 'Avbrytelse av "${job.title}" ble godkjent.',
    );
  }

  Future<void> rejectCancel(String id) async {
    final job = getJobById(id);
    if (job == null) return;
    if (job.cancelRequestedByUserId == null) return;

    final canReject = job.createdByUserId == _currentUser.id ||
        job.acceptedByUserId == _currentUser.id;
    if (!canReject) return;
    if (job.cancelRequestedByUserId == _currentUser.id) return;

    final updated = job.copyWith(
      cancelRequestedByUserId: null,
    );

    await _saveJobUpdate(
      updated,
      systemMessage:
          '${_currentUser.firstName} avslo avbrytelsen. Oppdraget fortsetter.',
      notification:
          '${_currentUser.firstName} avslo avbrytelsen av "${job.title}".',
    );
  }

  Future<void> withdrawCancelRequest(String id) async {
    final job = getJobById(id);
    if (job == null) return;
    if (job.cancelRequestedByUserId == null) return;
    if (job.cancelRequestedByUserId != _currentUser.id) return;

    final updated = job.copyWith(
      cancelRequestedByUserId: null,
    );

    await _saveJobUpdate(
      updated,
      systemMessage:
          '${_currentUser.firstName} trakk tilbake forespørselen om å avbryte.',
    );
  }

  Future<void> incrementView(String id) async {
    final job = getJobById(id);
    if (job == null) return;

    final updated = job.copyWith(viewCount: job.viewCount + 1);
    _replaceJobLocally(updated);
    notifyListeners();

    try {
      await _supabaseService.updateJob(updated);
    } catch (e) {
      debugPrint('incrementView error: $e');
    }
  }

  Future<void> loadImages(String id) async {
    if (_jobImages.containsKey(id) && _jobImages[id]!.isNotEmpty) return;

    final localJob = getJobById(id);
    final localUrls = <String>[];

    if (localJob?.imageUrl != null && localJob!.imageUrl!.isNotEmpty) {
      localUrls.add(localJob.imageUrl!);
    }

    try {
      final remote = await _supabaseService.fetchJobImages(id);
      final merged = <String>{...localUrls, ...remote}.toList();
      _jobImages[id] = merged;
    } catch (e) {
      debugPrint('loadImages error: $e');
      _jobImages[id] = localUrls;
    }

    notifyListeners();
  }

  void sendMessage({
    required String jobId,
    required String text,
    String? replyToMessageId,
    String? replyToText,
    String? imageUrl,
  }) {
    final trimmed = text.trim();
    if (trimmed.isEmpty && (imageUrl == null || imageUrl.isEmpty)) return;

    _messages.add(
      ChatMessage(
        id: _uuid.v4(),
        jobId: jobId,
        senderId: _currentUser.id,
        text: trimmed,
        createdAt: DateTime.now(),
        replyToMessageId: replyToMessageId,
        replyToText: replyToText,
        imageUrl: imageUrl,
      ),
    );

    final job = getJobById(jobId);
    final preview = trimmed.isNotEmpty
        ? (trimmed.length > 40 ? '${trimmed.substring(0, 40)}…' : trimmed)
        : '📷 Bilde';
    _addNotification(
      'Ny melding${job != null ? ' i "${job.title}"' : ''}: $preview',
      jobId: jobId,
    );

    notifyListeners();
  }

  void toggleReaction(String messageId, String reaction) {
    final index = _messages.indexWhere((m) => m.id == messageId);
    if (index == -1) return;

    final message = _messages[index];
    final updated = message.copyWith(
      reaction: message.reaction == reaction ? null : reaction,
    );
    _messages[index] = updated;
    notifyListeners();
  }

  void setPushNotifications(bool value) {
    _currentUser = _currentUser.copyWith(pushNotificationsEnabled: value);
    _users[_currentUser.id] = _currentUser;
    notifyListeners();
  }

  void updateProfile({
    required String firstName,
    required String email,
    required String phone,
    required bool wantsToWork,
    required String preferredArea,
  }) {
    _currentUser = _currentUser.copyWith(
      firstName: firstName,
      email: email,
      phone: phone,
      wantsToWork: wantsToWork,
      preferredArea: preferredArea,
    );
    _users[_currentUser.id] = _currentUser;
    notifyListeners();
  }

  /// Brukes av onboarding for å sette rolle + sted uten å røre andre felt.
  void applyOnboarding({
    required bool wantsToWork,
    required String preferredArea,
  }) {
    _currentUser = _currentUser.copyWith(
      wantsToWork: wantsToWork,
      preferredArea: preferredArea,
    );
    _users[_currentUser.id] = _currentUser;
    notifyListeners();
  }

  void switchUser() {
    final ids = _users.keys.toList();
    if (ids.length < 2) return;

    final next = ids.firstWhere(
      (id) => id != _currentUser.id,
      orElse: () => _currentUser.id,
    );

    _currentUser = _users[next]!;
    notifyListeners();
  }

  void rateUser({required String userId, required double newRating}) {
    final user = _users[userId];
    if (user == null) return;

    final total = (user.rating * user.ratingCount) + newRating;
    final nextCount = user.ratingCount + 1;
    final nextRating = total / nextCount;

    _users[userId] = user.copyWith(
      rating: nextRating,
      ratingCount: nextCount,
    );

    _addNotification(
      '${user.firstName} fikk ny vurdering: ${newRating.toStringAsFixed(1)}★',
    );

    notifyListeners();
  }

  // 🔔 Notification API

  void markAllNotificationsRead() {
    if (!_hasUnreadNotifications) return;
    _hasUnreadNotifications = false;
    notifyListeners();
  }

  void clearAllNotifications() {
    if (_notifications.isEmpty && !_hasUnreadNotifications) return;
    _notifications.clear();
    _hasUnreadNotifications = false;
    notifyListeners();
  }

  void _addNotification(String text, {String? jobId}) {
    _notifications.add(
      AppNotification(
        id: _uuid.v4(),
        text: text,
        createdAt: DateTime.now(),
        jobId: jobId,
      ),
    );
    _hasUnreadNotifications = true;
    notifyListeners();
  }

  Future<void> _saveJobUpdate(
    Job updated, {
    String? systemMessage,
    String? notification,
  }) async {
    _replaceJobLocally(updated);

    if (systemMessage != null && systemMessage.isNotEmpty) {
      _addSystemMessage(jobId: updated.id, text: systemMessage);
    }

    if (notification != null && notification.isNotEmpty) {
      _addNotification(notification, jobId: updated.id);
    }

    notifyListeners();

    try {
      final saved = await _supabaseService.updateJob(updated);
      if (saved != null) {
        _replaceJobLocally(saved);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('_saveJobUpdate error: $e');
    }
  }

  void _replaceJobLocally(Job updated) {
    final index = _jobs.indexWhere((j) => j.id == updated.id);
    if (index == -1) {
      _jobs.insert(0, updated);
    } else {
      _jobs[index] = updated;
    }
  }

  void _addSystemMessage({
    required String jobId,
    required String text,
  }) {
    _messages.add(
      ChatMessage(
        id: _uuid.v4(),
        jobId: jobId,
        senderId: 'system',
        text: text,
        createdAt: DateTime.now(),
      ),
    );
  }

  static const String _seedOwnerId = '00000000-0000-0000-0000-000000000001';
  static const String _seedWorkerId = '00000000-0000-0000-0000-000000000002';
  static const String _seedJobId = '00000000-0000-0000-0000-000000000010';

  void _seedUsers() {
    final owner = UserProfile(
      id: _seedOwnerId,
      firstName: 'Anders',
      email: '',
      phone: '',
      wantsToWork: false,
      preferredArea: 'Skien',
      rating: 4.5,
      ratingCount: 10,
      pushNotificationsEnabled: true,
    );

    final worker = UserProfile(
      id: _seedWorkerId,
      firstName: 'Kenneth',
      email: '',
      phone: '',
      wantsToWork: true,
      preferredArea: 'Skien',
      rating: 5,
      ratingCount: 1,
      pushNotificationsEnabled: true,
    );

    _users[owner.id] = owner;
    _users[worker.id] = worker;
    _currentUser = worker;
  }

  List<Job> _buildSeedJobs() {
    return [
      Job(
        id: _seedJobId,
        title: 'Bære ved',
        description: 'Trenger hjelp med å bære ved inn i boden.',
        price: 300,
        category: 'Hage',
        locationName: 'Skien',
        lat: 59.2096,
        lng: 9.6089,
        createdByUserId: _seedOwnerId,
        status: JobStatus.open,
        createdAt: DateTime.now(),
        viewCount: 0,
      ),
    ];
  }

  // V2 foundation

  double get userLat => _userLat;
  double get userLng => _userLng;

  void setUserLocation({required double lat, required double lng}) {
    _userLat = lat;
    _userLng = lng;
    notifyListeners();
  }

  double jobDistance(Job job) {
    return _haversineMeters(
      lat1: _userLat,
      lng1: _userLng,
      lat2: job.lat,
      lng2: job.lng,
    );
  }

  String formatDistance(double meters) {
    if (meters < 1000) return '${meters.round()} m unna';
    final km = meters / 1000.0;
    return '${km.toStringAsFixed(1)} km unna';
  }

  String jobLocationLabel(Job job) {
    final d = formatDistance(jobDistance(job));
    return '$d • ${job.locationName}';
  }

  double jobMarkerLat(Job job) =>
      job.lat + _hashOffset(job.id, 0x9E37) * _markerSpread;

  double jobMarkerLng(Job job) =>
      job.lng + _hashOffset(job.id, 0x85EB) * _markerSpread;

  List<String> get userPreferredCategories =>
      List.unmodifiable(_preferredCategories);

  void setUserPreferredCategories(List<String> categories) {
    _preferredCategories
      ..clear()
      ..addAll(categories);
    notifyListeners();
  }

  List<Job> get jobsMatchingUserPreferences {
    if (_preferredCategories.isEmpty) return List.unmodifiable(_jobs);
    return _jobs
        .where((j) => _preferredCategories.contains(j.category))
        .toList();
  }

  double _deg2rad(double deg) => deg * (pi / 180);

  double _haversineMeters({
    required double lat1,
    required double lng1,
    required double lat2,
    required double lng2,
  }) {
    const earthRadius = 6371000.0;
    final dLat = _deg2rad(lat2 - lat1);
    final dLng = _deg2rad(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) *
            cos(_deg2rad(lat2)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _hashOffset(String key, int salt) {
    int h = (2166136261 ^ salt) & 0x7FFFFFFF;
    for (final c in key.codeUnits) {
      h = (h ^ c) & 0x7FFFFFFF;
      h = (h * 16777619) & 0x7FFFFFFF;
    }
    return (h % 20000) / 10000.0 - 1.0;
  }
}
