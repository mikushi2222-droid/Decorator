import 'package:flutter/material.dart';
import '../database.dart';
import '../main.dart';
import '../models.dart';
import '../utils.dart';
import '../services/pdf_service.dart';
import 'invoice_form_screen.dart';

class InvoiceViewScreen extends StatefulWidget {
  final Invoice invoice;
  const InvoiceViewScreen({super.key, required this.invoice});

  @override
  State<InvoiceViewScreen> createState() => _InvoiceViewScreenState();
}

class _InvoiceViewScreenState extends State<InvoiceViewScreen> {
  late Invoice _invoice;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _invoice = widget.invoice;
  }

  Future<void> _changeStatus(InvoiceStatus status) async {
    if (_invoice.id == null) return;
    await AppDatabase.instance.updateInvoiceStatus(_invoice.id!, status);
    if (mounted) setState(() => _invoice = _invoice.copyWith(status: status));
  }

  Future<void> _duplicate() async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => InvoiceFormScreen(templateInvoice: _invoice),
      ),
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Накладная скопирована как черновик')),
      );
    }
  }

  Future<void> _edit() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => InvoiceFormScreen(existingInvoice: _invoice),
      ),
    );
    if (changed == true && mounted) {
      // Перезагружаем обновлённую накладную из БД
      final invoices = await AppDatabase.instance.getInvoices();
      final updated = invoices.where((i) => i.id == _invoice.id).firstOrNull;
      if (updated != null && mounted) setState(() => _invoice = updated);
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Удалить накладную?'),
        content: Text('${_invoice.number} — ${_invoice.clientName}\n\nЭто действие нельзя отменить.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok == true && _invoice.id != null) {
      await AppDatabase.instance.deleteInvoice(_invoice.id!);
      if (mounted) Navigator.pop(context, true);
    }
  }

  Future<void> _exportPDF() async {
    setState(() => _exporting = true);
    try {
      final settings = await AppDatabase.instance.getSettings();
      await PdfService.shareInvoice(_invoice, settings);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка экспорта PDF: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        title: Text(_invoice.number),
        actions: [
          if (_exporting)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
            )
          else
            IconButton(
              onPressed: _exportPDF,
              icon: const Icon(Icons.picture_as_pdf_outlined),
              tooltip: 'Скачать PDF',
            ),
          IconButton(
            onPressed: _edit,
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Редактировать',
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'duplicate') _duplicate();
              if (v == 'delete') _delete();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'duplicate',
                child: Row(children: [
                  Icon(Icons.copy_outlined, size: 20),
                  SizedBox(width: 12),
                  Text('Дублировать'),
                ]),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(children: [
                  Icon(Icons.delete_outline, size: 20, color: Colors.red.shade600),
                  const SizedBox(width: 12),
                  Text('Удалить', style: TextStyle(color: Colors.red.shade600)),
                ]),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // Header card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // Logo top-left
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      'assets/logo_akcent.jpg',
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: kGoldLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.brush_outlined, color: kBronze),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(_invoice.number,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold, color: kBronze)),
                      const SizedBox(height: 2),
                      Text(formatDate(_invoice.date),
                          style: const TextStyle(color: Color(0xFFB0A090), fontSize: 13)),
                    ]),
                  ),
                  _StatusChip(status: _invoice.status),
                ]),
                const Divider(height: 20),
                const Text('ПОКУПАТЕЛЬ', style: TextStyle(fontSize: 11, color: Color(0xFFB0A090), letterSpacing: 1)),
                const SizedBox(height: 4),
                Text(_invoice.clientName,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kGraphite)),
                if (_invoice.clientPhone.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(_invoice.clientPhone, style: const TextStyle(color: Color(0xFF9E9585))),
                ],
                if (_invoice.clientAddress.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(_invoice.clientAddress, style: const TextStyle(color: Color(0xFF9E9585))),
                ],
              ]),
            ),
          ),
          const SizedBox(height: 12),

          // Items
          Card(
            child: Column(children: [
              Container(
                decoration: const BoxDecoration(
                  color: kBronze,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: const Row(children: [
                  Expanded(flex: 5, child: Text('Наименование',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                  SizedBox(width: 4),
                  Expanded(flex: 2, child: Text('Цена',
                      style: TextStyle(color: Colors.white, fontSize: 11), textAlign: TextAlign.right)),
                  SizedBox(width: 4),
                  Expanded(flex: 2, child: Text('Сумма',
                      style: TextStyle(color: Colors.white, fontSize: 11), textAlign: TextAlign.right)),
                ]),
              ),
              ..._invoice.items.asMap().entries.map((e) => Container(
                    decoration: BoxDecoration(
                      color: e.key.isOdd ? kGoldLight : null,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Expanded(
                        flex: 5,
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(e.value.productName, style: const TextStyle(fontSize: 13)),
                          Text('× ${formatNumber(e.value.quantity)} ${e.value.unit}',
                              style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                        ]),
                      ),
                      const SizedBox(width: 4),
                      Expanded(flex: 2,
                          child: Text(formatCurrency(e.value.price),
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                              textAlign: TextAlign.right)),
                      const SizedBox(width: 4),
                      Expanded(flex: 2,
                          child: Text(formatCurrency(e.value.total),
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              textAlign: TextAlign.right)),
                    ]),
                  )),
            ]),
          ),
          const SizedBox(height: 12),

          // Totals
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(children: [
                _totRow('Подытог', formatCurrency(_invoice.subtotal)),
                if (_invoice.discount > 0)
                  _totRow('Скидка', '−${formatCurrency(_invoice.discount)}',
                      valueColor: Colors.red.shade700),
                const Divider(height: 16),
                Row(children: [
                  const Expanded(child: Text('ИТОГО', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: kGraphite))),
                  Text(formatCurrency(_invoice.total),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 22, color: kBronze)),
                ]),
              ]),
            ),
          ),
          if (_invoice.notes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Примечания', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  const SizedBox(height: 4),
                  Text(_invoice.notes, style: const TextStyle(fontStyle: FontStyle.italic)),
                ]),
              ),
            ),
          ],
          const SizedBox(height: 16),

          // Status change
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const Text('Статус накладной',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: kGraphite)),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: _statusBtn('Черновик', InvoiceStatus.draft, Colors.grey)),
                  const SizedBox(width: 8),
                  Expanded(child: _statusBtn('Выставлена', InvoiceStatus.sent, const Color(0xFFF59E0B))),
                  const SizedBox(width: 8),
                  Expanded(child: _statusBtn('Оплачена', InvoiceStatus.paid, const Color(0xFF22C55E))),
                ]),
              ]),
            ),
          ),
          const SizedBox(height: 12),

          ElevatedButton.icon(
            onPressed: _exporting ? null : _exportPDF,
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Скачать PDF накладную'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              textStyle: const TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }

  Widget _totRow(String label, String value, {Color? valueColor}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          Expanded(child: Text(label, style: const TextStyle(color: Color(0xFF9E9585)))),
          Text(value,
              style: TextStyle(fontWeight: FontWeight.w600, color: valueColor ?? kGraphite)),
        ]),
      );

  Widget _statusBtn(String label, InvoiceStatus status, Color color) {
    final active = _invoice.status == status;
    return GestureDetector(
      onTap: () => _changeStatus(status),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: active ? color : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: active ? color : color.withOpacity(0.3)),
        ),
        child: Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: active ? Colors.white : color)),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final InvoiceStatus status;
  const _StatusChip({required this.status});

  static const _colors = {
    InvoiceStatus.draft: Colors.grey,
    InvoiceStatus.sent:  Color(0xFFF59E0B),
    InvoiceStatus.paid:  Color(0xFF22C55E),
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[status] ?? Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(status.label,
          style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
    );
  }
}
