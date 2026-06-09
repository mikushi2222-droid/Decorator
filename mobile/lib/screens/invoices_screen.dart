import 'package:flutter/material.dart';
import '../database.dart';
import '../main.dart';
import '../models.dart';
import '../utils.dart';
import 'invoice_form_screen.dart';
import 'invoice_view_screen.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  final _searchC = TextEditingController();
  String _statusFilter = 'all';
  List<Invoice> _all = [];
  bool _loading = true;

  static const _filters = <(String, String)>[
    ('all',   'Все'),
    ('sent',  'Не оплачено'),
    ('paid',  'Оплачено'),
    ('draft', 'Черновик'),
  ];

  @override
  void initState() {
    super.initState();
    _load();
    AppDatabase.instance.dataRevision.addListener(_load);
    _searchC.addListener(() => setState(() {}));
  }

  Future<void> _load() async {
    final invoices = await AppDatabase.instance.getInvoices();
    if (!mounted) return;
    setState(() {
      _all = invoices;
      _loading = false;
    });
  }

  List<Invoice> get _filtered {
    var list = _all;
    switch (_statusFilter) {
      case 'sent':  list = list.where((i) => i.status == InvoiceStatus.sent).toList();
      case 'paid':  list = list.where((i) => i.status == InvoiceStatus.paid).toList();
      case 'draft': list = list.where((i) => i.status == InvoiceStatus.draft).toList();
    }
    final q = _searchC.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((i) =>
          i.clientName.toLowerCase().contains(q) ||
          i.number.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  double get _monthTotal {
    final now = DateTime.now();
    return _all
        .where((i) => i.date.year == now.year && i.date.month == now.month)
        .fold(0.0, (s, i) => s + i.total);
  }

  double get _outstanding =>
      _all.where((i) => i.status == InvoiceStatus.sent).fold(0.0, (s, i) => s + i.total);

  double get _paidTotal =>
      _all.where((i) => i.status == InvoiceStatus.paid).fold(0.0, (s, i) => s + i.total);

  int _count(String key) {
    switch (key) {
      case 'sent':  return _all.where((i) => i.status == InvoiceStatus.sent).length;
      case 'paid':  return _all.where((i) => i.status == InvoiceStatus.paid).length;
      case 'draft': return _all.where((i) => i.status == InvoiceStatus.draft).length;
      default:      return _all.length;
    }
  }

  Future<void> _create() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const InvoiceFormScreen()),
    );
    if (result == true) _load();
  }

  Future<void> _open(Invoice inv) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => InvoiceViewScreen(invoice: inv)),
    );
    if (result == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Header ───────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 0),
          child: Row(children: [
            const Text('Накладные',
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold, color: kGraphite)),
            const Spacer(),
            FilledButton.icon(
              onPressed: _create,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Создать'),
              style: FilledButton.styleFrom(
                backgroundColor: kBronze,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ]),
        ),

        // ── Stats bar ─────────────────────────────────────────────────────────
        if (_all.isNotEmpty)
          _StatsBar(
            monthTotal:  _monthTotal,
            outstanding: _outstanding,
            paid:        _paidTotal,
          ),

        // ── Search ────────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: TextField(
            controller: _searchC,
            decoration: InputDecoration(
              hintText: 'Поиск по клиенту, номеру…',
              prefixIcon: const Icon(Icons.search, size: 18),
              suffixIcon: _searchC.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 16),
                      onPressed: _searchC.clear,
                    )
                  : null,
            ),
          ),
        ),

        // ── Filter chips ─────────────────────────────────────────────────────
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            itemCount: _filters.length,
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemBuilder: (_, i) {
              final (key, label) = _filters[i];
              final cnt = _count(key);
              final active = _statusFilter == key;
              final chipLabel = (key != 'all' && cnt > 0) ? '$label · $cnt' : label;
              return FilterChip(
                label: Text(chipLabel),
                selected: active,
                onSelected: (_) => setState(() => _statusFilter = key),
                selectedColor: kBronze,
                labelStyle: TextStyle(
                  color: active ? Colors.white : null,
                  fontSize: 12,
                ),
                checkmarkColor: Colors.white,
                showCheckmark: false,
                padding: const EdgeInsets.symmetric(horizontal: 4),
              );
            },
          ),
        ),

        // ── Invoice list ──────────────────────────────────────────────────────
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : filtered.isEmpty
                  ? _EmptyState(hasData: _all.isNotEmpty, onCreate: _create)
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) => _InvoiceTile(
                        invoice: filtered[i],
                        onTap: () => _open(filtered[i]),
                      ),
                    ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    AppDatabase.instance.dataRevision.removeListener(_load);
    _searchC.dispose();
    super.dispose();
  }
}

// ─── Stats bar ────────────────────────────────────────────────────────────────

class _StatsBar extends StatelessWidget {
  final double monthTotal;
  final double outstanding;
  final double paid;
  const _StatsBar({
    required this.monthTotal,
    required this.outstanding,
    required this.paid,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [kBronze, Color(0xFF7A5C42)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: kBronze.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(children: [
        _cell('За месяц', monthTotal),
        _divider(),
        _cell('К оплате', outstanding),
        _divider(),
        _cell('Оплачено', paid),
      ]),
    );
  }

  Widget _cell(String label, double amount) => Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(label,
                style: const TextStyle(fontSize: 10, color: Colors.white70),
                textAlign: TextAlign.center),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                formatCompact(amount),
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        ),
      );

  Widget _divider() => Container(
        height: 32,
        width: 1,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        color: Colors.white24,
      );
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool hasData;
  final VoidCallback onCreate;
  const _EmptyState({required this.hasData, required this.onCreate});

  @override
  Widget build(BuildContext context) {
    if (hasData) {
      return const Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.filter_list_off, size: 48, color: Colors.grey),
          SizedBox(height: 8),
          Text('Ничего не найдено',
              style: TextStyle(color: Colors.grey, fontSize: 14)),
        ]),
      );
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: kGoldLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.receipt_long_outlined, size: 40, color: kBronze),
          ),
          const SizedBox(height: 20),
          const Text('Накладных пока нет',
              style: TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 17, color: kGraphite)),
          const SizedBox(height: 8),
          Text(
            'Создайте первую накладную — она сохранится здесь и будет доступна для печати',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add),
            label: const Text('Создать накладную'),
            style: FilledButton.styleFrom(
              backgroundColor: kBronze,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─── Invoice tile ─────────────────────────────────────────────────────────────

const _statusColors = {
  InvoiceStatus.draft: Color(0xFFAFA395),
  InvoiceStatus.sent:  Color(0xFFF59E0B),
  InvoiceStatus.paid:  Color(0xFF22C55E),
};

class _InvoiceTile extends StatelessWidget {
  final Invoice invoice;
  final VoidCallback onTap;
  const _InvoiceTile({required this.invoice, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final accentColor = _statusColors[invoice.status] ?? const Color(0xFFAFA395);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: IntrinsicHeight(
            child: Row(children: [
              Container(width: 4, color: accentColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  child: Row(children: [
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Row(children: [
                          _StatusBadge(status: invoice.status),
                          const SizedBox(width: 8),
                          Text(invoice.number,
                              style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 11,
                                  color: Colors.grey.shade500)),
                        ]),
                        const SizedBox(height: 4),
                        Text(invoice.clientName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: kGraphite),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text(
                          '${formatDateShort(invoice.date)} · ${invoice.items.length} поз.',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ]),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      formatCurrency(invoice.total),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: kBronze),
                    ),
                  ]),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final InvoiceStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _statusColors[status] ?? const Color(0xFFAFA395);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        status.label,
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
