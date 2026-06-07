import 'package:flutter/material.dart';
import '../database.dart';
import '../main.dart';
import '../models.dart';
import '../utils.dart';
import 'invoice_form_screen.dart';
import 'invoice_view_screen.dart';
import 'calculator_screen.dart';
import 'catalog_screen.dart';
import 'samples_screen.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  String _decoratorName = '';
  List<Invoice> _recentInvoices = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    AppDatabase.instance.dataRevision.addListener(_load);
  }

  @override
  void dispose() {
    AppDatabase.instance.dataRevision.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final name = await AppDatabase.instance.getDecoratorName();
      final invoices = await AppDatabase.instance.getInvoices();
      if (!mounted) return;
      setState(() {
        _decoratorName = name;
        _recentInvoices = invoices.take(5).toList();
        _loading = false;
      });
    } catch (_) {
      // Не оставляем экран в вечном спиннере, если чтение не удалось.
      if (mounted) setState(() => _loading = false);
    }
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h >= 5 && h < 12) return 'Доброе утро';
    if (h >= 12 && h < 18) return 'Добрый день';
    if (h >= 18 && h < 23) return 'Добрый вечер';
    return 'Доброй ночи';
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(slivers: [
      _buildAppBar(),
      SliverToBoxAdapter(child: _buildBody()),
    ]);
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      backgroundColor: kBackground,
      scrolledUnderElevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF7F4EF), Color(0xFFEDE8E0)],
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(
                      _decoratorName.isNotEmpty
                          ? '$_greeting, $_decoratorName'
                          : _greeting,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: kGraphite,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Декоратор · АКЦЕНТ',
                      style: TextStyle(
                        fontSize: 13,
                        color: kGraphite.withOpacity(0.5),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ]),
                ),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: kGoldLight,
                    shape: BoxShape.circle,
                    border: Border.all(color: kGold.withOpacity(0.4)),
                  ),
                  child: Center(
                    child: Text(
                      _decoratorName.isNotEmpty
                          ? _decoratorName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: kBronze,
                      ),
                    ),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionLabel('Быстрые действия'),
        const SizedBox(height: 10),
        _quickActions(),
        const SizedBox(height: 24),
        _sectionLabel('Последние накладные'),
        const SizedBox(height: 10),
        _recentInvoicesSection(),
        const SizedBox(height: 24),
        _sectionLabel('Материалы и инструменты'),
        const SizedBox(height: 10),
        _resourceCards(),
      ]),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Text(text,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFFB0A090),
                letterSpacing: 0.8)),
      );

  Widget _quickActions() {
    final actions = [
      _QuickAction(
        icon: Icons.receipt_long_outlined,
        label: 'Накладная',
        color: kBronze,
        onTap: () async {
          final ok = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const InvoiceFormScreen()),
          );
          if (ok == true) _load();
        },
      ),
      _QuickAction(
        icon: Icons.calculate_outlined,
        label: 'Калькулятор',
        color: const Color(0xFF7C9B8A),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CalculatorScreen()),
        ),
      ),
      _QuickAction(
        icon: Icons.search_outlined,
        label: 'Каталог',
        color: const Color(0xFF8B7BAE),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CatalogScreen()),
        ),
      ),
      _QuickAction(
        icon: Icons.palette_outlined,
        label: 'Галерея',
        color: const Color(0xFFC47B2B),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SamplesScreen()),
        ),
      ),
    ];

    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 0,
      childAspectRatio: 0.85,
      children: actions.map((a) => _QuickActionTile(action: a)).toList(),
    );
  }

  Widget _recentInvoicesSection() {
    if (_recentInvoices.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEEE8DF)),
        ),
        child: const Center(
          child: Column(children: [
            Icon(Icons.receipt_long_outlined, size: 32, color: Color(0xFFCCC0B0)),
            SizedBox(height: 8),
            Text('Накладных пока нет',
                style: TextStyle(color: Color(0xFFB0A090), fontSize: 13)),
          ]),
        ),
      );
    }
    return Column(
      children: _recentInvoices.map((inv) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: _InvoiceTile(
          invoice: inv,
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => InvoiceViewScreen(invoice: inv)),
            );
            _load();
          },
        ),
      )).toList(),
    );
  }

  Widget _resourceCards() {
    return Row(children: [
      Expanded(
        child: _ResourceCard(
          icon: Icons.auto_awesome_outlined,
          title: 'Подобрать\nфактуру',
          subtitle: 'Мастер выбора',
          color: kBronze,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SamplesScreen()),
          ),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: _ResourceCard(
          icon: Icons.calculate_outlined,
          title: 'Калькулятор',
          subtitle: 'Расход и стоимость',
          color: const Color(0xFF4A8A6E),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CalculatorScreen()),
          ),
        ),
      ),
    ]);
  }
}

// ─── Quick action tile ────────────────────────────────────────────────────────

class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label, required this.color, required this.onTap});
}

class _QuickActionTile extends StatelessWidget {
  final _QuickAction action;
  const _QuickActionTile({required this.action});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: action.onTap,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: action.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: action.color.withOpacity(0.2)),
          ),
          child: Icon(action.icon, size: 26, color: action.color),
        ),
        const SizedBox(height: 6),
        Text(action.label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kGraphite)),
      ]),
    );
  }
}

// ─── Invoice tile ─────────────────────────────────────────────────────────────

class _InvoiceTile extends StatelessWidget {
  final Invoice invoice;
  final VoidCallback onTap;
  const _InvoiceTile({required this.invoice, required this.onTap});

  static const _statusColors = {
    InvoiceStatus.draft: Color(0xFF9E9585),
    InvoiceStatus.sent:  Color(0xFFF59E0B),
    InvoiceStatus.paid:  Color(0xFF22C55E),
  };

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColors[invoice.status] ?? const Color(0xFF9E9585);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEEE8DF)),
        ),
        child: Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.receipt_long_outlined, size: 20, color: statusColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(invoice.clientName,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: kGraphite),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text('${invoice.number} · ${formatDateShort(invoice.date)}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFFB0A090))),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(formatCurrency(invoice.total),
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: kGraphite)),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(invoice.status.label,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: statusColor)),
            ),
          ]),
        ]),
      ),
    );
  }
}

// ─── Resource card ────────────────────────────────────────────────────────────

class _ResourceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  const _ResourceCard({
    required this.icon, required this.title, required this.subtitle,
    required this.color, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.18)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 28, color: color),
          const SizedBox(height: 10),
          Text(title,
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: color, height: 1.2)),
          const SizedBox(height: 3),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFFB0A090))),
        ]),
      ),
    );
  }
}
