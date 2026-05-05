class Prescription {
  int? id;
  int patientId;
  String tanggal;
  String catatan;

  Prescription({
    this.id,
    required this.patientId,
    required this.tanggal,
    required this.catatan,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'patient_id': patientId,
    'tanggal': tanggal,
    'catatan': catatan,
  };

  factory Prescription.fromMap(Map<String, dynamic> m) => Prescription(
    id: m['id'],
    patientId: m['patient_id'],
    tanggal: m['tanggal'],
    catatan: m['catatan'],
  );
}

class PrescriptionItem {
  int? id;
  int prescriptionId;
  int medicineId;
  String medicineName;
  String satuan;
  int jumlah;
  String aturanPakai;

  PrescriptionItem({
    this.id,
    required this.prescriptionId,
    required this.medicineId,
    required this.medicineName,
    required this.satuan,
    required this.jumlah,
    required this.aturanPakai,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'prescription_id': prescriptionId,
    'medicine_id': medicineId,
    'medicine_name': medicineName,
    'satuan': satuan,
    'jumlah': jumlah,
    'aturan_pakai': aturanPakai,
  };

  factory PrescriptionItem.fromMap(Map<String, dynamic> m) => PrescriptionItem(
    id: m['id'],
    prescriptionId: m['prescription_id'],
    medicineId: m['medicine_id'],
    medicineName: m['medicine_name'],
    satuan: m['satuan'],
    jumlah: m['jumlah'],
    aturanPakai: m['aturan_pakai'],
  );
}

class PrescriptionWithItems {
  final Prescription prescription;
  final List<PrescriptionItem> items;

  const PrescriptionWithItems({
    required this.prescription,
    required this.items,
  });
}
