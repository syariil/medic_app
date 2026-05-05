import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class DiagnosisLegend extends StatelessWidget {
  final Map<String, int> data;

  /// Callback untuk mendapatkan warna per key diagnosa.
  /// Dipakai agar warna konsisten dengan chart yang menampilkannya.
  final Color Function(String key) getColor;

  const DiagnosisLegend({
    super.key,
    required this.data,
    required this.getColor,
  });

  @override
  Widget build(BuildContext context) {
    final total = data.values.fold(0, (a, b) => a + b);

    final entries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value)); // terbesar dulu

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: List.generate(entries.length, (i) {
        final e = entries[i];
        final color = getColor(e.key);
        final pct = total > 0
            ? (e.value / total * 100).toStringAsFixed(1)
            : '0';

        return SizedBox(
          width: 140, // 2-kolom otomatis
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${e.key} ($pct%)',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
