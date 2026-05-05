import 'package:flutter/material.dart';
import '../models/export_config.dart';
import '../services/export_service.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';

// ─── STATE MACHINE ────────────────────────────────────────────────────────────

enum _Step { config, exporting, done }

// ─────────────────────────────────────────────────────────────────────────────

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  final _db = DatabaseService();

  _Step _step = _Step.config;

  // Config state
  Set<ExportTable> _selectedTables = {
    ExportTable.patients,
    ExportTable.doctors,
    ExportTable.medicines,
    ExportTable.prescriptions,
  };
  ExportMode _mode = ExportMode.singleFile;
  bool _useFilter = false;
  DateTime _filterStart = DateTime.now().subtract(const Duration(days: 29));
  DateTime _filterEnd = DateTime.now();

  // Result
  ExportSummary? _summary;
  String? _errorMsg;

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/'
      '${d.year}';

  ExportConfig get _config => ExportConfig(
    tables: _selectedTables,
    mode: _mode,
    startDate: _useFilter ? _filterStart : null,
    endDate: _useFilter ? _filterEnd : null,
  );

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _pickDateRange() async {
    final r = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: DateTimeRange(start: _filterStart, end: _filterEnd),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppTheme.primary),
        ),
        child: child!,
      ),
    );
    if (r != null) {
      setState(() {
        _filterStart = r.start;
        _filterEnd = r.end;
      });
    }
  }

  Future<void> _startExport() async {
    if (_selectedTables.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih minimal satu tabel untuk diekspor'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _step = _Step.exporting;
      _errorMsg = null;
    });

    try {
      final summary = await ExportService.exportAll(_config, _db);
      setState(() {
        _summary = summary;
        _step = _Step.done;
      });
    } catch (e) {
      setState(() {
        _errorMsg = e.toString();
        _step = _Step.config;
      });
    }
  }

  void _reset() {
    setState(() {
      _step = _Step.config;
      _summary = null;
      _errorMsg = null;
    });
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
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Export Data',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        Text(
          'Ekspor semua data ke file Excel',
          style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  Widget _buildBody() {
    switch (_step) {
      case _Step.config:
        return _buildConfig();
      case _Step.exporting:
        return _buildExporting();
      case _Step.done:
        return _buildDone();
    }
  }

  // ── CONFIG ────────────────────────────────────────────────────────────────

  Widget _buildConfig() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 1. Pilih tabel ─────────────────────────────────────────────────
          _Card(
            title: 'Pilih Data yang Diekspor',
            icon: Icons.table_rows_rounded,
            child: Column(
              children: [
                // Select all toggle
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${_selectedTables.length} dari ${ExportTable.values.length} tabel dipilih',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() {
                        _selectedTables =
                            _selectedTables.length == ExportTable.values.length
                            ? {}
                            : {...ExportTable.values};
                      }),
                      child: Text(
                        _selectedTables.length == ExportTable.values.length
                            ? 'Batalkan Semua'
                            : 'Pilih Semua',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...ExportTable.values.map(
                  (t) => _TableToggle(
                    table: t,
                    selected: _selectedTables.contains(t),
                    onToggle: () => setState(() {
                      _selectedTables.contains(t)
                          ? _selectedTables.remove(t)
                          : _selectedTables.add(t);
                    }),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── 2. Mode output ─────────────────────────────────────────────────
          _Card(
            title: 'Mode Output',
            icon: Icons.folder_zip_rounded,
            child: Column(
              children: ExportMode.values.map((m) {
                final selected = _mode == m;
                return GestureDetector(
                  onTap: () => setState(() => _mode = m),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppTheme.primary.withOpacity(0.06)
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? AppTheme.primary.withOpacity(0.4)
                            : Colors.grey.shade200,
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          m == ExportMode.singleFile
                              ? Icons.description_rounded
                              : Icons.folder_rounded,
                          size: 20,
                          color: selected
                              ? AppTheme.primary
                              : AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                m.label,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: selected
                                      ? AppTheme.primary
                                      : AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                m == ExportMode.singleFile
                                    ? 'Semua tabel dalam satu file .xlsx, sheet terpisah'
                                    : 'Setiap tabel menghasilkan file .xlsx tersendiri',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (selected)
                          const Icon(
                            Icons.check_circle_rounded,
                            size: 20,
                            color: AppTheme.primary,
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 16),

          // ── 3. Filter tanggal ──────────────────────────────────────────────
          _Card(
            title: 'Filter Tanggal (Opsional)',
            icon: Icons.date_range_rounded,
            trailing: Switch(
              value: _useFilter,
              activeColor: AppTheme.primary,
              onChanged: (v) => setState(() => _useFilter = v),
            ),
            child: AnimatedCrossFade(
              duration: const Duration(milliseconds: 200),
              crossFadeState: _useFilter
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              firstChild: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hanya data dengan tanggal kunjungan/resep dalam rentang ini yang diekspor.',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _pickDateRange,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.primary.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            size: 16,
                            color: AppTheme.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '${_fmt(_filterStart)}  →  ${_fmt(_filterEnd)}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primary,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.edit_rounded,
                            size: 14,
                            color: AppTheme.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              secondChild: Text(
                'Aktifkan toggle untuk memfilter data berdasarkan tanggal.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary.withOpacity(0.6),
                ),
              ),
            ),
          ),

          if (_errorMsg != null) ...[
            const SizedBox(height: 12),
            _ErrorCard(message: _errorMsg!),
          ],

          const SizedBox(height: 24),

          // ── Tombol export ──────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _selectedTables.isEmpty ? null : _startExport,
              icon: const Icon(Icons.download_rounded, size: 20),
              label: Text(
                'Export ${_selectedTables.length} Tabel'
                '${_useFilter ? ' (${_fmt(_filterStart)} – ${_fmt(_filterEnd)})' : ' (Semua Data)'}',
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── EXPORTING ─────────────────────────────────────────────────────────────

  Widget _buildExporting() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              color: AppTheme.primary,
              backgroundColor: AppTheme.primary.withOpacity(0.12),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Sedang mengekspor data...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            [
              if (_selectedTables.contains(ExportTable.patients)) 'Pasien',
              if (_selectedTables.contains(ExportTable.doctors)) 'Dokter',
              if (_selectedTables.contains(ExportTable.medicines)) 'Obat',
              if (_selectedTables.contains(ExportTable.prescriptions)) 'Resep',
            ].join(' • '),
            style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  // ── DONE ──────────────────────────────────────────────────────────────────

  Widget _buildDone() {
    final s = _summary!;
    final hasError = s.hasError;
    final successFiles = s.files.where((f) => f.success).toList();
    final failFiles = s.files.where((f) => !f.success).toList();

    return SingleChildScrollView(
      child: Column(
        children: [
          // Result icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: (hasError ? Colors.orange : AppTheme.accent).withOpacity(
                0.12,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasError ? Icons.warning_rounded : Icons.check_circle_rounded,
              size: 44,
              color: hasError ? Colors.orange : AppTheme.accent,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            hasError ? 'Export Selesai dengan Peringatan' : 'Export Berhasil!',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${s.totalRows} baris diekspor dalam '
            '${s.duration.inMilliseconds < 1000 ? '${s.duration.inMilliseconds}ms' : '${(s.duration.inSeconds)}s'}',
            style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 24),

          // File list sukses
          if (successFiles.isNotEmpty) ...[
            _SectionLabel(label: 'File Tersimpan (${successFiles.length})'),
            const SizedBox(height: 8),
            ...successFiles.map((f) => _FileResultCard(file: f)),
            const SizedBox(height: 16),
          ],

          // File gagal
          if (failFiles.isNotEmpty) ...[
            _SectionLabel(
              label: 'Gagal (${failFiles.length})',
              color: Colors.red,
            ),
            const SizedBox(height: 8),
            ...failFiles.map((f) => _FileResultCard(file: f, isError: true)),
            const SizedBox(height: 16),
          ],

          // Tombol aksi
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _reset,
                  icon: const Icon(Icons.arrow_back_rounded, size: 16),
                  label: const Text('Export Lagi'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── REUSABLE WIDGETS ─────────────────────────────────────────────────────────

/// Card section container
class _Card extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  const _Card({
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: AppTheme.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

/// Toggle baris per tabel
class _TableToggle extends StatelessWidget {
  final ExportTable table;
  final bool selected;
  final VoidCallback onToggle;

  const _TableToggle({
    required this.table,
    required this.selected,
    required this.onToggle,
  });

  static const _icons = {
    ExportTable.patients: Icons.people_alt_rounded,
    ExportTable.doctors: Icons.medical_information_rounded,
    ExportTable.medicines: Icons.medication_rounded,
    ExportTable.prescriptions: Icons.receipt_long_rounded,
  };

  static const _colors = {
    ExportTable.patients: AppTheme.primary,
    ExportTable.doctors: AppTheme.accent,
    ExportTable.medicines: Colors.orange,
    ExportTable.prescriptions: Color(0xFF7E3AF2),
  };

  static const _desc = {
    ExportTable.patients:
        'Data kunjungan pasien (nama, NIK, tanggal, keluhan, diagnosa)',
    ExportTable.doctors: 'Data dokter (nama, spesialis, jadwal, poli)',
    ExportTable.medicines: 'Data stok obat (nama, kategori, satuan, stok)',
    ExportTable.prescriptions: 'Riwayat resep obat per pasien',
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[table]!;
    final icon = _icons[table]!;
    final desc = _desc[table]!;

    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.05) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color.withOpacity(0.35) : Colors.grey.shade200,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: (selected ? color : Colors.grey.shade400).withOpacity(
                  0.12,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 18,
                color: selected ? color : Colors.grey.shade400,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    table.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: selected ? color : AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    desc,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: selected ? color : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: selected ? color : Colors.grey.shade300,
                  width: 1.5,
                ),
              ),
              child: selected
                  ? const Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: Colors.white,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// Label section di halaman done
class _SectionLabel extends StatelessWidget {
  final String label;
  final Color? color;
  const _SectionLabel({required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: color ?? AppTheme.textPrimary,
        ),
      ),
    );
  }
}

/// Card satu file hasil export
class _FileResultCard extends StatelessWidget {
  final ExportFileResult file;
  final bool isError;
  const _FileResultCard({required this.file, this.isError = false});

  @override
  Widget build(BuildContext context) {
    final color = isError ? Colors.red : AppTheme.accent;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isError
                    ? Icons.error_outline_rounded
                    : Icons.insert_drive_file_rounded,
                size: 18,
                color: color,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  file.fileName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
              if (!isError)
                Text(
                  '${file.totalRows} baris',
                  style: TextStyle(
                    fontSize: 12,
                    color: color.withOpacity(0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),

          if (file.path != null) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.folder_open_rounded,
                  size: 14,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    file.path!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],

          // Sheet breakdown
          if (!isError && file.rowCounts.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: file.rowCounts.entries
                  .map(
                    (e) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${e.key}: ${e.value}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.accent,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],

          // Error message
          if (isError && file.error != null) ...[
            const SizedBox(height: 8),
            Text(
              file.error!,
              style: const TextStyle(fontSize: 11, color: Colors.red),
            ),
          ],
        ],
      ),
    );
  }
}

/// Error card kecil
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
