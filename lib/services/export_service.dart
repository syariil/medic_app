import 'dart:io';

import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../models/patient.dart';
import '../models/doctor.dart';
import '../models/medicine.dart';
import '../models/prescription.dart';
import '../models/export_config.dart';
import 'database_service.dart';

class ExportService {
  ExportService._();

  // ─── Public API ───────────────────────────────────────────────────────────

  /// Export berdasarkan [config]. Return [ExportSummary] dengan path file.
  static Future<ExportSummary> exportAll(
    ExportConfig config,
    DatabaseService db,
  ) async {
    final sw = Stopwatch()..start();

    // Ambil data sesuai tabel yang dipilih + filter tanggal
    final patients = config.tables.contains(ExportTable.patients)
        ? await _fetchPatients(db, config)
        : <Patient>[];
    final doctors = config.tables.contains(ExportTable.doctors)
        ? await db.getDoctors()
        : <Doctor>[];
    final medicines = config.tables.contains(ExportTable.medicines)
        ? await db.getMedicines()
        : <Medicine>[];
    final prescriptions = config.tables.contains(ExportTable.prescriptions)
        ? await _fetchPrescriptions(db, config)
        : <PrescriptionWithItems>[];

    final files = <ExportFileResult>[];

    if (config.mode == ExportMode.singleFile) {
      final result = await _exportSingleFile(
        config,
        patients,
        doctors,
        medicines,
        prescriptions,
      );
      files.add(result);
    } else {
      // File terpisah per tabel yang dipilih
      if (patients.isNotEmpty) {
        files.add(await _exportPatientFile(patients, config));
      }
      if (doctors.isNotEmpty) {
        files.add(await _exportDoctorFile(doctors));
      }
      if (medicines.isNotEmpty) {
        files.add(await _exportMedicineFile(medicines));
      }
      if (prescriptions.isNotEmpty) {
        files.add(await _exportPrescriptionFile(prescriptions, config));
      }
    }

    sw.stop();

    final totalRows = files.fold<int>(0, (sum, f) => sum + f.totalRows);

    return ExportSummary(
      files: files,
      totalRows: totalRows,
      duration: sw.elapsed,
    );
  }

  /// Export pasien saja (dipakai dari dashboard pasien).
  static Future<String?> exportToExcel(List<Patient> data) async {
    try {
      final excel = Excel.createExcel();
      final sheetName = 'Data Pasien';
      excel.rename(excel.sheets.keys.first, sheetName);
      final sheet = excel[sheetName];
      _writePatientSheet(sheet, data);
      return await _saveFile(excel, 'data_pasien');
    } catch (e) {
      debugPrint('ExportService.exportToExcel: $e');
      return null;
    }
  }

  // ─── Single file ──────────────────────────────────────────────────────────

  static Future<ExportFileResult> _exportSingleFile(
    ExportConfig config,
    List<Patient> patients,
    List<Doctor> doctors,
    List<Medicine> medicines,
    List<PrescriptionWithItems> prescriptions,
  ) async {
    const fileName = 'export_medic_all';
    final rowCounts = <String, int>{};

    try {
      final excel = Excel.createExcel();
      final defSheet = excel.sheets.keys.first;

      bool firstSheet = true;

      void addSheet(String name, void Function(Sheet) writer, int count) {
        if (firstSheet) {
          excel.rename(defSheet, name);
          firstSheet = false;
        } else {
          excel[name];
        }
        writer(excel[name]);
        rowCounts[name] = count;
      }

      if (patients.isNotEmpty) {
        addSheet(
          'Pasien',
          (s) => _writePatientSheet(s, patients),
          patients.length,
        );
      }
      if (doctors.isNotEmpty) {
        addSheet(
          'Dokter',
          (s) => _writeDoctorSheet(s, doctors),
          doctors.length,
        );
      }
      if (medicines.isNotEmpty) {
        addSheet(
          'Obat',
          (s) => _writeMedicineSheet(s, medicines),
          medicines.length,
        );
      }
      if (prescriptions.isNotEmpty) {
        // Flatten ke baris resep detail
        final flat = _flattenPrescriptions(prescriptions);
        addSheet('Resep', (s) => _writePrescriptionSheet(s, flat), flat.length);
        rowCounts['Resep'] = flat.length;
      }

      // Jika semua kosong, tetap buat sheet placeholder
      if (rowCounts.isEmpty) {
        excel.rename(defSheet, 'Info');
        final s = excel['Info'];
        s.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value =
            TextCellValue('Tidak ada data pada rentang yang dipilih');
        rowCounts['Info'] = 0;
      }

      final path = await _saveFile(excel, fileName);
      return ExportFileResult(
        fileName: '$fileName.xlsx',
        path: path,
        rowCounts: rowCounts,
      );
    } catch (e, st) {
      debugPrint('ExportService._exportSingleFile: $e\n$st');
      return ExportFileResult(
        fileName: '$fileName.xlsx',
        error: e.toString(),
        rowCounts: rowCounts,
      );
    }
  }

