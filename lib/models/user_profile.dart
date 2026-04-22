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
  final DateTime createdAt;
  final bool isVerified;

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
    required this.createdAt,
    required this.isVerified,
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
    DateTime? createdAt,
    bool? isVerified,
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
      createdAt: createdAt ?? this.createdAt,
      isVerified: isVerified ?? this.isVerified,
    );
  }

  // ---------------- SUPABASE ----------------

  factory UserProfile.fromSupabase(Map<String, dynamic> map) {
    return UserProfile(
      id: _toStringValue(map['id']),
      firstName: _toStringValue(map['first_name'], fallback: 'Bruker'),
      // Profiles-tabellen lagrer ikke e-post (ligger i auth.users).
      // Fallback til tom streng ved lesing av andres profiler.
      email: _toStringValue(map['email']),
      phone: _toStringValue(map['phone']),
      wantsToWork: _toBool(map['wants_to_work'], fallback: true),
      preferredArea: _toStringValue(map['preferred_area']),
      rating: _toDouble(map['rating'], fallback: 5.0),
      ratingCount: _toInt(map['rating_count']),
      pushNotificationsEnabled:
          _toBool(map['push_notifications_enabled'], fallback: true),
      createdAt: _toDateTime(map['created_at']) ?? DateTime.now(),
      isVerified: _toBool(map['is_verified']),
    );
  }

  /// Brukes ved `upsert` av egen profil. `id` må være satt til
  /// `auth.uid()` for at RLS skal tillate skrivingen.
  Map<String, dynamic> toSupabaseUpsert() {
    return {
      'id': id,
      'first_name': firstName,
      'phone': phone,
      'wants_to_work': wantsToWork,
      'preferred_area': preferredArea,
      'rating': rating,
      'rating_count': ratingCount,
      'push_notifications_enabled': pushNotificationsEnabled,
      'is_verified': isVerified,
    };
  }

  // ---------------- PARSERS ----------------

  static String _toStringValue(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    final text = value.toString();
    return text.isEmpty ? fallback : text;
  }

  static bool _toBool(dynamic value, {bool fallback = false}) {
    if (value is bool) return value;
    if (value == null) return fallback;
    final s = value.toString().toLowerCase().trim();
    if (s.isEmpty) return fallback;
    return s == 'true' || s == '1' || s == 't';
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _toDouble(dynamic value, {double fallback = 0.0}) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value.toLocal();
    final parsed = DateTime.tryParse(value.toString());
    return parsed?.toLocal();
  }
}
