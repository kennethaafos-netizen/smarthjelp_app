import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../models/job.dart';
import '../providers/app_state.dart';
import '../widgets/job_card.dart';
import 'job_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  final Function(int)? onNavigate;

  const HomeScreen({super.key, this.onNavigate});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showMap = true;
  Job? _selectedJob;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().ensureJobsLoaded();
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final jobs = appState.smartRankedJobs;
    final markers = _buildMarkers(jobs);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      body: SafeArea(
        child: Column(
          children: [
            _header(context, jobs),
            if (appState.jobsError != null) _statusBanner(appState.jobsError!),
            const SizedBox(height: 10),
            _toggle(),
            const SizedBox(height: 10),
            Expanded(
              child: appState.isLoadingJobs && !appState.hasLoadedJobs
                  ? const Center(child: CircularProgressIndicator())
                  : jobs.isEmpty
                      ? _emptyState()
                      : AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: _showMap
                              ? _mapView(jobs, markers)
                              : _listView(jobs),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context, List<Job> jobs) {
    final user = context.read<AppState>().currentUser;
    final nearbyCount = jobs.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Hei ${user.firstName} 👋',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => widget.onNavigate?.call(4),
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.person_outline),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => setState(() => _showMap = false),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2356E8), Color(0xFF18B7A6)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_fire_department, color: Colors.white),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '$nearbyCount oppdrag i nærheten av deg',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.white),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBanner(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF4E5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: Color(0xFFB26A00)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: Color(0xFF8A5600),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _toggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            _toggleBtn('Kart', _showMap, () {
              setState(() => _showMap = true);
            }),
            _toggleBtn('Liste', !_showMap, () {
              setState(() => _showMap = false);
            }),
          ],
        ),
      ),
    );
  }

  Widget _toggleBtn(String text, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? const Color(0xFF2356E8) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: active ? Colors.white : Colors.grey,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _mapView(List<Job> jobs, Set<Marker> markers) {
    return Stack(
      key: const ValueKey('map_view'),
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: LatLng(59.14, 9.65),
                zoom: 11,
              ),
              markers: markers,
              myLocationButtonEnabled: true,
              zoomControlsEnabled: true,
              onTap: (_) => setState(() => _selectedJob = null),
            ),
          ),
        ),
        if (_selectedJob != null)
          Positioned(
            left: 20,
            right: 20,
            bottom: 20,
            child: JobCard(
              job: _selectedJob!,
              distanceText: _selectedJob!.locationName,
              onTap: () => _openJob(_selectedJob!),
              onTake: _selectedJob!.status == JobStatus.open
                  ? () async {
                      await _takeJobAndOpen(_selectedJob!.id);
                    }
                  : null,
            ),
          ),
      ],
    );
  }

  Set<Marker> _buildMarkers(List<Job> jobs) {
    return jobs.map((job) {
      return Marker(
        markerId: MarkerId(job.id),
        position: LatLng(job.lat, job.lng),
        infoWindow: InfoWindow(
          title: '${job.title} • ${job.price} kr',
          snippet: '${job.category} • ${job.locationName}',
        ),
        onTap: () {
          setState(() {
            _selectedJob = job;
          });
        },
      );
    }).toSet();
  }

  Widget _listView(List<Job> jobs) {
    final trending = [...jobs]
      ..sort((a, b) => b.viewCount.compareTo(a.viewCount));

    return ListView(
      key: const ValueKey('list_view'),
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          '🔥 Trending',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 190,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: trending.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final job = trending[i];

              return GestureDetector(
                onTap: () => _openJob(job),
                child: Container(
                  width: 240,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.title,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        job.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${job.price} kr'),
                          if (job.status == JobStatus.open)
                            ElevatedButton(
                              onPressed: () async {
                                await _takeJobAndOpen(job.id);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2356E8),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                minimumSize: const Size(0, 40),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Ta jobb',
                                style: TextStyle(fontSize: 14),
                              ),
                            )
                          else
                            _statusPill(job),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          '📍 Alle oppdrag',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        const SizedBox(height: 10),
        ...jobs.map(
          (job) => JobCard(
            job: job,
            distanceText: job.locationName,
            onTap: () => _openJob(job),
            onTake: job.status == JobStatus.open
                ? () async {
                    await _takeJobAndOpen(job.id);
                  }
                : null,
          ),
        ),
      ],
    );
  }

  Widget _statusPill(Job job) {
    String text;
    Color bg;
    Color fg;

    switch (job.status) {
      case JobStatus.reserved:
        text = 'Reservert';
        bg = const Color(0xFFFFF4E5);
        fg = const Color(0xFFB26A00);
        break;
      case JobStatus.inProgress:
        text = 'Pågår';
        bg = const Color(0xFFEAF2FF);
        fg = const Color(0xFF2356E8);
        break;
      case JobStatus.completed:
        text = 'Fullført';
        bg = const Color(0xFFE9F8EF);
        fg = const Color(0xFF1F8B4C);
        break;
      case JobStatus.open:
        text = 'Ta jobb';
        bg = const Color(0xFF2356E8);
        fg = Colors.white;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fg,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.work_outline_rounded,
              size: 56,
              color: Color(0xFF2356E8),
            ),
            const SizedBox(height: 12),
            const Text(
              'Ingen oppdrag enda',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF172033),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Når det kommer jobber fra Supabase, dukker de opp her automatisk.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF6E7A90),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => widget.onNavigate?.call(2),
              child: const Text('Legg ut jobb'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _takeJobAndOpen(String jobId) async {
    await context.read<AppState>().reserveJob(jobId);

    if (!mounted) return;

    final updatedJob = context.read<AppState>().getJobById(jobId);
    if (updatedJob == null) return;

    _openJob(updatedJob);
  }

  void _openJob(Job job) {
    context.read<AppState>().incrementView(job.id);

    final latestJob = context.read<AppState>().getJobById(job.id) ?? job;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => JobDetailScreen(job: latestJob),
      ),
    );
  }
}