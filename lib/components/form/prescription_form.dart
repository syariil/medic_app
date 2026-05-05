import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/medicine.dart';
import '../../models/prescription.dart';
import '../../theme/app_theme.dart';

/// Widget form resep yang dapat disematkan ke halaman manapun.
/// Menerima daftar obat tersedia dan mengembalikan list [PrescriptionItem]
/// via [onChanged].
class PrescriptionForm extends StatefulWidget {
  final List<Medicine> medicines;
  final List<PrescriptionItem> initialItems;
  final String initialCatatan;
  final ValueChanged<List<PrescriptionItem>> onItemsChanged;
  final ValueChanged<String> onCatatanChanged;

  const PrescriptionForm({
    super.key,
    required this.medicines,
    required this.initialItems,
    required this.initialCatatan,
    required this.onItemsChanged,
    required this.onCatatanChanged,
  });

  @override
  State<PrescriptionForm> createState() => _PrescriptionFormState();
}

class _PrescriptionFormState extends State<PrescriptionForm> {
  late List<_ItemRow> _rows;
  late TextEditingController _catatanCtrl;

  static const _aturanList = [
    '1x sehari',
    '2x sehari',
    '3x sehari',
    'Sebelum makan',
    'Sesudah makan',
    'Jika perlu',
  ];

  @override
  void initState() {
    super.initState();
    _catatanCtrl = TextEditingController(text: widget.initialCatatan);
    _rows = widget.initialItems.map((item) {
      final medicine = widget.medicines
          .where((m) => m.id == item.medicineId)
          .firstOrNull;
      return _ItemRow(
        medicine: medicine,
        jumlahCtrl: TextEditingController(text: item.jumlah.toString()),
        aturanPakai: item.aturanPakai,
      );
    }).toList();
    if (_rows.isEmpty) _addRow();
  }

  @override
  void dispose() {
    _catatanCtrl.dispose();
    for (final r in _rows) {
      r.jumlahCtrl.dispose();
    }
    super.dispose();
  }

  void _addRow() {
    setState(
      () => _rows.add(
        _ItemRow(
          medicine: null,
          jumlahCtrl: TextEditingController(text: '1'),
          aturanPakai: '3x sehari',
        ),
      ),
    );
  }

  void _removeRow(int index) {
    _rows[index].jumlahCtrl.dispose();
    setState(() => _rows.removeAt(index));
    _notify();
  }

  void _notify() {
    final items = <PrescriptionItem>[];
    for (final r in _rows) {
      if (r.medicine == null) continue;
      items.add(
        PrescriptionItem(
          prescriptionId: 0,
          medicineId: r.medicine!.id!,
          medicineName: r.medicine!.nama,
          satuan: r.medicine!.satuan,
          jumlah: int.tryParse(r.jumlahCtrl.text) ?? 1,
          aturanPakai: r.aturanPakai,
        ),
      );
    }
    widget.onItemsChanged(items);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ──────────────────────────────────────────────────────────
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.medication_rounded,
                size: 18,
                color: AppTheme.accent,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Resep Obat',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _addRow,
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Tambah Obat'),
              style: TextButton.styleFrom(foregroundColor: AppTheme.primary),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // ── Item rows ────────────────────────────────────────────────────────
        if (_rows.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: const Center(
              child: Text(
                'Belum ada obat. Klik "Tambah Obat".',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
            ),
          )
        else
          ...List.generate(_rows.length, (i) => _buildRow(i)),

        const SizedBox(height: 16),

        // ── Catatan ──────────────────────────────────────────────────────────
        const Text(
          'Catatan Dokter',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _catatanCtrl,
          maxLines: 2,
          decoration: const InputDecoration(
            hintText: 'Catatan tambahan untuk pasien (opsional)',
          ),
          onChanged: widget.onCatatanChanged,
        ),
      ],
    );
  }

  Widget _buildRow(int i) {
    final row = _rows[i];
    final stokHabis = row.medicine != null && row.medicine!.stok <= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: stokHabis ? Colors.red.withOpacity(0.03) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: stokHabis ? Colors.red.withOpacity(0.3) : Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          // Baris 1: pilih obat + tombol hapus
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Obat',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<Medicine>(
                      value: row.medicine,
                      isExpanded: true,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      hint: const Text('Pilih obat...'),
                      items: widget.medicines.map((m) {
                        final lowStock = m.stok <= 10;
                        return DropdownMenuItem(
                          value: m,
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${m.nama} (${m.satuan})',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: m.stok == 0
                                      ? Colors.red.withOpacity(0.1)
                                      : lowStock
                                      ? Colors.orange.withOpacity(0.1)
                                      : AppTheme.accent.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${m.stok}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: m.stok == 0
                                        ? Colors.red
                                        : lowStock
                                        ? Colors.orange
                                        : AppTheme.accent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (m) {
                        setState(
                          () => _rows[i] = _ItemRow(
                            medicine: m,
                            jumlahCtrl: row.jumlahCtrl,
                            aturanPakai: row.aturanPakai,
                          ),
                        );
                        _notify();
                      },
                    ),
                    if (stokHabis)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: const [
                            Icon(
                              Icons.error_outline_rounded,
                              size: 12,
                              color: Colors.red,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Stok habis',
                              style: TextStyle(fontSize: 11, color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 22),
                child: IconButton(
                  onPressed: () => _removeRow(i),
                  icon: const Icon(
                    Icons.remove_circle_rounded,
                    color: Colors.red,
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Baris 2: jumlah + aturan pakai
          Row(
            children: [
              // Jumlah
              SizedBox(
                width: 90,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Jumlah',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        // Minus
                        _StepBtn(
                          icon: Icons.remove,
                          onTap: () {
                            final v = int.tryParse(row.jumlahCtrl.text) ?? 1;
                            if (v > 1) {
                              row.jumlahCtrl.text = (v - 1).toString();
                              _notify();
                            }
                          },
                        ),
                        Expanded(
                          child: TextField(
                            controller: row.jumlahCtrl,
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 8,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            style: const TextStyle(fontSize: 13),
                            onChanged: (_) => _notify(),
                          ),
                        ),
                        // Plus
                        _StepBtn(
                          icon: Icons.add,
                          onTap: () {
                            final v = int.tryParse(row.jumlahCtrl.text) ?? 1;
                            final max = row.medicine?.stok ?? 999;
                            if (v < max) {
                              row.jumlahCtrl.text = (v + 1).toString();
                              _notify();
                            }
                          },
                        ),
                      ],
                    ),
                    if (row.medicine != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          'Stok: ${row.medicine!.stok} ${row.medicine!.satuan}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Aturan pakai
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Aturan Pakai',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      value: _aturanList.contains(row.aturanPakai)
                          ? row.aturanPakai
                          : _aturanList.first,
                      isExpanded: true,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: _aturanList
                          .map(
                            (a) => DropdownMenuItem(
                              value: a,
                              child: Text(
                                a,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        setState(
                          () => _rows[i] = _ItemRow(
                            medicine: row.medicine,
                            jumlahCtrl: row.jumlahCtrl,
                            aturanPakai: v,
                          ),
                        );
                        _notify();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Helper classes ────────────────────────────────────────────────────────────

class _ItemRow {
  final Medicine? medicine;
  final TextEditingController jumlahCtrl;
  final String aturanPakai;

  const _ItemRow({
    required this.medicine,
    required this.jumlahCtrl,
    required this.aturanPakai,
  });
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _StepBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 36,
        decoration: BoxDecoration(
          color: AppTheme.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 14, color: AppTheme.primary),
      ),
    );
  }
}
