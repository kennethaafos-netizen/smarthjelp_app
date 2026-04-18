// FIX: Added preferredCategories to support future push-notification matching.
// Existing fields, constructor signature, and copyWith semantics preserved.

class UserProfile {
  final String id;
  final String firstName;
  final String email;
  final String phone;
  final bool wantsToWork;
  final String preferredArea;
  final double rating;
  final int ratingCount;
  final bool pushNotificationsEnabled;
  final List<String> preferredCategories;

  const UserProfile({
    required this.id,
    required this.firstName,
    required this.email,
    required this.phone,
    required this.wantsToWork,
    required this.preferredArea,
    required this.rating,
    required this.ratingCount,
    required this.pushNotificationsEnabled,
    this.preferredCategories = const [],
  });

  UserProfile copyWith({
    String? id,
    String? firstName,
    String? email,
    String? phone,
    bool? wantsToWork,
    String? preferredArea,
    double? rating,
    int? ratingCount,
    bool? pushNotificationsEnabled,
    List<String>? preferredCategories,
  }) {
    return UserProfile(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      wantsToWork: wantsToWork ?? this.wantsToWork,
      preferredArea: preferredArea ?? this.preferredArea,
      rating: rating ?? this.rating,
      ratingCount: ratingCount ?? this.ratingCount,
      pushNotificationsEnabled:
          pushNotificationsEnabled ?? this.pushNotificationsEnabled,
      preferredCategories: preferredCategories ?? this.preferredCategories,
    );
  }
}
