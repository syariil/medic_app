import 'dart:io';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../models/patient.dart';
import '../models/doctor.dart';
import '../models/medicine.dart';
import '../models/import_result.dart';
import 'database_service.dart';

class ImportService {
  ImportService._();

  // ── Sheet names yang dikenali (case-insensitive, trim) ───────────────────

  static const _sheetPatient = ['pasien', 'data pasien', 'patients', 'patient'];
  static const _sheetDoctor = ['dokter', 'data dokter', 'doctors', 'doctor'];
  static const _sheetMedicine = [
    'obat',
    'data obat',
    'farmasi',
    'medicines',
    'medicine',
  ];

  // ── Column aliases (case-insensitive) ────────────────────────────────────

  static const _colNama = [
    'nama',
    'name',
    'nama pasien',
    'nama dokter',
    'nama obat',
  ];
  static const _colNik = ['nik', 'no ktp', 'no. ktp', 'ktp'];
  static const _colTanggal = ['tanggal', 'tanggal kunjungan', 'date', 'tgl'];
  static const _colKeluhan = ['keluhan', 'complaint', 'keluhan pasien'];
  static const _colDiagnosa = ['diagnosa', 'diagnosis', 'diagnosa pasien'];
  static const _colSpesialis = ['spesialis', 'spesialisasi', 'specialization'];
  static const _colJadwal = ['jadwal', 'jadwal praktik', 'schedule'];
  static const _colPoli = ['poli', 'ruangan', 'poli/ruangan', 'poli / ruangan'];
  static const _colKategori = ['kategori', 'category', 'kategori obat'];
  static const _colSatuan = ['satuan', 'unit', 'satuan obat'];
  static const _colStok = ['stok', 'stock', 'jumlah stok'];
  static const _colKeterangan = [
    'keterangan',
    'notes',
    'catatan',
    'description',
  ];

  // ─────────────────────────────────────────────────────────────────────────
  // 1. PICK FILE
  // ─────────────────────────────────────────────────────────────────────────

