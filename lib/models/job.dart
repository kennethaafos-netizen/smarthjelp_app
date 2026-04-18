// FIX: Added optional exactLat/exactLng fields so a job can carry a precise
// coordinate that is only revealed to the reserved worker (privacy-first
// location strategy). Existing fields, API, parsing, and UI are preserved.
// `lat` / `lng` remain the approximate (publicly shown) coordinate.

enum JobStatus {
  open,
  reserved,
  inProgress,
  completed,
}

/// Immutabel jobb-modell. Bruk [copyWith] for endringer – aldri direkte
/// mutasjon. Understøtter både Supabase (snake_case) og intern JSON.
class Job {
  final String id;
  final String title;
  final String description;
  final int price;
  final String locationName;
  final double lat;
  final double lng;
  final double? exactLat;
  final double? exactLng;
  final String category;
  final String? imageUrl;
  final String createdByUserId;
  final String? acceptedByUserId;
  final JobStatus status;
  final DateTime createdAt;
  final int viewCount;
  final DateTime? reservedAt;
  final bool isPaymentReserved;
  final bool isCompletedByWorker;
  final bool isApprovedByOwner;
  final String? cancelRequestedByUserId;

  const Job({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.locationName,
    required this.lat,
    required this.lng,
    required this.category,
    required this.createdByUserId,
    required this.status,
    required this.createdAt,
    this.exactLat,
    this.exactLng,
    this.imageUrl,
    this.acceptedByUserId,
    this.viewCount = 0,
    this.reservedAt,
    this.isPaymentReserved = false,
    this.isCompletedByWorker = false,
    this.isApprovedByOwner = false,
    this.cancelRequestedByUserId,
  });

  static const _sentinel = Object();

  // ---------------- COMPUTED ----------------

  DateTime? get reservedUntil {
    if (reservedAt == null) return null;
    return reservedAt!.add(const Duration(minutes: 10));
  }

  double get fee => price * 0.10;
  double get platformFee => fee;
  double get totalPrice => price + fee;
  double get payout => price.toDouble();

  bool get isOpen => status == JobStatus.open;
  bool get isReserved => status == JobStatus.reserved;
  bool get isInProgress => status == JobStatus.inProgress;
  bool get isFullyCompleted =>
      status == JobStatus.completed && isApprovedByOwner;

  bool get hasPendingCancelRequest => cancelRequestedByUserId != null;

  /// Om jobben har en eksakt posisjon som er forskjellig fra den
  /// omtrentlige. Brukes i fremtiden for å bytte mellom "bydel" og
  /// "nøyaktig adresse".
  bool get hasExactLocation => exactLat != null && exactLng != null;

  /// Beste kjente lat for reservert utfører. Faller tilbake til approx.
  double get visibleLatForReservedWorker => exactLat ?? lat;

  /// Beste kjente lng for reservert utfører. Faller tilbake til approx.
  double get visibleLngForReservedWorker => exactLng ?? lng;

  // ---------------- COPY ----------------

  Job copyWith({
    String? id,
    String? title,
    String? description,
    int? price,
    String? locationName,
    double? lat,
    double? lng,
    Object? exactLat = _sentinel,
    Object? exactLng = _sentinel,
    String? category,
    Object? imageUrl = _sentinel,
    String? createdByUserId,
    Object? acceptedByUserId = _sentinel,
    JobStatus? status,
    DateTime? createdAt,
    int? viewCount,
    Object? reservedAt = _sentinel,
    bool? isPaymentReserved,
    bool? isCompletedByWorker,
    bool? isApprovedByOwner,
    Object? cancelRequestedByUserId = _sentinel,
  }) {
    return Job(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      locationName: locationName ?? this.locationName,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      exactLat:
          exactLat == _sentinel ? this.exactLat : exactLat as double?,
      exactLng:
          exactLng == _sentinel ? this.exactLng : exactLng as double?,
      category: category ?? this.category,
      imageUrl: imageUrl == _sentinel ? this.imageUrl : imageUrl as String?,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      acceptedByUserId: acceptedByUserId == _sentinel
          ? this.acceptedByUserId
          : acceptedByUserId as String?,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      viewCount: viewCount ?? this.viewCount,
      reservedAt:
          reservedAt == _sentinel ? this.reservedAt : reservedAt as DateTime?,
      isPaymentReserved: isPaymentReserved ?? this.isPaymentReserved,
      isCompletedByWorker: isCompletedByWorker ?? this.isCompletedByWorker,
      isApprovedByOwner: isApprovedByOwner ?? this.isApprovedByOwner,
      cancelRequestedByUserId: cancelRequestedByUserId == _sentinel
          ? this.cancelRequestedByUserId
          : cancelRequestedByUserId as String?,
    );
  }

  // ---------------- SUPABASE / JSON ----------------

