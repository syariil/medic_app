import 'package:sqflite/sqflite.dart';
import '../models/drug_test.dart';
import 'db_provider.dart';
import 'drug_test_repository.dart';

class DrugTestRepositoryImpl implements DrugTestRepository {
  static final DrugTestRepositoryImpl _i = DrugTestRepositoryImpl._();
  factory DrugTestRepositoryImpl() => _i;
  DrugTestRepositoryImpl._();

  Future<Database> get _db => DbProvider.instance.database;

  @override
  Future<int> insert(DrugTest d) async {
    final db = await _db;
    final map = d.toMap()..remove('id');
    return db.insert('drug_tests', map);
  }

  @override
  Future<List<DrugTest>> getAll() async {
    final db = await _db;
    final rows = await db.query('drug_tests', orderBy: 'tanggal DESC, id DESC');
    return rows.map(DrugTest.fromMap).toList();
  }

  @override
  Future<DrugTest?> getById(int id) async {
    final db = await _db;
    final rows = await db.query(
      'drug_tests',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : DrugTest.fromMap(rows.first);
  }

  @override
  Future<int> update(DrugTest d) async {
    final db = await _db;
    return db.update(
      'drug_tests',
      d.toMap(),
      where: 'id = ?',
      whereArgs: [d.id],
    );
  }

  @override
  Future<int> delete(int id) async {
    final db = await _db;
    return db.delete('drug_tests', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<List<DrugTest>> search(String query) async {
    final db = await _db;
    final q = '%${query.toLowerCase()}%';
    final rows = await db.rawQuery(
      '''
      SELECT * FROM drug_tests
      WHERE LOWER(nama) LIKE ? OR LOWER(site) LIKE ?
        OR LOWER(departemen) LIKE ? OR LOWER(hasil) LIKE ?
      ORDER BY tanggal DESC
    ''',
      [q, q, q, q],
    );
    return rows.map(DrugTest.fromMap).toList();
  }

  @override
  Future<List<DrugTest>> getByHasil(String hasil) async {
    final db = await _db;
    final rows = await db.query(
      'drug_tests',
      where: 'hasil = ?',
      whereArgs: [hasil],
      orderBy: 'tanggal DESC',
    );
    return rows.map(DrugTest.fromMap).toList();
  }

  @override
  Future<List<DrugTest>> getByDateRange(String s, String e) async {
    final db = await _db;
    final rows = await db.query(
      'drug_tests',
      where: 'tanggal >= ? AND tanggal <= ?',
      whereArgs: [s, e],
      orderBy: 'tanggal DESC',
    );
    return rows.map(DrugTest.fromMap).toList();
  }
}
