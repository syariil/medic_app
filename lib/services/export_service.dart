import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../models/visit.dart';
import '../models/visit_prescription.dart';
import '../models/drug_test.dart';
import '../models/fit_to_work.dart';
import '../models/fatigue.dart';
import '../models/medicine.dart';
import '../models/export_config.dart';
import 'database_service.dart';

class ExportService {
  ExportService._();

  // ─── Column headers ───────────────────────────────────────────────────────

  static const _hVisit = [
    'No',
    'Tanggal',
    'Site',
    'Nama',
    'Posisi',
    'Departemen',
    'Keluhan',
    'Diagnosa',
    'Jam Tidur',
    'Suhu (°C)',
    'Tekanan Darah',
    'Pernapasan (x/m)',
    'Nadi (x/m)',
    'Keterangan',
  ];
  static const _hRx = [
    'No',
    'Tgl Resep',
    'Nama',
    'Site',
    'Departemen',
    'Nama Obat',
    'Jumlah',
    'Satuan',
    'Aturan Pakai',
    'Catatan',
  ];
  static const _hDrug = [
    'No',
    'Tanggal',
    'Site',
    'Nama',
    'Posisi',
    'Departemen',
    'AMP',
    'MET',
    'THC',
    'COC',
    'BZO',
    'Hasil',
    'Keterangan',
  ];
  static const _hFtw = [
    'No',
    'Tanggal',
    'Site',
    'Nama',
    'Posisi',
    'Departemen',
    'Lokasi',
    'Shift',
    'Jam Tidur',
    'Jam Masuk',
    'Tidur ≤6jam',
    'Kesehatan',
    'Minum Obat',
    'Pembatasan Kerja',
    'Status Fit',
    'Keterangan',
  ];
  static const _hFatigue = [
    'No',
    'Tanggal',
    'Site',
    'Nama',
    'Posisi',
    'Departemen',
    'Shift',
    'Jam Tidur',
    'Tekanan Darah',
    'Nadi',
    'Pernapasan',
    'Suhu (°C)',
    'Obat Dikonsumsi',
    'Efek Obat',
    'Kriteria',
    'Pembatasan Kerja',
    'Keterangan',
  ];
  static const _hMed = [
    'No',
    'Nama Obat',
    'Kategori',
    'Satuan',
    'Stok',
    'Keterangan',
  ];

  // ─── Public API ───────────────────────────────────────────────────────────

  static Future<ExportSummary> exportAll(
    ExportConfig config,
    DatabaseService db,
  ) async {
    final sw = Stopwatch()..start();

    // Fetch
    final visits = config.tables.contains(ExportTable.visits)
        ? await _fetchVisits(db, config)
        : <Visit>[];
    final rxMap = config.tables.contains(ExportTable.visitPrescriptions)
        ? await _fetchRx(db, visits)
        : <int, VisitPrescriptionWithItems>{};
    final drugs = config.tables.contains(ExportTable.drugTests)
        ? await _fetchDrugs(db, config)
        : <DrugTest>[];
    final ftws = config.tables.contains(ExportTable.fitToWork)
        ? await _fetchFtw(db, config)
        : <FitToWork>[];
    final fatigues = config.tables.contains(ExportTable.fatigues)
        ? await _fetchFatigue(db, config)
        : <Fatigue>[];
    final medicines = config.tables.contains(ExportTable.medicines)
        ? await db.getMedicines()
        : <Medicine>[];

    final rxFlat = _flatRx(rxMap, visits);

    final files = <ExportFileResult>[];

    if (config.includesExcel) {
      if (config.mode == ExportMode.singleFile) {
        files.add(
          await _xlsxSingle(
            config,
            visits,
            rxFlat,
            drugs,
            ftws,
            fatigues,
            medicines,
          ),
        );
      } else {
        if (visits.isNotEmpty)
          files.add(
            await _xlsxSheet(
              'export_kunjungan',
              'Kunjungan',
              _hVisit,
              _visitRows(visits),
            ),
          );
        if (rxFlat.isNotEmpty)
          files.add(await _xlsxSheet('export_resep', 'Resep', _hRx, rxFlat));
        if (drugs.isNotEmpty)
          files.add(
            await _xlsxSheet(
              'export_narkoba',
              'Tes Narkoba',
              _hDrug,
              _drugRows(drugs),
            ),
          );
        if (ftws.isNotEmpty)
          files.add(
            await _xlsxSheet(
              'export_ftw',
              'Fit To Work',
              _hFtw,
              _ftwRows(ftws),
            ),
          );
        if (fatigues.isNotEmpty)
          files.add(
            await _xlsxSheet(
              'export_fatigue',
              'Fatigue',
              _hFatigue,
              _fatigueRows(fatigues),
            ),
          );
        if (medicines.isNotEmpty)
          files.add(
            await _xlsxSheet('export_obat', 'Obat', _hMed, _medRows(medicines)),
          );
      }
    }

    if (config.includesCsv) {
      if (visits.isNotEmpty && config.tables.contains(ExportTable.visits))
        files.add(
          await _csvFile(
            'export_kunjungan',
            'Kunjungan',
            _hVisit,
            _visitRows(visits),
          ),
        );
      if (rxFlat.isNotEmpty &&
          config.tables.contains(ExportTable.visitPrescriptions))
        files.add(await _csvFile('export_resep', 'Resep', _hRx, rxFlat));
      if (drugs.isNotEmpty && config.tables.contains(ExportTable.drugTests))
        files.add(
          await _csvFile(
            'export_narkoba',
            'Tes Narkoba',
            _hDrug,
            _drugRows(drugs),
          ),
        );
      if (ftws.isNotEmpty && config.tables.contains(ExportTable.fitToWork))
        files.add(
          await _csvFile('export_ftw', 'Fit To Work', _hFtw, _ftwRows(ftws)),
        );
      if (fatigues.isNotEmpty && config.tables.contains(ExportTable.fatigues))
        files.add(
          await _csvFile(
            'export_fatigue',
            'Fatigue',
            _hFatigue,
            _fatigueRows(fatigues),
          ),
        );
      if (medicines.isNotEmpty && config.tables.contains(ExportTable.medicines))
        files.add(
          await _csvFile('export_obat', 'Obat', _hMed, _medRows(medicines)),
        );
    }

    sw.stop();
    return ExportSummary(
      files: files,
      totalRows: files.fold(0, (s, f) => s + f.totalRows),
      duration: sw.elapsed,
    );
  }

