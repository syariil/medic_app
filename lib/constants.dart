/// Global constants untuk seluruh aplikasi
class AppConstants {
  static const int minNameLength = 1;
  static const int maxNameLength = 100;
  static const int maxDescriptionLength = 500;
  static const int minAge = 0;
  static const int maxAge = 150;
  static const int stockWarningThreshold = 10;
  static const int minStockValue = 0;
  static const int maxStockValue = 99999;
  static const int minYear = 2000;
  static const int maxYear = 2100;
  static const int defaultPageSize = 50;
}

class DbTables {
  static const String medicines = 'medicines';
  static const String visits = 'visits';
  static const String visitPrescriptions = 'visit_prescriptions';
  static const String visitPrescriptionItems = 'visit_prescription_items';
  static const String drugTests = 'drug_tests';
  static const String fitToWorks = 'fit_to_works';
  static const String fatigues = 'fatigues';
}

class DbColumns {
  static const String id = 'id';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
  static const String medicineName = 'nama';
  static const String medicineStok = 'stok';
  static const String medicineKeterangan = 'keterangan';
  static const String visitTanggal = 'tanggal';
  static const String visitSite = 'site';
  static const String visitNama = 'nama';
  static const String visitPrescriptionId = 'visit_prescription_id';
  static const String visitId = 'visit_id';
}

class DbIndexes {
  static const String visitsTanggal =
      'CREATE INDEX IF NOT EXISTS idx_visits_tanggal ON visits(tanggal)';
  static const String visitsSite =
      'CREATE INDEX IF NOT EXISTS idx_visits_site ON visits(site)';
  static const String medicinesNama =
      'CREATE INDEX IF NOT EXISTS idx_medicines_nama ON medicines(LOWER(nama))';
  static const String visitPrescriptionsVisitId =
      'CREATE INDEX IF NOT EXISTS idx_visit_prescriptions_visit_id ON visit_prescriptions(visit_id)';
  static const String visitPrescriptionItemsVisitPrescriptionId =
      'CREATE INDEX IF NOT EXISTS idx_visit_prescription_items_visit_prescription_id ON visit_prescription_items(visit_prescription_id)';

  static List<String> getAll() => [
    visitsTanggal,
    visitsSite,
    medicinesNama,
    visitPrescriptionsVisitId,
    visitPrescriptionItemsVisitPrescriptionId,
  ];
}
