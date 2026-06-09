import 'package:flutter/material.dart';
import '../main.dart';
import '../database.dart';
import '../models.dart';
import '../utils.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final _searchC = TextEditingController();
  String _activeCategory = 'Все';
  List<String> _categories = ['Все'];
  List<Product> _products = [];
  int _total = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _search();
    // Обновляем каталог при изменении товаров в Настройках (IndexedStack
    // держит экран живым, иначе список был бы устаревшим до перезапуска).
    AppDatabase.instance.dataRevision.addListener(_onDataChanged);
  }

  void _onDataChanged() {
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

  Object? _searchToken;

  Future<void> _search() async {
    setState(() => _loading = true);
    final cat = _activeCategory == 'Все' ? null : _activeCategory;
    // Защита от гонки: при быстром наборе ранний (медленный) запрос не должен
    // перезаписать результат более позднего.
    final token = Object();
    _searchToken = token;
    final results = await AppDatabase.instance.searchProducts(_searchC.text, category: cat);
    if (!mounted || _searchToken != token) return;
    setState(() {
      _products = results;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('Каталог товаров',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kGraphite)),
          ),
        ),

        // Search bar
        Container(
          color: Theme.of(context).colorScheme.surface,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
          child: TextField(
            controller: _searchC,
            decoration: InputDecoration(
              hintText: 'Поиск по каталогу ($_total позиций)…',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchC.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () { _searchC.clear(); _search(); },
                    )
                  : null,
            ),
            onChanged: (_) => _search(),
          ),
        ),

        // Category chips
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            itemCount: _categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemBuilder: (_, i) {
              final cat = _categories[i];
              final active = cat == _activeCategory;
              return FilterChip(
                label: Text(cat),
                selected: active,
                onSelected: (_) {
                  setState(() => _activeCategory = cat);
                  _search();
                },
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

        // Results count
        if (_searchC.text.isNotEmpty || _activeCategory != 'Все')
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            child: Row(children: [
              Text(
                _products.isEmpty
                    ? 'Ничего не найдено'
                    : 'Найдено: ${_products.length}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ]),
          ),

        // Product list
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _products.isEmpty
                  ? const Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.search_off, size: 48, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('Ничего не найдено', style: TextStyle(color: Colors.grey)),
                      ]),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      itemCount: _products.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (_, i) => _ProductTile(product: _products[i]),
                    ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    AppDatabase.instance.dataRevision.removeListener(_onDataChanged);
    _searchC.dispose();
    super.dispose();
  }
}

class _ProductTile extends StatelessWidget {
  final Product product;
  const _ProductTile({required this.product});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(product.name,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 2),
              Row(children: [
                Text(formatCurrency(product.price),
                    style: const TextStyle(color: kBronze, fontWeight: FontWeight.bold)),
                Text(' / ${product.unit}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                if (product.category.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(product.category,
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade700)),
                  ),
                ],
              ]),
              if (product.description.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(product.description,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
            ]),
          ),
        ]),
      ),
    );
  }
}
