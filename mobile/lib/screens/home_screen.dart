import 'package:flutter/material.dart';
import '../database.dart';
import '../main.dart';
import 'calculator_screen.dart';
import 'invoices_screen.dart';
import 'catalog_screen.dart';
import 'settings_screen.dart';
import 'onboarding_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  static const _screens = [
    CalculatorScreen(),
    InvoicesScreen(),
    CatalogScreen(),
    SettingsScreen(),
  ];

  static const _items = [
    NavigationDestination(icon: Icon(Icons.calculate_outlined), selectedIcon: Icon(Icons.calculate), label: 'Калькулятор'),
    NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Накладные'),
    NavigationDestination(icon: Icon(Icons.search_outlined), selectedIcon: Icon(Icons.search), label: 'Каталог'),
    NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Настройки'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text('Декоратор'),
            Text('ООО «АКЦЕНТ»',
                style: TextStyle(fontSize: 11, color: Colors.white60, fontWeight: FontWeight.normal)),
          ],
        ),
        backgroundColor: kBrand,
      ),
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        indicatorColor: kBrand.withOpacity(0.15),
        destinations: _items,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
    );
  }
}
