// lib/screens/home_screen.dart
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
  Set<Marker> _markers = {};
  bool _isTakingJob = false;

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

    _buildMarkers(jobs, appState);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      body: SafeArea(
        child: Column(
          children: [
            _header(context, jobs),
            const SizedBox(height: 10),
            _toggle(),
            const SizedBox(height: 10),

            // 🔥 KART / LISTE
            Expanded(
              child: _showMap ? _mapView(jobs, appState) : _listView(jobs, appState),
            ),

            // 🔥 OPPDRAGSKORT UTENFOR MAP (VIKTIG)
            if (_selectedJob != null)
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: JobCard(
                    job: _selectedJob!,
                    distanceText: appState.jobLocationLabel(_selectedJob!),
                    onTap: () => _openJob(_selectedJob!),
                    onTake: (_selectedJob!.status == JobStatus.open &&
                           _selectedJob!.createdByUserId !=
                               context.read<AppState>().currentUser.id)
                        ? () => _takeAndOpen(_selectedJob!)
                        : null,
                    
                  ),
                ),
              ),

            if (_isTakingJob)
              const Padding(
                padding: EdgeInsets.only(bottom: 20),
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }

  // ---------------- MAP ----------------

  Widget _mapView(List<Job> jobs, AppState appState) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: GoogleMap(
          initialCameraPosition: const CameraPosition(
            target: LatLng(59.14, 9.65),
            zoom: 11,
          ),
          markers: _markers,
          myLocationButtonEnabled: true,
          zoomControlsEnabled: true,
          onTap: (_) => setState(() => _selectedJob = null),
        ),
      ),
    );
  }

  void _buildMarkers(List<Job> jobs, AppState appState) {
    _markers = jobs.map((job) {
      return Marker(
        markerId: MarkerId(job.id),
        position: LatLng(
          appState.jobMarkerLat(job),
          appState.jobMarkerLng(job),
        ),
        onTap: () {
          final fresh =
              context.read<AppState>().getJobById(job.id) ?? job;

          setState(() => _selectedJob = fresh);
        },
      );
    }).toSet();
  }

  // ---------------- LIST ----------------

  Widget _listView(List<Job> jobs, AppState appState) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: jobs
          .map(
            (job) => JobCard(
              job: job,
              distanceText: appState.jobLocationLabel(job),
              onTap: () => _openJob(job),
              onTake: job.status == JobStatus.open
                  ? () => _takeAndOpen(job)
                  : null,
            ),
          )
          .toList(),
    );
  }

  // ---------------- ACTIONS ----------------

  Future<void> _takeAndOpen(Job job) async {
    if (_isTakingJob) return;

    final appState = context.read<AppState>();

    setState(() => _isTakingJob = true);

    final ok = await appState.reserveJob(job.id);

    if (!mounted) return;

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kunne ikke ta oppdrag')),
      );
      setState(() => _isTakingJob = false);
      return;
    }

    final updated = appState.getJobById(job.id);

    if (updated != null) {
      _openJob(updated);
    }

    setState(() => _isTakingJob = false);
  }

  void _openJob(Job job) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => JobDetailScreen(job: job),
      ),
    );
  }

  // ---------------- UI ----------------

  Widget _header(BuildContext context, List<Job> jobs) {
    final user = context.read<AppState>().currentUser;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Hei ${user.firstName}',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _CounterButton(
            count: jobs.length,
            onTap: () => setState(() => _showMap = false),
          ),
        ],
      ),
    );
  }

  Widget _toggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton(
          onPressed: () => setState(() => _showMap = true),
          child: const Text('Kart'),
        ),
        TextButton(
          onPressed: () => setState(() => _showMap = false),
          child: const Text('Liste'),
        ),
      ],
    );
  }
}

// 🔥 Animated clickable counter (ripple + scale on press)
class _CounterButton extends StatefulWidget {
  final int count;
  final VoidCallback onTap;

  const _CounterButton({
    required this.count,
    required this.onTap,
  });

  @override
  State<_CounterButton> createState() => _CounterButtonState();
}

class _CounterButtonState extends State<_CounterButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 0.94 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: Material(
        color: const Color(0xFF2356E8).withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: widget.onTap,
          onHighlightChanged: (v) => setState(() => _pressed = v),
          splashColor: const Color(0xFF2356E8).withOpacity(0.18),
          highlightColor: const Color(0xFF2356E8).withOpacity(0.08),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.work_outline,
                  size: 16,
                  color: Color(0xFF2356E8),
                ),
                const SizedBox(width: 6),
                Text(
                  '${widget.count} oppdrag',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: Color(0xFF2356E8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
