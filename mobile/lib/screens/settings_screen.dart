import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../database.dart';
import '../main.dart';
import '../models.dart';
import '../utils.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('Настройки',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kGraphite)),
          ),
        ),
        TabBar(
          controller: _tabs,
          tabs: const [
            Tab(icon: Icon(Icons.store, size: 18), text: 'Реквизиты'),
            Tab(icon: Icon(Icons.inventory_2_outlined, size: 18), text: 'Товары'),
            Tab(icon: Icon(Icons.construction_outlined, size: 18), text: 'Работы'),
          ],
          labelColor: kBronze,
          indicatorColor: kBronze,
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: const [
              _StoreSettingsTab(),
              _ProductsTab(),
              _LaborTab(),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }
}

// ─── Store settings tab ─────────────────────────────────────────────────────────────────────

class _StoreSettingsTab extends StatefulWidget {
  const _StoreSettingsTab();

  @override
  State<_StoreSettingsTab> createState() => _StoreSettingsTabState();
}

class _StoreSettingsTabState extends State<_StoreSettingsTab> {
  StoreSettings? _settings;
  final _controllers = <String, TextEditingController>{};
  final _decoratorNameC = TextEditingController();
  String _businessType = 'ooo';
  bool _saved = false;

  static const _businessTypes = [
    ('ip', 'ИП'),
    ('samozanyat', 'Самозанятый'),
    ('ooo', 'ООО'),
    ('fizlico', 'Физлицо'),
  ];

  static const _fields = [
    ('name',            'Наименование организации',   false),
    ('address',         'Адрес',                      false),
    ('phone',           'Телефон',                    false),
    ('inn',             'ИНН',                        false),
    ('kpp',             'КПП',                        false),
    ('ogrn',            'ОГРН',                       false),
    ('bankName',        'Банк',                       false),
    ('bankBik',         'БИК банка',                  false),
    ('bankAccount',     'Расчётный счёт',              false),
    ('bankCorrAccount', 'Корр. счёт',                  false),
    ('bankInn',         'ИНН банка',                  false),
    ('bankKpp',         'КПП банка',                  false),
    ('adText',          'Реклама на накладных',        true),
  ];

  @override
  void initState() {
    super.initState();
    for (final f in _fields) _controllers[f.$1] = TextEditingController();
    _load();
  }

  Future<void> _load() async {
    final s = await AppDatabase.instance.getSettings();
    if (!mounted) return;
    setState(() {
      _settings = s;
      _decoratorNameC.text                  = s.decoratorName;
      _businessType                         = s.businessType.isEmpty ? 'ooo' : s.businessType;
      _controllers['name']!.text            = s.name;
      _controllers['address']!.text         = s.address;
      _controllers['phone']!.text           = s.phone;
      _controllers['inn']!.text             = s.inn;
      _controllers['kpp']!.text             = s.kpp;
      _controllers['ogrn']!.text            = s.ogrn;
      _controllers['bankName']!.text        = s.bankName;
      _controllers['bankBik']!.text         = s.bankBik;
      _controllers['bankAccount']!.text     = s.bankAccount;
      _controllers['bankCorrAccount']!.text = s.bankCorrAccount;
      _controllers['bankInn']!.text         = s.bankInn;
      _controllers['bankKpp']!.text         = s.bankKpp;
      _controllers['adText']!.text          = s.adText;
    });
  }

