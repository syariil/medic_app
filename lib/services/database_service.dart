// import 'package:sqflite/sqflite.dart';

import '../models/medicine.dart';
import '../models/visit.dart';
import '../models/visit_prescription.dart';
import '../models/drug_test.dart';
import '../models/fit_to_work.dart';
import '../models/fatigue.dart';
import '../repositories/medicine_repository_impl.dart';
import '../repositories/visit_repository_impl.dart';
import '../repositories/visit_prescription_repository_impl.dart';
import '../repositories/drug_test_repository_impl.dart';
import '../repositories/fit_to_work_repository_impl.dart';
import '../repositories/fatigue_repository_impl.dart';
// import '../repositories/db_provider.dart';

class DatabaseService {
  static final DatabaseService _i = DatabaseService._();
  factory DatabaseService() => _i;
  DatabaseService._();

  final _medRepo = MedicineRepositoryImpl();
  final _visitRepo = VisitRepositoryImpl();
  final _rxRepo = VisitPrescriptionRepositoryImpl();
  final _drugRepo = DrugTestRepositoryImpl();
  final _ftwRepo = FitToWorkRepositoryImpl();
  final _fatRepo = FatigueRepositoryImpl();

  // ── transaction helper ────────────────────────────────────────────────────

  // ── Medicines ─────────────────────────────────────────────────────────────
  Future<int> insertMedicine(Medicine m) => _medRepo.insert(m);
  Future<List<Medicine>> getMedicines() => _medRepo.getAll();
  Future<Medicine?> getMedicineById(int id) => _medRepo.getById(id);
  Future<int> updateMedicine(Medicine m) => _medRepo.update(m);
  Future<int> deleteMedicine(int id) => _medRepo.delete(id);
  Future<List<Medicine>> searchMedicines(String q) => _medRepo.search(q);
  Future<List<Medicine>> getMedicinesStokRendah({int t = 10}) =>
      _medRepo.getByStokRendah(threshold: t);
  Future<int> updateStokMedicine(int id, int s) => _medRepo.updateStock(id, s);

  // ── Visits ────────────────────────────────────────────────────────────────
  Future<int> insertVisit(Visit v) => _visitRepo.insert(v);
  Future<List<Visit>> getVisits() => _visitRepo.getAll();
  Future<Visit?> getVisitById(int id) => _visitRepo.getById(id);
  Future<int> updateVisit(Visit v) => _visitRepo.update(v);
  Future<int> deleteVisit(int id) => _visitRepo.delete(id);
  Future<List<Visit>> searchVisits(String q) => _visitRepo.search(q);
  Future<List<Visit>> getVisitsByDateRange(String s, String e) =>
      _visitRepo.getByDateRange(s, e);

  // ── Visit Prescriptions ───────────────────────────────────────────────────
  Future<int> insertVisitPrescription(
    VisitPrescription p,
    List<VisitPrescriptionItem> items,
  ) => _rxRepo.insertWithItems(p, items);
  
  Future<List<VisitPrescriptionWithItems>> getVisitPrescriptions(int vid) =>
      _rxRepo.getByVisit(vid);
  
  /// Batch query untuk multiple visit IDs - efficient N+1 solution
  Future<Map<int, List<VisitPrescriptionWithItems>>> getVisitPrescriptionsByIds(
    List<int> visitIds,
  ) => _rxRepo.getByVisitIds(visitIds);
  
  Future<void> updateVisitPrescription(
    VisitPrescription p,
    List<VisitPrescriptionItem> items,
  ) => _rxRepo.updateWithItems(p, items);
  
  Future<void> deleteVisitPrescriptions(int vid) => _rxRepo.deleteByVisit(vid);
  
  Future<Map<String, int>> getVisitMedicineUsageStat({
    String? startDate,
    String? endDate,
  }) => _rxRepo.getMedicineUsageStat(startDate: startDate, endDate: endDate);

  // ── Drug Tests ────────────────────────────────────────────────────────────
  Future<int> insertDrugTest(DrugTest d) => _drugRepo.insert(d);
  Future<List<DrugTest>> getDrugTests() => _drugRepo.getAll();
  Future<DrugTest?> getDrugTestById(int id) => _drugRepo.getById(id);
  Future<int> updateDrugTest(DrugTest d) => _drugRepo.update(d);
  Future<int> deleteDrugTest(int id) => _drugRepo.delete(id);
  Future<List<DrugTest>> searchDrugTests(String q) => _drugRepo.search(q);
  Future<List<DrugTest>> getDrugTestsByDateRange(String s, String e) =>
      _drugRepo.getByDateRange(s, e);

  // ── Fit To Work ───────────────────────────────────────────────────────────
  Future<int> insertFitToWork(FitToWork f) => _ftwRepo.insert(f);
  Future<List<FitToWork>> getFitToWorks() => _ftwRepo.getAll();
  Future<FitToWork?> getFitToWorkById(int id) => _ftwRepo.getById(id);
  Future<int> updateFitToWork(FitToWork f) => _ftwRepo.update(f);
  Future<int> deleteFitToWork(int id) => _ftwRepo.delete(id);
  Future<List<FitToWork>> searchFitToWorks(String q) => _ftwRepo.search(q);
  Future<List<FitToWork>> getFitToWorksByDateRange(String s, String e) =>
      _ftwRepo.getByDateRange(s, e);

  // ── Fatigues ──────────────────────────────────────────────────────────────
  Future<int> insertFatigue(Fatigue f) => _fatRepo.insert(f);
  Future<List<Fatigue>> getFatigues() => _fatRepo.getAll();
  Future<Fatigue?> getFatigueById(int id) => _fatRepo.getById(id);
  Future<int> updateFatigue(Fatigue f) => _fatRepo.update(f);
  Future<int> deleteFatigue(int id) => _fatRepo.delete(id);
  Future<List<Fatigue>> searchFatigues(String q) => _fatRepo.search(q);
  Future<List<Fatigue>> getFatiguesByDateRange(String s, String e) =>
      _fatRepo.getByDateRange(s, e);
}
