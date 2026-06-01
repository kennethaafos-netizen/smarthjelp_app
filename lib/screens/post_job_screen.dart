import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../data/dummy_data.dart';
import '../models/job.dart';
import '../providers/app_state.dart';
import '../services/supabase_service.dart';
import 'jobs_screen.dart' show JobsTab;

// Lokale design-tokens — speiler resten av appen (samme palett som
// HomeScreen/JobDetailScreen). Holdes lokalt her; ingen global token-
// refaktor i denne omgangen.
const Color _kPrimary = Color(0xFF2356E8);
const Color _kBg = Color(0xFFF4F7FC);
const Color _kTextPrimary = Color(0xFF0F1E3A);
const Color _kTextMuted = Color(0xFF6E7A90);
const Color _kBorder = Color(0xFFE4E9F2);
const Color _kSafeGreen = Color(0xFF0EA877);

class PostJobScreen extends StatefulWidget {
  final Job? existingJob;

  /// Valgfri callback som fyres etter at brukeren har publisert et NYTT
  /// oppdrag (ikke ved redigering) og lukket bekreftelses-arket. AppShell
  /// kobler dette til _onNavigateToJobsTab slik at brukeren lander på
  /// Oppdrag → Mine i stedet for å bli stående på Publiser-fanen.
  /// Hvis null (eller redigeringsmodus), gjøres ingenting — bevarer den
  /// eksisterende Navigator.pop()-flyten for push-rute-redigering.
  final void Function(JobsTab tab)? onPublished;

  const PostJobScreen({
    super.key,
    this.existingJob,
    this.onPublished,
  });