  Future<void> _save() async {
    final s = _settings ?? StoreSettings.defaults();
    final updated = s.copyWith(
      decoratorName:   _decoratorNameC.text.trim(),
      businessType:    _businessType,
      name:            _controllers['name']!.text,
      address:         _controllers['address']!.text,
      phone:           _controllers['phone']!.text,
      inn:             _controllers['inn']!.text,
      kpp:             _controllers['kpp']!.text,
      ogrn:            _controllers['ogrn']!.text,
      bankName:        _controllers['bankName']!.text,
      bankBik:         _controllers['bankBik']!.text,
      bankAccount:     _controllers['bankAccount']!.text,
      bankCorrAccount: _controllers['bankCorrAccount']!.text,
      bankInn:         _controllers['bankInn']!.text,
      bankKpp:         _controllers['bankKpp']!.text,
      adText:          _controllers['adText']!.text,
    );
    await AppDatabase.instance.saveSettings(updated);
    if (!mounted) return;
    setState(() { _settings = updated; _saved = true; });
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _saved = false);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // ── Профиль декоратора ──────────────────────────────────────────
        const Text('Профиль декоратора',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: kBronze)),
        const SizedBox(height: 10),
        TextFormField(
          controller: _decoratorNameC,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Ваше имя',
            hintText: 'Имя в шапке PDF-накладных',
            prefixIcon: Icon(Icons.person_outline, size: 20),
          ),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          value: _businessType,
          decoration: const InputDecoration(
            labelText: 'Тип деятельности',
            prefixIcon: Icon(Icons.business_center_outlined, size: 20),
          ),
          items: _businessTypes
              .map((t) => DropdownMenuItem(value: t.$1, child: Text(t.$2)))
              .toList(),
          onChanged: (v) => setState(() => _businessType = v ?? 'ooo'),
        ),
        const SizedBox(height: 18),
        const Divider(),
        const SizedBox(height: 12),
        const Text('Реквизиты организации',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: kBronze)),
        const SizedBox(height: 10),
        for (final f in _fields) ...[
          TextFormField(
            controller: _controllers[f.$1],
            maxLines: f.$3 ? 2 : 1,
            decoration: InputDecoration(labelText: f.$2),
          ),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 6),
        ElevatedButton.icon(
          onPressed: _save,
          icon: Icon(_saved ? Icons.check : Icons.save),
          label: Text(_saved ? 'Сохранено!' : 'Сохранить реквизиты'),
        ),
        const SizedBox(height: 24),
      ]),
    );
  }

  @override
  void dispose() {
    _decoratorNameC.dispose();
    for (final c in _controllers.values) c.dispose();
    super.dispose();
  }
}

// ─── Products tab ─────────────────────────────────────────────────────────────────────────────

class _ProductsTab extends StatefulWidget {
  const _ProductsTab();

  @override
  State<_ProductsTab> createState() => _ProductsTabState();
}

