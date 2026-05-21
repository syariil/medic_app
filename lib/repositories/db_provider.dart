import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import '../constants.dart';
import '../error_handler.dart';

class DbProvider {
  DbProvider._();
  static final DbProvider instance = DbProvider._();
  static Database? _db;
  static const int _version = 6;

  Future<Database> get database async {
    _db ??= await _init();
    return _db!;
  }

  Future<Database> _init() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, 'medic.db');
    return openDatabase(
      path,
      version: _version,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int _) async {
    for (final sql in _activeDDL) await db.execute(sql);
    // Create indexes for frequently queried columns
    for (final idx in DbIndexes.getAll()) {
      try {
        await db.execute(idx);
      } catch (e) {
        ErrorHandler.logWarning('Failed to create index: $idx', tag: 'DbIndexes');
      }
    }
  }

  Future<void> _onUpgrade(Database db, int old, int newV) async {
    if (old < 2) {
      await _safe(db, _sqlDoctorsLegacy);
      await _safe(db, _sqlMedicines);
    }
    if (old < 3) {
      await _safe(db, _sqlPrescriptionsLegacy);
      await _safe(db, _sqlPrescriptionItemsLegacy);
    }
    if (old < 4) {
      await _safe(db, _sqlVisitsV4);
      await _safe(db, _sqlDrugTests);
      await _safe(db, _sqlFitToWork);
      await _safe(db, _sqlFatigues);
    }
    if (old < 5) {
      await _safe(
        db,
        "ALTER TABLE visits ADD COLUMN keluhan TEXT NOT NULL DEFAULT ''",
      );
      await _safe(
        db,
        "ALTER TABLE visits ADD COLUMN diagnosa TEXT NOT NULL DEFAULT ''",
      );
      await _safe(db, _sqlVisitPrescriptions);
      await _safe(db, _sqlVisitPrescriptionItems);
    }
    if (old < 6) {
      // Hapus modul Pasien & Dokter sepenuhnya
      await _safe(db, 'DROP TABLE IF EXISTS prescription_items');
      await _safe(db, 'DROP TABLE IF EXISTS prescriptions');
      await _safe(db, 'DROP TABLE IF EXISTS patients');
      await _safe(db, 'DROP TABLE IF EXISTS doctors');
    }
  }

  Future<void> _safe(Database db, String sql) async {
    try {
      await db.execute(sql);
    } catch (e) {
      ErrorHandler.logWarning(
        'Failed to execute migration SQL: $sql',
        tag: 'DbMigration',
      );
    }
  }

  // ── DDL aktif ─────────────────────────────────────────────────────────────

  static const _sqlMedicines = '''
    CREATE TABLE IF NOT EXISTS medicines (
      id         INTEGER PRIMARY KEY AUTOINCREMENT,
      nama       TEXT NOT NULL,
      kategori   TEXT NOT NULL,
      satuan     TEXT NOT NULL,
      stok       INTEGER NOT NULL DEFAULT 0,
      keterangan TEXT NOT NULL DEFAULT ''
    )''';

  static const _sqlVisits = '''
    CREATE TABLE IF NOT EXISTS visits (
      id                INTEGER PRIMARY KEY AUTOINCREMENT,
      tanggal           TEXT NOT NULL,
      site              TEXT NOT NULL,
      nama              TEXT NOT NULL,
      posisi            TEXT NOT NULL,
      departemen        TEXT NOT NULL,
      keluhan           TEXT NOT NULL DEFAULT '',
      diagnosa          TEXT NOT NULL DEFAULT '',
      jumlah_jam_tidur  REAL NOT NULL DEFAULT 0,
      suhu_badan        REAL NOT NULL DEFAULT 0,
      tekanan_darah     TEXT NOT NULL DEFAULT '',
      pernapasan        INTEGER NOT NULL DEFAULT 0,
      nadi              INTEGER NOT NULL DEFAULT 0,
      keterangan        TEXT NOT NULL DEFAULT ''
    )''';

  static const _sqlVisitsV4 = '''
    CREATE TABLE IF NOT EXISTS visits (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      tanggal TEXT NOT NULL, site TEXT NOT NULL, nama TEXT NOT NULL,
      posisi TEXT NOT NULL, departemen TEXT NOT NULL,
      jumlah_jam_tidur REAL NOT NULL DEFAULT 0,
      suhu_badan REAL NOT NULL DEFAULT 0,
      tekanan_darah TEXT NOT NULL DEFAULT '',
      pernapasan INTEGER NOT NULL DEFAULT 0,
      nadi INTEGER NOT NULL DEFAULT 0,
      keterangan TEXT NOT NULL DEFAULT ''
    )''';

  static const _sqlVisitPrescriptions = '''
    CREATE TABLE IF NOT EXISTS visit_prescriptions (
      id       INTEGER PRIMARY KEY AUTOINCREMENT,
      visit_id INTEGER NOT NULL,
      tanggal  TEXT NOT NULL,
      catatan  TEXT NOT NULL DEFAULT '',
      FOREIGN KEY (visit_id) REFERENCES visits(id)
    )''';

  static const _sqlVisitPrescriptionItems = '''
    CREATE TABLE IF NOT EXISTS visit_prescription_items (
      id                    INTEGER PRIMARY KEY AUTOINCREMENT,
      visit_prescription_id INTEGER NOT NULL,
      medicine_id           INTEGER NOT NULL,
      medicine_name         TEXT NOT NULL,
      satuan                TEXT NOT NULL,
      jumlah                INTEGER NOT NULL DEFAULT 1,
      aturan_pakai          TEXT NOT NULL DEFAULT '',
      FOREIGN KEY (visit_prescription_id) REFERENCES visit_prescriptions(id),
      FOREIGN KEY (medicine_id) REFERENCES medicines(id)
    )''';

  static const _sqlDrugTests = '''
    CREATE TABLE IF NOT EXISTS drug_tests (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      tanggal TEXT NOT NULL, site TEXT NOT NULL,
      nama TEXT NOT NULL, posisi TEXT NOT NULL, departemen TEXT NOT NULL,
      amp TEXT NOT NULL DEFAULT 'Negatif', met TEXT NOT NULL DEFAULT 'Negatif',
      thc TEXT NOT NULL DEFAULT 'Negatif', coc TEXT NOT NULL DEFAULT 'Negatif',
      bzo TEXT NOT NULL DEFAULT 'Negatif', hasil TEXT NOT NULL DEFAULT 'Negatif',
      keterangan TEXT NOT NULL DEFAULT ''
    )''';

  static const _sqlFitToWork = '''
    CREATE TABLE IF NOT EXISTS fit_to_work (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      tanggal TEXT NOT NULL, site TEXT NOT NULL,
      nama TEXT NOT NULL, posisi TEXT NOT NULL, departemen TEXT NOT NULL,
      lokasi TEXT NOT NULL DEFAULT '', shift TEXT NOT NULL DEFAULT 'DAY',
      jumlah_jam_tidur REAL NOT NULL DEFAULT 0,
      jam_masuk TEXT NOT NULL DEFAULT '',
      tidur_kurang_dari_6 INTEGER NOT NULL DEFAULT 0,
      kesehatan TEXT NOT NULL DEFAULT 'Baik',
      minum_obat INTEGER NOT NULL DEFAULT 0,
      pembatasan_kerja TEXT NOT NULL DEFAULT 'Tidak Ada',
      keterangan TEXT NOT NULL DEFAULT ''
    )''';

  static const _sqlFatigues = '''
    CREATE TABLE IF NOT EXISTS fatigues (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      tanggal TEXT NOT NULL, site TEXT NOT NULL,
      nama TEXT NOT NULL, posisi TEXT NOT NULL, departemen TEXT NOT NULL,
      shift TEXT NOT NULL DEFAULT 'DAY',
      jumlah_jam_tidur REAL NOT NULL DEFAULT 0,
      tekanan_darah TEXT NOT NULL DEFAULT '',
      nadi INTEGER NOT NULL DEFAULT 0, pernapasan INTEGER NOT NULL DEFAULT 0,
      suhu_badan REAL NOT NULL DEFAULT 0,
      obat_dikonsumsi TEXT NOT NULL DEFAULT '',
      efek_obat TEXT NOT NULL DEFAULT '',
      kriteria TEXT NOT NULL DEFAULT 'Fit',
      pembatasan_kerja TEXT NOT NULL DEFAULT 'Tidak Ada',
      keterangan TEXT NOT NULL DEFAULT ''
    )''';

  // Legacy DDL (hanya untuk migration path)
  static const _sqlDoctorsLegacy =
      'CREATE TABLE IF NOT EXISTS doctors (id INTEGER PRIMARY KEY AUTOINCREMENT, nama TEXT, spesialis TEXT, jadwal TEXT, poli TEXT)';
  static const _sqlPrescriptionsLegacy =
      'CREATE TABLE IF NOT EXISTS prescriptions (id INTEGER PRIMARY KEY AUTOINCREMENT, patient_id INTEGER, tanggal TEXT, catatan TEXT)';
  static const _sqlPrescriptionItemsLegacy =
      'CREATE TABLE IF NOT EXISTS prescription_items (id INTEGER PRIMARY KEY AUTOINCREMENT, prescription_id INTEGER, medicine_id INTEGER, medicine_name TEXT, satuan TEXT, jumlah INTEGER, aturan_pakai TEXT)';

  static List<String> get _activeDDL => [
    _sqlMedicines,
    _sqlVisits,
    _sqlVisitPrescriptions,
    _sqlVisitPrescriptionItems,
    _sqlDrugTests,
    _sqlFitToWork,
    _sqlFatigues,
  ];
}
