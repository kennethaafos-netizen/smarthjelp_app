import 'job.dart';

/// Sprint 6: sortering brukt av JobFilter. Holdes i egen enum (ikke
/// JobSortOption som finnes lokalt i jobs_screen.dart) for å unngå
/// navne-kollisjon når home_screen.dart importerer både denne fila og
/// jobs_screen.dart for JobsTab. Sprint 6.5 kan konsolidere ved å
/// bytte ut JobsScreens lokale enum med denne.
enum JobSortMode {
  newest,
  priceHighLow,
  priceLowHigh,
  nearest,
  popular,
}

extension JobSortModeLabel on JobSortMode {
  String get label {
    switch (this) {
      case JobSortMode.newest:
        return 'Nyeste';
      case JobSortMode.priceHighLow:
        return 'Pris høy → lav';
      case JobSortMode.priceLowHigh:
        return 'Pris lav → høy';
      case JobSortMode.nearest:
        return 'Nærmest';
      case JobSortMode.popular:
        return 'Mest vist';
    }
  }
}

/// Immutable verdiklasse som representerer søk + filter på HomeScreen
/// (og senere JobsScreen i Sprint 6.5). All UI-state for filter ligger
/// her — AppState forblir source of truth for selve job-listen.
///
/// Sentinel-mønster i copyWith for nullable felter (samme mønster som
/// Job/UserProfile) slik at man kan eksplisitt sette feltet til null
/// uten å treffe default-verdien.
class JobFilter {
  final Set<String> categories;
  final int? minPrice;
  final int? maxPrice;
  final double? radiusKm;
  final JobSortMode sort;
  final String query;

  const JobFilter({
    this.categories = const <String>{},
    this.minPrice,
    this.maxPrice,
    this.radiusKm,
    this.sort = JobSortMode.newest,
    this.query = '',
  });

  static const _sentinel = Object();

  /// True når søkefeltet har innhold (whitespace teller ikke).
  bool get hasQuery => query.trim().isNotEmpty;

  /// True når noe filter er aktivt utover default-sortering. Brukes
  /// til å vise/skjule active-filter-chips og styre bypass av
  /// smartRankedJobs.
  bool get isActive {
    return categories.isNotEmpty ||
        minPrice != null ||
        maxPrice != null ||
        radiusKm != null ||
        sort != JobSortMode.newest;
  }

  /// True når både filter og søk er tomme (ren tilstand).
  bool get isEmpty => !isActive && !hasQuery;

  JobFilter copyWith({
    Set<String>? categories,
    Object? minPrice = _sentinel,
    Object? maxPrice = _sentinel,
    Object? radiusKm = _sentinel,
    JobSortMode? sort,
    String? query,
  }) {
    return JobFilter(
      categories: categories ?? this.categories,
      minPrice:
          minPrice == _sentinel ? this.minPrice : minPrice as int?,
      maxPrice:
          maxPrice == _sentinel ? this.maxPrice : maxPrice as int?,
      radiusKm:
          radiusKm == _sentinel ? this.radiusKm : radiusKm as double?,
      sort: sort ?? this.sort,
      query: query ?? this.query,
    );
  }

  JobFilter cleared() => const JobFilter();

  /// Anvender filter + søk + sortering på en jobliste. Distanse-funksjonen
  /// injiseres så modellen ikke har avhengighet til AppState — det gjør den
  /// trivielt gjenbrukbar i JobsScreen (Sprint 6.5) eller i tester.
  ///
  /// Rekkefølge:
  ///   1. Søk (case-insensitive contains over title/desc/category/locName)
  ///   2. Kategori (multi, case-insensitive)
  ///   3. Min/maks pris
  ///   4. Radius (jobDistance ≤ radiusKm * 1000m)
  ///   5. Sortering
  List<Job> apply(
    List<Job> jobs, {
    required double Function(Job job) distanceMetersFor,
  }) {
    Iterable<Job> result = jobs;

    if (hasQuery) {
      final needle = query.trim().toLowerCase();
      result = result.where((j) {
        return j.title.toLowerCase().contains(needle) ||
            j.description.toLowerCase().contains(needle) ||
            j.category.toLowerCase().contains(needle) ||
            j.locationName.toLowerCase().contains(needle);
      });
    }

    if (categories.isNotEmpty) {
      final lower = categories.map((c) => c.toLowerCase()).toSet();
      result =
          result.where((j) => lower.contains(j.category.toLowerCase()));
    }

    if (minPrice != null) {
      final m = minPrice!;
      result = result.where((j) => j.price >= m);
    }
    if (maxPrice != null) {
      final m = maxPrice!;
      result = result.where((j) => j.price <= m);
    }

    if (radiusKm != null) {
      final maxMeters = radiusKm! * 1000.0;
      result = result.where((j) => distanceMetersFor(j) <= maxMeters);
    }

    final list = result.toList();
    switch (sort) {
      case JobSortMode.newest:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case JobSortMode.priceHighLow:
        list.sort((a, b) => b.price.compareTo(a.price));
        break;
      case JobSortMode.priceLowHigh:
        list.sort((a, b) => a.price.compareTo(b.price));
        break;
      case JobSortMode.nearest:
        list.sort((a, b) =>
            distanceMetersFor(a).compareTo(distanceMetersFor(b)));
        break;
      case JobSortMode.popular:
        list.sort((a, b) => b.viewCount.compareTo(a.viewCount));
        break;
    }
    return list;
  }
}