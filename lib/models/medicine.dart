class Medicine {
  int? id;
  String nama;
  String kategori;
  String satuan;
  int stok;
  String keterangan;

  Medicine({
    this.id,
    required this.nama,
    required this.kategori,
    required this.satuan,
    required this.stok,
    required this.keterangan,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'nama': nama,
    'kategori': kategori,
    'satuan': satuan,
    'stok': stok,
    'keterangan': keterangan,
  };

  factory Medicine.fromMap(Map<String, dynamic> m) => Medicine(
    id: m['id'],
    nama: m['nama'],
    kategori: m['kategori'],
    satuan: m['satuan'],
    stok: m['stok'] ?? 0,
    keterangan: m['keterangan'] ?? '',
  );

  Medicine copyWith({
    int? id,
    String? nama,
    String? kategori,
    String? satuan,
    int? stok,
    String? keterangan,
  }) => Medicine(
    id: id ?? this.id,
    nama: nama ?? this.nama,
    kategori: kategori ?? this.kategori,
    satuan: satuan ?? this.satuan,
    stok: stok ?? this.stok,
    keterangan: keterangan ?? this.keterangan,
  );

  bool get isStokRendah => stok <= 10;
  bool get isHabis => stok == 0;
}
