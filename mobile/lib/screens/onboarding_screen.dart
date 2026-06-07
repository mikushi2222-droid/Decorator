import 'package:flutter/material.dart';
import '../database.dart';
import '../main.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _ctrl = PageController();
  int _page = 0;

  // Профиль (заполняется на последних слайдах)
  final _nameC = TextEditingController();
  String _businessType = 'ip';

  static const _infoCards = [
    _CardData(
      icon: Icons.auto_awesome_outlined,
      label: 'Добро пожаловать',
      title: 'Декоратор',
      body: 'Приложение для мастеров и учеников декоративной отделки.\n\nКалькулятор, накладные, галерея фактур, обучение — всё офлайн, в одном месте.',
    ),
    _CardData(
      icon: Icons.calculate_outlined,
      label: 'Шаг 1',
      title: 'Калькулятор',
      body: 'Введите площадь помещения, выберите штукатурку и виды работ.\n\nМгновенный расчёт расхода, упаковок и итоговой стоимости.',
    ),
    _CardData(
      icon: Icons.receipt_long_outlined,
      label: 'Шаг 2',
      title: 'Накладные',
      body: 'Создавайте документы с данными клиента и перечнем товаров.\n\nЭкспортируйте в PDF — отправляйте через WhatsApp или Telegram.',
    ),
    _CardData(
      icon: Icons.palette_outlined,
      label: 'Шаг 3',
      title: 'Галерея и обучение',
      body: 'Библиотека покрытий с характеристиками и расходом материалов.\n\nПошаговые техники нанесения для начинающих и профессионалов.',
    ),
  ];

  // Общее количество страниц: info + name + business
  int get _totalPages => _infoCards.length + 2;
  bool get _isProfilePage => _page == _infoCards.length;
  bool get _isBusinessPage => _page == _infoCards.length + 1;
  bool get _isLast => _page == _totalPages - 1;
  bool get _isInfoPage => _page < _infoCards.length;

  Future<void> _finish() async {
    // Сохранить имя если введено
    final name = _nameC.text.trim();
    if (name.isNotEmpty) {
      await AppDatabase.instance.saveDecoratorName(name);
    }
    // Сохранить тип деятельности
    final settings = await AppDatabase.instance.getSettings();
    await AppDatabase.instance.saveSettings(
      settings.copyWith(businessType: _businessType),
    );
    await AppDatabase.instance.markOnboardingShown();
    if (mounted) Navigator.pop(context);
  }

  void _next() {
    if (_page < _totalPages - 1) {
      _ctrl.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _nameC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        child: Column(children: [
          // Пропустить
          SizedBox(
            height: 52,
            child: Align(
              alignment: Alignment.centerRight,
              child: AnimatedOpacity(
                opacity: _isLast ? 0 : 1,
                duration: const Duration(milliseconds: 200),
                child: TextButton(
                  onPressed: _isLast ? null : _finish,
                  child: const Text('Пропустить',
                      style: TextStyle(color: Color(0xFFAFA395), fontSize: 14)),
                ),
              ),
            ),
          ),

          // Страницы
          Expanded(
            child: PageView.builder(
              controller: _ctrl,
              onPageChanged: (i) => setState(() => _page = i),
              itemCount: _totalPages,
              itemBuilder: (_, i) {
                if (i < _infoCards.length) {
                  return _InfoPage(card: _infoCards[i]);
                } else if (i == _infoCards.length) {
                  return _NamePage(controller: _nameC);
                } else {
                  return _BusinessPage(
                    selected: _businessType,
                    onChanged: (v) => setState(() => _businessType = v),
                  );
                }
              },
            ),
          ),

          // Индикатор + кнопка
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 20, 28, 36),
            child: Row(children: [
              Row(
                children: List.generate(_totalPages, (i) {
                  final active = i == _page;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    margin: const EdgeInsets.only(right: 5),
                    width: active ? 20 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: active ? kBronze : kGold.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
              const Spacer(),
              FilledButton(
                onPressed: _next,
                style: FilledButton.styleFrom(
                  backgroundColor: kBronze,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    _isLast ? 'Начать!' : 'Далее',
                    key: ValueKey(_isLast),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ─── Info page ────────────────────────────────────────────────────────────────

class _InfoPage extends StatelessWidget {
  final _CardData card;
  const _InfoPage({required this.card});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 36),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 110, height: 110,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [kBronze, kGold],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: kBronze.withOpacity(0.25),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Icon(card.icon, size: 50, color: Colors.white),
        ),
        const SizedBox(height: 36),
        Text(card.label.toUpperCase(),
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: kBronze.withOpacity(0.6),
                letterSpacing: 1.8)),
        const SizedBox(height: 10),
        Text(card.title,
            style: const TextStyle(
                fontSize: 26, fontWeight: FontWeight.bold, color: kGraphite, height: 1.2),
            textAlign: TextAlign.center),
        const SizedBox(height: 20),
        Text(card.body,
            style: const TextStyle(fontSize: 15, height: 1.65, color: Color(0xFF6B6055)),
            textAlign: TextAlign.center),
      ]),
    );
  }
}

// ─── Name page ────────────────────────────────────────────────────────────────

class _NamePage extends StatelessWidget {
  final TextEditingController controller;
  const _NamePage({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 36),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 110, height: 110,
          decoration: BoxDecoration(
            color: kGoldLight,
            shape: BoxShape.circle,
            border: Border.all(color: kGold.withOpacity(0.5), width: 2),
          ),
          child: const Icon(Icons.person_outline_rounded, size: 52, color: kBronze),
        ),
        const SizedBox(height: 36),
        const Text('ЗНАКОМСТВО',
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700,
                color: Color(0xFFB8A090), letterSpacing: 1.8)),
        const SizedBox(height: 10),
        const Text('Как вас зовут?',
            style: TextStyle(
                fontSize: 26, fontWeight: FontWeight.bold, color: kGraphite, height: 1.2),
            textAlign: TextAlign.center),
        const SizedBox(height: 12),
        Text(
          'Приложение будет обращаться к вам по имени',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, height: 1.5, color: kGraphite.withOpacity(0.5)),
        ),
        const SizedBox(height: 32),
        TextField(
          controller: controller,
          textCapitalization: TextCapitalization.words,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: kGraphite),
          decoration: InputDecoration(
            hintText: 'Ваше имя',
            prefixIcon: const Icon(Icons.person_outline, color: kBronze),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE0D8CE)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: kBronze, width: 1.5),
            ),
          ),
        ),
      ]),
    );
  }
}

