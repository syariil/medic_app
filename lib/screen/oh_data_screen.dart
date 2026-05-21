import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../components/form/app_search_bar.dart';
import '../components/cards/empty_state.dart';

// ─────────────────────────────────────────────────────────────
// COLUMN
// ─────────────────────────────────────────────────────────────

class OhCol {
  final String key;
  final String label;
  final double flex;

  const OhCol(this.key, this.label, this.flex);
}

// ─────────────────────────────────────────────────────────────
// SORT
// ─────────────────────────────────────────────────────────────

enum OhSortDir { none, asc, desc }

class OhSort {
  final String col;
  final OhSortDir dir;

  const OhSort(this.col, this.dir);

  const OhSort.none() : col = '', dir = OhSortDir.none;
}

// ─────────────────────────────────────────────────────────────
// MAIN SCREEN
// ─────────────────────────────────────────────────────────────

class OhDataScreen<T> extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  final List<OhCol> columns;

  final Future<List<T>> Function(String query) fetchData;

  final List<String> Function(T item, int index) cellValues;

  // nullable custom widget
  final Widget? Function(T item, String col)? customCell;

  final Future<void> Function(T item) onEdit;
  final Future<void> Function(T item) onDelete;

  final Widget Function(T item)? statusBadge;

  const OhDataScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.columns,
    required this.fetchData,
    required this.cellValues,
    this.customCell,
    required this.onEdit,
    required this.onDelete,
    this.statusBadge,
  });

  @override
  State<OhDataScreen<T>> createState() => _OhDataScreenState<T>();
}

class _OhDataScreenState<T> extends State<OhDataScreen<T>> {
  List<T> _all = [];
  List<T> _filtered = [];

  bool _isLoading = true;

  String _query = '';

