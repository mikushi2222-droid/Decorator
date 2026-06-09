import 'package:flutter/material.dart';
import '../database.dart';
import '../main.dart';
import '../models.dart';
import '../utils.dart';

class InvoiceFormScreen extends StatefulWidget {
  final Invoice? existingInvoice;   // null = новая, non-null = редактирование
  final Invoice? templateInvoice;   // дублирование: копирует клиента и позиции
  final Product? fromProduct;       // быстрое создание из каталога
  const InvoiceFormScreen({
    super.key,
    this.existingInvoice,
    this.templateInvoice,
    this.fromProduct,
  });

  @override
  State<InvoiceFormScreen> createState() => _InvoiceFormScreenState();
}

class _InvoiceFormScreenState extends State<InvoiceFormScreen> {
  final _clientNameC    = TextEditingController();
  final _clientPhoneC   = TextEditingController();
  final _clientAddressC = TextEditingController();
  final _notesC         = TextEditingController();
  final _discountC      = TextEditingController();

  DateTime _date = DateTime.now();
  late List<_ItemEntry> _items;
  bool _saving = false;

  // Поиск по каталогу
  final _productSearchC = TextEditingController();
  List<Product> _productSuggestions = [];
  Object? _productSearchToken;

  // Автодополнение клиентов
  final _clientNameFocus = FocusNode();
  List<Client> _clientSuggestions = [];
  Object? _clientSearchToken;

  bool get _isEdit => widget.existingInvoice != null;

  @override
  void initState() {
    super.initState();
    _clientNameFocus.addListener(_onClientFocus);
    final inv = widget.existingInvoice;
    if (inv != null) {
      // Режим редактирования
      _clientNameC.text    = inv.clientName;
      _clientPhoneC.text   = inv.clientPhone;
      _clientAddressC.text = inv.clientAddress;
      _date                = inv.date;
      if (inv.discount > 0) _discountC.text = _fmtQty(inv.discount);
      _notesC.text = inv.notes;
      _items = inv.items.map((item) => _ItemEntry(
        productId: item.productId,
        nameC:  TextEditingController(text: item.productName),
        unitC:  TextEditingController(text: item.unit),
        qtyC:   TextEditingController(text: _fmtQty(item.quantity)),
        priceC: TextEditingController(text: item.price.toStringAsFixed(2)),
      )).toList();
      if (_items.isEmpty) _items = [_ItemEntry()];
    } else if (widget.templateInvoice != null) {
      final tmpl = widget.templateInvoice!;
      _clientNameC.text    = tmpl.clientName;
      _clientPhoneC.text   = tmpl.clientPhone;
      _clientAddressC.text = tmpl.clientAddress;
      if (tmpl.discount > 0) _discountC.text = _fmtQty(tmpl.discount);
      _notesC.text = tmpl.notes;
      _items = tmpl.items.map((item) => _ItemEntry(
        productId: item.productId,
        nameC:  TextEditingController(text: item.productName),
        unitC:  TextEditingController(text: item.unit),
        qtyC:   TextEditingController(text: _fmtQty(item.quantity)),
        priceC: TextEditingController(text: item.price.toStringAsFixed(2)),
      )).toList();
      if (_items.isEmpty) _items = [_ItemEntry()];
    } else if (widget.fromProduct != null) {
      final p = widget.fromProduct!;
      _items = [_ItemEntry(
        productId: p.id,
        nameC:  TextEditingController(text: p.name),
        unitC:  TextEditingController(text: p.unit),
        qtyC:   TextEditingController(text: '1'),
        priceC: TextEditingController(text: p.price.toStringAsFixed(2)),
      )];
    } else {
      _items = [_ItemEntry()];
    }
  }

