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

// ─── Preset filter ────────────────────────────────────────────────────────────

enum _Preset { h1, h3, h5, w1, w2, m1, custom }

extension _PresetX on _Preset {
  String get label => const {
    _Preset.h1: '1 Hari',
    _Preset.h3: '3 Hari',
    _Preset.h5: '5 Hari',
    _Preset.w1: '1 Minggu',
    _Preset.w2: '2 Minggu',
    _Preset.m1: '1 Bulan',
    _Preset.custom: 'Custom',
  }[this]!;

  int get days => const {
    _Preset.h1: 1,
    _Preset.h3: 3,
    _Preset.h5: 5,
    _Preset.w1: 7,
    _Preset.w2: 14,
    _Preset.m1: 30,
    _Preset.custom: 0,
  }[this]!;
}

// ─── Helpers bulan ────────────────────────────────────────────────────────────

const _bulanPendek = [
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
const _bulanPanjang = [
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

String _shortMonth(String key) {
  final p = key.split('-');
  final b = p.length >= 2 ? (int.tryParse(p[1]) ?? 0) : 0;
  return b > 0 && b <= 12 ? _bulanPendek[b] : key;
}

String _longMonth(String key) {
  final p = key.split('-');
  final b = p.length >= 2 ? (int.tryParse(p[1]) ?? 0) : 0;
  final t = p.isNotEmpty ? p[0] : '';
  return b > 0 && b <= 12 ? '${_bulanPanjang[b]} $t' : key;
}

// ─── SCREEN ───────────────────────────────────────────────────────────────────

class PatientDashboardScreen extends StatefulWidget {
  const PatientDashboardScreen({super.key});

  @override
  State<PatientDashboardScreen> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboardScreen> {
  final _db = DatabaseService();

  List<Patient> _all = [], _filtered = [];
  bool _isLoading = true, _isExporting = false;

  _Preset _preset = _Preset.w1;
  DateTime? _cStart, _cEnd;

  // ── Warna diagnosa konsisten antara pie & legend ──────────────────────────
  final Map<String, Color> _colorMap = {};
  int _colorIdx = 0;

  Color _colorFor(String key) {
    return _colorMap.putIfAbsent(key, () {
      final c = AppTheme.chartColors[_colorIdx % AppTheme.chartColors.length];
      _colorIdx++;
      return c;
    });
  }

  // ── Filter ────────────────────────────────────────────────────────────────

  DateTime get _start {
    if (_preset == _Preset.custom && _cStart != null) return _cStart!;
    return DateTime.now().subtract(Duration(days: _preset.days - 1));
  }

  DateTime get _end {
    if (_preset == _Preset.custom && _cEnd != null) return _cEnd!;
    return DateTime.now();
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/'
      '${d.year}';

  String get _filterLabel => '${_fmt(_start)} – ${_fmt(_end)}';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    _all = await _db.getPatients();
    _applyFilter();
    setState(() => _isLoading = false);
  }

  void _applyFilter() {
    final s = _start;
    final e = _end;
    _filtered = _all.where((p) {
      final d = DateTime.tryParse(p.tanggal);
      if (d == null) return false;
      final date = DateTime(d.year, d.month, d.day);
      return !date.isBefore(DateTime(s.year, s.month, s.day)) &&
          !date.isAfter(DateTime(e.year, e.month, e.day));
    }).toList();
  }

  void _selectPreset(_Preset p) {
    if (p == _Preset.custom) {
      _pickCustom();
      return;
    }
    setState(() {
      _preset = p;
      _cStart = null;
      _cEnd = null;
      _applyFilter();
    });
  }

  Future<void> _pickCustom() async {
    final r = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: DateTimeRange(start: _start, end: _end),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppTheme.primary),
        ),
        child: child!,
      ),
    );
    if (r != null) {
      setState(() {
        _preset = _Preset.custom;
        _cStart = r.start;
        _cEnd = r.end;
        _applyFilter();
      });
    }
  }

  // ── Computed ──────────────────────────────────────────────────────────────

  Map<String, int> get _statDiagnosa {
    final m = <String, int>{};
    for (final p in _filtered) {
      m[p.diagnosa] = (m[p.diagnosa] ?? 0) + 1;
    }
    return m;
  }

  Map<String, int> get _perHari {
    final m = <String, int>{};
    for (final p in _filtered) {
      m[p.tanggal] = (m[p.tanggal] ?? 0) + 1;
    }
    return m;
  }

  Map<String, int> get _perBulan {
    final m = <String, int>{};
    for (final p in _filtered) {
      final b = p.tanggal.length >= 7 ? p.tanggal.substring(0, 7) : p.tanggal;
      m[b] = (m[b] ?? 0) + 1;
    }
    return m;
  }

  // ── Charts ────────────────────────────────────────────────────────────────

  /// Pie — pakai _colorFor agar warna sama dengan legend
  List<PieChartSectionData> get _pieData {
    final data = _statDiagnosa;
    final entries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = entries.fold(0, (a, b) => a + b.value);

    return entries.map((e) {
      final color = _colorFor(e.key);
      final pct = total > 0 ? (e.value / total * 100).toStringAsFixed(0) : '0';
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
    }).toList();
  }

  /// Line chart — X-axis tampilkan tanggal, skip label jika terlalu rapat
  Widget _lineChart() {
    final data = _perHari.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    if (data.isEmpty) {
      return const SizedBox(
        height: 160,
        child: EmptyState(message: 'Tidak ada data\npada rentang ini'),
      );
    }

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
            // X-axis: tanggal dd/mm
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                reservedSize: 30,
                getTitlesWidget: (value, _) {
                  final index = value.toInt();
                  if (index < 0 || index >= data.length) {
                    return const SizedBox.shrink();
                  }
                  // Skip label ganjil jika data > 10 agar tidak tabrakan
                  if (data.length > 10 && index % 2 != 0) {
                    return const SizedBox.shrink();
                  }
                  final date = DateTime.tryParse(data[index].key);
                  if (date == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '${date.day}/${date.month}',
                      style: const TextStyle(
                        fontSize: 9,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  );
                },
              ),
            ),
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
                    AppTheme.primary.withOpacity(0),
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

  Widget _barChart() {
    final data = _perBulan.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    if (data.isEmpty) {
      return const SizedBox(
        height: 160,
        child: EmptyState(message: 'Tidak ada data\npada rentang ini'),
      );
    }

    final bw = data.length <= 4 ? 28.0 : (data.length <= 8 ? 20.0 : 14.0);

    return Column(
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
                          _shortMonth(data[i].key),
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
                  getTooltipItem: (g, _, rod, __) => g.x >= data.length
                      ? null
                      : BarTooltipItem(
                          '${_longMonth(data[g.x].key)}\n',
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
                        ),
                ),
              ),
              barGroups: List.generate(data.length, (i) {
                final c = AppTheme.chartColors[i % AppTheme.chartColors.length];
                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: data[i].value.toDouble(),
                      gradient: LinearGradient(
                        colors: [c.withOpacity(0.75), c],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                      width: bw,
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
        const SizedBox(height: 12),
        _BarLegend(data: data),
      ],
    );
  }

  // ── Export ────────────────────────────────────────────────────────────────

  Future<void> _export() async {
    setState(() => _isExporting = true);
    final path = await ExportService.exportToExcel(_filtered);
    setState(() => _isExporting = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(path != null ? 'Disimpan: $path' : 'Gagal export'),
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
              onRefresh: _load,
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
                              'Dashboard Pasien',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              'Analitik data kunjungan',
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
                              onPressed: _filtered.isEmpty ? null : _export,
                              icon: const Icon(Icons.download_rounded),
                              tooltip: 'Export Excel',
                              style: IconButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                foregroundColor: Colors.white,
                              ),
                            ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Filter
                  _FilterBar(
                    selected: _preset,
                    label: _filterLabel,
                    onSelect: _selectPreset,
                  ),
                  const SizedBox(height: 16),

                  // Stats
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          label: 'Pasien (filter)',
                          value: '${_filtered.length}',
                          icon: Icons.people_alt_rounded,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatCard(
                          label: 'Jenis Diagnosa',
                          value: '${_statDiagnosa.length}',
                          icon: Icons.medical_services_rounded,
                          color: AppTheme.accent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Row 1: Pie + Line
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: SectionCard(
                            title: 'Distribusi Diagnosa',
                            child: _statDiagnosa.isEmpty
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
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: SizedBox(
                                          height: 160,
                                          child: DiagnosisLegend(
                                            data: _statDiagnosa,
                                            // ✅ pakai _colorFor agar warna pie = legend
                                            getColor: _colorFor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SectionCard(
                            title: 'Tren Harian',
                            child: _lineChart(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // const SizedBox(height: 0),

                  // Row 2: Bar + Top Diagnosa
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: SectionCard(
                            title: 'Kunjungan per Bulan',
                            child: _barChart(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SectionCard(
                            title: 'Top Diagnosa',
                            child: _TopDiagnosaChart(
                              data: _statDiagnosa,
                              getColor: _colorFor,
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

// ─── Filter Bar ───────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  final _Preset selected;
  final String label;
  final ValueChanged<_Preset> onSelect;

  const _FilterBar({
    required this.selected,
    required this.label,
    required this.onSelect,
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
                  label,
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
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _Preset.values.map((p) {
                final sel = selected == p;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () => onSelect(p),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: sel
                            ? AppTheme.primary
                            : AppTheme.primary.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: sel
                              ? AppTheme.primary
                              : AppTheme.primary.withOpacity(0.15),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (p == _Preset.custom)
                            Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Icon(
                                Icons.tune_rounded,
                                size: 12,
                                color: sel ? Colors.white : AppTheme.primary,
                              ),
                            ),
                          Text(
                            p.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: sel ? Colors.white : AppTheme.primary,
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

// ─── Bar Legend ───────────────────────────────────────────────────────────────

class _BarLegend extends StatelessWidget {
  final List<MapEntry<String, int>> data;
  const _BarLegend({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();
    final total = data.fold(0, (s, e) => s + e.value);
    return Column(
      children: [
        Row(
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
        Divider(height: 1, color: Colors.grey.shade100),
        const SizedBox(height: 4),
        ...List.generate(data.length, (i) {
          final e = data[i];
          final c = AppTheme.chartColors[i % AppTheme.chartColors.length];
          final pct = total > 0
              ? (e.value / total * 100).toStringAsFixed(1)
              : '0.0';
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: c, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _longMonth(e.key),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(
                  width: 60,
                  child: Text(
                    '${e.value}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: c,
                    ),
                  ),
                ),
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
                          backgroundColor: c.withOpacity(0.12),
                          valueColor: AlwaysStoppedAnimation(c),
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

// ─── Top Diagnosa ─────────────────────────────────────────────────────────────

class _TopDiagnosaChart extends StatelessWidget {
  final Map<String, int> data;
  final Color Function(String) getColor;

  const _TopDiagnosaChart({required this.data, required this.getColor});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const SizedBox(
        height: 160,
        child: EmptyState(message: 'Tidak ada data'),
      );
    }
    final sorted = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(5).toList();
    final max = top.first.value.toDouble();

    return Column(
      children: List.generate(top.length, (i) {
        final e = top[i];
        final c = getColor(e.key); // ✅ warna konsisten dengan pie
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            children: [
              SizedBox(
                width: 80,
                child: Text(
                  e.key,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: max > 0 ? e.value / max : 0,
                    minHeight: 10,
                    backgroundColor: c.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation(c),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${e.value}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: c,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