  OhSort _sort = const OhSort.none();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);

    _all = await widget.fetchData('');

    _applySearch(_query);

    setState(() => _isLoading = false);
  }

  void _applySearch(String q) {
    _query = q;

    final ql = q.toLowerCase();

    setState(() {
      _filtered = ql.isEmpty
          ? List.from(_all)
          : _all.where((item) {
              final cells = widget.cellValues(item, 0);

              return cells.any((c) => c.toLowerCase().contains(ql));
            }).toList();
    });
  }

  void _onSort(String col) {
    setState(() {
      if (_sort.col == col) {
        _sort = _sort.dir == OhSortDir.asc
            ? OhSort(col, OhSortDir.desc)
            : const OhSort.none();
      } else {
        _sort = OhSort(col, OhSortDir.asc);
      }
    });

    if (_sort.dir == OhSortDir.none) return;

    _filtered.sort((a, b) {
      final va = widget.cellValues(a, 0);
      final vb = widget.cellValues(b, 0);

      final colIdx = widget.columns.indexWhere((c) => c.key == _sort.col);

      if (colIdx < 0 || colIdx >= va.length) {
        return 0;
      }

      final cmp = va[colIdx].compareTo(vb[colIdx]);

      return _sort.dir == OhSortDir.asc ? cmp : -cmp;
    });

    setState(() {});
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
            // HEADER
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: widget.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(widget.icon, size: 22, color: widget.color),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),

                      Text(
                        '${_all.length} ${widget.subtitle}',
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
                    backgroundColor: widget.color.withOpacity(0.1),
                    foregroundColor: widget.color,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // SEARCH
            AppSearchBar(
              hint: 'Cari nama, site, departemen...',
              onChanged: _applySearch,
              onClear: () => _applySearch(''),
            ),

            const SizedBox(height: 12),

            // INFO
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: widget.color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _query.isEmpty
                    ? 'Menampilkan ${_all.length} data'
                    : 'Ditemukan ${_filtered.length} dari ${_all.length} data',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: widget.color,
                ),
              ),
            ),

            const SizedBox(height: 8),

            // TABLE
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
                      : _filtered.isEmpty
                      ? const EmptyState(
                          message: 'Tidak ada data',
                          icon: Icons.search_off_rounded,
                        )
                      : Column(
                          children: [
                            _TableHeader(
                              columns: widget.columns,
                              sort: _sort,
                              color: widget.color,
                              onSort: _onSort,
                            ),

                            Expanded(
                              child: ListView.builder(
                                itemCount: _filtered.length,
                                itemBuilder: (_, i) => _TableRow(
                                  index: i,
                                  item: _filtered[i],
                                  columns: widget.columns,

                                  cellValues: widget.cellValues(
                                    _filtered[i],
                                    i,
                                  ),

                                  customCell: widget.customCell != null
                                      ? (col) => widget.customCell!(
                                          _filtered[i],
                                          col,
                                        )
                                      : null,

                                  statusBadge: widget.statusBadge != null
                                      ? widget.statusBadge!(_filtered[i])
                                      : null,

                                  onEdit: () => widget
                                      .onEdit(_filtered[i])
                                      .then((_) => _load()),

                                  onDelete: () => widget
                                      .onDelete(_filtered[i])
                                      .then((_) => _load()),
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

// ─────────────────────────────────────────────────────────────
// HEADER
// ─────────────────────────────────────────────────────────────

class _TableHeader extends StatelessWidget {
  final List<OhCol> columns;
  final OhSort sort;
  final Color color;

  final ValueChanged<String> onSort;

  const _TableHeader({
    required this.columns,
    required this.sort,
    required this.color,
    required this.onSort,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.08), color.withOpacity(0.04)],
        ),
      ),
      child: Row(
        children: columns.map((col) {
          final sorted = sort.col == col.key;

          return Expanded(
            flex: (col.flex * 10).toInt(),
            child: InkWell(
              onTap: () => onSort(col.key),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        col.label,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: sorted ? color : AppTheme.textPrimary,
                        ),
                      ),
                    ),

                    if (col.key != 'aksi')
                      Icon(
                        sorted && sort.dir == OhSortDir.asc
                            ? Icons.arrow_upward_rounded
                            : sorted && sort.dir == OhSortDir.desc
                            ? Icons.arrow_downward_rounded
                            : Icons.unfold_more_rounded,
                        size: 11,
                        color: sorted ? color : Colors.grey,
                      ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ROW
// ─────────────────────────────────────────────────────────────

class _TableRow<T> extends StatefulWidget {
  final int index;
  final T item;

  final List<OhCol> columns;

  final List<String> cellValues;

  final Widget? Function(String col)? customCell;

  final Widget? statusBadge;

  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TableRow({
    required this.index,
    required this.item,
    required this.columns,
    required this.cellValues,
    this.customCell,
    this.statusBadge,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_TableRow<T>> createState() => _TableRowState<T>();
}

class _TableRowState<T> extends State<_TableRow<T>> {
  bool _hovered = false;

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
              ? AppTheme.primary.withOpacity(0.03)
              : isEven
              ? Colors.white
              : const Color(0xFFFAFBFF),

          border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
        ),

        child: Row(
          children: widget.columns.asMap().entries.map((entry) {
            final i = entry.key;
            final col = entry.value;

            // AKSI
            if (col.key == 'aksi') {
              return Expanded(
                flex: (col.flex * 10).toInt(),
                child: _AksiCell(
                  onEdit: widget.onEdit,
                  onDelete: widget.onDelete,
                ),
              );
            }

            // STATUS
            if (col.key == 'status' && widget.statusBadge != null) {
              return Expanded(
                flex: (col.flex * 10).toInt(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  child: widget.statusBadge!,
                ),
              );
            }

            // CUSTOM CELL
            if (widget.customCell != null) {
              final custom = widget.customCell!(col.key);

              if (custom != null) {
                return Expanded(flex: (col.flex * 10).toInt(), child: custom);
              }
            }

            // DEFAULT CELL
            final val = i < widget.cellValues.length
                ? widget.cellValues[i]
                : '';

            return Expanded(
              flex: (col.flex * 10).toInt(),
              child: Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 12,
                ),
                child: Text(
                  val,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppTheme.textPrimary,
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

// ─────────────────────────────────────────────────────────────
// AKSI CELL
// ─────────────────────────────────────────────────────────────

class _AksiCell extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AksiCell({required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _btn(
            icon: Icons.edit_rounded,
            color: AppTheme.primary,
            tooltip: 'Edit',
            onTap: onEdit,
          ),

          const SizedBox(width: 6),

          _btn(
            icon: Icons.delete_rounded,
            color: Colors.red,
            tooltip: 'Hapus',
            onTap: onDelete,
          ),
        ],
      ),
    );
  }

  Widget _btn({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
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
}