  factory Job.fromSupabase(Map<String, dynamic> map) {
    return Job(
      id: _toStringValue(map['id']),
      title: _toStringValue(map['title']),
      description: _toStringValue(map['description']),
      price: _toInt(map['price']),
      locationName: _toStringValue(map['location_name']),
      lat: _toDouble(map['lat']),
      lng: _toDouble(map['lng']),
      exactLat: _toNullableDouble(map['exact_lat']),
      exactLng: _toNullableDouble(map['exact_lng']),
      category: _toStringValue(map['category'], fallback: 'Annet'),
      imageUrl: _toNullableString(map['image_url']),
      createdByUserId: _toStringValue(map['created_by_user_id']),
      acceptedByUserId: _toNullableString(map['accepted_by_user_id']),
      status: _statusFromString(_toNullableString(map['status'])),
      createdAt: _toDateTime(map['created_at']) ?? DateTime.now(),
      viewCount: _toInt(map['view_count']),
      reservedAt: _toDateTime(map['reserved_at']),
      isPaymentReserved: _toBool(map['is_payment_reserved']),
      isCompletedByWorker: _toBool(map['is_completed_by_worker']),
      isApprovedByOwner: _toBool(map['is_approved_by_owner']),
      cancelRequestedByUserId:
          _toNullableString(map['cancel_requested_by_user_id']),
    );
  }

  factory Job.fromJson(Map<String, dynamic> json) {
    return Job.fromSupabase(json);
  }

  Map<String, dynamic> toSupabaseInsert() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'price': price,
      'location_name': locationName,
      'lat': lat,
      'lng': lng,
      'exact_lat': exactLat,
      'exact_lng': exactLng,
      'category': category,
      'image_url': imageUrl,
      'created_by_user_id': createdByUserId,
      'accepted_by_user_id': acceptedByUserId,
      'status': _statusToString(status),
      'created_at': createdAt.toIso8601String(),
      'view_count': viewCount,
      'reserved_at': reservedAt?.toIso8601String(),
      'is_payment_reserved': isPaymentReserved,
      'is_completed_by_worker': isCompletedByWorker,
      'is_approved_by_owner': isApprovedByOwner,
      'cancel_requested_by_user_id': cancelRequestedByUserId,
    };
  }

  Map<String, dynamic> toSupabaseUpdate() {
    return {
      'title': title,
      'description': description,
      'price': price,
      'location_name': locationName,
      'lat': lat,
      'lng': lng,
      'exact_lat': exactLat,
      'exact_lng': exactLng,
      'category': category,
      'image_url': imageUrl,
      'created_by_user_id': createdByUserId,
      'accepted_by_user_id': acceptedByUserId,
      'status': _statusToString(status),
      'created_at': createdAt.toIso8601String(),
      'view_count': viewCount,
      'reserved_at': reservedAt?.toIso8601String(),
      'is_payment_reserved': isPaymentReserved,
      'is_completed_by_worker': isCompletedByWorker,
      'is_approved_by_owner': isApprovedByOwner,
      'cancel_requested_by_user_id': cancelRequestedByUserId,
    };
  }

  // ---------------- EQUALITY ----------------

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Job && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  // ---------------- STATUS HELPERS ----------------

  static JobStatus _statusFromString(String? value) {
    switch (value) {
      case 'reserved':
        return JobStatus.reserved;
      case 'in_progress':
      case 'inProgress':
        return JobStatus.inProgress;
      case 'completed':
        return JobStatus.completed;
      case 'open':
      default:
        return JobStatus.open;
    }
  }

  static String _statusToString(JobStatus status) {
    switch (status) {
      case JobStatus.open:
        return 'open';
      case JobStatus.reserved:
        return 'reserved';
      case JobStatus.inProgress:
        return 'in_progress';
      case JobStatus.completed:
        return 'completed';
    }
  }

  // ---------------- PARSING HELPERS ----------------

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double? _toNullableDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static bool _toBool(dynamic value) {
    if (value is bool) return value;
    final normalized = value?.toString().toLowerCase().trim();
    return normalized == 'true' || normalized == '1' || normalized == 't';
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value.toLocal();

    final parsed = DateTime.tryParse(value.toString());
    return parsed?.toLocal();
  }

  static String _toStringValue(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    return value.toString();
  }

  static String? _toNullableString(dynamic value) {
    if (value == null) return null;
    final text = value.toString();
    return text.isEmpty ? null : text;
  }

  @override
  String toString() {
    return 'Job(id: $id, title: $title, status: $status, '
        'createdByUserId: $createdByUserId, '
        'acceptedByUserId: $acceptedByUserId, '
        'cancelRequestedByUserId: $cancelRequestedByUserId, '
        'hasExactLocation: $hasExactLocation)';
  }
}
