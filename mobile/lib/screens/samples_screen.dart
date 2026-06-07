import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../database.dart';

// ─── Data model ───────────────────────────────────────────────────────────────

enum TextureGroup { liquid, mineral, volume }

extension TextureGroupX on TextureGroup {
  String get label {
    switch (this) {
      case TextureGroup.liquid:  return 'Жидкие';
      case TextureGroup.mineral: return 'Минеральные';
      case TextureGroup.volume:  return 'Объёмные';
    }
  }

  Color get color {
    switch (this) {
      case TextureGroup.liquid:  return const Color(0xFF7C5CBF);
      case TextureGroup.mineral: return const Color(0xFF4A8A6E);
      case TextureGroup.volume:  return const Color(0xFFC47B2B);
    }
  }
}

enum TexturePattern { silk, velvet, suede, marmorin, venetian, travertine, sand, relief, base }

extension TexturePatternX on TexturePattern {
  String get label {
    switch (this) {
      case TexturePattern.silk:       return 'Шёлк (диагональный блеск)';
      case TexturePattern.velvet:     return 'Велюр (мягкие точки)';
      case TexturePattern.suede:      return 'Замша (мелкое зерно)';
      case TexturePattern.marmorin:   return 'Мармарин (прожилки + перламутр)';
      case TexturePattern.venetian:   return 'Венецианская (глянец + прожилки)';
      case TexturePattern.travertine: return 'Травертин (полосы + поры)';
      case TexturePattern.sand:       return 'Песок (зерно)';
      case TexturePattern.relief:     return 'Барельеф (объёмный цветок)';
      case TexturePattern.base:       return 'Гладкая (градиент)';
    }
  }
}

class TextureSample {
  final int? id;
  final String name;
  final TextureGroup group;
  final List<Color> gradient;
  final String description;
  final String effect;
  final int sheenLevel;    // 0–3
  final int difficulty;    // 1–5
  final String priceRange;
  final List<String> products;
  final TexturePattern pattern;
  final int sortOrder;
  final String imagePath;

