class Fatigue {
  int? id;
  String tanggal;
  String site;
  String nama;
  String posisi;
  String departemen;
  String shift;
  double jumlahJamTidur;
  String tekananDarah;
  int nadi;
  int pernapasan;
  double suhuBadan;
  String obatDikonsumsi;
  String efekObat;
  String kriteria; // 'Fit' | 'Fatigue Ringan' | 'Fatigue Berat' | 'Unfit'
  String pembatasanKerja;
  String keterangan;

  Fatigue({
    this.id,
    required this.tanggal,
    required this.site,
    required this.nama,
    required this.posisi,
    required this.departemen,
    required this.shift,
    required this.jumlahJamTidur,
    required this.tekananDarah,
    required this.nadi,
    required this.pernapasan,
    required this.suhuBadan,
    required this.obatDikonsumsi,
    required this.efekObat,
    required this.kriteria,
    required this.pembatasanKerja,
    required this.keterangan,
  });

  bool get isFit => kriteria == 'Fit';
  bool get isUnfit => kriteria == 'Unfit' || kriteria == 'Fatigue Berat';

  Map<String, dynamic> toMap() => {
    'id': id,
    'tanggal': tanggal,
    'site': site,
    'nama': nama,
    'posisi': posisi,
    'departemen': departemen,
    'shift': shift,
    'jumlah_jam_tidur': jumlahJamTidur,
    'tekanan_darah': tekananDarah,
    'nadi': nadi,
    'pernapasan': pernapasan,
    'suhu_badan': suhuBadan,
    'obat_dikonsumsi': obatDikonsumsi,
    'efek_obat': efekObat,
    'kriteria': kriteria,
    'pembatasan_kerja': pembatasanKerja,
    'keterangan': keterangan,
  };

  factory Fatigue.fromMap(Map<String, dynamic> m) => Fatigue(
    id: m['id'],
    tanggal: m['tanggal'] ?? '',
    site: m['site'] ?? '',
    nama: m['nama'] ?? '',
    posisi: m['posisi'] ?? '',
    departemen: m['departemen'] ?? '',
    shift: m['shift'] ?? 'Pagi',
    jumlahJamTidur: (m['jumlah_jam_tidur'] as num?)?.toDouble() ?? 0,
    tekananDarah: m['tekanan_darah'] ?? '',
    nadi: m['nadi'] as int? ?? 0,
    pernapasan: m['pernapasan'] as int? ?? 0,
    suhuBadan: (m['suhu_badan'] as num?)?.toDouble() ?? 0,
    obatDikonsumsi: m['obat_dikonsumsi'] ?? '',
    efekObat: m['efek_obat'] ?? '',
    kriteria: m['kriteria'] ?? 'Fit',
    pembatasanKerja: m['pembatasan_kerja'] ?? 'Tidak Ada',
    keterangan: m['keterangan'] ?? '',
  );
}