  // ─── Per-tabel files ──────────────────────────────────────────────────────

  static Future<ExportFileResult> _exportPatientFile(
    List<Patient> data,
    ExportConfig config,
  ) async {
    const name = 'export_pasien';
    try {
      final excel = Excel.createExcel();
      excel.rename(excel.sheets.keys.first, 'Pasien');
      _writePatientSheet(excel['Pasien'], data);
      final path = await _saveFile(excel, name);
      return ExportFileResult(
        fileName: '$name.xlsx',
        path: path,
        rowCounts: {'Pasien': data.length},
      );
    } catch (e) {
      return ExportFileResult(
        fileName: '$name.xlsx',
        error: e.toString(),
        rowCounts: {},
      );
    }
  }

  static Future<ExportFileResult> _exportDoctorFile(List<Doctor> data) async {
    const name = 'export_dokter';
    try {
      final excel = Excel.createExcel();
      excel.rename(excel.sheets.keys.first, 'Dokter');
      _writeDoctorSheet(excel['Dokter'], data);
      final path = await _saveFile(excel, name);
      return ExportFileResult(
        fileName: '$name.xlsx',
        path: path,
        rowCounts: {'Dokter': data.length},
      );
    } catch (e) {
      return ExportFileResult(
        fileName: '$name.xlsx',
        error: e.toString(),
        rowCounts: {},
      );
    }
  }

  static Future<ExportFileResult> _exportMedicineFile(
    List<Medicine> data,
  ) async {
    const name = 'export_obat';
    try {
      final excel = Excel.createExcel();
      excel.rename(excel.sheets.keys.first, 'Obat');
      _writeMedicineSheet(excel['Obat'], data);
      final path = await _saveFile(excel, name);
      return ExportFileResult(
        fileName: '$name.xlsx',
        path: path,
        rowCounts: {'Obat': data.length},
      );
    } catch (e) {
      return ExportFileResult(
        fileName: '$name.xlsx',
        error: e.toString(),
        rowCounts: {},
      );
    }
  }

  static Future<ExportFileResult> _exportPrescriptionFile(
    List<PrescriptionWithItems> data,
    ExportConfig config,
  ) async {
    const name = 'export_resep';
    try {
      final excel = Excel.createExcel();
      excel.rename(excel.sheets.keys.first, 'Resep');
      final flat = _flattenPrescriptions(data);
      _writePrescriptionSheet(excel['Resep'], flat);
      final path = await _saveFile(excel, name);
      return ExportFileResult(
        fileName: '$name.xlsx',
        path: path,
        rowCounts: {'Resep': flat.length},
      );
    } catch (e) {
      return ExportFileResult(
        fileName: '$name.xlsx',
        error: e.toString(),
        rowCounts: {},
      );
    }
  }

  // ─── Sheet writers ────────────────────────────────────────────────────────

  static void _writePatientSheet(Sheet sheet, List<Patient> data) {
    final headers = ['No', 'Nama', 'NIK', 'Tanggal', 'Keluhan', 'Diagnosa'];
    _writeStyledHeader(sheet, headers);
    for (var i = 0; i < data.length; i++) {
      final p = data[i];
      _appendRow(sheet, i + 1, [
        IntCellValue(i + 1),
        TextCellValue(p.nama),
        TextCellValue(p.nik),
        TextCellValue(p.tanggal),
        TextCellValue(p.keluhan),
        TextCellValue(p.diagnosa),
      ]);
    }
  }

  static void _writeDoctorSheet(Sheet sheet, List<Doctor> data) {
    final headers = ['No', 'Nama', 'Spesialis', 'Jadwal', 'Poli'];
    _writeStyledHeader(sheet, headers);
    for (var i = 0; i < data.length; i++) {
      final d = data[i];
      _appendRow(sheet, i + 1, [
        IntCellValue(i + 1),
        TextCellValue(d.nama),
        TextCellValue(d.spesialis),
        TextCellValue(d.jadwal),
        TextCellValue(d.poli),
      ]);
    }
  }

  static void _writeMedicineSheet(Sheet sheet, List<Medicine> data) {
    final headers = ['No', 'Nama', 'Kategori', 'Satuan', 'Stok', 'Keterangan'];
    _writeStyledHeader(sheet, headers);
    for (var i = 0; i < data.length; i++) {
      final m = data[i];
      _appendRow(sheet, i + 1, [
        IntCellValue(i + 1),
        TextCellValue(m.nama),
        TextCellValue(m.kategori),
        TextCellValue(m.satuan),
        IntCellValue(m.stok),
        TextCellValue(m.keterangan),
      ]);
    }
  }

