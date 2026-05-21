import '../models/drug_test.dart';
import 'base_repository.dart';

abstract class DrugTestRepository extends BaseRepository<DrugTest, int> {
  Future<List<DrugTest>> search(String query);
  Future<List<DrugTest>> getByHasil(String hasil);
  Future<List<DrugTest>> getByDateRange(String startDate, String endDate);
}
