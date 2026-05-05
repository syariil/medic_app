import '../models/doctor.dart';
import 'base_repository.dart';

abstract class DoctorRepository extends BaseRepository<Doctor, int> {
  Future<List<Doctor>> search(String query);
  Future<List<Doctor>> getByPoli(String poli);
  Future<List<Doctor>> getBySpesialis(String spesialis);
}
