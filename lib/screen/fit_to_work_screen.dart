import 'package:flutter/material.dart';
import '../models/fit_to_work.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../components/oh_shared.dart';
import 'oh_data_screen.dart';
import 'fit_to_work_input_screen.dart';

class FitToWorkScreen extends StatelessWidget {
  const FitToWorkScreen({super.key});

  static const _cols = [
    OhCol('no', '#', 0.4),
    OhCol('tanggal', 'Tanggal', 1.0),
    OhCol('site', 'Site', 0.9),
    OhCol('nama', 'Nama', 1.5),
    OhCol('departemen', 'Dept.', 1.0),
    OhCol('shift', 'Shift', 0.8),
    OhCol('jamTidur', 'Jam Tidur', 0.9),
    OhCol('jamMasuk', 'Jam Masuk', 0.9),
    OhCol('kesehatan', 'Kesehatan', 1.0),
    OhCol('status', 'Status', 1.0),
    OhCol('aksi', 'Aksi', 0.9),
  ];

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService();

    return OhDataScreen<FitToWork>(
      title: 'Data Fit To Work',
      subtitle: 'pemeriksaan tercatat',
      icon: Icons.health_and_safety_rounded,
      color: Colors.green,

      columns: _cols,

      fetchData: (_) => db.getFitToWorks(),

      cellValues: (f, i) => [
        '${i + 1}',
        f.tanggal,
        f.site,
        f.nama,
        f.departemen,
        f.shift,
        '${f.jumlahJamTidur} jam',
        f.jamMasuk,
        f.kesehatan,
        f.isFit ? 'FIT' : 'NOT FIT',
        '',
      ],

      customCell: (f, col) {
        // Badge Shift
        if (col == 'shift') {
          return Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: OhBadge(text: f.shift, color: shiftColor(f.shift)),
          );
        }

        // Badge Kesehatan
        if (col == 'kesehatan') {
          return Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: OhBadge(
              text: f.kesehatan,
              color: kesehatanColor(f.kesehatan),
            ),
          );
        }

        // selain custom column → pakai default text
        return null;
      },

      statusBadge: (f) => OhBadge(
        text: f.isFit ? 'FIT' : 'NOT FIT',
        color: f.isFit ? Colors.green : Colors.red,
      ),

      onEdit: (f) async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => Scaffold(
              appBar: AppBar(
                title: const Text('Edit Fit To Work'),
                flexibleSpace: Container(
                  decoration: const BoxDecoration(
                    gradient: AppTheme.appBarGradient,
                  ),
                ),
              ),
              body: FitToWorkInputScreen(record: f),
            ),
          ),
        );
      },

      onDelete: (f) => db.deleteFitToWork(f.id!),
    );
  }
}