  // ─── Data fetchers with filter ────────────────────────────────────────────

  static Future<List<Visit>> _fetchVisits(
    DatabaseService db,
    ExportConfig c,
  ) async {
    List<Visit> list = c.hasDateFilter
        ? await db.getVisitsByDateRange(_fmt(c.startDate!), _fmt(c.endDate!))
        : await db.getVisits();
    if (c.hasSiteFilter)
      list = list
          .where(
            (v) => v.site.toLowerCase().contains(c.filterSite!.toLowerCase()),
          )
          .toList();
    if (c.hasDeptFilter)
      list = list
          .where(
            (v) => v.departemen.toLowerCase().contains(
              c.filterDept!.toLowerCase(),
            ),
          )
          .toList();
    return list;
  }

  static Future<Map<int, VisitPrescriptionWithItems>> _fetchRx(
    DatabaseService db,
    List<Visit> visits,
  ) async {
    final map = <int, VisitPrescriptionWithItems>{};
    for (final v in visits) {
      if (v.id == null) continue;
      final rxList = await db.getVisitPrescriptions(v.id!);
      if (rxList.isNotEmpty) map[v.id!] = rxList.first;
    }
    return map;
  }

  static Future<List<DrugTest>> _fetchDrugs(
    DatabaseService db,
    ExportConfig c,
  ) async {
    List<DrugTest> list = c.hasDateFilter
        ? await db.getDrugTestsByDateRange(_fmt(c.startDate!), _fmt(c.endDate!))
        : await db.getDrugTests();
    if (c.hasSiteFilter)
      list = list
          .where(
            (d) => d.site.toLowerCase().contains(c.filterSite!.toLowerCase()),
          )
          .toList();
    if (c.hasDeptFilter)
      list = list
          .where(
            (d) => d.departemen.toLowerCase().contains(
              c.filterDept!.toLowerCase(),
            ),
          )
          .toList();
    return list;
  }

  static Future<List<FitToWork>> _fetchFtw(
    DatabaseService db,
    ExportConfig c,
  ) async {
    List<FitToWork> list = c.hasDateFilter
        ? await db.getFitToWorksByDateRange(
            _fmt(c.startDate!),
            _fmt(c.endDate!),
          )
        : await db.getFitToWorks();
    if (c.hasSiteFilter)
      list = list
          .where(
            (f) => f.site.toLowerCase().contains(c.filterSite!.toLowerCase()),
          )
          .toList();
    if (c.hasDeptFilter)
      list = list
          .where(
            (f) => f.departemen.toLowerCase().contains(
              c.filterDept!.toLowerCase(),
            ),
          )
          .toList();
    return list;
  }

