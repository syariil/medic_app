import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/visit.dart';
import '../models/medicine.dart';
import '../models/visit_prescription.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../components/form/labeled_text_field.dart';
import '../components/form/prescription_form.dart';
import '../components/oh_shared.dart';
import 'base_input_screen.dart';

class VisitInputScreen extends InputScreenBase<Visit> {
  const VisitInputScreen({super.key, Visit? visit}) : super(entity: visit);

  @override
  State<VisitInputScreen> createState() => _VisitInputScreenState();
}

class _VisitInputScreenState extends _InputScreenBaseState<Visit, VisitInputScreen> {
  final _db = DatabaseService();

  // Controllers
  final _tanggal = TextEditingController();
  final _site = TextEditingController();
  final _nama = TextEditingController();
  final _posisi = TextEditingController();
  final _departemen = TextEditingController();
  final _keluhan = TextEditingController();
  final _diagnosa = TextEditingController();
  final _jamTidur = TextEditingController();
  final _suhu = TextEditingController();
  final _tdSistolik = TextEditingController();
  final _tdDiastolik = TextEditingController();
  final _pernapasan = TextEditingController();
  final _nadi = TextEditingController();
  final _keterangan = TextEditingController();

  // Resep
  List<Medicine> _medicines = [];
  List<VisitPrescriptionItem> _rxItems = [];
  String _rxCatatan = '';
  bool _withPrescription = false;

  // Resep existing (edit mode)
  VisitPrescriptionWithItems? _existingRx;

  @override
  void initState() {
    super.initState();
    _loadMedicines();
    if (isEdit) {
      final v = widget.entity!;
      _tanggal.text = v.tanggal;
      _site.text = v.site;
      _nama.text = v.nama;
      _posisi.text = v.posisi;
      _departemen.text = v.departemen;
      _keluhan.text = v.keluhan;
      _diagnosa.text = v.diagnosa;
      _jamTidur.text = v.jumlahJamTidur.toString();
      _suhu.text = v.suhuBadan.toString();
      final td = v.tekananDarah.split('/');
      _tdSistolik.text = td.isNotEmpty ? td[0] : '';
      _tdDiastolik.text = td.length > 1 ? td[1] : '';
      _pernapasan.text = v.pernapasan.toString();
      _nadi.text = v.nadi.toString();
      _keterangan.text = v.keterangan;
      _loadExistingPrescription();
    }
  }

  @override
  void disposeControllers() {
    for (final c in [
      _tanggal,
      _site,
      _nama,
      _posisi,
      _departemen,
      _keluhan,
      _diagnosa,
      _jamTidur,
      _suhu,
      _tdSistolik,
      _tdDiastolik,
      _pernapasan,
      _nadi,
      _keterangan,
    ]) {
      c.dispose();
    }
  }

  Future<void> _loadMedicines() async {
    final list = await _db.getMedicines();
    setState(() => _medicines = list);
  }

