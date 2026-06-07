import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../database.dart';
import 'samples_screen.dart';

// ─── Параметры подбора ────────────────────────────────────────────────────────

enum _Effect {
  silkAndVelvet('Шёлк и бархат',     'Мягкий матовый или перламутровый блеск',    Icons.auto_awesome_outlined),
  marbleAndGloss('Мрамор / глянец',  'Венецианская, мармарин — глубокий лак',     Icons.brightness_high_outlined),
  stone('Природный камень',          'Травертин, песок — минеральная фактура',     Icons.landscape_outlined),
  relief('Объёмный рельеф',          'Барельеф, 3D-орнамент ручной работы',       Icons.texture_outlined),
  smooth('Гладкий / минимализм',     'Чистый градиент без видимой фактуры',        Icons.crop_square_outlined);

  final String label;
  final String hint;
  final IconData icon;
  const _Effect(this.label, this.hint, this.icon);
}

enum _Budget {
  low(    'До 600 ₽/м²',    'Минеральные и базовые'),
  mid(    '600–2000 ₽/м²',  'Средний сегмент'),
  premium('От 2000 ₽/м²',  'Премиум-покрытия');

  final String label;
  final String sub;
  const _Budget(this.label, this.sub);
}

// ─── Маппинг эффектов на паттерны ────────────────────────────────────────────

const _effectPatterns = {
  _Effect.silkAndVelvet:  [TexturePattern.silk, TexturePattern.velvet, TexturePattern.suede],
  _Effect.marbleAndGloss: [TexturePattern.marmorin, TexturePattern.venetian],
  _Effect.stone:          [TexturePattern.travertine, TexturePattern.sand],
  _Effect.relief:         [TexturePattern.relief],
  _Effect.smooth:         [TexturePattern.base],
};

// ─── Экран ───────────────────────────────────────────────────────────────────

class PlasterSelectorScreen extends StatefulWidget {
  const PlasterSelectorScreen({super.key});

  @override
  State<PlasterSelectorScreen> createState() => _PlasterSelectorScreenState();
}

class _PlasterSelectorScreenState extends State<PlasterSelectorScreen> {
  _Effect? _effect;
  int? _sheen;          // 0–3, null = любой
  int? _maxDifficulty;  // 1–5, null = любой
  _Budget? _budget;

