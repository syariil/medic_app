import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/fit_to_work.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../components/form/labeled_text_field.dart';
import '../components/oh_shared.dart';
import 'base_input_screen.dart';
import '../validators.dart';

class FitToWorkInputScreen extends InputScreenBase<FitToWork> {
  const FitToWorkInputScreen({super.key, FitToWork? record}) : super(entity: record);

  @override
  State<FitToWorkInputScreen> createState() => _FitToWorkInputScreenState();
}

class _FitToWorkInputScreenState extends _InputScreenBaseState<FitToWork, FitToWorkInputScreen> {
  final _db = DatabaseService();

  final _tanggal = TextEditingController();
  final _site = TextEditingController();
  final _nama = TextEditingController();
  final _posisi = TextEditingController();
  final _departemen = TextEditingController();
  final _lokasi = TextEditingController();
  final _jamTidur = TextEditingController();
  final _jamMasuk = TextEditingController();
  final _pembatasan = TextEditingController();
  final _keterangan = TextEditingController();

  String _shift = 'Pagi';
  String _kesehatan = 'Baik';
  bool _tidurKurang6 = false;
  bool _minumObat = false;

  @override
  void initState() {
    super.initState();
    if (isEdit) {
      final r = widget.entity as FitToWork;
      _tanggal.text = r.tanggal;
      _site.text = r.site;
      _nama.text = r.nama;
      _posisi.text = r.posisi;
      _departemen.text = r.departemen;
      _lokasi.text = r.lokasi;
      _jamTidur.text = r.jumlahJamTidur.toString();
      _jamMasuk.text = r.jamMasuk;
      _pembatasan.text = r.pembatasanKerja;
      _keterangan.text = r.keterangan;
      _shift = r.shift;
      _kesehatan = r.kesehatan;
      _tidurKurang6 = r.tidurKurangDari6;
      _minumObat = r.minumObat;
    } else {
      _pembatasan.text = kPembatasanDefault;
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
      _lokasi,
      _jamTidur,
      _jamMasuk,
      _pembatasan,
      _keterangan,
    ]) {
      c.dispose();
    }
  }

  bool get _isFitStatus =>
      !_tidurKurang6 &&
      _kesehatan == 'Baik' &&
      !_minumObat &&
      _pembatasan.text.trim() == 'Tidak Ada';

  @override
  void initState() {
    super.initState();
    if (isEdit) {
      final r = widget.entity as FitToWork;
      _tanggal.text = r.tanggal;
      _site.text = r.site;
      _nama.text = r.nama;
      _posisi.text = r.posisi;
      _departemen.text = r.departemen;
      _lokasi.text = r.lokasi;
      _jamTidur.text = r.jumlahJamTidur.toString();
      _jamMasuk.text = r.jamMasuk;
      _pembatasan.text = r.pembatasanKerja;
      _keterangan.text = r.keterangan;
      _shift = r.shift;
      _kesehatan = r.kesehatan;
      _tidurKurang6 = r.tidurKurangDari6;
      _minumObat = r.minumObat;
    } else {
      _pembatasan.text = kPembatasanDefault;
    }
  }

  @override
  void dispose() {
    for (final c in [
      _tanggal,
      _site,
      _nama,
      _posisi,
      _departemen,
      _lokasi,
      _jamTidur,
      _jamMasuk,
      _pembatasan,
      _keterangan,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_tanggal.text) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (d != null) _tanggal.text = d.toIso8601String().substring(0, 10);
  }

  @override
  Future<void> saveEntity() async {
    final record = FitToWork(
      id: widget.entity?.id,
      tanggal: _tanggal.text.trim(),
      site: _site.text.trim(),
      nama: _nama.text.trim(),
      posisi: _posisi.text.trim(),
      departemen: _departemen.text.trim(),
      lokasi: _lokasi.text.trim(),
      shift: _shift,
      jumlahJamTidur: double.tryParse(_jamTidur.text) ?? 0,
      jamMasuk: _jamMasuk.text.trim(),
      tidurKurangDari6: _tidurKurang6,
      kesehatan: _kesehatan,
      minumObat: _minumObat,
      pembatasanKerja: _pembatasan.text.trim(),
      keterangan: _keterangan.text.trim(),
    );

    if (isEdit) {
      await _db.updateFitToWork(record);
    } else {
      await _db.insertFitToWork(record);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(),
              const SizedBox(height: 20),
              _card(
                'Informasi Umum',
                Icons.info_outline_rounded,
                AppTheme.primary,
                _infoSection(),
              ),
              const SizedBox(height: 14),
              _card(
                'Kondisi Kerja',
                Icons.work_rounded,
                const Color(0xFFE3A008),
                _workSection(),
              ),
              const SizedBox(height: 14),
              _card(
                'Status Kesehatan',
                Icons.health_and_safety_rounded,
                Colors.green,
                _healthSection(),
              ),
              const SizedBox(height: 14),
              _statusPreview(),
              const SizedBox(height: 14),
              _card(
                'Keterangan',
                Icons.notes_rounded,
                Colors.grey,
                _notesSection(),
              ),
              const SizedBox(height: 24),
              _buildButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        isEdit ? 'Edit Fit To Work' : 'Input Fit To Work',
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: AppTheme.textPrimary,
        ),
      ),
      const Text(
        'Pemeriksaan kelayakan kerja',
        style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
      ),
    ],
  );

  Widget _card(String title, IconData icon, Color color, Widget child) =>
      Container(
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
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      );

  Widget _infoSection() => Column(
    children: [
      LabeledTextField(
        label: 'Tanggal',
        controller: _tanggal,
        hint: 'Pilih tanggal',
        readOnly: true,
        onTap: _pickDate,
        validator: (v) => (v == null || v.isEmpty) ? 'Wajib' : null,
      ),
      Row(
        children: [
          Expanded(
            child: LabeledTextField(
              label: 'Site',
              controller: _site,
              hint: 'Site',
              validator: (v) => (v == null || v.isEmpty) ? 'Wajib' : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: LabeledTextField(
              label: 'Departemen',
              controller: _departemen,
              hint: 'Departemen',
              validator: (v) => (v == null || v.isEmpty) ? 'Wajib' : null,
            ),
          ),
        ],
      ),
      LabeledTextField(
        label: 'Nama',
        controller: _nama,
        validator: (v) => (v == null || v.isEmpty) ? 'Wajib' : null,
      ),
      Row(
        children: [
          Expanded(
            child: LabeledTextField(
              label: 'Posisi',
              controller: _posisi,
              validator: (v) => (v == null || v.isEmpty) ? 'Wajib' : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: LabeledTextField(label: 'Lokasi', controller: _lokasi),
          ),
        ],
      ),
    ],
  );

  Widget _workSection() => Column(
    children: [
      OhFieldLabel(
        label: 'Shift',
        child: OhDropdown<String>(
          value: _shift,
          items: kShiftOptions,
          hint: 'Pilih shift',
          label: (v) => v,
          onChanged: (v) => setState(() => _shift = v ?? 'Pagi'),
        ),
      ),
      Row(
        children: [
          Expanded(
            child: OhFieldLabel(
              label: 'Jumlah Jam Tidur',
              child: TextFormField(
                controller: _jamTidur,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                ],
                decoration: const InputDecoration(hintText: 'Contoh: 7.5'),
                validator: (v) => (v == null || v.isEmpty) ? 'Wajib' : null,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: LabeledTextField(
              label: 'Jam Masuk',
              controller: _jamMasuk,
              hint: '07:00',
            ),
          ),
        ],
      ),
      // Tidur <= 6 jam toggle
      OhFieldLabel(
        label: 'Tidur ≤ 6 Jam?',
        child: Row(
          children: [
            Expanded(
              child: _toggleChip(
                'Ya',
                _tidurKurang6,
                Colors.red,
                () => setState(() => _tidurKurang6 = true),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _toggleChip(
                'Tidak',
                !_tidurKurang6,
                AppTheme.accent,
                () => setState(() => _tidurKurang6 = false),
              ),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _healthSection() => Column(
    children: [
      OhFieldLabel(
        label: 'Kondisi Kesehatan',
        child: Row(
          children: kKesehatan.map((k) {
            final sel = _kesehatan == k;
            final c = kesehatanColor(k);
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 6),
                child: GestureDetector(
                  onTap: () => setState(() => _kesehatan = k),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: sel ? c.withOpacity(0.12) : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: sel ? c : Colors.grey.shade200,
                        width: sel ? 1.5 : 1,
                      ),
                    ),
                    child: Text(
                      k,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: sel ? c : AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
      OhFieldLabel(
        label: 'Minum Obat?',
        child: Row(
          children: [
            Expanded(
              child: _toggleChip(
                'Ya',
                _minumObat,
                Colors.orange,
                () => setState(() => _minumObat = true),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _toggleChip(
                'Tidak',
                !_minumObat,
                AppTheme.accent,
                () => setState(() => _minumObat = false),
              ),
            ),
          ],
        ),
      ),
      OhFieldLabel(
        label: 'Pembatasan Kerja',
        child: TextFormField(
          controller: _pembatasan,
          decoration: const InputDecoration(hintText: 'Tidak Ada / Ada - ...'),
          onChanged: (_) => setState(() {}),
        ),
      ),
    ],
  );

  Widget _statusPreview() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: _isFitStatus
          ? AppTheme.accent.withOpacity(0.08)
          : Colors.red.withOpacity(0.06),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: _isFitStatus
            ? AppTheme.accent.withOpacity(0.3)
            : Colors.red.withOpacity(0.3),
      ),
    ),
    child: Row(
      children: [
        Icon(
          _isFitStatus ? Icons.check_circle_rounded : Icons.cancel_rounded,
          color: _isFitStatus ? AppTheme.accent : Colors.red,
          size: 24,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isFitStatus ? 'FIT TO WORK' : 'NOT FIT TO WORK',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _isFitStatus ? AppTheme.accent : Colors.red,
                ),
              ),
              Text(
                'Berdasarkan isian di atas',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _notesSection() => LabeledTextField(
    label: 'Keterangan',
    controller: _keterangan,
    hint: 'Catatan tambahan (opsional)',
    maxLines: 3,
  );

  Widget _toggleChip(
    String label,
    bool selected,
    Color color,
    VoidCallback onTap,
  ) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: selected ? color.withOpacity(0.12) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: selected ? color : Colors.grey.shade200,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: selected ? color : AppTheme.textSecondary,
        ),
      ),
    ),
  );

  Widget _buildButtons() => Row(
    children: [
      if (!isEdit) ...[
        Expanded(
          child: OutlinedButton(
            onPressed: _isSaving
                ? null
                : () {
                    formKey.currentState?.reset();
                    for (final c in [
                      _tanggal,
                      _site,
                      _nama,
                      _posisi,
                      _departemen,
                      _lokasi,
                      _jamTidur,
                      _jamMasuk,
                      _keterangan,
                    ]) {
                      c.clear();
                    }
                    _pembatasan.text = kPembatasanDefault;
                    setState(() {
                      _shift = 'Pagi';
                      _kesehatan = 'Baik';
                      _tidurKurang6 = false;
                      _minumObat = false;
                    });
                  },
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
          label: Text(isEdit ? 'Update' : 'Simpan'),
        ),
      ),
    ],
  );
}
