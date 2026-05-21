import 'package:sqflite/sqflite.dart';
import '../models/fatigue.dart';
import 'db_provider.dart';
import 'fatigue_repository.dart';

class FatigueRepositoryImpl implements FatigueRepository {
  static final FatigueRepositoryImpl _i = FatigueRepositoryImpl._();
  factory FatigueRepositoryImpl() => _i;
  FatigueRepositoryImpl._();

  Future<Database> get _db => DbProvider.instance.database;

  @override
  Future<int> insert(Fatigue f) async {
    final db = await _db;
    final map = f.toMap()..remove('id');
    return db.insert('fatigues', map);
  }

  @override
  Future<List<Fatigue>> getAll() async {
    final db = await _db;
    final rows = await db.query('fatigues', orderBy: 'tanggal DESC, id DESC');
    return rows.map(Fatigue.fromMap).toList();
  }

  @override
  Future<Fatigue?> getById(int id) async {
    final db = await _db;
    final rows = await db.query(
      'fatigues',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : Fatigue.fromMap(rows.first);
  }

  @override
  Future<int> update(Fatigue f) async {
    final db = await _db;
    return db.update('fatigues', f.toMap(), where: 'id = ?', whereArgs: [f.id]);
  }

  @override
  Future<int> delete(int id) async {
    final db = await _db;
    return db.delete('fatigues', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<List<Fatigue>> search(String query) async {
    final db = await _db;
    final q = '%${query.toLowerCase()}%';
    final rows = await db.rawQuery(
      '''
      SELECT * FROM fatigues
      WHERE LOWER(nama) LIKE ? OR LOWER(site) LIKE ?
        OR LOWER(departemen) LIKE ? OR LOWER(kriteria) LIKE ?
        OR LOWER(shift) LIKE ?
      ORDER BY tanggal DESC
    ''',
      [q, q, q, q, q],
    );
    return rows.map(Fatigue.fromMap).toList();
  }

  @override
  Future<List<Fatigue>> getByKriteria(String kriteria) async {
    final db = await _db;
    final rows = await db.query(
      'fatigues',
      where: 'kriteria = ?',
      whereArgs: [kriteria],
      orderBy: 'tanggal DESC',
    );
    return rows.map(Fatigue.fromMap).toList();
  }

  @override
  Future<List<Fatigue>> getByDateRange(String s, String e) async {
    final db = await _db;
    final rows = await db.query(
      'fatigues',
      where: 'tanggal >= ? AND tanggal <= ?',
      whereArgs: [s, e],
      orderBy: 'tanggal DESC',
    );
    return rows.map(Fatigue.fromMap).toList();
  }
}
