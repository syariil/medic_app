import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/fatigue.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../components/form/labeled_text_field.dart';
import '../components/oh_shared.dart';
import 'base_input_screen.dart';
import '../validators.dart';

class FatigueInputScreen extends InputScreenBase<Fatigue> {
  const FatigueInputScreen({super.key, Fatigue? record})
    : super(entity: record);

  @override
  State<FatigueInputScreen> createState() => _FatigueInputScreenState();
}

class _FatigueInputScreenState
    extends _InputScreenBaseState<Fatigue, FatigueInputScreen> {
  final _db = DatabaseService();

  final _tanggal = TextEditingController();
  final _site = TextEditingController();
  final _nama = TextEditingController();
  final _posisi = TextEditingController();
  final _departemen = TextEditingController();
  final _jamTidur = TextEditingController();
  final _tdSistolik = TextEditingController();
  final _tdDiastolik = TextEditingController();
  final _nadi = TextEditingController();
  final _pernapasan = TextEditingController();
  final _suhu = TextEditingController();
  final _obat = TextEditingController();
  final _efekObat = TextEditingController();
  final _pembatasan = TextEditingController();
  final _keterangan = TextEditingController();

  String _shift = 'Pagi';
  String _kriteria = 'Fit';

  @override
  void initState() {
    super.initState();
    if (isEdit) {
      final r = widget.entity as Fatigue;
      _tanggal.text = r.tanggal;
      _site.text = r.site;
      _nama.text = r.nama;
      _posisi.text = r.posisi;
      _departemen.text = r.departemen;
      _jamTidur.text = r.jumlahJamTidur.toString();
      final td = r.tekananDarah.split('/');
      _tdSistolik.text = td.isNotEmpty ? td[0] : '';
      _tdDiastolik.text = td.length > 1 ? td[1] : '';
      _nadi.text = r.nadi.toString();
      _pernapasan.text = r.pernapasan.toString();
      _suhu.text = r.suhuBadan.toString();
      _obat.text = r.obatDikonsumsi;
      _efekObat.text = r.efekObat;
      _pembatasan.text = r.pembatasanKerja;
      _keterangan.text = r.keterangan;
      _shift = r.shift;
      _kriteria = r.kriteria;
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
      _jamTidur,
      _tdSistolik,
      _tdDiastolik,
      _nadi,
      _pernapasan,
      _suhu,
      _obat,
      _efekObat,
      _pembatasan,
      _keterangan,
    ]) {
      c.dispose();
    }
  }

  @override
  void initState() {
    super.initState();
    if (isEdit) {
      final r = widget.entity as Fatigue;
      _tanggal.text = r.tanggal;
      _site.text = r.site;
      _nama.text = r.nama;
      _posisi.text = r.posisi;
      _departemen.text = r.departemen;
      _jamTidur.text = r.jumlahJamTidur.toString();
      final td = r.tekananDarah.split('/');
      _tdSistolik.text = td.isNotEmpty ? td[0] : '';
      _tdDiastolik.text = td.length > 1 ? td[1] : '';
      _nadi.text = r.nadi.toString();
      _pernapasan.text = r.pernapasan.toString();
      _suhu.text = r.suhuBadan.toString();
      _obat.text = r.obatDikonsumsi;
      _efekObat.text = r.efekObat;
      _pembatasan.text = r.pembatasanKerja;
      _keterangan.text = r.keterangan;
      _shift = r.shift;
      _kriteria = r.kriteria;
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
      _jamTidur,
      _tdSistolik,
      _tdDiastolik,
      _nadi,
      _pernapasan,
      _suhu,
      _obat,
      _efekObat,
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
    final record = Fatigue(
      id: widget.entity?.id,
      tanggal: _tanggal.text.trim(),
      site: _site.text.trim(),
      nama: _nama.text.trim(),
      posisi: _posisi.text.trim(),
      departemen: _departemen.text.trim(),
      shift: _shift,
      jumlahJamTidur: double.tryParse(_jamTidur.text) ?? 0,
      tekananDarah: '${_tdSistolik.text.trim()}/${_tdDiastolik.text.trim()}',
      nadi: int.tryParse(_nadi.text) ?? 0,
      pernapasan: int.tryParse(_pernapasan.text) ?? 0,
      suhuBadan: double.tryParse(_suhu.text) ?? 0,
      obatDikonsumsi: _obat.text.trim(),
      efekObat: _efekObat.text.trim(),
      kriteria: _kriteria,
      pembatasanKerja: _pembatasan.text.trim(),
      keterangan: _keterangan.text.trim(),
    );

    if (isEdit) {
      await _db.updateFatigue(record);
    } else {
      await _db.insertFatigue(record);
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
              Text(
                isEdit ? 'Edit Fatigue' : 'Input Fatigue',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Text(
                'Pemeriksaan kelelahan kerja',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 20),

              _card(
                'Informasi Umum',
                Icons.info_outline_rounded,
                AppTheme.primary,
                _infoSection(),
              ),
              const SizedBox(height: 14),
              _card(
                'Vital Sign',
                Icons.monitor_heart_rounded,
                Colors.red,
                _vitalSection(),
              ),
              const SizedBox(height: 14),
              _card(
                'Obat & Kriteria',
                Icons.medication_rounded,
                const Color(0xFF7E3AF2),
                _obatSection(),
              ),
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
              validator: (v) => (v == null || v.isEmpty) ? 'Wajib' : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: LabeledTextField(
              label: 'Departemen',
              controller: _departemen,
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
            child: OhFieldLabel(
              label: 'Shift',
              child: OhDropdown<String>(
                value: _shift,
                items: kShiftOptions,
                hint: 'Shift',
                label: (v) => v,
                onChanged: (v) => setState(() => _shift = v ?? 'Pagi'),
              ),
            ),
          ),
        ],
      ),
    ],
  );

  Widget _vitalSection() => Column(
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
            child: _numField('Suhu (°C)', _suhu, hint: '36.5', isDecimal: true),
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
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(hintText: 'Sistolik'),
                validator: (v) => (v == null || v.isEmpty) ? 'Wajib' : null,
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
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(hintText: 'Diastolik'),
                validator: (v) => (v == null || v.isEmpty) ? 'Wajib' : null,
              ),
            ),
          ],
        ),
      ),
      Row(
        children: [
          Expanded(child: _numField('Nadi (x/mnt)', _nadi, hint: '80')),
          const SizedBox(width: 12),
          Expanded(
            child: _numField('Pernapasan (x/mnt)', _pernapasan, hint: '18'),
          ),
        ],
      ),
    ],
  );

  Widget _obatSection() => Column(
    children: [
      LabeledTextField(
        label: 'Obat yang Dikonsumsi',
        controller: _obat,
        hint: 'Nama obat / Tidak Ada',
        maxLines: 2,
      ),
      LabeledTextField(
        label: 'Efek Obat',
        controller: _efekObat,
        hint: 'Mengantuk / Pusing / Tidak Ada',
        maxLines: 2,
      ),
      OhFieldLabel(
        label: 'Kriteria',
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: kFatigueKriteria.map((k) {
            final sel = _kriteria == k;
            final c = kriteriaColor(k);
            return GestureDetector(
              onTap: () => setState(() => _kriteria = k),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: sel ? c.withOpacity(0.12) : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: sel ? c : Colors.grey.shade200,
                    width: sel ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  k,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: sel ? c : AppTheme.textSecondary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
      OhFieldLabel(
        label: 'Pembatasan Kerja',
        child: TextFormField(
          controller: _pembatasan,
          decoration: const InputDecoration(hintText: 'Tidak Ada / Ada - ...'),
        ),
      ),
    ],
  );

  Widget _notesSection() => LabeledTextField(
    label: 'Keterangan',
    controller: _keterangan,
    hint: 'Catatan tambahan',
    maxLines: 3,
  );

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
                      _jamTidur,
                      _tdSistolik,
                      _tdDiastolik,
                      _nadi,
                      _pernapasan,
                      _suhu,
                      _obat,
                      _efekObat,
                      _keterangan,
                    ]) {
                      c.clear();
                    }
                    _pembatasan.text = kPembatasanDefault;
                    setState(() {
                      _shift = 'Pagi';
                      _kriteria = 'Fit';
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
