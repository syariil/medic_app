import '../models/prescription.dart';

abstract class PrescriptionRepository {
  Future<int> insertWithItems(
    Prescription prescription,
    List<PrescriptionItem> items,
  );

  Future<List<PrescriptionWithItems>> getByPatient(int patientId);

  Future<PrescriptionWithItems?> getById(int id);

  Future<void> updateWithItems(
    Prescription prescription,
    List<PrescriptionItem> items,
  );

  Future<void> deleteWithItems(int prescriptionId);

  Future<Map<String, int>> getMedicineUsageStat({
    String? startDate,
    String? endDate,
  });
}
