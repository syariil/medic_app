/// Nilai hasil tiap parameter: 'Negatif', 'Positif', '-' (tidak dites)
class DrugTest {
  int? id;
  String tanggal;
  String site;
  String nama;
  String posisi;
  String departemen;
  String amp; // Amphetamine
  String met; // Methamphetamine
  String thc; // THC/Cannabis
  String coc; // Cocaine
  String bzo; // Benzodiazepine
  String hasil; // 'Negatif' | 'Positif'
  String keterangan;

  DrugTest({
    this.id,
    required this.tanggal,
    required this.site,
    required this.nama,
    required this.posisi,
    required this.departemen,
    required this.amp,
    required this.met,
    required this.thc,
    required this.coc,
    required this.bzo,
    required this.hasil,
    required this.keterangan,
  });

  /// true jika ada parameter positif
  bool get isPositif => hasil == 'Positif';

  Map<String, dynamic> toMap() => {
    'id': id,
    'tanggal': tanggal,
    'site': site,
    'nama': nama,
    'posisi': posisi,
    'departemen': departemen,
    'amp': amp,
    'met': met,
    'thc': thc,
    'coc': coc,
    'bzo': bzo,
    'hasil': hasil,
    'keterangan': keterangan,
  };

  factory DrugTest.fromMap(Map<String, dynamic> m) => DrugTest(
    id: m['id'],
    tanggal: m['tanggal'] ?? '',
    site: m['site'] ?? '',
    nama: m['nama'] ?? '',
    posisi: m['posisi'] ?? '',
    departemen: m['departemen'] ?? '',
    amp: m['amp'] ?? 'Negatif',
    met: m['met'] ?? 'Negatif',
    thc: m['thc'] ?? 'Negatif',
    coc: m['coc'] ?? 'Negatif',
    bzo: m['bzo'] ?? 'Negatif',
    hasil: m['hasil'] ?? 'Negatif',
    keterangan: m['keterangan'] ?? '',
  );
}
