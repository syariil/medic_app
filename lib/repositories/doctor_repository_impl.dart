import 'package:sqflite/sqflite.dart';
import '../models/doctor.dart';
import 'doctor_repository.dart';
import 'db_provider.dart';

class DoctorRepositoryImpl implements DoctorRepository {
  static final DoctorRepositoryImpl _instance =
      DoctorRepositoryImpl._internal();
  factory DoctorRepositoryImpl() => _instance;
  DoctorRepositoryImpl._internal();

  Future<Database> get _db => DbProvider.instance.database;

  @override
  Future<int> insert(Doctor doctor) async {
    final db = await _db;
    final map = doctor.toMap()..remove('id');
    return db.insert('doctors', map);
  }

  @override
  Future<List<Doctor>> getAll() async {
    final db = await _db;
    final rows = await db.query('doctors', orderBy: 'nama ASC');
    return rows.map(Doctor.fromMap).toList();
  }

  @override
  Future<Doctor?> getById(int id) async {
    final db = await _db;
    final rows = await db.query(
      'doctors',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : Doctor.fromMap(rows.first);
  }

  @override
  Future<int> update(Doctor doctor) async {
    final db = await _db;
    return db.update(
      'doctors',
      doctor.toMap(),
      where: 'id = ?',
      whereArgs: [doctor.id],
    );
  }

  @override
  Future<int> delete(int id) async {
    final db = await _db;
    return db.delete('doctors', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<List<Doctor>> getByPoli(String poli) async {
    final db = await _db;
    final rows = await db.query(
      'doctors',
      where: 'LOWER(poli) = ?',
      whereArgs: [poli.toLowerCase()],
    );
    return rows.map(Doctor.fromMap).toList();
  }

  @override
  Future<List<Doctor>> getBySpesialis(String spesialis) async {
    final db = await _db;
    final rows = await db.query(
      'doctors',
      where: 'LOWER(spesialis) = ?',
      whereArgs: [spesialis],
    );
    return rows.map(Doctor.fromMap).toList();
  }

  @override
  Future<List<Doctor>> search(String query) async {
    final db = await _db;
    final q = '%${query.toLowerCase()}%';
    final rows = await db.rawQuery(
      '''
        SELECT * FROM doctors WHERE LOWER(nama) LIKE ? OR LOWER(spesialis) LIKE ? OR LOWER(poli) LIKE ? ORDER BY nama ASC
''',
      [q, q, q],
    );

    return rows.map(Doctor.fromMap).toList();
  }
}
