enum ExportTable {
  visits('Kunjungan', 'Kunjungan'),
  visitPrescriptions('Resep', 'Resep Kunjungan'),
  drugTests('Tes Narkoba', 'Tes Narkoba'),
  fitToWork('Fit To Work', 'Fit To Work'),
  fatigues('Fatigue', 'Fatigue'),
  medicines('Obat / Farmasi', 'Obat');

  final String label;
  final String sheetName;
  const ExportTable(this.label, this.sheetName);
}

enum ExportMode {
  singleFile('Satu File — semua sheet'),
  separateFiles('File Terpisah per Tabel');

  final String label;
  const ExportMode(this.label);
}

enum ExportFormat {
  excel('Excel (.xlsx)'),
  csv('CSV (.csv)'),
  both('Excel + CSV (keduanya)');

  final String label;
  const ExportFormat(this.label);
}

class ExportConfig {
  final Set<ExportTable> tables;
  final ExportMode mode;
  final ExportFormat format;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? filterSite;
  final String? filterDept;

  const ExportConfig({
    required this.tables,
    required this.mode,
    required this.format,
    this.startDate,
    this.endDate,
    this.filterSite,
    this.filterDept,
  });

  bool get hasDateFilter => startDate != null && endDate != null;
  bool get hasSiteFilter => filterSite != null && filterSite!.trim().isNotEmpty;
  bool get hasDeptFilter => filterDept != null && filterDept!.trim().isNotEmpty;
  bool get includesExcel =>
      format == ExportFormat.excel || format == ExportFormat.both;
  bool get includesCsv =>
      format == ExportFormat.csv || format == ExportFormat.both;

  ExportConfig copyWith({
    Set<ExportTable>? tables,
    ExportMode? mode,
    ExportFormat? format,
    DateTime? startDate,
    DateTime? endDate,
    String? filterSite,
    String? filterDept,
    bool clearDates = false,
  }) => ExportConfig(
    tables: tables ?? this.tables,
    mode: mode ?? this.mode,
    format: format ?? this.format,
    startDate: clearDates ? null : (startDate ?? this.startDate),
    endDate: clearDates ? null : (endDate ?? this.endDate),
    filterSite: filterSite ?? this.filterSite,
    filterDept: filterDept ?? this.filterDept,
  );
}

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
  int get successCount => files.where((f) => f.success).length;
}

class ExportFileResult {
  final String fileName;
  final ExportFormat format;
  final String? path;
  final String? error;
  final Map<String, int> rowCounts;
  const ExportFileResult({
    required this.fileName,
    required this.format,
    this.path,
    this.error,
    required this.rowCounts,
  });

  bool get success => path != null && error == null;
  int get totalRows => rowCounts.values.fold(0, (a, b) => a + b);
}
