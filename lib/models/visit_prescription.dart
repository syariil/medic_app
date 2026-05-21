/// Resep obat yang diberikan pada satu kunjungan
class VisitPrescription {
  int? id;
  int visitId;
  String tanggal;
  String catatan;

  VisitPrescription({
    this.id,
    required this.visitId,
    required this.tanggal,
    required this.catatan,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'visit_id': visitId,
    'tanggal': tanggal,
    'catatan': catatan,
  };

  factory VisitPrescription.fromMap(Map<String, dynamic> m) =>
      VisitPrescription(
        id: m['id'],
        visitId: m['visit_id'],
        tanggal: m['tanggal'] ?? '',
        catatan: m['catatan'] ?? '',
      );
}

/// Satu baris item resep kunjungan
class VisitPrescriptionItem {
  int? id;
  int visitPrescriptionId;
  int medicineId;
  String medicineName;
  String satuan;
  int jumlah;
  String aturanPakai;

  VisitPrescriptionItem({
    this.id,
    required this.visitPrescriptionId,
    required this.medicineId,
    required this.medicineName,
    required this.satuan,
    required this.jumlah,
    required this.aturanPakai,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'visit_prescription_id': visitPrescriptionId,
    'medicine_id': medicineId,
    'medicine_name': medicineName,
    'satuan': satuan,
    'jumlah': jumlah,
    'aturan_pakai': aturanPakai,
  };

  factory VisitPrescriptionItem.fromMap(Map<String, dynamic> m) =>
      VisitPrescriptionItem(
        id: m['id'],
        visitPrescriptionId: m['visit_prescription_id'],
        medicineId: m['medicine_id'],
        medicineName: m['medicine_name'],
        satuan: m['satuan'],
        jumlah: m['jumlah'] as int? ?? 1,
        aturanPakai: m['aturan_pakai'] ?? '',
      );

  VisitPrescriptionItem copyWith({
    int? id,
    int? visitPrescriptionId,
    int? medicineId,
    String? medicineName,
    String? satuan,
    int? jumlah,
    String? aturanPakai,
  }) => VisitPrescriptionItem(
    id: id ?? this.id,
    visitPrescriptionId: visitPrescriptionId ?? this.visitPrescriptionId,
    medicineId: medicineId ?? this.medicineId,
    medicineName: medicineName ?? this.medicineName,
    satuan: satuan ?? this.satuan,
    jumlah: jumlah ?? this.jumlah,
    aturanPakai: aturanPakai ?? this.aturanPakai,
  );
}

/// Gabungan resep + items untuk display
class VisitPrescriptionWithItems {
  final VisitPrescription prescription;
  final List<VisitPrescriptionItem> items;

  const VisitPrescriptionWithItems({
    required this.prescription,
    required this.items,
  });
}
