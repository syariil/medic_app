import 'package:intl/intl.dart';

/// Utility class untuk validasi input di seluruh aplikasi
class Validators {
  /// Validasi field required
  static String? required(String? value, {String fieldName = 'Field'}) {
    if (value == null || value.isEmpty || value.trim().isEmpty) {
      return '$fieldName tidak boleh kosong';
    }
    return null;
  }

  /// Validasi nama (1-100 karakter, hanya huruf, angka, spasi, dan tanda hubung)
  static String? name(String? value) {
    if (value == null || value.isEmpty) {
      return 'Nama tidak boleh kosong';
    }
    
    if (value.length < 1 || value.length > 100) {
      return 'Nama harus antara 1-100 karakter';
    }

    // Allow letters, numbers, spaces, and hyphens
    final nameRegex = RegExp(r'^[a-zA-Z0-9\s\-àáâäèéêëìíîïòóôöùúûüýþÿœæÀÁÂÄÈÉÊËÌÍÎÏÒÓÔÖÙÚÛÜÝÞŸŒÆ]+$');
    if (!nameRegex.hasMatch(value)) {
      return 'Nama hanya boleh mengandung huruf, angka, spasi, dan tanda hubung';
    }

    return null;
  }

  /// Validasi angka bulat positif
  static String? numeric(String? value, {String fieldName = 'Field'}) {
    if (value == null || value.isEmpty) {
      return '$fieldName tidak boleh kosong';
    }

    final numericRegex = RegExp(r'^[0-9]+$');
    if (!numericRegex.hasMatch(value)) {
      return '$fieldName harus berupa angka bulat positif';
    }

    return null;
  }

  /// Validasi angka desimal
  static String? numericDouble(String? value, {String fieldName = 'Field'}) {
    if (value == null || value.isEmpty) {
      return '$fieldName tidak boleh kosong';
    }

    try {
      double.parse(value);
    } catch (e) {
      return '$fieldName harus berupa angka desimal yang valid';
    }

    return null;
  }

  /// Validasi angka dalam range tertentu
  static String? numericRange(
    String? value, {
    required int min,
    required int max,
    String fieldName = 'Field',
  }) {
    final numError = numeric(value, fieldName: fieldName);
    if (numError != null) {
      return numError;
    }

    final intValue = int.parse(value!);
    if (intValue < min || intValue > max) {
      return '$fieldName harus antara $min-$max';
    }

    return null;
  }

  /// Validasi tanggal dengan format dd/MM/yyyy
  static String? date(String? value) {
    if (value == null || value.isEmpty) {
      return 'Tanggal tidak boleh kosong';
    }

    try {
      final formatter = DateFormat('dd/MM/yyyy');
      formatter.parseStrict(value);
      return null;
    } catch (e) {
      return 'Format tanggal tidak valid. Gunakan dd/MM/yyyy';
    }
  }

  /// Validasi stok (0-99999)
  static String? stock(String? value) {
    return numericRange(
      value,
      min: 0,
      max: 99999,
      fieldName: 'Stok',
    );
  }

  /// Validasi umur (0-150)
  static String? age(String? value) {
    return numericRange(
      value,
      min: 0,
      max: 150,
      fieldName: 'Umur',
    );
  }

  /// Validasi deskripsi (max 500 karakter)
  static String? description(String? value) {
    if (value == null) {
      return null; // Deskripsi adalah opsional
    }

    if (value.length > 500) {
      return 'Deskripsi maksimal 500 karakter';
    }

    return null;
  }

  /// Validasi tekanan darah (format: XXX/XX atau XXX/XXX)
  static String? bloodPressure(String? value) {
    if (value == null || value.isEmpty) {
      return 'Tekanan darah tidak boleh kosong';
    }

    final parts = value.split('/');
    if (parts.length != 2) {
      return 'Format tekanan darah tidak valid. Gunakan format XXX/XX';
    }

    final systolic = int.tryParse(parts[0]);
    final diastolic = int.tryParse(parts[1]);

    if (systolic == null || diastolic == null) {
      return 'Tekanan darah harus berupa angka';
    }

    if (systolic < 40 || systolic > 250) {
      return 'Tekanan darah sistolik tidak valid (40-250)';
    }

    if (diastolic < 20 || diastolic > 150) {
      return 'Tekanan darah diastolik tidak valid (20-150)';
    }

    if (systolic <= diastolic) {
      return 'Tekanan darah sistolik harus lebih besar dari diastolik';
    }

    return null;
  }

  /// Validasi path file (hanya nama file dengan ekstensi)
  static String? filePath(String? value) {
    if (value == null || value.isEmpty) {
      return 'Path file tidak boleh kosong';
    }

    // Check if file has extension
    if (!value.contains('.')) {
      return 'File harus memiliki ekstensi';
    }

    // Check for invalid characters
    final invalidChars = RegExp(r'[<>:"|?*]');
    if (invalidChars.hasMatch(value)) {
      return 'Path file mengandung karakter yang tidak diizinkan';
    }

    return null;
  }

  /// Validasi email
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email tidak boleh kosong';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?)*$',
    );

    if (!emailRegex.hasMatch(value)) {
      return 'Format email tidak valid';
    }

    return null;
  }

  /// Validasi nomor telepon (format: +62 atau 0, diikuti 9-12 digit)
  static String? phoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Nomor telepon tidak boleh kosong';
    }

    final phoneRegex = RegExp(r'^(\+62|0)[0-9]{9,12}$');
    if (!phoneRegex.hasMatch(value.replaceAll(RegExp(r'[\s\-]'), ''))) {
      return 'Format nomor telepon tidak valid';
    }

    return null;
  }

  /// Validasi persamaan dua nilai (untuk konfirmasi password, dll)
  static String? match(
    String? value,
    String? otherValue, {
    String fieldName = 'Field',
  }) {
    if (value != otherValue) {
      return '$fieldName tidak sesuai';
    }
    return null;
  }

  /// Validasi panjang teks minimum
  static String? minLength(
    String? value,
    int min, {
    String fieldName = 'Field',
  }) {
    if (value == null || value.isEmpty) {
      return '$fieldName tidak boleh kosong';
    }

    if (value.length < min) {
      return '$fieldName minimal $min karakter';
    }

    return null;
  }

  /// Validasi panjang teks maksimum
  static String? maxLength(
    String? value,
    int max, {
    String fieldName = 'Field',
  }) {
    if (value != null && value.length > max) {
      return '$fieldName maksimal $max karakter';
    }

    return null;
  }
}
