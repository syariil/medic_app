import 'package:sqflite/sqflite.dart';
import '../models/fit_to_work.dart';
import 'db_provider.dart';
import 'fit_to_work_repository.dart';

class FitToWorkRepositoryImpl implements FitToWorkRepository {
  static final FitToWorkRepositoryImpl _i = FitToWorkRepositoryImpl._();
  factory FitToWorkRepositoryImpl() => _i;
  FitToWorkRepositoryImpl._();

  Future<Database> get _db => DbProvider.instance.database;

  @override
  Future<int> insert(FitToWork f) async {
    final db = await _db;
    final map = f.toMap()..remove('id');
    return db.insert('fit_to_work', map);
  }

  @override
  Future<List<FitToWork>> getAll() async {
    final db = await _db;
    final rows = await db.query(
      'fit_to_work',
      orderBy: 'tanggal DESC, id DESC',
    );
    return rows.map(FitToWork.fromMap).toList();
  }

  @override
  Future<FitToWork?> getById(int id) async {
    final db = await _db;
    final rows = await db.query(
      'fit_to_work',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : FitToWork.fromMap(rows.first);
  }

  @override
  Future<int> update(FitToWork f) async {
    final db = await _db;
    return db.update(
      'fit_to_work',
      f.toMap(),
      where: 'id = ?',
      whereArgs: [f.id],
    );
  }

  @override
  Future<int> delete(int id) async {
    final db = await _db;
    return db.delete('fit_to_work', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<List<FitToWork>> search(String query) async {
    final db = await _db;
    final q = '%${query.toLowerCase()}%';
    final rows = await db.rawQuery(
      '''
      SELECT * FROM fit_to_work
      WHERE LOWER(nama) LIKE ? OR LOWER(site) LIKE ?
        OR LOWER(departemen) LIKE ? OR LOWER(shift) LIKE ?
        OR LOWER(lokasi) LIKE ?
      ORDER BY tanggal DESC
    ''',
      [q, q, q, q, q],
    );
    return rows.map(FitToWork.fromMap).toList();
  }

  @override
  Future<List<FitToWork>> getByShift(String shift) async {
    final db = await _db;
    final rows = await db.query(
      'fit_to_work',
      where: 'shift = ?',
      whereArgs: [shift],
      orderBy: 'tanggal DESC',
    );
    return rows.map(FitToWork.fromMap).toList();
  }

  @override
  Future<List<FitToWork>> getByDateRange(String s, String e) async {
    final db = await _db;
    final rows = await db.query(
      'fit_to_work',
      where: 'tanggal >= ? AND tanggal <= ?',
      whereArgs: [s, e],
      orderBy: 'tanggal DESC',
    );
    return rows.map(FitToWork.fromMap).toList();
  }
}
