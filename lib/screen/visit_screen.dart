import 'package:flutter/material.dart';
import '../models/visit.dart';
import '../models/visit_prescription.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../components/form/app_search_bar.dart';
import '../components/cards/empty_state.dart';
import '../components/oh_shared.dart';
import 'visit_input_screen.dart';

class VisitScreen extends StatefulWidget {
  const VisitScreen({super.key});

  @override
  State<VisitScreen> createState() => _VisitScreenState();
}

class _VisitScreenState extends State<VisitScreen> {
  final _db = DatabaseService();

  List<Visit> _all = [];
  List<Visit> _filtered = [];
  bool _isLoading = true;
  String _query = '';

  // Cache resep per visitId agar tidak query ulang tiap build
  final Map<int, List<VisitPrescriptionWithItems>> _rxCache = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    _all = await _db.getVisits();
    _rxCache.clear();

    // Pre-fetch semua resep sekaligus
    for (final v in _all) {
      if (v.id != null) {
        _rxCache[v.id!] = await _db.getVisitPrescriptions(v.id!);
      }
    }

    _applySearch(_query);
    setState(() => _isLoading = false);
  }

  void _applySearch(String q) {
    _query = q;
    final ql = q.toLowerCase();
    setState(() {
      _filtered = ql.isEmpty
          ? List.from(_all)
          : _all
                .where(
                  (v) =>
                      v.nama.toLowerCase().contains(ql) ||
                      v.site.toLowerCase().contains(ql) ||
                      v.departemen.toLowerCase().contains(ql) ||
                      v.keluhan.toLowerCase().contains(ql) ||
                      v.diagnosa.toLowerCase().contains(ql),
                )
                .toList();
    });
  }

  Future<void> _editVisit(Visit v) async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: const Text('Edit Kunjungan'),
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: AppTheme.appBarGradient,
              ),
            ),
          ),
          body: VisitInputScreen(visit: v),
        ),
      ),
    );
    if (ok == true) await _load();
  }

  Future<void> _deleteVisit(Visit v) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.warning_rounded, color: Colors.red, size: 22),
            SizedBox(width: 8),
            Text('Hapus Kunjungan'),
          ],
        ),
        content: RichText(
          text: TextSpan(
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textPrimary,
              height: 1.5,
            ),
            children: [
              const TextSpan(text: 'Yakin menghapus kunjungan '),
              TextSpan(
                text: v.nama,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const TextSpan(
                text:
                    '?\nResep obat terkait juga akan dihapus '
                    'dan stok dikembalikan.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.delete_rounded, size: 16),
            label: const Text('Hapus'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (confirm == true && v.id != null) {
      // Hapus resep dulu (rollback stok) lalu visit
      await _db.deleteVisitPrescriptions(v.id!);
      await _db.deleteVisit(v.id!);
      await _load();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kunjungan ${v.nama} dihapus'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red.shade700,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.local_hospital_rounded,
                    size: 22,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Data Kunjungan',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        '${_all.length} kunjungan tercatat',
                        style: const TextStyle(
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
                  tooltip: 'Refresh',
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.primary.withOpacity(0.1),
                    foregroundColor: AppTheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            AppSearchBar(
              hint: 'Cari nama, site, keluhan, diagnosa...',
              onChanged: _applySearch,
              onClear: () => _applySearch(''),
            ),
            const SizedBox(height: 12),

            // Info bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _query.isEmpty
                    ? 'Menampilkan ${_all.length} data'
                    : 'Ditemukan ${_filtered.length} dari ${_all.length} data',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Table
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _all.isEmpty
                      ? const EmptyState(
                          message: 'Belum ada data kunjungan',
                          icon: Icons.local_hospital_rounded,
                        )
                      : _filtered.isEmpty
                      ? const EmptyState(
                          message: 'Tidak ada data yang cocok',
                          icon: Icons.search_off_rounded,
                        )
                      : Column(
                          children: [
                            _buildHeader(),
                            Expanded(
                              child: ListView.builder(
                                itemCount: _filtered.length,
                                itemBuilder: (_, i) => _VisitRow(
                                  index: i,
                                  visit: _filtered[i],
                                  rxItems: _rxCache[_filtered[i].id] ?? [],
                                  onEdit: () => _editVisit(_filtered[i]),
                                  onDelete: () => _deleteVisit(_filtered[i]),
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    const headers = [
      ('#', 0.4),
      ('Tanggal', 1.0),
      ('Site', 0.9),
      ('Nama', 1.5),
      ('Dept.', 1.0),
      ('Keluhan', 1.5),
      ('Diagnosa', 1.3),
      ('Vital', 1.2),
      ('Resep', 0.9),
      ('Aksi', 0.9),
    ];

    return Container(
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
          children: headers
              .map(
                (h) => Expanded(
                  flex: (h.$2 * 10).toInt(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 12,
                    ),
                    child: Text(
                      h.$1,
                      style: const TextStyle(
                        fontSize: 11,
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
    );
  }
}

// ─── Visit Row ────────────────────────────────────────────────────────────────

class _VisitRow extends StatefulWidget {
  final int index;
  final Visit visit;
  final List<VisitPrescriptionWithItems> rxItems;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _VisitRow({
    required this.index,
    required this.visit,
    required this.rxItems,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_VisitRow> createState() => _VisitRowState();
}

class _VisitRowState extends State<_VisitRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final v = widget.visit;
    final isEven = widget.index % 2 == 0;
    final hasRx = widget.rxItems.isNotEmpty;
    final rxCount = widget.rxItems.fold<int>(0, (s, r) => s + r.items.length);

    // Badge warna diagnosa konsisten
    final diagColor = AppTheme
        .chartColors[v.diagnosa.hashCode.abs() % AppTheme.chartColors.length];

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: _hovered
              ? AppTheme.primary.withOpacity(0.04)
              : isEven
              ? Colors.white
              : const Color(0xFFFAFBFF),
          border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // No
              _cell(
                0.4,
                Text(
                  '${widget.index + 1}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              // Tanggal
              _cell(
                1.0,
                Text(
                  v.tanggal,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              // Site
              _cell(
                0.9,
                Text(
                  v.site,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              // Nama
              _cell(
                1.5,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      v.nama,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      v.posisi,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Departemen
              _cell(
                1.0,
                Text(
                  v.departemen,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              // Keluhan
              _cell(
                1.5,
                Text(
                  v.keluhan,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              // Diagnosa badge
              _cell(
                1.3,
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: diagColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: diagColor.withOpacity(0.25)),
                  ),
                  child: Text(
                    v.diagnosa,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: diagColor,
                    ),
                  ),
                ),
              ),
              // Vital summary
              _cell(
                1.2,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _vitalLine(
                      Icons.thermostat_rounded,
                      '${v.suhuBadan}°C',
                      Colors.red,
                    ),
                    _vitalLine(
                      Icons.favorite_rounded,
                      '${v.nadi} x/m',
                      Colors.pink,
                    ),
                    _vitalLine(
                      Icons.compress_rounded,
                      v.tekananDarah,
                      AppTheme.primary,
                    ),
                  ],
                ),
              ),
              // Resep badge
              _cell(
                0.9,
                hasRx
                    ? Tooltip(
                        message: widget.rxItems
                            .expand((r) => r.items)
                            .map(
                              (i) =>
                                  '${i.medicineName} (${i.jumlah}${i.satuan})',
                            )
                            .join('\n'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.accent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppTheme.accent.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: .center,
                            children: [
                              const Icon(
                                Icons.medication_rounded,
                                size: 18,
                                color: AppTheme.accent,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$rxCount',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.accent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              // Aksi
              _cell(
                0.9,
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _actionBtn(
                      Icons.edit_rounded,
                      AppTheme.primary,
                      widget.onEdit,
                      'Edit',
                    ),
                    const SizedBox(width: 6),
                    _actionBtn(
                      Icons.delete_rounded,
                      Colors.red,
                      widget.onDelete,
                      'Hapus',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cell(double flex, Widget child) => Expanded(
    flex: (flex * 10).toInt(),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: child,
    ),
  );

  Widget _vitalLine(IconData icon, String text, Color color) => Row(
    children: [
      Icon(icon, size: 12, color: color.withOpacity(0.7)),
      const SizedBox(width: 3),
      Flexible(
        child: Text(text, style: TextStyle(fontSize: 12, color: color)),
      ),
    ],
  );

  Widget _actionBtn(
    IconData icon,
    Color color,
    VoidCallback onTap,
    String tooltip,
  ) => Tooltip(
    message: tooltip,
    child: InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    ),
  );
}