  String _fmtQty(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  // ── Поиск товаров ──────────────────────────────────────────────────────────

  void _searchProducts(String q) async {
    if (q.isEmpty) { setState(() => _productSuggestions = []); return; }
    final token = Object();
    _productSearchToken = token;
    final res = await AppDatabase.instance.searchProducts(q);
    if (!mounted || _productSearchToken != token) return;
    setState(() => _productSuggestions = res.take(30).toList());
  }

  void _addProductFromCatalog(Product p) {
    setState(() {
      _items.add(_ItemEntry(
        productId: p.id,
        nameC:  TextEditingController(text: p.name),
        unitC:  TextEditingController(text: p.unit),
        qtyC:   TextEditingController(text: '1'),
        priceC: TextEditingController(text: p.price.toStringAsFixed(2)),
      ));
      _productSuggestions = [];
      _productSearchC.clear();
    });
  }

  // ── Автодополнение клиентов ────────────────────────────────────────────────

  void _onClientFocus() {
    if (_clientNameFocus.hasFocus && _clientNameC.text.isEmpty) {
      _loadRecentClients();
    }
  }

  void _loadRecentClients() async {
    final token = Object();
    _clientSearchToken = token;
    final res = await AppDatabase.instance.getAllClients();
    if (!mounted || _clientSearchToken != token) return;
    setState(() => _clientSuggestions = res.take(5).toList());
  }

  void _searchClients(String q) async {
    if (q.isEmpty) { _loadRecentClients(); return; }
    final token = Object();
    _clientSearchToken = token;
    final res = await AppDatabase.instance.searchClients(q);
    if (!mounted || _clientSearchToken != token) return;
    setState(() => _clientSuggestions = res);
  }

  void _selectClient(Client c) {
    setState(() {
      _clientNameC.text    = c.name;
      _clientPhoneC.text   = c.phone;
      _clientAddressC.text = c.address;
      _clientSuggestions   = [];
    });
  }

  // ── Вычисления ─────────────────────────────────────────────────────────────

  double get _subtotal =>
      _items.fold(0, (s, i) => s + (parseNum(i.qtyC.text) ?? 0) * (parseNum(i.priceC.text) ?? 0));
  // Скидка не может быть отрицательной и не больше подытога.
  double get _discountAmt => (parseNum(_discountC.text) ?? 0).clamp(0, _subtotal);
  double get _total => (_subtotal - _discountAmt).clamp(0, double.infinity);

  // ── Сохранение ─────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (_clientNameC.text.trim().isEmpty) {
      _showError('Укажите имя клиента');
      return;
    }
    if (_items.any((i) => i.nameC.text.trim().isEmpty)) {
      _showError('Заполните название во всех позициях');
      return;
    }
    // Проверяем, что количество и цена — корректные неотрицательные числа.
    for (var k = 0; k < _items.length; k++) {
      final i = _items[k];
      final qty = parseNum(i.qtyC.text);
      final price = parseNum(i.priceC.text);
      if (qty == null || qty <= 0) {
        _showError('Позиция ${k + 1}: укажите количество больше нуля');
        return;
      }
      if (price == null || price < 0) {
        _showError('Позиция ${k + 1}: цена указана неверно');
        return;
      }
    }
    setState(() => _saving = true);
    try {
      final db = AppDatabase.instance;
      final invoiceItems = _items.map((i) => InvoiceItem(
        productId:   i.productId,
        productName: i.nameC.text.trim(),
        unit:        i.unitC.text.trim().isEmpty ? 'шт.' : i.unitC.text.trim(),
        quantity:    parseNum(i.qtyC.text) ?? 1,
        price:       parseNum(i.priceC.text) ?? 0,
      )).toList();

      if (_isEdit) {
        final updated = widget.existingInvoice!.copyWith(
          date:          _date,
          clientName:    _clientNameC.text.trim(),
          clientPhone:   _clientPhoneC.text.trim(),
          clientAddress: _clientAddressC.text.trim(),
          items:         invoiceItems,
          subtotal:      _subtotal,
          discount:      _discountAmt,
          total:         _total,
          notes:         _notesC.text.trim(),
        );
        await db.updateInvoice(updated);
      } else {
        await db.createInvoiceWithNumber((number) => Invoice(
          number:        number,
          date:          _date,
          clientName:    _clientNameC.text.trim(),
          clientPhone:   _clientPhoneC.text.trim(),
          clientAddress: _clientAddressC.text.trim(),
          items:         invoiceItems,
          subtotal:      _subtotal,
          discount:      _discountAmt,
          total:         _total,
          status:        InvoiceStatus.draft,
          notes:         _notesC.text.trim(),
          createdAt:     DateTime.now(),
        ));
      }

      // Автосохранение клиента в базу
      await db.upsertClient(Client(
        name:    _clientNameC.text.trim(),
        phone:   _clientPhoneC.text.trim(),
        address: _clientAddressC.text.trim(),
      ));

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) _showError('Ошибка сохранения: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Редактировать накладную' : 'Новая накладная'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Сохранить', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [

          // ── Шаг 1: Данные клиента ─────────────────────────────────────────
          _card('Шаг 1 — Данные клиента', [
            // Поле с автодополнением
            TextFormField(
              controller: _clientNameC,
              focusNode: _clientNameFocus,
              decoration: const InputDecoration(
                labelText: 'Имя / Организация *',
                hintText: 'Иванов Иван Иванович',
                suffixIcon: Icon(Icons.person_outline, size: 18),
              ),
              onChanged: (v) { setState(() {}); _searchClients(v); },
            ),
            if (_clientSuggestions.isNotEmpty) ...[
              const SizedBox(height: 4),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                constraints: const BoxConstraints(maxHeight: 160),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _clientSuggestions.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final c = _clientSuggestions[i];
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.person, size: 18, color: kBronze),
                      title: Text(c.name, style: const TextStyle(fontSize: 13)),
                      subtitle: c.phone.isNotEmpty ? Text(c.phone, style: const TextStyle(fontSize: 11)) : null,
                      onTap: () => _selectClient(c),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 8),
            _tf('Телефон', _clientPhoneC, keyboard: TextInputType.phone),
            const SizedBox(height: 8),
            _tf('Адрес объекта', _clientAddressC),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                  locale: const Locale('ru', 'RU'),
                );
                if (picked != null) setState(() => _date = picked);
              },
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Дата накладной'),
                child: Row(children: [
                  const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(formatDate(_date)),
                ]),
              ),
            ),
          ]),
          const SizedBox(height: 12),

          // ── Шаг 2: Товары ─────────────────────────────────────────────────
          _card('Шаг 2 — Товары', [
            TextField(
              controller: _productSearchC,
              decoration: const InputDecoration(
                hintText: 'Поиск товара в каталоге…',
                prefixIcon: Icon(Icons.search, size: 18),
              ),
              onChanged: _searchProducts,
            ),
            if (_productSuggestions.isNotEmpty) ...[
              const SizedBox(height: 4),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _productSuggestions.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final p = _productSuggestions[i];
                    return ListTile(
                      dense: true,
                      title: Text(p.name, style: const TextStyle(fontSize: 13)),
                      subtitle: Text('${formatCurrency(p.price)} / ${p.unit}',
                          style: const TextStyle(fontSize: 11)),
                      trailing: const Icon(Icons.add_circle_outline, size: 20),
                      onTap: () => _addProductFromCatalog(p),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 12),
            ..._items.asMap().entries.map((e) => _ItemRow(
              index: e.key,
              entry: e.value,
              onDelete: _items.length > 1 ? () => setState(() => _items.removeAt(e.key)) : null,
              onChanged: () => setState(() {}),
            )),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => setState(() => _items.add(_ItemEntry())),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Добавить строку'),
            ),
          ]),
          const SizedBox(height: 12),

          // ── Шаг 3: Итого ──────────────────────────────────────────────────
          _card('Шаг 3 — Итого', [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Подытог:', style: TextStyle(color: Colors.grey)),
              Text(formatCurrency(_subtotal)),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              const Expanded(child: Text('Скидка, ₽:', style: TextStyle(color: Colors.grey))),
              SizedBox(
                width: 120,
                child: TextFormField(
                  controller: _discountC,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(hintText: '0'),
                  textAlign: TextAlign.right,
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ]),
            const Divider(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('К оплате:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(formatCurrency(_total),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 20, color: kBronze)),
            ]),
          ]),
          const SizedBox(height: 12),

          // ── Примечания ────────────────────────────────────────────────────
          _card('Примечания', [
            TextFormField(
              controller: _notesC,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Условия оплаты, срок, особые договорённости…',
                border: OutlineInputBorder(),
              ),
            ),
          ]),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }

  Widget _card(String title, List<Widget> children) => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Container(
                width: 3,
                height: 16,
                decoration: BoxDecoration(
                  color: kBronze,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14, color: kGraphite)),
            ]),
            const SizedBox(height: 12),
            ...children,
          ]),
        ),
      );

  Widget _tf(String label, TextEditingController c,
      {TextInputType? keyboard, String? hint}) =>
      TextFormField(
        controller: c,
        keyboardType: keyboard,
        decoration: InputDecoration(labelText: label, hintText: hint),
        onChanged: (_) => setState(() {}),
      );

  @override
  void dispose() {
    _clientNameFocus.removeListener(_onClientFocus);
    _clientNameFocus.dispose();
    _clientNameC.dispose(); _clientPhoneC.dispose(); _clientAddressC.dispose();
    _notesC.dispose(); _discountC.dispose(); _productSearchC.dispose();
    for (final i in _items) i.dispose();
    super.dispose();
  }
}

