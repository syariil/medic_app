import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/medicine.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../components/cards/stat_card.dart';
import '../components/cards/section_card.dart';
import '../components/cards/empty_state.dart';

class MedicineDashboardScreen extends StatefulWidget {
  const MedicineDashboardScreen({super.key});
  @override
  State<MedicineDashboardScreen> createState() => _State();
}

class _State extends State<MedicineDashboardScreen> {
  final _db = DatabaseService();

  List<Medicine> _all = [];
  Map<String, int> _usageStat = {};
  bool _isLoading = true;

  // Filter penggunaan
  DateTime _usageStart = DateTime.now().subtract(const Duration(days: 29));
  DateTime _usageEnd = DateTime.now();

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _load() async {
    setState(() => _isLoading = true);
    _all = await _db.getMedicines();
    _usageStat = await _db.getMedicineUsageStat(
      startDate: _fmt(_usageStart),
      endDate: _fmt(_usageEnd),
    );
    setState(() => _isLoading = false);
  }

  Future<void> _pickUsageRange() async {
    final r = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: DateTimeRange(start: _usageStart, end: _usageEnd),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppTheme.primary),
        ),
        child: child!,
      ),
    );
    if (r != null) {
      _usageStart = r.start;
      _usageEnd = r.end;
      await _load();
    }
  }

  // ── Computed ─────────────────────────────────────────────────────────────
  int get _totalStok => _all.fold(0, (s, m) => s + m.stok);
  int get _stokRendahCount =>
      _all.where((m) => m.isStokRendah && !m.isHabis).length;
  int get _stokHabisCount => _all.where((m) => m.isHabis).length;
  Map<String, int> get _byKategori {
    final m = <String, int>{};
    for (final med in _all) m[med.kategori] = (m[med.kategori] ?? 0) + 1;
    return m;
  }

  List<PieChartSectionData> get _kategoriPie {
    final data = _byKategori;
    final total = data.values.fold(0, (a, b) => a + b);
    int idx = 0;
    return data.entries.map((e) {
      final c = AppTheme.chartColors[idx++ % AppTheme.chartColors.length];
      final pct = total > 0 ? (e.value / total * 100).toStringAsFixed(0) : '0';
      return PieChartSectionData(
        color: c,
        value: e.value.toDouble(),
        title: '$pct%',
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

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
                              'Dashboard Farmasi',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const Text(
                              'Manajemen stok & pemakaian obat',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton.filled(
                        onPressed: _load,
                        icon: const Icon(Icons.refresh_rounded),
                        style: IconButton.styleFrom(
                          backgroundColor: AppTheme.primary.withOpacity(0.1),
                          foregroundColor: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Stat Cards Row 1 ──────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          label: 'Total Obat',
                          value: '${_all.length}',
                          icon: Icons.medication_rounded,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatCard(
                          label: 'Total Stok',
                          value: '$_totalStok',
                          icon: Icons.inventory_2_rounded,
                          color: AppTheme.accent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatCard(
                          label: 'Stok Rendah',
                          value: '$_stokRendahCount',
                          icon: Icons.warning_amber_rounded,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatCard(
                          label: 'Stok Habis',
                          value: '$_stokHabisCount',
                          icon: Icons.remove_circle_rounded,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Charts Row 1: Pie kategori + Top Usage ────────────────
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: SectionCard(
                            title: 'Sebaran Kategori',
                            child: _byKategori.isEmpty
                                ? const SizedBox(
                                    height: 160,
                                    child: EmptyState(
                                      message: 'Tidak ada data',
                                    ),
                                  )
                                : Column(
                                    children: [
                                      SizedBox(
                                        height: 150,
                                        child: PieChart(
                                          PieChartData(
                                            sections: _kategoriPie,
                                            sectionsSpace: 3,
                                            centerSpaceRadius: 30,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      _KategoriLegend(data: _byKategori),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SectionCard(
                            title: 'Pemakaian Obat',
                            trailing: TextButton.icon(
                              onPressed: _pickUsageRange,
                              icon: const Icon(Icons.tune_rounded, size: 14),
                              label: Text(
                                '${_usageStart.day}/${_usageStart.month} – ${_usageEnd.day}/${_usageEnd.month}',
                                style: const TextStyle(fontSize: 11),
                              ),
                              style: TextButton.styleFrom(
                                foregroundColor: AppTheme.primary,
                                padding: EdgeInsets.zero,
                              ),
                            ),
                            child: _usageStat.isEmpty
                                ? const SizedBox(
                                    height: 160,
                                    child: EmptyState(
                                      message:
                                          'Belum ada resep\npada periode ini',
                                      icon: Icons.receipt_long_rounded,
                                    ),
                                  )
                                : _UsageChart(data: _usageStat),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // const SizedBox(height: 12),

                  // ── Stok rendah alert ─────────────────────────────────────
                  if (_stokRendahCount > 0 || _stokHabisCount > 0)
                    SectionCard(
                      title: '⚠️  Perhatian Stok',
                      child: _StokAlertList(
                        medicines: _all.where((m) => m.isStokRendah).toList()
                          ..sort((a, b) => a.stok.compareTo(b.stok)),
                      ),
                    ),
                  // if (_stokRendahCount > 0 || _stokHabisCount > 0)
                  // const SizedBox(height: 12),
                  // ── Tabel stok semua obat ─────────────────────────────────
                  SectionCard(
                    title: 'Semua Stok Obat',
                    child: _StokTable(medicines: _all),
                  ),
                ],
              ),
            ),
    );
  }
}

// ─── Kategori Legend ──────────────────────────────────────────────────────────
class _KategoriLegend extends StatelessWidget {
  final Map<String, int> data;
  const _KategoriLegend({required this.data});
  @override
  Widget build(BuildContext context) {
    final entries = data.entries.toList();
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: List.generate(entries.length, (i) {
        final c = AppTheme.chartColors[i % AppTheme.chartColors.length];
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: c, shape: BoxShape.circle),
            ),
            const SizedBox(width: 4),
            Text(
              '${entries[i].key} (${entries[i].value})',
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        );
      }),
    );
  }
}

// ─── Usage horizontal bar chart ──────────────────────────────────────────────
class _UsageChart extends StatelessWidget {
  final Map<String, int> data;
  const _UsageChart({required this.data});
  @override
  Widget build(BuildContext context) {
    final sorted = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(6).toList();
    final max = top.isEmpty ? 1 : top.first.value.toDouble();
    return Column(
      children: List.generate(top.length, (i) {
        final e = top[i];
        final c = AppTheme.chartColors[i % AppTheme.chartColors.length];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            children: [
              SizedBox(
                width: 90,
                child: Text(
                  e.key,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: max > 0 ? e.value / max : 0,
                    minHeight: 12,
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

// ─── Stok Alert List ─────────────────────────────────────────────────────────
class _StokAlertList extends StatelessWidget {
  final List<Medicine> medicines;
  const _StokAlertList({required this.medicines});
  @override
  Widget build(BuildContext context) {
    if (medicines.isEmpty) return const SizedBox.shrink();
    return Column(
      children: medicines.map((m) {
        final isHabis = m.isHabis;
        final color = isHabis ? Colors.red : Colors.orange;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Icon(
                isHabis
                    ? Icons.remove_circle_rounded
                    : Icons.warning_amber_rounded,
                size: 18,
                color: color,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.nama,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      m.kategori,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Text(
                  isHabis ? 'HABIS' : '${m.stok} ${m.satuan}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ─── Stok Table ───────────────────────────────────────────────────────────────
class _StokTable extends StatelessWidget {
  final List<Medicine> medicines;
  const _StokTable({required this.medicines});

  Color _stokColor(Medicine m) => m.isHabis
      ? Colors.red
      : m.isStokRendah
      ? Colors.orange
      : AppTheme.accent;

  @override
  Widget build(BuildContext context) {
    if (medicines.isEmpty)
      return const EmptyState(
        message: 'Belum ada data obat',
        icon: Icons.medication_outlined,
      );
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.06),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: const [
              Expanded(
                flex: 5,
                child: Text(
                  'Nama Obat',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  'Kategori',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Stok',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        ...List.generate(medicines.length, (i) {
          final m = medicines[i];
          final c = _stokColor(m);
          final isEven = i % 2 == 0;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isEven ? Colors.white : const Color(0xFFFAFBFF),
              border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Text(
                    m.nama,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    m.kategori,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: c.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: c.withOpacity(0.3)),
                      ),
                      child: Text(
                        '${m.stok}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: c,
                        ),
                      ),
                    ),
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
