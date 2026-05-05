import 'package:flutter/material.dart';
import '../models/doctor.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../components/form/app_search_bar.dart';
import '../components/cards/empty_state.dart';
import 'doctor_input_screen.dart';

// ─── Kolom ───────────────────────────────────────────────────────────────────

class _Col {
  final String key;
  final String label;
  final double flex;
  const _Col(this.key, this.label, this.flex);
}

const _columns = [
  _Col('no', '#', 0.4),
  _Col('nama', 'Nama Dokter', 1.8),
  _Col('spesialis', 'Spesialisasi', 1.6),
  _Col('poli', 'Poli', 1.2),
  _Col('jadwal', 'Jadwal', 1.6),
  _Col('aksi', 'Aksi', 0.9),
];

enum _SortDir { none, asc, desc }

class _Sort {
  final String col;
  final _SortDir dir;
  const _Sort(this.col, this.dir);
}

// ─── SCREEN ───────────────────────────────────────────────────────────────────

class DoctorScreen extends StatefulWidget {
  const DoctorScreen({super.key});

  @override
  State<DoctorScreen> createState() => _DoctorScreenState();
}

class _DoctorScreenState extends State<DoctorScreen> {
  final _db = DatabaseService();

  List<Doctor> _all = [];
  List<Doctor> _filtered = [];
  bool _isLoading = true;
  String _searchQuery = '';
  _Sort _sort = const _Sort('', _SortDir.none);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    _all = await _db.getDoctors();
    _applyFilter();
    setState(() => _isLoading = false);
  }

  void _applyFilter() {
    final q = _searchQuery.toLowerCase();
    var list = q.isEmpty
        ? List<Doctor>.from(_all)
        : _all
              .where(
                (d) =>
                    d.nama.toLowerCase().contains(q) ||
                    d.spesialis.toLowerCase().contains(q) ||
                    d.poli.toLowerCase().contains(q),
              )
              .toList();

    if (_sort.dir != _SortDir.none) {
      list.sort((a, b) {
        final va = _sortVal(a, _sort.col);
        final vb = _sortVal(b, _sort.col);
        return _sort.dir == _SortDir.asc ? va.compareTo(vb) : vb.compareTo(va);
      });
    }
    _filtered = list;
  }

  String _sortVal(Doctor d, String col) {
    switch (col) {
      case 'nama':
        return d.nama;
      case 'spesialis':
        return d.spesialis;
      case 'poli':
        return d.poli;
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
      if (_sort.col == col) {
        _sort = _sort.dir == _SortDir.asc
            ? _Sort(col, _SortDir.desc)
            : const _Sort('', _SortDir.none);
      } else {
        _sort = _Sort(col, _SortDir.asc);
      }
      _applyFilter();
    });
  }

  Future<void> _edit(Doctor doctor) async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: const Text('Edit Dokter'),
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: AppTheme.appBarGradient,
              ),
            ),
          ),
          body: DoctorInputScreen(doctor: doctor),
        ),
      ),
    );
    if (ok == true) await _loadData();
  }

  Future<void> _delete(Doctor doctor) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.warning_rounded, color: Colors.red, size: 22),
            SizedBox(width: 8),
            Text('Hapus Dokter'),
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
                text: doctor.nama,
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

    if (ok == true && doctor.id != null) {
      await _db.deleteDoctor(doctor.id!);
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
              Text('Data ${doctor.nama} dihapus'),
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
                        'Data Dokter',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        '${_all.length} dokter terdaftar',
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
            ),

            const SizedBox(height: 16),
            AppSearchBar(
              hint: 'Cari nama, spesialisasi, atau poli...',
              onChanged: _onSearch,
              onClear: () => _onSearch(''),
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
                    _searchQuery.isEmpty
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
                          message: 'Belum ada data dokter',
                          icon: Icons.person_off_rounded,
                        )
                      : _filtered.isEmpty
                      ? const EmptyState(
                          message: 'Tidak ada data yang cocok',
                          icon: Icons.search_off_rounded,
                        )
                      : Column(
                          children: [
                            _DoctorTableHeader(
                              columns: _columns,
                              sort: _sort,
                              onSort: _onSort,
                            ),
                            Expanded(
                              child: ListView.builder(
                                itemCount: _filtered.length,
                                itemBuilder: (_, i) => _DoctorTableRow(
                                  index: i,
                                  doctor: _filtered[i],
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

class _DoctorTableHeader extends StatelessWidget {
  final List<_Col> columns;
  final _Sort sort;
  final ValueChanged<String> onSort;

  const _DoctorTableHeader({
    required this.columns,
    required this.sort,
    required this.onSort,
  });

  static const _sortable = {'nama', 'spesialis', 'poli'};

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

class _DoctorTableRow extends StatefulWidget {
  final int index;
  final Doctor doctor;
  final List<_Col> columns;
  final Future<void> Function(Doctor) onEdit;
  final Future<void> Function(Doctor) onDelete;

  const _DoctorTableRow({
    required this.index,
    required this.doctor,
    required this.columns,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_DoctorTableRow> createState() => _DoctorTableRowState();
}

class _DoctorTableRowState extends State<_DoctorTableRow> {
  bool _hovered = false;

  Color _spesialisColor(String s) {
    const colors = [
      Color(0xFF1A56DB),
      Color(0xFF0E9F6E),
      Color(0xFFE3A008),
      Color(0xFFE02424),
      Color(0xFF7E3AF2),
      Color(0xFFFF5A1F),
    ];
    return colors[s.hashCode.abs() % colors.length];
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
          border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: widget.columns.map((col) {
              return Expanded(
                flex: (col.flex * 10).toInt(),
                child: _buildCell(col),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildCell(_Col col) {
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
              CircleAvatar(
                radius: 16,
                backgroundColor: AppTheme.primary.withOpacity(0.1),
                child: Text(
                  widget.doctor.nama.isNotEmpty
                      ? widget.doctor.nama[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.doctor.nama,
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

      case 'spesialis':
        final color = _spesialisColor(widget.doctor.spesialis);
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
              widget.doctor.spesialis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );

      case 'poli':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              const Icon(
                Icons.room_rounded,
                size: 13,
                color: AppTheme.textSecondary,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  widget.doctor.poli,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );

      case 'jadwal':
        final hariList = widget.doctor.jadwal.split(', ');
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Wrap(
            spacing: 4,
            runSpacing: 4,
            children: hariList
                .map(
                  (h) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      h.trim(),
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
        );

      case 'aksi':
        return _AksiCell(
          onEdit: () => widget.onEdit(widget.doctor),
          onDelete: () => widget.onDelete(widget.doctor),
        );

      default:
        return const SizedBox.shrink();
    }
  }
}

// ─── AKSI CELL ────────────────────────────────────────────────────────────────

class _AksiCell extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _AksiCell({required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
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
              onTap: onEdit,
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
              onTap: onDelete,
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