  List<TextureSample> _allSamples = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rows = await AppDatabase.instance.getTextureSamples();
    if (!mounted) return;
    setState(() {
      _allSamples = rows.map(TextureSample.fromMap).toList();
      _loading = false;
    });
  }

  // ── Скоринг ────────────────────────────────────────────────────────────────

  int _score(TextureSample s) {
    int score = 0;
    if (_effect != null) {
      if (_effectPatterns[_effect]!.contains(s.pattern)) score += 3;
    }
    if (_sheen != null && s.sheenLevel == _sheen) score += 2;
    if (_maxDifficulty != null && s.difficulty <= _maxDifficulty!) score += 2;
    if (_budget != null) {
      final avg = _avgPrice(s.priceRange);
      if (avg > 0) {
        final fits = switch (_budget!) {
          _Budget.low     => avg < 600,
          _Budget.mid     => avg >= 500 && avg < 2500,
          _Budget.premium => avg >= 1500,
        };
        if (fits) score += 2;
      }
    }
    return score;
  }

  double _avgPrice(String raw) {
    final nums = RegExp(r'\d[\d\s]*')
        .allMatches(raw)
        .map((m) => double.tryParse(m.group(0)!.replaceAll(' ', '')) ?? 0)
        .where((n) => n > 10)
        .toList();
    if (nums.isEmpty) return 0;
    return nums.reduce((a, b) => a + b) / nums.length;
  }

  List<TextureSample> get _results {
    final hasFilter = _effect != null || _sheen != null ||
        _maxDifficulty != null || _budget != null;
    if (!hasFilter) return _allSamples;
    return _allSamples
        .where((s) => _score(s) > 0)
        .toList()
      ..sort((a, b) => _score(b).compareTo(_score(a)));
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final results = _results;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Подбор фактуры'),
        actions: [
          if (_effect != null || _sheen != null || _maxDifficulty != null || _budget != null)
            TextButton(
              onPressed: () => setState(() {
                _effect = null; _sheen = null; _maxDifficulty = null; _budget = null;
              }),
              child: const Text('Сбросить', style: TextStyle(color: Colors.white70)),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [

          // ── Желаемый эффект ───────────────────────────────────────────────
          _sectionTitle('1. Желаемый эффект'),
          const SizedBox(height: 8),
          ...(_Effect.values.map((e) => _EffectTile(
            effect: e,
            selected: _effect == e,
            onTap: () => setState(() => _effect = _effect == e ? null : e),
          ))),
          const SizedBox(height: 20),

          // ── Уровень блеска ────────────────────────────────────────────────
          _sectionTitle('2. Блеск поверхности'),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final entry in const {
              0: 'Матовый',
              1: 'Полуматовый',
              2: 'Сатиновый',
              3: 'Глянцевый',
            }.entries)
              _choiceChip(
                label: entry.value,
                selected: _sheen == entry.key,
                onTap: () => setState(() => _sheen = _sheen == entry.key ? null : entry.key),
              ),
          ]),
          const SizedBox(height: 20),

          // ── Сложность ─────────────────────────────────────────────────────
          _sectionTitle('3. Опыт мастера'),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            _choiceChip(
              label: 'Новичок',
              sub: '★ 1–2',
              selected: _maxDifficulty == 2,
              onTap: () => setState(() => _maxDifficulty = _maxDifficulty == 2 ? null : 2),
            ),
            _choiceChip(
              label: 'Уверенный',
              sub: '★ 1–3',
              selected: _maxDifficulty == 3,
              onTap: () => setState(() => _maxDifficulty = _maxDifficulty == 3 ? null : 3),
            ),
            _choiceChip(
              label: 'Мастер',
              sub: '★ 1–5',
              selected: _maxDifficulty == 5,
              onTap: () => setState(() => _maxDifficulty = _maxDifficulty == 5 ? null : 5),
            ),
          ]),
          const SizedBox(height: 20),

          // ── Бюджет ────────────────────────────────────────────────────────
          _sectionTitle('4. Бюджет работ'),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: _Budget.values.map((b) =>
            _choiceChip(
              label: b.label,
              sub: b.sub,
              selected: _budget == b,
              onTap: () => setState(() => _budget = _budget == b ? null : b),
            ),
          ).toList()),
          const SizedBox(height: 24),

          // ── Результаты ────────────────────────────────────────────────────
          Row(children: [
            Expanded(
              child: Text(
                results.isEmpty
                    ? 'Нет подходящих фактур'
                    : 'Подходит: ${results.length}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: results.isEmpty ? Colors.grey : const Color(0xFF1E3A4A),
                ),
              ),
            ),
            if (results.isNotEmpty)
              Text('отсортировано по совпадению',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          ]),
          const SizedBox(height: 10),

          if (results.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.search_off, size: 48, color: Colors.grey.shade300),
                  const SizedBox(height: 8),
                  Text('Попробуйте расширить критерии подбора',
                      style: TextStyle(color: Colors.grey.shade500)),
                ]),
              ),
            )
          else
            ...results.map((s) => _ResultTile(
              sample: s,
              score: _score(s),
              maxScore: (_effect != null ? 3 : 0) + (_sheen != null ? 2 : 0) +
                        (_maxDifficulty != null ? 2 : 0) + (_budget != null ? 2 : 0),
              onTap: () => _openDetail(s),
            )),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E3A4A)),
      );

  Widget _choiceChip({
    required String label,
    String? sub,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1E3A4A) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? const Color(0xFF1E3A4A) : Colors.grey.shade300,
          ),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : Colors.black87,
              )),
          if (sub != null)
            Text(sub,
                style: TextStyle(
                  fontSize: 10,
                  color: selected ? Colors.white70 : Colors.grey.shade500,
                )),
        ]),
      ),
    );
  }

  void _openDetail(TextureSample sample) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SampleDetailSheet(sample: sample),
    );
  }
}

// ─── Effect tile ──────────────────────────────────────────────────────────────

class _EffectTile extends StatelessWidget {
  final _Effect effect;
  final bool selected;
  final VoidCallback onTap;
  const _EffectTile({required this.effect, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1E3A4A) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFF1E3A4A) : Colors.grey.shade200,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(children: [
          Icon(effect.icon,
              size: 22,
              color: selected ? Colors.white : const Color(0xFF1E3A4A)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(effect.label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: selected ? Colors.white : Colors.black87,
                  )),
              Text(effect.hint,
                  style: TextStyle(
                    fontSize: 11,
                    color: selected ? Colors.white70 : Colors.grey.shade600,
                  )),
            ]),
          ),
          if (selected) const Icon(Icons.check_circle, color: Colors.white, size: 20),
        ]),
      ),
    );
  }
}

