import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../models/visit.dart';
import '../models/drug_test.dart';
import '../models/fit_to_work.dart';
import '../models/fatigue.dart';
import '../models/medicine.dart';
import '../models/import_result.dart';
import 'database_service.dart';

class ImportService {
  ImportService._();

  // ── Sheet name aliases (case-insensitive) ─────────────────────────────────

  static const _sVisit = ['kunjungan', 'visit', 'visits', 'data kunjungan'];
  static const _sDrug = [
    'tes narkoba',
    'narkoba',
    'drug test',
    'drug_test',
    'drug tests',
  ];
  static const _sFtw = ['fit to work', 'fit_to_work', 'ftw', 'kelayakan kerja'];
  static const _sFatigue = ['fatigue', 'fatigues', 'kelelahan'];
  static const _sMedicine = [
    'obat',
    'farmasi',
    'medicine',
    'medicines',
    'data obat',
  ];

  // ── Column aliases ────────────────────────────────────────────────────────

  static const _cTanggal = ['tanggal', 'date', 'tgl', 'tanggal kunjungan'];
  static const _cSite = ['site', 'lokasi site', 'nama site'];
  static const _cNama = ['nama', 'name', 'nama lengkap'];
  static const _cPosisi = ['posisi', 'jabatan', 'position', 'posisi/jabatan'];
  static const _cDept = ['departemen', 'department', 'dept', 'dept.'];
  static const _cKeluhan = ['keluhan', 'complaint', 'keluhan pasien'];
  static const _cDiagnosa = ['diagnosa', 'diagnosis'];
  static const _cJamTidur = [
    'jam tidur',
    'jumlah jam tidur',
    'sleep hours',
    'jam_tidur',
  ];
  static const _cSuhu = ['suhu', 'suhu badan', 'temperature', 'suhu (°c)'];
  static const _cTd = ['tekanan darah', 'td', 'blood pressure'];
  static const _cPernap = [
    'pernapasan',
    'respiratory',
    'pernapasan (x/m)',
    'napas',
  ];
  static const _cNadi = ['nadi', 'pulse', 'nadi (x/m)', 'heart rate'];
  static const _cKet = ['keterangan', 'notes', 'catatan', 'keterangan/catatan'];
  static const _cAmp = ['amp', 'amphetamine'];
  static const _cMet = ['met', 'methamphetamine'];
  static const _cThc = ['thc', 'cannabis', 'thc (cannabis)'];
  static const _cCoc = ['coc', 'cocaine'];
  static const _cBzo = ['bzo', 'benzodiazepine'];
  static const _cHasil = ['hasil', 'result', 'hasil keseluruhan'];
  static const _cLokasi = ['lokasi', 'work location'];
  static const _cShift = ['shift', 'jadwal shift'];
  static const _cJamMasuk = ['jam masuk', 'time in', 'jam_masuk'];
  static const _cTidurKurang6 = [
    'tidur ≤6jam',
    'tidur kurang 6',
    'tidur <= 6 jam',
    'tidur_kurang_dari_6',
  ];
  static const _cKesehatan = ['kesehatan', 'health', 'kondisi kesehatan'];
  static const _cMinumObat = ['minum obat', 'taking medicine', 'minum_obat'];
  static const _cPembatasan = [
    'pembatasan kerja',
    'work restriction',
    'pembatasan',
  ];
  static const _cObatKonsumsi = [
    'obat dikonsumsi',
    'obat yang dikonsumsi',
    'medicine taken',
  ];
  static const _cEfekObat = ['efek obat', 'drug effect', 'efek'];
  static const _cKriteria = ['kriteria', 'criteria', 'status fatigue'];
  static const _cKategori = ['kategori', 'category', 'kategori obat'];
  static const _cSatuan = ['satuan', 'unit'];
  static const _cStok = ['stok', 'stock', 'jumlah stok'];

  // ─────────────────────────────────────────────────────────────────────────
  // PICK FILE
  // ─────────────────────────────────────────────────────────────────────────