  @override
  State<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends State<PostJobScreen> {
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _price = TextEditingController();
  final _postcode = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final PageController _controller = PageController();

  String? category;
  List<XFile> images = [];
  int currentIndex = 0;
  bool _isSubmitting = false;
  String? _editKommune;

  // Reservasjonsvindu valgt av oppdragsgiver. MVP: 30 (vanlig, default)
  // eller 10 (haste). Styrer kun hvor lenge oppdraget er låst etter at
  // noen tar det — ikke hvor raskt jobben må gjøres.
  int _reservationMinutes = 30;

  bool get _isEditing => widget.existingJob != null;

  @override
  void initState() {
    super.initState();
    final job = widget.existingJob;
    if (job != null) {
      _title.text = job.title;
      _desc.text = job.description;
      _price.text = job.price.toString();
      category = job.category;
      _editKommune = kLocations.contains(job.locationName) ? job.locationName : kLocations.first;
      _reservationMinutes = job.reservationMinutes == 10 ? 10 : 30;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _price.dispose();
    _postcode.dispose();
    _controller.dispose();
    super.dispose();
  }

  String? _kommuneForPostcode(String raw) {
    final p = int.tryParse(raw.trim());
    if (p == null) return null;
    if (p >= 3700 && p <= 3747) return 'Skien';
    if (p >= 3748 && p <= 3749) return 'Siljan';
    if (p >= 3900 && p <= 3949) return 'Porsgrunn';
    if (p >= 3950 && p <= 3999) return 'Bamble';
    return null;
  }

  String? get _derivedKommune => _kommuneForPostcode(_postcode.text);

  int get _priceValue => int.tryParse(_price.text.trim()) ?? 0;
  double get _feeValue => _priceValue * 0.10;
  double get _totalValue => _priceValue + _feeValue;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: Text(_isEditing ? 'Rediger oppdrag' : 'Legg ut oppdrag'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          // Beholder romslig bunn-padding: PostJobScreen vises også som
          // fane i AppShell under den flytende bottom-naven (extendBody),
          // så submit-knappen må klarere navet.
          padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 140),
          children: [
            if (!_isEditing) ...[
              _sectionHeader(
                icon: Icons.photo_library_outlined,
                title: 'Bilder',
                subtitle: 'Legg til inntil 5 bilder (valgfritt)',
              ),
              _imagePicker(),
              const SizedBox(height: 22),
            ],
            _sectionHeader(
              icon: Icons.assignment_outlined,
              title: 'Om oppdraget',
            ),
            _field(_title, 'Tittel', icon: Icons.title_rounded),
            _field(_desc, 'Beskrivelse', maxLines: 4),
            _dropdown(kCategories, category, 'Kategori', (v) => setState(() => category = v)),
            const SizedBox(height: 22),
            _sectionHeader(
              icon: Icons.payments_outlined,
              title: 'Pris',
            ),
            _field(_price, 'Pris til oppdragstaker (kr)',
                number: true,
                icon: Icons.payments_outlined,
                onChanged: (_) => setState(() {})),
            if (_priceValue > 0) ...[
              const SizedBox(height: 10),
              _priceBreakdownCard(),
            ],
            const SizedBox(height: 22),
            _sectionHeader(
              icon: Icons.place_outlined,
              title: 'Sted',
            ),
            if (_isEditing)
              _dropdown(kLocations, _editKommune, 'Kommune', (v) => setState(() => _editKommune = v))
            else
              _postcodeField(),
            const SizedBox(height: 22),
            _sectionHeader(
              icon: Icons.timelapse_rounded,
              title: 'Reservasjonstid',
            ),
            _reservationSelector(),
            const SizedBox(height: 28),
            _submitButton(),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader({
    required IconData icon,
    required String title,
    String? subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: _kPrimary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 16, color: _kPrimary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _kTextPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: _kTextMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _priceBreakdownCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _priceRow('Til oppdragstaker', '$_priceValue kr'),
          const SizedBox(height: 6),
          _priceRow(
              'Plattformavgift (inkl. mva)', '${_feeValue.toStringAsFixed(0)} kr'),
          const SizedBox(height: 10),
          const Divider(height: 1, color: _kBorder),
          const SizedBox(height: 10),
          _priceRow('Du betaler totalt', '${_totalValue.toStringAsFixed(0)} kr',
              emphasize: true),
          const SizedBox(height: 10),
          const Row(
            children: [
              Icon(Icons.lock_outline_rounded, size: 14, color: _kSafeGreen),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Beløpet holdes trygt av SmartHjelp til du godkjenner fullført jobb.',
                  style: TextStyle(
                    color: _kSafeGreen,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _priceRow(String label, String value, {bool emphasize = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: emphasize ? _kTextPrimary : _kTextMuted,
            fontWeight: emphasize ? FontWeight.w700 : FontWeight.w600,
            fontSize: 13.5,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: emphasize ? _kPrimary : _kTextPrimary,
            fontWeight: FontWeight.w800,
            fontSize: emphasize ? 16 : 14,
          ),
        ),
      ],
    );
  }

  Widget _submitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isSubmitting ? null : _submit,
        icon: _isSubmitting
            ? const SizedBox.shrink()
            : Icon(_isEditing ? Icons.save_rounded : Icons.send_rounded,
                size: 20),
        label: _isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child:
                    CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Text(_isEditing ? 'Lagre endringer' : 'Publiser'),
        style: ElevatedButton.styleFrom(
          backgroundColor: _kPrimary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _imagePicker() {
    final hasImages = images.isNotEmpty;
    return Column(
      children: [
        GestureDetector(
          onTap: _pickImages,
          behavior: HitTestBehavior.opaque,
          child: Container(
            height: 140,
            width: double.infinity,
            decoration: BoxDecoration(
              color: _kPrimary.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: _kPrimary.withValues(alpha: 0.35), width: 1.5),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: _kPrimary.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    hasImages
                        ? Icons.collections_rounded
                        : Icons.add_a_photo_outlined,
                    color: _kPrimary,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  hasImages ? 'Endre bilder' : 'Legg til bilder',
                  style: const TextStyle(
                      color: _kTextPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  hasImages ? '${images.length}/5 valgt' : 'Inntil 5 bilder',
                  style: const TextStyle(
                      color: _kTextMuted,
                      fontWeight: FontWeight.w500,
                      fontSize: 12),
                ),
              ],
            ),
          ),
        ),
        if (images.isNotEmpty) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  PageView.builder(
                    controller: _controller,
                    itemCount: images.length,
                    onPageChanged: (i) => setState(() => currentIndex = i),
                    itemBuilder: (_, index) {
                      final img = images[index];
                      return FutureBuilder(
                        future: img.readAsBytes(),
                        builder: (_, snap) {
                          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                          return Image.memory(snap.data!, fit: BoxFit.cover, width: double.infinity);
                        },
                      );
                    },
                  ),
                  Positioned(
                    left: 10, top: 0, bottom: 0,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                      onPressed: currentIndex > 0
                          ? () => _controller.previousPage(duration: const Duration(milliseconds: 200), curve: Curves.ease)
                          : null,
                    ),
                  ),
                  Positioned(
                    right: 10, top: 0, bottom: 0,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_forward_ios, color: Colors.white),
                      onPressed: currentIndex < images.length - 1
                          ? () => _controller.nextPage(duration: const Duration(milliseconds: 200), curve: Curves.ease)
                          : null,
                    ),
                  ),
                  Positioned(
                    bottom: 10, right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text('${currentIndex + 1}/${images.length}', style: const TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _pickImages() async {
    try {
      if (kIsWeb) {
        final result = await FilePicker.platform.pickFiles(type: FileType.image, allowMultiple: true, withData: true);
        if (result != null) {
          setState(() {
            images = result.files
                .where((f) => f.bytes != null)
                .take(5)
                .map((f) => XFile.fromData(f.bytes!, name: f.name))
                .toList();
            currentIndex = 0;
          });
        }
      } else {
        final picked = await ImagePicker().pickMultiImage();
        setState(() { images = picked.take(5).toList(); currentIndex = 0; });
      }
    } catch (e) {
      debugPrint('Image pick error: $e');
    }
  }

  Future<void> _submit() async {
    // Sprint 8 fix: lukk tastaturet FØR vi viser bottom sheet / snackbar /
    // dialog. Prisfeltet (talltastatur) beholdt fokus tidligere, så
    // publiserings-bekreftelsen kom bak/over tastaturet. unfocus() her
    // dekker alle exit-veier under (suksess-sheet, feil-snackbar, dialog).
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;
    if (category == null) return;

    final String kommune;
    if (_isEditing) {
      if (_editKommune == null) return;
      kommune = _editKommune!;
    } else {
      final derived = _derivedKommune;
      if (derived == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Postnummeret er ikke i SmartHjelp sitt dekningsområde (Skien, Porsgrunn, Siljan, Bamble).'),
        ));
        return;
      }
      kommune = derived;
    }

    final parsedPrice = int.tryParse(_price.text.trim());
    if (parsedPrice == null || parsedPrice <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pris må være et gyldig tall')));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final appState = context.read<AppState>();
      if (_isEditing) {
        final ok = await appState.updateOwnJob(
          jobId: widget.existingJob!.id,
          title: _title.text.trim(),
          description: _desc.text.trim(),
          price: parsedPrice,
          category: category!,
          locationName: kommune,
          lat: _latForLocation(kommune),
          lng: _lngForLocation(kommune),
          reservationMinutes: _reservationMinutes,
        );
        if (!mounted) return;
        if (ok) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Oppdrag oppdatert')));
          Navigator.of(context).pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kunne ikke oppdatere oppdraget.')));
        }
      } else {
        // Sprint 7A: ærlig bilde-opplasting. Tidligere falt vi tilbake
        // til lokal fil-sti som imageUrl hvis Supabase storage feilet.
        // Det ga "Oppdrag publisert"-snackbar selv om andre brukere
        // aldri kunne se bildet (lokal sti != fungerende URL). Nå
        // teller vi feilede opplastinger og spør brukeren EKSPLISITT
        // før vi publiserer uten dem.
        final supabase = SupabaseService();
        final urls = <String>[];
        int failedCount = 0;

        for (final img in images) {
          try {
            final bytes = await img.readAsBytes();
            final url = await supabase.uploadJobImage(
                bytes: bytes, originalFileName: img.name);
            if (url != null) {
              urls.add(url);
            } else {
              failedCount++;
            }
          } catch (e) {
            debugPrint('Upload error: $e');
            failedCount++;
          }
        }

        // Hvis 1+ bilder feilet, gi bruker valg om å publisere uten
        // dem eller avbryte og prøve igjen. Skjuler ikke feil bak
        // lokal-sti-fallback som ga broken images i prod.
        if (failedCount > 0 && images.isNotEmpty) {
          if (!mounted) return;
          final proceed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text('Noen bilder ble ikke lastet opp'),
              content: Text(
                '$failedCount av ${images.length} bilder kunne ikke lastes opp '
                'til SmartHjelp. Vil du publisere oppdraget uten disse bildene?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Avbryt'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Publiser uten disse'),
                ),
              ],
            ),
          );
          if (proceed != true) {
            if (mounted) setState(() => _isSubmitting = false);
            return;
          }
        }

        final ok = await appState.addJob(
          title: _title.text.trim(),
          description: _desc.text.trim(),
          price: parsedPrice,
          locationName: kommune,
          lat: _latForLocation(kommune),
          lng: _lngForLocation(kommune),
          category: category!,
          imageUrl: urls.isNotEmpty ? urls.first : null,
          imageUrls: urls,
          reservationMinutes: _reservationMinutes,
        );

        if (ok) await appState.reloadJobs();
        if (!mounted) return;

        if (!ok) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Kunne ikke lagre oppdraget i Supabase. Sjekk tilkobling / innlogging.'),
          ));
        } else {
          // Fase A: bytt snackbar med premium bottom sheet som setter
          // forventning om respons-tid mens reservasjonen løper. Reduserer
          // antall "ingen tok jobben"-frustrasjoner ved at owner blir på
          // telefonen mens oppdragstakere har spørsmål.
          _title.clear(); _desc.clear(); _price.clear(); _postcode.clear();
          setState(() { images = []; category = null; currentIndex = 0; });
          await _showPublishedSheet();
          // Etter publisering + "Forstått": send brukeren videre til
          // Oppdrag → Mine. Kun for nye oppdrag — redigerings-flyten
          // (push-rute fra JobsScreen) lar Navigator.pop håndtere retur.
          // mounted-sjekk fordi sheet er en await — brukeren kan ha
          // navigert vekk mens den var åpen.
          if (mounted && !_isEditing) {
            widget.onPublished?.call(JobsTab.mine);
          }
        }
      }
    } catch (e) {
      debugPrint('Submit error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Noe gikk galt under publisering')));
      }
    }

    if (mounted) setState(() => _isSubmitting = false);
  }

  Future<void> _showPublishedSheet() async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: false,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE4E9F2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Icon(Icons.check_circle_rounded,
                        color: Color(0xFF0EA877), size: 26),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Oppdraget er publisert',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F1E3A),
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  'Tips: Vær tilgjengelig de neste minuttene. Oppdragstakere '
                  'kan ha spørsmål før de tar jobben, og rask respons gjør '
                  'at du får hjelp fortere.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6E7A90),
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2356E8),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Forstått',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Oppdragsgiver velger reservasjonsvindu. MVP: kun to valg.
  // Presiserer at dette er låsetid, ikke en frist for å fullføre jobben.
  Widget _reservationSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _reservationOption(
                minutes: 30,
                title: 'Vanlig',
                subtitle: '30 min reservasjon',
                icon: Icons.schedule_rounded,
                accent: const Color(0xFF2356E8),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _reservationOption(
                minutes: 10,
                title: 'Haste',
                subtitle: '10 min reservasjon',
                icon: Icons.bolt_rounded,
                accent: const Color(0xFFE08A00),
              ),
            ),
          ],
        ),
        const Padding(
          padding: EdgeInsets.only(left: 4, top: 8),
          child: Text(
            'Styrer hvor lenge oppdraget er låst til den som tar det — ikke hvor raskt jobben må gjøres.',
            style: TextStyle(
              color: Color(0xFF6E7A90),
              fontSize: 12,
              height: 1.35,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _reservationOption({
    required int minutes,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accent,
  }) {
    final bool selected = _reservationMinutes == minutes;
    return GestureDetector(
      onTap: () => setState(() => _reservationMinutes = minutes),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.10) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? accent : const Color(0xFFE4E9F2),
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: accent),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14.5,
                    color: selected ? accent : const Color(0xFF0F1E3A),
                  ),
                ),
                const Spacer(),
                if (selected)
                  Icon(Icons.check_circle_rounded, size: 16, color: accent),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                color: Color(0xFF6E7A90),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController c,
    String label, {
    bool number = false,
    int maxLines = 1,
    ValueChanged<String>? onChanged,
    IconData? icon,
  }) {
    // FASE 3 FIX: multiline felt skal gi newline når brukeren trykker Enter,
    // ikke submit. Dette krever TextInputType.multiline + newline-action.
    final isMultiline = maxLines > 1;
    final keyboard = number
        ? TextInputType.number
        : (isMultiline ? TextInputType.multiline : TextInputType.text);
    final action = isMultiline ? TextInputAction.newline : TextInputAction.next;

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: TextFormField(
        controller: c,
        keyboardType: keyboard,
        textInputAction: action,
        maxLines: maxLines,
        onChanged: onChanged,
        validator: (v) => (v == null || v.isEmpty) ? '$label må fylles ut' : null,
        decoration: InputDecoration(
          labelText: label,
          alignLabelWithHint: isMultiline,
          prefixIcon:
              icon == null ? null : Icon(icon, size: 20, color: _kTextMuted),
        ),
      ),
    );
  }

  Widget _postcodeField() {
    final kommune = _derivedKommune;
    final hasInput = _postcode.text.trim().isNotEmpty;
    final isValid = kommune != null;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _postcode,
            keyboardType: TextInputType.number,
            maxLength: 4,
            onChanged: (_) => setState(() {}),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Postnummer må fylles ut';
              if (_kommuneForPostcode(v) == null) return 'Postnummeret er utenfor dekningsområdet';
              return null;
            },
            decoration: const InputDecoration(
              labelText: 'Postnummer',
              hintText: 'f.eks. 3717',
              counterText: '',
              prefixIcon: Icon(Icons.markunread_mailbox_outlined,
                  size: 20, color: _kTextMuted),
            ),
          ),
          if (hasInput)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 4),
              child: Text(
                isValid ? 'Kommune: $kommune' : 'Utenfor dekningsområdet (Skien, Porsgrunn, Siljan, Bamble)',
                style: TextStyle(
                  color: isValid ? const Color(0xFF0EA877) : const Color(0xFFDC2626),
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _dropdown(List<String> list, String? value, String label, Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: DropdownButtonFormField<String>(
        value: value,
        items: list.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: onChanged,
        validator: (v) => v == null ? '$label må velges' : null,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  double _latForLocation(String locationName) {
    final key = locationName.trim().toLowerCase();
    if (key.contains('skien')) return 59.2096;
    if (key.contains('porsgrunn')) return 59.1419;
    if (key.contains('siljan')) return 59.3024;
    if (key.contains('langesund')) return 59.0000;
    if (key.contains('stathelle')) return 59.0456;
    if (key.contains('bamble')) return 59.0197;
    return 59.14;
  }

  double _lngForLocation(String locationName) {
    final key = locationName.trim().toLowerCase();
    if (key.contains('skien')) return 9.6089;
    if (key.contains('porsgrunn')) return 9.6561;
    if (key.contains('siljan')) return 9.7181;
    if (key.contains('langesund')) return 9.7500;
    if (key.contains('stathelle')) return 9.6910;
    if (key.contains('bamble')) return 9.5600;
    return 9.65;
  }
}