  /// Buka file picker dan return path file yang dipilih, atau null jika dibatalkan
  static Future<String?> pickFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
      allowMultiple: false,
    );
    return result?.files.single.path;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 2. PARSE FILE
  // ─────────────────────────────────────────────────────────────────────────

  /// Parse file Excel dan return [ImportResult] dengan data + status per baris
  static Future<ImportResult> parseFile(String path) async {
    try {
      final bytes = await File(path).readAsBytes();
      final excel = Excel.decodeBytes(bytes);

      final patients = <ParsedRow<Patient>>[];
      final doctors = <ParsedRow<Doctor>>[];
      final medicines = <ParsedRow<Medicine>>[];
      final errors = <SheetError>[];

      for (final sheetName in excel.sheets.keys) {
        final sheet = excel.sheets[sheetName]!;
        final key = sheetName.trim().toLowerCase();

        if (_sheetPatient.contains(key)) {
          patients.addAll(_parsePatients(sheet, sheetName, errors));
        } else if (_sheetDoctor.contains(key)) {
          doctors.addAll(_parseDoctors(sheet, sheetName, errors));
        } else if (_sheetMedicine.contains(key)) {
          medicines.addAll(_parseMedicines(sheet, sheetName, errors));
        }
        // Sheet tidak dikenal → skip (tidak error)
      }

      return ImportResult(
        patients: patients,
        doctors: doctors,
        medicines: medicines,
        globalErrors: errors,
      );
    } catch (e, st) {
      debugPrint('ImportService.parseFile error: $e\n$st');
      return ImportResult(
        patients: [],
        doctors: [],
        medicines: [],
        globalErrors: [SheetError('file', 0, 'Gagal membaca file: $e')],
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 3. IMPORT KE DB
  // ─────────────────────────────────────────────────────────────────────────

  /// Simpan semua baris valid dari [result] ke database.
  /// Duplikat diizinkan — semua baris valid langsung di-insert.
  static Future<ImportSummary> importToDb(
    ImportResult result,
    DatabaseService db,
  ) async {
    int patientsOk = 0, doctorsOk = 0, medicinesOk = 0, skipped = 0;
    final errors = <String>[];

    // Patients
    for (final row in result.patients.where((r) => r.isValid)) {
      try {
        await db.insertPatient(row.data!);
        patientsOk++;
      } catch (e) {
        skipped++;
        errors.add('Pasien baris ${row.rowNumber}: $e');
      }
    }

    // Doctors
    for (final row in result.doctors.where((r) => r.isValid)) {
      try {
        await db.insertDoctor(row.data!);
        doctorsOk++;
      } catch (e) {
        skipped++;
        errors.add('Dokter baris ${row.rowNumber}: $e');
      }
    }

    // Medicines
    for (final row in result.medicines.where((r) => r.isValid)) {
      try {
        await db.insertMedicine(row.data!);
        medicinesOk++;
      } catch (e) {
        skipped++;
        errors.add('Obat baris ${row.rowNumber}: $e');
      }
    }

    return ImportSummary(
      patientsInserted: patientsOk,
      doctorsInserted: doctorsOk,
      medicinesInserted: medicinesOk,
      skipped: skipped,
      errors: errors,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 4. DOWNLOAD TEMPLATE
  // ─────────────────────────────────────────────────────────────────────────

  /// Buat file template Excel dengan 3 sheet + contoh data
  static Future<String?> generateTemplate() async {
    try {
      final excel = Excel.createExcel();

      // Hapus sheet default
      final defaultSheet = excel.sheets.keys.first;

      // ── Sheet Pasien ───────────────────────────────────────────────────
      excel.rename(defaultSheet, 'Pasien');
      final sPasien = excel['Pasien'];
      _writeHeader(sPasien, ['Nama', 'NIK', 'Tanggal', 'Keluhan', 'Diagnosa']);
      _writeRow(sPasien, 1, [
        'Budi Santoso',
        '3201234567890001',
        '2024-01-15',
        'Demam dan batuk',
        'ISPA',
      ]);
      _writeRow(sPasien, 2, [
        'Siti Rahma',
        '3201234567890002',
        '2024-01-16',
        'Sakit kepala',
        'Migrain',
      ]);

      // ── Sheet Dokter ───────────────────────────────────────────────────
      excel['Dokter'];
      final sDokter = excel['Dokter'];
      _writeHeader(sDokter, ['Nama', 'Spesialis', 'Jadwal', 'Poli']);
      _writeRow(sDokter, 1, [
        'dr. Ahmad Fauzi',
        'Penyakit Dalam',
        'Senin, Rabu, Jumat',
        'Poli Umum',
      ]);
      _writeRow(sDokter, 2, [
        'dr. Dewi Kusuma',
        'Anak',
        'Selasa, Kamis',
        'Poli Anak',
      ]);

      // ── Sheet Obat ─────────────────────────────────────────────────────
      excel['Obat'];
      final sObat = excel['Obat'];
      _writeHeader(sObat, ['Nama', 'Kategori', 'Satuan', 'Stok', 'Keterangan']);
      _writeRow(sObat, 1, [
        'Paracetamol 500mg',
        'Analgesik',
        'Tablet',
        '100',
        'Diminum 3x sehari',
      ]);
      _writeRow(sObat, 2, [
        'Amoxicillin 500mg',
        'Antibiotik',
        'Kapsul',
        '50',
        'Sesuai resep dokter',
      ]);

      // Simpan
      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/template_import_medic.xlsx';
      final bytes = excel.encode();
      if (bytes == null) throw Exception('encode() returned null');
      await File(filePath).writeAsBytes(bytes);
      return filePath;
    } catch (e) {
      debugPrint('ImportService.generateTemplate error: $e');
      return null;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PRIVATE HELPERS
  // ─────────────────────────────────────────────────────────────────────────

  static void _writeHeader(Sheet sheet, List<String> headers) {
    for (var i = 0; i < headers.length; i++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
      );
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = CellStyle(bold: true);
    }
  }

  static void _writeRow(Sheet sheet, int rowIndex, List<String> values) {
    for (var i = 0; i < values.length; i++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: rowIndex))
          .value = TextCellValue(
        values[i],
      );
    }
  }

  /// Buat map: nama kolom lowercase → index kolom, dari baris pertama sheet
  static Map<String, int> _buildHeaderMap(Sheet sheet) {
    final map = <String, int>{};
    if (sheet.rows.isEmpty) return map;
    final headerRow = sheet.rows.first;
    for (var i = 0; i < headerRow.length; i++) {
      final cell = headerRow[i];
      if (cell?.value != null) {
        final key = cell!.value.toString().trim().toLowerCase();
        map[key] = i;
      }
    }
    return map;
  }

  /// Ambil nilai sel sebagai String, atau null jika kosong
  static String? _cell(List<Data?> row, int? colIdx) {
    if (colIdx == null || colIdx >= row.length) return null;
    final v = row[colIdx]?.value;
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  /// Cari index kolom dari daftar alias
  static int? _findCol(Map<String, int> map, List<String> aliases) {
    for (final alias in aliases) {
      if (map.containsKey(alias)) return map[alias];
    }
    return null;
  }

  // ── Parser per entitas ────────────────────────────────────────────────────

  static List<ParsedRow<Patient>> _parsePatients(
    Sheet sheet,
    String sheetName,
    List<SheetError> globalErrors,
  ) {
    final result = <ParsedRow<Patient>>[];
    if (sheet.rows.length <= 1) return result;

    final hMap = _buildHeaderMap(sheet);
    final iNama = _findCol(hMap, _colNama);
    final iNik = _findCol(hMap, _colNik);
    final iTanggal = _findCol(hMap, _colTanggal);
    final iKeluhan = _findCol(hMap, _colKeluhan);
    final iDiagnosa = _findCol(hMap, _colDiagnosa);

    // Validasi header wajib
    if (iNama == null || iNik == null) {
      globalErrors.add(
        SheetError(
          sheetName,
          0,
          'Kolom wajib tidak ditemukan: Nama dan NIK harus ada',
        ),
      );
      return result;
    }

    for (var i = 1; i < sheet.rows.length; i++) {
      final row = sheet.rows[i];
      final rowNo = i; // 1-based (tidak termasuk header)

      final nama = _cell(row, iNama);
      final nik = _cell(row, iNik);
      final tanggal = _cell(row, iTanggal);
      final keluhan = _cell(row, iKeluhan);
      final diagnosa = _cell(row, iDiagnosa);

      // Skip baris kosong total
      if (nama == null && nik == null) continue;

      // Validasi
      final errors = <String>[];
      if (nama == null || nama.isEmpty) errors.add('Nama kosong');
      if (nik == null || nik.isEmpty) errors.add('NIK kosong');
      if (nik != null && nik.length != 16) errors.add('NIK harus 16 digit');
      if (keluhan == null) errors.add('Keluhan kosong');
      if (diagnosa == null) errors.add('Diagnosa kosong');

      if (errors.isNotEmpty) {
        result.add(
          ParsedRow(
            rowNumber: rowNo,
            status: RowStatus.invalid,
            message: errors.join(', '),
          ),
        );
        continue;
      }

      // Warning jika tanggal kosong / format salah
      String finalTanggal = tanggal ?? '';
      String? warning;
      if (tanggal == null) {
        finalTanggal = DateTime.now().toIso8601String().substring(0, 10);
        warning = 'Tanggal kosong, diisi hari ini';
      } else if (DateTime.tryParse(tanggal) == null) {
        // Coba parse format dd/mm/yyyy
        final parts = tanggal.split(RegExp(r'[/\-.]'));
        if (parts.length == 3) {
          final d = int.tryParse(parts[0]);
          final m = int.tryParse(parts[1]);
          final y = int.tryParse(parts[2]);
          if (d != null && m != null && y != null) {
            finalTanggal =
                '${y.toString().padLeft(4, '0')}-${m.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';
          } else {
            finalTanggal = DateTime.now().toIso8601String().substring(0, 10);
            warning = 'Format tanggal tidak dikenal "$tanggal", diisi hari ini';
          }
        }
      }

      result.add(
        ParsedRow(
          rowNumber: rowNo,
          data: Patient(
            nama: nama!,
            nik: nik!,
            tanggal: finalTanggal,
            keluhan: keluhan!,
            diagnosa: diagnosa!,
          ),
          status: warning != null ? RowStatus.warning : RowStatus.valid,
          message: warning,
        ),
      );
    }
    return result;
  }

  static List<ParsedRow<Doctor>> _parseDoctors(
    Sheet sheet,
    String sheetName,
    List<SheetError> globalErrors,
  ) {
    final result = <ParsedRow<Doctor>>[];
    if (sheet.rows.length <= 1) return result;

    final hMap = _buildHeaderMap(sheet);
    final iNama = _findCol(hMap, _colNama);
    final iSpesialis = _findCol(hMap, _colSpesialis);
    final iJadwal = _findCol(hMap, _colJadwal);
    final iPoli = _findCol(hMap, _colPoli);

    if (iNama == null || iSpesialis == null) {
      globalErrors.add(
        SheetError(
          sheetName,
          0,
          'Kolom wajib tidak ditemukan: Nama dan Spesialis harus ada',
        ),
      );
      return result;
    }

    for (var i = 1; i < sheet.rows.length; i++) {
      final row = sheet.rows[i];
      final rowNo = i;

      final nama = _cell(row, iNama);
      final spesialis = _cell(row, iSpesialis);
      final jadwal = _cell(row, iJadwal);
      final poli = _cell(row, iPoli);

      if (nama == null && spesialis == null) continue;

      final errors = <String>[];
      if (nama == null) errors.add('Nama kosong');
      if (spesialis == null) errors.add('Spesialis kosong');

      if (errors.isNotEmpty) {
        result.add(
          ParsedRow(
            rowNumber: rowNo,
            status: RowStatus.invalid,
            message: errors.join(', '),
          ),
        );
        continue;
      }

      result.add(
        ParsedRow(
          rowNumber: rowNo,
          data: Doctor(
            nama: nama!,
            spesialis: spesialis!,
            jadwal: jadwal ?? '-',
            poli: poli ?? '-',
          ),
          status: RowStatus.valid,
        ),
      );
    }
    return result;
  }

  static List<ParsedRow<Medicine>> _parseMedicines(
    Sheet sheet,
    String sheetName,
    List<SheetError> globalErrors,
  ) {
    final result = <ParsedRow<Medicine>>[];
    if (sheet.rows.length <= 1) return result;

    final hMap = _buildHeaderMap(sheet);
    final iNama = _findCol(hMap, _colNama);
    final iKategori = _findCol(hMap, _colKategori);
    final iSatuan = _findCol(hMap, _colSatuan);
    final iStok = _findCol(hMap, _colStok);
    final iKeterangan = _findCol(hMap, _colKeterangan);

    if (iNama == null) {
      globalErrors.add(
        SheetError(sheetName, 0, 'Kolom wajib tidak ditemukan: Nama harus ada'),
      );
      return result;
    }

    for (var i = 1; i < sheet.rows.length; i++) {
      final row = sheet.rows[i];
      final rowNo = i;

      final nama = _cell(row, iNama);
      final kategori = _cell(row, iKategori);
      final satuan = _cell(row, iSatuan);
      final stokStr = _cell(row, iStok);
      final keterangan = _cell(row, iKeterangan);

      if (nama == null) continue;

      final errors = <String>[];
      final warnings = <String>[];
      if (nama.isEmpty) errors.add('Nama kosong');

      int stok = 0;
      if (stokStr != null) {
        stok = int.tryParse(stokStr) ?? -1;
        if (stok < 0) {
          warnings.add('Stok "$stokStr" bukan angka, diisi 0');
          stok = 0;
        }
      } else {
        warnings.add('Stok kosong, diisi 0');
      }

      if (errors.isNotEmpty) {
        result.add(
          ParsedRow(
            rowNumber: rowNo,
            status: RowStatus.invalid,
            message: errors.join(', '),
          ),
        );
        continue;
      }

      result.add(
        ParsedRow(
          rowNumber: rowNo,
          data: Medicine(
            nama: nama!,
            kategori: kategori ?? 'Lainnya',
            satuan: satuan ?? 'Tablet',
            stok: stok,
            keterangan: keterangan ?? '',
          ),
          status: warnings.isNotEmpty ? RowStatus.warning : RowStatus.valid,
          message: warnings.isNotEmpty ? warnings.join(', ') : null,
        ),
      );
    }
    return result;
  }
}
