import '../models/visit_prescription.dart';

/// Abstract repository untuk Visit Prescriptions - standardisasi interface
abstract class VisitPrescriptionRepository {
  /// Insert resep kunjungan dengan items dan kurangi stok
  Future<int> insertWithItems(
    VisitPrescription prescription,
    List<VisitPrescriptionItem> items,
  );

  /// Get resep berdasarkan visit ID
  Future<List<VisitPrescriptionWithItems>> getByVisit(int visitId);

  /// Get resep berdasarkan multiple visit IDs (untuk batch query)
  Future<Map<int, List<VisitPrescriptionWithItems>>> getByVisitIds(
    List<int> visitIds,
  );

  /// Update resep dengan items baru - rollback stok lama, kurangi stok baru
  Future<void> updateWithItems(
    VisitPrescription prescription,
    List<VisitPrescriptionItem> items,
  );

  /// Delete resep berdasarkan visit ID dan kembalikan stok
  Future<void> deleteByVisit(int visitId);

  /// Get statistik penggunaan obat
  Future<Map<String, int>> getMedicineUsageStat({
    String? startDate,
    String? endDate,
  });
}
