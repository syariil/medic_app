import 'package:flutter/material.dart';
import '../models/import_result.dart';
import '../services/import_service.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';

enum _Step { idle, parsing, preview, importing, done }

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

  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _pickAndParse() async {
    setState(() {
      _step = _Step.idle;
      _errorMsg = null;
    });
    final path = await ImportService.pickFile();
    if (path == null) return;

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

  void _reset() => setState(() {
    _step = _Step.idle;
    _filePath = null;
    _fileName = null;
    _result = null;
    _summary = null;
    _errorMsg = null;
  });

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
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          Expanded(child: _buildBody()),
        ],
      ),
    ),
  );

  Widget _buildHeader() => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Import Data Excel',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            Text(
              'Import Kunjungan, Narkoba, FTW, Fatigue & Obat',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
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

  // ── IDLE ──────────────────────────────────────────────────────────────────

  Widget _buildIdle() => Column(
    children: [
      GestureDetector(
        onTap: _pickAndParse,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 44),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppTheme.cardShadow,
            border: Border.all(
              color: AppTheme.primary.withOpacity(0.2),
              width: 2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.upload_file_rounded,
                  size: 34,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Klik untuk memilih file Excel',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Format: .xlsx / .xls',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      ),

      if (_errorMsg != null) ...[
        const SizedBox(height: 14),
        _ErrCard(message: _errorMsg!),
      ],
      const SizedBox(height: 20),

      // Format guide
      Container(
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
              children: const [
                Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: AppTheme.primary,
                ),
                SizedBox(width: 6),
                Text(
                  'Panduan Format Sheet',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...[
              (
                'Kunjungan',
                AppTheme.primary,
                'Tanggal*, Site*, Nama*, Posisi, Departemen, Keluhan, Diagnosa, Jam Tidur, Suhu, TD, Pernapasan, Nadi',
              ),
              (
                'Tes Narkoba',
                const Color(0xFF7E3AF2),
                'Tanggal*, Site*, Nama*, Posisi, Departemen, AMP, MET, THC, COC, BZO, Hasil',
              ),
              (
                'Fit To Work',
                Colors.green,
                'Tanggal*, Site*, Nama*, Posisi, Departemen, Lokasi, Shift, Jam Tidur, Jam Masuk, Tidur≤6jam, Kesehatan, Minum Obat, Pembatasan',
              ),
              (
                'Fatigue',
                Colors.deepOrange,
                'Tanggal*, Site*, Nama*, Posisi, Departemen, Shift, Jam Tidur, TD, Nadi, Pernapasan, Suhu, Obat, Efek, Kriteria, Pembatasan',
              ),
              (
                'Obat',
                Colors.orange,
                'Nama*, Kategori, Satuan, Stok, Keterangan',
              ),
            ].map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 4,
                      height: 4,
                      margin: const EdgeInsets.only(top: 6, right: 8),
                      decoration: BoxDecoration(
                        color: item.$2,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textPrimary,
                            height: 1.4,
                          ),
                          children: [
                            TextSpan(
                              text: 'Sheet "${item.$1}" — ',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: item.$2,
                              ),
                            ),
                            TextSpan(
                              text: item.$3,
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '* = wajib diisi',
              style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    ],
  );

  // ── PARSING ───────────────────────────────────────────────────────────────

  Widget _buildParsing() => Center(
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

  // ── PREVIEW ───────────────────────────────────────────────────────────────

  Widget _buildPreview() {
    final r = _result!;
    final counts = [
      r.visits.length,
      r.drugTests.length,
      r.fitToWorks.length,
      r.fatigues.length,
      r.medicines.length,
    ];
    final labels = ['Kunjungan', 'Narkoba', 'FTW', 'Fatigue', 'Obat'];
    final colors = [
      AppTheme.primary,
      const Color(0xFF7E3AF2),
      Colors.green,
      Colors.deepOrange,
      Colors.orange,
    ];

    return Column(
      children: [
        // Summary + badges
        Container(
          padding: const EdgeInsets.all(14),
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
                    size: 18,
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
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  ...List.generate(
                    5,
                    (i) => counts[i] > 0
                        ? _Badge(
                            label: '${labels[i]} (${counts[i]})',
                            color: colors[i],
                          )
                        : const SizedBox.shrink(),
                  ),
                  if (r.totalInvalid > 0)
                    _Badge(
                      label: '${r.totalInvalid} invalid',
                      color: Colors.red,
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Tabs
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: AppTheme.cardShadow,
          ),
          child: TabBar(
            controller: _tabs,
            labelColor: AppTheme.primary,
            unselectedLabelColor: AppTheme.textSecondary,
            indicatorColor: AppTheme.primary,
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            tabs: [
              Tab(text: 'Kunjungan (${r.visits.length})'),
              Tab(text: 'Narkoba (${r.drugTests.length})'),
              Tab(text: 'FTW (${r.fitToWorks.length})'),
              Tab(text: 'Fatigue (${r.fatigues.length})'),
              Tab(text: 'Obat (${r.medicines.length})'),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Tab views
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              _PreviewTable(
                rows: r.visits,
                headers: const [
                  '#',
                  'Status',
                  'Tanggal',
                  'Site',
                  'Nama',
                  'Dept.',
                  'Keluhan',
                  'Diagnosa',
                ],
                cellFn: (row) {
                  final v = row.data as dynamic;
                  return [
                    '${row.rowNumber}',
                    '',
                    v?.tanggal ?? '',
                    v?.site ?? '',
                    v?.nama ?? '',
                    v?.departemen ?? '',
                    v?.keluhan ?? '',
                    v?.diagnosa ?? '',
                  ];
                },
              ),
              _PreviewTable(
                rows: r.drugTests,
                headers: const [
                  '#',
                  'Status',
                  'Tanggal',
                  'Site',
                  'Nama',
                  'Dept.',
                  'Hasil',
                ],
                cellFn: (row) {
                  final d = row.data as dynamic;
                  return [
                    '${row.rowNumber}',
                    '',
                    d?.tanggal ?? '',
                    d?.site ?? '',
                    d?.nama ?? '',
                    d?.departemen ?? '',
                    d?.hasil ?? '',
                  ];
                },
              ),
              _PreviewTable(
                rows: r.fitToWorks,
                headers: const [
                  '#',
                  'Status',
                  'Tanggal',
                  'Site',
                  'Nama',
                  'Shift',
                  'Kesehatan',
                  'Status Fit',
                ],
                cellFn: (row) {
                  final f = row.data as dynamic;
                  final fit = f != null ? (f.isFit ? 'FIT' : 'NOT FIT') : '';
                  return [
                    '${row.rowNumber}',
                    '',
                    f?.tanggal ?? '',
                    f?.site ?? '',
                    f?.nama ?? '',
                    f?.shift ?? '',
                    f?.kesehatan ?? '',
                    fit,
                  ];
                },
              ),
              _PreviewTable(
                rows: r.fatigues,
                headers: const [
                  '#',
                  'Status',
                  'Tanggal',
                  'Site',
                  'Nama',
                  'Shift',
                  'Kriteria',
                ],
                cellFn: (row) {
                  final f = row.data as dynamic;
                  return [
                    '${row.rowNumber}',
                    '',
                    f?.tanggal ?? '',
                    f?.site ?? '',
                    f?.nama ?? '',
                    f?.shift ?? '',
                    f?.kriteria ?? '',
                  ];
                },
              ),
              _PreviewTable(
                rows: r.medicines,
                headers: const [
                  '#',
                  'Status',
                  'Nama',
                  'Kategori',
                  'Satuan',
                  'Stok',
                ],
                cellFn: (row) {
                  final m = row.data as dynamic;
                  return [
                    '${row.rowNumber}',
                    '',
                    m?.nama ?? '',
                    m?.kategori ?? '',
                    m?.satuan ?? '',
                    '${m?.stok ?? 0}',
                  ];
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Global errors
        if (r.globalErrors.isNotEmpty) ...[
          _ErrCard(
            message: r.globalErrors
                .map((e) => '${e.sheet}: ${e.message}')
                .join('\n'),
          ),
          const SizedBox(height: 8),
        ],

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

  Widget _buildImporting() => const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(),
        SizedBox(height: 16),
        Text(
          'Menyimpan ke database...',
          style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
        ),
      ],
    ),
  );

  // ── DONE ──────────────────────────────────────────────────────────────────

  Widget _buildDone() {
    final s = _summary!;
    return SingleChildScrollView(
      child: Column(
        children: [
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
            style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 24),

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
                  Icons.local_hospital_rounded,
                  AppTheme.primary,
                  'Kunjungan',
                  s.visitsInserted,
                ),
                const Divider(height: 18),
                _ResultRow(
                  Icons.science_rounded,
                  const Color(0xFF7E3AF2),
                  'Tes Narkoba',
                  s.drugTestsInserted,
                ),
                const Divider(height: 18),
                _ResultRow(
                  Icons.health_and_safety_rounded,
                  Colors.green,
                  'Fit To Work',
                  s.fitToWorksInserted,
                ),
                const Divider(height: 18),
                _ResultRow(
                  Icons.battery_alert_rounded,
                  Colors.deepOrange,
                  'Fatigue',
                  s.fatiguesInserted,
                ),
                const Divider(height: 18),
                _ResultRow(
                  Icons.inventory_2_rounded,
                  Colors.orange,
                  'Obat',
                  s.medicinesInserted,
                ),
                if (s.skipped > 0) ...[
                  const Divider(height: 18),
                  _ResultRow(
                    Icons.warning_rounded,
                    Colors.red,
                    'Gagal/Skip',
                    s.skipped,
                  ),
                ],
              ],
            ),
          ),

          if (s.errors.isNotEmpty) ...[
            const SizedBox(height: 12),
            _ErrCard(
              message:
                  s.errors.take(5).join('\n') +
                  (s.errors.length > 5
                      ? '\n...dan ${s.errors.length - 5} error lainnya'
                      : ''),
            ),
          ],
          const SizedBox(height: 20),

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
    );
  }
}

// ─── Preview table ────────────────────────────────────────────────────────────

class _PreviewTable extends StatelessWidget {
  final List<ParsedRow> rows;
  final List<String> headers;
  final List<String> Function(ParsedRow) cellFn;

  const _PreviewTable({
    required this.rows,
    required this.headers,
    required this.cellFn,
  });

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty)
      return const Center(
        child: Text(
          'Tidak ada data pada sheet ini',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppTheme.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
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
              child: Row(
                children: headers
                    .asMap()
                    .entries
                    .map(
                      (e) => Expanded(
                        flex: e.key == 0
                            ? 3
                            : e.key == 1
                            ? 4
                            : 8,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 10,
                          ),
                          child: Text(
                            e.value,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            // Rows
            Expanded(
              child: ListView.builder(
                itemCount: rows.length,
                itemBuilder: (_, i) {
                  final row = rows[i];
                  final cells = cellFn(row);
                  final isEven = i % 2 == 0;

                  Color bg;
                  if (row.status == RowStatus.invalid)
                    bg = Colors.red.withOpacity(0.04);
                  else if (row.status == RowStatus.warning)
                    bg = Colors.orange.withOpacity(0.04);
                  else
                    bg = isEven ? Colors.white : const Color(0xFFFAFBFF);

                  return Container(
                    decoration: BoxDecoration(
                      color: bg,
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade100),
                      ),
                    ),
                    child: Row(
                      children: cells.asMap().entries.map((e) {
                        if (e.key == 1) {
                          return Expanded(
                            flex: 4,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 8,
                              ),
                              child: _StatusChip(row: row),
                            ),
                          );
                        }
                        return Expanded(
                          flex: e.key == 0 ? 3 : 8,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 9,
                            ),
                            child: Text(
                              e.value,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        );
                      }).toList(),
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

// ─── Small widgets ────────────────────────────────────────────────────────────

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
          child: _chip('Warn', Colors.orange, Icons.warning_rounded),
        );
      case RowStatus.invalid:
        return Tooltip(
          message: row.message ?? '',
          child: _chip('Error', Colors.red, Icons.close_rounded),
        );
    }
  }

  Widget _chip(String label, Color c, IconData icon) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
    decoration: BoxDecoration(
      color: c.withOpacity(0.1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: c.withOpacity(0.3)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 9, color: c),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: c),
        ),
      ],
    ),
  );
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.2)),
    ),
    child: Text(
      label,
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
    ),
  );
}

class _ResultRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final int count;
  const _ResultRow(this.icon, this.color, this.label, this.count);
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
        ),
      ),
      Text(
        '$count data',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    ],
  );
}

class _ErrCard extends StatelessWidget {
  final String message;
  const _ErrCard({required this.message});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.red.withOpacity(0.05),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.red.withOpacity(0.2)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.error_outline_rounded, color: Colors.red, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.red,
              height: 1.5,
            ),
          ),
        ),
      ],
    ),
  );
}
