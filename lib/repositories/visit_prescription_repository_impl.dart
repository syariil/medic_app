import 'package:sqflite/sqflite.dart';
import '../models/visit_prescription.dart';
import '../error_handler.dart';
import 'db_provider.dart';
import 'visit_prescription_repository.dart';

class VisitPrescriptionRepositoryImpl implements VisitPrescriptionRepository {
  static final VisitPrescriptionRepositoryImpl _i =
      VisitPrescriptionRepositoryImpl._();
  factory VisitPrescriptionRepositoryImpl() => _i;
  VisitPrescriptionRepositoryImpl._();

  Future<Database> get _db => DbProvider.instance.database;

  // ── Insert — stok otomatis berkurang ─────────────────────────────────────

  @override
  Future<int> insertWithItems(
    VisitPrescription prescription,
    List<VisitPrescriptionItem> items,
  ) async {
    final db = await _db;
    return db.transaction((txn) async {
      final map = prescription.toMap()..remove('id');
      final pid = await txn.insert('visit_prescriptions', map);

      for (final item in items) {
        final imap = item.copyWith(visitPrescriptionId: pid).toMap()
          ..remove('id');
        await txn.insert('visit_prescription_items', imap);
        // Kurangi stok
        await txn.rawUpdate(
          'UPDATE medicines SET stok = MAX(0, stok - ?) WHERE id = ?',
          [item.jumlah, item.medicineId],
        );
      }
      return pid;
    });
  }

  // ── Get by visit ─────────────────────────────────────────────────────────

  @override
  Future<List<VisitPrescriptionWithItems>> getByVisit(int visitId) async {
    final db = await _db;
    final rows = await db.query(
      'visit_prescriptions',
      where: 'visit_id = ?',
      whereArgs: [visitId],
    );
    final result = <VisitPrescriptionWithItems>[];
    for (final row in rows) {
      final p = VisitPrescription.fromMap(row);
      final items = await _getItems(db, p.id!);
      result.add(VisitPrescriptionWithItems(prescription: p, items: items));
    }
    return result;
  }

  /// Batch query untuk multiple visit IDs - efficient untuk menghindari N+1 problem
  @override
  Future<Map<int, List<VisitPrescriptionWithItems>>> getByVisitIds(
    List<int> visitIds,
  ) async {
    if (visitIds.isEmpty) return {};

    final db = await _db;
    final placeholders = List.filled(visitIds.length, '?').join(',');
    final rows = await db.rawQuery(
      'SELECT * FROM visit_prescriptions WHERE visit_id IN ($placeholders)',
      visitIds,
    );

    final result = <int, List<VisitPrescriptionWithItems>>{};
    for (final row in rows) {
      final p = VisitPrescription.fromMap(row);
      final items = await _getItems(db, p.id!);
      final visitId = p.visitId;
      result
          .putIfAbsent(visitId, () => [])
          .add(VisitPrescriptionWithItems(prescription: p, items: items));
    }
    return result;
  }

  Future<List<VisitPrescriptionItem>> _getItems(
    DatabaseExecutor db,
    int prescriptionId,
  ) async {
    final rows = await db.query(
      'visit_prescription_items',
      where: 'visit_prescription_id = ?',
      whereArgs: [prescriptionId],
    );
    return rows.map(VisitPrescriptionItem.fromMap).toList();
  }

  // ── Update — rollback stok lama, kurangi stok baru ───────────────────────

  @override
  Future<void> updateWithItems(
    VisitPrescription prescription,
    List<VisitPrescriptionItem> items,
  ) async {
    final db = await _db;
    await db.transaction((txn) async {
      // Rollback stok lama
      final oldItems = await _getItems(txn, prescription.id!);
      for (final old in oldItems) {
        await txn.rawUpdate(
          'UPDATE medicines SET stok = stok + ? WHERE id = ?',
          [old.jumlah, old.medicineId],
        );
      }
      // Hapus items lama
      await txn.delete(
        'visit_prescription_items',
        where: 'visit_prescription_id = ?',
        whereArgs: [prescription.id],
      );
      // Update header
      await txn.update(
        'visit_prescriptions',
        prescription.toMap(),
        where: 'id = ?',
        whereArgs: [prescription.id],
      );
      // Insert items baru + kurangi stok
      for (final item in items) {
        final imap = item.copyWith(visitPrescriptionId: prescription.id).toMap()
          ..remove('id');
        await txn.insert('visit_prescription_items', imap);
        await txn.rawUpdate(
          'UPDATE medicines SET stok = MAX(0, stok - ?) WHERE id = ?',
          [item.jumlah, item.medicineId],
        );
      }
    });
  }

  // ── Delete — kembalikan stok ──────────────────────────────────────────────

