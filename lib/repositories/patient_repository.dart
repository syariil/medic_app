import '../models/patient.dart';
import 'base_repository.dart';

/// Interface repository untuk entitas [Patient].
/// Extend [BaseRepository] dan tambahkan method spesifik domain jika perlu.
abstract class PatientRepository extends BaseRepository<Patient, int> {
  /// Cari pasien berdasarkan nama atau NIK (case-insensitive).
  Future<List<Patient>> search(String query);
}
