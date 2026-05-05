import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/patient.dart';
import '../services/database_service.dart';
import '../services/export_service.dart';
import '../theme/app_theme.dart';
import '../components/cards/stat_card.dart';
import '../components/cards/section_card.dart';
import '../components/cards/empty_state.dart';
import '../components/charts/diagnosis_legend.dart';

// ─── ENUM PRESET FILTER ───────────────────────────────────────────────────────

enum DateRangePreset {
  hari1('1 Hari', 1),
  hari3('3 Hari', 3),
  hari5('5 Hari', 5),
  minggu1('1 Minggu', 7),
  minggu2('2 Minggu', 14),
  bulan1('1 Bulan', 30),
  custom('Custom', 0);

  final String label;
  final int days;
  const DateRangePreset(this.label, this.days);
}

// ─── NAMA BULAN ───────────────────────────────────────────────────────────────

const _namaBulanPendek = [
  '',
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Ags',
  'Sep',
  'Okt',
  'Nov',
  'Des',
];
const _namaBulanPanjang = [
  '',
  'Januari',
  'Februari',
  'Maret',
  'April',
  'Mei',
  'Juni',
  'Juli',
  'Agustus',
  'September',
  'Oktober',
  'November',
  'Desember',
];

String _labelBulanPendek(String key) {
  final parts = key.split('-');
  final b = parts.length >= 2 ? (int.tryParse(parts[1]) ?? 0) : 0;
  return b > 0 && b <= 12 ? _namaBulanPendek[b] : key;
}

String _labelBulanPanjang(String key) {
  final parts = key.split('-');
  final b = parts.length >= 2 ? (int.tryParse(parts[1]) ?? 0) : 0;
  final t = parts.isNotEmpty ? parts[0] : '';
  return b > 0 && b <= 12 ? '${_namaBulanPanjang[b]} $t' : key;
}