  static Future<List<Fatigue>> _fetchFatigue(
    DatabaseService db,
    ExportConfig c,
  ) async {
    List<Fatigue> list = c.hasDateFilter
        ? await db.getFatiguesByDateRange(_fmt(c.startDate!), _fmt(c.endDate!))
        : await db.getFatigues();
    if (c.hasSiteFilter)
      list = list
          .where(
            (f) => f.site.toLowerCase().contains(c.filterSite!.toLowerCase()),
          )
          .toList();
    if (c.hasDeptFilter)
      list = list
          .where(
            (f) => f.departemen.toLowerCase().contains(
              c.filterDept!.toLowerCase(),
            ),
          )
          .toList();
    return list;
  }

  // ─── Row builders ─────────────────────────────────────────────────────────

  static List<List<String>> _visitRows(List<Visit> data) =>
      data.asMap().entries.map((e) {
        final i = e.key;
        final v = e.value;
        return [
          '${i + 1}',
          v.tanggal,
          v.site,
          v.nama,
          v.posisi,
          v.departemen,
          v.keluhan,
          v.diagnosa,
          '${v.jumlahJamTidur}',
          '${v.suhuBadan}',
          v.tekananDarah,
          '${v.pernapasan}',
          '${v.nadi}',
          v.keterangan,
        ];
      }).toList();

  /// Flatten resep → satu baris per item
  static List<List<String>> _flatRx(
    Map<int, VisitPrescriptionWithItems> rxMap,
    List<Visit> visits,
  ) {
    final rows = <List<String>>[];
    int no = 1;
    for (final v in visits) {
      if (v.id == null || !rxMap.containsKey(v.id)) continue;
      final rx = rxMap[v.id!]!;
      for (final item in rx.items) {
        rows.add([
          '$no',
          rx.prescription.tanggal,
          v.nama,
          v.site,
          v.departemen,
          item.medicineName,
          '${item.jumlah}',
          item.satuan,
          item.aturanPakai,
          rx.prescription.catatan,
        ]);
        no++;
      }
    }
    return rows;
  }

  static List<List<String>> _drugRows(List<DrugTest> data) =>
      data.asMap().entries.map((e) {
        final i = e.key;
        final d = e.value;
        return [
          '${i + 1}',
          d.tanggal,
          d.site,
          d.nama,
          d.posisi,
          d.departemen,
          d.amp,
          d.met,
          d.thc,
          d.coc,
          d.bzo,
          d.hasil,
          d.keterangan,
        ];
      }).toList();

  static List<List<String>> _ftwRows(List<FitToWork> data) =>
      data.asMap().entries.map((e) {
        final i = e.key;
        final f = e.value;
        return [
          '${i + 1}',
          f.tanggal,
          f.site,
          f.nama,
          f.posisi,
          f.departemen,
          f.lokasi,
          f.shift,
          '${f.jumlahJamTidur}',
          f.jamMasuk,
          f.tidurKurangDari6 ? 'Ya' : 'Tidak',
          f.kesehatan,
          f.minumObat ? 'Ya' : 'Tidak',
          f.pembatasanKerja,
          f.isFit ? 'FIT' : 'NOT FIT',
          f.keterangan,
        ];
      }).toList();

  static List<List<String>> _fatigueRows(List<Fatigue> data) =>
      data.asMap().entries.map((e) {
        final i = e.key;
        final f = e.value;
        return [
          '${i + 1}',
          f.tanggal,
          f.site,
          f.nama,
          f.posisi,
          f.departemen,
          f.shift,
          '${f.jumlahJamTidur}',
          f.tekananDarah,
          '${f.nadi}',
          '${f.pernapasan}',
          '${f.suhuBadan}',
          f.obatDikonsumsi,
          f.efekObat,
          f.kriteria,
          f.pembatasanKerja,
          f.keterangan,
        ];
      }).toList();

  static List<List<String>> _medRows(List<Medicine> data) =>
      data.asMap().entries.map((e) {
        final i = e.key;
        final m = e.value;
        return [
          '${i + 1}',
          m.nama,
          m.kategori,
          m.satuan,
          '${m.stok}',
          m.keterangan,
        ];
      }).toList();

  // ─── Excel writers ────────────────────────────────────────────────────────