// ─── Result tile ──────────────────────────────────────────────────────────────

class _ResultTile extends StatelessWidget {
  final TextureSample sample;
  final int score;
  final int maxScore;
  final VoidCallback onTap;
  const _ResultTile({required this.sample, required this.score, required this.maxScore, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final pct = maxScore > 0 ? score / maxScore : 1.0;
    final hasImg = sample.imagePath.isNotEmpty && File(sample.imagePath).existsSync();

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            // Preview
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 64, height: 64,
                child: hasImg
                    ? Image.file(File(sample.imagePath), fit: BoxFit.cover)
                    : _GradientBox(gradient: sample.gradient),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(
                    child: Text(sample.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: sample.group.color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(sample.group.label,
                        style: TextStyle(fontSize: 10, color: sample.group.color, fontWeight: FontWeight.w600)),
                  ),
                ]),
                const SizedBox(height: 2),
                Text(sample.effect,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                const SizedBox(height: 6),
                Row(children: [
                  _diffStars(sample.difficulty),
                  const SizedBox(width: 8),
                  _sheenDots(sample.sheenLevel),
                  const Spacer(),
                  if (sample.priceRange.isNotEmpty)
                    Text(sample.priceRange,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF1E3A4A))),
                ]),
                if (maxScore > 0) ...[
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct.clamp(0.0, 1.0),
                      minHeight: 4,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation(
                        pct >= 0.75 ? Colors.green.shade500 :
                        pct >= 0.5  ? const Color(0xFF1E3A4A) : Colors.orange.shade400,
                      ),
                    ),
                  ),
                ],
              ]),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ]),
        ),
      ),
    );
  }

  Widget _diffStars(int d) {
    final color = d <= 2 ? Colors.green.shade600 : d == 3 ? Colors.orange.shade600 : Colors.red.shade500;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.build_outlined, size: 11, color: color),
      const SizedBox(width: 2),
      Text('${'★' * d}${'☆' * (5 - d)}', style: TextStyle(fontSize: 9, color: color)),
    ]);
  }

  Widget _sheenDots(int level) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) => Container(
          width: 6, height: 6,
          margin: const EdgeInsets.only(right: 2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: i < level ? const Color(0xFFD4AF37) : Colors.grey.shade300,
          ),
        )),
      );
}

// ─── Gradient box (замена CustomPaint без зависимости от приватного класса) ──

class _GradientBox extends StatelessWidget {
  final List<Color> gradient;
  const _GradientBox({required this.gradient});

  @override
  Widget build(BuildContext context) {
    final colors = gradient.length >= 2 ? gradient : [Colors.grey.shade300, Colors.grey.shade200];
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }
}

// ─── Detail bottom sheet ──────────────────────────────────────────────────────

class _SampleDetailSheet extends StatelessWidget {
  final TextureSample sample;
  const _SampleDetailSheet({required this.sample});

  @override
  Widget build(BuildContext context) {
    final imageFile = sample.imagePath.isNotEmpty && File(sample.imagePath).existsSync()
        ? File(sample.imagePath)
        : null;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
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
            // Handle
            Center(child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 36, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            )),

            // Preview
            SizedBox(
              height: 200,
              child: imageFile != null
                  ? Image.file(imageFile, fit: BoxFit.cover, width: double.infinity)
                  : _GradientBox(gradient: sample.gradient),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Header
                Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(sample.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(sample.effect, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                  ])),
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
                  const SizedBox(height: 16),
                ],

                // Характеристики
                _row('Цена работ', sample.priceRange, Icons.payments_outlined),
                _row('Блеск', _sheenLabel(sample.sheenLevel), Icons.wb_sunny_outlined),
                _row('Сложность', _diffLabel(sample.difficulty), Icons.bar_chart),
                const SizedBox(height: 16),

                // Материалы
                if (sample.products.isNotEmpty) ...[
                  Text('Рекомендуемые материалы',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
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

                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 44),
                    foregroundColor: const Color(0xFF1E3A4A),
                    side: const BorderSide(color: Color(0xFF1E3A4A)),
                  ),
                  child: const Text('Закрыть'),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, IconData icon) => Padding(
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
