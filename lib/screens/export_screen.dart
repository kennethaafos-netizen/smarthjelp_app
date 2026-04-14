import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../providers/app_state.dart';

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  bool _isExporting = false;
  bool _isSendingEmail = false;
  late int _selectedYear;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final appState = context.read<AppState>();
    final years = appState.availableTaxReportYears;
    _selectedYear = years.isNotEmpty ? years.first : DateTime.now().year;
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final availableYears = appState.availableTaxReportYears;
    final report = appState.buildTaxReportForYear(_selectedYear);
    final currency = NumberFormat.currency(
      locale: 'nb_NO',
      symbol: 'kr ',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        title: const Text('Skatterapport'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _topPanel(
              availableYears: availableYears,
              report: report,
              currency: currency,
            ),
            Expanded(
              child: report.entries.isEmpty
                  ? _emptyState()
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      children: [
                        const SizedBox(height: 8),
                        _sectionTitle('Transaksjoner'),
                        const SizedBox(height: 12),
                        ...report.entries.map(
                          (entry) => _entryCard(
                            entry: entry,
                            currency: currency,
                          ),
                        ),
                      ],
                    ),
            ),
            _bottomActions(report),
          ],
        ),
      ),
    );
  }

  Widget _topPanel({
    required List<int> availableYears,
    required TaxReportSummary report,
    required NumberFormat currency,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2356E8), Color(0xFF18B7A6)],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2356E8).withOpacity(0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Excel-rapport for skattemelding',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Velg år og eksporter en ryddig rapport med dato, transaksjonstype, oppdragstype, sted og beløp.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.92),
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _selectedYear,
                      dropdownColor: Colors.white,
                      iconEnabledColor: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w700,
                      ),
                      items: availableYears
                          .map(
                            (year) => DropdownMenuItem<int>(
                              value: year,
                              child: Text('$year'),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _selectedYear = value);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _statCard(
                  title: 'Tjent',
                  value: currency.format(report.totalIncome),
                  icon: Icons.south_west_rounded,
                  accent: const Color(0xFF18B7A6),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _statCard(
                  title: 'Brukt',
                  value: currency.format(report.totalExpenses),
                  icon: Icons.north_east_rounded,
                  accent: const Color(0xFFEB5757),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _statCard(
                  title: 'Netto',
                  value: currency.format(report.net),
                  icon: Icons.account_balance_wallet_outlined,
                  accent: const Color(0xFF2356E8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
    required Color accent,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: Color(0xFF172033),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6E7A90),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.table_chart_outlined,
                size: 52,
                color: Color(0xFF2356E8),
              ),
              SizedBox(height: 14),
              Text(
                'Ingen fullførte transaksjoner for valgt år',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: Color(0xFF172033),
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Når du fullfører oppdrag, vil inntekter og kostnader automatisk dukke opp her.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF6E7A90),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return const Padding(
      padding: EdgeInsets.only(left: 2),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'Transaksjoner',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF172033),
          ),
        ),
      ),
    );
  }

  Widget _entryCard({
    required TaxReportEntry entry,
    required NumberFormat currency,
  }) {
    final isIncome = entry.isIncome;
    final accent = isIncome ? const Color(0xFF18B7A6) : const Color(0xFFEB5757);
    final bg = isIncome ? const Color(0xFFEAFBF7) : const Color(0xFFFFF1F1);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isIncome ? Icons.south_west_rounded : Icons.north_east_rounded,
              color: accent,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.jobTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: Color(0xFF172033),
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _chip(entry.typeLabel, accent.withOpacity(0.10), accent),
                    _chip(
                      entry.category,
                      const Color(0xFFEEF3FF),
                      const Color(0xFF2356E8),
                    ),
                    _chip(
                      DateFormat('dd.MM.yyyy').format(entry.date),
                      const Color(0xFFF3F5F9),
                      const Color(0xFF6E7A90),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  entry.locationName,
                  style: const TextStyle(
                    color: Color(0xFF6E7A90),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${isIncome ? '+' : '-'}${currency.format(entry.amount)}',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _bottomActions(TaxReportSummary report) {
    final disabled = report.entries.isEmpty || _isExporting || _isSendingEmail;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: disabled ? null : () => _exportExcel(report),
                icon: _isExporting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.file_download_outlined),
                label: Text(_isExporting ? 'Lager fil...' : 'Eksporter Excel'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: disabled ? null : () => _sendToEmail(report),
                icon: _isSendingEmail
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.mail_outline),
                label:
                    Text(_isSendingEmail ? 'Forbereder...' : 'Send til e-post'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportExcel(TaxReportSummary report) async {
    setState(() => _isExporting = true);

    try {
      final fileName = 'smarthjelp_skatterapport_${report.year}.xlsx';
      final bytes = await _buildExcelBytes(report);
      final xFile = XFile.fromData(
        Uint8List.fromList(bytes),
        mimeType:
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        name: fileName,
      );

      await Share.shareXFiles(
        [xFile],
        text:
            'Skatterapport fra SmartHjelp for ${report.year}. Du kan lagre filen lokalt eller åpne den i Excel.',
        subject: 'SmartHjelp skatterapport ${report.year}',
      );
    } catch (error) {
      if (!mounted) return;
      _showSnackBar(
        'Kunne ikke eksportere Excel akkurat nå. Feil: $error',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _sendToEmail(TaxReportSummary report) async {
    setState(() => _isSendingEmail = true);

    try {
      final fileName = 'smarthjelp_skatterapport_${report.year}.xlsx';
      final bytes = await _buildExcelBytes(report);
      final xFile = XFile.fromData(
        Uint8List.fromList(bytes),
        mimeType:
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        name: fileName,
      );

      await Share.shareXFiles(
        [xFile],
        text:
            'Vedlagt ligger SmartHjelp skatterapport for ${report.year}. Velg Mail eller Gmail i delingsmenyen for å sende filen på e-post.',
        subject: 'SmartHjelp skatterapport ${report.year}',
      );
    } catch (error) {
      if (!mounted) return;
      _showSnackBar(
        'Kunne ikke forberede e-post med vedlegg. Feil: $error',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isSendingEmail = false);
      }
    }
  }

  Future<List<int>> _buildExcelBytes(TaxReportSummary report) async {
    final excel = Excel.createExcel();
    final overview = excel['Oversikt'];
    final transactions = excel['Transaksjoner'];

    final defaultSheet = excel.getDefaultSheet();
    if (defaultSheet != null &&
        defaultSheet != 'Oversikt' &&
        defaultSheet != 'Transaksjoner') {
      excel.delete(defaultSheet);
    }

    final user = context.read<AppState>().currentUser;
    final dateFormat = DateFormat('dd.MM.yyyy');
    final generatedAt = DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now());

    overview.appendRow([TextCellValue('SmartHjelp skatterapport ${report.year}')]);
    overview.appendRow([TextCellValue('Generert: $generatedAt')]);
    overview.appendRow([TextCellValue('Bruker: ${user.firstName}')]);
    overview.appendRow([TextCellValue('E-post: ${user.email.isEmpty ? 'Ikke satt' : user.email}')]);
    overview.appendRow([TextCellValue('Telefon: ${user.phone.isEmpty ? 'Ikke satt' : user.phone}')]);
    overview.appendRow([]);
    overview.appendRow([
      TextCellValue('År'),
      TextCellValue('Antall transaksjoner'),
      TextCellValue('Tjent'),
      TextCellValue('Brukt'),
      TextCellValue('Netto'),
    ]);
    overview.appendRow([
      IntCellValue(report.year),
      IntCellValue(report.transactionCount),
      DoubleCellValue(report.totalIncome),
      DoubleCellValue(report.totalExpenses),
      DoubleCellValue(report.net),
    ]);
    overview.appendRow([]);
    overview.appendRow([TextCellValue('Rapporten inneholder kun fullførte oppdrag.')]);

    transactions.appendRow([
      TextCellValue('Dato'),
      TextCellValue('Transaksjonstype'),
      TextCellValue('Oppdragstype'),
      TextCellValue('Tittel'),
      TextCellValue('Sted'),
      TextCellValue('Beløp'),
    ]);

    for (final entry in report.entries) {
      transactions.appendRow([
        TextCellValue(dateFormat.format(entry.date)),
        TextCellValue(entry.typeLabel),
        TextCellValue(entry.category),
        TextCellValue(entry.jobTitle),
        TextCellValue(entry.locationName),
        DoubleCellValue(entry.isIncome ? entry.amount : -entry.amount),
      ]);
    }

    final bytes = excel.save();
    if (bytes == null) {
      throw Exception('Excel-pakken returnerte ingen filbytes.');
    }

    return bytes;
  }

  void _showSnackBar(String text, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: isError ? Colors.redAccent : null,
      ),
    );
  }
}