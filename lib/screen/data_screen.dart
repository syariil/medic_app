import 'package:flutter/material.dart';
import '../models/patient.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../components/form/app_search_bar.dart';
import '../components/cards/empty_state.dart';
import 'input_screen.dart';

// ── Kolom definisi ────────────────────────────────────────────────────────────

class _ColDef {
  final String key;
  final String label;
  final double flex;
  const _ColDef(this.key, this.label, this.flex);
}

const _columns = [
  _ColDef('no', '#', 0.4),
  _ColDef('nama', 'Nama Pasien', 1.6),
  _ColDef('nik', 'NIK', 1.4),
  _ColDef('tanggal', 'Tanggal', 1.0),
  _ColDef('keluhan', 'Keluhan', 1.8),
  _ColDef('diagnosa', 'Diagnosa', 1.6),
  _ColDef('aksi', 'Aksi', 0.9),
];

// ── Sort state ────────────────────────────────────────────────────────────────

enum _SortDir { none, asc, desc }

class _SortState {
  final String col;
  final _SortDir dir;
  const _SortState(this.col, this.dir);
}

// ─────────────────────────────────────────────────────────────────────────────

class DataScreen extends StatefulWidget {
  const DataScreen({super.key});

  @override
  State<DataScreen> createState() => _DataScreenState();
}

class _DataScreenState extends State<DataScreen> {
  final _db = DatabaseService();
  final _scrollH = ScrollController(); // horizontal scroll
  final _scrollV = ScrollController(); // vertical scroll