// ─── HOME SCREEN ──────────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _db = DatabaseService();

  List<Patient> _allPatients = [];
  List<Patient> _filteredPatients = [];
  bool _isLoading = true;
  bool _isExporting = false;

  // Filter state
  DateRangePreset _preset = DateRangePreset.minggu1;
  DateTime? _customStart;
  DateTime? _customEnd;

  // ── Filter helpers ────────────────────────────────────────────────────────

  DateTime get _filterStart {
    if (_preset == DateRangePreset.custom && _customStart != null) {
      return _customStart!;
    }
    return DateTime.now().subtract(Duration(days: _preset.days - 1));
  }

  DateTime get _filterEnd {
    if (_preset == DateRangePreset.custom && _customEnd != null) {
      return _customEnd!;
    }
    return DateTime.now();
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/'
      '${d.year}';

  String get _filterLabel => '${_fmt(_filterStart)} – ${_fmt(_filterEnd)}';

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    _allPatients = await _db.getPatients();
    _applyFilter();
    setState(() => _isLoading = false);
  }

  void _applyFilter() {
    final s = _filterStart;
    final e = _filterEnd;
    _filteredPatients = _allPatients.where((p) {
      final d = DateTime.tryParse(p.tanggal);
      if (d == null) return false;
      final date = DateTime(d.year, d.month, d.day);
      return !date.isBefore(DateTime(s.year, s.month, s.day)) &&
          !date.isAfter(DateTime(e.year, e.month, e.day));
    }).toList();
  }

  void _selectPreset(DateRangePreset preset) {
    if (preset == DateRangePreset.custom) {
      _pickCustomRange();
      return;
    }
    setState(() {
      _preset = preset;
      _customStart = null;
      _customEnd = null;
      _applyFilter();
    });
  }

  Future<void> _pickCustomRange() async {
    final picked = await showDateRangePicker(
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
    if (picked != null) {
      setState(() {
        _preset = DateRangePreset.custom;
        _customStart = picked.start;
        _customEnd = picked.end;
        _applyFilter();
      });
    }
  }

  // ── Computed ──────────────────────────────────────────────────────────────

  Map<String, int> get _statistikDiagnosa {
    final m = <String, int>{};
    for (final p in _filteredPatients) {
      m[p.diagnosa] = (m[p.diagnosa] ?? 0) + 1;
    }
    return m;
  }

  Map<String, int> get _pasienPerHari {
    final m = <String, int>{};
    for (final p in _filteredPatients) {
      m[p.tanggal] = (m[p.tanggal] ?? 0) + 1;
    }
    return m;
  }

  Map<String, int> get _pasienPerBulan {
    final m = <String, int>{};
    for (final p in _filteredPatients) {
      final bulan = p.tanggal.length >= 7
          ? p.tanggal.substring(0, 7)
          : p.tanggal;
      m[bulan] = (m[bulan] ?? 0) + 1;
    }
    return m;
  }

  // SHORT COLOR
  final Map<String, Color> _diagnosisColorMap = {};
  int _colorIndex = 0;

  Color _getDiagnosisColor(String key) {
    if (!_diagnosisColorMap.containsKey(key)) {
      _diagnosisColorMap[key] =
          AppTheme.chartColors[_colorIndex % AppTheme.chartColors.length];
      _colorIndex++;
    }
    return _diagnosisColorMap[key]!;
  }

  // ── Charts ────────────────────────────────────────────────────────────────

  List<PieChartSectionData> get _pieData {
    final entries = _statistikDiagnosa.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final total = entries.fold(0, (a, b) => a + b.value);

    return List.generate(entries.length, (i) {
      final e = entries[i];

      final color = _getDiagnosisColor(e.key);

      final pct = e.value > 0
          ? (e.value / total * 100).toStringAsFixed(0)
          : '0';

      return PieChartSectionData(
        color: color,
        value: e.value.toDouble(),
        title: '$pct%',
        radius: 55,
        titleStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    });
  }

  Widget _buildLineChart() {
    final data = _pasienPerHari.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    if (data.isEmpty) {
      return const SizedBox(
        height: 160,
        child: EmptyState(message: 'Tidak ada data\npada rentang ini'),
      );
    }

    // 🔥 Cari nilai maksimum untuk scaling Y
    final maxY = data.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: 180,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: (maxY + 1).toDouble(),

          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: Colors.grey.shade100, strokeWidth: 1),
          ),

          borderData: FlBorderData(show: false),

          titlesData: FlTitlesData(
            // ─── X AXIS (TANGGAL) ─────────────────────────
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();

                  if (index < 0 || index >= data.length) {
                    return const SizedBox.shrink();
                  }

                  // 🔥 Batasi biar tidak tabrakan
                  if (data.length > 10 && index % 2 != 0) {
                    return const SizedBox.shrink();
                  }

                  final dateStr = data[index].key;
                  final date = DateTime.tryParse(dateStr);

                  if (date == null) return const SizedBox.shrink();

                  final label = '${date.day}/${date.month}';

                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 9,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  );
                },
              ),
            ),

            // ─── Y AXIS ───────────────────────────────────
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                reservedSize: 28,
                getTitlesWidget: (v, _) => Text(
                  v.toInt().toString(),
                  style: const TextStyle(
                    fontSize: 9,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ),

            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),

          lineBarsData: [
            LineChartBarData(
              isCurved: true,
              spots: List.generate(
                data.length,
                (i) => FlSpot(i.toDouble(), data[i].value.toDouble()),
              ),
              gradient: const LinearGradient(
                colors: [AppTheme.primary, Color(0xFF6366F1)],
              ),
              barWidth: 2.5,
              dotData: FlDotData(show: data.length <= 12),

              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primary.withOpacity(0.18),
                    AppTheme.primary.withOpacity(0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart() {
    final data = _pasienPerBulan.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    if (data.isEmpty) {
      return const SizedBox(
        height: 160,
        child: EmptyState(message: 'Tidak ada data\npada rentang ini'),
      );
    }

    final barWidth = data.length <= 4 ? 28.0 : (data.length <= 8 ? 20.0 : 14.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 160,
          child: BarChart(
            BarChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) =>
                    FlLine(color: Colors.grey.shade100, strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    getTitlesWidget: (v, _) {
                      final i = v.toInt();
                      if (i >= data.length) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          _labelBulanPendek(data[i].key),
                          style: const TextStyle(
                            fontSize: 9,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    getTitlesWidget: (v, _) => Text(
                      v.toInt().toString(),
                      style: const TextStyle(
                        fontSize: 9,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, _, rod, __) {
                    final i = group.x;
                    if (i >= data.length) return null;
                    return BarTooltipItem(
                      '${_labelBulanPanjang(data[i].key)}\n',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                      children: [
                        TextSpan(
                          text: '${rod.toY.toInt()} pasien',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              barGroups: List.generate(data.length, (i) {
                final color =
                    AppTheme.chartColors[i % AppTheme.chartColors.length];
                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: data[i].value.toDouble(),
                      gradient: LinearGradient(
                        colors: [color.withOpacity(0.75), color],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                      width: barWidth,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(5),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),

        // Legend
        const SizedBox(height: 12),
        _BarChartLegend(data: data),
      ],
    );
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _handleExport() async {
    setState(() => _isExporting = true);
    final path = await ExportService.exportToExcel(_filteredPatients);
    setState(() => _isExporting = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          path != null ? 'Berhasil disimpan: $path' : 'Gagal mengekspor data',
        ),
        backgroundColor: path != null ? AppTheme.accent : Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(20),
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                children: [
                  // Header
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Dashboard',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              'Ringkasan data pasien',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _isExporting
                          ? const SizedBox(
                              width: 36,
                              height: 36,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : IconButton.filled(
                              onPressed: _filteredPatients.isEmpty
                                  ? null
                                  : _handleExport,
                              icon: const Icon(Icons.download_rounded),
                              tooltip: 'Export Excel (data terfilter)',
                              style: IconButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                foregroundColor: Colors.white,
                              ),
                            ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ── DATE RANGE FILTER ─────────────────────────────────────
                  _DateRangeFilter(
                    selectedPreset: _preset,
                    filterLabel: _filterLabel,
                    onSelectPreset: _selectPreset,
                  ),

                  const SizedBox(height: 16),

                  // ── Stat Cards ────────────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          label: 'Pasien (filter)',
                          value: _filteredPatients.length.toString(),
                          icon: Icons.people_alt_rounded,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatCard(
                          label: 'Jenis Diagnosa',
                          value: _statistikDiagnosa.length.toString(),
                          icon: Icons.medical_services_rounded,
                          color: AppTheme.accent,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ── Charts Row 1: Pie + Line ──────────────────────────────
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: SectionCard(
                            title: 'Distribusi Diagnosa',
                            child: _statistikDiagnosa.isEmpty
                                ? const SizedBox(
                                    height: 160,
                                    child: EmptyState(
                                      message:
                                          'Tidak ada data\npada rentang ini',
                                    ),
                                  )
                                : Row(
                                    children: [
                                      SizedBox(
                                        height: 160,
                                        width: 160,
                                        child: PieChart(
                                          PieChartData(
                                            sections: _pieData,
                                            sectionsSpace: 3,
                                            centerSpaceRadius: 32,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 32),
                                      Expanded(
                                        child: SizedBox(
                                          height: 160,
                                          child: DiagnosisLegend(
                                            data: _statistikDiagnosa,
                                            getColor: _getDiagnosisColor,
                                          ),
                                        ),
                                      ),
                                      // DiagnosisLegend(data: _statistikDiagnosa),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SectionCard(
                            title: 'Tren Harian',
                            child: _buildLineChart(),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Charts Row 2: Bar + Slot ──────────────────────────────
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: SectionCard(
                            title: 'Kunjungan per Bulan',
                            child: _buildBarChart(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Slot kosong — ganti dengan chart berikutnya
                        Expanded(
                          child: SectionCard(
                            title: 'Chart Lainnya',
                            child: SizedBox(
                              height: 160,
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.add_chart_rounded,
                                      size: 36,
                                      color: AppTheme.textSecondary.withOpacity(
                                        0.25,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Tambahkan chart di sini',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textSecondary
                                            .withOpacity(0.45),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
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
}

// ─── DATE RANGE FILTER ────────────────────────────────────────────────────────

class _DateRangeFilter extends StatelessWidget {
  final DateRangePreset selectedPreset;
  final String filterLabel;
  final ValueChanged<DateRangePreset> onSelectPreset;

  const _DateRangeFilter({
    required this.selectedPreset,
    required this.filterLabel,
    required this.onSelectPreset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label baris atas
          Row(
            children: [
              const Icon(
                Icons.date_range_rounded,
                size: 15,
                color: AppTheme.primary,
              ),
              const SizedBox(width: 6),
              const Text(
                'Filter Periode',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  filterLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Preset chips — scrollable horizontal
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: DateRangePreset.values.map((preset) {
                final selected = selectedPreset == preset;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () => onSelectPreset(preset),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppTheme.primary
                            : AppTheme.primary.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected
                              ? AppTheme.primary
                              : AppTheme.primary.withOpacity(0.15),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (preset == DateRangePreset.custom)
                            Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Icon(
                                Icons.tune_rounded,
                                size: 12,
                                color: selected
                                    ? Colors.white
                                    : AppTheme.primary,
                              ),
                            ),
                          Text(
                            preset.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: selected ? Colors.white : AppTheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── BAR CHART LEGEND ─────────────────────────────────────────────────────────

class _BarChartLegend extends StatelessWidget {
  final List<MapEntry<String, int>> data;

  const _BarChartLegend({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();

    final total = data.fold(0, (sum, e) => sum + e.value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: const [
              SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Bulan',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              SizedBox(
                width: 60,
                child: Text(
                  'Pasien',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              SizedBox(
                width: 56,
                child: Text(
                  'Proporsi',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),

        Divider(height: 1, thickness: 1, color: Colors.grey.shade100),
        const SizedBox(height: 4),

        ...List.generate(data.length, (i) {
          final e = data[i];
          final color = AppTheme.chartColors[i % AppTheme.chartColors.length];
          final pct = total > 0
              ? (e.value / total * 100).toStringAsFixed(1)
              : '0.0';

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                // Color dot
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                // Label bulan
                Expanded(
                  child: Text(
                    _labelBulanPanjang(e.key),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Jumlah
                SizedBox(
                  width: 60,
                  child: Text(
                    '${e.value}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
                // Progress + persen
                SizedBox(
                  width: 56,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$pct%',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: total > 0 ? e.value / total : 0,
                          minHeight: 4,
                          backgroundColor: color.withOpacity(0.12),
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
