import 'package:flutter/material.dart';
import '../models/fatigue.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../components/oh_shared.dart';
import 'oh_data_screen.dart';
import 'fatigue_input_screen.dart';

class FatigueScreen extends StatelessWidget {
  const FatigueScreen({super.key});

  static const _cols = [
    OhCol('no', '#', 0.4),
    OhCol('tanggal', 'Tanggal', 1.0),
    OhCol('site', 'Site', 0.9),
    OhCol('nama', 'Nama', 1.5),
    OhCol('departemen', 'Dept.', 1.0),
    OhCol('shift', 'Shift', 0.8),
    OhCol('jamTidur', 'Jam Tidur', 0.8),
    OhCol('td', 'TD', 0.8),
    OhCol('nadi', 'Nadi', 0.7),
    OhCol('status', 'Kriteria', 1.1),
    OhCol('aksi', 'Aksi', 0.9),
  ];

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService();

    return OhDataScreen<Fatigue>(
      title: 'Data Fatigue',
      subtitle: 'pemeriksaan tercatat',
      icon: Icons.battery_alert_rounded,
      color: Colors.deepOrange,

      columns: _cols,

      fetchData: (_) => db.getFatigues(),

      cellValues: (f, i) => [
        '${i + 1}',
        f.tanggal,
        f.site,
        f.nama,
        f.departemen,
        f.shift,
        '${f.jumlahJamTidur}h',
        f.tekananDarah,
        '${f.nadi}',
        f.kriteria,
        '',
      ],

      customCell: (f, col) {
        if (col == 'shift') {
          return Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: OhBadge(text: f.shift, color: shiftColor(f.shift)),
          );
        }

        // penting ✨
        return null;
      },

      statusBadge: (f) =>
          OhBadge(text: f.kriteria, color: kriteriaColor(f.kriteria)),

      onEdit: (f) async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => Scaffold(
              appBar: AppBar(
                title: const Text('Edit Fatigue'),
                flexibleSpace: Container(
                  decoration: const BoxDecoration(
                    gradient: AppTheme.appBarGradient,
                  ),
                ),
              ),
              body: FatigueInputScreen(record: f),
            ),
          ),
        );
      },

      onDelete: (f) => db.deleteFatigue(f.id!),
    );
  }
}