  List<Patient> _all = [];
  List<Patient> _filtered = [];
  bool _isLoading = true;
  String _searchQuery = '';
  _SortState _sort = const _SortState('', _SortDir.none);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _scrollH.dispose();
    _scrollV.dispose();
    super.dispose();
  }

  // ── Data ──────────────────────────────────────────────────────────────────

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    _all = await _db.getPatients();
    _applyFilterAndSort();
    setState(() => _isLoading = false);
  }

  void _applyFilterAndSort() {
    final q = _searchQuery.toLowerCase();

    var list = q.isEmpty
        ? List<Patient>.from(_all)
        : _all.where((p) {
            return p.nama.toLowerCase().contains(q) ||
                p.nik.contains(q) ||
                p.diagnosa.toLowerCase().contains(q) ||
                p.keluhan.toLowerCase().contains(q);
          }).toList();

    if (_sort.dir != _SortDir.none) {
      list.sort((a, b) {
        final String va, vb;
        switch (_sort.col) {
          case 'nama':
            va = a.nama;
            vb = b.nama;
            break;
          case 'nik':
            va = a.nik;
            vb = b.nik;
            break;
          case 'tanggal':
            va = a.tanggal;
            vb = b.tanggal;
            break;
          case 'diagnosa':
            va = a.diagnosa;
            vb = b.diagnosa;
            break;
          default:
            va = '';
            vb = '';
        }
        final cmp = va.compareTo(vb);
        return _sort.dir == _SortDir.asc ? cmp : -cmp;
      });
    }

    _filtered = list;
  }

  void _onSearch(String q) {
    setState(() {
      _searchQuery = q;
      _applyFilterAndSort();
    });
  }

  void _onSort(String col) {
    setState(() {
      if (_sort.col == col) {
        _sort = _SortState(
          col,
          _sort.dir == _SortDir.asc ? _SortDir.desc : _SortDir.none,
        );
        if (_sort.dir == _SortDir.none)
          _sort = const _SortState('', _SortDir.none);
      } else {
        _sort = _SortState(col, _SortDir.asc);
      }
      _applyFilterAndSort();
    });
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _editPatient(Patient patient) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: const Text('Edit Pasien'),
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: AppTheme.appBarGradient,
              ),
            ),
          ),
          body: InputScreen(patient: patient),
        ),
      ),
    );
    if (updated == true) await _loadData();
  }

  Future<void> _deletePatient(Patient patient) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.warning_rounded, color: Colors.red, size: 22),
            SizedBox(width: 8),
            Text('Hapus Pasien'),
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
              const TextSpan(text: 'Yakin menghapus data '),
              TextSpan(
                text: patient.nama,
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

    if (confirm == true && patient.id != null) {
      await _db.deletePatient(patient.id!);
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text('Data ${patient.nama} dihapus'),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red.shade700,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            AppSearchBar(
              hint: 'Cari nama, NIK, keluhan, atau diagnosa...',
              onChanged: _onSearch,
              onClear: () => _onSearch(''),
            ),
            const SizedBox(height: 16),
            _buildTableInfo(),
            const SizedBox(height: 8),
            Expanded(child: _buildTable()),
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
                'Data Pasien',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                '${_all.length} pasien terdaftar',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
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
    );
  }

  Widget _buildTableInfo() {
    final showing = _filtered.length;
    final total = _all.length;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _searchQuery.isEmpty
                ? 'Menampilkan $total data'
                : 'Ditemukan $showing dari $total data',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.primary,
            ),
          ),
        ),
        if (_sort.dir != _SortDir.none) ...[
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => setState(() {
              _sort = const _SortState('', _SortDir.none);
              _applyFilterAndSort();
            }),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.sort_rounded,
                    size: 13,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Urut: ${_sort.col} ${_sort.dir == _SortDir.asc ? '↑' : '↓'}  ✕',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTable() {
    return Container(
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
                message: 'Belum ada data pasien',
                icon: Icons.people_outline_rounded,
              )
            : _filtered.isEmpty
            ? const EmptyState(
                message: 'Tidak ada data yang cocok\ndengan pencarian',
                icon: Icons.search_off_rounded,
              )
            : Column(
                children: [
                  // ── Header row ────────────────────────────────────
                  _TableHeader(columns: _columns, sort: _sort, onSort: _onSort),

                  // ── Data rows ─────────────────────────────────────
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollV,
                      itemCount: _filtered.length,
                      itemBuilder: (ctx, i) {
                        return _TableRow(
                          index: i,
                          patient: _filtered[i],
                          columns: _columns,
                          onEdit: _editPatient,
                          onDelete: _deletePatient,
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

// ─── TABLE HEADER ─────────────────────────────────────────────────────────────

class _TableHeader extends StatelessWidget {
  final List<_ColDef> columns;
  final _SortState sort;
  final ValueChanged<String> onSort;

  const _TableHeader({
    required this.columns,
    required this.sort,
    required this.onSort,
  });

  static const _sortable = {'nama', 'nik', 'tanggal', 'diagnosa'};

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
            final isSortable = _sortable.contains(col.key);
            final isSorted = sort.col == col.key;

            return Expanded(
              flex: (col.flex * 10).toInt(),
              child: GestureDetector(
                onTap: isSortable ? () => onSort(col.key) : null,
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
                          color: isSorted
                              ? AppTheme.primary
                              : AppTheme.textPrimary,
                          letterSpacing: 0.3,
                        ),
                      ),
                      if (isSortable) ...[
                        const SizedBox(width: 4),
                        Icon(
                          isSorted && sort.dir == _SortDir.asc
                              ? Icons.arrow_upward_rounded
                              : isSorted && sort.dir == _SortDir.desc
                              ? Icons.arrow_downward_rounded
                              : Icons.unfold_more_rounded,
                          size: 13,
                          color: isSorted
                              ? AppTheme.primary
                              : AppTheme.textSecondary.withOpacity(0.5),
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

class _TableRow extends StatefulWidget {
  final int index;
  final Patient patient;
  final List<_ColDef> columns;
  final Future<void> Function(Patient) onEdit;
  final Future<void> Function(Patient) onDelete;

  const _TableRow({
    required this.index,
    required this.patient,
    required this.columns,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_TableRow> createState() => _TableRowState();
}

class _TableRowState extends State<_TableRow> {
  bool _hovered = false;

  String _cellValue(String key) {
    switch (key) {
      case 'no':
        return '${widget.index + 1}';
      case 'nama':
        return widget.patient.nama;
      case 'nik':
        return widget.patient.nik;
      case 'tanggal':
        return widget.patient.tanggal;
      case 'keluhan':
        return widget.patient.keluhan;
      case 'diagnosa':
        return widget.patient.diagnosa;
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEven = widget.index % 2 == 0;

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
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade100, width: 1),
          ),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: widget.columns.map((col) {
              return Expanded(
                flex: (col.flex * 10).toInt(),
                child: col.key == 'aksi'
                    ? _AksiCell(
                        patient: widget.patient,
                        onEdit: widget.onEdit,
                        onDelete: widget.onDelete,
                      )
                    : col.key == 'no'
                    ? _NoCell(value: _cellValue(col.key))
                    : col.key == 'diagnosa'
                    ? _DiagnosaCell(value: widget.patient.diagnosa)
                    : _TextCell(
                        value: _cellValue(col.key),
                        muted: col.key == 'nik',
                      ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

// ─── CELL WIDGETS ─────────────────────────────────────────────────────────────

class _NoCell extends StatelessWidget {
  final String value;
  const _NoCell({required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      alignment: Alignment.center,
      child: Text(
        value,
        style: const TextStyle(
          fontSize: 12,
          color: AppTheme.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _TextCell extends StatelessWidget {
  final String value;
  final bool muted;
  const _TextCell({required this.value, this.muted = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      alignment: Alignment.centerLeft,
      child: Text(
        value,
        style: TextStyle(
          fontSize: 13,
          color: muted ? AppTheme.textSecondary : AppTheme.textPrimary,
          fontFamily: muted ? 'monospace' : null,
          letterSpacing: muted ? 0.5 : 0,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 2,
      ),
    );
  }
}

class _DiagnosaCell extends StatelessWidget {
  final String value;
  const _DiagnosaCell({required this.value});

  // Warna badge berdasarkan hash string → konsisten per diagnosa
  Color _badgeColor(String text) {
    final colors = [
      const Color(0xFF1A56DB),
      const Color(0xFF0E9F6E),
      const Color(0xFFE3A008),
      const Color(0xFFE02424),
      const Color(0xFF7E3AF2),
      const Color(0xFFFF5A1F),
    ];
    return colors[text.hashCode.abs() % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final color = _badgeColor(value);
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
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _AksiCell extends StatelessWidget {
  final Patient patient;
  final Future<void> Function(Patient) onEdit;
  final Future<void> Function(Patient) onDelete;

  const _AksiCell({
    required this.patient,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Edit ──────────────────────────────────────────────────────────
          Tooltip(
            message: 'Edit',
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => onEdit(patient),
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

          // ── Delete ────────────────────────────────────────────────────────
          Tooltip(
            message: 'Hapus',
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => onDelete(patient),
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
  }
}
