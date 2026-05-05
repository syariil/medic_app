class Doctor {
  int? id;
  String nama;
  String spesialis;
  String jadwal;
  String poli;

  Doctor({
    this.id,
    required this.nama,
    required this.spesialis,
    required this.jadwal,
    required this.poli,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama': nama,
      'spesialis': spesialis,
      'jadwal': jadwal,
      'poli': poli,
    };
  }

  factory Doctor.fromMap(Map<String, dynamic> map) {
    return Doctor(
      id: map['id'],
      nama: map['nama'],
      spesialis: map['spesialis'],
      jadwal: map['jadwal'],
      poli: map['poli'],
    );
  }

  Doctor copyWith({
    int? id,
    String? nama,
    String? spesialis,
    String? jadwal,
    String? poli,
  }) {
    return Doctor(
      id: id ?? this.id,
      nama: nama ?? this.nama,
      spesialis: spesialis ?? this.spesialis,
      jadwal: jadwal ?? this.jadwal,
      poli: poli ?? this.poli,
    );
  }
}