// ─── Business type page ───────────────────────────────────────────────────────

class _BusinessPage extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  const _BusinessPage({required this.selected, required this.onChanged});

  static const _types = [
    _BizType('ip', 'ИП', 'Индивидуальный предприниматель',
        Icons.person_outlined),
    _BizType('samozanyat', 'Самозанятый', 'Налог на профессиональный доход',
        Icons.badge_outlined),
    _BizType('ooo', 'ООО', 'Общество с ограниченной ответственностью',
        Icons.business_outlined),
    _BizType('fizlico', 'Физлицо', 'Частный мастер без регистрации',
        Icons.handyman_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 110, height: 110,
          decoration: BoxDecoration(
            color: kGoldLight,
            shape: BoxShape.circle,
            border: Border.all(color: kGold.withOpacity(0.5), width: 2),
          ),
          child: const Icon(Icons.business_center_outlined, size: 52, color: kBronze),
        ),
        const SizedBox(height: 30),
        const Text('ТИП ДЕЯТЕЛЬНОСТИ',
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700,
                color: Color(0xFFB8A090), letterSpacing: 1.8)),
        const SizedBox(height: 10),
        const Text('Как вы работаете?',
            style: TextStyle(
                fontSize: 26, fontWeight: FontWeight.bold, color: kGraphite),
            textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(
          'Влияет на оформление накладных\nи документов для клиентов',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, height: 1.5, color: kGraphite.withOpacity(0.5)),
        ),
        const SizedBox(height: 24),
        ...(_types.map((t) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GestureDetector(
            onTap: () => onChanged(t.key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: selected == t.key ? kGoldLight : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected == t.key ? kBronze : const Color(0xFFE0D8CE),
                  width: selected == t.key ? 1.5 : 1,
                ),
              ),
              child: Row(children: [
                Icon(t.icon, size: 22, color: selected == t.key ? kBronze : const Color(0xFFAFA395)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(t.label,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: selected == t.key ? kBronze : kGraphite)),
                    Text(t.description,
                        style: const TextStyle(fontSize: 12, color: Color(0xFFB0A090))),
                  ]),
                ),
                if (selected == t.key)
                  const Icon(Icons.check_circle_rounded, color: kBronze, size: 20),
              ]),
            ),
          ),
        ))),
      ]),
    );
  }
}

class _BizType {
  final String key;
  final String label;
  final String description;
  final IconData icon;
  const _BizType(this.key, this.label, this.description, this.icon);
}

// ─── Card data ────────────────────────────────────────────────────────────────

class _CardData {
  final IconData icon;
  final String label;
  final String title;
  final String body;
  const _CardData({
    required this.icon, required this.label,
    required this.title, required this.body,
  });
}
