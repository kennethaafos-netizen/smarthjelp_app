import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/chat_message.dart';
import '../models/job.dart';
import '../models/user_profile.dart';
import '../services/supabase_service.dart';

enum TaxTransactionType { income, expense }

enum AppNotificationType {
  message,
  reserved,
  started,
  completed,
  approved,
  cancelRequested,
  cancelApproved,
  cancelRejected,
  reservationExpired,
  reservationReleased,
}

String _notificationTypeToWire(AppNotificationType t) {
  switch (t) {
    case AppNotificationType.message: return 'message';
    case AppNotificationType.reserved: return 'reserved';
    case AppNotificationType.started: return 'started';
    case AppNotificationType.completed: return 'completed';
    case AppNotificationType.approved: return 'approved';
    case AppNotificationType.cancelRequested: return 'cancel_requested';
    case AppNotificationType.cancelApproved: return 'cancel_approved';
    case AppNotificationType.cancelRejected: return 'cancel_rejected';
    case AppNotificationType.reservationExpired: return 'reservation_expired';
    case AppNotificationType.reservationReleased: return 'reservation_released';
  }
}

AppNotificationType _notificationTypeFromWire(String? s) {
  switch (s) {
    case 'message': return AppNotificationType.message;
    case 'reserved': return AppNotificationType.reserved;
    case 'started': return AppNotificationType.started;
    case 'completed': return AppNotificationType.completed;
    case 'approved': return AppNotificationType.approved;
    case 'cancel_requested': return AppNotificationType.cancelRequested;
    case 'cancel_approved': return AppNotificationType.cancelApproved;
    case 'cancel_rejected': return AppNotificationType.cancelRejected;
    case 'reservation_expired': return AppNotificationType.reservationExpired;
    case 'reservation_released': return AppNotificationType.reservationReleased;
    default: return AppNotificationType.message;
  }
}

class AppNotification {
  final String id;
  final String recipientUserId;
  final AppNotificationType type;
  final String text;
  final DateTime createdAt;
  final String? jobId;
  final bool isRead;

  const AppNotification({
    required this.id,
    required this.recipientUserId,
    required this.type,
    required this.text,
    required this.createdAt,
    required this.jobId,
    required this.isRead,
  });

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      recipientUserId: recipientUserId,
      type: type,
      text: text,
      createdAt: createdAt,
      jobId: jobId,
      isRead: isRead ?? this.isRead,
    );
  }

  bool get isMessage => type == AppNotificationType.message;

  factory AppNotification.fromSupabase(Map<String, dynamic> map) {
    final dt = map['created_at'];
    DateTime created = DateTime.now();
    if (dt is DateTime) {
      created = dt.toLocal();
    } else if (dt != null) {
      created = DateTime.tryParse(dt.toString())?.toLocal() ?? DateTime.now();
    }
    return AppNotification(
      id: (map['id'] ?? '').toString(),
      recipientUserId: (map['recipient_user_id'] ?? '').toString(),
      type: _notificationTypeFromWire(map['type']?.toString()),
      text: (map['text'] ?? '').toString(),
      createdAt: created,
      jobId: map['job_id'] == null ? null : map['job_id'].toString(),
      isRead: map['is_read'] == true,
    );
  }
}

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

class AppState extends ChangeNotifier {
  AppState({SupabaseService? supabaseService})
      : _supabaseService = supabaseService ?? SupabaseService() {
    _seedUsers();
    _currentUser = _guestProfile();
    _bootstrap();
  }

  final Uuid _uuid = const Uuid();
  final SupabaseService _supabaseService;

  late UserProfile _currentUser;

  final Map<String, UserProfile> _users = {};
  final Set<String> _profilesRequested = <String>{};
  List<Job> _jobs = [];
  final List<ChatMessage> _messages = [];
  final Set<String> _loadedMessageJobIds = <String>{};
  final Map<String, List<String>> _jobImages = {};

  final List<AppNotification> _notifications = [];

  bool _isLoadingJobs = false;
  bool _hasLoadedJobs = false;
  String? _jobsError;

  bool _isAuthenticated = false;
  bool _isAuthLoading = true;

  RealtimeChannel? _jobsChannel;
  RealtimeChannel? _chatChannel;
  RealtimeChannel? _notificationsChannel;
  RealtimeChannel? _profilesChannel;

  Timer? _notifReloadTimer;

  static const double _markerSpread = 0.006;
  double _userLat = 59.14;
  double _userLng = 9.65;
  final Set<String> _preferredCategories = <String>{};

  UserProfile get currentUser => _currentUser;
  List<Job> get jobs => List.unmodifiable(_jobs);
  bool get isLoadingJobs => _isLoadingJobs;
  bool get hasLoadedJobs => _hasLoadedJobs;
  String? get jobsError => _jobsError;

  bool get isAuthenticated => _isAuthenticated;
  bool get isAuthLoading => _isAuthLoading;

  SupabaseClient get _client => Supabase.instance.client;

