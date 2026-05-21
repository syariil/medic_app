import '../models/fatigue.dart';
import 'base_repository.dart';

abstract class FatigueRepository extends BaseRepository<Fatigue, int> {
  Future<List<Fatigue>> search(String query);
  Future<List<Fatigue>> getByKriteria(String kriteria);
  Future<List<Fatigue>> getByDateRange(String startDate, String endDate);
}
