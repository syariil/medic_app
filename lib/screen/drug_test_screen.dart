import 'package:flutter/material.dart';
import '../models/drug_test.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../components/oh_shared.dart';
import 'oh_data_screen.dart';
import 'drug_test_input_screen.dart';

class DrugTestScreen extends StatelessWidget {
  const DrugTestScreen({super.key});

  static const _cols = [
    OhCol('no', '#', 0.4),
    OhCol('tanggal', 'Tanggal', 1.0),
    OhCol('site', 'Site', 1.0),
    OhCol('nama', 'Nama', 1.5),
    OhCol('posisi', 'Posisi', 1.0),
    OhCol('departemen', 'Dept.', 1.0),
    OhCol('amp', 'AMP', 0.7),
    OhCol('met', 'MET', 0.7),
    OhCol('thc', 'THC', 0.7),
    OhCol('coc', 'COC', 0.7),
    OhCol('bzo', 'BZO', 0.7),
    OhCol('status', 'Hasil', 1.0),
    OhCol('aksi', 'Aksi', 0.9),
  ];

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService();

    return OhDataScreen<DrugTest>(
      title: 'Data Tes Narkoba',
      subtitle: 'tes tercatat',
      icon: Icons.science_rounded,
      color: const Color(0xFF7E3AF2),

      columns: _cols,

      fetchData: (_) => db.getDrugTests(),

      cellValues: (d, i) => [
        '${i + 1}',
        d.tanggal,
        d.site,
        d.nama,
        d.posisi,
        d.departemen,
        d.amp,
        d.met,
        d.thc,
        d.coc,
        d.bzo,
        d.hasil,
        '',
      ],

      customCell: (d, col) {
        switch (col) {
          case 'amp':
            return _paramCell(d.amp);

          case 'met':
            return _paramCell(d.met);

          case 'thc':
            return _paramCell(d.thc);

          case 'coc':
            return _paramCell(d.coc);

          case 'bzo':
            return _paramCell(d.bzo);

          // penting ⚡
          default:
            return null;
        }
      },

      statusBadge: (d) => OhBadge(text: d.hasil, color: hasilColor(d.hasil)),

      onEdit: (d) async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => Scaffold(
              appBar: AppBar(
                title: const Text('Edit Tes Narkoba'),
                flexibleSpace: Container(
                  decoration: const BoxDecoration(
                    gradient: AppTheme.appBarGradient,
                  ),
                ),
              ),
              body: DrugTestInputScreen(drugTest: d),
            ),
          ),
        );
      },

      onDelete: (d) => db.deleteDrugTest(d.id!),
    );
  }

  // ─────────────────────────────────────────────
  // PARAM CELL
  // ─────────────────────────────────────────────

  Widget _paramCell(String val) {
    final c = _paramColor(val);

    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),

      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),

        decoration: BoxDecoration(
          color: c.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: c.withOpacity(0.25)),
        ),

        child: Text(
          val == '-' ? '-' : val.substring(0, 3),

          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: c),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // PARAM COLOR
  // ─────────────────────────────────────────────

  Color _paramColor(String v) {
    if (v == 'Positif') {
      return Colors.red;
    }

    if (v == '-') {
      return Colors.grey;
    }

    return AppTheme.accent;
  }
}
