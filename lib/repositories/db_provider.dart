import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class DbProvider {
  DbProvider._();
  static final DbProvider instance = DbProvider._();

  static Database? _db;

  static const int _version = 1;

  Future<Database> get database async {
    _db ??= await _init();
    return _db!;
  }

  Future<Database> _init() async {
    final Directory dir = await getApplicationDocumentsDirectory();
    final String path = join(dir.path, 'medic.db');

    return openDatabase(
      path,
      version: _version,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute(_sqlPatients);
    await db.execute(_sqlDoctors);
    await db.execute(_sqlMedicines);
    await db.execute(_sqlPrescriptions);
    await db.execute(_sqlPrescriptionIntems);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // on upggrate
  }

  static const _sqlPatients = '''
    CREATE TABLE IF NOT EXISTS patients (
      id       INTEGER PRIMARY KEY AUTOINCREMENT,
      nama     TEXT NOT NULL,
      nik      TEXT NOT NULL,
      tanggal  TEXT NOT NULL,
      keluhan  TEXT NOT NULL,
      diagnosa TEXT NOT NULL
    )
  ''';

  static const _sqlDoctors = '''
    CREATE TABLE IF NOT EXISTS doctors (
      id         INTEGER PRIMARY KEY AUTOINCREMENT,
      nama       TEXT NOT NULL,
      spesialis  TEXT NOT NULL,
      jadwal     TEXT NOT NULL,
      poli       TEXT NOT NULL
    )
  ''';

  static const _sqlMedicines = '''
    CREATE TABLE IF NOT EXISTS medicines (
      id          INTEGER PRIMARY KEY AUTOINCREMENT,
      nama        TEXT NOT NULL,
      kategori    TEXT NOT NULL,
      satuan      TEXT NOT NULL,
      stok        INTEGER NOT NULL DEFAULT 0,
      keterangan  TEXT NOT NULL DEFAULT ''
    )
  ''';

  static const _sqlPrescriptions = '''
    CREATE TABLE IF NOT EXISTS prescriptions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      patient_id INTEGER NOT NULL,
      tanggal TEXT NOT NULL,
      catatan TEXT NOT NULL DEFAULT '',
      FOREIGN KEY (patient_id) REFERENCES patients(id)
    )
''';

  static const _sqlPrescriptionIntems = '''
    CREATE TABLE IF NOT EXISTS prescription_items (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      prescription_id INTEGER NOT NULL,
      medicine_id INTEGER NOT NULL,
      medicine_name TEXT NOT NULL,
      satuan TEXT NOT NULL,
      jumlah INTEGER NOT NULL DEFAULT 1,
      aturan_pakai TEXT NOT NULL DEFAULT '',
      FOREIGN KEY (prescription_id) REFERENCES prescriptions(id),
      FOREIGN KEY (medicine_id) REFERENCES medicines(id)
    )
''';
}
