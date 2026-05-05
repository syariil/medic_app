import 'package:sqflite/sqflite.dart';
import 'package:medic_app/repositories/db_provider.dart';
import '../models/patient.dart';
import 'patient_repository.dart';

class PatientRepositoryImpl implements PatientRepository {
  static final PatientRepositoryImpl _instance =
      PatientRepositoryImpl._internal();

  factory PatientRepositoryImpl() => _instance;

  PatientRepositoryImpl._internal();

  Future<Database> get _db => DbProvider.instance.database;

  @override
  Future<int> insert(Patient patient) async {
    final db = await _db;
    // Jangan insert id secara manual — biarkan AUTOINCREMENT
    final map = patient.toMap()..remove('id');
    return db.insert('patients', map);
  }

  @override
  Future<List<Patient>> getAll() async {
    final db = await _db;
    final rows = await db.query('patients', orderBy: 'id DESC');
    return rows.map(Patient.fromMap).toList();
  }

  @override
  Future<Patient?> getById(int id) async {
    final db = await _db;
    final rows = await db.query(
      'patients',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : Patient.fromMap(rows.first);
  }

  @override
  Future<int> update(Patient patient) async {
    final db = await _db;
    return db.update(
      'patients',
      patient.toMap(),
      where: 'id = ?',
      whereArgs: [patient.id],
    );
  }

  @override
  Future<int> delete(int id) async {
    final db = await _db;
    return db.delete('patients', where: 'id = ?', whereArgs: [id]);
  }

  // ── PatientRepository ─────────────────────────────────────────────────────

  @override
  Future<List<Patient>> search(String query) async {
    final db = await _db;
    final q = '%${query.toLowerCase()}%';
    final rows = await db.rawQuery(
      '''
      SELECT * FROM patients
      WHERE LOWER(nama) LIKE ? OR nik LIKE ? OR LOWER(diagnosa) LIKE ?
      ORDER BY id DESC
      ''',
      [q, q, q],
    );
    return rows.map(Patient.fromMap).toList();
  }
}
