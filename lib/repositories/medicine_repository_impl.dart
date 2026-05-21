import 'package:sqflite/sqflite.dart';
import '../models/medicine.dart';
import 'medicine_repository.dart';
import 'db_provider.dart';

class MedicineRepositoryImpl implements MedicineRepository {
  static final MedicineRepositoryImpl _i = MedicineRepositoryImpl._();
  factory MedicineRepositoryImpl() => _i;
  MedicineRepositoryImpl._();

  Future<Database> get _db => DbProvider.instance.database;

  @override
  Future<int> insert(Medicine entity) async {
    final db = await _db;
    final map = entity.toMap()..remove('id');
    return db.insert('medicines', map);
  }

  @override
  Future<List<Medicine>> getAll() async {
    final db = await _db;
    final rows = await db.query('medicines', orderBy: 'nama ASC');
    return rows.map(Medicine.fromMap).toList();
  }

  @override
  Future<Medicine?> getById(int id) async {
    final db = await _db;
    final rows = await db.query(
      'medicines',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : Medicine.fromMap(rows.first);
  }

  @override
  Future<int> update(Medicine entity) async {
    final db = await _db;
    return db.update(
      'medicines',
      entity.toMap(),
      where: 'id = ?',
      whereArgs: [entity.id],
    );
  }

  @override
  Future<int> delete(int id) async {
    final db = await _db;
    return db.delete('medicines', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<List<Medicine>> search(String query) async {
    final db = await _db;
    final q = '%${query.toLowerCase()}%';
    final rows = await db.rawQuery(
      '''
      SELECT * FROM medicines WHERE LOWER(nama) LIKE ? OR LOWER(kategori) LIKE ? OR LOWER(keterangan) LOKE ? ORDER BY nama ASC
''',
      [q, q, q],
    );

    return rows.map(Medicine.fromMap).toList();
  }

  @override
  Future<List<Medicine>> getByKategori(String kategori) async {
    final db = await _db;
    final rows = await db.query(
      'medicines',
      where: 'LOWER(kategori) = ?',
      whereArgs: [kategori.toLowerCase()],
    );
    return rows.map(Medicine.fromMap).toList();
  }

  @override
  Future<List<Medicine>> getByStokRendah({int threshold = 10}) async {
    final db = await _db;
    final rows = await db.query(
      'medicines',
      where: 'LOWER(stok) <= ?',
      whereArgs: [threshold],
      orderBy: 'stok ASC',
    );
    return rows.map(Medicine.fromMap).toList();
  }

  @override
  Future<int> updateStock(int id, int StockBaru) async {
    final db = await _db;
    return db.update(
      'medicines',
      {'stok': StockBaru},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