class _ProductsTabState extends State<_ProductsTab> {
  final _searchC = TextEditingController();
  List<Product> _products = [];
  List<String> _categories = ['Все'];
  String _activeCategory = 'Все';
  int _total = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _search();
  }

  Future<void> _loadCategories() async {
    final cats = await AppDatabase.instance.getCategories();
    final count = await AppDatabase.instance.countProducts();
    if (!mounted) return;
    setState(() {
      _categories = ['Все', ...cats];
      _total = count;
    });
  }

  Future<void> _search() async {
    setState(() => _loading = true);
    final cat = _activeCategory == 'Все' ? null : _activeCategory;
    final res = await AppDatabase.instance.searchProducts(_searchC.text, category: cat);
    if (!mounted) return;
    setState(() { _products = res; _loading = false; });
  }

  Future<void> _showProductDialog([Product? existing]) async {
    final isEdit = existing != null;
    final nameC     = TextEditingController(text: existing?.name ?? '');
    final unitC     = TextEditingController(text: existing?.unit ?? 'кг');
    final priceC    = TextEditingController(text: existing != null ? existing.price.toStringAsFixed(2) : '');
    final coverageC = TextEditingController(text: existing != null && existing.coverage > 0 ? existing.coverage.toString() : '');
    final packSizeC = TextEditingController(text: existing != null && existing.packSize > 0 ? existing.packSize.toString() : '');
    final catC      = TextEditingController(text: existing?.category ?? '');
    final descC     = TextEditingController(text: existing?.description ?? '');

    bool changed = false;
    try {
      changed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(isEdit ? 'Редактировать товар' : 'Добавить товар'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: nameC, decoration: const InputDecoration(labelText: 'Название *')),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: TextField(controller: unitC, decoration: const InputDecoration(labelText: 'Ед.'))),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: priceC, keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Цена, ₽ *'))),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: TextField(controller: coverageC, keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Расход кг/м²'))),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: packSizeC, keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Фасовка кг'))),
              ]),
              const SizedBox(height: 8),
              TextField(controller: catC, decoration: const InputDecoration(labelText: 'Категория')),
              const SizedBox(height: 8),
              TextField(controller: descC, decoration: const InputDecoration(labelText: 'Описание')),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
            TextButton(
              onPressed: () async {
                if (nameC.text.trim().isEmpty || priceC.text.isEmpty) return;
                final product = Product(
                  id:          existing?.id,
                  name:        nameC.text.trim(),
                  unit:        unitC.text.trim(),
                  price:       double.tryParse(priceC.text) ?? 0,
                  coverage:    double.tryParse(coverageC.text) ?? 0,
                  packSize:    double.tryParse(packSizeC.text) ?? 0,
                  category:    catC.text.trim(),
                  description: descC.text.trim(),
                );
                if (isEdit) {
                  await AppDatabase.instance.updateProduct(product);
                } else {
                  await AppDatabase.instance.insertProduct(product);
                }
                if (context.mounted) Navigator.pop(context, true);
              },
              child: Text(isEdit ? 'Сохранить' : 'Добавить'),
            ),
          ],
        ),
      ) == true;
    } finally {
      nameC.dispose(); unitC.dispose(); priceC.dispose();
      coverageC.dispose(); packSizeC.dispose(); catC.dispose(); descC.dispose();
    }
    if (changed) { _loadCategories(); _search(); }
  }

  Future<void> _exportCsv() async {
    final all = await AppDatabase.instance.getProducts();
    final csv = productsAsCsv(all);
    try {
      final dir  = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/products_export.csv');
      await file.writeAsString(csv);
      if (!mounted) return;
      await Clipboard.setData(ClipboardData(text: file.path));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Файл сохранён:\n${file.path}\n(путь скопирован в буфер)'),
        duration: const Duration(seconds: 5),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Ошибка экспорта: $e'),
        backgroundColor: Colors.red,
      ));
    }
  }

  Future<void> _showImportDialog() async {
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Импорт CSV'),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Формат: name,unit,price,coverage,pack_size,category,description',
              style: TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            maxLines: 8,
            decoration: const InputDecoration(
              hintText: 'Вставьте содержимое CSV-файла…',
              border: OutlineInputBorder(),
            ),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Импортировать'),
          ),
        ],
      ),
    );

    if (ok != true || !mounted) { controller.dispose(); return; }
    final rows = parseCsvProducts(controller.text);
    controller.dispose();

    if (rows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Нет данных для импорта'), backgroundColor: Colors.orange));
      return;
    }

    final db = AppDatabase.instance;
    int count = 0;
    for (final r in rows) {
      if ((r['name'] as String).isEmpty) continue;
      await db.insertProduct(Product(
        name:        r['name'] as String,
        unit:        r['unit'] as String,
        price:       (r['price'] as num).toDouble(),
        coverage:    (r['coverage'] as num).toDouble(),
        packSize:    (r['pack_size'] as num).toDouble(),
        category:    r['category'] as String,
        description: r['description'] as String,
      ));
      count++;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Импортировано $count товаров')));
    _loadCategories();
    _search();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _searchC,
                decoration: InputDecoration(
                  hintText: 'Поиск (всего $_total позиций)…',
                  prefixIcon: const Icon(Icons.search, size: 18),
                  isDense: true,
                  suffixIcon: _searchC.text.isNotEmpty
                      ? IconButton(icon: const Icon(Icons.clear, size: 16),
                          onPressed: () { _searchC.clear(); _search(); })
                      : null,
                ),
                onChanged: (_) => _search(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: () => _showProductDialog(),
              icon: const Icon(Icons.add),
              tooltip: 'Добавить товар',
              style: IconButton.styleFrom(backgroundColor: kBronze, foregroundColor: Colors.white),
            ),
            const SizedBox(width: 4),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (v) {
                if (v == 'export') _exportCsv();
                if (v == 'import') _showImportDialog();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'export', child: Row(children: [
                  Icon(Icons.download_outlined, size: 18), SizedBox(width: 8), Text('Экспорт CSV'),
                ])),
                PopupMenuItem(value: 'import', child: Row(children: [
                  Icon(Icons.upload_outlined, size: 18), SizedBox(width: 8), Text('Импорт CSV'),
                ])),
              ],
            ),
          ]),
        ),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            itemCount: _categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemBuilder: (_, i) {
              final cat = _categories[i];
              final active = cat == _activeCategory;
              return FilterChip(
                label: Text(cat, style: const TextStyle(fontSize: 11)),
                selected: active,
                onSelected: (_) { setState(() => _activeCategory = cat); _search(); },
                selectedColor: kBronze,
                labelStyle: TextStyle(color: active ? Colors.white : null),
                showCheckmark: false,
                padding: const EdgeInsets.symmetric(horizontal: 2),
                visualDensity: VisualDensity.compact,
              );
            },
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: _products.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final p = _products[i];
                    return ListTile(
                      dense: true,
                      title: Text(p.name, style: const TextStyle(fontSize: 13)),
                      subtitle: Text(
                        '${formatCurrency(p.price)} / ${p.unit}${p.category.isNotEmpty ? " · ${p.category}" : ""}',
                        style: const TextStyle(fontSize: 11),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18, color: kBronze),
                            onPressed: () => _showProductDialog(p),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () async {
                              final ok = await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('Удалить товар?'),
                                  content: Text(p.name),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
                                    TextButton(onPressed: () => Navigator.pop(context, true),
                                        child: const Text('Удалить', style: TextStyle(color: Colors.red))),
                                  ],
                                ),
                              );
                              if (ok == true && p.id != null) {
                                await AppDatabase.instance.deleteProduct(p.id!);
                                _loadCategories();
                                _search();
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  },
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

