import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/visit.dart';
import '../models/drug_test.dart';
import '../models/fit_to_work.dart';
import '../models/fatigue.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../components/cards/section_card.dart';
import '../components/cards/empty_state.dart';
import '../components/oh_shared.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _OhDashboardState();
}

class _OhDashboardState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  final _db = DatabaseService();
  late TabController _tabs;

  List<Visit> _visits = [];
  List<DrugTest> _drugs = [];
  List<FitToWork> _ftws = [];
  List<Fatigue> _fatigues = [];
  Map<String, int> _visitMedUsage = {};

  bool _isLoading = true;

  DateTime _start = DateTime.now().subtract(const Duration(days: 29));
  DateTime _end = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  String _fmtDb(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final s = _fmtDb(_start);
    final e = _fmtDb(_end);

    final results = await Future.wait([
      _db.getVisitsByDateRange(s, e),
      _db.getDrugTestsByDateRange(s, e),
      _db.getFitToWorksByDateRange(s, e),
      _db.getFatiguesByDateRange(s, e),
      _db.getVisitMedicineUsageStat(startDate: s, endDate: e),
    ]);

    setState(() {
      _visits = results[0] as List<Visit>;
      _drugs = results[1] as List<DrugTest>;
      _ftws = results[2] as List<FitToWork>;
      _fatigues = results[3] as List<Fatigue>;
      _visitMedUsage = results[4] as Map<String, int>;
      _isLoading = false;
    });
  }

  Future<void> _pickRange() async {
    final r = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: DateTimeRange(start: _start, end: _end),
    );
    if (r != null) {
      setState(() {
        _start = r.start;
        _end = r.end;
      });
      await _load();
    }
  }

  // ==================== WARNA DINAMIS ====================
  // Warna yang lebih stabil (menggunakan Map cache)
  final Map<String, Color> _colorCache = {};

  Color getDynamicColor(String key) {
    if (_colorCache.containsKey(key)) {
      return _colorCache[key]!;
    }

    final index = _colorCache.length % AppTheme.chartColors.length;
    final color = AppTheme.chartColors[index];
    _colorCache[key] = color;
    return color;
  }

  // ==================== COMPUTED ====================
  Map<String, int> get _visitPerHari {
    final m = <String, int>{};
    for (final v in _visits) m[v.tanggal] = (m[v.tanggal] ?? 0) + 1;
    return m;
  }

  Map<String, int> get _visitPerDiagnosa {
    final m = <String, int>{};
    for (final v in _visits) m[v.diagnosa] = (m[v.diagnosa] ?? 0) + 1;
    return m;
  }

  Map<String, int> get _drugResult {
    final m = {'Negatif': 0, 'Positif': 0};
    for (final d in _drugs) m[d.hasil] = (m[d.hasil] ?? 0) + 1;
    return m;
  }

  Map<String, int> get _ftwStatus {
    final m = {'Fit': 0, 'Not Fit': 0};
    for (final f in _ftws) {
      final k = f.isFit ? 'Fit' : 'Not Fit';
      m[k] = (m[k] ?? 0) + 1;
    }
    return m;
  }

  Map<String, int> get _fatigueKrit {
    final m = <String, int>{};
    for (final f in _fatigues) m[f.kriteria] = (m[f.kriteria] ?? 0) + 1;
    return m;
  }

  Map<String, int> _groupBy<T>(List<T> list, String Function(T) keyFn) {
    final m = <String, int>{};
    for (final item in list) {
      final key = keyFn(item);
      m[key] = (m[key] ?? 0) + 1;
    }
    return m;
  }

  // ==================== LINE CHART (FULL) ====================
  Widget _lineChart(List<MapEntry<String, int>> data, Color color) {
    if (data.isEmpty) {
      return const SizedBox(
        height: 160,
        child: EmptyState(message: 'Tidak ada data kunjungan'),
      );
    }

    final sortedData = data..sort((a, b) => a.key.compareTo(b.key));
    final maxY = sortedData
        .map((e) => e.value)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();

    return SizedBox(
      height: 180,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxY + (maxY * 0.25),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 1,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: Colors.grey.shade200, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              tooltipBorderRadius: BorderRadius.circular(8),
              tooltipPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              tooltipMargin: 8,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final dateStr = sortedData[spot.x.toInt()].key;
                  final date = DateTime.tryParse(dateStr);
                  final dateLabel = date != null
                      ? '${date.day}/${date.month}'
                      : dateStr;
                  return LineTooltipItem(
                    '$dateLabel\n${spot.y.toInt()} kunjungan',
                    const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                }).toList();
              },
            ),
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                interval: sortedData.length > 14 ? 2 : 1,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= sortedData.length)
                    return const SizedBox();
                  if (sortedData.length > 12 && index % 2 != 0)
                    return const SizedBox();
                  final date = DateTime.tryParse(sortedData[index].key);
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      date != null ? '${date.day}/${date.month}' : '',
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
                reservedSize: 28,
                getTitlesWidget: (value, meta) => Text(
                  value.toInt().toString(),
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
              curveSmoothness: 0.35,
              spots: List.generate(
                sortedData.length,
                (i) => FlSpot(i.toDouble(), sortedData[i].value.toDouble()),
              ),
              gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: sortedData.length <= 12,
                getDotPainter: (spot, percent, barData, index) =>
                    FlDotCirclePainter(
                      radius: 3.5,
                      color: Colors.white,
                      strokeWidth: 2,
                      strokeColor: color,
                    ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [color.withOpacity(0.25), color.withOpacity(0.02)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _diagnosaPie(Map<String, int> data) {
    if (data.isEmpty) {
      return const SizedBox(
        height: 160,
        child: EmptyState(message: 'Tidak ada data diagnosa'),
      );
    }

    final total = data.values.fold(0, (a, b) => a + b);
    final entries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topEntries = entries.take(8).toList();

    final sections = List.generate(topEntries.length, (i) {
      final e = topEntries[i];
      return PieChartSectionData(
        color: getDynamicColor(e.key),
        value: e.value.toDouble(),
        title: '${(e.value / total * 100).toStringAsFixed(0)}%',
        radius: 54,
        titleStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    });

    return Column(
      children: [
        SizedBox(
          height: 170,
          child: PieChart(
            PieChartData(
              sections: sections,
              sectionsSpace: 4,
              centerSpaceRadius: 38,
              centerSpaceColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: topEntries.map((e) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    color: getDynamicColor(e.key),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${e.key} (${e.value})',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  // ==================== VERTICAL BAR CHART ====================
  // ==================== VERTICAL BAR CHART (Compatible) ====================
  // ==================== VERTICAL BAR CHART (FIXED) ====================
  Widget _barChart(Map<String, int> data, String title) {
    if (data.isEmpty) {
      return const SizedBox(
        height: 200,
        child: EmptyState(message: 'Tidak ada data'),
      );
    }

    final entries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return SizedBox(
      height: 240,
      child: BarChart(
        BarChartData(
          maxY: entries.first.value.toDouble() * 1.25,
          minY: 0,
          barGroups: List.generate(entries.length, (index) {
            final item = entries[index];
            final color = getDynamicColor(item.key);

            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: item.value.toDouble(),
                  color: color,
                  width: 26,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(2),
                  ),
                ),
              ],
            );
          }),
          groupsSpace: 12,
          alignment: BarChartAlignment.spaceAround,

          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 55,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= entries.length) return const SizedBox();
                  final label = entries[idx].key;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      label.length > 9 ? '${label.substring(0, 9)}..' : label,
                      style: const TextStyle(fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 35),
            ),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),

          gridData: FlGridData(show: true, drawVerticalLine: false),
          borderData: FlBorderData(show: false),

          // ==================== TOOLTIP (VERSI BARU) ====================
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              // tooltipBgColor: Colors.black.withOpacity(0.85),
              tooltipPadding: const EdgeInsets.all(8),
              // tooltipBorderRadius: ,           // ini masih support di sebagian besar versi
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final item = entries[group.x.toInt()];
                return BarTooltipItem(
                  '${item.key}\n${item.value}',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _resultPie(Map<String, int> data, Map<String, Color> colorMap) {
    final total = data.values.fold(0, (a, b) => a + b);
    final sections = data.entries.where((e) => e.value > 0).map((e) {
      final c = colorMap[e.key] ?? AppTheme.primary;
      final pct = total > 0 ? (e.value / total * 100).toStringAsFixed(0) : '0';
      return PieChartSectionData(
        color: c,
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

    return Column(
      children: [
        SizedBox(
          height: 160,
          child: PieChart(
            PieChartData(
              sections: sections,
              sectionsSpace: 3,
              centerSpaceRadius: 35,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 6,
          children: data.entries.where((e) => e.value > 0).map((e) {
            final c = colorMap[e.key] ?? AppTheme.primary;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: c, shape: BoxShape.circle),
                ),
                const SizedBox(width: 5),
                Text(
                  '${e.key}: ${e.value}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _miniCard(String label, String value, Color color, IconData icon) =>
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      );

  Widget _avgSleepChart() {
    final grouped = <String, List<double>>{};
    for (final f in _fatigues) {
      grouped.putIfAbsent(f.kriteria, () => []).add(f.jumlahJamTidur);
    }
    final avgs = grouped.map(
      (k, v) => MapEntry(k, v.reduce((a, b) => a + b) / v.length),
    );
    return OhHorizBar(
      data: avgs.map((k, v) => MapEntry(k, v.round())),
      colorFn: kriteriaColor,
    );
  }

  // ==================== TABS ====================
  Widget _visitTab() {
    final sortedHari = _visitPerHari.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final diagnosa = _visitPerDiagnosa;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      children: [
        // SectionCard(
        //   title: 'Tren Kunjungan Harian',
        //   child: _lineChart(sortedHari, AppTheme.primary),
        // ),

        // const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SectionCard(
                  title: 'Tren Kunjungan Harian',
                  child: _lineChart(sortedHari, AppTheme.primary),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SectionCard(
                  title: 'Distribusi Diagnosa',
                  child: _diagnosaPie(diagnosa),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SectionCard(
                  title: 'Top Keluhan',
                  // child: OhHorizBar(data: diagnosa, colorFn: getDynamicColor),
                  child: _barChart(
                    _groupBy(_visits, (v) => v.keluhan),
                    "Top Keluhan",
                  ),
                ),
              ),
            ],
          ),
        ),

        // const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SectionCard(
                  title: 'Per Site',
                  child: _barChart(
                    _groupBy(_visits, (v) => v.site),
                    "Per Site",
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SectionCard(
                  title: 'Per Posisi',
                  child: _barChart(
                    _groupBy(_visits, (v) => v.posisi),
                    "Per Posisi",
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SectionCard(
                  title: 'Per Departemen',
                  // child: OhHorizBar(
                  //   data: _groupBy(_visits, (v) => v.departemen),
                  //   colorFn: getDynamicColor,
                  // ),
                  child: _barChart(
                    _groupBy(_visits, (v) => v.departemen),
                    "Per Departemen",
                  ),
                ),
              ),
            ],
          ),
        ),

        // const SizedBox(height: 12),
      ],
    );
  }

  Widget _drugTab() {
    final hasil = _drugResult;
    final positif = hasil['Positif'] ?? 0;
    final total = _drugs.length;
    final pct = total > 0 ? (positif / total * 100).toStringAsFixed(1) : '0.0';

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      children: [
        Row(
          children: [
            Expanded(
              child: _miniCard(
                'Total Tes',
                '$total',
                const Color(0xFF7E3AF2),
                Icons.science_rounded,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _miniCard(
                'Positif',
                '$positif ($pct%)',
                Colors.red,
                Icons.warning_rounded,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _miniCard(
                'Negatif',
                '${hasil['Negatif'] ?? 0}',
                AppTheme.accent,
                Icons.check_circle_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SectionCard(
                  title: 'Hasil Keseluruhan',
                  child: _drugs.isEmpty
                      ? const SizedBox(
                          height: 140,
                          child: EmptyState(message: 'Tidak ada data'),
                        )
                      : _resultPie(hasil, {
                          'Negatif': AppTheme.accent,
                          'Positif': Colors.red,
                        }),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SectionCard(
                  title: 'Positif per Parameter',
                  child: OhHorizBar(
                    data: {
                      'AMP': _drugs.where((d) => d.amp == 'Positif').length,
                      'MET': _drugs.where((d) => d.met == 'Positif').length,
                      'THC': _drugs.where((d) => d.thc == 'Positif').length,
                      'COC': _drugs.where((d) => d.coc == 'Positif').length,
                      'BZO': _drugs.where((d) => d.bzo == 'Positif').length,
                    },
                    colorFn: (_) => Colors.red,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: .stretch,
            children: [
              Expanded(
                child: SectionCard(
                  title: 'Per Departemen',
                  // child: OhHorizBar(
                  //   data: _groupBy(_drugs, (d) => d.departemen),
                  //   colorFn: getDynamicColor,
                  // ),
                  child: _barChart(
                    _groupBy(_drugs, (d) => d.departemen),
                    "Per Departemen",
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SectionCard(
                  title: 'Per Posisi',
                  // child: OhHorizBar(
                  //   data: _groupBy(_drugs, (d) => d.departemen),
                  //   colorFn: getDynamicColor,
                  // ),
                  child: _barChart(
                    _groupBy(_drugs, (d) => d.posisi),
                    "Per Posisi",
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _ftwTab() {
    final status = _ftwStatus;
    final fit = status['Fit'] ?? 0;
    final notFit = status['Not Fit'] ?? 0;
    final fitPct = _ftws.isNotEmpty
        ? (fit / _ftws.length * 100).toStringAsFixed(1)
        : '0.0';

    final shiftData = _groupBy(_ftws, (f) => f.shift);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      children: [
        Row(
          children: [
            Expanded(
              child: _miniCard(
                'Total',
                '${_ftws.length}',
                Colors.green,
                Icons.health_and_safety_rounded,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _miniCard(
                'Fit ($fitPct%)',
                '$fit',
                Colors.green,
                Icons.check_circle_rounded,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _miniCard(
                'Not Fit',
                '$notFit',
                Colors.red,
                Icons.cancel_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SectionCard(
                  title: 'Per Posisi',
                  child: _barChart(
                    _groupBy(_ftws, (f) => f.posisi),
                    "Per Posisi",
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SectionCard(
                  title: 'Per Departemen',
                  child: _barChart(
                    _groupBy(_ftws, (f) => f.departemen),
                    "Per Departemen",
                  ),
                ),
              ),
            ],
          ),
        ),

        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SectionCard(
                  title: 'Fit vs Not Fit',
                  child: _ftws.isEmpty
                      ? const SizedBox(
                          height: 140,
                          child: EmptyState(message: 'Tidak ada data'),
                        )
                      : _resultPie(status, {
                          'Fit': Colors.green,
                          'Not Fit': Colors.red,
                        }),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SectionCard(
                  title: 'Per Shift',
                  child: shiftData.isEmpty
                      ? const SizedBox(
                          height: 160,
                          child: EmptyState(message: 'Tidak ada data shift'),
                        )
                      : _resultPie(shiftData, {
                          "Pagi": Colors.orange,
                          "Siang": Colors.blueAccent,
                          "Malam": Colors.indigo,
                        }),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _fatigueTab() {
    final krit = _fatigueKrit;
    final unfitCount = _fatigues.where((f) => f.isUnfit).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      children: [
        Row(
          children: [
            Expanded(
              child: _miniCard(
                'Total',
                '${_fatigues.length}',
                Colors.deepOrange,
                Icons.battery_alert_rounded,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _miniCard(
                'Fit',
                '${krit['Fit'] ?? 0}',
                AppTheme.accent,
                Icons.check_circle_rounded,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _miniCard(
                'Unfit/Berat',
                '$unfitCount',
                Colors.red,
                Icons.cancel_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SectionCard(
                  title: 'Distribusi Kriteria',
                  child: _fatigues.isEmpty
                      ? const SizedBox(
                          height: 140,
                          child: EmptyState(message: 'Tidak ada data'),
                        )
                      : OhHorizBar(data: krit, colorFn: kriteriaColor),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SectionCard(
                  title: 'Rata-rata Jam Tidur per Kriteria',
                  child: _avgSleepChart(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SectionCard(
                  title: 'Per Posisi',
                  child: _barChart(
                    _groupBy(_fatigues, (f) => f.posisi),
                    "Per Posisi",
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SectionCard(
                  title: 'Per Departemen',
                  child: _barChart(
                    _groupBy(_fatigues, (f) => f.departemen),
                    "Per Departemen",
                  ),
                ),
              ),
            ],
          ),
        ),
        // const SizedBox(width: 12),
        // Expanded(
        //   child: SectionCard(
        //     title: 'Per Posisi',
        //     child: _barChart(
        //       _groupBy(_fatigues, (f) => f.posisi),
        //       "Per Posisi",
        //     ),
        //   ),
        // ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dashboard OH',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            'Kunjungan • Narkoba • Fit To Work • Fatigue',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton.filled(
                      onPressed: _load,
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                OhDateFilter(start: _start, end: _end, onTap: _pickRange),
              ],
            ),
          ),

          const SizedBox(height: 6),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
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
              tabs: const [
                Tab(text: 'Kunjungan'),
                Tab(text: 'Narkoba'),
                Tab(text: 'Fit To Work'),
                Tab(text: 'Fatigue'),
              ],
            ),
          ),
          const SizedBox(height: 12),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabs,
                    children: [
                      _visitTab(),
                      _drugTab(),
                      _ftwTab(),
                      _fatigueTab(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
