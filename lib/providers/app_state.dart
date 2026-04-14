import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/chat_message.dart';
import '../models/job.dart';
import '../models/user_profile.dart';

enum TaxTransactionType {
  income,
  expense,
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

  String get typeLabel {
    switch (type) {
      case TaxTransactionType.income:
        return 'Inntekt';
      case TaxTransactionType.expense:
        return 'Kostnad';
    }
  }

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

  List<TaxReportEntry> get incomeEntries =>
      entries.where((e) => e.type == TaxTransactionType.income).toList();

  List<TaxReportEntry> get expenseEntries =>
      entries.where((e) => e.type == TaxTransactionType.expense).toList();
}

class AppState extends ChangeNotifier {
  final Uuid _uuid = const Uuid();

  late UserProfile _currentUser;

  final Map<String, UserProfile> _users = {};
  List<Job> _jobs = [];
  final List<ChatMessage> _messages = [];

  AppState() {
    _seed();
  }

  UserProfile get currentUser => _currentUser;

  List<Job> get jobs => List.unmodifiable(_jobs);

  UserProfile? getUserById(String id) => _users[id];

  UserProfile getJobOwner(Job job) =>
      _users[job.createdByUserId] ?? _currentUser;

  void switchUser() {
    final ids = _users.keys.toList();
    if (ids.length < 2) return;

    final currentIndex = ids.indexOf(_currentUser.id);
    final nextIndex = (currentIndex + 1) % ids.length;
    _currentUser = _users[ids[nextIndex]]!;
    notifyListeners();
  }

  List<Job> get smartRankedJobs {
    final list = _jobs.where((j) => j.status == JobStatus.open).toList();

    list.sort((a, b) {
      final aFresh =
          DateTime.now().difference(a.createdAt).inHours < 24 ? 10 : 0;
      final bFresh =
          DateTime.now().difference(b.createdAt).inHours < 24 ? 10 : 0;

      final aScore = a.viewCount + aFresh;
      final bScore = b.viewCount + bFresh;
      return bScore.compareTo(aScore);
    });

    return list;
  }

