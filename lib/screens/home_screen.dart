import 'dart:math' as math;
import 'dart:ui' as ui;

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
  GoogleMapController? _mapController;

  bool _showMap = true;
  double _zoom = 11.0;
  int _lastRenderedZoomBucket = -1;

  Set<Marker> _markers = <Marker>{};
  Set<Circle> _heatmap = <Circle>{};
  Set<Marker> _nextMarkers = <Marker>{};

  Job? _selectedJob;

  String _renderSignature = '';
  bool _isAnimating = false;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    appState.checkExpiredReservations();

    final jobs = appState.smartRankedJobs;

    _scheduleMapRefresh(jobs);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      body: SafeArea(
        child: Column(
          children: [
            _topBar(),
            const SizedBox(height: 10),
            _toggle(),
            Expanded(
              child: _showMap
                  ? _mapView(jobs)
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _hotJobs(jobs),
                        const SizedBox(height: 16),
                        _newJobs(jobs),
                        const SizedBox(height: 16),
                        ...jobs.map(
                          (job) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: JobCard(
                              job: job,
                              distanceText: job.locationName,
                              onTap: () => _openJob(job),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= TOP =================

  Widget _topBar() {
    final user = context.read<AppState>().currentUser;
    final jobs = context.read<AppState>().smartRankedJobs;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Hei, ${user.firstName} 👋",
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            "Oppdrag nær deg",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            "⚡ ${jobs.length} tilgjengelige nå",
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // ================= TOGGLE =================

  Widget _toggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _toggleBtn("Kart", _showMap, () {
            setState(() => _showMap = true);
          }),
          const SizedBox(width: 8),
          _toggleBtn("Liste", !_showMap, () {
            setState(() => _showMap = false);
          }),
        ],
      ),
    );
  }

  Widget _toggleBtn(String text, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? Colors.blue : Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: active ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ================= LIST SECTIONS =================

  Widget _hotJobs(List<Job> jobs) {
    final hot = [...jobs]
  ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final top = hot.take(5).toList();

    if (top.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("🔥 Populære oppdrag",
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: top.length,
            itemBuilder: (_, i) {
              final job = top[i];
              return SizedBox(
                width: 220,
                child: JobCard(
                  job: job,
                  distanceText: job.locationName,
                  onTap: () => _openJob(job),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _newJobs(List<Job> jobs) {
    final fresh = [...jobs]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final top = fresh.take(5).toList();

    if (top.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("⚡ Nye nå",
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        ...top.map(
          (job) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: JobCard(
              job: job,
              distanceText: job.locationName,
              onTap: () => _openJob(job),
            ),
          ),
        ),
      ],
    );
  }

  // ================= MAP =================

  Widget _mapView(List<Job> jobs) {
    return GoogleMap(
      initialCameraPosition: const CameraPosition(
        target: LatLng(59.14, 9.65),
        zoom: 11,
      ),
      markers: _markers,
      circles: _heatmap,
    );
  }

  void _scheduleMapRefresh(List<Job> jobs) {}

  // ================= NAV =================

  void _openJob(Job job) {
    context.read<AppState>().incrementView(job.id);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => JobDetailScreen(job: job),
      ),
    );
  }
}