  const TextureSample({
    this.id,
    required this.name,
    required this.group,
    required this.gradient,
    required this.description,
    required this.effect,
    required this.sheenLevel,
    required this.difficulty,
    required this.priceRange,
    required this.products,
    required this.pattern,
    this.sortOrder = 0,
    this.imagePath = '',
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'grp': group.name,
        'pattern': pattern.name,
        'gradient': jsonEncode(gradient.map((c) => c.value).toList()),
        'description': description,
        'effect': effect,
        'sheen': sheenLevel,
        'difficulty': difficulty,
        'price_range': priceRange,
        'products': jsonEncode(products),
        'sort_order': sortOrder,
        'image_path': imagePath,
      };

  factory TextureSample.fromMap(Map<String, Object?> m) {
    final grad = (jsonDecode((m['gradient'] as String?) ?? '[]') as List)
        .map((v) => Color(v as int))
        .toList();
    return TextureSample(
      id: m['id'] as int?,
      name: (m['name'] as String?) ?? '',
      group: TextureGroup.values
          .asNameMap()[m['grp'] as String?] ?? TextureGroup.liquid,
      pattern: TexturePattern.values
          .asNameMap()[m['pattern'] as String?] ?? TexturePattern.base,
      gradient: grad.length >= 2
          ? grad
          : const [Color(0xFFEAE0D0), Color(0xFFCCC0A8), Color(0xFFA89878)],
      description: (m['description'] as String?) ?? '',
      effect: (m['effect'] as String?) ?? '',
      sheenLevel: (m['sheen'] as int?) ?? 0,
      difficulty: (m['difficulty'] as int?) ?? 1,
      priceRange: (m['price_range'] as String?) ?? '',
      products:
          ((jsonDecode((m['products'] as String?) ?? '[]') as List).cast<String>()),
      sortOrder: (m['sort_order'] as int?) ?? 0,
      imagePath: (m['image_path'] as String?) ?? '',
    );
  }

  TextureSample copyWith({
    int? id,
    String? name,
    TextureGroup? group,
    List<Color>? gradient,
    String? description,
    String? effect,
    int? sheenLevel,
    int? difficulty,
    String? priceRange,
    List<String>? products,
    TexturePattern? pattern,
    int? sortOrder,
    String? imagePath,
  }) =>
      TextureSample(
        id: id ?? this.id,
        name: name ?? this.name,
        group: group ?? this.group,
        gradient: gradient ?? this.gradient,
        description: description ?? this.description,
        effect: effect ?? this.effect,
        sheenLevel: sheenLevel ?? this.sheenLevel,
        difficulty: difficulty ?? this.difficulty,
        priceRange: priceRange ?? this.priceRange,
        products: products ?? this.products,
        pattern: pattern ?? this.pattern,
        sortOrder: sortOrder ?? this.sortOrder,
        imagePath: imagePath ?? this.imagePath,
      );
}

// Палитры-пресеты для редактора (без RGB-пипетки, чтобы было просто и офлайн).
const Map<String, List<Color>> _palettes = {
  'Песочный':      [Color(0xFFF5EDD8), Color(0xFFD9C9A8), Color(0xFFBDAD8A)],
  'Тёмный велюр':  [Color(0xFF7A5248), Color(0xFF4E3028), Color(0xFF2E1C18)],
  'Замша':         [Color(0xFFCCAA80), Color(0xFFA88860), Color(0xFF7A6040)],
  'Жемчуг':        [Color(0xFFEAE0D0), Color(0xFFCCC0A8), Color(0xFFA89878)],
  'Белый мрамор':  [Color(0xFFF8F4EC), Color(0xFFE0D8C4), Color(0xFFC4BAA4)],
  'Травертин':     [Color(0xFFE8D8B0), Color(0xFFD0BF94), Color(0xFFB8A870)],
  'Тёплый песок':  [Color(0xFFE0D0A8), Color(0xFFCCC090), Color(0xFFB0A870)],
  'Серый камень':  [Color(0xFFE0E0E0), Color(0xFFBEBEBE), Color(0xFF9A9A9A)],
  'Графит':        [Color(0xFF6B6E72), Color(0xFF45484C), Color(0xFF2A2C2E)],
  'Изумруд':       [Color(0xFFBFD8C4), Color(0xFF7FA98C), Color(0xFF4A7059)],
  'Терракота':     [Color(0xFFD9A88A), Color(0xFFB87856), Color(0xFF8A5438)],
  'Лазурь':        [Color(0xFFBCD3DE), Color(0xFF87AEC0), Color(0xFF577E92)],
};

// Стартовый набор — засевается в БД при первом запуске.
const _defaultSamples = <TextureSample>[
  TextureSample(
    name: 'Шёлк',
    group: TextureGroup.liquid,
    gradient: [Color(0xFFF5EDD8), Color(0xFFD9C9A8), Color(0xFFBDAD8A)],
    description: 'Гладкая поверхность с нежным шелковистым блеском. Переливается при изменении угла освещения. Наносится в 2–3 слоя с тщательной затиркой.',
    effect: 'Шёлк / Перламутр',
    sheenLevel: 3,
    difficulty: 4,
    priceRange: '700 – 1 600 ₽/м²',
    products: ['DECORAZZA Seta da Vinci'],
    pattern: TexturePattern.silk,
  ),
  TextureSample(
    name: 'Велюр',
    group: TextureGroup.liquid,
    gradient: [Color(0xFF7A5248), Color(0xFF4E3028), Color(0xFF2E1C18)],
    description: 'Мягкая бархатистая поверхность с глубиной цвета. Имитирует ткань велюр. Тёплые насыщенные оттенки.',
    effect: 'Велюр / Бархат',
    sheenLevel: 1,
    difficulty: 3,
    priceRange: '700 – 1 600 ₽/м²',
    products: ['DECORAZZA Velours', 'DECORAZZA Velluto'],
    pattern: TexturePattern.velvet,
  ),
  TextureSample(
    name: 'Замша',
    group: TextureGroup.liquid,
    gradient: [Color(0xFFCCAA80), Color(0xFFA88860), Color(0xFF7A6040)],
    description: 'Нежная матовая поверхность с микрорельефом. Имитирует натуральную замшу. Тёплые земляные тона.',
    effect: 'Замша / Alcantara',
    sheenLevel: 1,
    difficulty: 4,
    priceRange: '900 – 1 800 ₽/м²',
    products: ['DECORAZZA Alcantara'],
    pattern: TexturePattern.suede,
  ),
  TextureSample(
    name: 'Мармарин',
    group: TextureGroup.liquid,
    gradient: [Color(0xFFEAE0D0), Color(0xFFCCC0A8), Color(0xFFA89878)],
    description: 'Жидкая мраморная штукатурка с глубоким перламутровым блеском. Создаёт богатую поверхность с внутренним свечением.',
    effect: 'Мрамор / Глубина',
    sheenLevel: 3,
    difficulty: 5,
    priceRange: '1 500 – 3 000 ₽/м²',
    products: ['DECORAZZA Brezza', 'DECORAZZA Aretino'],
    pattern: TexturePattern.marmorin,
  ),
  TextureSample(
    name: 'Венецианская',
    group: TextureGroup.liquid,
    gradient: [Color(0xFFF8F4EC), Color(0xFFE0D8C4), Color(0xFFC4BAA4)],
    description: 'Классическая венецианская штукатурка — имитация полированного мрамора. Многослойная техника, глянцевый финиш.',
    effect: 'Полированный мрамор',
    sheenLevel: 3,
    difficulty: 5,
    priceRange: '2 500 – 5 000 ₽/м²',
    products: ['DECORAZZA Stucco Veneziano', 'DECORAZZA Calce Veneziana'],
    pattern: TexturePattern.venetian,
  ),
  TextureSample(
    name: 'Травертин',
    group: TextureGroup.mineral,
    gradient: [Color(0xFFE8D8B0), Color(0xFFD0BF94), Color(0xFFB8A870)],
    description: 'Имитация натурального травертинового камня с горизонтальными полосами и характерными порами.',
    effect: 'Травертин / Камень',
    sheenLevel: 0,
    difficulty: 3,
    priceRange: '1 000 – 1 800 ₽/м²',
    products: ['DECORAZZA Travertino', 'DECORAZZA Traverta'],
    pattern: TexturePattern.travertine,
  ),
  TextureSample(
    name: 'Песок',
    group: TextureGroup.mineral,
    gradient: [Color(0xFFE0D0A8), Color(0xFFCCC090), Color(0xFFB0A870)],
    description: 'Тёплая зернистая поверхность. Скрывает дефекты основания, легко наносится, устойчива к истиранию.',
    effect: 'Песок / Зерно',
    sheenLevel: 0,
    difficulty: 2,
    priceRange: '400 – 900 ₽/м²',
    products: ['BAYRAMIX Sandeco', 'BAYRAMIX Micromineral'],
    pattern: TexturePattern.sand,
  ),
  TextureSample(
    name: 'Барельеф',
    group: TextureGroup.volume,
    gradient: [Color(0xFFF2EDE4), Color(0xFFDDD5C8), Color(0xFFC4BCAC)],
    description: 'Объёмный лепной декор ручной работы. Цветы, геометрия, орнаменты — каждый элемент уникален.',
    effect: '3D-рельеф / Лепнина',
    sheenLevel: 1,
    difficulty: 5,
    priceRange: '5 000 – 15 000 ₽/м²',
    products: ['DECORAZZA Barilievo', 'DECORAZZA Sollievo'],
    pattern: TexturePattern.relief,
  ),
];

// ─── Screen ────────────────────────────────────────────────────────────────────

class SamplesScreen extends StatefulWidget {
  const SamplesScreen({super.key});

