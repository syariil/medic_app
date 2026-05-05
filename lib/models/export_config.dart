/// Tabel yang bisa diekspor
enum ExportTable {
  patients('Pasien', 'patients'),
  doctors('Dokter', 'doctors'),
  medicines('Obat / Farmasi', 'medicines'),
  prescriptions('Resep', 'prescriptions');

  final String label;
  final String sheetName;
  const ExportTable(this.label, this.sheetName);
}

/// Mode output file
enum ExportMode {
  singleFile('Satu File (semua sheet)'),
  separateFiles('File Terpisah per Tabel');

  final String label;
  const ExportMode(this.label);
}

/// Konfigurasi yang dipilih user sebelum export
class ExportConfig {
  final Set<ExportTable> tables;
  final ExportMode mode;
  final DateTime? startDate;
  final DateTime? endDate;

  const ExportConfig({
    required this.tables,
    required this.mode,
    this.startDate,
    this.endDate,
  });

  bool get hasDateFilter => startDate != null && endDate != null;

  ExportConfig copyWith({
    Set<ExportTable>? tables,
    ExportMode? mode,
    DateTime? startDate,
    DateTime? endDate,
    bool clearDates = false,
  }) {
    return ExportConfig(
      tables: tables ?? this.tables,
      mode: mode ?? this.mode,
      startDate: clearDates ? null : (startDate ?? this.startDate),
      endDate: clearDates ? null : (endDate ?? this.endDate),
    );
  }
}

/// Ringkasan hasil export
class ExportSummary {
  final List<ExportFileResult> files;
  final int totalRows;
  final Duration duration;

  const ExportSummary({
    required this.files,
    required this.totalRows,
    required this.duration,
  });

  bool get hasError => files.any((f) => f.error != null);
}

/// Hasil satu file yang diekspor
class ExportFileResult {
  final String fileName;
  final String? path; // null jika gagal
  final String? error;
  final Map<String, int> rowCounts; // sheet → jumlah baris

  const ExportFileResult({
    required this.fileName,
    this.path,
    this.error,
    required this.rowCounts,
  });

  bool get success => path != null && error == null;
  int get totalRows => rowCounts.values.fold(0, (a, b) => a + b);
}
