import '../models/visit.dart';
import '../models/drug_test.dart';
import '../models/fit_to_work.dart';
import '../models/fatigue.dart';
import '../models/medicine.dart';

enum RowStatus { valid, invalid, warning }

class ParsedRow<T> {
  final int rowNumber;
  final T? data;
  final RowStatus status;
  final String? message;
  const ParsedRow({
    required this.rowNumber,
    this.data,
    required this.status,
    this.message,
  });
  bool get isValid => status != RowStatus.invalid;
}

class SheetError {
  final String sheet;
  final int row;
  final String message;
  const SheetError(this.sheet, this.row, this.message);
}

class ImportResult {
  final List<ParsedRow<Visit>> visits;
  final List<ParsedRow<DrugTest>> drugTests;
  final List<ParsedRow<FitToWork>> fitToWorks;
  final List<ParsedRow<Fatigue>> fatigues;
  final List<ParsedRow<Medicine>> medicines;
  final List<SheetError> globalErrors;

  const ImportResult({
    required this.visits,
    required this.drugTests,
    required this.fitToWorks,
    required this.fatigues,
    required this.medicines,
    required this.globalErrors,
  });

  bool get isEmpty =>
      visits.isEmpty &&
      drugTests.isEmpty &&
      fitToWorks.isEmpty &&
      fatigues.isEmpty &&
      medicines.isEmpty;

  int get totalValid =>
      visits.where((r) => r.isValid).length +
      drugTests.where((r) => r.isValid).length +
      fitToWorks.where((r) => r.isValid).length +
      fatigues.where((r) => r.isValid).length +
      medicines.where((r) => r.isValid).length;

  int get totalInvalid =>
      visits.where((r) => !r.isValid).length +
      drugTests.where((r) => !r.isValid).length +
      fitToWorks.where((r) => !r.isValid).length +
      fatigues.where((r) => !r.isValid).length +
      medicines.where((r) => !r.isValid).length;
}

class ImportSummary {
  final int visitsInserted;
  final int drugTestsInserted;
  final int fitToWorksInserted;
  final int fatiguesInserted;
  final int medicinesInserted;
  final int skipped;
  final List<String> errors;
  const ImportSummary({
    required this.visitsInserted,
    required this.drugTestsInserted,
    required this.fitToWorksInserted,
    required this.fatiguesInserted,
    required this.medicinesInserted,
    required this.skipped,
    required this.errors,
  });
  int get total =>
      visitsInserted +
      drugTestsInserted +
      fitToWorksInserted +
      fatiguesInserted +
      medicinesInserted;
}
