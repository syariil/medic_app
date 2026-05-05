import 'package:flutter/material.dart';
import '../models/medicine.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../components/form/app_search_bar.dart';
import '../components/cards/empty_state.dart';
import 'medicine_input_screen.dart';

// ─── Kolom ───────────────────────────────────────────────────────────────────

class _Col {
  final String key, label;
  final double flex;
  const _Col(this.key, this.label, this.flex);
}

const _columns = [
  _Col('no', '#', 0.4),
  _Col('nama', 'Nama Obat', 1.8),
  _Col('kategori', 'Kategori', 1.4),
  _Col('satuan', 'Satuan', 0.9),
  _Col('stok', 'Stok', 0.9),
  _Col('keterangan', 'Keterangan', 1.6),
  _Col('aksi', 'Aksi', 0.9),
];

enum _SortDir { none, asc, desc }

class _Sort {
  final String col;
  final _SortDir dir;
  const _Sort(this.col, this.dir);
}

// ─── SCREEN ───────────────────────────────────────────────────────────────────

class MedicineScreen extends StatefulWidget {
  const MedicineScreen({super.key});

  @override
  State<MedicineScreen> createState() => _MedicineScreenState();
}

class _MedicineScreenState extends State<MedicineScreen> {
  final _db = DatabaseService();