  static Future<String?> pickFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
      allowMultiple: false,
    );
    return result?.files.single.path;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PARSE
  // ─────────────────────────────────────────────────────────────────────────

  static Future<ImportResult> parseFile(String path) async {
    try {
      final bytes = await File(path).readAsBytes();
      final excel = Excel.decodeBytes(bytes);

      final visits = <ParsedRow<Visit>>[];
      final drugs = <ParsedRow<DrugTest>>[];
      final ftws = <ParsedRow<FitToWork>>[];
      final fatigues = <ParsedRow<Fatigue>>[];
      final medicines = <ParsedRow<Medicine>>[];
      final errors = <SheetError>[];

      for (final sName in excel.sheets.keys) {
        final sheet = excel.sheets[sName]!;
        final key = sName.trim().toLowerCase();

        if (_sVisit.contains(key))
          visits.addAll(_parseVisits(sheet, sName, errors));
        else if (_sDrug.contains(key))
          drugs.addAll(_parseDrugs(sheet, sName, errors));
        else if (_sFtw.contains(key))
          ftws.addAll(_parseFtws(sheet, sName, errors));
        else if (_sFatigue.contains(key))
          fatigues.addAll(_parseFatigues(sheet, sName, errors));
        else if (_sMedicine.contains(key))
          medicines.addAll(_parseMedicines(sheet, sName, errors));
      }

      return ImportResult(
        visits: visits,
        drugTests: drugs,
        fitToWorks: ftws,
        fatigues: fatigues,
        medicines: medicines,
        globalErrors: errors,
      );
    } catch (e, st) {
      debugPrint('ImportService.parseFile: $e\n$st');
      return ImportResult(
        visits: [],
        drugTests: [],
        fitToWorks: [],
        fatigues: [],
        medicines: [],
        globalErrors: [SheetError('file', 0, 'Gagal membaca file: $e')],
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // IMPORT TO DB
  // ─────────────────────────────────────────────────────────────────────────

  static Future<ImportSummary> importToDb(
    ImportResult result,
    DatabaseService db,
  ) async {
    int vOk = 0, dOk = 0, ftwOk = 0, fatOk = 0, medOk = 0, skip = 0;
    final errs = <String>[];

    Future<void> run<T>(
      List<ParsedRow<T>> rows,
      Future Function(T) insert,
      String label,
      void Function() inc,
    ) async {
      for (final r in rows.where((x) => x.isValid)) {
        try {
          await insert(r.data as T);
          inc();
        } catch (e) {
          skip++;
          errs.add('$label baris ${r.rowNumber}: $e');
        }
      }
    }

    await run(
      result.visits,
      (v) => db.insertVisit(v),
      'Kunjungan',
      () => vOk++,
    );
    await run(
      result.drugTests,
      (d) => db.insertDrugTest(d),
      'Narkoba',
      () => dOk++,
    );
    await run(
      result.fitToWorks,
      (f) => db.insertFitToWork(f),
      'FTW',
      () => ftwOk++,
    );
    await run(
      result.fatigues,
      (f) => db.insertFatigue(f),
      'Fatigue',
      () => fatOk++,
    );
    await run(
      result.medicines,
      (m) => db.insertMedicine(m),
      'Obat',
      () => medOk++,
    );

    return ImportSummary(
      visitsInserted: vOk,
      drugTestsInserted: dOk,
      fitToWorksInserted: ftwOk,
      fatiguesInserted: fatOk,
      medicinesInserted: medOk,
      skipped: skip,
      errors: errs,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TEMPLATE GENERATOR
  // ─────────────────────────────────────────────────────────────────────────

  static Future<String?> generateTemplate() async {
    try {
      final excel = Excel.createExcel();
      bool first = true;

      void addSheet(
        String name,
        List<String> headers,
        List<List<String>> samples,
      ) {
        if (first) {
          excel.rename(excel.sheets.keys.first, name);
          first = false;
        } else {
          excel[name];
        }
        final s = excel[name];
        _writeHeader(s, headers);
        for (var i = 0; i < samples.length; i++) {
          _writeRow(s, i + 1, samples[i]);
        }
      }

      addSheet(
        'Kunjungan',
        [
          'Tanggal',
          'Site',
          'Nama',
          'Posisi',
          'Departemen',
          'Keluhan',
          'Diagnosa',
          'Jam Tidur',
          'Suhu Badan',
          'Tekanan Darah',
          'Pernapasan',
          'Nadi',
          'Keterangan',
        ],
        [
          [
            '2024-01-15',
            'Site A',
            'Budi Santoso',
            'Operator',
            'Tambang',
            'Demam dan pusing',
            'ISPA',
            '7',
            '36.5',
            '120/80',
            '18',
            '80',
            '',
          ],
          [
            '2024-01-16',
            'Site B',
            'Siti Rahma',
            'Supervisor',
            'Produksi',
            'Sakit kepala',
            'Migrain',
            '6',
            '36.8',
            '130/85',
            '20',
            '82',
            'Perlu istirahat',
          ],
        ],
      );

      addSheet(
        'Tes Narkoba',
        [
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
        ],
        [
          [
            '2024-01-15',
            'Site A',
            'Ahmad Fauzi',
            'Operator',
            'Tambang',
            'Negatif',
            'Negatif',
            'Negatif',
            'Negatif',
            'Negatif',
            'Negatif',
            '',
          ],
          [
            '2024-01-16',
            'Site B',
            'Dewi Kusuma',
            'Driver',
            'Logistik',
            'Negatif',
            'Negatif',
            'Positif',
            'Negatif',
            'Negatif',
            'Positif',
            'Konfirmasi ulang',
          ],
        ],
      );

      addSheet(
        'Fit To Work',
        [
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
          'Keterangan',
        ],
        [
          [
            '2024-01-15',
            'Site A',
            'Rudi Hartono',
            'Operator',
            'Tambang',
            'Pit A',
            'Pagi',
            '8',
            '07:00',
            'Tidak',
            'Baik',
            'Tidak',
            'Tidak Ada',
            '',
          ],
          [
            '2024-01-16',
            'Site A',
            'Lina Wahyuni',
            'Mekanik',
            'Maintenance',
            'Workshop',
            'Siang',
            '5',
            '15:00',
            'Ya',
            'Kurang Baik',
            'Ya',
            'Kerja ringan saja',
            'Kelelahan',
          ],
        ],
      );

      addSheet(
        'Fatigue',
        [
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
          'Suhu Badan',
          'Obat Dikonsumsi',
          'Efek Obat',
          'Kriteria',
          'Pembatasan Kerja',
          'Keterangan',
        ],
        [
          [
            '2024-01-15',
            'Site A',
            'Hendra Wijaya',
            'Operator',
            'Tambang',
            'Pagi',
            '7',
            '120/80',
            '78',
            '18',
            '36.5',
            'Tidak Ada',
            'Tidak Ada',
            'Fit',
            'Tidak Ada',
            '',
          ],
          [
            '2024-01-16',
            'Site B',
            'Maya Sari',
            'Supervisor',
            'Produksi',
            'Malam',
            '4',
            '140/90',
            '92',
            '22',
            '37.2',
            'Paracetamol',
            'Mengantuk',
            'Fatigue Berat',
            'Dilarang mengoperasikan alat berat',
            'Perlu istirahat',
          ],
        ],
      );

      addSheet(
        'Obat',
        ['Nama', 'Kategori', 'Satuan', 'Stok', 'Keterangan'],
        [
          [
            'Paracetamol 500mg',
            'Analgesik',
            'Tablet',
            '100',
            'Diminum 3x sehari',
          ],
          ['Amoxicillin 500mg', 'Antibiotik', 'Kapsul', '50', 'Sesuai resep'],
          ['Antasida', 'Antasida', 'Tablet', '80', 'Sebelum makan'],
        ],
      );

      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/template_import_oh.xlsx';
      final bytes = excel.encode();
      if (bytes == null) throw Exception('encode null');
      await File(path).writeAsBytes(bytes);
      return path;
    } catch (e) {
      debugPrint('generateTemplate: $e');
      return null;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PRIVATE PARSERS
  // ─────────────────────────────────────────────────────────────────────────

  static List<ParsedRow<Visit>> _parseVisits(
    Sheet sheet,
    String sName,
    List<SheetError> errs,
  ) {
    final result = <ParsedRow<Visit>>[];
    if (sheet.rows.length <= 1) return result;

    final h = _hmap(sheet);
    final iNama = _col(h, _cNama);
    final iSite = _col(h, _cSite);
    final iTgl = _col(h, _cTanggal);
    final iPosisi = _col(h, _cPosisi);
    final iDept = _col(h, _cDept);
    final iKeluhan = _col(h, _cKeluhan);
    final iDiag = _col(h, _cDiagnosa);
    final iJamT = _col(h, _cJamTidur);
    final iSuhu = _col(h, _cSuhu);
    final iTd = _col(h, _cTd);
    final iPernap = _col(h, _cPernap);
    final iNadi = _col(h, _cNadi);
    final iKet = _col(h, _cKet);

    if (iNama == null || iSite == null) {
      errs.add(SheetError(sName, 0, 'Kolom Nama dan Site wajib ada'));
      return result;
    }

    for (var i = 1; i < sheet.rows.length; i++) {
      final row = sheet.rows[i];
      final nama = _val(row, iNama);
      if (nama == null) continue;

      final errList = <String>[];
      if (nama.isEmpty) errList.add('Nama kosong');
      final site = _val(row, iSite) ?? '';
      if (site.isEmpty) errList.add('Site kosong');

      if (errList.isNotEmpty) {
        result.add(
          ParsedRow(
            rowNumber: i,
            status: RowStatus.invalid,
            message: errList.join(', '),
          ),
        );
        continue;
      }

      final tglRaw = _val(row, iTgl) ?? '';
      final tgl =
          _parseDate(tglRaw) ??
          DateTime.now().toIso8601String().substring(0, 10);
      final warn = tglRaw.isNotEmpty && _parseDate(tglRaw) == null
          ? 'Format tanggal tidak dikenal, diisi hari ini'
          : null;

      result.add(
        ParsedRow(
          rowNumber: i,
          status: warn != null ? RowStatus.warning : RowStatus.valid,
          message: warn,
          data: Visit(
            tanggal: tgl,
            site: site,
            nama: nama,
            posisi: _val(row, iPosisi) ?? '',
            departemen: _val(row, iDept) ?? '',
            keluhan: _val(row, iKeluhan) ?? '',
            diagnosa: _val(row, iDiag) ?? '',
            jumlahJamTidur: double.tryParse(_val(row, iJamT) ?? '') ?? 0,
            suhuBadan: double.tryParse(_val(row, iSuhu) ?? '') ?? 0,
            tekananDarah: _val(row, iTd) ?? '',
            pernapasan: int.tryParse(_val(row, iPernap) ?? '') ?? 0,
            nadi: int.tryParse(_val(row, iNadi) ?? '') ?? 0,
            keterangan: _val(row, iKet) ?? '',
          ),
        ),
      );
    }
    return result;
  }

  static List<ParsedRow<DrugTest>> _parseDrugs(
    Sheet sheet,
    String sName,
    List<SheetError> errs,
  ) {
    final result = <ParsedRow<DrugTest>>[];
    if (sheet.rows.length <= 1) return result;

    final h = _hmap(sheet);
    final iNama = _col(h, _cNama);
    final iSite = _col(h, _cSite);
    if (iNama == null || iSite == null) {
      errs.add(SheetError(sName, 0, 'Kolom Nama dan Site wajib ada'));
      return result;
    }

    final iTgl = _col(h, _cTanggal);
    final iPos = _col(h, _cPosisi);
    final iDept = _col(h, _cDept);
    final iAmp = _col(h, _cAmp);
    final iMet = _col(h, _cMet);
    final iThc = _col(h, _cThc);
    final iCoc = _col(h, _cCoc);
    final iBzo = _col(h, _cBzo);
    final iHasil = _col(h, _cHasil);
    final iKet = _col(h, _cKet);

    for (var i = 1; i < sheet.rows.length; i++) {
      final row = sheet.rows[i];
      final nama = _val(row, iNama);
      if (nama == null || nama.isEmpty) continue;

      final amp = _drugVal(_val(row, iAmp));
      final met = _drugVal(_val(row, iMet));
      final thc = _drugVal(_val(row, iThc));
      final coc = _drugVal(_val(row, iCoc));
      final bzo = _drugVal(_val(row, iBzo));

      // Auto-calc hasil jika tidak diisi
      final hasilRaw = _val(row, iHasil);
      final hasil = (hasilRaw != null && hasilRaw.isNotEmpty)
          ? hasilRaw
          : [amp, met, thc, coc, bzo].any((v) => v == 'Positif')
          ? 'Positif'
          : 'Negatif';

      result.add(
        ParsedRow(
          rowNumber: i,
          status: RowStatus.valid,
          data: DrugTest(
            tanggal:
                _parseDate(_val(row, iTgl) ?? '') ??
                DateTime.now().toIso8601String().substring(0, 10),
            site: _val(row, iSite) ?? '',
            nama: nama,
            posisi: _val(row, iPos) ?? '',
            departemen: _val(row, iDept) ?? '',
            amp: amp,
            met: met,
            thc: thc,
            coc: coc,
            bzo: bzo,
            hasil: hasil,
            keterangan: _val(row, iKet) ?? '',
          ),
        ),
      );
    }
    return result;
  }

  static List<ParsedRow<FitToWork>> _parseFtws(
    Sheet sheet,
    String sName,
    List<SheetError> errs,
  ) {
    final result = <ParsedRow<FitToWork>>[];
    if (sheet.rows.length <= 1) return result;

    final h = _hmap(sheet);
    final iNama = _col(h, _cNama);
    final iSite = _col(h, _cSite);
    if (iNama == null || iSite == null) {
      errs.add(SheetError(sName, 0, 'Kolom Nama dan Site wajib ada'));
      return result;
    }

    final iTgl = _col(h, _cTanggal);
    final iPos = _col(h, _cPosisi);
    final iDept = _col(h, _cDept);
    final iLok = _col(h, _cLokasi);
    final iShift = _col(h, _cShift);
    final iJamT = _col(h, _cJamTidur);
    final iJamM = _col(h, _cJamMasuk);
    final iTidurK = _col(h, _cTidurKurang6);
    final iKeseh = _col(h, _cKesehatan);
    final iMinum = _col(h, _cMinumObat);
    final iPemb = _col(h, _cPembatasan);
    final iKet = _col(h, _cKet);

    for (var i = 1; i < sheet.rows.length; i++) {
      final row = sheet.rows[i];
      final nama = _val(row, iNama);
      if (nama == null || nama.isEmpty) continue;

      result.add(
        ParsedRow(
          rowNumber: i,
          status: RowStatus.valid,
          data: FitToWork(
            tanggal:
                _parseDate(_val(row, iTgl) ?? '') ??
                DateTime.now().toIso8601String().substring(0, 10),
            site: _val(row, iSite) ?? '',
            nama: nama,
            posisi: _val(row, iPos) ?? '',
            departemen: _val(row, iDept) ?? '',
            lokasi: _val(row, iLok) ?? '',
            shift: _shiftVal(_val(row, iShift)),
            jumlahJamTidur: double.tryParse(_val(row, iJamT) ?? '') ?? 0,
            jamMasuk: _val(row, iJamM) ?? '',
            tidurKurangDari6: _boolVal(_val(row, iTidurK)),
            kesehatan: _kesehatanVal(_val(row, iKeseh)),
            minumObat: _boolVal(_val(row, iMinum)),
            pembatasanKerja: _val(row, iPemb) ?? 'Tidak Ada',
            keterangan: _val(row, iKet) ?? '',
          ),
        ),
      );
    }
    return result;
  }

  static List<ParsedRow<Fatigue>> _parseFatigues(
    Sheet sheet,
    String sName,
    List<SheetError> errs,
  ) {
    final result = <ParsedRow<Fatigue>>[];
    if (sheet.rows.length <= 1) return result;

    final h = _hmap(sheet);
    final iNama = _col(h, _cNama);
    final iSite = _col(h, _cSite);
    if (iNama == null || iSite == null) {
      errs.add(SheetError(sName, 0, 'Kolom Nama dan Site wajib ada'));
      return result;
    }

    final iTgl = _col(h, _cTanggal);
    final iPos = _col(h, _cPosisi);
    final iDept = _col(h, _cDept);
    final iShift = _col(h, _cShift);
    final iJamT = _col(h, _cJamTidur);
    final iTd = _col(h, _cTd);
    final iNadi = _col(h, _cNadi);
    final iPernap = _col(h, _cPernap);
    final iSuhu = _col(h, _cSuhu);
    final iObat = _col(h, _cObatKonsumsi);
    final iEfek = _col(h, _cEfekObat);
    final iKrit = _col(h, _cKriteria);
    final iPemb = _col(h, _cPembatasan);
    final iKet = _col(h, _cKet);

    for (var i = 1; i < sheet.rows.length; i++) {
      final row = sheet.rows[i];
      final nama = _val(row, iNama);
      if (nama == null || nama.isEmpty) continue;

      result.add(
        ParsedRow(
          rowNumber: i,
          status: RowStatus.valid,
          data: Fatigue(
            tanggal:
                _parseDate(_val(row, iTgl) ?? '') ??
                DateTime.now().toIso8601String().substring(0, 10),
            site: _val(row, iSite) ?? '',
            nama: nama,
            posisi: _val(row, iPos) ?? '',
            departemen: _val(row, iDept) ?? '',
            shift: _shiftVal(_val(row, iShift)),
            jumlahJamTidur: double.tryParse(_val(row, iJamT) ?? '') ?? 0,
            tekananDarah: _val(row, iTd) ?? '',
            nadi: int.tryParse(_val(row, iNadi) ?? '') ?? 0,
            pernapasan: int.tryParse(_val(row, iPernap) ?? '') ?? 0,
            suhuBadan: double.tryParse(_val(row, iSuhu) ?? '') ?? 0,
            obatDikonsumsi: _val(row, iObat) ?? '',
            efekObat: _val(row, iEfek) ?? '',
            kriteria: _kriteriaVal(_val(row, iKrit)),
            pembatasanKerja: _val(row, iPemb) ?? 'Tidak Ada',
            keterangan: _val(row, iKet) ?? '',
          ),
        ),
      );
    }
    return result;
  }

  static List<ParsedRow<Medicine>> _parseMedicines(
    Sheet sheet,
    String sName,
    List<SheetError> errs,
  ) {
    final result = <ParsedRow<Medicine>>[];
    if (sheet.rows.length <= 1) return result;

    final h = _hmap(sheet);
    final iNama = _col(h, _cNama);
    if (iNama == null) {
      errs.add(SheetError(sName, 0, 'Kolom Nama wajib ada'));
      return result;
    }
    final iKat = _col(h, _cKategori);
    final iSat = _col(h, _cSatuan);
    final iStok = _col(h, _cStok);
    final iKet = _col(h, _cKet);

    for (var i = 1; i < sheet.rows.length; i++) {
      final row = sheet.rows[i];
      final nama = _val(row, iNama);
      if (nama == null || nama.isEmpty) continue;

      final stokRaw = _val(row, iStok) ?? '0';
      final stok = int.tryParse(stokRaw) ?? 0;
      final warn = int.tryParse(stokRaw) == null && stokRaw.isNotEmpty
          ? 'Stok "$stokRaw" bukan angka, diisi 0'
          : null;

      result.add(
        ParsedRow(
          rowNumber: i,
          status: warn != null ? RowStatus.warning : RowStatus.valid,
          message: warn,
          data: Medicine(
            nama: nama,
            kategori: _val(row, iKat) ?? 'Lainnya',
            satuan: _val(row, iSat) ?? 'Tablet',
            stok: stok,
            keterangan: _val(row, iKet) ?? '',
          ),
        ),
      );
    }
    return result;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HELPER UTILS
  // ─────────────────────────────────────────────────────────────────────────

  static Map<String, int> _hmap(Sheet sheet) {
    final map = <String, int>{};
    if (sheet.rows.isEmpty) return map;
    for (var i = 0; i < sheet.rows.first.length; i++) {
      final cell = sheet.rows.first[i];
      if (cell?.value != null) {
        map[cell!.value.toString().trim().toLowerCase()] = i;
      }
    }
    return map;
  }

  static int? _col(Map<String, int> h, List<String> aliases) {
    for (final a in aliases) if (h.containsKey(a)) return h[a];
    return null;
  }

  static String? _val(List<Data?> row, int? idx) {
    if (idx == null || idx >= row.length) return null;
    final v = row[idx]?.value?.toString().trim();
    return (v == null || v.isEmpty) ? null : v;
  }

  static String? _parseDate(String raw) {
    if (raw.isEmpty) return null;
    if (DateTime.tryParse(raw) != null) return raw.substring(0, 10);
    // dd/mm/yyyy or dd-mm-yyyy
    final parts = raw.split(RegExp(r'[/.\-]'));
    if (parts.length == 3) {
      final d = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      final y = int.tryParse(parts[2]);
      if (d != null && m != null && y != null) {
        return '${y.toString().padLeft(4, '0')}-'
            '${m.toString().padLeft(2, '0')}-'
            '${d.toString().padLeft(2, '0')}';
      }
    }
    return null;
  }

  static String _drugVal(String? raw) {
    if (raw == null) return 'Negatif';
    final v = raw.toLowerCase();
    if (v == 'positif' || v == 'positive' || v == '+') return 'Positif';
    if (v == '-' || v == 'n/a') return '-';
    return 'Negatif';
  }

  static bool _boolVal(String? raw) {
    if (raw == null) return false;
    final v = raw.toLowerCase();
    return v == 'ya' || v == 'yes' || v == '1' || v == 'true';
  }

  static String _shiftVal(String? raw) {
    if (raw == null) return 'Pagi';
    final v = raw.toLowerCase();
    if (v.contains('siang') || v.contains('day')) return 'Siang';
    if (v.contains('malam') || v.contains('night')) return 'Malam';
    return 'Pagi';
  }

  static String _kesehatanVal(String? raw) {
    if (raw == null) return 'Baik';
    final v = raw.toLowerCase();
    if (v.contains('kurang') || v.contains('fair')) return 'Kurang Baik';
    if (v.contains('sakit') || v.contains('sick') || v.contains('ill'))
      return 'Sakit';
    return 'Baik';
  }

  static String _kriteriaVal(String? raw) {
    if (raw == null) return 'Fit';
    final v = raw.toLowerCase();
    if (v.contains('unfit') || v == 'tidak fit') return 'Unfit';
    if (v.contains('berat') || v.contains('severe')) return 'Fatigue Berat';
    if (v.contains('ringan') || v.contains('mild')) return 'Fatigue Ringan';
    return 'Fit';
  }

  static void _writeHeader(Sheet s, List<String> headers) {
    for (var i = 0; i < headers.length; i++) {
      final cell = s.cell(
        CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
      );
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = CellStyle(bold: true);
    }
  }

  static void _writeRow(Sheet s, int row, List<String> vals) {
    for (var i = 0; i < vals.length; i++) {
      s.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: row)).value =
          TextCellValue(vals[i]);
    }
  }
}
