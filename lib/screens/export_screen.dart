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
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: const TextStyle(
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
    final period = '01.01.${report.year} – 31.12.${report.year}';

    // -------- Stiler --------
    final primaryBg = ExcelColor.fromHexString('FF2356E8');
    final softBlueBg = ExcelColor.fromHexString('FFEEF3FF');
    final mutedColor = ExcelColor.fromHexString('FF6E7A90');
    final warningColor = ExcelColor.fromHexString('FFE08A00');
    final krFormat = NumFormat.custom(formatCode: '#,##0" kr"');

    final titleStyle = CellStyle(
      bold: true,
      fontSize: 16,
      fontColorHex: ExcelColor.white,
      backgroundColorHex: primaryBg,
      horizontalAlign: HorizontalAlign.Center,
    );
    final topNoteStyle = CellStyle(
      italic: true,
      bold: true,
      fontColorHex: mutedColor,
      horizontalAlign: HorizontalAlign.Center,
    );
    final headerStyle = CellStyle(
      bold: true,
      fontColorHex: ExcelColor.white,
      backgroundColorHex: primaryBg,
      horizontalAlign: HorizontalAlign.Center,
    );
    final sectionStyle = CellStyle(
      bold: true,
      fontSize: 13,
      fontColorHex: ExcelColor.fromHexString('FF2356E8'),
    );
    final labelStyle = CellStyle(bold: true);
    final krStyle = CellStyle(numberFormat: krFormat);
    final krTotalsStyle = CellStyle(
      bold: true,
      backgroundColorHex: softBlueBg,
      numberFormat: krFormat,
    );
    final totalsLabelStyle = CellStyle(
      bold: true,
      backgroundColorHex: softBlueBg,
    );
    final footnoteStyle = CellStyle(
      italic: true,
      fontColorHex: mutedColor,
    );
    final keySumStyle = CellStyle(
      bold: true,
      fontColorHex: ExcelColor.fromHexString('FF0F1E3A'),
      numberFormat: krFormat,
    );
    final warningStyle = CellStyle(bold: true, fontColorHex: warningColor);

    void setCell(
      Sheet s,
      int col,
      int rowIdx,
      CellValue? value, {
      CellStyle? style,
    }) {
      final c = s.cell(
        CellIndex.indexByColumnRow(columnIndex: col, rowIndex: rowIdx),
      );
      c.value = value;
      if (style != null) c.cellStyle = style;
    }

    // ====================== OVERSIKT ======================
    // Row 0: Title (merged A:H)
    setCell(
      overview,
      0,
      0,
      TextCellValue('SmartHjelp – Skatterapport ${report.year}'),
      style: titleStyle,
    );
    overview.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
      CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: 0),
    );
    overview.setRowHeight(0, 28);

    // Row 1: Kort merknad (merged A:H)
    setCell(
      overview,
      0,
      1,
      TextCellValue(
        'Hjelpedokument — ikke skatterådgivning. '
        'Du er selv ansvarlig for skattemelding.',
      ),
      style: topNoteStyle,
    );
    overview.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1),
      CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: 1),
    );
    overview.setRowHeight(1, 18);

    // Rows 3..7: Metadata-blokk
    setCell(overview, 0, 3, TextCellValue('Generert'), style: labelStyle);
    setCell(overview, 1, 3, TextCellValue(generatedAt));
    setCell(overview, 0, 4, TextCellValue('Bruker'), style: labelStyle);
    setCell(overview, 1, 4, TextCellValue(user.firstName));
    setCell(overview, 0, 5, TextCellValue('E-post'), style: labelStyle);
    setCell(
      overview,
      1,
      5,
      TextCellValue(user.email.isEmpty ? 'Ikke satt' : user.email),
    );
    setCell(overview, 0, 6, TextCellValue('Telefon'), style: labelStyle);
    setCell(
      overview,
      1,
      6,
      TextCellValue(user.phone.isEmpty ? 'Ikke satt' : user.phone),
    );
    setCell(overview, 0, 7, TextCellValue('Periode'), style: labelStyle);
    setCell(overview, 1, 7, TextCellValue(period));

    // Row 9: KPI-tabell
    const kpiHeaders = [
      'År',
      'Antall transaksjoner',
      'Antall inntekter',
      'Antall kostnader',
      'Sum inntekter',
      'Sum plattformavgift',
      'Sum kostnader',
      'Netto',
    ];
    for (var i = 0; i < kpiHeaders.length; i++) {
      setCell(overview, i, 9, TextCellValue(kpiHeaders[i]), style: headerStyle);
    }
    overview.setRowHeight(9, 22);

    final incomeCount = report.entries.where((e) => e.isIncome).length;
    final expenseCount = report.entries.length - incomeCount;
    final totalPlatformFee = report.entries
        .fold<double>(0, (sum, e) => sum + e.platformFee);

    const kpiRow = 10;
    setCell(overview, 0, kpiRow, IntCellValue(report.year));
    setCell(overview, 1, kpiRow, IntCellValue(report.transactionCount));
    setCell(overview, 2, kpiRow, IntCellValue(incomeCount));
    setCell(overview, 3, kpiRow, IntCellValue(expenseCount));
    setCell(overview, 4, kpiRow, DoubleCellValue(report.totalIncome), style: krStyle);
    setCell(overview, 5, kpiRow, DoubleCellValue(totalPlatformFee), style: krStyle);
    setCell(overview, 6, kpiRow, DoubleCellValue(report.totalExpenses), style: krStyle);
    setCell(overview, 7, kpiRow, DoubleCellValue(report.net), style: krStyle);

    // -------- Sammendrag per kategori --------
    final catCount = <String, int>{};
    final catIncome = <String, double>{};
    final catExpense = <String, double>{};
    for (final e in report.entries) {
      catCount[e.category] = (catCount[e.category] ?? 0) + 1;
      if (e.isIncome) {
        catIncome[e.category] = (catIncome[e.category] ?? 0) + e.amount;
      } else {
        catExpense[e.category] = (catExpense[e.category] ?? 0) + e.amount;
      }
    }

    var row = 12;
    setCell(
      overview,
      0,
      row,
      TextCellValue('Sammendrag per kategori'),
      style: sectionStyle,
    );
    row++;
    const catHeaders = ['Kategori', 'Antall', 'Inntekt', 'Kostnad', 'Netto'];
    for (var i = 0; i < catHeaders.length; i++) {
      setCell(overview, i, row, TextCellValue(catHeaders[i]), style: headerStyle);
    }
    overview.setRowHeight(row, 22);
    row++;

    final sortedCategories = catCount.keys.toList()..sort();
    for (final cat in sortedCategories) {
      final c = catCount[cat] ?? 0;
      final inc = catIncome[cat] ?? 0;
      final exp = catExpense[cat] ?? 0;
      setCell(overview, 0, row, TextCellValue(cat));
      setCell(overview, 1, row, IntCellValue(c));
      setCell(overview, 2, row, DoubleCellValue(inc), style: krStyle);
      setCell(overview, 3, row, DoubleCellValue(exp), style: krStyle);
      setCell(overview, 4, row, DoubleCellValue(inc - exp), style: krStyle);
      row++;
    }

    // -------- TIL SKATTEMELDINGEN --------
    row++; // tom rad
    setCell(
      overview,
      0,
      row,
      TextCellValue('Til skattemeldingen'),
      style: sectionStyle,
    );
    row++;

    // Kopierbare nøkkelsummer (etikett + beløp som tall).
    setCell(overview, 0, row,
        TextCellValue('Sum inntekter som utfører'), style: labelStyle);
    setCell(overview, 1, row,
        DoubleCellValue(report.totalIncome), style: keySumStyle);
    row++;
    setCell(overview, 0, row,
        TextCellValue('Sum plattformavgift betalt som oppdragsgiver'),
        style: labelStyle);
    setCell(overview, 1, row,
        DoubleCellValue(totalPlatformFee), style: keySumStyle);
    row++;
    setCell(overview, 0, row,
        TextCellValue('Sum betalt som oppdragsgiver inkl. plattformavgift'),
        style: labelStyle);
    setCell(overview, 1, row,
        DoubleCellValue(report.totalExpenses), style: keySumStyle);
    row++;
    setCell(overview, 0, row,
        TextCellValue('Netto oversikt'), style: labelStyle);
    setCell(overview, 1, row,
        DoubleCellValue(report.net), style: keySumStyle);
    row++;

    // Forsiktige merknader for skattemeldings-seksjonen
    row++;
    final taxSectionNotes = [
      'Utgifter som privat oppdragsgiver er normalt ikke fradragsberettiget.',
      'Plattformavgift er inkl. mva og betales av oppdragsgiver. Utfører skal '
          'ikke trekke denne fra sin inntekt dersom utfører ikke har betalt avgiften.',
    ];
    for (final n in taxSectionNotes) {
      setCell(overview, 0, row, TextCellValue(n), style: footnoteStyle);
      overview.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
        CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: row),
      );
      row++;
    }

    // -------- SMÅJOBB-KONTROLL (6 000 kr-grensen) --------
    row++; // tom rad
    setCell(
      overview,
      0,
      row,
      TextCellValue('Småjobb-kontroll (6 000 kr-grensen)'),
      style: sectionStyle,
    );
    row++;

    final smallJobNotes = [
      'Småjobber i private hjem/fritidsbolig kan være skattefrie inntil 6 000 kr '
          'per kalenderår fra samme oppdragsgiver/husstand til samme person, '
          'hvis vilkårene er oppfylt. Kontroller dette selv hos Skatteetaten.',
      'Hvis en oppdragsgiver/husstand betaler over grensen, kan hele beløpet '
          'fra den oppdragsgiveren bli skattepliktig.',
      'Begrensning: SmartHjelp grupperer kun per individuell oppdragsgiver '
          '(bruker-konto). "Samme husstand" kan ikke utledes fra appen — '
          'sjekk selv. Tallene under er kun en regnemessig kontroll, ikke '
          'en skattemessig avgjørelse.',
    ];
    for (final n in smallJobNotes) {
      setCell(overview, 0, row, TextCellValue(n), style: footnoteStyle);
      overview.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
        CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: row),
      );
      row++;
    }
    row++; // tom rad

    // Grupper inntekter per counterpartyUserId
    final cpName = <String, String>{};
    final cpCount = <String, int>{};
    final cpSum = <String, double>{};
    for (final e in report.entries.where((e) => e.isIncome)) {
      final id = e.counterpartyUserId.isEmpty
          ? 'ukjent_${e.sourceJobId}'
          : e.counterpartyUserId;
      cpCount[id] = (cpCount[id] ?? 0) + 1;
      cpSum[id] = (cpSum[id] ?? 0) + e.amount;
      if (!(cpName[id]?.isNotEmpty ?? false)) {
        cpName[id] = e.counterpartyName.isEmpty
            ? 'Oppdragsgiver (ukjent navn)'
            : e.counterpartyName;
      }
    }

    const cpHeaders = ['Oppdragsgiver', 'Antall jobber', 'Sum inntekt', 'Kontroll'];
    for (var i = 0; i < cpHeaders.length; i++) {
      setCell(overview, i, row, TextCellValue(cpHeaders[i]), style: headerStyle);
    }
    overview.setRowHeight(row, 22);
    row++;

    if (cpCount.isEmpty) {
      setCell(
        overview,
        0,
        row,
        TextCellValue('Ingen inntekter som utfører i denne perioden.'),
        style: footnoteStyle,
      );
      overview.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
        CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row),
      );
      row++;
    } else {
      // Høyeste sum først så brukeren ser eventuelle grensetilfeller øverst.
      final sortedIds = cpSum.keys.toList()
        ..sort((a, b) => (cpSum[b] ?? 0).compareTo(cpSum[a] ?? 0));
      for (final id in sortedIds) {
        final name = cpName[id] ?? 'Oppdragsgiver (ukjent navn)';
        final count = cpCount[id] ?? 0;
        final sum = cpSum[id] ?? 0;
        final over = sum > 6000;
        final controlText = over
            ? 'Over 6 000 kr — krever nærmere kontroll'
            : 'Under 6 000 kr';
        setCell(overview, 0, row, TextCellValue(name));
        setCell(overview, 1, row, IntCellValue(count));
        setCell(overview, 2, row, DoubleCellValue(sum), style: krStyle);
        setCell(
          overview,
          3,
          row,
          TextCellValue(controlText),
          style: over ? warningStyle : null,
        );
        row++;
      }
    }

    // -------- ANSVAR OG FORBEHOLD --------
    row++; // tom rad
    setCell(
      overview,
      0,
      row,
      TextCellValue('Ansvar og forbehold'),
      style: sectionStyle,
    );
    row++;
    final disclaimers = [
      'SmartHjelp rapporterer ikke inntekter, utgifter eller skatt på vegne av deg.',
      'Du er selv ansvarlig for å vurdere om inntekter er skattepliktige og for å rapportere riktig.',
      'Rapporten er kun et hjelpedokument basert på fullførte og godkjente oppdrag i SmartHjelp.',
      'SmartHjelp gir ikke skatte-, juridisk eller regnskapsmessig rådgivning. '
          'Sjekk Skatteetaten eller kontakt regnskapsfører ved tvil.',
      'Dette er ikke skatterådgivning.',
      'Plattformavgift er 10 % (inkl. mva) og betales av oppdragsgiver.',
      'Dato = oppdragets opprettelsesdato (SmartHjelp lagrer ikke '
          'fullføringsdato i denne versjonen).',
    ];
    for (final n in disclaimers) {
      setCell(overview, 0, row, TextCellValue(n), style: footnoteStyle);
      overview.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
        CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: row),
      );
      row++;
    }

    // Kolonnebredder Oversikt
    overview.setColumnWidth(0, 36); // Etiketter / Oppdragsgiver-navn
    overview.setColumnWidth(1, 22);
    overview.setColumnWidth(2, 18);
    overview.setColumnWidth(3, 36); // Kontroll-tekst
    overview.setColumnWidth(4, 18);
    overview.setColumnWidth(5, 22);
    overview.setColumnWidth(6, 18);
    overview.setColumnWidth(7, 14);

    // ====================== TRANSAKSJONER ======================
    const txHeaders = [
      'Dato',
      'Type',
      'Status',
      'Kategori',
      'Tittel',
      'Sted',
      'Motpart',
      'Oppdragspris (kr)',
      'Plattformavgift (kr)',
      'Beløp (kr)',
    ];
    for (var i = 0; i < txHeaders.length; i++) {
      setCell(
        transactions,
        i,
        0,
        TextCellValue(txHeaders[i]),
        style: headerStyle,
      );
    }
    transactions.setRowHeight(0, 22);

    var txRow = 1;
    for (final entry in report.entries) {
      final signedAmount = entry.isIncome ? entry.amount : -entry.amount;
      final mpFallback = entry.isIncome
          ? 'Oppdragsgiver (ukjent navn)'
          : 'Oppdragstaker (ukjent navn)';
      final motpart =
          entry.counterpartyName.isEmpty ? mpFallback : entry.counterpartyName;
      setCell(transactions, 0, txRow, TextCellValue(dateFormat.format(entry.date)));
      setCell(transactions, 1, txRow, TextCellValue(entry.typeLabel));
      setCell(transactions, 2, txRow, TextCellValue('Fullført'));
      setCell(transactions, 3, txRow, TextCellValue(entry.category));
      setCell(transactions, 4, txRow, TextCellValue(entry.jobTitle));
      setCell(transactions, 5, txRow, TextCellValue(entry.locationName));
      setCell(transactions, 6, txRow, TextCellValue(motpart));
      setCell(transactions, 7, txRow, DoubleCellValue(entry.grossAmount), style: krStyle);
      setCell(transactions, 8, txRow, DoubleCellValue(entry.platformFee), style: krStyle);
      setCell(transactions, 9, txRow, DoubleCellValue(signedAmount), style: krStyle);
      txRow++;
    }

    // Totalrad — kolonner forskjøvet +1 pga Motpart-kolonnen.
    if (report.entries.isNotEmpty) {
      final totalGross =
          report.entries.fold<double>(0, (s, e) => s + e.grossAmount);
      final totalFee =
          report.entries.fold<double>(0, (s, e) => s + e.platformFee);
      final totalSigned = report.entries.fold<double>(
        0,
        (s, e) => s + (e.isIncome ? e.amount : -e.amount),
      );
      setCell(transactions, 0, txRow, TextCellValue('Sum'), style: totalsLabelStyle);
      for (var i = 1; i <= 6; i++) {
        setCell(transactions, i, txRow, TextCellValue(''), style: totalsLabelStyle);
      }
      setCell(transactions, 7, txRow, DoubleCellValue(totalGross), style: krTotalsStyle);
      setCell(transactions, 8, txRow, DoubleCellValue(totalFee), style: krTotalsStyle);
      setCell(transactions, 9, txRow, DoubleCellValue(totalSigned), style: krTotalsStyle);
    }

    // Kolonnebredder Transaksjoner
    transactions.setColumnWidth(0, 12); // Dato
    transactions.setColumnWidth(1, 12); // Type
    transactions.setColumnWidth(2, 12); // Status
    transactions.setColumnWidth(3, 14); // Kategori
    transactions.setColumnWidth(4, 32); // Tittel
    transactions.setColumnWidth(5, 16); // Sted
    transactions.setColumnWidth(6, 22); // Motpart
    transactions.setColumnWidth(7, 20); // Oppdragspris
    transactions.setColumnWidth(8, 22); // Plattformavgift
    transactions.setColumnWidth(9, 16); // Beløp

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