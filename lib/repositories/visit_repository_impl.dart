import 'package:sqflite/sqflite.dart';
import '../models/visit.dart';
import 'db_provider.dart';
import 'visit_repository.dart';

class VisitRepositoryImpl implements VisitRepository {
  static final VisitRepositoryImpl _i = VisitRepositoryImpl._();
  factory VisitRepositoryImpl() => _i;
  VisitRepositoryImpl._();

  Future<Database> get _db => DbProvider.instance.database;

  @override
  Future<int> insert(Visit v, {Transaction? txn}) async {
    final db = txn ?? await _db;
    final map = v.toMap()..remove('id');
    return db.insert('visits', map);
  }

  @override
  Future<List<Visit>> getAll() async {
    final db = await _db;
    final rows = await db.query('visits', orderBy: 'tanggal DESC, id DESC');
    return rows.map(Visit.fromMap).toList();
  }

  @override
  Future<Visit?> getById(int id) async {
    final db = await _db;
    final rows = await db.query(
      'visits',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : Visit.fromMap(rows.first);
  }

  @override
  Future<int> update(Visit v, {Transaction? txn}) async {
    final db = txn ?? await _db;
    return db.update('visits', v.toMap(), where: 'id = ?', whereArgs: [v.id]);
  }

  @override
  Future<int> delete(int id) async {
    final db = await _db;
    return db.delete('visits', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<List<Visit>> search(String query) async {
    final db = await _db;
    final q = '%${query.toLowerCase()}%';
    final rows = await db.rawQuery(
      '''
      SELECT * FROM visits
      WHERE LOWER(nama) LIKE ? OR LOWER(site) LIKE ?
        OR LOWER(departemen) LIKE ? OR LOWER(posisi) LIKE ?
        OR LOWER(keluhan) LIKE ? OR LOWER(diagnosa) LIKE ?
      ORDER BY tanggal DESC
    ''',
      [q, q, q, q, q, q],
    );
    return rows.map(Visit.fromMap).toList();
  }

  @override
  Future<List<Visit>> getBySite(String site) async {
    final db = await _db;
    final rows = await db.query(
      'visits',
      where: 'LOWER(site) = ?',
      whereArgs: [site.toLowerCase()],
      orderBy: 'tanggal DESC',
    );
    return rows.map(Visit.fromMap).toList();
  }

  @override
  Future<List<Visit>> getByDateRange(String startDate, String endDate) async {
    final db = await _db;
    final rows = await db.query(
      'visits',
      where: 'tanggal >= ? AND tanggal <= ?',
      whereArgs: [startDate, endDate],
      orderBy: 'tanggal DESC',
    );
    return rows.map(Visit.fromMap).toList();
  }
}