  List<Job> get sortedOpenJobs {
    final list = _jobs.where((j) => j.status == JobStatus.open).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  List<Job> get chatJobs => _jobs
      .where(
        (j) =>
            j.createdByUserId == _currentUser.id ||
            j.acceptedByUserId == _currentUser.id,
      )
      .toList();

  List<Job> get activeTakenJobs => _jobs
      .where(
        (j) =>
            j.acceptedByUserId == _currentUser.id &&
            j.status != JobStatus.completed,
      )
      .toList();

  List<Job> get completedTakenJobs => _jobs
      .where(
        (j) =>
            j.acceptedByUserId == _currentUser.id &&
            j.status == JobStatus.completed,
      )
      .toList();

  List<Job> get activePostedJobs => _jobs
      .where(
        (j) =>
            j.createdByUserId == _currentUser.id &&
            j.status != JobStatus.completed,
      )
      .toList();

  List<Job> get completedPostedJobs => _jobs
      .where(
        (j) =>
            j.createdByUserId == _currentUser.id &&
            j.status == JobStatus.completed,
      )
      .toList();

  double get moneyEarned =>
      completedTakenJobs.fold(0, (sum, job) => sum + job.payout);

  double get moneySpent =>
      completedPostedJobs.fold(0, (sum, job) => sum + job.totalPrice);

  List<int> get availableTaxReportYears {
    final years = <int>{
      DateTime.now().year,
      ...completedTakenJobs.map((j) => j.createdAt.year),
      ...completedPostedJobs.map((j) => j.createdAt.year),
    }.toList();

    years.sort((a, b) => b.compareTo(a));
    return years;
  }

  TaxReportSummary buildTaxReportForYear(int year) {
    final incomeEntries = completedTakenJobs
        .where((job) => job.createdAt.year == year)
        .map(
          (job) => TaxReportEntry(
            id: 'income_${job.id}',
            type: TaxTransactionType.income,
            date: job.createdAt,
            jobTitle: job.title,
            category: job.category,
            locationName: job.locationName,
            amount: job.payout,
            sourceJobId: job.id,
          ),
        )
        .toList();

    final expenseEntries = completedPostedJobs
        .where((job) => job.createdAt.year == year)
        .map(
          (job) => TaxReportEntry(
            id: 'expense_${job.id}',
            type: TaxTransactionType.expense,
            date: job.createdAt,
            jobTitle: job.title,
            category: job.category,
            locationName: job.locationName,
            amount: job.totalPrice,
            sourceJobId: job.id,
          ),
        )
        .toList();

    final entries = <TaxReportEntry>[
      ...incomeEntries,
      ...expenseEntries,
    ]..sort((a, b) => b.date.compareTo(a.date));

    final totalIncome =
        incomeEntries.fold<double>(0, (sum, entry) => sum + entry.amount);

    final totalExpenses =
        expenseEntries.fold<double>(0, (sum, entry) => sum + entry.amount);

    return TaxReportSummary(
      year: year,
      entries: entries,
      totalIncome: totalIncome,
      totalExpenses: totalExpenses,
    );
  }

  void _replaceJob(Job updated) {
    final index = _jobs.indexWhere((j) => j.id == updated.id);
    if (index == -1) return;

    _jobs[index] = updated;
    notifyListeners();
  }

  void addJob({
    required String title,
    required String description,
    required int price,
    required String category,
    required String locationName,
    required double lat,
    required double lng,
    String? imageUrl,
  }) {
    final job = Job(
      id: _uuid.v4(),
      title: title.trim(),
      description: description.trim(),
      price: price,
      locationName: locationName,
      lat: lat,
      lng: lng,
      category: category,
      imageUrl: imageUrl,
      createdByUserId: _currentUser.id,
      acceptedByUserId: null,
      status: JobStatus.open,
      createdAt: DateTime.now(),
      viewCount: 0,
      reservedAt: null,
      isPaymentReserved: false,
      isCompletedByWorker: false,
      isApprovedByOwner: false,
      cancelRequestedByUserId: null,
    );

    _jobs.insert(0, job);
    notifyListeners();
  }

  void reserveJob(String id) {
    final job = _jobs.firstWhere((e) => e.id == id);
    if (job.status != JobStatus.open) return;

    _replaceJob(
      job.copyWith(
        status: JobStatus.reserved,
        acceptedByUserId: _currentUser.id,
        reservedAt: DateTime.now(),
        isPaymentReserved: false,
        isCompletedByWorker: false,
        isApprovedByOwner: false,
        cancelRequestedByUserId: null,
      ),
    );
  }

  void releaseJob(String id) {
    final job = _jobs.firstWhere((e) => e.id == id);

    _replaceJob(
      job.copyWith(
        status: JobStatus.open,
        acceptedByUserId: null,
        reservedAt: null,
        isPaymentReserved: false,
        isCompletedByWorker: false,
        isApprovedByOwner: false,
        cancelRequestedByUserId: null,
      ),
    );
  }

  void expireReservation(String id) {
    final index = _jobs.indexWhere((j) => j.id == id);
    if (index == -1) return;

    final job = _jobs[index];

    if (job.status != JobStatus.reserved) return;

    _jobs[index] = job.copyWith(
      status: JobStatus.open,
      acceptedByUserId: null,
      reservedAt: null,
      isPaymentReserved: false,
      isCompletedByWorker: false,
      isApprovedByOwner: false,
      cancelRequestedByUserId: null,
    );

    _systemMessage(id, 'Reservasjonen utløp automatisk.');
    notifyListeners();
  }

  void startJob(String id) {
    final job = _jobs.firstWhere((e) => e.id == id);

    _replaceJob(
      job.copyWith(
        status: JobStatus.inProgress,
        isPaymentReserved: true,
      ),
    );
  }

  void completeJobByWorker(String id) {
    final job = _jobs.firstWhere((e) => e.id == id);

    _replaceJob(
      job.copyWith(
        isCompletedByWorker: true,
      ),
    );
  }

  void approveAndReleasePayment(String id) {
    final job = _jobs.firstWhere((e) => e.id == id);

    _replaceJob(
      job.copyWith(
        isApprovedByOwner: true,
        status: JobStatus.completed,
      ),
    );
  }

  void completeJob(String id) {
    final job = _jobs.firstWhere((e) => e.id == id);

    _replaceJob(
      job.copyWith(
        status: JobStatus.completed,
      ),
    );
  }

  void incrementView(String id) {
    final job = _jobs.firstWhere((e) => e.id == id);

    _replaceJob(
      job.copyWith(
        viewCount: job.viewCount + 1,
      ),
    );
  }

  void requestCancel(String id) {
    final job = _jobs.firstWhere((e) => e.id == id);

    if (!job.isPaymentReserved) {
      _replaceJob(
        job.copyWith(
          status: JobStatus.open,
          acceptedByUserId: null,
          reservedAt: null,
          isCompletedByWorker: false,
          isApprovedByOwner: false,
          cancelRequestedByUserId: null,
        ),
      );
      _systemMessage(id, 'Oppdrag ble avbrutt.');
      return;
    }

    if (job.cancelRequestedByUserId == null) {
      _replaceJob(
        job.copyWith(
          cancelRequestedByUserId: _currentUser.id,
        ),
      );
      _systemMessage(id, 'Avbrytelse forespurt. Begge må godkjenne.');
    }
  }

  void approveCancel(String id) {
    final job = _jobs.firstWhere((e) => e.id == id);
    if (job.cancelRequestedByUserId == null) return;
    if (job.cancelRequestedByUserId == _currentUser.id) return;

    _replaceJob(
      job.copyWith(
        status: JobStatus.open,
        acceptedByUserId: null,
        reservedAt: null,
        isPaymentReserved: false,
        isCompletedByWorker: false,
        isApprovedByOwner: false,
        cancelRequestedByUserId: null,
      ),
    );
    _systemMessage(id, 'Oppdrag avbrutt av begge parter.');
  }

  void cancelJob(String id) {
    requestCancel(id);
  }

  List<ChatMessage> getMessagesForJob(String jobId) {
    final list = _messages.where((m) => m.jobId == jobId).toList();
    list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return list;
  }

  void sendMessage(
    String jobId,
    String text, {
    ChatMessage? replyTo,
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
        replyToMessageId: replyTo?.id,
        replyToText: replyTo?.text,
        imageUrl: imageUrl,
      ),
    );
    notifyListeners();
  }

