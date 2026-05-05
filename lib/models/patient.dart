class Patient {
  int? id;
  String nama;
  String nik;
  String tanggal;
  String keluhan;
  String diagnosa;

  Patient({
    this.id,
    required this.nama,
    required this.nik,
    required this.tanggal,
    required this.keluhan,
    required this.diagnosa,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama': nama,
      'nik': nik,
      'tanggal': tanggal,
      'keluhan': keluhan,
      'diagnosa': diagnosa,
    };
  }

  factory Patient.fromMap(Map<String, dynamic> map) {
    return Patient(
      id: map['id'],
      nama: map['nama'],
      nik: map['nik'],
      tanggal: map['tanggal'],
      keluhan: map['keluhan'],
      diagnosa: map['diagnosa'],
    );
  }

  Patient copyWith({
    int? id,
    String? nama,
    String? nik,
    String? tanggal,
    String? keluhan,
    String? diagnosa,
  }) {
    return Patient(
      id: id ?? this.id,
      nama: nama ?? this.nama,
      nik: nik ?? this.nik,
      tanggal: tanggal ?? this.tanggal,
      keluhan: keluhan ?? this.keluhan,
      diagnosa: diagnosa ?? this.diagnosa,
    );
  }
}
