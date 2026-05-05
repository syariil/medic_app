import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'patient_dashboard_screen.dart';
import 'medicine_dashboard_screen.dart';
import 'data_screen.dart';
import 'input_screen.dart';
import 'doctor_screen.dart';
import 'doctor_input_screen.dart';
import 'medicine_screen.dart';
import 'medicine_input_screen.dart';
import 'import_screen.dart';
import 'export_screen.dart';

class _NavItem {
  final int pageIndex;
  final IconData icon;
  final String label;
  const _NavItem(this.pageIndex, this.icon, this.label);
}

class _NavGroup {
  final String label;
  final IconData icon;
  final List<_NavItem> items;
  const _NavGroup(this.label, this.icon, this.items);
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedPage = 0;

  static final _groups = [
    _NavGroup('Dashboard', Icons.dashboard_rounded, [
      _NavItem(0, Icons.people_alt_rounded, 'Dashboard Pasien'),
      _NavItem(1, Icons.medication_rounded, 'Dashboard Farmasi'),
    ]),
    _NavGroup('Pasien', Icons.personal_injury_rounded, [
      _NavItem(2, Icons.table_rows_rounded, 'Data Pasien'),
      _NavItem(3, Icons.person_add_rounded, 'Input Pasien'),
    ]),
    _NavGroup('Dokter', Icons.medical_information_rounded, [
      _NavItem(4, Icons.table_rows_rounded, 'Data Dokter'),
      _NavItem(5, Icons.person_add_alt_1_rounded, 'Input Dokter'),
    ]),
    _NavGroup('Farmasi', Icons.local_pharmacy_rounded, [
      _NavItem(6, Icons.table_rows_rounded, 'Data Obat'),
      _NavItem(7, Icons.add_box_rounded, 'Input Obat'),
    ]),
    _NavGroup('Utilitas', Icons.build_rounded, [
      _NavItem(8, Icons.upload_file_rounded, 'Import Excel'),
      _NavItem(9, Icons.download_rounded, 'Export Data'),
    ]),
  ];

  Widget _buildPage(int index) {
    switch (index) {
      case 0:
        return const PatientDashboardScreen();
      case 1:
        return const MedicineDashboardScreen();
      case 2:
        return const DataScreen();
      case 3:
        return const InputScreen();
      case 4:
        return const DoctorScreen();
      case 5:
        return const DoctorInputScreen();
      case 6:
        return const MedicineScreen();
      case 7:
        return const MedicineInputScreen();
      case 8:
        return const ImportScreen();
      case 9:
        return const ExportScreen();
      default:
        return const PatientDashboardScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _AccordionSidebar(
            groups: _groups,
            selectedPage: _selectedPage,
            onSelect: (i) => setState(() => _selectedPage = i),
          ),
          Expanded(child: _buildPage(_selectedPage)),
        ],
      ),
    );
  }
}

// ─── ACCORDION SIDEBAR ────────────────────────────────────────────────────────

class _AccordionSidebar extends StatefulWidget {
  final List<_NavGroup> groups;
  final int selectedPage;
  final ValueChanged<int> onSelect;
  const _AccordionSidebar({
    required this.groups,
    required this.selectedPage,
    required this.onSelect,
  });
  @override
  State<_AccordionSidebar> createState() => _AccordionSidebarState();
}

class _AccordionSidebarState extends State<_AccordionSidebar> {
  late Set<int> _expanded;
  @override
  void initState() {
    super.initState();
    _expanded = {0, 1, 2, 3, 4};
  }

  void _toggle(int gi) => setState(
    () => _expanded.contains(gi) ? _expanded.remove(gi) : _expanded.add(gi),
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 224,
      decoration: const BoxDecoration(
        gradient: AppTheme.sidebarGradient,
        boxShadow: [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 16,
            offset: Offset(4, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 36, 20, 24),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.local_hospital_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'MEDIC APP',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: List.generate(widget.groups.length, (gi) {
                  final group = widget.groups[gi];
                  final isExpanded = _expanded.contains(gi);
                  final hasActive = group.items.any(
                    (item) => item.pageIndex == widget.selectedPage,
                  );
                  return _AccordionGroup(
                    group: group,
                    groupIndex: gi,
                    isExpanded: isExpanded,
                    hasActive: hasActive,
                    selectedPage: widget.selectedPage,
                    onToggle: () => _toggle(gi),
                    onSelect: widget.onSelect,
                  );
                }),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'v1.0.0',
              style: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccordionGroup extends StatelessWidget {
  final _NavGroup group;
  final int groupIndex;
  final bool isExpanded, hasActive;
  final int selectedPage;
  final VoidCallback onToggle;
  final ValueChanged<int> onSelect;
  const _AccordionGroup({
    required this.group,
    required this.groupIndex,
    required this.isExpanded,
    required this.hasActive,
    required this.selectedPage,
    required this.onToggle,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onToggle,
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 4, 12, 0),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: hasActive && !isExpanded
                  ? Colors.white.withOpacity(0.08)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  group.icon,
                  size: 17,
                  color: hasActive
                      ? Colors.white
                      : Colors.white.withOpacity(0.5),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    group.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: hasActive
                          ? Colors.white
                          : Colors.white.withOpacity(0.5),
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: isExpanded ? 0.25 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: Colors.white.withOpacity(0.4),
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 200),
          crossFadeState: isExpanded
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          firstChild: Column(
            children: group.items.map((item) {
              final isActive = item.pageIndex == selectedPage;
              return _NavItemTile(
                item: item,
                isActive: isActive,
                onTap: () => onSelect(item.pageIndex),
              );
            }).toList(),
          ),
          secondChild: const SizedBox(width: double.infinity),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          child: Divider(height: 1, color: Colors.white.withOpacity(0.08)),
        ),
      ],
    );
  }
}

class _NavItemTile extends StatelessWidget {
  final _NavItem item;
  final bool isActive;
  final VoidCallback onTap;
  const _NavItemTile({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.fromLTRB(24, 1, 12, 1),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: isActive ? Colors.white.withOpacity(0.16) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isActive
              ? Border.all(color: Colors.white.withOpacity(0.12))
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 3,
              height: 16,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: isActive ? AppTheme.accent : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Icon(
              item.icon,
              size: 15,
              color: isActive ? Colors.white : Colors.white.withOpacity(0.5),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                item.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  color: isActive
                      ? Colors.white
                      : Colors.white.withOpacity(0.55),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
