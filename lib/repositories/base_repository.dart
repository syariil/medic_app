/// Kontrak CRUD generik yang harus diimplementasikan oleh semua repository.
/// [T]  = tipe model  (misal: Patient)
/// [ID] = tipe primary key (misal: int)
abstract class BaseRepository<T, ID> {
  Future<ID> insert(T entity);
  Future<List<T>> getAll();
  Future<T?> getById(ID id);
  Future<int> update(T entity);
  Future<int> delete(ID id);
}
