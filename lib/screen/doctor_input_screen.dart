import 'package:flutter/material.dart';
import '../models/doctor.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../components/form/labeled_text_field.dart';

class DoctorInputScreen extends StatefulWidget {
  final Doctor? doctor;
  const DoctorInputScreen({super.key, this.doctor});

  @override
  State<DoctorInputScreen> createState() => _DoctorInputScreenState();
}

class _DoctorInputScreenState extends State<DoctorInputScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nama = TextEditingController();
  final _spesialis = TextEditingController();
  final _jadwal = TextEditingController();
  final _poli = TextEditingController();

  final _db = DatabaseService();
  bool _isSaving = false;

  bool get _isEdit => widget.doctor != null;

  // Preset jadwal hari
  static const _hariList = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];
  final Set<String> _selectedHari = {};

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _nama.text = widget.doctor!.nama;
      _spesialis.text = widget.doctor!.spesialis;
      _jadwal.text = widget.doctor!.jadwal;
      _poli.text = widget.doctor!.poli;

      // Parse jadwal yang sudah ada ke set hari
      for (final h in _hariList) {
        if (widget.doctor!.jadwal.contains(h)) _selectedHari.add(h);
      }
    }
  }

  @override
  void dispose() {
    _nama.dispose();
    _spesialis.dispose();
    _jadwal.dispose();
    _poli.dispose();
    super.dispose();
  }

  void _toggleHari(String hari) {
    setState(() {
      if (_selectedHari.contains(hari)) {
        _selectedHari.remove(hari);
      } else {
        _selectedHari.add(hari);
      }
      // Susun jadwal sesuai urutan hari
      final ordered = _hariList.where(_selectedHari.contains).toList();
      _jadwal.text = ordered.join(', ');
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final doctor = Doctor(
      id: widget.doctor?.id,
      nama: _nama.text.trim(),
      spesialis: _spesialis.text.trim(),
      jadwal: _jadwal.text.trim(),
      poli: _poli.text.trim(),
    );

    try {
      if (_isEdit) {
        await _db.updateDoctor(doctor);
      } else {
        await _db.insertDoctor(doctor);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEdit ? 'Data dokter diperbarui' : 'Dokter berhasil disimpan',
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isEdit ? 'Edit Data Dokter' : 'Tambah Dokter Baru',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _isEdit
                  ? 'Ubah informasi dokter'
                  : 'Isi data dokter dengan lengkap',
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LabeledTextField(
                      label: 'Nama Dokter',
                      controller: _nama,
                      hint: 'dr. Nama Lengkap',
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Nama tidak boleh kosong'
                          : null,
                    ),
                    LabeledTextField(
                      label: 'Spesialisasi',
                      controller: _spesialis,
                      hint: 'Contoh: Penyakit Dalam, Anak, Kandungan...',
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Spesialisasi tidak boleh kosong'
                          : null,
                    ),
                    LabeledTextField(
                      label: 'Poli / Ruangan',
                      controller: _poli,
                      hint: 'Contoh: Poli Anak, Poli Umum...',
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Poli tidak boleh kosong'
                          : null,
                    ),

                    // ── Jadwal Picker ────────────────────────────────────────
                    const Text(
                      'Jadwal Praktik',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _hariList.map((hari) {
                        final selected = _selectedHari.contains(hari);
                        return GestureDetector(
                          onTap: () => _toggleHari(hari),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppTheme.primary
                                  : AppTheme.primary.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: selected
                                    ? AppTheme.primary
                                    : AppTheme.primary.withOpacity(0.2),
                              ),
                            ),
                            child: Text(
                              hari,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: selected
                                    ? Colors.white
                                    : AppTheme.primary,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    if (_jadwal.text.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.schedule_rounded,
                              size: 14,
                              color: AppTheme.accent,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _jadwal.text,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.accent,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Validasi jadwal tersembunyi
                    TextFormField(
                      controller: _jadwal,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                      ),
                      style: const TextStyle(fontSize: 0.1),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Pilih minimal 1 hari jadwal'
                          : null,
                    ),

                    const SizedBox(height: 20),

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
                                      _spesialis.clear();
                                      _jadwal.clear();
                                      _poli.clear();
                                      setState(() => _selectedHari.clear());
                                    },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
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
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _submit,
                            child: _isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    _isEdit ? 'Update Data' : 'Simpan Dokter',
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