// ─── Item row ──────────────────────────────────────────────────────────────────

class _ItemEntry {
  final int? productId;
  final TextEditingController nameC;
  final TextEditingController unitC;
  final TextEditingController qtyC;
  final TextEditingController priceC;

  _ItemEntry({
    this.productId,
    TextEditingController? nameC,
    TextEditingController? unitC,
    TextEditingController? qtyC,
    TextEditingController? priceC,
  })  : nameC  = nameC  ?? TextEditingController(),
        unitC  = unitC  ?? TextEditingController(text: 'шт.'),
        qtyC   = qtyC   ?? TextEditingController(text: '1'),
        priceC = priceC ?? TextEditingController(text: '0');

  void dispose() { nameC.dispose(); unitC.dispose(); qtyC.dispose(); priceC.dispose(); }
}

class _ItemRow extends StatelessWidget {
  final int index;
  final _ItemEntry entry;
  final VoidCallback? onDelete;
  final VoidCallback onChanged;

  const _ItemRow({required this.index, required this.entry, this.onDelete, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final qty   = parseNum(entry.qtyC.text) ?? 0;
    final price = parseNum(entry.priceC.text) ?? 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Text('Позиция ${index + 1}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
          const Spacer(),
          if (onDelete != null)
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline, size: 20),
              color: Colors.redAccent,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ]),
        const SizedBox(height: 6),
        TextFormField(
          controller: entry.nameC,
          decoration: const InputDecoration(
            hintText: 'Название товара или услуги',
            isDense: true,
          ),
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: 6),
        Row(children: [
          Expanded(
            child: TextFormField(
              controller: entry.qtyC,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Кол-во', isDense: true),
              onChanged: (_) => onChanged(),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: TextFormField(
              controller: entry.unitC,
              decoration: const InputDecoration(labelText: 'Ед.', isDense: true),
              onChanged: (_) => onChanged(),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: entry.priceC,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Цена, ₽', isDense: true),
              onChanged: (_) => onChanged(),
            ),
          ),
        ]),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            'Сумма: ${formatCurrency(qty * price)}',
            style: const TextStyle(fontWeight: FontWeight.w600, color: kBronze, fontSize: 13),
          ),
        ),
      ]),
    );
  }
}
