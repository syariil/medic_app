import 'package:flutter/material.dart';
import '../models/patient.dart';
import '../models/medicine.dart';
import '../models/prescription.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../components/form/labeled_text_field.dart';
import '../components/form/prescription_form.dart';

class InputScreen extends StatefulWidget {
  final Patient? patient;
  const InputScreen({super.key, this.patient});

  @override
  State<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nama = TextEditingController();
  final _nik = TextEditingController();
  final _tanggal = TextEditingController();
  final _keluhan = TextEditingController();
  final _diagnosa = TextEditingController();

  final _db = DatabaseService();
  bool _isSaving = false;

  // Resep
  List<Medicine> _medicines = [];
  List<PrescriptionItem> _rxItems = [];
  String _rxCatatan = '';
  bool _withPrescription = false;

  // Resep existing (mode edit)
  PrescriptionWithItems? _existingRx;

  bool get _isEdit => widget.patient != null;

  @override
  void initState() {
    super.initState();
    _loadMedicines();
    if (_isEdit) {
      _nama.text = widget.patient!.nama;
      _nik.text = widget.patient!.nik;
      _tanggal.text = widget.patient!.tanggal;
      _keluhan.text = widget.patient!.keluhan;
      _diagnosa.text = widget.patient!.diagnosa;
      _loadExistingPrescription();
    }
  }

  @override
  void dispose() {
    _nama.dispose();
    _nik.dispose();
    _tanggal.dispose();
    _keluhan.dispose();
    _diagnosa.dispose();
    super.dispose();
  }

  Future<void> _loadMedicines() async {
    final list = await _db.getMedicines();
    setState(() => _medicines = list);
  }

  Future<void> _loadExistingPrescription() async {
    if (widget.patient?.id == null) return;
    final list = await _db.getPrescriptionsByPatient(widget.patient!.id!);
    if (list.isNotEmpty) {
      setState(() {
        _existingRx = list.first;
        _rxItems = list.first.items;
        _rxCatatan = list.first.prescription.catatan;
        _withPrescription = true;
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_tanggal.text) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      _tanggal.text = picked.toIso8601String().substring(0, 10);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final patient = Patient(
        id: widget.patient?.id,
        nama: _nama.text.trim(),
        nik: _nik.text.trim(),
        tanggal: _tanggal.text.trim(),
        keluhan: _keluhan.text.trim(),
        diagnosa: _diagnosa.text.trim(),
      );

      int patientId;
      if (_isEdit) {
        await _db.updatePatient(patient);
        patientId = patient.id!;
      } else {
        patientId = await _db.insertPatient(patient);
      }

      // ── Handle resep ─────────────────────────────────────────────────────
      if (_withPrescription && _rxItems.isNotEmpty) {
        final rx = Prescription(
          id: _existingRx?.prescription.id,
          patientId: patientId,
          tanggal: _tanggal.text.trim(),
          catatan: _rxCatatan,
        );

        if (_existingRx != null) {
          await _db.updatePrescription(rx, _rxItems);
        } else {
          await _db.insertPrescription(rx, _rxItems);
        }
      } else if (!_withPrescription && _existingRx != null) {
        // User mematikan toggle resep → hapus resep lama
        await _db.deletePrescription(_existingRx!.prescription.id!);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEdit
                ? 'Data pasien & resep diperbarui'
                : 'Pasien & resep berhasil disimpan',
          ),
          backgroundColor: AppTheme.accent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      if (Navigator.canPop(context)) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isEdit ? 'Edit Data Pasien' : 'Input Pasien Baru',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _isEdit
                    ? 'Ubah data pasien & resep'
                    : 'Isi data pasien, diagnosa, dan resep obat',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 24),

              // ── Data Pasien card ────────────────────────────────────────────
              _SectionContainer(
                title: 'Data Pasien',
                icon: Icons.person_rounded,
                child: Column(
                  children: [
                    LabeledTextField(
                      label: 'Nama Lengkap',
                      controller: _nama,
                      hint: 'Masukkan nama pasien',
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Nama tidak boleh kosong'
                          : null,
                    ),
                    LabeledTextField(
                      label: 'NIK',
                      controller: _nik,
                      hint: '16 digit NIK',
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty)
                          return 'NIK tidak boleh kosong';
                        if (v.trim().length != 4) return 'NIK harus 16 digit';
                        return null;
                      },
                    ),
                    LabeledTextField(
                      label: 'Tanggal Kunjungan',
                      controller: _tanggal,
                      hint: 'Pilih tanggal',
                      readOnly: true,
                      onTap: _pickDate,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Tanggal tidak boleh kosong'
                          : null,
                    ),
                    LabeledTextField(
                      label: 'Keluhan',
                      controller: _keluhan,
                      hint: 'Deskripsikan keluhan pasien',
                      maxLines: 2,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Keluhan tidak boleh kosong'
                          : null,
                    ),
                    LabeledTextField(
                      label: 'Diagnosa',
                      controller: _diagnosa,
                      hint: 'Masukkan diagnosa dokter',
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Diagnosa tidak boleh kosong'
                          : null,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Resep card ────────────────────────────────────────────────
              _SectionContainer(
                title: 'Resep Obat',
                icon: Icons.medication_rounded,
                iconColor: AppTheme.accent,
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
                                      'Belum ada data obat. Tambahkan obat di menu Farmasi terlebih dahulu.',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.orange,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : PrescriptionForm(
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

              const SizedBox(height: 24),

              // ── Tombol ────────────────────────────────────────────────────
              Row(
                children: [
                  if (!_isEdit) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSaving
                            ? null
                            : () {
                                _formKey.currentState?.reset();
                                _nama.clear();
                                _nik.clear();
                                _tanggal.clear();
                                _keluhan.clear();
                                _diagnosa.clear();
                                setState(() {
                                  _rxItems = [];
                                  _withPrescription = false;
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
                      onPressed: _isSaving ? null : _submit,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save_rounded, size: 18),
                      label: Text(_isEdit ? 'Update Data' : 'Simpan Pasien'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Section Container ────────────────────────────────────────────────────────

class _SectionContainer extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color? iconColor;
  final Widget child;
  final Widget? trailing;

  const _SectionContainer({
    required this.title,
    required this.icon,
    required this.child,
    this.iconColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? AppTheme.primary;
    return Container(
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
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              if (trailing != null) ...[const Spacer(), trailing!],
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
