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

  const UserProfile({
    required this.id,
    required this.firstName,
    required this.email,
    required this.phone,
    required this.wantsToWork,
    required this.preferredArea,
    this.rating = 5.0,
    this.ratingCount = 0,
    this.pushNotificationsEnabled = true,
  });

  UserProfile copyWith({
    String? firstName,
    String? email,
    String? phone,
    bool? wantsToWork,
    String? preferredArea,
    double? rating,
    int? ratingCount,
    bool? pushNotificationsEnabled,
  }) {
    return UserProfile(
      id: id,
      firstName: firstName ?? this.firstName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      wantsToWork: wantsToWork ?? this.wantsToWork,
      preferredArea: preferredArea ?? this.preferredArea,
      rating: rating ?? this.rating,
      ratingCount: ratingCount ?? this.ratingCount,
      pushNotificationsEnabled:
          pushNotificationsEnabled ?? this.pushNotificationsEnabled,
    );
  }
}