  void toggleReaction(String messageId, String reaction) {
    final index = _messages.indexWhere((m) => m.id == messageId);
    if (index == -1) return;

    final current = _messages[index];
    final nextReaction = current.reaction == reaction ? null : reaction;

    _messages[index] = current.copyWith(reaction: nextReaction);
    notifyListeners();
  }

  void _systemMessage(String jobId, String text) {
    _messages.add(
      ChatMessage(
        id: _uuid.v4(),
        jobId: jobId,
        senderId: 'system',
        text: text,
        createdAt: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  void setPushNotifications(bool value) {
    _currentUser = _currentUser.copyWith(
      pushNotificationsEnabled: value,
    );
    _users[_currentUser.id] = _currentUser;
    notifyListeners();
  }

  void updateProfile({
    required String firstName,
    String? email,
    String? phone,
    bool? wantsToWork,
    String? preferredArea,
  }) {
    _currentUser = _currentUser.copyWith(
      firstName: firstName,
      email: email ?? _currentUser.email,
      phone: phone ?? _currentUser.phone,
      wantsToWork: wantsToWork ?? _currentUser.wantsToWork,
      preferredArea: preferredArea ?? _currentUser.preferredArea,
    );
    _users[_currentUser.id] = _currentUser;
    notifyListeners();
  }

  void rateUser({
    required String userId,
    required double newRating,
  }) {
    final user = _users[userId];
    if (user == null) return;

    final total = (user.rating * user.ratingCount) + newRating;
    final count = user.ratingCount + 1;

    _users[userId] = user.copyWith(
      rating: total / count,
      ratingCount: count,
    );
    notifyListeners();
  }

  void checkExpiredReservations() {
    final now = DateTime.now();
    bool changed = false;

    _jobs = _jobs.map((job) {
      if (job.status == JobStatus.reserved &&
          job.reservedUntil != null &&
          now.isAfter(job.reservedUntil!)) {
        changed = true;
        return job.copyWith(
          status: JobStatus.open,
          acceptedByUserId: null,
          reservedAt: null,
          isPaymentReserved: false,
          isCompletedByWorker: false,
          isApprovedByOwner: false,
          cancelRequestedByUserId: null,
        );
      }
      return job;
    }).toList();

    if (changed) {
      notifyListeners();
    }
  }

  void _seed() {
    final owner = UserProfile(
      id: 'u1',
      firstName: 'Anders',
      email: 'anders@smarthjelp.test',
      phone: '90000001',
      wantsToWork: false,
      preferredArea: 'Skien',
      rating: 4.8,
      ratingCount: 12,
      pushNotificationsEnabled: true,
    );

    final worker = UserProfile(
      id: 'u2',
      firstName: 'Kenneth',
      email: 'kenneth@smarthjelp.test',
      phone: '90000002',
      wantsToWork: true,
      preferredArea: 'Skien',
      rating: 5.0,
      ratingCount: 1,
      pushNotificationsEnabled: true,
    );

    _users[owner.id] = owner;
    _users[worker.id] = worker;
    _currentUser = worker;

    _jobs = [
      Job(
        id: 'j1',
        title: 'Bære ved',
        description: 'Trenger hjelp til å bære ved.',
        price: 300,
        category: 'Hage',
        locationName: 'Skien',
        lat: 59.14,
        lng: 9.65,
        createdByUserId: owner.id,
        acceptedByUserId: null,
        status: JobStatus.open,
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        viewCount: 6,
      ),
      Job(
        id: 'j2',
        title: 'Male vegg',
        description: 'Lite rom, maling tilgjengelig.',
        price: 900,
        category: 'Maling',
        locationName: 'Porsgrunn',
        lat: 59.13,
        lng: 9.64,
        createdByUserId: owner.id,
        acceptedByUserId: worker.id,
        status: JobStatus.reserved,
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        viewCount: 9,
        reservedAt: DateTime.now().subtract(const Duration(minutes: 2)),
      ),
      Job(
        id: 'j3',
        title: 'Flytte sofa',
        description: 'Bære sofa opp i 2. etasje.',
        price: 500,
        category: 'Flytting',
        locationName: 'Skien',
        lat: 59.15,
        lng: 9.63,
        createdByUserId: owner.id,
        acceptedByUserId: worker.id,
        status: JobStatus.inProgress,
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        viewCount: 12,
        reservedAt: DateTime.now().subtract(const Duration(minutes: 25)),
        isPaymentReserved: true,
      ),
      Job(
        id: 'j4',
        title: 'Klippe plen',
        description: 'Jobben er ferdig og godkjent.',
        price: 400,
        category: 'Hage',
        locationName: 'Bamble',
        lat: 59.02,
        lng: 9.71,
        createdByUserId: owner.id,
        acceptedByUserId: worker.id,
        status: JobStatus.completed,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        viewCount: 20,
        reservedAt: DateTime.now().subtract(const Duration(days: 1)),
        isPaymentReserved: true,
        isCompletedByWorker: true,
        isApprovedByOwner: true,
      ),
    ];

    _messages.addAll([
      ChatMessage(
        id: _uuid.v4(),
        jobId: 'j3',
        senderId: owner.id,
        text: 'Hei! Når kan du komme?',
        createdAt: DateTime.now().subtract(const Duration(minutes: 12)),
      ),
      ChatMessage(
        id: _uuid.v4(),
        jobId: 'j3',
        senderId: worker.id,
        text: 'Jeg er der om ca 20 min 👍',
        createdAt: DateTime.now().subtract(const Duration(minutes: 8)),
      ),
      ChatMessage(
        id: _uuid.v4(),
        jobId: 'j2',
        senderId: owner.id,
        text: 'Passer det i kveld?',
        createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
      ),
      ChatMessage(
        id: _uuid.v4(),
        jobId: 'j2',
        senderId: worker.id,
        text: 'Ja, det passer fint.',
        createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
      ),
    ]);
  }
}