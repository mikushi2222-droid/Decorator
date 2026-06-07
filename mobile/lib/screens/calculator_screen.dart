import 'package:flutter/material.dart';
import '../database.dart';
import '../models.dart';
import '../utils.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final _lengthC = TextEditingController();
  final _widthC  = TextEditingController();
  final _heightC = TextEditingController();
  final _areaC   = TextEditingController();

  bool _useDirectArea = false;
  Product? _selectedProduct;
  String _mode = 'both'; // 'both' | 'material' | 'labor'

  List<Product> _plasters = [];
  List<LaborRate> _laborRates = [];
  Set<int> _selectedRates = {};

  _CalcResult? _result;

  @override
  void initState() {
    super.initState();
    _load();
    // Перезагружаем справочники, когда товары/ставки меняются в Настройках.
    AppDatabase.instance.dataRevision.addListener(_load);
  }

  Future<void> _load() async {
    final db = AppDatabase.instance;
    final products = await db.getProducts();
    final rates = await db.getLaborRates();
    if (!mounted) return;
    setState(() {
      _plasters = products.where((p) => p.coverage > 0).toList();
      _laborRates = rates;
    });
  }

  double get _calcArea {
    if (_useDirectArea) return double.tryParse(_areaC.text) ?? 0;
    final l = double.tryParse(_lengthC.text) ?? 0;
    final w = double.tryParse(_widthC.text) ?? 0;
    final h = double.tryParse(_heightC.text) ?? 0;
    if (h > 0) return (l + w) * 2 * h;
    return l * w;
  }

  void _calculate() {
    final area = _calcArea;
    if (area <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите площадь больше нуля')),
      );
      return;
    }

    double materialKg = 0, materialCost = 0;
    if (_mode != 'labor' && _selectedProduct != null) {
      materialKg = area * _selectedProduct!.coverage;
      materialCost = materialKg * _selectedProduct!.price;
    }

    // В режиме «только материал» ставки работ не учитываем — иначе в результате
    // появлялись бы строки работ, не входящие в ИТОГО.
    final activeRates = _mode != 'material'
        ? _laborRates.where((r) => _selectedRates.contains(r.id)).toList()
        : <LaborRate>[];
    final laborLines = activeRates.map((r) => _LaborLine(r.name, r.pricePerSqm * area)).toList();
    final laborCost = laborLines.fold(0.0, (s, l) => s + l.cost);

    setState(() {
      _result = _CalcResult(
        area: area,
        materialKg: materialKg,
        materialCost: materialCost,
        laborLines: laborLines,
        laborCost: laborCost,
        total: materialCost + laborCost,
      );
    });
  }

  void _reset() {
    _lengthC.clear(); _widthC.clear(); _heightC.clear(); _areaC.clear();
    setState(() {
      _selectedProduct = null;
      _selectedRates = {};
      _result = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Hint
          _infoCard('Введите площадь → выберите штукатурку → отметьте работы → нажмите «Рассчитать»'),
          const SizedBox(height: 12),

          // Area
          _sectionCard('Шаг 1 — Площадь', [
            Row(children: [
              Expanded(child: _segBtn('По размерам', !_useDirectArea, () => setState(() { _useDirectArea = false; }))),
              const SizedBox(width: 8),
              Expanded(child: _segBtn('Готовая площадь', _useDirectArea, () => setState(() { _useDirectArea = true; }))),
            ]),
            const SizedBox(height: 12),
            if (!_useDirectArea) ...[
              Row(children: [
                Expanded(child: _field('Длина, м', _lengthC)),
                const SizedBox(width: 8),
                Expanded(child: _field('Ширина, м', _widthC)),
              ]),
              const SizedBox(height: 8),
              _field('Высота стен, м (для стен)', _heightC,
                  hint: 'Оставьте пустым для пола/потолка'),
              if (_calcArea > 0) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3A4A).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('Площадь: ${formatNumber(_calcArea)} м²',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            ] else
              _field('Площадь, м²', _areaC),
          ]),
          const SizedBox(height: 12),

          // Mode
          _sectionCard('Шаг 2 — Что считаем', [
            _dropdown<String>(
              value: _mode,
              items: const {
                'both': 'Материал + работа',
                'material': 'Только материал',
                'labor': 'Только работа',
              },
              onChanged: (v) => setState(() => _mode = v!),
            ),
          ]),
          const SizedBox(height: 12),

          // Material
          if (_mode != 'labor') ...[
            _sectionCard('Шаг 3 — Штукатурка', [
              if (_plasters.isEmpty)
                const Text('Нет товаров с нормой расхода. Добавьте в Настройках.',
                    style: TextStyle(color: Colors.grey))
              else
                _dropdown<Product?>(
                  value: _selectedProduct,
                  items: {null: '— Выберите штукатурку —', ...<Product, String>{for (final p in _plasters) p: '${p.name} (${p.coverage} кг/м²)'}},
                  onChanged: (v) => setState(() => _selectedProduct = v),
                ),
            ]),
            const SizedBox(height: 12),
          ],

          // Labor
          if (_mode != 'material' && _laborRates.isNotEmpty) ...[
            _sectionCard(
              _mode == 'labor' ? 'Шаг 3 — Виды работ' : 'Шаг 4 — Виды работ',
              _laborRates.map((r) {
                final sel = _selectedRates.contains(r.id);
                return InkWell(
                  onTap: () {
                    if (r.id == null) return;
                    setState(() {
                      if (sel) _selectedRates.remove(r.id); else _selectedRates.add(r.id!);
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: sel ? const Color(0xFF1E3A4A) : Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                      color: sel ? const Color(0xFF1E3A4A).withOpacity(0.06) : null,
                    ),
                    child: Row(children: [
                      Icon(sel ? Icons.check_box : Icons.check_box_outline_blank,
                          color: sel ? const Color(0xFF1E3A4A) : Colors.grey, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r.name, style: const TextStyle(fontSize: 13)),
                            if (r.hasMarketData)
                              Text(
                                'Рынок: ${formatCurrency(r.marketMin)} – ${formatCurrency(r.marketMax)}',
                                style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(formatCurrency(r.pricePerSqm),
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    ]),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],

          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _reset,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Сброс'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _calculate,
                child: const Text('Рассчитать', style: TextStyle(fontSize: 16)),
              ),
            ),
          ]),

          if (_result != null) ...[
            const SizedBox(height: 16),
            _ResultCard(result: _result!),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _infoCard(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1E3A4A).withOpacity(0.07),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(children: [
          const Icon(Icons.info_outline, size: 16, color: Color(0xFF1E3A4A)),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: Color(0xFF1E3A4A)))),
        ]),
      );

  Widget _sectionCard(String title, List<Widget> children) => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 12),
              ...children,
            ],
          ),
        ),
      );

  Widget _field(String label, TextEditingController c, {String? hint}) => TextFormField(
        controller: c,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          helperText: hint,
          helperMaxLines: 2,
        ),
        onChanged: (_) => setState(() {}),
      );

  Widget _segBtn(String label, bool active, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? const Color(0xFF1E3A4A) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: active ? Colors.white : Colors.black87)),
        ),
      );

  Widget _dropdown<T>({
    required T value,
    required Map<T, String> items,
    required void Function(T?) onChanged,
    String? label,
  }) => DropdownButtonFormField<T>(
        value: value,
        decoration: InputDecoration(labelText: label),
        items: items.entries
            .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, overflow: TextOverflow.ellipsis)))
            .toList(),
        onChanged: onChanged,
        isExpanded: true,
      );

  @override
  void dispose() {
    AppDatabase.instance.dataRevision.removeListener(_load);
    _lengthC.dispose(); _widthC.dispose(); _heightC.dispose(); _areaC.dispose();
    super.dispose();
  }
}

