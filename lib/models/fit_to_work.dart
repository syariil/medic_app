class FitToWork {
  int? id;
  String tanggal;
  String site;
  String nama;
  String posisi;
  String departemen;
  String lokasi;
  String shift; // 'Pagi' | 'Siang' | 'Malam'
  double jumlahJamTidur;
  String jamMasuk; // format "HH:mm"
  bool tidurKurangDari6; // tidur ≤ 6 jam
  String kesehatan; // 'Baik' | 'Kurang Baik' | 'Sakit'
  bool minumObat;
  String pembatasanKerja; // 'Tidak Ada' | 'Ada - ...'
  String keterangan;

  FitToWork({
    this.id,
    required this.tanggal,
    required this.site,
    required this.nama,
    required this.posisi,
    required this.departemen,
    required this.lokasi,
    required this.shift,
    required this.jumlahJamTidur,
    required this.jamMasuk,
    required this.tidurKurangDari6,
    required this.kesehatan,
    required this.minumObat,
    required this.pembatasanKerja,
    required this.keterangan,
  });

  bool get isFit =>
      !tidurKurangDari6 &&
      kesehatan == 'Baik' &&
      !minumObat &&
      pembatasanKerja == 'Tidak Ada';

  Map<String, dynamic> toMap() => {
    'id': id,
    'tanggal': tanggal,
    'site': site,
    'nama': nama,
    'posisi': posisi,
    'departemen': departemen,
    'lokasi': lokasi,
    'shift': shift,
    'jumlah_jam_tidur': jumlahJamTidur,
    'jam_masuk': jamMasuk,
    'tidur_kurang_dari_6': tidurKurangDari6 ? 1 : 0,
    'kesehatan': kesehatan,
    'minum_obat': minumObat ? 1 : 0,
    'pembatasan_kerja': pembatasanKerja,
    'keterangan': keterangan,
  };

  factory FitToWork.fromMap(Map<String, dynamic> m) => FitToWork(
    id: m['id'],
    tanggal: m['tanggal'] ?? '',
    site: m['site'] ?? '',
    nama: m['nama'] ?? '',
    posisi: m['posisi'] ?? '',
    departemen: m['departemen'] ?? '',
    lokasi: m['lokasi'] ?? '',
    shift: m['shift'] ?? 'Pagi',
    jumlahJamTidur: (m['jumlah_jam_tidur'] as num?)?.toDouble() ?? 0,
    jamMasuk: m['jam_masuk'] ?? '',
    tidurKurangDari6: (m['tidur_kurang_dari_6'] as int? ?? 0) == 1,
    kesehatan: m['kesehatan'] ?? 'Baik',
    minumObat: (m['minum_obat'] as int? ?? 0) == 1,
    pembatasanKerja: m['pembatasan_kerja'] ?? 'Tidak Ada',
    keterangan: m['keterangan'] ?? '',
  );
}
