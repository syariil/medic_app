import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import '../models/patient.dart';
import '../theme/app_theme.dart';
import 'database_service.dart';

class PatientDataSource extends DataGridSource {
  final List<Patient> patients;
  final DatabaseService db;
  final BuildContext context;

  /// Dipanggil setelah delete → parent refresh list
  final VoidCallback? onDeleted;

  /// Dipanggil saat tombol Edit ditekan → parent buka InputScreen
  final Future<void> Function(Patient)? onEdit;

  late List<List<DataGridCell>> _rows;
  final TextEditingController _editCtrl = TextEditingController();

  PatientDataSource(
    this.patients,
    this.db,
    this.context, {
    this.onDeleted,
    this.onEdit,
  }) {
    _buildRows();
  }

  void _buildRows() {
    _rows = patients.map(_patientToCells).toList();
  }

  List<DataGridCell> _patientToCells(Patient p) => [
    DataGridCell<String>(columnName: 'nama', value: p.nama),
    DataGridCell<String>(columnName: 'nik', value: p.nik),
    DataGridCell<String>(columnName: 'tanggal', value: p.tanggal),
    DataGridCell<String>(columnName: 'keluhan', value: p.keluhan),
    DataGridCell<String>(columnName: 'diagnosa', value: p.diagnosa),
    DataGridCell<String>(columnName: 'aksi', value: ''),
  ];

  @override
  List<DataGridRow> get rows =>
      _rows.map((cells) => DataGridRow(cells: cells)).toList();

  // ── Edit Widget ────────────────────────────────────────────────────────────

  @override
  Widget? buildEditWidget(
    DataGridRow row,
    RowColumnIndex rowColumnIndex,
    GridColumn column,
    CellSubmit submitCell,
  ) {
    if (column.columnName == 'aksi') return null;

    final currentValue =
        row
            .getCells()
            .firstWhere((c) => c.columnName == column.columnName)
            .value
            ?.toString() ??
        '';

    _editCtrl.text = currentValue;

    // Kolom tanggal → date picker
    if (column.columnName == 'tanggal') {
      return InkWell(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: DateTime.tryParse(currentValue) ?? DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
          );
          if (picked != null) {
            _editCtrl.text = picked.toIso8601String().substring(0, 10);
            submitCell();
          }
        },
        child: Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            currentValue.isEmpty ? 'Pilih tanggal' : currentValue,
            style: const TextStyle(color: AppTheme.primary),
          ),
        ),
      );
    }

    return TextField(
      controller: _editCtrl,
      autofocus: true,
      decoration: const InputDecoration(
        contentPadding: EdgeInsets.symmetric(horizontal: 8),
        border: InputBorder.none,
      ),
      onSubmitted: (_) => submitCell(),
    );
  }

  // ── Cell Submit ────────────────────────────────────────────────────────────

  @override
  Future<void> onCellSubmit(
    DataGridRow row,
    RowColumnIndex rowColumnIndex,
    GridColumn column,
  ) async {
    if (column.columnName == 'aksi') return;

    final newValue = _editCtrl.text.trim();
    final rowIndex = rowColumnIndex.rowIndex - 1;
    if (rowIndex < 0 || rowIndex >= patients.length) return;

    final patient = patients[rowIndex];
    final oldValue = row
        .getCells()
        .firstWhere((c) => c.columnName == column.columnName)
        .value
        ?.toString();

    if (oldValue == newValue) return;

    switch (column.columnName) {
      case 'nama':
        patient.nama = newValue;
        break;
      case 'nik':
        patient.nik = newValue;
        break;
      case 'tanggal':
        patient.tanggal = newValue;
        break;
      case 'keluhan':
        patient.keluhan = newValue;
        break;
      case 'diagnosa':
        patient.diagnosa = newValue;
        break;
    }

    await db.updatePatient(patient);

    // FIX: rebuild row baru — tidak mutate UnmodifiableListView
    _rows[rowIndex] = _patientToCells(patient);
    notifyListeners();
  }

  // ── Build Row ──────────────────────────────────────────────────────────────

  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    final rowIndex = rows.indexOf(row);
    final patient = rowIndex >= 0 && rowIndex < patients.length
        ? patients[rowIndex]
        : null;

    return DataGridRowAdapter(
      cells: row.getCells().map((cell) {
        if (cell.columnName == 'aksi' && patient != null) {
          return _buildAksiCell(patient);
        }
        return Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Text(
            cell.value?.toString() ?? '',
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAksiCell(Patient patient) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Tombol Edit
        Tooltip(
          message: 'Edit',
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: () async {
              if (onEdit != null) {
                await onEdit!(patient);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(6),
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

        // Tombol Delete
        Tooltip(
          message: 'Hapus',
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: () => _confirmDelete(patient),
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                size: 15,
                color: Colors.red,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(Patient patient) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Pasien'),
        content: Text(
          'Yakin menghapus data ${patient.nama}?\n'
          'Tindakan ini tidak bisa dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true && patient.id != null) {
      await db.deletePatient(patient.id!);
      onDeleted?.call();
    }
  }

  @override
  void dispose() {
    _editCtrl.dispose();
    super.dispose();
  }
}