  List<Medicine> _all = [];
  List<Medicine> _filtered = [];
  bool _isLoading = true;
  String _searchQuery = '';
  _Sort _sort = const _Sort('', _SortDir.none);
  bool _showStokRendahOnly = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    _all = await _db.getMedicines();
    _applyFilter();
    setState(() => _isLoading = false);
  }

  void _applyFilter() {
    final q = _searchQuery.toLowerCase();
    var list = _all.where((m) {
      final matchSearch =
          q.isEmpty ||
          m.nama.toLowerCase().contains(q) ||
          m.kategori.toLowerCase().contains(q) ||
          m.keterangan.toLowerCase().contains(q);
      final matchStok = !_showStokRendahOnly || m.isStokRendah;
      return matchSearch && matchStok;
    }).toList();

    if (_sort.dir != _SortDir.none) {
      list.sort((a, b) {
        if (_sort.col == 'stok') {
          return _sort.dir == _SortDir.asc
              ? a.stok.compareTo(b.stok)
              : b.stok.compareTo(a.stok);
        }
        final va = _sortVal(a, _sort.col);
        final vb = _sortVal(b, _sort.col);
        return _sort.dir == _SortDir.asc ? va.compareTo(vb) : vb.compareTo(va);
      });
    }
    _filtered = list;
  }

  String _sortVal(Medicine m, String col) {
    switch (col) {
      case 'nama':
        return m.nama;
      case 'kategori':
        return m.kategori;
      default:
        return '';
    }
  }

  void _onSearch(String q) => setState(() {
    _searchQuery = q;
    _applyFilter();
  });

  void _onSort(String col) {
    setState(() {
      _sort = _sort.col == col
          ? _sort.dir == _SortDir.asc
                ? _Sort(col, _SortDir.desc)
                : const _Sort('', _SortDir.none)
          : _Sort(col, _SortDir.asc);
      _applyFilter();
    });
  }

  Future<void> _edit(Medicine m) async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: const Text('Edit Obat'),
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: AppTheme.appBarGradient,
              ),
            ),
          ),
          body: MedicineInputScreen(medicine: m),
        ),
      ),
    );
    if (ok == true) await _loadData();
  }

  Future<void> _delete(Medicine m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.warning_rounded, color: Colors.red, size: 22),
            SizedBox(width: 8),
            Text('Hapus Obat'),
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
              const TextSpan(text: 'Yakin menghapus '),
              TextSpan(
                text: m.nama,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const TextSpan(text: '?\nTindakan ini tidak bisa dibatalkan.'),
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

    if (ok == true && m.id != null) {
      await _db.deleteMedicine(m.id!);
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${m.nama} dihapus'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red.shade700,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  int get _stokRendahCount => _all.where((m) => m.isStokRendah).length;

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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Data Obat / Farmasi',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        '${_all.length} obat terdaftar',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Badge stok rendah
                if (_stokRendahCount > 0)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          size: 14,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$_stokRendahCount stok rendah',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                IconButton.filled(
                  onPressed: _loadData,
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

            // Search + filter stok rendah
            Row(
              children: [
                Expanded(
                  child: AppSearchBar(
                    hint: 'Cari nama obat, kategori...',
                    onChanged: _onSearch,
                    onClear: () => _onSearch(''),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => setState(() {
                    _showStokRendahOnly = !_showStokRendahOnly;
                    _applyFilter();
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 13,
                    ),
                    decoration: BoxDecoration(
                      color: _showStokRendahOnly
                          ? Colors.orange
                          : Colors.orange.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _showStokRendahOnly
                            ? Colors.orange
                            : Colors.orange.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.filter_list_rounded,
                          size: 16,
                          color: _showStokRendahOnly
                              ? Colors.white
                              : Colors.orange,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Stok Rendah',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _showStokRendahOnly
                                ? Colors.white
                                : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Info bar
            Row(
              children: [
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
                    _searchQuery.isEmpty && !_showStokRendahOnly
                        ? 'Menampilkan ${_all.length} data'
                        : 'Ditemukan ${_filtered.length} dari ${_all.length} data',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Tabel
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
                          message: 'Belum ada data obat',
                          icon: Icons.medication_outlined,
                        )
                      : _filtered.isEmpty
                      ? const EmptyState(
                          message: 'Tidak ada data yang cocok',
                          icon: Icons.search_off_rounded,
                        )
                      : Column(
                          children: [
                            _MedTableHeader(
                              columns: _columns,
                              sort: _sort,
                              onSort: _onSort,
                            ),
                            Expanded(
                              child: ListView.builder(
                                itemCount: _filtered.length,
                                itemBuilder: (_, i) => _MedTableRow(
                                  // key: ValueKey(_filtered[i].id!),
                                  index: i,
                                  medicine: _filtered[i],
                                  columns: _columns,
                                  onEdit: _edit,
                                  onDelete: _delete,
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
}

// ─── TABLE HEADER ─────────────────────────────────────────────────────────────

class _MedTableHeader extends StatelessWidget {
  final List<_Col> columns;
  final _Sort sort;
  final ValueChanged<String> onSort;

  const _MedTableHeader({
    required this.columns,
    required this.sort,
    required this.onSort,
  });

  static const _sortable = {'nama', 'kategori', 'stok'};

  @override
  Widget build(BuildContext context) {
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
          children: columns.map((col) {
            final sortable = _sortable.contains(col.key);
            final sorted = sort.col == col.key;
            return Expanded(
              flex: (col.flex * 10).toInt(),
              child: GestureDetector(
                onTap: sortable ? () => onSort(col.key) : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Text(
                        col.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: sorted
                              ? AppTheme.primary
                              : AppTheme.textPrimary,
                          letterSpacing: 0.3,
                        ),
                      ),
                      if (sortable) ...[
                        const SizedBox(width: 4),
                        Icon(
                          sorted && sort.dir == _SortDir.asc
                              ? Icons.arrow_upward_rounded
                              : sorted && sort.dir == _SortDir.desc
                              ? Icons.arrow_downward_rounded
                              : Icons.unfold_more_rounded,
                          size: 13,
                          color: sorted
                              ? AppTheme.primary
                              : AppTheme.textSecondary.withOpacity(0.4),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ─── TABLE ROW ────────────────────────────────────────────────────────────────

class _MedTableRow extends StatefulWidget {
  final int index;
  final Medicine medicine;
  final List<_Col> columns;
  final Future<void> Function(Medicine) onEdit;
  final Future<void> Function(Medicine) onDelete;
  // final ValueKey<int> key;

  const _MedTableRow({
    // required this.key,
    required this.index,
    required this.medicine,
    required this.columns,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_MedTableRow> createState() => _MedTableRowState();
}

class _MedTableRowState extends State<_MedTableRow> {
  bool _hovered = false;

  Color _kategoriColor(String k) {
    const colors = [
      Color(0xFF1A56DB),
      Color(0xFF0E9F6E),
      Color(0xFFE3A008),
      Color(0xFFE02424),
      Color(0xFF7E3AF2),
      Color(0xFFFF5A1F),
    ];
    return colors[k.hashCode.abs() % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final isEven = widget.index % 2 == 0;
    final m = widget.medicine;

    return MouseRegion(
      opaque: false,
      hitTestBehavior: HitTestBehavior.translucent,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: _hovered
              ? AppTheme.primary.withOpacity(0.04)
              : m.isHabis
              ? Colors.red.withOpacity(0.03)
              : m.isStokRendah
              ? Colors.orange.withOpacity(0.03)
              : isEven
              ? Colors.white
              : const Color(0xFFFAFBFF),
          border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
        ),

        child: Row(
          children: widget.columns
              .map(
                (col) => Expanded(
                  flex: (col.flex * 10).toInt(),
                  child: _buildCell(col),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildCell(_Col col) {
    final m = widget.medicine;
    switch (col.key) {
      case 'no':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          alignment: Alignment.center,
          child: Text(
            '${widget.index + 1}',
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
        );

      case 'nama':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.medication_rounded,
                  size: 16,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  m.nama,
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
        );

      case 'kategori':
        final color = _kategoriColor(m.kategori);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.25)),
            ),
            child: Text(
              m.kategori,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );

      case 'satuan':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Text(
            m.satuan,
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            overflow: TextOverflow.ellipsis,
          ),
        );

      case 'stok':
        final stokColor = m.isHabis
            ? Colors.red
            : m.isStokRendah
            ? Colors.orange
            : AppTheme.accent;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          alignment: Alignment.center,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: stokColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: stokColor.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (m.isHabis || m.isStokRendah)
                  Padding(
                    padding: const EdgeInsets.only(right: 3),
                    child: Icon(
                      m.isHabis
                          ? Icons.remove_circle_rounded
                          : Icons.warning_rounded,
                      size: 11,
                      color: stokColor,
                    ),
                  ),
                Text(
                  '${m.stok}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: stokColor,
                  ),
                ),
              ],
            ),
          ),
        );

      case 'keterangan':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Text(
            m.keterangan.isEmpty ? '—' : m.keterangan,
            style: TextStyle(
              fontSize: 12,
              color: m.keterangan.isEmpty
                  ? AppTheme.textSecondary.withOpacity(0.4)
                  : AppTheme.textSecondary,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        );

      case 'aksi':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Tooltip(
                message: 'Edit',
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => widget.onEdit(m),
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      size: 15,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Tooltip(
                message: 'Hapus',
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => widget.onDelete(m),
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.delete_rounded,
                      size: 15,
                      color: Colors.red,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }
}
