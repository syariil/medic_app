import '../models/fit_to_work.dart';
import 'base_repository.dart';

abstract class FitToWorkRepository extends BaseRepository<FitToWork, int> {
  Future<List<FitToWork>> search(String query);
  Future<List<FitToWork>> getByShift(String shift);
  Future<List<FitToWork>> getByDateRange(String startDate, String endDate);
}
