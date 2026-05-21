import 'package:flutter/material.dart';
import '../models/export_config.dart';
import '../services/export_service.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';

enum _Step { config, exporting, done }

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});
  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  final _db = DatabaseService();

  _Step _step = _Step.config;

  Set<ExportTable> _tables = {
    ExportTable.visits,
    ExportTable.visitPrescriptions,
    ExportTable.drugTests,
    ExportTable.fitToWork,
    ExportTable.fatigues,
    ExportTable.medicines,
  };
  ExportMode _mode = ExportMode.singleFile;
  ExportFormat _format = ExportFormat.excel;

  bool _useDate = false;
  DateTime _dateStart = DateTime.now().subtract(const Duration(days: 29));
  DateTime _dateEnd = DateTime.now();

  final _siteCtrl = TextEditingController();
  final _deptCtrl = TextEditingController();

  ExportSummary? _summary;
  String? _errorMsg;

  @override
  void dispose() {
    _siteCtrl.dispose();
    _deptCtrl.dispose();
    super.dispose();
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/'
      '${d.year}';

  ExportConfig get _config => ExportConfig(
    tables: _tables,
    mode: _mode,
    format: _format,
    startDate: _useDate ? _dateStart : null,
    endDate: _useDate ? _dateEnd : null,
    filterSite: _siteCtrl.text.trim().isEmpty ? null : _siteCtrl.text.trim(),
    filterDept: _deptCtrl.text.trim().isEmpty ? null : _deptCtrl.text.trim(),
  );

  Future<void> _pickDateRange() async {
    final r = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: DateTimeRange(start: _dateStart, end: _dateEnd),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppTheme.primary),
        ),
        child: child!,
      ),
    );
    if (r != null)
      setState(() {
        _dateStart = r.start;
        _dateEnd = r.end;
      });
  }

  Future<void> _startExport() async {
    if (_tables.isEmpty) {
      _showSnack('Pilih minimal satu tabel', Colors.orange);
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

  void _reset() => setState(() {
    _step = _Step.config;
    _summary = null;
    _errorMsg = null;
  });

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text(
              'Export Data',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const Text(
              'Ekspor data OH ke Excel atau CSV',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 24),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
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
        children: [
          // 1. Pilih tabel
          _Card(
            title: 'Pilih Data',
            icon: Icons.table_rows_rounded,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${_tables.length} dari ${ExportTable.values.length} dipilih',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(
                        () => _tables =
                            _tables.length == ExportTable.values.length
                            ? {}
                            : {...ExportTable.values},
                      ),
                      child: Text(
                        _tables.length == ExportTable.values.length
                            ? 'Batalkan Semua'
                            : 'Pilih Semua',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ...ExportTable.values.map(
                  (t) => _TableToggle(
                    table: t,
                    selected: _tables.contains(t),
                    onToggle: () => setState(
                      () => _tables.contains(t)
                          ? _tables.remove(t)
                          : _tables.add(t),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 2. Format file
          _Card(
            title: 'Format File',
            icon: Icons.insert_drive_file_rounded,
            child: Column(
              children: ExportFormat.values.map((f) {
                final sel = _format == f;
                return GestureDetector(
                  onTap: () => setState(() => _format = f),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: sel
                          ? AppTheme.primary.withOpacity(0.06)
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: sel
                            ? AppTheme.primary.withOpacity(0.4)
                            : Colors.grey.shade200,
                        width: sel ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          f == ExportFormat.excel
                              ? Icons.table_chart_rounded
                              : f == ExportFormat.csv
                              ? Icons.text_snippet_rounded
                              : Icons.layers_rounded,
                          size: 20,
                          color: sel
                              ? AppTheme.primary
                              : AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            f.label,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: sel
                                  ? AppTheme.primary
                                  : AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        if (sel)
                          const Icon(
                            Icons.check_circle_rounded,
                            size: 18,
                            color: AppTheme.primary,
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),

          // 3. Mode output
          _Card(
            title: 'Mode Output',
            icon: Icons.folder_zip_rounded,
            child: Column(
              children: ExportMode.values.map((m) {
                final sel = _mode == m;
                return GestureDetector(
                  onTap: () => setState(() => _mode = m),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: sel
                          ? AppTheme.accent.withOpacity(0.06)
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: sel
                            ? AppTheme.accent.withOpacity(0.4)
                            : Colors.grey.shade200,
                        width: sel ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          m == ExportMode.singleFile
                              ? Icons.description_rounded
                              : Icons.folder_rounded,
                          size: 20,
                          color: sel ? AppTheme.accent : AppTheme.textSecondary,
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
                                  color: sel
                                      ? AppTheme.accent
                                      : AppTheme.textPrimary,
                                ),
                              ),
                              Text(
                                m == ExportMode.singleFile
                                    ? 'Semua tabel dalam 1 file, sheet terpisah'
                                    : 'Setiap tabel jadi file tersendiri',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (sel)
                          Icon(
                            Icons.check_circle_rounded,
                            size: 18,
                            color: AppTheme.accent,
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),

          // 4. Filter
          _Card(
            title: 'Filter (Opsional)',
            icon: Icons.filter_list_rounded,
            child: Column(
              children: [
                // Filter tanggal
                Row(
                  children: [
                    Switch(
                      value: _useDate,
                      activeColor: AppTheme.primary,
                      onChanged: (v) => setState(() => _useDate = v),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Filter Tanggal',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),

                if (_useDate) ...[
                  const SizedBox(height: 8),
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
                              '${_fmt(_dateStart)}  →  ${_fmt(_dateEnd)}',
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
                  const SizedBox(height: 8),
                ],

                const Divider(height: 20),

                // Filter Site
                TextField(
                  controller: _siteCtrl,
                  decoration: InputDecoration(
                    labelText: 'Filter Site (opsional)',
                    hintText: 'Contoh: Site A',
                    prefixIcon: const Icon(Icons.location_on_rounded, size: 18),
                    suffixIcon: _siteCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, size: 16),
                            onPressed: () => setState(() => _siteCtrl.clear()),
                          )
                        : null,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),

                // Filter Departemen
                TextField(
                  controller: _deptCtrl,
                  decoration: InputDecoration(
                    labelText: 'Filter Departemen (opsional)',
                    hintText: 'Contoh: Tambang',
                    prefixIcon: const Icon(Icons.business_rounded, size: 18),
                    suffixIcon: _deptCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, size: 16),
                            onPressed: () => setState(() => _deptCtrl.clear()),
                          )
                        : null,
                  ),
                  onChanged: (_) => setState(() {}),
                ),

                // Filter summary
                if (_siteCtrl.text.isNotEmpty ||
                    _deptCtrl.text.isNotEmpty ||
                    _useDate) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          size: 14,
                          color: AppTheme.accent,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Filter aktif: ${[if (_useDate) '${_fmt(_dateStart)} – ${_fmt(_dateEnd)}', if (_siteCtrl.text.isNotEmpty) 'Site: ${_siteCtrl.text}', if (_deptCtrl.text.isNotEmpty) 'Dept: ${_deptCtrl.text}'].join(' | ')}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.accent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          if (_errorMsg != null) ...[
            const SizedBox(height: 12),
            _ErrorCard(message: _errorMsg!),
          ],

          const SizedBox(height: 20),

          // Tombol export
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _tables.isEmpty ? null : _startExport,
              icon: const Icon(Icons.download_rounded, size: 20),
              label: Text(
                'Export ${_tables.length} Tabel'
                '${_useDate ? " (${_fmt(_dateStart)} – ${_fmt(_dateEnd)})" : ""}',
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
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
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ── EXPORTING ─────────────────────────────────────────────────────────────

  Widget _buildExporting() => Center(
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
          'Mengekspor data...',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _tables.map((t) => t.label).join(' • '),
          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
      ],
    ),
  );

  // ── DONE ──────────────────────────────────────────────────────────────────

  Widget _buildDone() {
    final s = _summary!;
    final hasErr = s.hasError;
    final okFiles = s.files.where((f) => f.success).toList();
    final failFiles = s.files.where((f) => !f.success).toList();

    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: (hasErr ? Colors.orange : AppTheme.accent).withOpacity(
                0.12,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasErr ? Icons.warning_rounded : Icons.check_circle_rounded,
              size: 44,
              color: hasErr ? Colors.orange : AppTheme.accent,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            hasErr ? 'Export Selesai dengan Peringatan' : 'Export Berhasil!',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${s.totalRows} baris dalam '
            '${s.duration.inMilliseconds < 1000 ? "${s.duration.inMilliseconds}ms" : "${s.duration.inSeconds}s"}',
            style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 24),

          if (okFiles.isNotEmpty) ...[
            _sectionLabel('File Tersimpan (${okFiles.length})'),
            const SizedBox(height: 8),
            ...okFiles.map((f) => _FileCard(file: f)),
            const SizedBox(height: 16),
          ],
          if (failFiles.isNotEmpty) ...[
            _sectionLabel('Gagal (${failFiles.length})', color: Colors.red),
            const SizedBox(height: 8),
            ...failFiles.map((f) => _FileCard(file: f, isError: true)),
            const SizedBox(height: 16),
          ],

          SizedBox(
            width: double.infinity,
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
    );
  }

  Widget _sectionLabel(String text, {Color? color}) => Align(
    alignment: Alignment.centerLeft,
    child: Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: color ?? AppTheme.textPrimary,
      ),
    ),
  );
}

// ─── Widgets ──────────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _Card({required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) => Container(
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
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        child,
      ],
    ),
  );
}

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
    ExportTable.visits: Icons.local_hospital_rounded,
    ExportTable.visitPrescriptions: Icons.medication_rounded,
    ExportTable.drugTests: Icons.science_rounded,
    ExportTable.fitToWork: Icons.health_and_safety_rounded,
    ExportTable.fatigues: Icons.battery_alert_rounded,
    ExportTable.medicines: Icons.inventory_2_rounded,
  };
  static const _colors = {
    ExportTable.visits: AppTheme.primary,
    ExportTable.visitPrescriptions: AppTheme.accent,
    ExportTable.drugTests: Color(0xFF7E3AF2),
    ExportTable.fitToWork: Colors.green,
    ExportTable.fatigues: Colors.deepOrange,
    ExportTable.medicines: Colors.orange,
  };

  @override
  Widget build(BuildContext context) {
    final c = _colors[table]!;
    final icon = _icons[table]!;
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? c.withOpacity(0.05) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? c.withOpacity(0.35) : Colors.grey.shade200,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: (selected ? c : Colors.grey.shade400).withOpacity(0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(
                icon,
                size: 16,
                color: selected ? c : Colors.grey.shade400,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                table.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? c : AppTheme.textPrimary,
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: selected ? c : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: selected ? c : Colors.grey.shade300,
                  width: 1.5,
                ),
              ),
              child: selected
                  ? const Icon(
                      Icons.check_rounded,
                      size: 12,
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

class _FileCard extends StatelessWidget {
  final ExportFileResult file;
  final bool isError;
  const _FileCard({required this.file, this.isError = false});

  @override
  Widget build(BuildContext context) {
    final c = isError ? Colors.red : AppTheme.accent;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.withOpacity(0.2)),
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
                color: c,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  file.fileName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: c,
                  ),
                ),
              ),
              if (!isError)
                Text(
                  '${file.totalRows} baris',
                  style: TextStyle(
                    fontSize: 11,
                    color: c.withOpacity(0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          if (file.path != null) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.folder_open_rounded,
                  size: 13,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    file.path!,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppTheme.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          if (!isError && file.rowCounts.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: file.rowCounts.entries
                  .map(
                    (e) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${e.key}: ${e.value}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.accent,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          if (isError && file.error != null) ...[
            const SizedBox(height: 6),
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

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});
  @override
  Widget build(BuildContext context) => Container(
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
