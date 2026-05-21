import 'package:flutter/material.dart';
import '../models/drug_test.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../components/form/labeled_text_field.dart';
import '../components/oh_shared.dart';

class DrugTestInputScreen extends StatefulWidget {
  final DrugTest? drugTest;
  const DrugTestInputScreen({super.key, this.drugTest});

  @override
  State<DrugTestInputScreen> createState() => _DrugTestInputScreenState();
}

class _DrugTestInputScreenState extends State<DrugTestInputScreen> {
  final _formKey = GlobalKey<FormState>();
  final _db = DatabaseService();
  bool _isSaving = false;

  final _tanggal = TextEditingController();
  final _site = TextEditingController();
  final _nama = TextEditingController();
  final _posisi = TextEditingController();
  final _departemen = TextEditingController();
  final _keterangan = TextEditingController();

  String _amp = 'Negatif';
  String _met = 'Negatif';
  String _thc = 'Negatif';
  String _coc = 'Negatif';
  String _bzo = 'Negatif';
  String _hasil = 'Negatif';

  bool get _isEdit => widget.drugTest != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final d = widget.drugTest!;
      _tanggal.text = d.tanggal;
      _site.text = d.site;
      _nama.text = d.nama;
      _posisi.text = d.posisi;
      _departemen.text = d.departemen;
      _keterangan.text = d.keterangan;
      _amp = d.amp;
      _met = d.met;
      _thc = d.thc;
      _coc = d.coc;
      _bzo = d.bzo;
      _hasil = d.hasil;
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
      _keterangan,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _recalcHasil() {
    setState(() {
      _hasil = [_amp, _met, _thc, _coc, _bzo].any((v) => v == 'Positif')
          ? 'Positif'
          : 'Negatif';
    });
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final dt = DrugTest(
      id: widget.drugTest?.id,
      tanggal: _tanggal.text.trim(),
      site: _site.text.trim(),
      nama: _nama.text.trim(),
      posisi: _posisi.text.trim(),
      departemen: _departemen.text.trim(),
      amp: _amp,
      met: _met,
      thc: _thc,
      coc: _coc,
      bzo: _bzo,
      hasil: _hasil,
      keterangan: _keterangan.text.trim(),
    );

    try {
      _isEdit ? await _db.updateDrugTest(dt) : await _db.insertDrugTest(dt);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEdit ? 'Data diperbarui' : 'Tes narkoba disimpan'),
          backgroundColor: AppTheme.accent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      if (Navigator.canPop(context)) Navigator.pop(context, true);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
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
                _isEdit ? 'Edit Tes Narkoba' : 'Input Tes Narkoba',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                'Isi hasil pemeriksaan narkoba',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 20),

              // Informasi umum
              _card(
                'Informasi Umum',
                Icons.info_outline_rounded,
                AppTheme.primary,
                _buildGeneralFields(),
              ),
              const SizedBox(height: 14),

              // Parameter tes
              _card(
                'Parameter Tes',
                Icons.science_rounded,
                const Color(0xFF7E3AF2),
                _buildTestParams(),
              ),
              const SizedBox(height: 14),

              // Hasil & catatan
              _card(
                'Hasil & Catatan',
                Icons.assignment_rounded,
                Colors.orange,
                _buildResultFields(),
              ),
              const SizedBox(height: 24),
              _buildButtons(),
            ],
          ),
        ),
      ),
    );
  }

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

  Widget _buildGeneralFields() => Column(
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
              hint: 'Nama site',
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
        hint: 'Nama lengkap',
        validator: (v) => (v == null || v.isEmpty) ? 'Wajib' : null,
      ),
      LabeledTextField(
        label: 'Posisi',
        controller: _posisi,
        hint: 'Jabatan/Posisi',
        validator: (v) => (v == null || v.isEmpty) ? 'Wajib' : null,
      ),
    ],
  );

  Widget _buildTestParams() {
    final params = [
      (
        'AMP (Amphetamine)',
        _amp,
        (v) => setState(() {
          _amp = v!;
          _recalcHasil();
        }),
      ),
      (
        'MET (Methamphetamine)',
        _met,
        (v) => setState(() {
          _met = v!;
          _recalcHasil();
        }),
      ),
      (
        'THC (Cannabis)',
        _thc,
        (v) => setState(() {
          _thc = v!;
          _recalcHasil();
        }),
      ),
      (
        'COC (Cocaine)',
        _coc,
        (v) => setState(() {
          _coc = v!;
          _recalcHasil();
        }),
      ),
      (
        'BZO (Benzodiazepine)',
        _bzo,
        (v) => setState(() {
          _bzo = v!;
          _recalcHasil();
        }),
      ),
    ];

    return Column(
      children: params.map((p) {
        final (label, val, onChanged) = p;
        final isPositif = val == 'Positif';
        return OhFieldLabel(
          label: label,
          child: Row(
            children: kDrugResult.map((opt) {
              final sel = val == opt;
              final optColor = opt == 'Positif'
                  ? Colors.red
                  : opt == 'Negatif'
                  ? AppTheme.accent
                  : AppTheme.textSecondary;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () => onChanged(opt),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: sel
                            ? optColor.withOpacity(0.12)
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: sel ? optColor : Colors.grey.shade200,
                          width: sel ? 1.5 : 1,
                        ),
                      ),
                      child: Text(
                        opt,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: sel ? optColor : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildResultFields() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Hasil otomatis
      Row(
        children: [
          const Text(
            'Hasil Keseluruhan:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(width: 12),
          OhBadge(text: _hasil, color: hasilColor(_hasil)),
          const SizedBox(width: 8),
          Text(
            '(otomatis dari parameter)',
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondary.withOpacity(0.6),
            ),
          ),
        ],
      ),
      const SizedBox(height: 14),
      LabeledTextField(
        label: 'Keterangan',
        controller: _keterangan,
        hint: 'Catatan tambahan (opsional)',
        maxLines: 3,
      ),
    ],
  );

  Widget _buildButtons() => Row(
    children: [
      if (!_isEdit) ...[
        Expanded(
          child: OutlinedButton(
            onPressed: _isSaving
                ? null
                : () {
                    _formKey.currentState?.reset();
                    for (final c in [
                      _tanggal,
                      _site,
                      _nama,
                      _posisi,
                      _departemen,
                      _keterangan,
                    ]) {
                      c.clear();
                    }
                    setState(() {
                      _amp = _met = _thc = _coc = _bzo = _hasil = 'Negatif';
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
          label: Text(_isEdit ? 'Update' : 'Simpan'),
        ),
      ),
    ],
  );
}