// ─── Labor tab ───────────────────────────────────────────────────────────────────────────────

class _LaborTab extends StatefulWidget {
  const _LaborTab();

  @override
  State<_LaborTab> createState() => _LaborTabState();
}

class _LaborTabState extends State<_LaborTab> {
  List<LaborRate> _rates = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rates = await AppDatabase.instance.getLaborRates();
    if (!mounted) return;
    setState(() => _rates = rates);
  }

  Future<void> _showAddDialog() async {
    final nameC = TextEditingController();
    final priceC = TextEditingController();
    final unitC = TextEditingController(text: 'м²');
    bool inserted = false;
    try {
      inserted = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Добавить вид работ'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: nameC, decoration: const InputDecoration(labelText: 'Название *')),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: TextField(controller: priceC, keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Ставка, ₽ *'))),
              const SizedBox(width: 8),
              Expanded(child: TextField(controller: unitC, decoration: const InputDecoration(labelText: 'Ед.'))),
            ]),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
            TextButton(
              onPressed: () async {
                if (nameC.text.trim().isEmpty || priceC.text.isEmpty) return;
                await AppDatabase.instance.insertLaborRate(LaborRate(
                  name: nameC.text.trim(),
                  pricePerSqm: double.tryParse(priceC.text) ?? 0,
                  unit: unitC.text.trim(),
                ));
                if (context.mounted) Navigator.pop(context, true);
              },
              child: const Text('Добавить'),
            ),
          ],
        ),
      ) == true;
    } finally {
      nameC.dispose();
      priceC.dispose();
      unitC.dispose();
    }
    if (inserted) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(children: [
            const Expanded(child: Text('Ставки работ',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
            FilledButton.icon(
              onPressed: _showAddDialog,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Добавить'),
              style: FilledButton.styleFrom(
                backgroundColor: kBronze,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ]),
        ),
        Expanded(
          child: _rates.isEmpty
              ? const Center(child: Text('Нет ставок. Нажмите «Добавить».'))
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _rates.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final r = _rates[i];
                    return ListTile(
                      title: Text(r.name, style: const TextStyle(fontSize: 14)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${formatCurrency(r.pricePerSqm)} за ${r.unit}',
                              style: const TextStyle(fontSize: 12)),
                          if (r.hasMarketData)
                            Text(
                              'Рынок: от ${formatCurrency(r.marketMin)} · медиана ${formatCurrency(r.marketMedian)} · макс ${formatCurrency(r.marketMax)}',
                              style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                            ),
                        ],
                      ),
                      isThreeLine: r.hasMarketData,
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                        onPressed: () async {
                          if (r.id == null) return;
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Удалить ставку?'),
                              content: Text(r.name),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Удалить', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                          if (ok == true) {
                            await AppDatabase.instance.deleteLaborRate(r.id!);
                            _load();
                          }
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
