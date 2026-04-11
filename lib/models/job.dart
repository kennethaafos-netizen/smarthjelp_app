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
    this.imageUrl,
    this.acceptedByUserId,
    this.viewCount = 0,
    this.reservedAt,
    this.isPaymentReserved = false,
    this.isCompletedByWorker = false,
    this.isApprovedByOwner = false,
    this.cancelRequestedByUserId,
  });

  DateTime? get reservedUntil {
    if (reservedAt == null) return null;
    return reservedAt!.add(const Duration(minutes: 10));
  }

  double get fee => price * 0.10;
  double get totalPrice => price + fee;
  double get payout => price.toDouble();

  Job copyWith({
    String? id,
    String? title,
    String? description,
    int? price,
    String? locationName,
    double? lat,
    double? lng,
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
      isCompletedByWorker:
          isCompletedByWorker ?? this.isCompletedByWorker,
      isApprovedByOwner: isApprovedByOwner ?? this.isApprovedByOwner,
      cancelRequestedByUserId:
          cancelRequestedByUserId == _sentinel
              ? this.cancelRequestedByUserId
              : cancelRequestedByUserId as String?,
    );
  }

  static const _sentinel = Object();
}