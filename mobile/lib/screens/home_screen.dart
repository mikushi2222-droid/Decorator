import 'package:flutter/material.dart';
import '../database.dart';
import '../main.dart';
import 'home_dashboard_screen.dart';
import 'projects_screen.dart';
import 'catalog_screen.dart';
import 'invoices_screen.dart';
import 'calculator_screen.dart';
import 'samples_screen.dart';
import 'settings_screen.dart';
import 'onboarding_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  static const _mainScreens = <Widget>[
    HomeDashboardScreen(),
    ProjectsScreen(),
    CatalogScreen(),
    InvoicesScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkOnboarding());
  }

  Future<void> _checkOnboarding() async {
    final shown = await AppDatabase.instance.isOnboardingShown();
    if (!shown && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const OnboardingScreen(),
          fullscreenDialog: true,
        ),
      );
    }
  }

  void _onDestinationSelected(int i) {
    if (i == 4) {
      _showMoreSheet();
    } else {
      setState(() => _index = i);
    }
  }

  void _showMoreSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _MoreSheet(
        onNavigate: (builder) {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: builder));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 700;
    return wide ? _wideLayout() : _narrowLayout();
  }

  Widget _narrowLayout() {
    return Scaffold(
      backgroundColor: kBackground,
      body: IndexedStack(index: _index, children: _mainScreens),
      bottomNavigationBar: _LuxuryNavBar(
        selectedIndex: _index,
        onDestinationSelected: _onDestinationSelected,
      ),
    );
  }

  Widget _wideLayout() {
    return Scaffold(
      backgroundColor: kBackground,
      body: Row(children: [
        _WideNavRail(
          selectedIndex: _index,
          onDestinationSelected: _onDestinationSelected,
        ),
        const VerticalDivider(thickness: 1, width: 1),
        Expanded(
          child: IndexedStack(index: _index, children: _mainScreens),
        ),
      ]),
    );
  }
}

// ─── Luxury bottom navigation bar ────────────────────────────────────────────

class _LuxuryNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  const _LuxuryNavBar({required this.selectedIndex, required this.onDestinationSelected});

  static const _items = [
    _NavItem(Icons.home_outlined, Icons.home_rounded, 'Главная'),
    _NavItem(Icons.folder_outlined, Icons.folder_rounded, 'Проекты'),
    _NavItem(Icons.search_outlined, Icons.search_rounded, 'Каталог'),
    _NavItem(Icons.receipt_long_outlined, Icons.receipt_long_rounded, 'Счета'),
    _NavItem(Icons.grid_view_outlined, Icons.grid_view_rounded, 'Ещё'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEEE8DF))),
        boxShadow: [
          BoxShadow(color: Color(0x0A000000), blurRadius: 16, offset: Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(_items.length, (i) {
              final item = _items[i];
              final selected = i == selectedIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onDestinationSelected(i),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: selected ? 44 : 0,
                          height: 4,
                          decoration: BoxDecoration(
                            color: kBronze,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Icon(
                          selected ? item.activeIcon : item.icon,
                          size: 24,
                          color: selected ? kBronze : const Color(0xFFAFA395),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                            color: selected ? kBronze : const Color(0xFFAFA395),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem(this.icon, this.activeIcon, this.label);
}

// ─── Wide navigation rail ─────────────────────────────────────────────────────

class _WideNavRail extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  const _WideNavRail({required this.selectedIndex, required this.onDestinationSelected});

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      labelType: NavigationRailLabelType.all,
      backgroundColor: kNavDark,
      selectedIconTheme: const IconThemeData(color: Colors.white),
      unselectedIconTheme: const IconThemeData(color: Colors.white54),
      selectedLabelTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
      unselectedLabelTextStyle: const TextStyle(color: Colors.white54, fontSize: 11),
      indicatorColor: Colors.white12,
      leading: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: kGold.withOpacity(0.2), shape: BoxShape.circle),
            child: const Icon(Icons.brush_outlined, size: 18, color: kGold),
          ),
        ]),
      ),
      destinations: const [
        NavigationRailDestination(
            icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded),
            label: Text('Главная')),
        NavigationRailDestination(
            icon: Icon(Icons.folder_outlined), selectedIcon: Icon(Icons.folder_rounded),
            label: Text('Проекты')),
        NavigationRailDestination(
            icon: Icon(Icons.search_outlined), selectedIcon: Icon(Icons.search_rounded),
            label: Text('Каталог')),
        NavigationRailDestination(
            icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long_rounded),
            label: Text('Счета')),
        NavigationRailDestination(
            icon: Icon(Icons.grid_view_outlined), selectedIcon: Icon(Icons.grid_view_rounded),
            label: Text('Ещё')),
      ],
    );
  }
}

// ─── "Ещё" bottom sheet ───────────────────────────────────────────────────────

class _MoreSheet extends StatelessWidget {
  final void Function(WidgetBuilder builder) onNavigate;
  const _MoreSheet({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final items = [
      _MoreItem(Icons.calculate_outlined, 'Калькулятор расхода',
          'Материалы и работы', kBronze,
          (_) => const CalculatorScreen()),
      _MoreItem(Icons.palette_outlined, 'Галерея фактур',
          'Шёлк, Травертин, Барельеф', kGold,
          (_) => Scaffold(
            backgroundColor: kBackground,
            appBar: AppBar(title: const Text('Галерея фактур')),
            body: const SamplesScreen(),
          )),
      _MoreItem(Icons.settings_outlined, 'Настройки',
          'Профиль, реквизиты, каталог', const Color(0xFF9E9585),
          (_) => Scaffold(
            backgroundColor: kBackground,
            appBar: AppBar(title: const Text('Настройки')),
            body: const SettingsScreen(),
          )),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 36, height: 4,
          decoration: BoxDecoration(
            color: const Color(0xFFDDD6CC),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 16),
        Row(children: [
          const Text('Разделы',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: kGraphite)),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () => Navigator.pop(context),
            color: const Color(0xFFAFA395),
          ),
        ]),
        const SizedBox(height: 8),
        ...items.map((item) => _MoreTile(item: item, onTap: () => onNavigate(item.screenBuilder))),
        const SizedBox(height: 8),
        SafeArea(child: const SizedBox()),
      ]),
    );
  }
}

class _MoreItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final WidgetBuilder screenBuilder;
  _MoreItem(this.icon, this.title, this.subtitle, this.color, this.screenBuilder);
}

class _MoreTile extends StatelessWidget {
  final _MoreItem item;
  final VoidCallback onTap;
  const _MoreTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: item.color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(item.icon, size: 22, color: item.color),
      ),
      title: Text(item.title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: kGraphite)),
      subtitle: Text(item.subtitle,
          style: const TextStyle(fontSize: 12, color: Color(0xFFB0A090))),
      trailing: const Icon(Icons.chevron_right, color: Color(0xFFCCC0B0), size: 20),
      onTap: onTap,
    );
  }
}
