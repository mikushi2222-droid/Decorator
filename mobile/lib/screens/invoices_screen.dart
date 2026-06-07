import 'package:flutter/material.dart';
import '../database.dart';
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
  List<Invoice> _all = [];
  List<Invoice> _filtered = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final invoices = await AppDatabase.instance.getInvoices();
    if (!mounted) return;
    setState(() {
      _all = invoices;
      _filtered = _applyFilter(_all);
    });
  }

  List<Invoice> _applyFilter(List<Invoice> source) {
    final q = _searchC.text.toLowerCase();
    if (q.isEmpty) return source;
    return source.where((inv) =>
        inv.number.toLowerCase().contains(q) ||
        inv.clientName.toLowerCase().contains(q)).toList();
  }

  void _filter() => setState(() => _filtered = _applyFilter(_all));

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
    return Column(
      children: [
        // Search + create
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _searchC,
                decoration: InputDecoration(
                  hintText: 'Поиск накладных…',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchC.text.isNotEmpty
                      ? IconButton(icon: const Icon(Icons.clear, size: 18),
                          onPressed: () { _searchC.clear(); _filter(); })
                      : null,
                ),
                onChanged: (_) => _filter(),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: _create,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Создать'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A4A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              ),
            ),
          ]),
        ),

        // List
        Expanded(
          child: _filtered.isEmpty
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    Text(
                      _searchC.text.isNotEmpty ? 'Ничего не найдено' : 'Накладных пока нет',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                    if (_searchC.text.isEmpty) ...[
                      const SizedBox(height: 6),
                      Text('Нажмите «Создать» чтобы оформить первую накладную',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                          textAlign: TextAlign.center),
                    ],
                  ]),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: _filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _InvoiceTile(
                    invoice: _filtered[i],
                    onTap: () => _open(_filtered[i]),
                  ),
                ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _searchC.dispose();
    super.dispose();
  }
}

// ─── Invoice tile ──────────────────────────────────────────────────────────────────────────

const _statusColors = {
  InvoiceStatus.draft: Colors.grey,
  InvoiceStatus.sent:  Color(0xFFF59E0B),
  InvoiceStatus.paid:  Color(0xFF22C55E),
};

class _InvoiceTile extends StatelessWidget {
  final Invoice invoice;
  final VoidCallback onTap;
  const _InvoiceTile({required this.invoice, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final borderColor = _statusColors[invoice.status] ?? Colors.grey;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: IntrinsicHeight(
            child: Row(children: [
              Container(width: 4, color: borderColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  child: Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text('${formatDateShort(invoice.date)} · ${invoice.items.length} поз.',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      ]),
                    ),
                    const SizedBox(width: 8),
                    Text(formatCurrency(invoice.total),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF1E3A4A))),
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
    final color = _statusColors[status] ?? Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(status.label,
          style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }
}