  @override
  State<SamplesScreen> createState() => _SamplesScreenState();
}

class _SamplesScreenState extends State<SamplesScreen> {
  TextureGroup? _filter;
  List<TextureSample> _samples = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = AppDatabase.instance;
    // Засеять стартовые примеры при первом запуске.
    if (await db.textureSamplesCount() == 0) {
      for (var i = 0; i < _defaultSamples.length; i++) {
        await db.insertTextureSample(_defaultSamples[i].copyWith(sortOrder: i).toMap());
      }
    }
    final rows = await db.getTextureSamples();
    if (!mounted) return;
    setState(() {
      _samples = rows.map(TextureSample.fromMap).toList();
      _loading = false;
    });
  }

  List<TextureSample> get _visible =>
      _filter == null ? _samples : _samples.where((s) => s.group == _filter).toList();

  Future<void> _addNew() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const SampleEditScreen()),
    );
    if (saved == true) _load();
  }

  Future<void> _openDetail(TextureSample sample) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DetailSheet(sample: sample),
    );
    if (!mounted) return;
    if (action == 'edit') {
      final saved = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => SampleEditScreen(sample: sample)),
      );
      if (saved == true) _load();
    } else if (action == 'delete') {
      await _confirmDelete(sample);
    }
  }

  Future<void> _confirmDelete(TextureSample sample) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Удалить пример?'),
        content: Text(sample.name),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok == true && sample.id != null) {
      await AppDatabase.instance.deleteTextureSample(sample.id!);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      children: [
        // Header + add
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(children: [
            const Expanded(
              child: Text('Примеры покрытий',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
            FilledButton.icon(
              onPressed: _addNew,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Добавить'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A4A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ]),
        ),

        // Group filter chips
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            children: [
              _chip('Все', _filter == null, () => setState(() => _filter = null)),
              const SizedBox(width: 6),
              ...TextureGroup.values.map((g) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: _chip(g.label, _filter == g, () => setState(() => _filter = g), color: g.color),
                  )),
            ],
          ),
        ),

        // Grid
        Expanded(
          child: _visible.isEmpty
              ? const Center(
                  child: Text('Примеров пока нет. Нажмите «Добавить».',
                      style: TextStyle(color: Colors.grey)),
                )
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: _visible.length,
                  itemBuilder: (_, i) => _SampleCard(
                    sample: _visible[i],
                    onTap: () => _openDetail(_visible[i]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _chip(String label, bool active, VoidCallback onTap, {Color? color}) {
    final c = color ?? const Color(0xFF1E3A4A);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? c : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? c : Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: active ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
}

// ─── Sample card ──────────────────────────────────────────────────────────────

class _SampleCard extends StatelessWidget {
  final TextureSample sample;
  final VoidCallback onTap;
  const _SampleCard({required this.sample, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 3))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Texture preview (60% of card)
              Expanded(
                flex: 6,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _hasImage(sample)
                        ? Image.file(File(sample.imagePath), fit: BoxFit.cover)
                        : CustomPaint(painter: _TexturePainter(sample.pattern, sample.gradient)),
                    Positioned(
                      top: 8, right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: sample.group.color.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(sample.group.label,
                            style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
              // Info (40% of card)
              Expanded(
                flex: 4,
                child: Container(
                  color: Theme.of(context).colorScheme.surface,
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(sample.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(sample.effect,
                          style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const Spacer(),
                      Row(children: [
                        ..._sheenDots(sample.sheenLevel),
                        const Spacer(),
                        _diffBadge(sample.difficulty),
                      ]),
                      const SizedBox(height: 4),
                      Text(sample.priceRange,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF1E3A4A)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _hasImage(TextureSample s) =>
      s.imagePath.isNotEmpty && File(s.imagePath).existsSync();

  List<Widget> _sheenDots(int level) {
    return List.generate(3, (i) => Container(
          width: 6, height: 6,
          margin: const EdgeInsets.only(right: 2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: i < level ? const Color(0xFFD4AF37) : Colors.grey.shade300,
          ),
        ));
  }

  Widget _diffBadge(int d) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
        decoration: BoxDecoration(
          color: _diffColor(d).withOpacity(0.15),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: _diffColor(d).withOpacity(0.3)),
        ),
        child: Text('★' * d, style: TextStyle(fontSize: 8, color: _diffColor(d))),
      );

  Color _diffColor(int d) {
    if (d <= 2) return Colors.green.shade600;
    if (d == 3) return Colors.orange.shade700;
    return Colors.red.shade600;
  }
}

// ─── Detail bottom sheet ──────────────────────────────────────────────────────

class _DetailSheet extends StatelessWidget {
  final TextureSample sample;
  const _DetailSheet({required this.sample});

  File? get _imageFile {
    if (sample.imagePath.isEmpty) return null;
    final f = File(sample.imagePath);
    return f.existsSync() ? f : null;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, sc) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: ListView(
          controller: sc,
          padding: EdgeInsets.zero,
          children: [
            // Drag handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 6),
                width: 36, height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
            ),

            // Large texture preview
            SizedBox(
              height: 220,
              child: _imageFile != null
                  ? Image.file(_imageFile!, fit: BoxFit.cover, width: double.infinity)
                  : CustomPaint(painter: _TexturePainter(sample.pattern, sample.gradient)),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(sample.name,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(sample.effect,
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                      ]),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: sample.group.color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: sample.group.color.withOpacity(0.3)),
                      ),
                      child: Text(sample.group.label,
                          style: TextStyle(fontSize: 12, color: sample.group.color, fontWeight: FontWeight.w600)),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  if (sample.description.isNotEmpty) ...[
                    Text(sample.description, style: const TextStyle(fontSize: 14, height: 1.5)),
                    const SizedBox(height: 20),
                  ],

                  // Characteristics
                  if (sample.priceRange.isNotEmpty)
                    _infoRow('Цена работ', sample.priceRange, Icons.payments_outlined),
                  if (sample.effect.isNotEmpty)
                    _infoRow('Эффект', sample.effect, Icons.auto_awesome_outlined),
                  _infoRow('Блеск', _sheenLabel(sample.sheenLevel), Icons.wb_sunny_outlined),
                  _infoRow('Сложность', _diffLabel(sample.difficulty), Icons.bar_chart),
                  const SizedBox(height: 16),

                  // Products
                  if (sample.products.isNotEmpty) ...[
                    Text('Материалы', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
                    const SizedBox(height: 6),
                    ...sample.products.map((p) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(children: [
                            Icon(Icons.circle, size: 5, color: Colors.grey.shade400),
                            const SizedBox(width: 8),
                            Expanded(child: Text(p, style: const TextStyle(fontSize: 13))),
                          ]),
                        )),
                    const SizedBox(height: 16),
                  ],

                  // Actions
                  Row(children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pop(context, 'edit'),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Редактировать'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF1E3A4A),
                          side: const BorderSide(color: Color(0xFF1E3A4A)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context, 'delete'),
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Удалить'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, IconData icon) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(children: [
          Icon(icon, size: 16, color: Colors.grey.shade500),
          const SizedBox(width: 8),
          Text('$label: ', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
        ]),
      );

  String _sheenLabel(int l) {
    switch (l) {
      case 0: return 'Матовый';
      case 1: return 'Полуматовый';
      case 2: return 'Сатиновый';
      default: return 'Глянцевый';
    }
  }

  String _diffLabel(int d) {
    switch (d) {
      case 1: return 'Очень лёгкая ★';
      case 2: return 'Лёгкая ★★';
      case 3: return 'Средняя ★★★';
      case 4: return 'Сложная ★★★★';
      default: return 'Очень сложная ★★★★★';
    }
  }
}

// ─── Add / edit screen ──────────────────────────────────────────────────────────

class SampleEditScreen extends StatefulWidget {
  final TextureSample? sample;
  const SampleEditScreen({super.key, this.sample});

  @override
  State<SampleEditScreen> createState() => _SampleEditScreenState();
}

class _SampleEditScreenState extends State<SampleEditScreen> {
  late final TextEditingController _nameC;
  late final TextEditingController _effectC;
  late final TextEditingController _descC;
  late final TextEditingController _priceC;
  late final TextEditingController _productsC;

  late TextureGroup _group;
  late TexturePattern _pattern;
  late List<Color> _gradient;
  late int _sheen;
  late int _difficulty;
  late String _imagePath;
  bool _saving = false;

  bool get _isEdit => widget.sample != null;

  @override
  void initState() {
    super.initState();
    final s = widget.sample;
    _nameC = TextEditingController(text: s?.name ?? '');
    _effectC = TextEditingController(text: s?.effect ?? '');
    _descC = TextEditingController(text: s?.description ?? '');
    _priceC = TextEditingController(text: s?.priceRange ?? '');
    _productsC = TextEditingController(text: (s?.products ?? const []).join('\n'));
    _group = s?.group ?? TextureGroup.liquid;
    _pattern = s?.pattern ?? TexturePattern.base;
    _gradient = s?.gradient ?? _palettes.values.first;
    _sheen = s?.sheenLevel ?? 0;
    _difficulty = s?.difficulty ?? 1;
    _imagePath = s?.imagePath ?? '';
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 85, maxWidth: 1200);
    if (picked == null) return;
    final dir = await getApplicationDocumentsDirectory();
    final imgDir = Directory(p.join(dir.path, 'texture_images'));
    await imgDir.create(recursive: true);
    final fileName = 'texture_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final dest = p.join(imgDir.path, fileName);
    await File(picked.path).copy(dest);
    setState(() => _imagePath = dest);
  }

  void _removeImage() => setState(() => _imagePath = '');

  @override
  void dispose() {
    _nameC.dispose();
    _effectC.dispose();
    _descC.dispose();
    _priceC.dispose();
    _productsC.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameC.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Укажите название')),
      );
      return;
    }
    setState(() => _saving = true);
    final products = _productsC.text
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final model = (widget.sample ??
            const TextureSample(
              name: '', group: TextureGroup.liquid, gradient: [],
              description: '', effect: '', sheenLevel: 0, difficulty: 1,
              priceRange: '', products: [], pattern: TexturePattern.base,
            ))
        .copyWith(
      name: _nameC.text.trim(),
      effect: _effectC.text.trim(),
      description: _descC.text.trim(),
      priceRange: _priceC.text.trim(),
      products: products,
      group: _group,
      pattern: _pattern,
      gradient: _gradient,
      sheenLevel: _sheen,
      difficulty: _difficulty,
      imagePath: _imagePath,
    );
    final db = AppDatabase.instance;
    if (_isEdit && widget.sample!.id != null) {
      await db.updateTextureSample(widget.sample!.id!, model.toMap());
    } else {
      await db.insertTextureSample(model.toMap());
    }
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Редактировать пример' : 'Новый пример'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Сохранить', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Photo / live preview
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 160,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _imagePath.isNotEmpty && File(_imagePath).existsSync()
                      ? Image.file(File(_imagePath), fit: BoxFit.cover)
                      : CustomPaint(painter: _TexturePainter(_pattern, _gradient)),
                  // Overlay buttons
                  Positioned(
                    bottom: 8, right: 8,
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      if (_imagePath.isNotEmpty) ...[
                        _overlayBtn(Icons.delete_outline, Colors.red, _removeImage),
                        const SizedBox(width: 6),
                      ],
                      // Camera only available on mobile
                      if (Platform.isAndroid || Platform.isIOS) ...[
                        _overlayBtn(Icons.camera_alt_outlined, Colors.white,
                            () => _pickImage(ImageSource.camera)),
                        const SizedBox(width: 6),
                      ],
                      _overlayBtn(Icons.photo_library_outlined, Colors.white,
                          () => _pickImage(ImageSource.gallery)),
                    ]),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text('Фото заменяет нарисованную фактуру в карточке.',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          const SizedBox(height: 12),

          _label('Название'),
          TextFormField(controller: _nameC, decoration: const InputDecoration(hintText: 'Например: Шёлк')),
          const SizedBox(height: 12),

          _label('Эффект (подзаголовок)'),
          TextFormField(controller: _effectC, decoration: const InputDecoration(hintText: 'Например: Шёлк / Перламутр')),
          const SizedBox(height: 12),

          _label('Группа'),
          DropdownButtonFormField<TextureGroup>(
            value: _group,
            isExpanded: true,
            items: TextureGroup.values
                .map((g) => DropdownMenuItem(value: g, child: Text(g.label)))
                .toList(),
            onChanged: (v) => setState(() => _group = v!),
          ),
          const SizedBox(height: 12),

          _label('Фактура (как рисуется)'),
          DropdownButtonFormField<TexturePattern>(
            value: _pattern,
            isExpanded: true,
            items: TexturePattern.values
                .map((p) => DropdownMenuItem(value: p, child: Text(p.label, overflow: TextOverflow.ellipsis)))
                .toList(),
            onChanged: (v) => setState(() => _pattern = v!),
          ),
          const SizedBox(height: 12),

          _label('Палитра'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _palettes.entries.map((e) {
              final selected = _sameColors(e.value, _gradient);
              return GestureDetector(
                onTap: () => setState(() => _gradient = e.value),
                child: Container(
                  width: 64,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: e.value),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selected ? const Color(0xFF1E3A4A) : Colors.grey.shade300,
                      width: selected ? 2.5 : 1,
                    ),
                  ),
                  child: selected
                      ? const Icon(Icons.check, color: Colors.white, size: 18)
                      : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          _label('Блеск'),
          _segments(
            count: 4,
            startAt: 0,
            value: _sheen,
            labels: const ['Матовый', 'Полумат.', 'Сатин', 'Глянец'],
            onChanged: (v) => setState(() => _sheen = v),
          ),
          const SizedBox(height: 16),

          _label('Сложность'),
          _segments(
            count: 5,
            startAt: 1,
            value: _difficulty,
            labels: const ['1★', '2★', '3★', '4★', '5★'],
            onChanged: (v) => setState(() => _difficulty = v),
          ),
          const SizedBox(height: 16),

          _label('Цена работ (текст)'),
          TextFormField(controller: _priceC, decoration: const InputDecoration(hintText: 'Например: 700 – 1 600 ₽/м²')),
          const SizedBox(height: 12),

          _label('Материалы (по одному в строке)'),
          TextFormField(
            controller: _productsC,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'DECORAZZA Seta da Vinci\nDECORAZZA Aretino',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),

          _label('Описание'),
          TextFormField(
            controller: _descC,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Краткое описание фактуры и техники нанесения…',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  bool _sameColors(List<Color> a, List<Color> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Widget _overlayBtn(IconData icon, Color color, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
      );

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
      );

  Widget _segments({
    required int count,
    required int startAt,
    required int value,
    required List<String> labels,
    required ValueChanged<int> onChanged,
  }) {
    return Row(
      children: List.generate(count, (i) {
        final v = startAt + i;
        final active = v == value;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(v),
            child: Container(
              margin: EdgeInsets.only(right: i == count - 1 ? 0 : 6),
              padding: const EdgeInsets.symmetric(vertical: 9),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? const Color(0xFF1E3A4A) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                labels[i],
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: active ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ─── Texture painters ─────────────────────────────────────────────────────────

class _TexturePainter extends CustomPainter {
  final TexturePattern type;
  final List<Color> gradient;
  const _TexturePainter(this.type, this.gradient);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Base gradient (минимум 2 цвета гарантируется моделью)
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(rect),
    );

    switch (type) {
      case TexturePattern.silk:
        _paintSilk(canvas, size);
      case TexturePattern.velvet:
        _paintVelvet(canvas, size);
      case TexturePattern.suede:
        _paintSuede(canvas, size);
      case TexturePattern.marmorin:
        _paintMarmorin(canvas, size);
      case TexturePattern.venetian:
        _paintVenetian(canvas, size);
      case TexturePattern.travertine:
        _paintTravertine(canvas, size);
      case TexturePattern.sand:
        _paintSand(canvas, size);
      case TexturePattern.relief:
        _paintRelief(canvas, size);
      case TexturePattern.base:
        _paintBase(canvas, size);
    }
  }

  void _paintSilk(Canvas canvas, Size size) {
    // Fine diagonal shimmer lines
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.18)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    for (double i = -size.height; i < size.width + size.height; i += 10) {
      canvas.drawLine(Offset(i, 0), Offset(i + size.height, size.height), linePaint);
    }
    // Central shimmer
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          colors: [Colors.transparent, Colors.white.withOpacity(0.22), Colors.transparent],
          stops: const [0.2, 0.5, 0.8],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(Offset.zero & size),
    );
  }

  void _paintVelvet(Canvas canvas, Size size) {
    // Soft micro-dots pattern
    final r = math.Random(42);
    final dotPaint = Paint()..color = Colors.white.withOpacity(0.06);
    for (int i = 0; i < 300; i++) {
      final x = r.nextDouble() * size.width;
      final y = r.nextDouble() * size.height;
      canvas.drawCircle(Offset(x, y), 1.2, dotPaint);
    }
    // Edge highlight
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          colors: [Colors.white.withOpacity(0.12), Colors.transparent],
          radius: 0.7,
          center: Alignment.topLeft,
        ).createShader(Offset.zero & size),
    );
  }

  void _paintSuede(Canvas canvas, Size size) {
    // Fine stipple texture
    final r = math.Random(99);
    for (int i = 0; i < 500; i++) {
      final x = r.nextDouble() * size.width;
      final y = r.nextDouble() * size.height;
      final brightness = r.nextDouble();
      final p = Paint()
        ..color = Colors.white.withOpacity(0.04 + brightness * 0.08)
        ..strokeWidth = 0.8;
      canvas.drawCircle(Offset(x, y), 0.8, p);
    }
    // Soft directional light
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          colors: [Colors.white.withOpacity(0.15), Colors.transparent, Colors.black.withOpacity(0.1)],
          stops: const [0.0, 0.4, 1.0],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Offset.zero & size),
    );
  }

  void _paintMarmorin(Canvas canvas, Size size) {
    // Flowing marble veins
    final veinPaint = Paint()
      ..color = Colors.white.withOpacity(0.25)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(0, size.height * 0.3);
    path.cubicTo(size.width * 0.3, size.height * 0.1, size.width * 0.6, size.height * 0.5, size.width, size.height * 0.3);
    canvas.drawPath(path, veinPaint);

    final path2 = Path();
    path2.moveTo(0, size.height * 0.7);
    path2.cubicTo(size.width * 0.25, size.height * 0.55, size.width * 0.7, size.height * 0.85, size.width, size.height * 0.6);
    canvas.drawPath(path2, veinPaint..color = Colors.white.withOpacity(0.18));

    final path3 = Path();
    path3.moveTo(size.width * 0.4, 0);
    path3.cubicTo(size.width * 0.5, size.height * 0.3, size.width * 0.35, size.height * 0.6, size.width * 0.5, size.height);
    canvas.drawPath(path3, veinPaint..color = Colors.black.withOpacity(0.12)..strokeWidth = 0.8);

    // Pearl shimmer overlay
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          colors: [Colors.transparent, Colors.white.withOpacity(0.2), Colors.transparent],
          stops: const [0.0, 0.6, 1.0],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ).createShader(Offset.zero & size),
    );
  }

  void _paintVenetian(Canvas canvas, Size size) {
    // Polished marble — bold veins + high gloss
    final veinPaint = Paint()
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(size.width * 0.1, 0);
    path.cubicTo(size.width * 0.3, size.height * 0.4, size.width * 0.6, size.height * 0.2, size.width * 0.8, size.height);
    canvas.drawPath(path, veinPaint..color = Colors.grey.withOpacity(0.25));

    final path2 = Path();
    path2.moveTo(0, size.height * 0.5);
    path2.cubicTo(size.width * 0.4, size.height * 0.3, size.width * 0.6, size.height * 0.7, size.width, size.height * 0.4);
    canvas.drawPath(path2, veinPaint..color = Colors.grey.withOpacity(0.15)..strokeWidth = 1.2);

    // High gloss reflection
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          colors: [Colors.white.withOpacity(0.45), Colors.transparent, Colors.white.withOpacity(0.1)],
          stops: const [0.0, 0.5, 1.0],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(Offset.zero & size),
    );
  }

  void _paintTravertine(Canvas canvas, Size size) {
    // Horizontal stone bands
    final bandPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    const bands = 8;
    for (int i = 1; i < bands; i++) {
      final y = size.height * i / bands;
      final alpha = (i % 2 == 0) ? 0.12 : 0.06;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), bandPaint..color = Colors.brown.withOpacity(alpha));
    }
    // Pores / holes
    final r = math.Random(77);
    final porePaint = Paint()..color = Colors.brown.withOpacity(0.15);
    for (int i = 0; i < 30; i++) {
      final x = r.nextDouble() * size.width;
      final y = r.nextDouble() * size.height;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, y), width: r.nextDouble() * 8 + 2, height: r.nextDouble() * 3 + 1),
        porePaint,
      );
    }
    // Soft highlight
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          colors: [Colors.white.withOpacity(0.2), Colors.transparent],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Offset.zero & size),
    );
  }

  void _paintSand(Canvas canvas, Size size) {
    // Fine grain dots
    final r = math.Random(55);
    for (int i = 0; i < 800; i++) {
      final x = r.nextDouble() * size.width;
      final y = r.nextDouble() * size.height;
      final radius = r.nextDouble() * 1.5 + 0.3;
      final brightness = r.nextDouble();
      canvas.drawCircle(
        Offset(x, y),
        radius,
        Paint()..color = Colors.white.withOpacity(0.05 + brightness * 0.1),
      );
      if (r.nextBool()) {
        canvas.drawCircle(
          Offset(x + 0.5, y + 0.5),
          radius * 0.5,
          Paint()..color = Colors.black.withOpacity(0.04),
        );
      }
    }
  }

  void _paintRelief(Canvas canvas, Size size) {
    // Floral relief pattern
    final c = Offset(size.width / 2, size.height / 2);
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.35);
    final basePaint = Paint()
      ..color = gradient[gradient.length > 1 ? 1 : 0].withOpacity(0.9);

    // Draw petal shapes
    for (int p = 0; p < 6; p++) {
      final angle = p * math.pi / 3;
      final px = c.dx + math.cos(angle) * size.width * 0.22;
      final py = c.dy + math.sin(angle) * size.height * 0.22;
      final petalCenter = Offset(px, py);
      canvas.drawCircle(Offset(px + 1.5, py + 2), size.width * 0.1, shadowPaint);
      canvas.drawCircle(petalCenter, size.width * 0.1, basePaint);
      canvas.drawCircle(petalCenter, size.width * 0.1,
          Paint()..shader = RadialGradient(
            colors: [Colors.white.withOpacity(0.3), Colors.transparent],
          ).createShader(Rect.fromCircle(center: petalCenter, radius: size.width * 0.1)));
    }
    // Centre
    canvas.drawCircle(Offset(c.dx + 1, c.dy + 2), size.width * 0.12, shadowPaint);
    canvas.drawCircle(c, size.width * 0.12, basePaint);
    canvas.drawCircle(c, size.width * 0.12, highlightPaint..shader = RadialGradient(
      colors: [Colors.white.withOpacity(0.4), Colors.transparent],
    ).createShader(Rect.fromCircle(center: c, radius: size.width * 0.12)));
  }

  void _paintBase(Canvas canvas, Size size) {
    // Simple smooth gradient — nothing extra
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          colors: [Colors.white.withOpacity(0.2), Colors.transparent],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(covariant _TexturePainter old) =>
      old.type != type || old.gradient != gradient;
}