  static void _writePrescriptionSheet(
    Sheet sheet,
    List<_PrescriptionRow> data,
  ) {
    final headers = [
      'No',
      'Tgl Resep',
      'Nama Pasien',
      'ID Pasien',
      'Nama Obat',
      'Jumlah',
      'Satuan',
      'Aturan Pakai',
      'Catatan',
    ];
    _writeStyledHeader(sheet, headers);
    for (var i = 0; i < data.length; i++) {
      final r = data[i];
      _appendRow(sheet, i + 1, [
        IntCellValue(i + 1),
        TextCellValue(r.tanggal),
        TextCellValue(r.patientName),
        IntCellValue(r.patientId),
        TextCellValue(r.medicineName),
        IntCellValue(r.jumlah),
        TextCellValue(r.satuan),
        TextCellValue(r.aturanPakai),
        TextCellValue(r.catatan),
      ]);
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  static void _writeStyledHeader(Sheet sheet, List<String> headers) {
    for (var i = 0; i < headers.length; i++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
      );
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = CellStyle(bold: true);
    }
  }

  static void _appendRow(Sheet sheet, int rowIndex, List<CellValue> values) {
    for (var i = 0; i < values.length; i++) {
      sheet
              .cell(
                CellIndex.indexByColumnRow(columnIndex: i, rowIndex: rowIndex),
              )
              .value =
          values[i];
    }
  }

  static Future<String?> _saveFile(Excel excel, String baseName) async {
    final bytes = excel.encode();
    if (bytes == null) throw Exception('encode() returned null');
    final dir = await getApplicationDocumentsDirectory();
    final ts = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .substring(0, 19);
    final path = '${dir.path}/${baseName}_$ts.xlsx';
    await File(path).writeAsBytes(bytes);
    return path;
  }

  static Future<List<Patient>> _fetchPatients(
    DatabaseService db,
    ExportConfig config,
  ) async {
    final all = await db.getPatients();
    if (!config.hasDateFilter) return all;
    final s = config.startDate!;
    final e = config.endDate!;
    return all.where((p) {
      final d = DateTime.tryParse(p.tanggal);
      if (d == null) return false;
      final date = DateTime(d.year, d.month, d.day);
      return !date.isBefore(DateTime(s.year, s.month, s.day)) &&
          !date.isAfter(DateTime(e.year, e.month, e.day));
    }).toList();
  }

  static Future<List<PrescriptionWithItems>> _fetchPrescriptions(
    DatabaseService db,
    ExportConfig config,
  ) async {
    // Ambil semua pasien lalu gabung resep-nya
    final patients = await db.getPatients();
    final result = <PrescriptionWithItems>[];
    for (final p in patients) {
      if (p.id == null) continue;
      final rxList = await db.getPrescriptionsByPatient(p.id!);
      if (!config.hasDateFilter) {
        result.addAll(rxList);
      } else {
        final s = config.startDate!;
        final e = config.endDate!;
        result.addAll(
          rxList.where((rx) {
            final d = DateTime.tryParse(rx.prescription.tanggal);
            if (d == null) return false;
            final date = DateTime(d.year, d.month, d.day);
            return !date.isBefore(DateTime(s.year, s.month, s.day)) &&
                !date.isAfter(DateTime(e.year, e.month, e.day));
          }),
        );
      }
    }
    return result;
  }

  static List<_PrescriptionRow> _flattenPrescriptions(
    List<PrescriptionWithItems> data,
  ) {
    final rows = <_PrescriptionRow>[];
    for (final pw in data) {
      for (final item in pw.items) {
        rows.add(
          _PrescriptionRow(
            tanggal: pw.prescription.tanggal,
            patientId: pw.prescription.patientId,
            patientName: 'Pasien #${pw.prescription.patientId}',
            medicineName: item.medicineName,
            jumlah: item.jumlah,
            satuan: item.satuan,
            aturanPakai: item.aturanPakai,
            catatan: pw.prescription.catatan,
          ),
        );
      }
    }
    return rows;
  }
}

class _PrescriptionRow {
  final String tanggal, patientName, medicineName, satuan, aturanPakai, catatan;
  final int patientId, jumlah;
  const _PrescriptionRow({
    required this.tanggal,
    required this.patientId,
    required this.patientName,
    required this.medicineName,
    required this.jumlah,
    required this.satuan,
    required this.aturanPakai,
    required this.catatan,
  });
}
