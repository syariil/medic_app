import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/medicine.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../components/form/labeled_text_field.dart';

class MedicineInputScreen extends StatefulWidget {
  final Medicine? medicine;
  const MedicineInputScreen({super.key, this.medicine});

  @override
  State<MedicineInputScreen> createState() => _MedicineInputScreenState();
}

class _MedicineInputScreenState extends State<MedicineInputScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nama = TextEditingController();
  final _kategori = TextEditingController();
  final _satuan = TextEditingController();
  final _stok = TextEditingController();
  final _keterangan = TextEditingController();

  final _db = DatabaseService();
  bool _isSaving = false;

  bool get _isEdit => widget.medicine != null;

  // Preset kategori & satuan
  static const _kategoriList = [
    'Antibiotik',
    'Analgesik',
    'Antihipertensi',
    'Antihistamin',
    'Vitamin',
    'Antidiabetes',
    'Antiinflamasi',
    'Lainnya',
  ];
  static const _satuanList = [
    'Tablet',
    'Kapsul',
    'Sirup (ml)',
    'Ampul',
    'Vial',
    'Tube',
    'Sachet',
    'Botol',
  ];

  String? _selectedKategori;
  String? _selectedSatuan;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _nama.text = widget.medicine!.nama;
      _kategori.text = widget.medicine!.kategori;
      _satuan.text = widget.medicine!.satuan;
      _stok.text = widget.medicine!.stok.toString();
      _keterangan.text = widget.medicine!.keterangan;
      _selectedKategori = _kategoriList.contains(widget.medicine!.kategori)
          ? widget.medicine!.kategori
          : null;
      _selectedSatuan = _satuanList.contains(widget.medicine!.satuan)
          ? widget.medicine!.satuan
          : null;
    }
  }

  @override
  void dispose() {
    _nama.dispose();
    _kategori.dispose();
    _satuan.dispose();
    _stok.dispose();
    _keterangan.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final medicine = Medicine(
      id: widget.medicine?.id,
      nama: _nama.text.trim(),
      kategori: _kategori.text.trim(),
      satuan: _satuan.text.trim(),
      stok: int.tryParse(_stok.text.trim()) ?? 0,
      keterangan: _keterangan.text.trim(),
    );

    try {
      _isEdit
          ? await _db.updateMedicine(medicine)
          : await _db.insertMedicine(medicine);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEdit ? 'Data obat diperbarui' : 'Obat berhasil disimpan',
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
              _isEdit ? 'Edit Data Obat' : 'Tambah Obat Baru',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _isEdit ? 'Ubah informasi obat' : 'Isi data obat dengan lengkap',
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
                      label: 'Nama Obat',
                      controller: _nama,
                      hint: 'Contoh: Paracetamol 500mg',
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Nama obat tidak boleh kosong'
                          : null,
                    ),

                    // ── Kategori picker ───────────────────────────────────────
                    _PickerField(
                      label: 'Kategori',
                      items: _kategoriList,
                      selected: _selectedKategori,
                      controller: _kategori,
                      onSelect: (v) => setState(() {
                        _selectedKategori = v;
                        _kategori.text = v;
                      }),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Pilih atau isi kategori'
                          : null,
                    ),

                    const SizedBox(height: 14),

                    // ── Satuan picker ─────────────────────────────────────────
                    _PickerField(
                      label: 'Satuan',
                      items: _satuanList,
                      selected: _selectedSatuan,
                      controller: _satuan,
                      onSelect: (v) => setState(() {
                        _selectedSatuan = v;
                        _satuan.text = v;
                      }),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Pilih atau isi satuan'
                          : null,
                    ),

                    const SizedBox(height: 14),

                    // ── Stok ──────────────────────────────────────────────────
                    const Text(
                      'Stok',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _stok,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        hintText: '0',
                        suffixText: _satuan.text.isNotEmpty
                            ? _satuan.text
                            : null,
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty)
                          return 'Stok tidak boleh kosong';
                        if (int.tryParse(v) == null) return 'Masukkan angka';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    LabeledTextField(
                      label: 'Keterangan',
                      controller: _keterangan,
                      hint: 'Dosis, indikasi, atau catatan tambahan (opsional)',
                      maxLines: 3,
                    ),

                    const SizedBox(height: 8),

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
                                      _kategori.clear();
                                      _satuan.clear();
                                      _stok.clear();
                                      _keterangan.clear();
                                      setState(() {
                                        _selectedKategori = null;
                                        _selectedSatuan = null;
                                      });
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
                                : Text(_isEdit ? 'Update Data' : 'Simpan Obat'),
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

// ─── PICKER FIELD ─────────────────────────────────────────────────────────────

class _PickerField extends StatelessWidget {
  final String label;
  final List<String> items;
  final String? selected;
  final TextEditingController controller;
  final ValueChanged<String> onSelect;
  final String? Function(String?)? validator;

  const _PickerField({
    required this.label,
    required this.items,
    required this.selected,
    required this.controller,
    required this.onSelect,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: items.map((item) {
            final isSelected = selected == item;
            return GestureDetector(
              onTap: () => onSelect(item),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primary
                      : AppTheme.primary.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primary
                        : AppTheme.primary.withOpacity(0.2),
                  ),
                ),
                child: Text(
                  item,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : AppTheme.primary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        // Input manual jika tidak ada di preset
        TextFormField(
          controller: controller,
          validator: validator,
          decoration: InputDecoration(
            hintText: 'Atau ketik manual...',
            hintStyle: TextStyle(
              color: AppTheme.textSecondary.withOpacity(0.5),
            ),
          ),
          onChanged: (_) {},
        ),
      ],
    );
  }
}