  static Future<ExportFileResult> _xlsxSingle(
    ExportConfig config,
    List<Visit> visits,
    List<List<String>> rxFlat,
    List<DrugTest> drugs,
    List<FitToWork> ftws,
    List<Fatigue> fatigues,
    List<Medicine> medicines,
  ) async {
    const baseName = 'export_oh_all';
    final rowCounts = <String, int>{};
    try {
      final excel = Excel.createExcel();
      bool firstUsed = false;

      void add(String name, List<String> headers, List<List<String>> rows) {
        if (!firstUsed) {
          excel.rename(excel.sheets.keys.first, name);
          firstUsed = true;
        } else {
          excel[name];
        }
        _writeSheet(excel[name], headers, rows);
        rowCounts[name] = rows.length;
      }

      if (visits.isNotEmpty) add('Kunjungan', _hVisit, _visitRows(visits));
      if (rxFlat.isNotEmpty) add('Resep', _hRx, rxFlat);
      if (drugs.isNotEmpty) add('Tes Narkoba', _hDrug, _drugRows(drugs));
      if (ftws.isNotEmpty) add('Fit To Work', _hFtw, _ftwRows(ftws));
      if (fatigues.isNotEmpty)
        add('Fatigue', _hFatigue, _fatigueRows(fatigues));
      if (medicines.isNotEmpty) add('Obat', _hMed, _medRows(medicines));

      if (!firstUsed) {
        excel.rename(excel.sheets.keys.first, 'Info');
        excel['Info']
            .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
            .value = TextCellValue(
          'Tidak ada data pada filter yang dipilih',
        );
        rowCounts['Info'] = 0;
      }

      final path = await _saveXlsx(excel, baseName);
      return ExportFileResult(
        fileName: '$baseName.xlsx',
        format: ExportFormat.excel,
        path: path,
        rowCounts: rowCounts,
      );
    } catch (e, st) {
      debugPrint('_xlsxSingle: $e\n$st');
      return ExportFileResult(
        fileName: '$baseName.xlsx',
        format: ExportFormat.excel,
        error: e.toString(),
        rowCounts: {},
      );
    }
  }

  static Future<ExportFileResult> _xlsxSheet(
    String baseName,
    String sheetName,
    List<String> headers,
    List<List<String>> rows,
  ) async {
    try {
      final excel = Excel.createExcel();
      excel.rename(excel.sheets.keys.first, sheetName);
      _writeSheet(excel[sheetName], headers, rows);
      final path = await _saveXlsx(excel, baseName);
      return ExportFileResult(
        fileName: '$baseName.xlsx',
        format: ExportFormat.excel,
        path: path,
        rowCounts: {sheetName: rows.length},
      );
    } catch (e) {
      return ExportFileResult(
        fileName: '$baseName.xlsx',
        format: ExportFormat.excel,
        error: e.toString(),
        rowCounts: {},
      );
    }
  }

  static void _writeSheet(
    Sheet sheet,
    List<String> headers,
    List<List<String>> rows,
  ) {
    for (var i = 0; i < headers.length; i++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
      );
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = CellStyle(bold: true);
    }
    for (var r = 0; r < rows.length; r++) {
      final row = rows[r];
      for (var c = 0; c < row.length; c++) {
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r + 1))
            .value = TextCellValue(
          row[c],
        );
      }
    }
  }

  static Future<String?> _saveXlsx(Excel excel, String baseName) async {
    final bytes = excel.encode();
    if (bytes == null) throw Exception('encode() returned null');
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/${baseName}_${_ts()}.xlsx';
    await File(path).writeAsBytes(bytes);
    return path;
  }

  // ─── CSV writer ───────────────────────────────────────────────────────────

  static Future<ExportFileResult> _csvFile(
    String baseName,
    String tableName,
    List<String> headers,
    List<List<String>> rows,
  ) async {
    final fileName = '$baseName.csv';
    try {
      final buf = StringBuffer();
      buf.writeln(_csvLine(headers));
      for (final row in rows) buf.writeln(_csvLine(row));
      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/${baseName}_${_ts()}.csv';
      // BOM untuk Excel compatibility
      final bom = '\uFEFF';
      await File(path).writeAsString('$bom${buf.toString()}');
      return ExportFileResult(
        fileName: fileName,
        format: ExportFormat.csv,
        path: path,
        rowCounts: {tableName: rows.length},
      );
    } catch (e) {
      return ExportFileResult(
        fileName: fileName,
        format: ExportFormat.csv,
        error: e.toString(),
        rowCounts: {},
      );
    }
  }

  static String _csvLine(List<String> fields) =>
      fields.map((f) => '"${f.replaceAll('"', '""')}"').join(',');

  // ─── Helpers ──────────────────────────────────────────────────────────────

  static String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}'
      '-${d.day.toString().padLeft(2, '0')}';

  static String _ts() =>
      DateTime.now().toIso8601String().replaceAll(':', '-').substring(0, 19);
}
