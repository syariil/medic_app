import 'package:sqflite/sqflite.dart';
import '../models/prescription.dart';
import 'db_provider.dart';
import 'prescription_repository.dart';

class PrescriptionRepositoryImpl implements PrescriptionRepository {
  static final PrescriptionRepositoryImpl _i = PrescriptionRepositoryImpl._();
  factory PrescriptionRepositoryImpl() => _i;
  PrescriptionRepositoryImpl._();

  Future<Database> get _db => DbProvider.instance.database;

  // ── Insert ────────────────────────────────────────────────────────────────

  @override
  Future<int> insertWithItems(
    Prescription prescription,
    List<PrescriptionItem> items,
  ) async {
    final db = await _db;

    return db.transaction((txn) async {
      // 1. Insert resep
      final map = prescription.toMap()..remove('id');
      final prescriptionId = await txn.insert('prescriptions', map);

      // 2. Insert setiap item + kurangi stok
      for (final item in items) {
        final itemMap = item.copyWith(prescriptionId: prescriptionId).toMap()
          ..remove('id');
        await txn.insert('prescription_items', itemMap);

        // Kurangi stok — tidak boleh minus
        await txn.rawUpdate(
          '''
          UPDATE medicines
          SET stok = MAX(0, stok - ?)
          WHERE id = ?
        ''',
          [item.jumlah, item.medicineId],
        );
      }

      return prescriptionId;
    });
  }

  // ── Read ──────────────────────────────────────────────────────────────────

  @override
  Future<List<PrescriptionWithItems>> getByPatient(int patientId) async {
    final db = await _db;
    final rows = await db.query(
      'prescriptions',
      where: 'patient_id = ?',
      whereArgs: [patientId],
      orderBy: 'tanggal DESC',
    );

    final result = <PrescriptionWithItems>[];
    for (final row in rows) {
      final p = Prescription.fromMap(row);
      final items = await _getItems(db, p.id!);
      result.add(PrescriptionWithItems(prescription: p, items: items));
    }
    return result;
  }

  @override
  Future<PrescriptionWithItems?> getById(int id) async {
    final db = await _db;
    final rows = await db.query(
      'prescriptions',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;

    final p = Prescription.fromMap(rows.first);
    final items = await _getItems(db, id);
    return PrescriptionWithItems(prescription: p, items: items);
  }

  Future<List<PrescriptionItem>> _getItems(
    DatabaseExecutor db,
    int prescriptionId,
  ) async {
    final rows = await db.query(
      'prescription_items',
      where: 'prescription_id = ?',
      whereArgs: [prescriptionId],
    );
    return rows.map(PrescriptionItem.fromMap).toList();
  }

  // ── Update ────────────────────────────────────────────────────────────────

  @override
  Future<void> updateWithItems(
    Prescription prescription,
    List<PrescriptionItem> items,
  ) async {
    final db = await _db;

    await db.transaction((txn) async {
      // 1. Rollback stok dari item lama
      final oldItems = await _getItems(txn, prescription.id!);
      for (final old in oldItems) {
        await txn.rawUpdate(
          'UPDATE medicines SET stok = stok + ? WHERE id = ?',
          [old.jumlah, old.medicineId],
        );
      }

      // 2. Hapus item lama
      await txn.delete(
        'prescription_items',
        where: 'prescription_id = ?',
        whereArgs: [prescription.id],
      );

      // 3. Update header resep
      await txn.update(
        'prescriptions',
        prescription.toMap(),
        where: 'id = ?',
        whereArgs: [prescription.id],
      );

      // 4. Insert item baru + kurangi stok
      for (final item in items) {
        final itemMap = item.copyWith(prescriptionId: prescription.id).toMap()
          ..remove('id');
        await txn.insert('prescription_items', itemMap);

        await txn.rawUpdate(
          '''
          UPDATE medicines SET stok = MAX(0, stok - ?) WHERE id = ?
        ''',
          [item.jumlah, item.medicineId],
        );
      }
    });
  }

  // ── Delete ────────────────────────────────────────────────────────────────

  @override
  Future<void> deleteWithItems(int prescriptionId) async {
    final db = await _db;

    await db.transaction((txn) async {
      // 1. Kembalikan stok
      final items = await _getItems(txn, prescriptionId);
      for (final item in items) {
        await txn.rawUpdate(
          'UPDATE medicines SET stok = stok + ? WHERE id = ?',
          [item.jumlah, item.medicineId],
        );
      }

      // 2. Hapus item lalu header
      await txn.delete(
        'prescription_items',
        where: 'prescription_id = ?',
        whereArgs: [prescriptionId],
      );
      await txn.delete(
        'prescriptions',
        where: 'id = ?',
        whereArgs: [prescriptionId],
      );
    });
  }

  // ── Stats ─────────────────────────────────────────────────────────────────

  @override
  Future<Map<String, int>> getMedicineUsageStat({
    String? startDate,
    String? endDate,
  }) async {
    final db = await _db;

    String where = '';
    final args = <dynamic>[];

    if (startDate != null && endDate != null) {
      where = '''
        WHERE p.tanggal >= ? AND p.tanggal <= ?
      ''';
      args.addAll([startDate, endDate]);
    }

    final rows = await db.rawQuery('''
      SELECT pi.medicine_name, SUM(pi.jumlah) as total
      FROM prescription_items pi
      JOIN prescriptions p ON pi.prescription_id = p.id
      $where
      GROUP BY pi.medicine_name
      ORDER BY total DESC limit 10
    ''', args);

    return {
      for (final r in rows)
        r['medicine_name'] as String: (r['total'] as num).toInt(),
    };
  }
}

// Extension helper agar copyWith bisa dipakai di PrescriptionItem
extension _PrescriptionItemX on PrescriptionItem {
  PrescriptionItem copyWith({
    int? id,
    int? prescriptionId,
    int? medicineId,
    String? medicineName,
    String? satuan,
    int? jumlah,
    String? aturanPakai,
  }) => PrescriptionItem(
    id: id ?? this.id,
    prescriptionId: prescriptionId ?? this.prescriptionId,
    medicineId: medicineId ?? this.medicineId,
    medicineName: medicineName ?? this.medicineName,
    satuan: satuan ?? this.satuan,
    jumlah: jumlah ?? this.jumlah,
    aturanPakai: aturanPakai ?? this.aturanPakai,
  );
}
