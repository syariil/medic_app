import '../models/visit.dart';
import 'base_repository.dart';

abstract class VisitRepository extends BaseRepository<Visit, int> {
  Future<List<Visit>> search(String query);
  Future<List<Visit>> getBySite(String site);
  Future<List<Visit>> getByDateRange(String startDate, String endDate);
}
