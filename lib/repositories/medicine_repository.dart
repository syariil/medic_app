import '../models/medicine.dart';
import 'base_repository.dart';

abstract class MedicineRepository extends BaseRepository<Medicine, int> {
  Future<List<Medicine>> search(String query);
  Future<List<Medicine>> getByKategori(String kategori);
  Future<List<Medicine>> getByStokRendah({int threshold = 10});
  // ignore: non_constant_identifier_names
  Future<int> updateStock(int id, int StockBaru);
}
