class Visit {
  int? id;
  String tanggal;
  String site;
  String nama;
  String posisi;
  String departemen;
  String keluhan; // ← baru
  String diagnosa; // ← baru
  double jumlahJamTidur;
  double suhuBadan;
  String tekananDarah;
  int pernapasan;
  int nadi;
  String keterangan;

  Visit({
    this.id,
    required this.tanggal,
    required this.site,
    required this.nama,
    required this.posisi,
    required this.departemen,
    required this.keluhan,
    required this.diagnosa,
    required this.jumlahJamTidur,
    required this.suhuBadan,
    required this.tekananDarah,
    required this.pernapasan,
    required this.nadi,
    required this.keterangan,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'tanggal': tanggal,
    'site': site,
    'nama': nama,
    'posisi': posisi,
    'departemen': departemen,
    'keluhan': keluhan,
    'diagnosa': diagnosa,
    'jumlah_jam_tidur': jumlahJamTidur,
    'suhu_badan': suhuBadan,
    'tekanan_darah': tekananDarah,
    'pernapasan': pernapasan,
    'nadi': nadi,
    'keterangan': keterangan,
  };

  factory Visit.fromMap(Map<String, dynamic> m) => Visit(
    id: m['id'],
    tanggal: m['tanggal'] ?? '',
    site: m['site'] ?? '',
    nama: m['nama'] ?? '',
    posisi: m['posisi'] ?? '',
    departemen: m['departemen'] ?? '',
    keluhan: m['keluhan'] ?? '',
    diagnosa: m['diagnosa'] ?? '',
    jumlahJamTidur: (m['jumlah_jam_tidur'] as num?)?.toDouble() ?? 0,
    suhuBadan: (m['suhu_badan'] as num?)?.toDouble() ?? 0,
    tekananDarah: m['tekanan_darah'] ?? '',
    pernapasan: m['pernapasan'] as int? ?? 0,
    nadi: m['nadi'] as int? ?? 0,
    keterangan: m['keterangan'] ?? '',
  );
}