class _LaborLine {
  final String name;
  final double cost;
  _LaborLine(this.name, this.cost);
}

class _CalcResult {
  final double area;
  final double materialKg;
  final double materialCost;
  final List<_LaborLine> laborLines;
  final double laborCost;
  final double total;
  _CalcResult({
    required this.area, required this.materialKg, required this.materialCost,
    required this.laborLines, required this.laborCost, required this.total,
  });
}

class _ResultCard extends StatelessWidget {
  final _CalcResult result;
  const _ResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Color(0xFF1E3A4A), width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
            child: Row(children: [
              const Icon(Icons.bar_chart, color: Color(0xFF1E3A4A)),
              const SizedBox(width: 8),
              const Text('Результат расчёта',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ]),
          ),
          _row('Площадь', '${formatNumber(result.area)} м²'),
          if (result.materialKg > 0) ...[
            _row('Потребность', '${formatNumber(result.materialKg)} кг'),
            _row('Стоимость материала', formatCurrency(result.materialCost)),
          ],
          ...result.laborLines.map((l) => _row(l.name, formatCurrency(l.cost))),
          Container(
            margin: const EdgeInsets.all(14),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A4A),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(children: [
              const Expanded(child: Text('ИТОГО',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
              Text(formatCurrency(result.total),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Row(children: [
          Expanded(child: Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ]),
      );
}
