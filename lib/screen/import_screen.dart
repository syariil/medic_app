import 'package:flutter/material.dart';
import '../models/import_result.dart';
import '../services/import_service.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';

// ─── STATE MACHINE ────────────────────────────────────────────────────────────

enum _Step { idle, parsing, preview, importing, done }

// ─────────────────────────────────────────────────────────────────────────────

class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen>
    with SingleTickerProviderStateMixin {
  final _db = DatabaseService();

  _Step _step = _Step.idle;
  String? _filePath;
  String? _fileName;
  ImportResult? _result;
  ImportSummary? _summary;
  String? _errorMsg;
  bool _isDownloadingTemplate = false;

  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _pickAndParse() async {
    setState(() {
      _step = _Step.idle;
      _errorMsg = null;
    });

    final path = await ImportService.pickFile();
    if (path == null) return; // dibatalkan

    setState(() {
      _filePath = path;
      _fileName = path.split(RegExp(r'[/\\]')).last;
      _step = _Step.parsing;
    });

    final result = await ImportService.parseFile(path);

    if (result.isEmpty && result.globalErrors.isNotEmpty) {
      setState(() {
        _step = _Step.idle;
        _errorMsg = result.globalErrors.map((e) => e.message).join('\n');
      });
      return;
    }

    setState(() {
      _result = result;
      _step = _Step.preview;
    });
  }

  Future<void> _confirmImport() async {
    if (_result == null) return;
    setState(() => _step = _Step.importing);

    final summary = await ImportService.importToDb(_result!, _db);

    setState(() {
      _summary = summary;
      _step = _Step.done;
    });
  }

  void _reset() {
    setState(() {
      _step = _Step.idle;
      _filePath = null;
      _fileName = null;
      _result = null;
      _summary = null;
      _errorMsg = null;
    });
  }

  Future<void> _downloadTemplate() async {
    setState(() => _isDownloadingTemplate = true);
    final path = await ImportService.generateTemplate();
    setState(() => _isDownloadingTemplate = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          path != null ? 'Template disimpan:\n$path' : 'Gagal membuat template',
        ),
        backgroundColor: path != null ? AppTheme.accent : Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Import Data Excel',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Text(
                'Import pasien, dokter, dan obat dari file .xlsx',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
        // Tombol download template
        _isDownloadingTemplate
            ? const SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : OutlinedButton.icon(
                onPressed: _downloadTemplate,
                icon: const Icon(Icons.download_rounded, size: 16),
                label: const Text('Download Template'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primary,
                  side: const BorderSide(color: AppTheme.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
      ],
    );
  }

  Widget _buildBody() {
    switch (_step) {
      case _Step.idle:
        return _buildIdle();
      case _Step.parsing:
        return _buildParsing();
      case _Step.preview:
        return _buildPreview();
      case _Step.importing:
        return _buildImporting();
      case _Step.done:
        return _buildDone();
    }
  }

  // ── IDLE: pick file zone ───────────────────────────────────────────────────

  Widget _buildIdle() {
    return Column(
      children: [
        // Drag & drop zone (klik untuk browse)
        GestureDetector(
          onTap: _pickAndParse,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 48),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppTheme.cardShadow,
              border: Border.all(
                color: AppTheme.primary.withOpacity(0.2),
                width: 2,
                // dashed effect via padding + clip
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.upload_file_rounded,
                    size: 36,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Klik untuk memilih file Excel',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Format yang didukung: .xlsx, .xls',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ),

        if (_errorMsg != null) ...[
          const SizedBox(height: 16),
          _ErrorCard(message: _errorMsg!),
        ],

        const SizedBox(height: 24),

        // Panduan format
        _buildFormatGuide(),
      ],
    );
  }

  Widget _buildFormatGuide() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: AppTheme.primary,
              ),
              const SizedBox(width: 6),
              const Text(
                'Panduan Format File',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _SheetGuide(
            color: AppTheme.primary,
            sheetName: 'Sheet "Pasien"',
            columns: [
              'Nama*',
              'NIK* (16 digit)',
              'Tanggal',
              'Keluhan*',
              'Diagnosa*',
            ],
          ),
          const SizedBox(height: 10),
          _SheetGuide(
            color: AppTheme.accent,
            sheetName: 'Sheet "Dokter"',
            columns: ['Nama*', 'Spesialis*', 'Jadwal', 'Poli'],
          ),
          const SizedBox(height: 10),
          _SheetGuide(
            color: Colors.orange,
            sheetName: 'Sheet "Obat"',
            columns: ['Nama*', 'Kategori', 'Satuan', 'Stok', 'Keterangan'],
          ),
          const SizedBox(height: 12),
          Text(
            '* = wajib diisi',
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondary.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  // ── PARSING ───────────────────────────────────────────────────────────────

  Widget _buildParsing() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          const Text(
            'Membaca file Excel...',
            style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
          if (_fileName != null) ...[
            const SizedBox(height: 8),
            Text(
              _fileName!,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── PREVIEW ───────────────────────────────────────────────────────────────

  Widget _buildPreview() {
    final r = _result!;
    final pValid = r.patients.where((x) => x.isValid).length;
    final dValid = r.doctors.where((x) => x.isValid).length;
    final mValid = r.medicines.where((x) => x.isValid).length;
    final pInvalid = r.patients.where((x) => !x.isValid).length;
    final dInvalid = r.doctors.where((x) => !x.isValid).length;
    final mInvalid = r.medicines.where((x) => !x.isValid).length;

    return Column(
      children: [
        // File info + summary badges
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.insert_drive_file_rounded,
                    color: AppTheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _fileName ?? '',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _CountBadge(
                    label: 'Pasien valid',
                    count: pValid,
                    color: AppTheme.primary,
                  ),
                  _CountBadge(
                    label: 'Dokter valid',
                    count: dValid,
                    color: AppTheme.accent,
                  ),
                  _CountBadge(
                    label: 'Obat valid',
                    count: mValid,
                    color: Colors.orange,
                  ),
                  if (pInvalid + dInvalid + mInvalid > 0)
                    _CountBadge(
                      label: 'Tidak valid',
                      count: pInvalid + dInvalid + mInvalid,
                      color: Colors.red,
                    ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Tab bar
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: AppTheme.cardShadow,
          ),
          child: TabBar(
            controller: _tabCtrl,
            labelColor: AppTheme.primary,
            unselectedLabelColor: AppTheme.textSecondary,
            indicatorColor: AppTheme.primary,
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            tabs: [
              Tab(text: 'Pasien (${r.patients.length})'),
              Tab(text: 'Dokter (${r.doctors.length})'),
              Tab(text: 'Obat (${r.medicines.length})'),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: [
              _PatientPreviewTable(rows: r.patients),
              _DoctorPreviewTable(rows: r.doctors),
              _MedicinePreviewTable(rows: r.medicines),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Global errors jika ada
        if (r.globalErrors.isNotEmpty)
          _ErrorCard(
            message: r.globalErrors
                .map((e) => '${e.sheet}: ${e.message}')
                .join('\n'),
          ),

        const SizedBox(height: 12),

        // Action buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _reset,
                icon: const Icon(Icons.arrow_back_rounded, size: 16),
                label: const Text('Ganti File'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: r.totalValid == 0 ? null : _confirmImport,
                icon: const Icon(Icons.save_rounded, size: 18),
                label: Text('Import ${r.totalValid} Data'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── IMPORTING ─────────────────────────────────────────────────────────────

  Widget _buildImporting() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          const Text(
            'Menyimpan data ke database...',
            style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  // ── DONE ──────────────────────────────────────────────────────────────────

  Widget _buildDone() {
    final s = _summary!;
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon sukses
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.accent.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                size: 44,
                color: AppTheme.accent,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Import Selesai!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${s.total} data berhasil disimpan',
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),

            const SizedBox(height: 24),

            // Breakdown hasil
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Column(
                children: [
                  _ResultRow(
                    icon: Icons.people_alt_rounded,
                    color: AppTheme.primary,
                    label: 'Pasien',
                    count: s.patientsInserted,
                  ),
                  const Divider(height: 20),
                  _ResultRow(
                    icon: Icons.medical_information_rounded,
                    color: AppTheme.accent,
                    label: 'Dokter',
                    count: s.doctorsInserted,
                  ),
                  const Divider(height: 20),
                  _ResultRow(
                    icon: Icons.medication_rounded,
                    color: Colors.orange,
                    label: 'Obat',
                    count: s.medicinesInserted,
                  ),
                  if (s.skipped > 0) ...[
                    const Divider(height: 20),
                    _ResultRow(
                      icon: Icons.warning_rounded,
                      color: Colors.red,
                      label: 'Gagal disimpan',
                      count: s.skipped,
                    ),
                  ],
                ],
              ),
            ),

            // Error detail jika ada
            if (s.errors.isNotEmpty) ...[
              const SizedBox(height: 12),
              _ErrorCard(
                message:
                    s.errors.take(5).join('\n') +
                    (s.errors.length > 5
                        ? '\n... dan ${s.errors.length - 5} error lainnya'
                        : ''),
              ),
            ],

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _reset,
                icon: const Icon(Icons.upload_file_rounded, size: 18),
                label: const Text('Import File Lain'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── PREVIEW TABLES ───────────────────────────────────────────────────────────

class _PatientPreviewTable extends StatelessWidget {
  final List<ParsedRow> rows;
  const _PatientPreviewTable({required this.rows});

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const Center(
        child: Text(
          'Tidak ada data pasien di file ini',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      );
    }
    return _PreviewTableShell(
      headers: const [
        '#',
        'Status',
        'Nama',
        'NIK',
        'Tanggal',
        'Keluhan',
        'Diagnosa',
      ],
      flex: const [1, 2, 3, 3, 2, 3, 3],
      rows: rows,
      cellBuilder: (row) {
        final p = row.data;
        if (p == null) return ['${row.rowNumber}', '', '', '', '', '', ''];
        final pat = p as dynamic;
        return [
          '${row.rowNumber}',
          '',
          pat.nama,
          pat.nik,
          pat.tanggal,
          pat.keluhan,
          pat.diagnosa,
        ];
      },
    );
  }
}

class _DoctorPreviewTable extends StatelessWidget {
  final List<ParsedRow> rows;
  const _DoctorPreviewTable({required this.rows});

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const Center(
        child: Text(
          'Tidak ada data dokter di file ini',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      );
    }
    return _PreviewTableShell(
      headers: const ['#', 'Status', 'Nama', 'Spesialis', 'Jadwal', 'Poli'],
      flex: const [1, 2, 3, 3, 3, 2],
      rows: rows,
      cellBuilder: (row) {
        final d = row.data;
        if (d == null) return ['${row.rowNumber}', '', '', '', '', ''];
        final doc = d as dynamic;
        return [
          '${row.rowNumber}',
          '',
          doc.nama,
          doc.spesialis,
          doc.jadwal,
          doc.poli,
        ];
      },
    );
  }
}

class _MedicinePreviewTable extends StatelessWidget {
  final List<ParsedRow> rows;
  const _MedicinePreviewTable({required this.rows});

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const Center(
        child: Text(
          'Tidak ada data obat di file ini',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      );
    }
    return _PreviewTableShell(
      headers: const [
        '#',
        'Status',
        'Nama',
        'Kategori',
        'Satuan',
        'Stok',
        'Keterangan',
      ],
      flex: const [1, 2, 3, 2, 2, 1, 3],
      rows: rows,
      cellBuilder: (row) {
        final m = row.data;
        if (m == null) return ['${row.rowNumber}', '', '', '', '', '', ''];
        final med = m as dynamic;
        return [
          '${row.rowNumber}',
          '',
          med.nama,
          med.kategori,
          med.satuan,
          '${med.stok}',
          med.keterangan,
        ];
      },
    );
  }
}

// ─── GENERIC PREVIEW TABLE ────────────────────────────────────────────────────

class _PreviewTableShell extends StatelessWidget {
  final List<String> headers;
  final List<int> flex;
  final List<ParsedRow> rows;
  final List<String> Function(ParsedRow) cellBuilder;

  const _PreviewTableShell({
    required this.headers,
    required this.flex,
    required this.rows,
    required this.cellBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // Header
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primary.withOpacity(0.08),
                    AppTheme.primary.withOpacity(0.04),
                  ],
                ),
                border: Border(
                  bottom: BorderSide(color: AppTheme.primary.withOpacity(0.15)),
                ),
              ),
              child: IntrinsicHeight(
                child: Row(
                  children: List.generate(
                    headers.length,
                    (i) => Expanded(
                      flex: flex[i],
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 12,
                        ),
                        child: Text(
                          headers[i],
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Rows
            Expanded(
              child: ListView.builder(
                itemCount: rows.length,
                itemBuilder: (_, i) {
                  final row = rows[i];
                  final cells = cellBuilder(row);
                  final isEven = i % 2 == 0;

                  Color? rowColor;
                  if (row.status == RowStatus.invalid) {
                    rowColor = Colors.red.withOpacity(0.04);
                  } else if (row.status == RowStatus.warning) {
                    rowColor = Colors.orange.withOpacity(0.04);
                  } else {
                    rowColor = isEven ? Colors.white : const Color(0xFFFAFBFF);
                  }

                  return Container(
                    decoration: BoxDecoration(
                      color: rowColor,
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade100),
                      ),
                    ),
                    child: IntrinsicHeight(
                      child: Row(
                        children: List.generate(headers.length, (ci) {
                          // Kolom status (index 1)
                          if (ci == 1) {
                            return Expanded(
                              flex: flex[ci],
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 8,
                                ),
                                child: _StatusChip(row: row),
                              ),
                            );
                          }
                          return Expanded(
                            flex: flex[ci],
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 10,
                              ),
                              child: Text(
                                cells[ci],
                                style: TextStyle(
                                  fontSize: 11,
                                  color: row.status == RowStatus.invalid
                                      ? AppTheme.textSecondary
                                      : AppTheme.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── SMALL WIDGETS ────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final ParsedRow row;
  const _StatusChip({required this.row});

  @override
  Widget build(BuildContext context) {
    switch (row.status) {
      case RowStatus.valid:
        return _chip('Valid', Colors.green, Icons.check_rounded);
      case RowStatus.warning:
        return Tooltip(
          message: row.message ?? '',
          child: _chip('Warning', Colors.orange, Icons.warning_rounded),
        );
      case RowStatus.invalid:
        return Tooltip(
          message: row.message ?? '',
          child: _chip('Invalid', Colors.red, Icons.close_rounded),
        );
    }
  }

  Widget _chip(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _CountBadge({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$count ',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: color.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final int count;
  const _ResultRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
          ),
        ),
        Text(
          '$count data',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.red, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.red,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetGuide extends StatelessWidget {
  final Color color;
  final String sheetName;
  final List<String> columns;
  const _SheetGuide({
    required this.color,
    required this.sheetName,
    required this.columns,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 4,
          height: 4,
          margin: const EdgeInsets.only(top: 6, right: 8),
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textPrimary,
                height: 1.5,
              ),
              children: [
                TextSpan(
                  text: '$sheetName — ',
                  style: TextStyle(fontWeight: FontWeight.w700, color: color),
                ),
                TextSpan(
                  text: columns.join(', '),
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
