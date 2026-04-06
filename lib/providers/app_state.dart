import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/chat_message.dart';
import '../models/job.dart';
import '../models/user_profile.dart';

class AppState extends ChangeNotifier {
  final Uuid _uuid = const Uuid();

  late String _currentUserId;

  Map<String, UserProfile> _users = {};
  List<Job> _jobs = [];
  final List<ChatMessage> _messages = [];

  UserProfile get currentUser => _users[_currentUserId]!;

  List<Job> get jobs => List.unmodifiable(_jobs);

  AppState() {
    seedData();
  }

  // ================= SEED =================

  void seedData() {
    _users = {
      'user1': const UserProfile(
        id: 'user1',
        firstName: 'Kenneth',
        email: '',
        phone: '',
        wantsToWork: true,
        preferredArea: 'Skien',
        rating: 4.9,
        ratingCount: 12,
        pushNotificationsEnabled: true,
      ),
      'user2': const UserProfile(
        id: 'user2',
        firstName: 'Jan Erik',
        email: '',
        phone: '',
        wantsToWork: false,
        preferredArea: 'Skien',
        rating: 4.8,
        ratingCount: 23,
        pushNotificationsEnabled: true,
      ),
    };

    _currentUserId = 'user1';

    _jobs = [
      Job(
        id: _uuid.v4(),
        title: 'Flytte sofa',
        description: 'Trenger hjelp til å flytte sofa',
        price: 500,
        locationName: 'Skien',
        lat: 59.2094,
        lng: 9.6090,
        category: 'Flyttehjelp',
        imageUrl: null,
        createdByUserId: 'user2',
        acceptedByUserId: null,
        status: JobStatus.open,
        createdAt: DateTime.now(),
        viewCount: 10,
      ),
    ];
  }

  // ================= USERS =================

  UserProfile getJobOwner(Job job) => _users[job.createdByUserId]!;

  UserProfile? getUserById(String id) => _users[id];

  // ================= SORT / AI =================

  List<Job> get smartRankedJobs {
    if (!currentUser.wantsToWork) return [];

    final list = _jobs.where((j) => j.status == JobStatus.open).toList();

    list.sort((a, b) => _score(b).compareTo(_score(a)));

    return list;
  }

  double _score(Job j) {
    final views = j.viewCount * 1.2;
    final price = j.price * 0.02;
    final age = DateTime.now().difference(j.createdAt).inHours + 1;

    return views + price - (age * 0.5);
  }

  List<Job> get sortedOpenJobs =>
      _jobs.where((j) => j.status == JobStatus.open).toList();

  // ================= JOB LISTS =================

  List<Job> get activeTakenJobs =>
      _jobs.where((j) => j.acceptedByUserId == _currentUserId).toList();

  List<Job> get completedTakenJobs =>
      _jobs.where((j) => j.status == JobStatus.completed).toList();

  List<Job> get activePostedJobs =>
      _jobs.where((j) => j.createdByUserId == _currentUserId).toList();

  List<Job> get completedPostedJobs =>
      _jobs.where((j) => j.status == JobStatus.completed).toList();

  List<Job> get chatJobs => _jobs;

  // ================= STATS =================

  double get moneyEarned =>
      completedTakenJobs.fold(0, (sum, j) => sum + j.price).toDouble();

  double get moneySpent =>
      completedPostedJobs.fold(0, (sum, j) => sum + j.price).toDouble();

  // ================= RESERVE SYSTEM =================

  void reserveJob(String jobId) {
    _jobs = _jobs.map((j) {
      if (j.id == jobId && j.status == JobStatus.open) {
        return j.copyWith(
          status: JobStatus.reserved,
          acceptedByUserId: _currentUserId,
          reservedAt: DateTime.now(),
        );
      }
      return j;
    }).toList();

    notifyListeners();
  }

  void confirmJob(String jobId) {
    _jobs = _jobs.map((j) {
      if (j.id == jobId && j.status == JobStatus.reserved) {
        return j.copyWith(status: JobStatus.inProgress);
      }
      return j;
    }).toList();

    notifyListeners();
  }