  Future<void> _loadExistingPrescription() async {
    if (widget.visit?.id == null) return;
    final list = await _db.getVisitPrescriptions(widget.visit!.id!);
    if (list.isNotEmpty) {
      setState(() {
        _existingRx = list.first;
        _rxCatatan = list.first.prescription.catatan;
        _withPrescription = true;
        // Convert VisitPrescriptionItem → PrescriptionItem-compatible
        _rxItems = list.first.items;
      });
    }
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_tanggal.text) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (d != null) {
      setState(() => _tanggal.text = d.toIso8601String().substring(0, 10));
    }
  }

  @override
  Future<void> saveEntity() async {
    final visit = Visit(
      id: widget.entity?.id,
      tanggal: _tanggal.text.trim(),
      site: _site.text.trim(),
      nama: _nama.text.trim(),
      posisi: _posisi.text.trim(),
      departemen: _departemen.text.trim(),
      keluhan: _keluhan.text.trim(),
      diagnosa: _diagnosa.text.trim(),
      jumlahJamTidur: double.tryParse(_jamTidur.text) ?? 0,
      suhuBadan: double.tryParse(_suhu.text) ?? 0,
      tekananDarah: '${_tdSistolik.text.trim()}/${_tdDiastolik.text.trim()}',
      pernapasan: int.tryParse(_pernapasan.text) ?? 0,
      nadi: int.tryParse(_nadi.text) ?? 0,
      keterangan: _keterangan.text.trim(),
    );

    int visitId;
    if (isEdit) {
      await _db.updateVisit(visit);
      visitId = visit.id!;
    } else {
      visitId = await _db.insertVisit(visit);
    }

    // ── Handle resep kunjungan ─────────────────────────────────────────
    if (_withPrescription && _rxItems.isNotEmpty) {
      final rx = VisitPrescription(
        id: _existingRx?.prescription.id,
        visitId: visitId,
        tanggal: _tanggal.text.trim(),
        catatan: _rxCatatan,
      );

      if (_existingRx != null) {
        await _db.updateVisitPrescription(rx, _rxItems);
      } else {
        await _db.insertVisitPrescription(rx, _rxItems);
      }
    } else if (!_withPrescription && _existingRx != null) {
      // User matikan toggle → hapus resep lama + kembalikan stok
      await _db.deleteVisitPrescriptions(visitId);
    }
  }

  @override
  String getSuccessMessage() =>
      isEdit
          ? 'Data kunjungan & resep diperbarui'
          : 'Kunjungan berhasil disimpan';

  @override
  Widget buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Text(
          isEdit ? 'Edit Kunjungan' : 'Input Kunjungan',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        Text(
          isEdit
              ? 'Ubah data kunjungan & resep'
              : 'Isi data kunjungan, diagnosa, dan resep obat',
          style: const TextStyle(
            fontSize: 13,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 20),

        // ── Informasi Umum ────────────────────────────────────────────
        _SectionCard(
          title: 'Informasi Umum',
          icon: Icons.badge_rounded,
          color: AppTheme.primary,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: LabeledTextField(
                      label: 'Tanggal',
                      controller: _tanggal,
                      hint: 'Pilih tanggal',
                      readOnly: true,
                      onTap: _pickDate,
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'Tanggal wajib diisi'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: LabeledTextField(
                      label: 'Site',
                      controller: _site,
                      hint: 'Nama site',
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Wajib' : null,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: LabeledTextField(
                      label: 'Departemen',
                      controller: _departemen,
                      hint: 'Nama departemen',
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Wajib' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: LabeledTextField(
                      label: 'Posisi / Jabatan',
                      controller: _posisi,
                      hint: 'Contoh: Operator, Supervisor',
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Wajib' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: LabeledTextField(
                      label: 'Nama',
                      controller: _nama,
                      hint: 'Nama lengkap',
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'Nama wajib diisi'
                          : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ── Keluhan & Diagnosa ────────────────────────────────────────
        _SectionCard(
          title: 'Keluhan & Diagnosa',
          icon: Icons.medical_services_rounded,
          color: const Color(0xFF7E3AF2),
          child: Row(
            children: [
              Expanded(
                child: LabeledTextField(
                  label: 'Keluhan',
                  controller: _keluhan,
                  hint: 'Deskripsikan keluhan pasien',
                  // maxLines: 3,
                  validator: (v) => (v == null || v.isEmpty)
                      ? 'Keluhan wajib diisi'
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: LabeledTextField(
                  label: 'Diagnosa',
                  controller: _diagnosa,
                  hint: 'Masukkan diagnosa',
                  validator: (v) => (v == null || v.isEmpty)
                      ? 'Diagnosa wajib diisi'
                      : null,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ── Vital Sign ────────────────────────────────────────────────
        _SectionCard(
          title: 'Vital Sign',
          icon: Icons.monitor_heart_rounded,
          color: Colors.red,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _numField(
                      'Jam Tidur (jam)',
                      _jamTidur,
                      hint: '7.5',
                      isDecimal: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _numField(
                      'Suhu Badan (°C)',
                      _suhu,
                      hint: '36.5',
                      isDecimal: true,
                    ),
                  ),
                ],
              ),
              OhFieldLabel(
                label: 'Tekanan Darah (mmHg)',
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _tdSistolik,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          hintText: 'Sistolik',
                        ),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Wajib' : null,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        '/',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                    Expanded(
                      child: TextFormField(
                        controller: _tdDiastolik,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          hintText: 'Diastolik',
                        ),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Wajib' : null,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: _numField(
                      'Pernapasan (x/mnt)',
                      _pernapasan,
                      hint: '18',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _numField('Nadi (x/mnt)', _nadi, hint: '80'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ── Resep Obat ────────────────────────────────────────────────
        _SectionCard(
          title: 'Resep Obat',
          icon: Icons.medication_rounded,
          color: AppTheme.accent,
          trailing: Switch(
            value: _withPrescription,
            activeColor: AppTheme.primary,
            onChanged: (v) => setState(() => _withPrescription = v),
          ),
          child: _withPrescription
              ? (_medicines.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: const [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.orange,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Belum ada data obat. Tambahkan di menu Farmasi terlebih dahulu.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.orange,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    // Reuse PrescriptionForm dengan adapter
                    : _VisitPrescriptionFormAdapter(
                        medicines: _medicines,
                        initialItems: _rxItems,
                        initialCatatan: _rxCatatan,
                        onItemsChanged: (items) =>
                            setState(() => _rxItems = items),
                        onCatatanChanged: (v) => _rxCatatan = v,
                      ))
              : Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Aktifkan toggle untuk menambahkan resep obat.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary.withOpacity(0.6),
                    ),
                  ),
                ),
        ),
        const SizedBox(height: 14),

        // ── Keterangan ────────────────────────────────────────────────
        _SectionCard(
          title: 'Keterangan',
          icon: Icons.notes_rounded,
          color: Colors.grey,
          child: LabeledTextField(
            label: 'Keterangan',
            controller: _keterangan,
            hint: 'Catatan tambahan (opsional)',
            maxLines: 3,
          ),
        ),
        const SizedBox(height: 24),

        // ── Tombol ────────────────────────────────────────────────────
        Row(
          children: [
            if (!isEdit) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: isSaving ? null : _resetForm,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Reset'),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: isSaving ? null : submit,
                icon: isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_rounded, size: 18),
                label: Text(isEdit ? 'Update Data' : 'Simpan Kunjungan'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _resetForm() {
    formKey.currentState?.reset();
    for (final c in [
      _tanggal,
      _site,
      _nama,
      _posisi,
      _departemen,
      _keluhan,
      _diagnosa,
      _jamTidur,
      _suhu,
      _tdSistolik,
      _tdDiastolik,
      _pernapasan,
      _nadi,
      _keterangan,
    ]) {
      c.clear();
    }
    setState(() {
      _rxItems = [];
      _rxCatatan = '';
      _withPrescription = false;
    });
  }

  Widget _numField(
    String label,
    TextEditingController ctrl, {
    String? hint,
    bool isDecimal = false,
  }) => OhFieldLabel(
    label: label,
    child: TextFormField(
      controller: ctrl,
      keyboardType: TextInputType.numberWithOptions(decimal: isDecimal),
      inputFormatters: isDecimal
          ? [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))]
          : [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(hintText: hint),
      validator: (v) => (v == null || v.isEmpty) ? 'Wajib' : null,
    ),
  );
}

// ─── Section card ─────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Widget child;
  final Widget? trailing;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: AppTheme.cardShadow,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
        const SizedBox(height: 16),
        child,
      ],
    ),
  );
}

// ─── Adapter — PrescriptionForm menghasilkan PrescriptionItem,
//     tapi kita butuh VisitPrescriptionItem ─────────────────────────────────

class _VisitPrescriptionFormAdapter extends StatefulWidget {
  final List<Medicine> medicines;
  final List<VisitPrescriptionItem> initialItems;
  final String initialCatatan;
  final ValueChanged<List<VisitPrescriptionItem>> onItemsChanged;
  final ValueChanged<String> onCatatanChanged;

  const _VisitPrescriptionFormAdapter({
    required this.medicines,
    required this.initialItems,
    required this.initialCatatan,
    required this.onItemsChanged,
    required this.onCatatanChanged,
  });

  @override
  State<_VisitPrescriptionFormAdapter> createState() =>
      _VisitPrescriptionFormAdapterState();
}

class _VisitPrescriptionFormAdapterState
    extends State<_VisitPrescriptionFormAdapter> {
  // Reuse PrescriptionForm dari pasien — convert type saat keluar
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
      final med = widget.medicines
          .where((m) => m.id == item.medicineId)
          .firstOrNull;
      return _ItemRow(
        medicine: med,
        jumlahCtrl: TextEditingController(text: item.jumlah.toString()),
        aturanPakai: item.aturanPakai,
      );
    }).toList();
    if (_rows.isEmpty) _addRow();
  }

  @override
  void dispose() {
    _catatanCtrl.dispose();
    for (final r in _rows) r.jumlahCtrl.dispose();
    super.dispose();
  }

  void _addRow() => setState(
    () => _rows.add(
      _ItemRow(
        medicine: null,
        jumlahCtrl: TextEditingController(text: '1'),
        aturanPakai: '3x sehari',
      ),
    ),
  );

  void _removeRow(int i) {
    _rows[i].jumlahCtrl.dispose();
    setState(() => _rows.removeAt(i));
    _notify();
  }

  void _notify() {
    final items = <VisitPrescriptionItem>[];
    for (final r in _rows) {
      if (r.medicine == null) continue;
      items.add(
        VisitPrescriptionItem(
          visitPrescriptionId: 0,
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
              'Daftar Obat',
              style: TextStyle(
                fontSize: 14,
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
        const SizedBox(height: 10),

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
          ...List.generate(_rows.length, _buildRow),

        const SizedBox(height: 14),

        // Catatan
        const Text(
          'Catatan Resep',
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
            hintText: 'Catatan untuk pasien (opsional)',
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
          // Row 1 — pilih obat
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: DropdownButtonFormField<Medicine>(
                  value: row.medicine,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Obat',
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
                  hint: const Text(
                    'Pilih obat...',
                    style: TextStyle(fontSize: 13),
                  ),
                  items: widget.medicines.map((m) {
                    final low = m.stok <= 10;
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
                                  : low
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
                                    : low
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
                    setState(() {
                      _rows[i] = _ItemRow(
                        medicine: m,
                        jumlahCtrl: row.jumlahCtrl,
                        aturanPakai: row.aturanPakai,
                      );
                    });
                    _notify();
                  },
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: IconButton(
                  onPressed: () => _removeRow(i),
                  icon: const Icon(
                    Icons.remove_circle_rounded,
                    color: Colors.red,
                    size: 22,
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

          if (stokHabis)
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
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
            ),

          const SizedBox(height: 10),

          // Row 2 — jumlah + aturan
          Row(
            children: [
              // Jumlah stepper
              SizedBox(
                width: 120,
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
                        setState(() {
                          _rows[i] = _ItemRow(
                            medicine: row.medicine,
                            jumlahCtrl: row.jumlahCtrl,
                            aturanPakai: v,
                          );
                        });
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
  Widget build(BuildContext context) => GestureDetector(
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
