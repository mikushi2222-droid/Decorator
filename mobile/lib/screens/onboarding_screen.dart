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

  static const _cards = [
    _CardData(
      icon: Icons.palette_outlined,
      label: 'Добро пожаловать',
      title: 'Декоратор',
      body:
          'Приложение для мастеров декоративной отделки ООО «АКЦЕНТ».\n\nРасчёт материалов и работ, оформление накладных и работа с каталогом — всё в одном месте, без интернета.',
    ),
    _CardData(
      icon: Icons.calculate_outlined,
      label: 'Шаг 1',
      title: 'Калькулятор',
      body:
          'Введите площадь или размеры помещения, выберите штукатурку и виды работ.\n\nКалькулятор мгновенно покажет расход материала, количество упаковок и итоговую стоимость.',
    ),
    _CardData(
      icon: Icons.receipt_long_outlined,
      label: 'Шаг 2',
      title: 'Накладные',
      body:
          'Создавайте расходные накладные с данными клиента и перечнем товаров.\n\nЭкспортируйте в PDF и отправляйте прямо с телефона через любой мессенджер.',
    ),
    _CardData(
      icon: Icons.inventory_2_outlined,
      label: 'Шаг 3',
      title: 'Каталог · 550+ позиций',
      body:
          'Полный прайс-лист РРЦ:\nKIITOS · OLSTA · DECORAZZA · BAYRAMIX · PRORAB · ECOTINT · Инструменты.\n\nПоиск по названию, фильтр по брендам.',
    ),
    _CardData(
      icon: Icons.settings_outlined,
      label: 'Шаг 4',
      title: 'Настройки',
      body:
          'Заполните реквизиты организации — они автоматически появятся на всех накладных.\n\nДобавляйте собственные товары с нормой расхода и настраивайте ставки работ.',
    ),
  ];

  Future<void> _finish() async {
    await AppDatabase.instance.markOnboardingShown();
    if (mounted) Navigator.pop(context);
  }

  void _next() {
    if (_page < _cards.length - 1) {
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _page == _cards.length - 1;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Верхняя строка: пропустить
            SizedBox(
              height: 52,
              child: Align(
                alignment: Alignment.centerRight,
                child: AnimatedOpacity(
                  opacity: isLast ? 0 : 1,
                  duration: const Duration(milliseconds: 200),
                  child: TextButton(
                    onPressed: isLast ? null : _finish,
                    child: const Text(
                      'Пропустить',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ),
                ),
              ),
            ),

            // Страницы
            Expanded(
              child: PageView.builder(
                controller: _ctrl,
                onPageChanged: (i) => setState(() => _page = i),
                itemCount: _cards.length,
                itemBuilder: (_, i) => _PageContent(card: _cards[i]),
              ),
            ),

            // Индикатор + кнопка
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 20, 28, 36),
              child: Row(
                children: [
                  // Точки
                  Row(
                    children: List.generate(_cards.length, (i) {
                      final active = i == _page;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        margin: const EdgeInsets.only(right: 6),
                        width: active ? 22 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: active ? kBrand : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const Spacer(),
                  // Кнопка
                  FilledButton(
                    onPressed: _next,
                    style: FilledButton.styleFrom(
                      backgroundColor: kBrand,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        isLast ? 'Начать!' : 'Далее',
                        key: ValueKey(isLast),
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Содержимое одной страницы ────────────────────────────────────────────────

class _PageContent extends StatelessWidget {
  final _CardData card;
  const _PageContent({required this.card});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 36),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Иконка в круге
          Container(
            width: 116,
            height: 116,
            decoration: BoxDecoration(
              color: kBrand,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: kBrand.withOpacity(0.22),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(card.icon, size: 54, color: Colors.white),
          ),
          const SizedBox(height: 40),

          // Метка
          Text(
            card.label.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: kBrand.withOpacity(0.55),
              letterSpacing: 1.8,
            ),
          ),
          const SizedBox(height: 10),

          // Заголовок
          Text(
            card.title,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: kBrand,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 22),

          // Описание
          Text(
            card.body,
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: Colors.grey.shade700,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Данные карточки ─────────────────────────────────────────────────────────

class _CardData {
  final IconData icon;
  final String label;
  final String title;
  final String body;
  const _CardData({
    required this.icon,
    required this.label,
    required this.title,
    required this.body,
  });
}