  void releaseJob(String jobId) {
    _jobs = _jobs.map((j) {
      if (j.id == jobId && j.status == JobStatus.reserved) {
        return j.copyWith(
          status: JobStatus.open,
          acceptedByUserId: null,
          reservedAt: null,
        );
      }
      return j;
    }).toList();

    notifyListeners();
  }

  void checkExpiredReservations() {
    final now = DateTime.now();

    _jobs = _jobs.map((j) {
      if (j.status == JobStatus.reserved && j.reservedAt != null) {
        final diff = now.difference(j.reservedAt!);

        if (diff.inMinutes >= 10) {
          return j.copyWith(
            status: JobStatus.open,
            acceptedByUserId: null,
            reservedAt: null,
          );
        }
      }
      return j;
    }).toList();

    notifyListeners();
  }

  // ================= ACTIONS =================

  void addJob({
    required String title,
    required String description,
    required int price,
    required String locationName,
    required double lat,
    required double lng,
    required String category,
    String? imageUrl,
  }) {
    _jobs.insert(
      0,
      Job(
        id: _uuid.v4(),
        title: title,
        description: description,
        price: price,
        locationName: locationName,
        lat: lat,
        lng: lng,
        category: category,
        imageUrl: imageUrl,
        createdByUserId: _currentUserId,
        acceptedByUserId: null,
        status: JobStatus.open,
        createdAt: DateTime.now(),
      ),
    );

    notifyListeners();
  }

  void incrementView(String id) {
    _jobs = _jobs.map((j) {
      if (j.id == id) {
        return j.copyWith(viewCount: j.viewCount + 1);
      }
      return j;
    }).toList();

    notifyListeners();
  }

  void completeJob(String id) {
    _jobs = _jobs.map((j) {
      if (j.id == id) {
        return j.copyWith(status: JobStatus.completed);
      }
      return j;
    }).toList();

    notifyListeners();
  }

  void reopenJob(String id) {
    _jobs = _jobs.map((j) {
      if (j.id == id) {
        return j.copyWith(
          status: JobStatus.open,
          acceptedByUserId: null,
        );
      }
      return j;
    }).toList();

    notifyListeners();
  }

  // ================= PROFILE =================

  void updateProfile({
    required String firstName,
    required String email,
    required String phone,
    required bool wantsToWork,
    required String preferredArea,
  }) {
    _users[_currentUserId] = currentUser.copyWith(
      firstName: firstName,
      email: email,
      phone: phone,
      wantsToWork: wantsToWork,
      preferredArea: preferredArea,
    );

    // 🔥 ADDED: AUTO ENABLE PUSH IF USER WANTS WORK
    if (wantsToWork) {
      _users[_currentUserId] =
          _users[_currentUserId]!.copyWith(
        pushNotificationsEnabled: true,
      );
    }

    notifyListeners();
  }

  void setPushNotifications(bool enabled) {
    _users[_currentUserId] =
        currentUser.copyWith(pushNotificationsEnabled: enabled);

    notifyListeners();
  }

  // ================= CHAT =================

  List<ChatMessage> getMessagesForJob(String jobId) =>
      _messages.where((m) => m.jobId == jobId).toList();

  void sendMessage(String jobId, String text) {
    _messages.add(
      ChatMessage(
        id: _uuid.v4(),
        jobId: jobId,
        senderId: _currentUserId,
        text: text,
        createdAt: DateTime.now(),
      ),
    );

    notifyListeners();
  }

  // ================= RATING =================

  void rateUser({
    required String userId,
    required double newRating,
  }) {
    final user = _users[userId]!;

    final total = user.rating * user.ratingCount;
    final count = user.ratingCount + 1;

    _users[userId] = user.copyWith(
      rating: (total + newRating) / count,
      ratingCount: count,
    );

    notifyListeners();
  }
}