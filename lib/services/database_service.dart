import '../models/patient.dart';
import '../models/doctor.dart';
import '../models/medicine.dart';
import '../models/prescription.dart';
import '../repositories/patient_repository_impl.dart';
import '../repositories/doctor_repository_impl.dart';
import '../repositories/medicine_repository_impl.dart';
import '../repositories/prescription_repository_impl.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  final _patientRepo = PatientRepositoryImpl();
  final _doctorRepo = DoctorRepositoryImpl();
  final _medicineRepo = MedicineRepositoryImpl();
  final _prescriptionRepo = PrescriptionRepositoryImpl();

  // patient
  Future<int> insertPatient(Patient patient) => _patientRepo.insert(patient);
  Future<List<Patient>> getPatients() => _patientRepo.getAll();
  Future<Patient?> getPatientById(int id) => _patientRepo.getById(id);
  Future<int> updatePatient(Patient patient) => _patientRepo.update(patient);
  Future<int> deletePatient(int id) => _patientRepo.delete(id);
  Future<List<Patient>> searchPatients(String query) =>
      _patientRepo.search(query);

  // doctor
  Future<int> insertDoctor(Doctor doctor) => _doctorRepo.insert(doctor);
  Future<List<Doctor>> getDoctors() => _doctorRepo.getAll();
  Future<Doctor?> getDoctorById(int id) => _doctorRepo.getById(id);
  Future<int> updateDoctor(Doctor doctor) => _doctorRepo.update(doctor);
  Future<int> deleteDoctor(int id) => _doctorRepo.delete(id);
  Future<List<Doctor>> searchDoctors(String q) => _doctorRepo.search(q);

  // medicine
  Future<int> insertMedicine(Medicine medicine) =>
      _medicineRepo.insert(medicine);
  Future<List<Medicine>> getMedicines() => _medicineRepo.getAll();
  Future<Medicine?> getMedicineById(int id) => _medicineRepo.getById(id);
  Future<int> updateMedicine(Medicine medicine) =>
      _medicineRepo.update(medicine);
  Future<int> deleteMedicine(int id) => _medicineRepo.delete(id);
  Future<List<Medicine>> searchMedicines(String q) => _medicineRepo.search(q);
  Future<List<Medicine>> getMedicinesStokRendah({int t = 10}) =>
      _medicineRepo.getByStokRendah(threshold: t);
  Future<int> updateStockMedicine(int id, int stok) =>
      _medicineRepo.updateStock(id, stok);

  // ── Prescriptions ─────────────────────────────────────────────────────────
  Future<int> insertPrescription(
    Prescription p,
    List<PrescriptionItem> items,
  ) => _prescriptionRepo.insertWithItems(p, items);

  Future<List<PrescriptionWithItems>> getPrescriptionsByPatient(
    int patientId,
  ) => _prescriptionRepo.getByPatient(patientId);

  Future<PrescriptionWithItems?> getPrescriptionById(int id) =>
      _prescriptionRepo.getById(id);

  Future<void> updatePrescription(
    Prescription p,
    List<PrescriptionItem> items,
  ) => _prescriptionRepo.updateWithItems(p, items);

  Future<void> deletePrescription(int id) =>
      _prescriptionRepo.deleteWithItems(id);

  Future<Map<String, int>> getMedicineUsageStat({
    String? startDate,
    String? endDate,
  }) => _prescriptionRepo.getMedicineUsageStat(
    startDate: startDate,
    endDate: endDate,
  );
}
