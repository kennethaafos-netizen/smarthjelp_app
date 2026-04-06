enum JobStatus {
  open,
  reserved,
  inProgress,
  completed,
}

class Job {
  final String id;
  final String title;
  final String description;
  final int price;

  final String locationName;
  final double lat;
  final double lng;

  final String category;
  final String? imageUrl;

  final String createdByUserId;
  final String? acceptedByUserId;

  final JobStatus status;
  final DateTime createdAt;

  final int viewCount;

  final DateTime? reservedAt;

  const Job({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.locationName,
    required this.lat,
    required this.lng,
    required this.category,
    this.imageUrl,
    required this.createdByUserId,
    this.acceptedByUserId,
    required this.status,
    required this.createdAt,
    this.viewCount = 0,
    this.reservedAt,
  });

  // 🔥 AUTO CALCULATED TIMER (DET DU MANGLER)
  DateTime? get reservedUntil {
    if (reservedAt == null) return null;
    return reservedAt!.add(const Duration(minutes: 10));
  }

  Job copyWith({
    String? title,
    String? description,
    int? price,
    String? locationName,
    double? lat,
    double? lng,
    String? category,
    String? imageUrl,

    Object? acceptedByUserId = _noChange,
    JobStatus? status,
    int? viewCount,
    DateTime? reservedAt,
  }) {
    return Job(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      locationName: locationName ?? this.locationName,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      createdByUserId: createdByUserId,
      acceptedByUserId: acceptedByUserId == _noChange
          ? this.acceptedByUserId
          : acceptedByUserId as String?,
      status: status ?? this.status,
      createdAt: createdAt,
      viewCount: viewCount ?? this.viewCount,
      reservedAt: reservedAt ?? this.reservedAt,
    );
  }

  static const _noChange = Object();
}