  // ---- NOTIFICATIONS ----

  List<AppNotification> get notifications {
    final mine = _notifications
        .where((n) => n.recipientUserId == _currentUser.id)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(mine);
  }

  int get unreadNotificationCount => _notifications
      .where((n) => n.recipientUserId == _currentUser.id && !n.isRead)
      .length;

  bool get hasUnreadNotifications => unreadNotificationCount > 0;

  // FASE 3: chat-spesifikke uleste tellere for badge i bottom-nav.
  int get unreadChatNotificationCount => _notifications
      .where((n) =>
          n.recipientUserId == _currentUser.id &&
          !n.isRead &&
          n.type == AppNotificationType.message)
      .length;

  bool get hasUnreadChat => unreadChatNotificationCount > 0;

  void markNotificationRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index == -1) return;
    if (_notifications[index].isRead) return;
    _notifications[index] = _notifications[index].copyWith(isRead: true);
    notifyListeners();
    _supabaseService.markNotificationReadRemote(id);
  }

  void markAllNotificationsRead() {
    var changed = false;
    for (var i = 0; i < _notifications.length; i++) {
      final n = _notifications[i];
      if (n.recipientUserId == _currentUser.id && !n.isRead) {
        _notifications[i] = n.copyWith(isRead: true);
        changed = true;
      }
    }
    if (changed) notifyListeners();
    if (_currentUser.id.isNotEmpty) {
      _supabaseService.markAllNotificationsReadRemote(_currentUser.id);
    }
  }

  void clearNotifications() {
    final before = _notifications.length;
    _notifications.removeWhere((n) => n.recipientUserId == _currentUser.id);
    if (_notifications.length != before) notifyListeners();
    if (_currentUser.id.isNotEmpty) {
      _supabaseService.deleteNotificationsForUser(_currentUser.id);
    }
  }

  void clearAllNotifications() => clearNotifications();

  void _pushNotification({
    required String recipientUserId,
    required AppNotificationType type,
    required String text,
    String? jobId,
  }) {
    if (recipientUserId.isEmpty) return;
    final id = _uuid.v4();
    final createdAt = DateTime.now();
    _supabaseService.insertNotification(
      id: id,
      recipientUserId: recipientUserId,
      type: _notificationTypeToWire(type),
      text: text,
      jobId: jobId,
      createdAt: createdAt,
    );
  }

  // ---- JOB LISTS ----

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

  // FASE 3: inProgress-oppdrag der current user er deltaker.
  // Brukes av HomeScreen-banneret.
  List<Job> get inProgressJobsForCurrentUser {
    if (_currentUser.id.isEmpty) return const [];
    return _jobs.where((j) {
      if (j.status != JobStatus.inProgress) return false;
      return j.createdByUserId == _currentUser.id ||
          j.acceptedByUserId == _currentUser.id;
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  // ---- AUTH ----

  Future<void> _bootstrap() async {
    await loadCurrentUser();
    if (_isAuthenticated) {
      await ensureJobsLoaded();
      await _hydrateOwnProfile();
      await _loadNotifications();
    }
  }

  Future<void> loadCurrentUser() async {
    _isAuthLoading = true;
    notifyListeners();

    final user = _client.auth.currentUser;
    if (user == null) {
      _currentUser = _guestProfile();
      _isAuthenticated = false;
      _isAuthLoading = false;
      notifyListeners();
      return;
    }

    _currentUser = _profileFromAuthUser(user);
    _users[_currentUser.id] = _currentUser;
    _isAuthenticated = true;
    _isAuthLoading = false;
    notifyListeners();
  }

  Future<String?> login({
    required String email,
    required String password,
  }) async {
    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty || password.isEmpty) {
      return 'Fyll inn e-post og passord.';
    }
    try {
      final res = await _client.auth.signInWithPassword(
        email: trimmedEmail,
        password: password,
      );
      if (res.user == null) return 'Feil e-post eller passord.';
      await loadCurrentUser();
      await ensureJobsLoaded();
      await _hydrateOwnProfile();
      await _loadNotifications();
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      debugPrint('login error: $e');
      return 'Noe gikk galt. Prøv igjen.';
    }
  }

  Future<String?> register({
    required String email,
    required String password,
    required String name,
    bool wantsToWork = true,
    String preferredArea = '',
  }) async {
    final trimmedEmail = email.trim();
    final trimmedName = name.trim();
    if (trimmedEmail.isEmpty || password.isEmpty || trimmedName.isEmpty) {
      return 'Fyll inn navn, e-post og passord.';
    }
    if (password.length < 6) return 'Passordet må være minst 6 tegn.';
    try {
      final res = await _client.auth.signUp(
        email: trimmedEmail,
        password: password,
        data: {
          'first_name': trimmedName,
          'wants_to_work': wantsToWork,
          'preferred_area': preferredArea,
        },
      );
      if (res.user == null) return 'Kunne ikke opprette bruker.';
      if (res.session == null) {
        return 'Vi har sendt en bekreftelsesepost. Bekreft den og logg inn.';
      }
      await loadCurrentUser();
      await ensureJobsLoaded();
      await _hydrateOwnProfile();
      await _loadNotifications();
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      debugPrint('register error: $e');
      return 'Noe gikk galt. Prøv igjen.';
    }
  }

  Future<void> logout() async {
    _notifReloadTimer?.cancel();
    _notifReloadTimer = null;
    await _teardownAllRealtime();
    try {
      await _client.auth.signOut();
    } catch (e) {
      debugPrint('signOut error: $e');
    }
    _resetStateAfterLogout();
    notifyListeners();
  }

  void _resetStateAfterLogout() {
    _currentUser = _guestProfile();
    _isAuthenticated = false;
    _isAuthLoading = false;
    _jobs = [];
    _hasLoadedJobs = false;
    _jobsError = null;
    _notifications.clear();
    _messages.clear();
    _loadedMessageJobIds.clear();
    _jobImages.clear();
    _profilesRequested.clear();
    _preferredCategories.clear();
  }

  UserProfile _profileFromAuthUser(User user) {
    final md = user.userMetadata ?? const <String, dynamic>{};
    final fallbackName = (user.email ?? '').split('@').first;
    final firstName =
        (md['first_name'] ?? md['name'] ?? fallbackName).toString().trim();
    final phone = (md['phone'] ?? user.phone ?? '').toString();
    final wantsToWork =
        md['wants_to_work'] is bool ? md['wants_to_work'] as bool : true;
    final preferredArea = (md['preferred_area'] ?? '').toString();

    DateTime created;
    try {
      created = DateTime.parse(user.createdAt);
    } catch (_) {
      created = DateTime.now();
    }

    return UserProfile(
      id: user.id,
      firstName: firstName.isEmpty ? 'Bruker' : firstName,
      email: user.email ?? '',
      phone: phone,
      wantsToWork: wantsToWork,
      preferredArea: preferredArea,
      rating: 5.0,
      ratingCount: 0,
      pushNotificationsEnabled: true,
      createdAt: created,
      isVerified: user.emailConfirmedAt != null,
    );
  }

  UserProfile _guestProfile() {
    return UserProfile(
      id: '',
      firstName: 'Gjest',
      email: '',
      phone: '',
      wantsToWork: false,
      preferredArea: '',
      rating: 0,
      ratingCount: 0,
      pushNotificationsEnabled: false,
      createdAt: DateTime.now(),
      isVerified: false,
    );
  }

  Future<void> _hydrateOwnProfile() async {
    if (!_isAuthenticated || _currentUser.id.isEmpty) return;
    final existing = await _supabaseService.fetchProfile(_currentUser.id);

    final authVerified = _client.auth.currentUser?.emailConfirmedAt != null;

    if (existing != null) {
      final effectiveVerified = existing.isVerified || authVerified;
      _currentUser = _currentUser.copyWith(
        firstName: existing.firstName.isEmpty
            ? _currentUser.firstName
            : existing.firstName,
        phone: existing.phone,
        wantsToWork: existing.wantsToWork,
        preferredArea: existing.preferredArea,
        rating: existing.rating,
        ratingCount: existing.ratingCount,
        isVerified: effectiveVerified,
      );
      _users[_currentUser.id] = _currentUser;
      notifyListeners();

      if (authVerified && !existing.isVerified) {
        await _supabaseService.upsertProfile(_currentUser);
      }
    } else {
      await _supabaseService.upsertProfile(_currentUser);
    }
    _setupProfilesSubscription();
  }

  Future<void> _syncProfileToSupabase() async {
    if (!_isAuthenticated) return;
    try {
      await _client.auth.updateUser(
        UserAttributes(
          data: {
            'first_name': _currentUser.firstName,
            'phone': _currentUser.phone,
            'wants_to_work': _currentUser.wantsToWork,
            'preferred_area': _currentUser.preferredArea,
          },
        ),
      );
    } catch (e) {
      debugPrint('profile auth sync error: $e');
    }
    await _supabaseService.upsertProfile(_currentUser);
  }

  // ---- JOBS ----

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
      debugPrint('ensureJobsLoaded error: $e');
      _jobs = [];
      _hasLoadedJobs = true;
      _jobsError = 'Kunne ikke laste oppdrag. Sjekk nettverk og prøv igjen.';
    }

    _isLoadingJobs = false;
    notifyListeners();

    if (_isAuthenticated) {
      _setupJobsSubscription();
      _setupChatSubscription();
      _setupNotificationsSubscription();
      _setupProfilesSubscription();
      _hydrateProfilesForLoadedJobs();
      _hydrateImagesForLoadedJobs();
    }
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

    if (_isAuthenticated) {
      _setupJobsSubscription();
      _setupChatSubscription();
      _setupNotificationsSubscription();
      _setupProfilesSubscription();
      _hydrateProfilesForLoadedJobs();
      _hydrateImagesForLoadedJobs();
    }
  }

  Job? getJobById(String id) {
    try {
      return _jobs.firstWhere((j) => j.id == id);
    } catch (_) {
      return null;
    }
  }

  UserProfile? getUserById(String id) {
    if (id.isEmpty) return null;
    final cached = _users[id];
    if (cached != null) return cached;
    _ensureProfileLoaded(id);
    return null;
  }

  List<String> getImages(String jobId) =>
      List.unmodifiable(_jobImages[jobId] ?? const []);

  List<ChatMessage> getMessagesForJob(String jobId) {
    final result = _messages.where((m) => m.jobId == jobId).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return result;
  }

  int completedJobCountForUser(String userId) {
    if (userId.isEmpty) return 0;
    return _jobs.where((j) {
      final done = j.status == JobStatus.completed && j.isApprovedByOwner;
      if (!done) return false;
      return j.createdByUserId == userId || j.acceptedByUserId == userId;
    }).length;
  }

  List<Job> get smartRankedJobs {
    final result = _jobs.where((j) {
      if (j.status != JobStatus.open) return false;
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

  double get totalIncome => moneyEarned;
  double get totalExpenses => moneySpent;
  double get netBalance => totalIncome - totalExpenses;

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
      entries.add(TaxReportEntry(
        id: 'income_${job.id}',
        type: TaxTransactionType.income,
        date: job.createdAt,
        jobTitle: job.title,
        category: job.category,
        locationName: job.locationName,
        amount: job.payout,
        sourceJobId: job.id,
      ));
    }

    for (final job
        in completedPostedJobs.where((j) => j.createdAt.year == year)) {
      entries.add(TaxReportEntry(
        id: 'expense_${job.id}',
        type: TaxTransactionType.expense,
        date: job.createdAt,
        jobTitle: job.title,
        category: job.category,
        locationName: job.locationName,
        amount: job.totalPrice,
        sourceJobId: job.id,
      ));
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
    if (!_isAuthenticated || _currentUser.id.isEmpty) return false;

    final draft = Job(
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

    Job saved;
    try {
      saved = await _supabaseService.createJob(draft);
    } catch (e) {
      debugPrint('addJob error: $e');
      return false;
    }

    _replaceJobLocally(saved);

    final urls = <String>[];
    if (imageUrls != null && imageUrls.isNotEmpty) {
      urls.addAll(imageUrls);
    } else if (imageUrl != null && imageUrl.isNotEmpty) {
      urls.add(imageUrl);
    }
    if (urls.isNotEmpty) {
      _jobImages[saved.id] = List<String>.from(urls);
      try {
        await _supabaseService.addJobImages(jobId: saved.id, urls: urls);
      } catch (e) {
        debugPrint('addJob image attach error: $e');
      }
    }

    notifyListeners();
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

    final updated = job.copyWith(
      title: title,
      description: description,
      price: price,
      category: category,
      locationName: locationName,
      lat: lat,
      lng: lng,
    );

    try {
      final saved = await _supabaseService.updateJob(updated);
      if (saved == null) {
        await reloadJobs();
        return false;
      }
      _replaceJobLocally(saved);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('updateOwnJob error: $e');
      return false;
    }
  }

  Future<bool> deleteOwnJob(String jobId) async {
    final job = getJobById(jobId);
    if (job == null) return false;
    if (job.createdByUserId != _currentUser.id) return false;
    if (job.status != JobStatus.open) return false;

    try {
      await _supabaseService.deleteJob(jobId);
    } catch (e) {
      debugPrint('deleteOwnJob error: $e');
      return false;
    }

    _jobs.removeWhere((j) => j.id == jobId);
    _jobImages.remove(jobId);
    notifyListeners();
    return true;
  }

  Future<bool> reserveJob(String id) async {
    if (!_isAuthenticated || _currentUser.id.isEmpty) return false;

    final job = getJobById(id);
    if (job == null) return false;
    if (job.status != JobStatus.open) return false;
    if (job.createdByUserId == _currentUser.id) return false;

    final now = DateTime.now();
    Job? saved;
    try {
      saved = await _supabaseService.reserveJobAtomic(
        jobId: id,
        workerUserId: _currentUser.id,
        reservedAt: now,
      );
    } catch (e) {
      debugPrint('reserveJob error: $e');
      return false;
    }

    if (saved == null) {
      await reloadJobs();
      return false;
    }

    _replaceJobLocally(saved);
    _addSystemMessage(
      jobId: saved.id,
      text: '${_currentUser.firstName} reserverte oppdraget.',
    );
    _pushNotification(
      recipientUserId: saved.createdByUserId,
      type: AppNotificationType.reserved,
      text:
          '${_currentUser.firstName} reserverte oppdraget «${saved.title}».',
      jobId: saved.id,
    );
    notifyListeners();
    return true;
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
      notifyUserId: updated.createdByUserId,
      notificationType: AppNotificationType.started,
      notificationText:
          '${_currentUser.firstName} startet oppdraget «${updated.title}».',
    );
  }

  Future<void> completeJob(String id) async => completeJobByWorker(id);

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
      notifyUserId: updated.createdByUserId,
      notificationType: AppNotificationType.completed,
      notificationText:
          '${_currentUser.firstName} har fullført «${updated.title}». Godkjenn for utbetaling.',
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
      isPaidOut: true,
      cancelRequestedByUserId: null,
    );

    await _saveJobUpdate(
      updated,
      systemMessage:
          '${_currentUser.firstName} godkjente oppdraget. Klar for utbetaling.',
      notifyUserId: updated.acceptedByUserId,
      notificationType: AppNotificationType.approved,
      notificationText:
          'Oppdraget «${updated.title}» er godkjent. Utbetaling er klar.',
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

    final otherParty = job.acceptedByUserId == _currentUser.id
        ? job.createdByUserId
        : job.acceptedByUserId;

    final updated = job.copyWith(
      status: JobStatus.open,
      acceptedByUserId: null,
      reservedAt: null,
      isPaymentReserved: false,
      paymentReservedAt: null,
      isPaidOut: false,
      isCompletedByWorker: false,
      isApprovedByOwner: false,
      cancelRequestedByUserId: null,
    );

    await _saveJobUpdate(
      updated,
      systemMessage: 'Reservasjonen ble opphevet.',
      notifyUserId: otherParty,
      notificationType: AppNotificationType.reservationReleased,
      notificationText:
          'Reservasjonen på «${updated.title}» ble opphevet.',
    );
  }

  Future<void> expireReservation(String id) async {
    final job = getJobById(id);
    if (job == null) return;
    if (job.status != JobStatus.reserved) return;

    final reservedUntil = job.reservedUntil;
    if (reservedUntil == null || reservedUntil.isAfter(DateTime.now())) return;

    final previousWorker = job.acceptedByUserId;
    final owner = job.createdByUserId;

    final updated = job.copyWith(
      status: JobStatus.open,
      acceptedByUserId: null,
      reservedAt: null,
      cancelRequestedByUserId: null,
      isPaymentReserved: false,
      paymentReservedAt: null,
      isPaidOut: false,
      isCompletedByWorker: false,
      isApprovedByOwner: false,
    );

    final ok = await _saveJobUpdate(
      updated,
      systemMessage: 'Reservasjonen utløp automatisk.',
    );
    if (!ok) return;

    if (previousWorker != null) {
      _pushNotification(
        recipientUserId: previousWorker,
        type: AppNotificationType.reservationExpired,
        text:
            'Reservasjonen din på «${updated.title}» har utløpt. Oppdraget er åpent igjen.',
        jobId: updated.id,
      );
    }
    _pushNotification(
      recipientUserId: owner,
      type: AppNotificationType.reservationExpired,
      text:
          'Reservasjonen på «${updated.title}» utløp. Oppdraget er åpent igjen.',
      jobId: updated.id,
    );
    notifyListeners();
  }

  Future<void> cancelJob(String id) async {
    final job = getJobById(id);
    if (job == null) return;

    final isOwner = job.createdByUserId == _currentUser.id;
    final isWorker = job.acceptedByUserId == _currentUser.id;
    if (!isOwner && !isWorker) return;

    if (job.status == JobStatus.open) {
      if (isOwner) await deleteOwnJob(id);
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

      final otherParty = isOwner ? job.acceptedByUserId : job.createdByUserId;
      final updated = job.copyWith(cancelRequestedByUserId: _currentUser.id);

      await _saveJobUpdate(
        updated,
        systemMessage:
            '${_currentUser.firstName} ba om å avbryte oppdraget.',
        notifyUserId: otherParty,
        notificationType: AppNotificationType.cancelRequested,
        notificationText:
            '${_currentUser.firstName} ba om å avbryte «${updated.title}». Godkjenn eller avslå.',
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

    final requesterId = job.cancelRequestedByUserId!;

    final updated = job.copyWith(
      status: JobStatus.open,
      acceptedByUserId: null,
      reservedAt: null,
      isPaymentReserved: false,
      paymentReservedAt: null,
      isPaidOut: false,
      isCompletedByWorker: false,
      isApprovedByOwner: false,
      cancelRequestedByUserId: null,
    );

    await _saveJobUpdate(
      updated,
      systemMessage: 'Avbrytelsen ble godkjent. Oppdraget er åpnet igjen.',
      notifyUserId: requesterId,
      notificationType: AppNotificationType.cancelApproved,
      notificationText:
          'Forespørselen om å avbryte «${updated.title}» ble godkjent.',
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

    final requesterId = job.cancelRequestedByUserId!;
    final updated = job.copyWith(cancelRequestedByUserId: null);

    await _saveJobUpdate(
      updated,
      systemMessage:
          '${_currentUser.firstName} avslo avbrytelsen. Oppdraget fortsetter.',
      notifyUserId: requesterId,
      notificationType: AppNotificationType.cancelRejected,
      notificationText:
          'Forespørselen om å avbryte «${updated.title}» ble avslått.',
    );
  }

  Future<void> withdrawCancelRequest(String id) async {
    final job = getJobById(id);
    if (job == null) return;
    if (job.cancelRequestedByUserId == null) return;
    if (job.cancelRequestedByUserId != _currentUser.id) return;

    final updated = job.copyWith(cancelRequestedByUserId: null);

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

  Future<void> loadMessagesForJob(String jobId) async {
    if (jobId.isEmpty) return;
    if (_loadedMessageJobIds.contains(jobId)) return;
    _loadedMessageJobIds.add(jobId);

    final remote = await _supabaseService.fetchMessagesForJob(jobId);
    for (final m in remote) {
      _mergeMessage(m);
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
    if (_currentUser.id.isEmpty) return;

    final msg = ChatMessage(
      id: _uuid.v4(),
      jobId: jobId,
      senderId: _currentUser.id,
      text: trimmed,
      createdAt: DateTime.now(),
      replyToMessageId: replyToMessageId,
      replyToText: replyToText,
      imageUrl: imageUrl,
    );

    _mergeMessage(msg);
    notifyListeners();

    _supabaseService.insertMessage(msg).then((saved) {
      _mergeMessage(saved);
      notifyListeners();
    }).catchError((e) {
      debugPrint('sendMessage error: $e');
      _messages.removeWhere((m) => m.id == msg.id);
      notifyListeners();
    });

    final job = getJobById(jobId);
    if (job != null) {
      final otherParty = job.createdByUserId == _currentUser.id
          ? job.acceptedByUserId
          : job.createdByUserId;
      if (otherParty != null && otherParty != _currentUser.id) {
        _pushNotification(
          recipientUserId: otherParty,
          type: AppNotificationType.message,
          text:
              '${_currentUser.firstName}: ${trimmed.isNotEmpty ? trimmed : '📎 Bilde'}',
          jobId: jobId,
        );
      }
    }
  }

  void toggleReaction(String messageId, String reaction) {
    final index = _messages.indexWhere((m) => m.id == messageId);
    if (index == -1) return;

    final message = _messages[index];
    final nextReaction = message.reaction == reaction ? null : reaction;
    final updated = message.copyWith(reaction: nextReaction);
    _messages[index] = updated;
    notifyListeners();

    _supabaseService
        .setMessageReaction(messageId: messageId, reaction: nextReaction)
        .then((saved) {
      if (saved != null) {
        _mergeMessage(saved);
        notifyListeners();
      }
    });
  }

  void setPushNotifications(bool value) {
    _currentUser = _currentUser.copyWith(pushNotificationsEnabled: value);
    _users[_currentUser.id] = _currentUser;
    notifyListeners();
    _supabaseService.upsertProfile(_currentUser);
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
    _syncProfileToSupabase();
  }

  void updateBasicProfile({
    required String firstName,
    required String phone,
  }) {
    final cleanedName = firstName.trim();
    final cleanedPhone = phone.trim();
    _currentUser = _currentUser.copyWith(
      firstName: cleanedName.isEmpty ? _currentUser.firstName : cleanedName,
      phone: cleanedPhone,
    );
    _users[_currentUser.id] = _currentUser;
    notifyListeners();
    _syncProfileToSupabase();
  }

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
    _syncProfileToSupabase();
  }

  void switchUser() {}

  void rateUser({required String userId, required double newRating}) {
    final user = _users[userId];
    if (user == null) return;

    final total = (user.rating * user.ratingCount) + newRating;
    final nextCount = user.ratingCount + 1;
    final nextRating = total / nextCount;

    final updated = user.copyWith(
      rating: nextRating,
      ratingCount: nextCount,
    );
    _users[userId] = updated;
    notifyListeners();

    if (userId == _currentUser.id) {
      _currentUser = updated;
      _supabaseService.upsertProfile(updated);
    }
  }

  Future<bool> _saveJobUpdate(
    Job updated, {
    String? systemMessage,
    String? notifyUserId,
    AppNotificationType? notificationType,
    String? notificationText,
  }) async {
    Job? saved;
    try {
      saved = await _supabaseService.updateJob(updated);
    } catch (e) {
      debugPrint('_saveJobUpdate error: $e');
      return false;
    }

    if (saved == null) {
      await reloadJobs();
      return false;
    }

    _replaceJobLocally(saved);

    if (systemMessage != null && systemMessage.isNotEmpty) {
      _addSystemMessage(jobId: saved.id, text: systemMessage);
    }

    if (notifyUserId != null &&
        notifyUserId.isNotEmpty &&
        notificationType != null &&
        notificationText != null &&
        notifyUserId != _currentUser.id) {
      _pushNotification(
        recipientUserId: notifyUserId,
        type: notificationType,
        text: notificationText,
        jobId: saved.id,
      );
    }

    notifyListeners();
    return true;
  }

  void _replaceJobLocally(Job updated) {
    final index = _jobs.indexWhere((j) => j.id == updated.id);
    if (index == -1) {
      _jobs.insert(0, updated);
    } else {
      _jobs[index] = updated;
    }
    _hydrateProfilesForJob(updated);
  }

  void _addSystemMessage({required String jobId, required String text}) {
    final msg = ChatMessage(
      id: _uuid.v4(),
      jobId: jobId,
      senderId: 'system',
      text: text,
      createdAt: DateTime.now(),
    );
    _mergeMessage(msg);
    _supabaseService.insertMessage(msg).then((saved) {
      _mergeMessage(saved);
      notifyListeners();
    }).catchError((e) {
      debugPrint('system message insert error: $e');
    });
  }

  void _mergeMessage(ChatMessage msg) {
    final idx = _messages.indexWhere((m) => m.id == msg.id);
    if (idx == -1) {
      _messages.add(msg);
    } else {
      _messages[idx] = msg;
    }
  }

  void _ensureProfileLoaded(String id) {
    if (_profilesRequested.contains(id)) return;
    _profilesRequested.add(id);
    _supabaseService.fetchProfile(id).then((p) {
      if (p == null) return;
      _users[p.id] = p;
      notifyListeners();
    });
  }

  void _hydrateProfilesForJob(Job job) {
    _ensureProfileLoaded(job.createdByUserId);
    final accepted = job.acceptedByUserId;
    if (accepted != null && accepted.isNotEmpty) {
      _ensureProfileLoaded(accepted);
    }
  }

  Future<void> _hydrateProfilesForLoadedJobs() async {
    final ids = <String>{};
    for (final j in _jobs) {
      ids.add(j.createdByUserId);
      final a = j.acceptedByUserId;
      if (a != null && a.isNotEmpty) ids.add(a);
    }
    ids.removeWhere((id) => _users.containsKey(id) || id.isEmpty);
    if (ids.isEmpty) return;
    _profilesRequested.addAll(ids);
    final profiles = await _supabaseService.fetchProfiles(ids);
    for (final p in profiles) {
      _users[p.id] = p;
    }
    notifyListeners();
  }

  Future<void> _hydrateImagesForLoadedJobs() async {
    final jobIds = _jobs
        .map((j) => j.id)
        .where((id) {
          final existing = _jobImages[id];
          return existing == null || existing.isEmpty;
        })
        .toList();
    if (jobIds.isEmpty) return;

    await Future.wait(jobIds.map((id) async {
      try {
        final remote = await _supabaseService.fetchJobImages(id);
        if (remote.isNotEmpty) {
          _jobImages[id] = remote;
        } else {
          final job = getJobById(id);
          final fallback = job?.imageUrl;
          if (fallback != null && fallback.isNotEmpty) {
            _jobImages[id] = [fallback];
          }
        }
      } catch (e) {
        debugPrint('hydrate images error for $id: $e');
      }
    }));
    notifyListeners();
  }

  Future<void> _loadNotifications() async {
    if (_currentUser.id.isEmpty) return;
    final rows = await _supabaseService.fetchNotifications(_currentUser.id);
    _notifications.clear();
    for (final r in rows) {
      _notifications.add(AppNotification.fromSupabase(r));
    }
    notifyListeners();
  }

  void _scheduleNotificationsReload() {
    if (_currentUser.id.isEmpty) return;
    _notifReloadTimer?.cancel();
    _notifReloadTimer = Timer(const Duration(milliseconds: 600), () {
      _loadNotifications();
    });
  }

  void _setupJobsSubscription() {
    if (_jobsChannel != null) return;
    final channel = _client.channel('public:jobs:smarthjelp');
    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'jobs',
      callback: (payload) => _handleRemoteJobUpsert(payload.newRecord),
    );
    channel.onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'jobs',
      callback: (payload) => _handleRemoteJobUpsert(payload.newRecord),
    );
    channel.onPostgresChanges(
      event: PostgresChangeEvent.delete,
      schema: 'public',
      table: 'jobs',
      callback: (payload) {
        final oldId = payload.oldRecord['id']?.toString();
        if (oldId != null && oldId.isNotEmpty) _handleRemoteJobDelete(oldId);
      },
    );
    channel.subscribe();
    _jobsChannel = channel;
  }

  void _handleRemoteJobUpsert(Map<String, dynamic> row) {
    if (row.isEmpty) return;
    try {
      final job = Job.fromSupabase(Map<String, dynamic>.from(row));
      _replaceJobLocally(job);
      notifyListeners();

      final involvesMe = job.createdByUserId == _currentUser.id ||
          job.acceptedByUserId == _currentUser.id;
      if (involvesMe) {
        _scheduleNotificationsReload();
      }
    } catch (e) {
      debugPrint('realtime job upsert error: $e');
    }
  }

  void _handleRemoteJobDelete(String id) {
    final before = _jobs.length;
    _jobs.removeWhere((j) => j.id == id);
    if (_jobs.length != before) notifyListeners();
  }

  void _setupChatSubscription() {
    if (_chatChannel != null) return;
    final channel = _client.channel('public:chat:smarthjelp');
    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'chat_messages',
      callback: (payload) => _handleRemoteMessageUpsert(payload.newRecord),
    );
    channel.onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'chat_messages',
      callback: (payload) => _handleRemoteMessageUpsert(payload.newRecord),
    );
    channel.subscribe();
    _chatChannel = channel;
  }

  void _handleRemoteMessageUpsert(Map<String, dynamic> row) {
    if (row.isEmpty) return;
    try {
      final msg = ChatMessage.fromSupabase(Map<String, dynamic>.from(row));
      _mergeMessage(msg);
      notifyListeners();
    } catch (e) {
      debugPrint('realtime chat upsert error: $e');
    }
  }

  void _setupNotificationsSubscription() {
    if (_notificationsChannel != null) return;
    final channel = _client.channel('public:notifications:smarthjelp');
    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'notifications',
      callback: (payload) =>
          _handleRemoteNotificationUpsert(payload.newRecord),
    );
    channel.onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'notifications',
      callback: (payload) =>
          _handleRemoteNotificationUpsert(payload.newRecord),
    );
    channel.onPostgresChanges(
      event: PostgresChangeEvent.delete,
      schema: 'public',
      table: 'notifications',
      callback: (payload) {
        final id = payload.oldRecord['id']?.toString();
        if (id == null) return;
        _notifications.removeWhere((n) => n.id == id);
        notifyListeners();
      },
    );
    channel.subscribe();
    _notificationsChannel = channel;
  }

  void _handleRemoteNotificationUpsert(Map<String, dynamic> row) {
    if (row.isEmpty) return;
    try {
      final n = AppNotification.fromSupabase(Map<String, dynamic>.from(row));
      if (n.recipientUserId != _currentUser.id) return;
      final idx = _notifications.indexWhere((x) => x.id == n.id);
      if (idx == -1) {
        _notifications.add(n);
      } else {
        _notifications[idx] = n;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('realtime notification upsert error: $e');
    }
  }

  void _setupProfilesSubscription() {
    if (_profilesChannel != null) return;
    final channel = _client.channel('public:profiles:smarthjelp');
    channel.onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'profiles',
      callback: (payload) => _handleRemoteProfileUpsert(payload.newRecord),
    );
    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'profiles',
      callback: (payload) => _handleRemoteProfileUpsert(payload.newRecord),
    );
    channel.subscribe();
    _profilesChannel = channel;
  }

  void _handleRemoteProfileUpsert(Map<String, dynamic> row) {
    if (row.isEmpty) return;
    try {
      final p = UserProfile.fromSupabase(Map<String, dynamic>.from(row));
      if (p.id.isEmpty) return;
      _users[p.id] = p;
      if (p.id == _currentUser.id) {
        final authVerified =
            _client.auth.currentUser?.emailConfirmedAt != null;
        _currentUser = _currentUser.copyWith(
          firstName: p.firstName,
          phone: p.phone,
          wantsToWork: p.wantsToWork,
          preferredArea: p.preferredArea,
          rating: p.rating,
          ratingCount: p.ratingCount,
          isVerified: p.isVerified || authVerified,
        );
      }
      notifyListeners();
    } catch (e) {
      debugPrint('realtime profile upsert error: $e');
    }
  }

  Future<void> _teardownAllRealtime() async {
    final channels = [
      _jobsChannel,
      _chatChannel,
      _notificationsChannel,
      _profilesChannel,
    ];
    _jobsChannel = null;
    _chatChannel = null;
    _notificationsChannel = null;
    _profilesChannel = null;
    for (final c in channels) {
      if (c == null) continue;
      try {
        await _client.removeChannel(c);
      } catch (e) {
        debugPrint('realtime teardown error: $e');
      }
    }
  }

  @override
  void dispose() {
    _notifReloadTimer?.cancel();
    _notifReloadTimer = null;
    _teardownAllRealtime();
    super.dispose();
  }

  static const String _seedOwnerId = '00000000-0000-0000-0000-000000000001';
  static const String _seedWorkerId = '00000000-0000-0000-0000-000000000002';
  static const String _seedJobId = '00000000-0000-0000-0000-000000000010';

  void _seedUsers() {
    final now = DateTime.now();
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
      createdAt: now,
      isVerified: false,
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
      createdAt: now,
      isVerified: false,
    );
    _users[owner.id] = owner;
    _users[worker.id] = worker;
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

  double jobMarkerLat(Job job) {
    return job.lat + _hashOffset(job.id, 0x9E37) * _markerSpread;
  }

  double jobMarkerLng(Job job) {
    return job.lng + _hashOffset(job.id, 0x85EB) * _markerSpread;
  }

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
