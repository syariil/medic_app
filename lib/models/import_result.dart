import '../models/patient.dart';
import '../models/doctor.dart';
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

  bool get isValid => status == RowStatus.valid;
}

class SheetError {
  final String sheet;
  final int row;
  final String message;
  const SheetError(this.sheet, this.row, this.message);
}

class ImportResult {
  final List<ParsedRow<Patient>> patients;
  final List<ParsedRow<Doctor>> doctors;
  final List<ParsedRow<Medicine>> medicines;
  final List<SheetError> globalErrors;

  const ImportResult({
    required this.patients,
    required this.doctors,
    required this.medicines,
    required this.globalErrors,
  });

  int get totalValid =>
      patients.where((r) => r.isValid).length +
      doctors.where((r) => r.isValid).length +
      medicines.where((r) => r.isValid).length;

  int get totalInvalid =>
      patients.where((r) => !r.isValid).length +
      doctors.where((r) => !r.isValid).length +
      medicines.where((r) => !r.isValid).length;

  bool get isEmpty => patients.isEmpty && doctors.isEmpty && medicines.isEmpty;
}

class ImportSummary {
  final int patientsInserted;
  final int doctorsInserted;
  final int medicinesInserted;
  final int skipped;
  final List<String> errors;

  const ImportSummary({
    required this.patientsInserted,
    required this.doctorsInserted,
    required this.medicinesInserted,
    required this.skipped,
    required this.errors,
  });

  int get total => patientsInserted + doctorsInserted + medicinesInserted;
}