  @override
  Future<void> deleteByVisit(int visitId) async {
    final db = await _db;
    await db.transaction((txn) async {
      final rows = await txn.query(
        'visit_prescriptions',
        where: 'visit_id = ?',
        whereArgs: [visitId],
      );
      for (final row in rows) {
        final pid = row['id'] as int;
        final items = await _getItems(txn, pid);
        for (final item in items) {
          await txn.rawUpdate(
            'UPDATE medicines SET stok = stok + ? WHERE id = ?',
            [item.jumlah, item.medicineId],
          );
        }
        await txn.delete(
          'visit_prescription_items',
          where: 'visit_prescription_id = ?',
          whereArgs: [pid],
        );
        await txn.delete(
          'visit_prescriptions',
          where: 'id = ?',
          whereArgs: [pid],
        );
      }
    });
  }

  // ── Usage stat — untuk dashboard ─────────────────────────────────────────

  @override
  Future<Map<String, int>> getMedicineUsageStat({
    String? startDate,
    String? endDate,
  }) async {
    final db = await _db;
    String where = '';
    final args = <dynamic>[];
    if (startDate != null && endDate != null) {
      where = 'WHERE vp.tanggal >= ? AND vp.tanggal <= ?';
      args.addAll([startDate, endDate]);
    }
    final rows = await db.rawQuery('''
      SELECT vpi.medicine_name, SUM(vpi.jumlah) as total
      FROM visit_prescription_items vpi
      JOIN visit_prescriptions vp ON vpi.visit_prescription_id = vp.id
      $where
      GROUP BY vpi.medicine_name
      ORDER BY total DESC
    ''', args);
    return {
      for (final r in rows)
        r['medicine_name'] as String: (r['total'] as num).toInt(),
    };
  }

  // Future<int> insertWithItems(
  //   VisitPrescription prescription,
  //   List<VisitPrescriptionItem> items, {
  //   Transaction? txn,
  // }) async {
  //   final db = txn ?? await _db;
  //   return db.transaction((tx) async {
  //     // pakai tx lokal
  //     final map = prescription.toMap()..remove('id');
  //     final pid = await tx.insert('visit_prescriptions', map);

  //     for (final item in items) {
  //       final imap = item.copyWith(visitPrescriptionId: pid).toMap()
  //         ..remove('id');
  //       await tx.insert('visit_prescription_items', imap);
  //       await tx.rawUpdate(
  //         'UPDATE medicines SET stok = MAX(0, stok - ?) WHERE id = ?',
  //         [item.jumlah, item.medicineId],
  //       );
  //     }
  //     return pid;
  //   });
  // }

  // Future<void> updateWithItems(
  //   VisitPrescription prescription,
  //   List<VisitPrescriptionItem> items, {
  //   Transaction? txn,
  // }) async {
  //   final db = txn ?? await _db;
  //   await db.transaction((tx) async {
  //     // rollback stok lama
  //     final oldItems = await _getItems(tx, prescription.id!);
  //     for (final old in oldItems) {
  //       await tx.rawUpdate(
  //         'UPDATE medicines SET stok = stok + ? WHERE id = ?',
  //         [old.jumlah, old.medicineId],
  //       );
  //     }

  //     await tx.delete(
  //       'visit_prescription_items',
  //       where: 'visit_prescription_id = ?',
  //       whereArgs: [prescription.id],
  //     );

  //     await tx.update(
  //       'visit_prescriptions',
  //       prescription.toMap(),
  //       where: 'id = ?',
  //       whereArgs: [prescription.id],
  //     );

  //     for (final item in items) {
  //       final imap = item.copyWith(visitPrescriptionId: prescription.id).toMap()
  //         ..remove('id');
  //       await tx.insert('visit_prescription_items', imap);
  //       await tx.rawUpdate(
  //         'UPDATE medicines SET stok = MAX(0, stok - ?) WHERE id = ?',
  //         [item.jumlah, item.medicineId],
  //       );
  //     }
  //   });
  // }

  // Future<void> deleteByVisit(int visitId, {Transaction? txn}) async {
  //   final db = txn ?? await _db;
  //   await db.transaction((tx) async {
  //     final rows = await tx.query(
  //       'visit_prescriptions',
  //       where: 'visit_id = ?',
  //       whereArgs: [visitId],
  //     );
  //     for (final row in rows) {
  //       final pid = row['id'] as int;
  //       final items = await _getItems(tx, pid);
  //       for (final item in items) {
  //         await tx.rawUpdate(
  //           'UPDATE medicines SET stok = stok + ? WHERE id = ?',
  //           [item.jumlah, item.medicineId],
  //         );
  //       }
  //       await tx.delete(
  //         'visit_prescription_items',
  //         where: 'visit_prescription_id = ?',
  //         whereArgs: [pid],
  //       );
  //       await tx.delete(
  //         'visit_prescriptions',
  //         where: 'id = ?',
  //         whereArgs: [pid],
  //       );
  //     }
  //   });
  // }
}
