/// Shared constants, helpers, and small widgets
/// dipakai oleh semua screen Kunjungan / Tes Narkoba / FitToWork / Fatigue
library oh_shared;

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ── Constants ──────────────────────────────────────────────────────────────

const kShiftOptions = ['Pagi', 'Siang', 'Malam'];
const kDrugResult = ['Negatif', 'Positif', '-'];
const kKesehatan = ['Baik', 'Kurang Baik', 'Sakit'];
const kFatigueKriteria = ['Fit', 'Fatigue Ringan', 'Fatigue Berat', 'Unfit'];
const kPembatasanDefault = 'Tidak Ada';

/// Pilihan pembatasan kerja (bisa pilih atau ketik manual)
const kPembatasanOptions = [
  'Tidak Ada',
  'Dilarang kerja di ketinggian',
  'Dilarang mengoperasikan alat berat',
  'Istirahat total',
  'Kerja ringan saja',
];

// ── Color helpers ──────────────────────────────────────────────────────────

Color hasilColor(String hasil) =>
    hasil == 'Positif' ? Colors.red : AppTheme.accent;

Color kriteriaColor(String k) {
  switch (k) {
    case 'Fit':
      return AppTheme.accent;
    case 'Fatigue Ringan':
      return Colors.orange;
    case 'Fatigue Berat':
      return Colors.deepOrange;
    case 'Unfit':
      return Colors.red;
    default:
      return AppTheme.textSecondary;
  }
}

Color kesehatanColor(String k) {
  switch (k) {
    case 'Baik':
      return AppTheme.accent;
    case 'Kurang Baik':
      return Colors.orange;
    case 'Sakit':
      return Colors.red;
    default:
      return AppTheme.textSecondary;
  }
}

Color shiftColor(String s) {
  switch (s) {
    case 'Pagi':
      return const Color(0xFFE3A008);
    case 'Siang':
      return AppTheme.primary;
    case 'Malam':
      return const Color(0xFF7E3AF2);
    default:
      return AppTheme.textSecondary;
  }
}

// ── Reusable form widgets ─────────────────────────────────────────────────

/// Label + field wrapper (stateless, for display)
class OhFieldLabel extends StatelessWidget {
  final String label;
  final Widget child;
  const OhFieldLabel({super.key, required this.label, required this.child});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary,
        ),
      ),
      const SizedBox(height: 5),
      child,
      const SizedBox(height: 14),
    ],
  );
}

/// Styled dropdown
class OhDropdown<T> extends StatelessWidget {
  final T? value;
  final List<T> items;
  final String hint;
  final String Function(T) label;
  final ValueChanged<T?> onChanged;

  const OhDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.hint,
    required this.label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<T>(
    value: value,
    isExpanded: true,
    decoration: const InputDecoration(),
    hint: Text(
      hint,
      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
    ),
    items: items
        .map(
          (i) => DropdownMenuItem(
            value: i,
            child: Text(label(i), style: const TextStyle(fontSize: 13)),
          ),
        )
        .toList(),
    onChanged: onChanged,
  );
}

/// Badge chip (status/label)
class OhBadge extends StatelessWidget {
  final String text;
  final Color color;
  const OhBadge({super.key, required this.text, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Text(
      text,
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
    ),
  );
}

/// Two-value stat card mini
class OhMiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const OhMiniStat({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: AppTheme.cardShadow,
    ),
    child: Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Date filter bar (reusable across all OH dashboards)
class OhDateFilter extends StatelessWidget {
  final DateTime start;
  final DateTime end;
  final VoidCallback onTap;

  const OhDateFilter({
    super.key,
    required this.start,
    required this.end,
    required this.onTap,
  });

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/'
      '${d.year}';

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.date_range_rounded,
            size: 16,
            color: AppTheme.primary,
          ),
          const SizedBox(width: 8),
          const Text(
            'Periode: ',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          Text(
            '${_fmt(start)}  –  ${_fmt(end)}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.primary,
            ),
          ),
          const Spacer(),
          const Icon(Icons.tune_rounded, size: 14, color: AppTheme.primary),
        ],
      ),
    ),
  );
}

/// Horizontal bar chart mini (untuk distribusi)
class OhHorizBar extends StatelessWidget {
  final Map<String, int> data;
  final Color Function(String) colorFn;

  const OhHorizBar({super.key, required this.data, required this.colorFn});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            'Tidak ada data',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
        ),
      );
    }
    final sorted = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxVal = sorted.first.value.toDouble();

    return Column(
      children: sorted.map((e) {
        final c = colorFn(e.key);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            children: [
              SizedBox(
                width: 100,
                child: Text(
                  e.key,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: maxVal > 0 ? e.value / maxVal : 0,
                    minHeight: 12,
                    backgroundColor: c.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation(c),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${e.value}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: c,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
