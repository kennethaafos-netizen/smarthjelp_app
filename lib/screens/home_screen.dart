import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
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

  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().ensureJobsLoaded();
    });
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final jobs = appState.smartRankedJobs;

    _buildMarkers(jobs);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      body: SafeArea(
        child: Column(
          children: [
            _header(context, jobs),
            const SizedBox(height: 10),
            _toggle(),
            const SizedBox(height: 10),

            // 🔥 KART / LISTE (overlay-kort nå over kartet, ikke under)
            Expanded(
              child: _showMap ? _mapView(jobs) : _listView(jobs),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- MAP ----------------

  Widget _mapView(List<Job> jobs) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // 🔥 SELVE KARTET
            Positioned.fill(
              child: GoogleMap(
                initialCameraPosition: const CameraPosition(
                  target: LatLng(59.14, 9.65),
                  zoom: 11,
                ),
                markers: _markers,
                myLocationButtonEnabled: true,
                zoomControlsEnabled: true,

                // 🔥 EAGER GESTURES – fikser web/mobile-toggle touch-problemer
                // slik at preview-kortet faktisk kan trykkes.
                gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                  Factory<OneSequenceGestureRecognizer>(
                    () => EagerGestureRecognizer(),
                  ),
                },

                onMapCreated: (controller) {
                  _mapController = controller;
                },

                // 🔥 VIKTIG: ingen auto-deselect ved tap på kartet.
                // Tidligere fjernet dette preview-kortet for tidlig på web/mobile
                // og gjorde knappene utilgjengelige. Kortet lukkes nå bare via X.
                onTap: (_) {},
              ),
            ),

            // 🔥 PREVIEW / OPPDRAGSLINJE SOM OVERLAY
            if (_selectedJob != null)
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: _MapPreviewCard(
                  job: _selectedJob!,
                  isTaking: _isTakingJob,
                  onClose: () => setState(() => _selectedJob = null),
                  onOpen: () => _openJob(_selectedJob!),
                  onTake: _selectedJob!.status == JobStatus.open &&
                          _selectedJob!.createdByUserId !=
                              context.read<AppState>().currentUser.id
                      ? () => _takeAndOpen(_selectedJob!)
                      : null,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _buildMarkers(List<Job> jobs) {
    _markers = jobs.map((job) {
      return Marker(
        markerId: MarkerId(job.id),
        position: LatLng(job.lat, job.lng),
        consumeTapEvents: true,
        onTap: () async {
          final fresh = context.read<AppState>().getJobById(job.id) ?? job;

          setState(() => _selectedJob = fresh);

          // Anim kamera til jobbens posisjon (hvis mulig) så kortet gir mening
          try {
            await _mapController?.animateCamera(
              CameraUpdate.newLatLng(LatLng(fresh.lat, fresh.lng)),
            );
          } catch (_) {
            // ignorer – karten er ikke klar enda
          }
        },
      );
    }).toSet();
  }

  // ---------------- LIST ----------------

  Widget _listView(List<Job> jobs) {
    if (jobs.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          SizedBox(height: 40),
          Center(
            child: Text(
              'Ingen oppdrag å vise akkurat nå.',
              style: TextStyle(
                color: Color(0xFF6E7A90),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: jobs
          .map(
            (job) => JobCard(
              job: job,
              distanceText: job.locationName,
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

    // Rydd preview-kortet før vi åpner detaljsiden
    setState(() {
      _isTakingJob = false;
      _selectedJob = null;
    });

    if (updated != null) {
      _openJob(updated);
    }
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              '${jobs.length} oppdrag',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF2356E8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _toggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _toggleBtn('Kart', _showMap, () => setState(() => _showMap = true)),
        const SizedBox(width: 12),
        _toggleBtn('Liste', !_showMap, () => setState(() => _showMap = false)),
      ],
    );
  }

  Widget _toggleBtn(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF2356E8) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: const Color(0xFF2356E8).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : const Color(0xFF172033),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ---------------- PREVIEW CARD ----------------

class _MapPreviewCard extends StatelessWidget {
  final Job job;
  final bool isTaking;
  final VoidCallback onClose;
  final VoidCallback onOpen;
  final VoidCallback? onTake;

  const _MapPreviewCard({
    required this.job,
    required this.isTaking,
    required this.onClose,
    required this.onOpen,
    required this.onTake,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: onOpen,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Liten preview-bilde-plate
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF3FB),
                      borderRadius: BorderRadius.circular(14),
                      image: (job.imageUrl != null && job.imageUrl!.isNotEmpty)
                          ? DecorationImage(
                              image: NetworkImage(job.imageUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: (job.imageUrl == null || job.imageUrl!.isEmpty)
                        ? const Icon(
                            Icons.work_outline,
                            color: Color(0xFF2356E8),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),

                  // Tittel + info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                job.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  color: Color(0xFF172033),
                                ),
                              ),
                            ),
                            // Lukk-knapp (erstatter auto-deselect)
                            InkWell(
                              onTap: onClose,
                              borderRadius: BorderRadius.circular(20),
                              child: const Padding(
                                padding: EdgeInsets.all(4),
                                child: Icon(
                                  Icons.close,
                                  size: 18,
                                  color: Color(0xFF6E7A90),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${job.locationName} · ${job.category}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF6E7A90),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              '${job.price} kr',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF18B7A6),
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _takeOrOpenButton(context),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _takeOrOpenButton(BuildContext context) {
    if (onTake == null) {
      return SizedBox(
        height: 36,
        child: OutlinedButton(
          onPressed: onOpen,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Se oppdrag',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
      );
    }

    return SizedBox(
      height: 36,
      child: ElevatedButton(
        onPressed: isTaking ? null : onTake,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2356E8),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isTaking
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text(
                'Ta jobb',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
      ),
    );
  }
}
