import 'package:flutter/material.dart';
import 'package:medic_app/screen/dashboard_screen.dart';
import '../theme/app_theme.dart';
import 'medicine_dashboard_screen.dart';
import 'oh_dashboard_screen.dart';
import 'visit_screen.dart';
import 'visit_input_screen.dart';
import 'drug_test_screen.dart';
import 'drug_test_input_screen.dart';
import 'fit_to_work_screen.dart';
import 'fit_to_work_input_screen.dart';
import 'fatigue_screen.dart';
import 'fatigue_input_screen.dart';
import 'medicine_screen.dart';
import 'medicine_input_screen.dart';
import 'import_screen.dart';
import 'export_screen.dart';

// ─── Menu model ───────────────────────────────────────────────────────────────

class _NavItem {
  final int pageIndex;
  final IconData icon;
  final String label;
  final bool isInputPage; // dibuka sebagai modal
  const _NavItem(
    this.pageIndex,
    this.icon,
    this.label, {
    this.isInputPage = false,
  });
}

class _NavGroup {
  final String label;
  final IconData icon;
  final Color color;
  final List<_NavItem> items;
  const _NavGroup(this.label, this.icon, this.color, this.items);
}

// ─── MAIN SCREEN ──────────────────────────────────────────────────────────────

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedPage = 0;

  static final List<_NavGroup> _groups = [
    _NavGroup('Dashboard', Icons.dashboard_rounded, AppTheme.primary, [
      _NavItem(0, Icons.bar_chart_rounded, 'Dashboard OH'),
      _NavItem(1, Icons.medication_rounded, 'Dashboard Farmasi'),
    ]),
    _NavGroup('Occ. Health', Icons.health_and_safety_rounded, Colors.green, [
      _NavItem(2, Icons.local_hospital_rounded, 'Data Kunjungan'),
      _NavItem(10, Icons.add_rounded, 'Input Kunjungan', isInputPage: true),
      _NavItem(3, Icons.science_rounded, 'Data Tes Narkoba'),
      _NavItem(11, Icons.add_rounded, 'Input Tes Narkoba', isInputPage: true),
      _NavItem(4, Icons.health_and_safety_rounded, 'Data Fit To Work'),
      _NavItem(12, Icons.add_rounded, 'Input Fit To Work', isInputPage: true),
      _NavItem(5, Icons.battery_alert_rounded, 'Data Fatigue'),
      _NavItem(13, Icons.add_rounded, 'Input Fatigue', isInputPage: true),
    ]),
    _NavGroup('Utilitas', Icons.build_rounded, AppTheme.textSecondary, [
      _NavItem(6, Icons.inventory_2_rounded, 'Data Obat'),
      _NavItem(14, Icons.add_box_rounded, 'Input Obat', isInputPage: true),
      _NavItem(7, Icons.upload_file_rounded, 'Import Excel'),
      _NavItem(8, Icons.download_rounded, 'Export Data'),
    ]),
  ];

  Widget _buildPage(int index) {
    switch (index) {
      case 0:
        return const DashboardScreen();
      case 1:
        return const MedicineDashboardScreen();
      case 2:
        return const VisitScreen();
      case 3:
        return const DrugTestScreen();
      case 4:
        return const FitToWorkScreen();
      case 5:
        return const FatigueScreen();
      case 6:
        return const MedicineScreen();
      case 7:
        return const ImportScreen();
      case 8:
        return const ExportScreen();
      default:
        return const OhDashboardScreen();
    }
  }

  void _handleSelect(int index, bool isInputPage) {
    if (!isInputPage) {
      setState(() => _selectedPage = index);
      return;
    }
    // Input pages → modal fullscreen
    Widget? page;
    String title = '';
    switch (index) {
      case 10:
        page = const VisitInputScreen();
        title = 'Input Kunjungan';
        break;
      case 11:
        page = const DrugTestInputScreen();
        title = 'Input Tes Narkoba';
        break;
      case 12:
        page = const FitToWorkInputScreen();
        title = 'Input Fit To Work';
        break;
      case 13:
        page = const FatigueInputScreen();
        title = 'Input Fatigue';
        break;
      case 14:
        page = const MedicineInputScreen();
        title = 'Input Obat';
        break;
      default:
        return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: Text(title),
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: AppTheme.appBarGradient,
              ),
            ),
          ),
          body: page!,
        ),
      ),
    ).then((ok) {
      // Refresh current data screen if input was saved
      if (ok == true) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _AccordionSidebar(
            groups: _groups,
            selectedPage: _selectedPage,
            onSelect: _handleSelect,
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
  final void Function(int, bool) onSelect;

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
    _expanded = {0, 1, 2};
  }

  void _toggle(int gi) => setState(
    () => _expanded.contains(gi) ? _expanded.remove(gi) : _expanded.add(gi),
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 228,
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
          // ── Logo ─────────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 32, 18, 20),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(
                    Icons.health_and_safety_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'OH MEDIC',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      'Management System',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 9,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Groups ───────────────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: List.generate(widget.groups.length, (gi) {
                  final group = widget.groups[gi];
                  final isExpanded = _expanded.contains(gi);
                  final hasActive = group.items.any(
                    (item) =>
                        !item.isInputPage &&
                        item.pageIndex == widget.selectedPage,
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

          // ── Footer ───────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppTheme.accent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'v1.0.0  •  DB v6',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── ACCORDION GROUP ──────────────────────────────────────────────────────────

class _AccordionGroup extends StatelessWidget {
  final _NavGroup group;
  final int groupIndex;
  final bool isExpanded, hasActive;
  final int selectedPage;
  final VoidCallback onToggle;
  final void Function(int, bool) onSelect;

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
        // Group header
        GestureDetector(
          onTap: onToggle,
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 3, 12, 0),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: hasActive && !isExpanded
                  ? Colors.white.withOpacity(0.07)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: hasActive ? group.color : Colors.white30,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  group.icon,
                  size: 15,
                  color: hasActive ? Colors.white : Colors.white54,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    group.label.toUpperCase(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.9,
                      color: hasActive ? Colors.white : Colors.white54,
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: isExpanded ? 0.25 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(
                    Icons.chevron_right_rounded,
                    size: 14,
                    color: Colors.white30,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Items
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 200),
          crossFadeState: isExpanded
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          firstChild: Column(
            children: group.items
                .map(
                  (item) => _NavTile(
                    item: item,
                    isActive:
                        !item.isInputPage && item.pageIndex == selectedPage,
                    groupColor: group.color,
                    onTap: () => onSelect(item.pageIndex, item.isInputPage),
                  ),
                )
                .toList(),
          ),
          secondChild: const SizedBox(width: double.infinity),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
          child: Divider(height: 1, color: Colors.white.withOpacity(0.07)),
        ),
      ],
    );
  }
}

// ─── NAV TILE ─────────────────────────────────────────────────────────────────

class _NavTile extends StatelessWidget {
  final _NavItem item;
  final bool isActive;
  final Color groupColor;
  final VoidCallback onTap;

  const _NavTile({
    required this.item,
    required this.isActive,
    required this.groupColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isInput = item.isInputPage;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: EdgeInsets.fromLTRB(isInput ? 36 : 28, 1, 12, 1),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.white.withOpacity(0.13) : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          border: isActive
              ? Border.all(color: Colors.white.withOpacity(0.12))
              : null,
        ),
        child: Row(
          children: [
            // Active indicator bar
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 3,
              height: 14,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: isActive ? groupColor : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Icon(
              item.icon,
              size: isInput ? 14 : 16,
              color: isActive
                  ? Colors.white
                  : isInput
                  ? Colors.white38
                  : Colors.white54,
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                item.label,
                style: TextStyle(
                  fontSize: isInput ? 12 : 14,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  color: isActive
                      ? Colors.white
                      : isInput
                      ? Colors.white38
                      : Colors.white54,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isInput)
              Icon(Icons.open_in_new_rounded, size: 14, color: Colors.white24),
          ],
        ),
      ),
    );
  }
}
