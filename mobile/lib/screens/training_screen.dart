import 'package:flutter/material.dart';

// ─── Data model ───────────────────────────────────────────────────────────────

enum Difficulty { beginner, medium, pro }

extension DifficultyX on Difficulty {
  String get label {
    switch (this) {
      case Difficulty.beginner: return 'Начинающий';
      case Difficulty.medium:   return 'Средний';
      case Difficulty.pro:      return 'Профессионал';
    }
  }

  Color get color {
    switch (this) {
      case Difficulty.beginner: return const Color(0xFF22C55E);
      case Difficulty.medium:   return const Color(0xFFF59E0B);
      case Difficulty.pro:      return const Color(0xFFEF4444);
    }
  }

  IconData get icon {
    switch (this) {
      case Difficulty.beginner: return Icons.sentiment_satisfied_alt;
      case Difficulty.medium:   return Icons.sentiment_neutral;
      case Difficulty.pro:      return Icons.sentiment_very_dissatisfied;
    }
  }
}

enum PhaseType { prep, layer, polish, finish, paint }

extension PhaseTypeX on PhaseType {
  Color get color {
    switch (this) {
      case PhaseType.prep:   return const Color(0xFF78716C);
      case PhaseType.layer:  return const Color(0xFF3B82F6);
      case PhaseType.polish: return const Color(0xFF8B5CF6);
      case PhaseType.finish: return const Color(0xFFF59E0B);
      case PhaseType.paint:  return const Color(0xFFEC4899);
    }
  }

  IconData get icon {
    switch (this) {
      case PhaseType.prep:   return Icons.cleaning_services_outlined;
      case PhaseType.layer:  return Icons.layers_outlined;
      case PhaseType.polish: return Icons.auto_fix_high_outlined;
      case PhaseType.finish: return Icons.star_outline;
      case PhaseType.paint:  return Icons.brush_outlined;
    }
  }
}

class TrainingPhase {
  final String title;
  final PhaseType type;
  final String? waitTime;
  final String? tip;
  final List<String> steps;

  const TrainingPhase({
    required this.title,
    required this.type,
    this.waitTime,
    this.tip,
    required this.steps,
  });
}

class TrainingArticle {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Difficulty difficulty;
  final String duration;
  final List<String> tools;
  final List<String> materials;
  final List<TrainingPhase> phases;
  final List<String> tips;
  final List<String> mistakes;
  final List<String> tags;

  const TrainingArticle({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.difficulty,
    required this.duration,
    required this.tools,
    required this.materials,
    required this.phases,
    required this.tips,
    required this.mistakes,
    required this.tags,
  });
}

// ─── Knowledge base ───────────────────────────────────────────────────────────

const _articles = <TrainingArticle>[
  // 1. Surface Preparation (universal)
  TrainingArticle(
    id: 'prep',
    title: 'Подготовка основания',
    subtitle: 'Универсальный первый шаг для любой штукатурки',
    icon: Icons.cleaning_services_outlined,
    color: Color(0xFF78716C),
    difficulty: Difficulty.beginner,
    duration: '1 день',
    tags: ['подготовка', 'база', 'универсальный'],
    tools: [
      'Правило 2 м',
      'Шпатель широкий 30–40 см',
      'Шпатель узкий 10 см',
      'Валик для грунта',
      'Кисть для углов',
      'Наждачная 80–120',
      'Пылесос / влажная тряпка',
    ],
    materials: [
      'Грунтовка глубокого проникновения',
      'Шпаклёвка финишная',
      'Армирующая лента (серпянка)',
      'Вода',
    ],
    phases: [
      TrainingPhase(
        title: 'Осмотр и очистка',
        type: PhaseType.prep,
        steps: [
          'Снять все выключатели, розетки, плинтусы',
          'Простучать поверхность — пустоты удалить или заделать',
          'Убрать старое покрытие, которое отслаивается',
          'Обезжирить жирные пятна (уайт-спирит или антисиликон)',
          'Удалить плесень хлорсодержащим раствором, обработать фунгицидом',
          'Пропылесосить, протереть слегка влажной тряпкой',
        ],
        tip: 'Основание должно быть прочным, чистым, обезжиренным — «ЧОС»',
      ),
      TrainingPhase(
        title: 'Ремонт трещин',
        type: PhaseType.prep,
        steps: [
          'Расшить трещины шпателем под углом 45° — расширить до 3–5 мм',
          'Грунтовать трещину кистью',
          'Узкие трещины — заполнить шпаклёвкой без армирования',
          'Трещины шире 3 мм — проклеить серпянку, зашпаклевать',
          'Срезать шпателем заподлицо после высыхания',
          'Зашлифовать наждачной 80–120',
        ],
        waitTime: 'Высыхание шпаклёвки: 4–12 часов',
        tip: 'Не игнорируйте трещины — они вернутся через 3–6 месяцев',
      ),
      TrainingPhase(
        title: 'Проверка ровности',
        type: PhaseType.prep,
        steps: [
          'Приложить правило 2 м в разных направлениях',
          'Отклонение под венецианскую — не более 1–2 мм',
          'Под жидкие обои, травертин — допустимо 3–4 мм',
          'Выступы срезать шпателем или болгаркой',
          'Впадины более 3 мм выравнивать шпаклёвкой',
        ],
      ),
      TrainingPhase(
        title: 'Грунтование',
        type: PhaseType.layer,
        steps: [
          'Нанести первый слой грунта валиком, углы — кистью',
          'Выдержать 2–4 часа до полного высыхания',
          'Нанести второй слой грунта',
          'Перед нанесением штукатурки — ещё один слой грунта',
        ],
        waitTime: 'Каждый слой грунта: 2–4 часа',
        tip: 'Впитывающие основания (газоблок, кирпич) — грунтовать 3 слоя',
      ),
    ],
    tips: [
      'Влажность стены не более 4% — проверить полиэтиленовым тестом: плёнка 50×50 см, залепить скотчем на 48 ч, конденсат = стена сырая',
      'Температура воздуха при работе: +15…+25 °C',
      'Без хорошей подготовки самая дорогая штукатурка не продержится год',
      'Поверхность после грунта должна быть чуть шершавой на ощупь — это норма',
    ],
    mistakes: [
      'Грунтовать сырую поверхность — грунт не проникает, покрытие отслоится',
      'Шпаклевать без расшивки трещин — через год трещина пойдёт снова',
      'Пропустить слой грунта из экономии — плохая адгезия, вздутия',
      'Не убрать пыль после шлифовки — слой лежит на «подшипнике» из пыли',
    ],
  ),

  // 2. Venetian plaster
  TrainingArticle(
    id: 'venetian',
    title: 'Венецианская штукатурка',
    subtitle: 'Эффект полированного мрамора с глубоким блеском',
    icon: Icons.diamond_outlined,
    color: Color(0xFF7C5CBF),
    difficulty: Difficulty.pro,
    duration: '3–4 дня',
    tags: ['венецианская', 'мрамор', 'глянец', 'блеск'],
    tools: [
      'Венецианский шпатель 12–15 см (нержавейка)',
      'Широкий шпатель 30–35 см',
      'Полировочный шпатель (гибкий, нержавейка)',
      'Шлифблок + наждачная 400–600',
      'Восковой шпатель или мягкая ткань',
      'Правило 2 м для проверки основания',
    ],
    materials: [
      'Венецианская штукатурка (2–3 кг/м²)',
      'Колер универсальный',
      'Акриловая грунтовка',
      'Декоративный воск (карнаубский или акриловый)',
    ],
    phases: [
      TrainingPhase(
        title: 'Подготовка основания',
        type: PhaseType.prep,
        steps: [
          'Выровнять стену до допуска 1–2 мм на 2 м правила',
          'Нанести 2 слоя акрилового грунта с интервалом 2–4 ч',
          'Тонировать штукатурку колером до финального цвета',
          'Сделать пробный образец на гипсокартоне — дождаться высыхания',
        ],
        tip: 'Венецианка требует идеально ровного основания — каждый бугор будет виден под углом света',
      ),
      TrainingPhase(
        title: '1-й слой — база',
        type: PhaseType.layer,
        steps: [
          'Нанести тонкий слой ≤0.5 мм хаотичными мазками',
          'Держать шпатель под углом 15–30° к поверхности',
          'Двигаться в разных направлениях — нет системы',
          'Покрыть полностью, без просветов',
          'Слегка выровнять в конце широким шпателем',
        ],
        waitTime: 'Сушка: 4–6 часов (полная, до матовости)',
      ),
      TrainingPhase(
        title: '2-й слой — рисунок',
        type: PhaseType.layer,
        steps: [
          'Направление мазков перпендикулярно первому слою',
          'Шпатель почти параллельно стене — угол ≤10°',
          'Слегка перекрывать предыдущий слой',
          'Варьировать размер и форму мазков — создать «рисунок мрамора»',
          'Тонкие участки выравнивать, оставлять небольшие просветы',
        ],
        waitTime: 'Сушка: 4–6 часов',
        tip: 'Не нажимать сильно — инструмент скользит, не вдавливается',
      ),
      TrainingPhase(
        title: '3-й слой + горячая полировка',
        type: PhaseType.polish,
        steps: [
          'Нанести очень тонкий слой — почти прозрачный',
          'Работать секция за секцией (~0.3–0.5 м²)',
          'Пока материал ещё чуть влажный — полировать чистым сухим шпателем',
          'Давить с нажимом, быстрые круговые или дугообразные движения',
          'Чем сильнее нажим — тем ярче глянец',
          'Немедленно убирать инструментом любые «усики» и наплывы',
        ],
        waitTime: 'Полная сушка перед финишем: 12–24 часа',
        tip: 'Полировку делать только на свежем слое — по сухому блеска не будет',
      ),
      TrainingPhase(
        title: 'Финиш — воск или лак',
        type: PhaseType.finish,
        steps: [
          'Нанести воск шпателем или мягкой тканью тонким слоем',
          'Растирать круговыми движениями по всей поверхности',
          'Дать воску «схватиться» 15–20 минут',
          'Полировать чистой хлопковой тканью до зеркального блеска',
          'При необходимости — 2-й слой воска через 24 часа',
        ],
        tip: 'Воск защищает от влаги и пыли, поддерживает блеск',
      ),
    ],
    tips: [
      'Шпатель должен быть идеально чистым — даже мелкие частицы оставляют царапины',
      'Работать при боковом освещении — видны все дефекты в процессе',
      'Всегда готовить пробный образец на гипсокартоне — проверить цвет после высыхания',
      'Один непрерывный «заход» на секцию — стыки видны',
      'Конец рабочего дня — всегда на углу или архитектурном элементе',
    ],
    mistakes: [
      'Толстые слои (более 1 мм) → трещины при высыхании',
      'Полировать полностью сухой слой → нет блеска, только царапины',
      'Загрязнённый шпатель → полосы и крапины на всей поверхности',
      'Работать без пробного образца → сюрприз с цветом после высыхания',
      'Спешить с сушкой → вздутия, плохая адгезия между слоями',
    ],
  ),

  // 3. Liquid wallpaper
  TrainingArticle(
    id: 'liquid',
    title: 'Жидкие обои (Шёлк / Велюр)',
    subtitle: 'Мягкая бархатистая фактура без швов и стыков',
    icon: Icons.grain,
    color: Color(0xFF4A8A6E),
    difficulty: Difficulty.beginner,
    duration: '2 дня',
    tags: ['жидкие обои', 'шёлк', 'велюр', 'бархат'],
    tools: [
      'Шпатель 20–30 см (пластиковый или нержавейка)',
      'Гребень или резиновый шпатель для разравнивания',
      'Валик + кисть для грунтовки',
      'Малярная лента',
      'Губка натуральная (для исправления)',
    ],
    materials: [
      'Жидкие обои (1 упаковка ≈ 1.5–2 м²)',
      'Акриловый грунт белый (обязательно белый!)',
      'Финишный акриловый лак (для влажных помещений)',
      'Вода',
    ],
    phases: [
      TrainingPhase(
        title: 'Подготовка основания',
        type: PhaseType.prep,
        steps: [
          'Основание: гипсокартон или тщательно отшпаклёванная стена',
          'Загрунтовать БЕЛЫМ акриловым грунтом — 2 слоя',
          'Важно: любой цвет, который просвечивает через жидкие обои, будет виден',
          'Заклеить малярной лентой потолок, плинтусы, розетки',
        ],
        waitTime: 'Сушка белого грунта: 24 часа',
        tip: 'Жёлтый или розовый грунт — цвет обоев уйдёт: нужен строго белый',
      ),
      TrainingPhase(
        title: 'Замешивание',
        type: PhaseType.prep,
        steps: [
          'Вскрыть упаковку, высыпать в ёмкость',
          'Залить холодной водой по инструкции (обычно 3–4 литра на кг)',
          'Тщательно перемешать руками или миксером',
          'Оставить набухнуть 30–60 минут, перемешать ещё раз',
          'Консистенция готовой массы — густая сметана',
        ],
        tip: 'Сухую смесь можно разделить — наносить по частям, остаток хранить',
      ),
      TrainingPhase(
        title: 'Нанесение',
        type: PhaseType.layer,
        steps: [
          'Начинать от угла или от верхнего края стены',
          'Набирать небольшое количество на шпатель',
          'Наносить вертикальными полосами 30–40 см',
          'Разравнивать гребнем или влажным шпателем по горизонтали',
          'Толщина слоя: 1.5–2 мм',
          'На стыке полос — размыть край и аккуратно соединить без нажима',
          'Не переходить на стык несколько раз — будет видна граница',
        ],
        waitTime: 'Сушка: 24–48 часов',
        tip: 'Все мазки в одном направлении — тогда фактура выглядит однородно',
      ),
      TrainingPhase(
        title: 'Финиш — лакировка',
        type: PhaseType.finish,
        steps: [
          'Дать полностью высохнуть (24–48 ч, не торопить)',
          'Нанести акриловый лак валиком тонким слоем',
          'Углы — кистью',
          'Дать высохнуть 4–6 часов',
          'Нанести второй слой лака',
        ],
        tip: 'Лак особенно важен на кухне и в ванной — защита от брызг и влаги',
      ),
    ],
    tips: [
      'Температура воздуха при нанесении и сушке: +15…+25 °C',
      'Избегать сквозняков и прямого солнца во время сушки',
      'Дефекты легко исправить: смочить водой и разгладить',
      'Жидкие обои можно наносить поверх обоев (без кафеля и краски)',
    ],
    mistakes: [
      'Цветной или жёлтый грунт — цвет обоев искажается или уходит',
      'Сквозняки при сушке — трещины и отслоения',
      'Слишком толстый слой → провисание и долгое (3–5 дней) высыхание',
      'Торопить сушку феном — коробление и неравномерная усадка',
      'Не лакировать в ванной — жидкие обои намокнут и отвалятся',
    ],
  ),

  // 4. Marmorin
  TrainingArticle(
    id: 'marmorin',
    title: 'Марморин',
    subtitle: 'Имитация мрамора с прожилками и перламутром',
    icon: Icons.blur_circular_outlined,
    color: Color(0xFF0EA5E9),
    difficulty: Difficulty.medium,
    duration: '3 дня',
    tags: ['марморин', 'мрамор', 'прожилки', 'перламутр'],
    tools: [
      'Шпатели 10, 20, 30 см (нержавейка)',
      'Шпатель полировочный (гибкий)',
      'Натуральная губка',
      'Восковой шпатель или мягкая ткань',
    ],
    materials: [
      'Марморин основной цвет (2–3 кг/м²)',
      'Марморин 2-й цвет (светлый / контрастный)',
      'Марморин 3-й цвет для прожилок (опционально)',
      'Декоративный воск',
    ],
    phases: [
      TrainingPhase(
        title: 'Подготовка',
        type: PhaseType.prep,
        steps: [
          'Ровная поверхность — как под венецианскую (≤2 мм на 2 м)',
          'Два слоя акрилового грунта',
          'Подготовить все 2–3 цвета марморина заранее',
          'Изучить образец или фото натурального мрамора',
        ],
      ),
      TrainingPhase(
        title: '1-й слой — базовый фон',
        type: PhaseType.layer,
        steps: [
          'Нанести основной цвет тонко (~0.3–0.5 мм)',
          'Хаотичные мазки шпателем 20–30 см',
          'Покрыть всю поверхность равномерно',
          'В конце разгладить широким шпателем',
        ],
        waitTime: 'Сушка: 4–6 часов',
      ),
      TrainingPhase(
        title: '2-й слой — мраморный рисунок',
        type: PhaseType.layer,
        steps: [
          'Нанести второй цвет небольшими пятнами и мазками (20–30% поверхности)',
          'Пока свежий — смочить губку в воде, слегка отжать',
          'Губкой размыть края пятен — плавный переход к основному цвету',
          'Если есть 3-й цвет: нанести тонкие прожилки шпателем 10 см',
          'Прожилки — одним движением под углом 30–45°, рука чуть дрожит',
          'Прожилки должны быть ломаными, не идеально прямыми',
          'Размыть края прожилок губкой слегка',
        ],
        waitTime: 'Сушка: 4–6 часов',
        tip: 'Смотрите на натуральный мрамор — у него нет одинаковых прожилок',
      ),
      TrainingPhase(
        title: 'Полировка',
        type: PhaseType.polish,
        steps: [
          'После полного высыхания полировать сухим жёстким шпателем',
          'Движения в разных направлениях с нажимом',
          'Поверхность должна стать гладкой и блестящей',
        ],
        waitTime: 'После полировки — 2 часа перед финишем',
      ),
      TrainingPhase(
        title: 'Финиш — воск',
        type: PhaseType.finish,
        steps: [
          'Нанести воск шпателем или тканью круговыми движениями',
          'Дать 15–20 минут схватиться',
          'Полировать чистой хлопковой тканью — появляется перламутровый блеск',
        ],
        tip: 'Воск усиливает перламутровый эффект — главная «изюминка» марморина',
      ),
    ],
    tips: [
      'Изучите фото натурального мрамора до начала — не придумывайте рисунок «в голове»',
      'Прожилки: меньше — лучше, чем слишком много',
      'Губку промывать чистой водой между применениями',
    ],
    mistakes: [
      'Прямые идеальные прожилки — выглядит как рисунок, не как камень',
      'Слишком много цветов и прожилок — хаос вместо мрамора',
      'Полировать не дав полностью высохнуть — смазывается рисунок',
      'Нажимать губкой сильно — стирается рисунок, нужно лёгкое касание',
    ],
  ),

  // 5. Travertine
  TrainingArticle(
    id: 'travertine',
    title: 'Травертин',
    subtitle: 'Фактура пористого камня с эффектом состаренности',
    icon: Icons.texture,
    color: Color(0xFFC47B2B),
    difficulty: Difficulty.medium,
    duration: '2–3 дня',
    tags: ['травертин', 'камень', 'поры', 'состаривание'],
    tools: [
      'Шпатель 20–30 см',
      'Жёсткая кисть или щётка',
      'Скомканная бумага / целлофан (для пор)',
      'Поролоновый валик',
      'Наждачная 80–120',
      'Широкая кисть или губка для лессировки',
    ],
    materials: [
      'Структурная штукатурка (травертин / «барашек» крупный)',
      'Акриловый грунт',
      'Лессировочная краска (тоньше и темнее фона)',
      'Акриловый лак матовый',
    ],
    phases: [
      TrainingPhase(
        title: 'Подготовка',
        type: PhaseType.prep,
        steps: [
          'Загрунтовать поверхность акриловым грунтом',
          'Допускается лёгкая шероховатость — травертин скрывает неровности',
          'Отклонение до 5 мм на 2 м — допустимо',
        ],
        waitTime: 'Грунт: 4–6 часов',
      ),
      TrainingPhase(
        title: 'Нанесение структуры',
        type: PhaseType.layer,
        steps: [
          'Нанести штукатурку шпателем горизонтальными полосами',
          'Толщина 2–4 мм, неравномерно — намеренно',
          'Создать «наслоения» — как природные пласты',
          'Пока материал свежий (15–20 мин) — создать поры:',
          '  · Жёсткой кистью сделать горизонтальные потёртости',
          '  · Или прижать скомканный целлофан и оторвать',
          '  · Или проткнуть в нескольких местах кончиком шпателя',
          'Цель: поверхность должна быть неровной с ямками и порами',
        ],
        waitTime: 'Сушка: 12–24 часа',
      ),
      TrainingPhase(
        title: 'Шлифовка выступов',
        type: PhaseType.polish,
        steps: [
          'После полного высыхания — лёгкая шлифовка наждачной 80–120',
          'Шлифовать только выступы — поры оставить',
          'Убрать пыль слегка влажной тканью',
        ],
      ),
      TrainingPhase(
        title: 'Лессировка — эффект камня',
        type: PhaseType.paint,
        steps: [
          'Разбавить лессировочную краску (темнее фона на 2–3 тона)',
          'Нанести широкой кистью или губкой на всю поверхность',
          'Сразу снять с выступов чистой ветошью или губкой',
          'В порах и углублениях краска остаётся — создаёт глубину',
          'При необходимости — повторить лессировку в 2 слоя',
        ],
        waitTime: 'Каждый слой лессировки: 4–6 часов',
        tip: 'Смотрите под углом — должна появиться иллюзия глубины камня',
      ),
      TrainingPhase(
        title: 'Защитный лак',
        type: PhaseType.finish,
        steps: [
          'Нанести акриловый матовый лак в 1–2 слоя',
          'Глянцевый лак не используется — камень должен быть матовым',
        ],
        waitTime: 'Лак: 6–8 часов',
      ),
    ],
    tips: [
      'Работать быстро пока материал свежий — формирование пор только в первые 20 мин',
      'Горизонтальные полосы имитируют природные слои — вертикальные смотрятся неестественно',
      'Тестировать лессировку на образце — тёмная краска сильно меняет вид',
    ],
    mistakes: [
      'Ровный однородный слой — потеряет весь эффект камня',
      'Слишком тёмная лессировка — смотрится как грязь, не как камень',
      'Шлифовать поры — вся фактура уничтожается',
      'Использовать глянцевый лак — камень должен быть матовым',
    ],
  ),

  // 6. Relief / Bas-relief
  TrainingArticle(
    id: 'relief',
    title: 'Барельеф / Объёмный декор',
    subtitle: 'Лепной рельеф из декоративной массы на стене',
    icon: Icons.filter_hdr_outlined,
    color: Color(0xFFEC4899),
    difficulty: Difficulty.pro,
    duration: '3–5 дней',
    tags: ['барельеф', 'объём', 'лепка', 'декор'],
    tools: [
      'Шпатели 10, 15, 20 см',
      'Стеки для лепки (деревянные или пластиковые)',
      'Трафарет или карандаш для переноса рисунка',
      'Кисти №2, №6, №12',
      'Малярная лента',
      'Мелкая губка',
    ],
    materials: [
      'Декоративная масса для барельефа (гипс, акрил или полимер)',
      'Акриловый грунт',
      'Акриловые краски (несколько оттенков)',
      'Декоративная патина или воск',
    ],
    phases: [
      TrainingPhase(
        title: 'Эскиз и перенос рисунка',
        type: PhaseType.prep,
        steps: [
          'Разработать или выбрать рисунок',
          'Распечатать трафарет в нужном размере',
          'Перевести карандашом или маркером на поверхность',
          'Разметить уровни рельефа: фон (0), средний план (3–5 мм), передний план (5–8+ мм)',
        ],
      ),
      TrainingPhase(
        title: 'Грунтование',
        type: PhaseType.prep,
        steps: [
          'Загрунтовать рабочую зону акриловым грунтом',
          'Зашкурить слегка для лучшей адгезии',
        ],
        waitTime: 'Грунт: 4–6 часов',
      ),
      TrainingPhase(
        title: 'Наращивание объёма',
        type: PhaseType.layer,
        steps: [
          'Начинать с элементов самого высокого рельефа (передний план)',
          'Нанести декоративную массу шпателем или стеком',
          'Слой не более 5–6 мм за один проход — иначе трещины',
          'Несколько тонких слоёв лучше одного толстого',
          'Перед новым слоем слегка смочить предыдущий водой',
        ],
        waitTime: 'Каждый слой: 2–4 часа',
        tip: 'Увлажнять предыдущий слой перед нанесением нового — иначе плохое сцепление',
      ),
      TrainingPhase(
        title: 'Лепка деталей',
        type: PhaseType.layer,
        steps: [
          'Работать с чуть влажным материалом (добавить воды если подсох)',
          'Стеком формировать контуры, прожилки, углубления',
          'Пальцем разглаживать переходы к фону',
          'Мокрой губкой убирать лишнее',
          'Детали прорабатывать пока масса ещё пластична',
        ],
        waitTime: 'Полная сушка: 24–48 часов',
      ),
      TrainingPhase(
        title: 'Базовая покраска',
        type: PhaseType.paint,
        steps: [
          'Покрыть весь барельеф базовым цветом (основной тон)',
          'Дать высохнуть',
          'Нанести более тёмный оттенок кистью в углубления',
          'Убрать лишнее с выступов, пока не высохло',
        ],
        waitTime: 'Сушка краски: 1–2 часа между слоями',
      ),
      TrainingPhase(
        title: 'Финишная патина',
        type: PhaseType.finish,
        steps: [
          'Нанести сухой кистью светлый цвет или золото на выступы',
          'Движение кисти — лёгкое касание самих выступов',
          'При необходимости — нанести патину или воск',
          'Покрыть акриловым лаком для защиты',
        ],
      ),
    ],
    tips: [
      'Несколько тонких слоёв всегда лучше одного толстого — это ключевое правило барельефа',
      'Сфотографировать прогресс каждого слоя — помогает следить за симметрией',
      'Работать при хорошем боковом освещении — видна вся объёмность',
    ],
    mistakes: [
      'Толстый слой за один проход → трещины при высыхании и отслоение',
      'Наносить новый слой на сухой без смачивания → плохое сцепление, отваливается',
      'Торопить сушку — трещины и деформация',
      'Тёмный фон вместо базовой подготовки → патина не читается',
    ],
  ),

  // 7. Microcement
  TrainingArticle(
    id: 'microcement',
    title: 'Микроцемент',
    subtitle: 'Гладкое бесшовное покрытие в стиле лофт и минимализм',
    icon: Icons.layers_outlined,
    color: Color(0xFF64748B),
    difficulty: Difficulty.medium,
    duration: '2–3 дня',
    tags: ['микроцемент', 'лофт', 'гладкая', 'бесшовная', 'минимализм'],
    tools: [
      'Широкий нержавеющий шпатель 40–50 см',
      'Шлифблок + наждачная 120, 220, 400',
      'Валик короткошёрстный + кисть',
      'Малярная лента и плёнка для защиты',
    ],
    materials: [
      'Микроцемент базовый слой',
      'Микроцемент финишный слой',
      'Кварцевая (адгезионная) грунтовка',
      'Пропитка (воск / полиуретановый лак / эпокси)',
      'Колер при необходимости',
    ],
    phases: [
      TrainingPhase(
        title: 'Подготовка (критично важна)',
        type: PhaseType.prep,
        steps: [
          'Микроцемент 1.5–3 мм тонкий — повторяет ВСЁ что под ним',
          'Заделать все трещины, проверить углы уровнем',
          'На стыки ГКЛ/плиты — серпянка + шпаклёвка',
          'Нанести кварцевую (адгезионную) грунтовку — обязательно',
          'Тест на влажность: плёнка 50×50 см на 48 ч',
        ],
        waitTime: 'Адгезионный грунт: 24 часа',
        tip: 'Без кварцевой грунтовки микроцемент плохо держится — не экономить',
      ),
      TrainingPhase(
        title: '1-й слой — базовый',
        type: PhaseType.layer,
        steps: [
          'Нанести шпателем крест-накрест равномерно',
          'Толщина 1.5–2 мм',
          'Добиться максимально ровного слоя — устранить все бугры',
          'Работать быстро — материал схватывается',
        ],
        waitTime: 'Сушка: 4–6 часов',
      ),
      TrainingPhase(
        title: 'Шлифовка после 1-го слоя',
        type: PhaseType.polish,
        steps: [
          'Отшлифовать наждачной 120 — убрать все рубцы, поднятые кромки',
          'При боковом освещении видны все неровности — устранить их',
          'Удалить пыль пылесосом и влажной тряпкой',
        ],
        tip: 'Боковое освещение (фонарик под углом) покажет все дефекты до финиша',
      ),
      TrainingPhase(
        title: '2-й слой — финишный',
        type: PhaseType.layer,
        steps: [
          'Нанести финишный микроцемент тонко — 0.5–1 мм',
          'Заполнить все поры и следы от шлифовки',
          'Движения в одну сторону для однородности текстуры',
          'Ближе к концу — слегка увлажнить шпатель для идеального скольжения',
        ],
        waitTime: 'Сушка: 6–8 часов',
      ),
      TrainingPhase(
        title: 'Финишная шлифовка',
        type: PhaseType.polish,
        steps: [
          'Шлифовать последовательно: 220, затем 400',
          'Поверхность должна стать шёлковой на ощупь',
          'Убрать всю пыль — это критично перед пропиткой',
        ],
      ),
      TrainingPhase(
        title: 'Пропитка — защита',
        type: PhaseType.finish,
        steps: [
          'Выбрать пропитку по влажности помещения:',
          '  · Жилые зоны — воск или матовый акрил',
          '  · Ванная / кухня — полиуретановый лак 2-3 слоя',
          '  · Пол — эпоксидная пропитка',
          'Нанести первый слой равномерно валиком',
          'После высыхания — шлифовка 400, удалить пыль',
          'Нанести второй слой пропитки',
        ],
        tip: 'Водостойкость целиком зависит от качества пропитки — не экономить',
      ),
    ],
    tips: [
      'Освещение сбоку (торшер / фонарик) перед нанесением финишного слоя — найти все дефекты',
      'Тест влажности обязателен — сырое основание даёт пузыри и отслоения',
      'Все инструменты должны быть идеально чистыми — частицы оставляют борозды',
      'Микроцемент на полу требует более плотной пропитки, чем на стенах',
    ],
    mistakes: [
      'Экономить на шлифовке — видны все следы от шпателя, рубцы',
      'Сырое основание → пузыри, отслоения через 1–2 месяца',
      'Тонкий слой на неровном основании → трещины по неровностям',
      'Не шлифовать между нанесением пропитки → ворс и шероховатость',
      'Пропустить кварцевый грунт → плохая адгезия, микроцемент «сползает»',
    ],
  ),
];

// ─── Screens ──────────────────────────────────────────────────────────────────

class TrainingScreen extends StatefulWidget {
  const TrainingScreen({super.key});

  @override
  State<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends State<TrainingScreen> {
  final _searchC = TextEditingController();
  Difficulty? _diffFilter;
  String _query = '';

  @override
  void dispose() {
    _searchC.dispose();
    super.dispose();
  }

  List<TrainingArticle> get _filtered {
    final q = _query.toLowerCase();
    return _articles.where((a) {
      final matchDiff = _diffFilter == null || a.difficulty == _diffFilter;
      final matchQ = q.isEmpty ||
          a.title.toLowerCase().contains(q) ||
          a.subtitle.toLowerCase().contains(q) ||
          a.tags.any((t) => t.contains(q));
      return matchDiff && matchQ;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Column(children: [
      _buildHeader(),
      Expanded(
        child: filtered.isEmpty
            ? const Center(child: Text('Ничего не найдено', style: TextStyle(color: Colors.grey)))
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _ArticleCard(
                  article: filtered[i],
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => _ArticleDetailScreen(article: filtered[i])),
                  ),
                ),
              ),
      ),
    ]);
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _searchC,
            decoration: InputDecoration(
              hintText: 'Поиск по технике...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () => setState(() { _searchC.clear(); _query = ''; }),
                    )
                  : null,
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
          child: Row(children: [
            _filterChip('Все', null),
            const SizedBox(width: 6),
            ...Difficulty.values.map((d) => Padding(
              padding: const EdgeInsets.only(right: 6),
              child: _filterChip(d.label, d),
            )),
          ]),
        ),
      ]),
    );
  }

  Widget _filterChip(String label, Difficulty? d) {
    final active = _diffFilter == d;
    final color = d?.color ?? const Color(0xFF1E3A4A);
    return GestureDetector(
      onTap: () => setState(() => _diffFilter = d),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active ? color : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? color : color.withOpacity(0.25)),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: active ? Colors.white : color)),
      ),
    );
  }
}

// ─── Article card ─────────────────────────────────────────────────────────────

class _ArticleCard extends StatelessWidget {
  final TrainingArticle article;
  final VoidCallback onTap;
  const _ArticleCard({required this.article, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Container(width: 5, color: article.color),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: article.color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(article.icon, size: 22, color: article.color),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(article.title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 2),
                        Text(article.subtitle,
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            maxLines: 2, overflow: TextOverflow.ellipsis),
                      ]),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    _pill(
                      Icons.schedule_outlined,
                      article.duration,
                      Colors.grey.shade600,
                      Colors.grey.shade100,
                    ),
                    const SizedBox(width: 8),
                    _pill(
                      article.difficulty.icon,
                      article.difficulty.label,
                      article.difficulty.color,
                      article.difficulty.color.withOpacity(0.1),
                    ),
                    const Spacer(),
                    Icon(Icons.chevron_right, color: Colors.grey.shade400),
                  ]),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _pill(IconData icon, String label, Color fg, Color bg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
        ]),
      );
}

// ─── Article detail ───────────────────────────────────────────────────────────

class _ArticleDetailScreen extends StatelessWidget {
  final TrainingArticle article;
  const _ArticleDetailScreen({required this.article});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(slivers: [
        _buildAppBar(context),
        SliverToBoxAdapter(child: _buildBody(context)),
      ]),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 160,
      pinned: true,
      backgroundColor: article.color,
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.fromLTRB(56, 0, 16, 14),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(article.title,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [article.color, article.color.withOpacity(0.7)],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 50),
            child: Row(children: [
              Icon(article.icon, size: 40, color: Colors.white.withOpacity(0.9)),
              const SizedBox(width: 16),
              Expanded(
                child: Text(article.subtitle,
                    style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.9)),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Overview chips
        _overviewCard(),
        const SizedBox(height: 16),

        // Tools & Materials
        _sectionTitle('Инструменты и материалы'),
        const SizedBox(height: 8),
        _toolsCard(),
        const SizedBox(height: 16),

        // Phases timeline
        _sectionTitle('Пошаговый процесс'),
        const SizedBox(height: 8),
        ...article.phases.asMap().entries.map((e) =>
            _PhaseCard(phase: e.value, isLast: e.key == article.phases.length - 1)),

        const SizedBox(height: 16),

        // Tips
        if (article.tips.isNotEmpty) ...[
          _sectionTitle('Советы мастера'),
          const SizedBox(height: 8),
          _tipsCard(),
          const SizedBox(height: 16),
        ],

        // Mistakes
        if (article.mistakes.isNotEmpty) ...[
          _sectionTitle('Частые ошибки'),
          const SizedBox(height: 8),
          _mistakesCard(),
        ],

        const SizedBox(height: 32),
      ]),
    );
  }

  Widget _sectionTitle(String text) => Text(text,
      style: TextStyle(
          fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey.shade500, letterSpacing: 0.5));

  Widget _overviewCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          _overviewItem(Icons.schedule_outlined, 'Время', article.duration),
          const SizedBox(width: 16),
          _overviewItem(article.difficulty.icon, 'Уровень', article.difficulty.label,
              color: article.difficulty.color),
          const SizedBox(width: 16),
          _overviewItem(Icons.layers_outlined, 'Этапов', '${article.phases.length}'),
        ]),
      ),
    );
  }

  Widget _overviewItem(IconData icon, String label, String value, {Color? color}) {
    final c = color ?? const Color(0xFF1E3A4A);
    return Expanded(
      child: Column(children: [
        Icon(icon, size: 22, color: c),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: c),
            textAlign: TextAlign.center),
      ]),
    );
  }

  Widget _toolsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _subSection('Инструменты', Icons.hardware_outlined, const Color(0xFF1E3A4A),
              article.tools),
          const SizedBox(height: 12),
          _subSection('Материалы', Icons.inventory_2_outlined, const Color(0xFF4A8A6E),
              article.materials),
        ]),
      ),
    );
  }

  Widget _subSection(String label, IconData icon, Color color, List<String> items) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
        ]),
        const SizedBox(height: 8),
        ...items.map((t) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Container(
                      width: 5, height: 5,
                      decoration: BoxDecoration(color: color.withOpacity(0.6), shape: BoxShape.circle)),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(t, style: const TextStyle(fontSize: 13))),
              ]),
            )),
      ]);

  Widget _tipsCard() => Card(
        color: const Color(0xFFF0FDF4),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: article.tips.map((tip) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.lightbulb_outline, size: 16, color: Color(0xFF16A34A)),
                const SizedBox(width: 8),
                Expanded(child: Text(tip, style: const TextStyle(fontSize: 13))),
              ]),
            )).toList(),
          ),
        ),
      );

  Widget _mistakesCard() => Card(
        color: const Color(0xFFFFF1F2),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: article.mistakes.map((m) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.warning_amber_outlined, size: 16, color: Color(0xFFDC2626)),
                const SizedBox(width: 8),
                Expanded(child: Text(m, style: const TextStyle(fontSize: 13))),
              ]),
            )).toList(),
          ),
        ),
      );
}

// ─── Phase card (timeline style) ─────────────────────────────────────────────

class _PhaseCard extends StatefulWidget {
  final TrainingPhase phase;
  final bool isLast;
  const _PhaseCard({required this.phase, required this.isLast});

  @override
  State<_PhaseCard> createState() => _PhaseCardState();
}

class _PhaseCardState extends State<_PhaseCard> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final color = widget.phase.type.color;
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // Timeline column
        SizedBox(
          width: 32,
          child: Column(children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Icon(widget.phase.type.icon, size: 15, color: Colors.white),
            ),
            if (!widget.isLast)
              Expanded(
                child: Container(
                  width: 2,
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  color: color.withOpacity(0.25),
                ),
              ),
          ]),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: widget.isLast ? 0 : 12),
            child: Card(
              margin: EdgeInsets.zero,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => setState(() => _expanded = !_expanded),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(widget.phase.title,
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.bold, color: color)),
                      ),
                      const Spacer(),
                      if (widget.phase.waitTime != null)
                        Row(children: [
                          Icon(Icons.timer_outlined, size: 12, color: Colors.grey.shade500),
                          const SizedBox(width: 3),
                          Text(widget.phase.waitTime!,
                              style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                          const SizedBox(width: 4),
                        ]),
                      Icon(_expanded ? Icons.expand_less : Icons.expand_more,
                          size: 18, color: Colors.grey.shade400),
                    ]),
                    if (_expanded) ...[
                      const SizedBox(height: 10),
                      ...widget.phase.steps.map((s) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: _StepRow(text: s, color: color),
                          )),
                      if (widget.phase.tip != null) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Icon(Icons.tips_and_updates_outlined, size: 14, color: color),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(widget.phase.tip!,
                                  style: TextStyle(fontSize: 12, color: color,
                                      fontStyle: FontStyle.italic)),
                            ),
                          ]),
                        ),
                      ],
                    ],
                  ]),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class _StepRow extends StatelessWidget {
  final String text;
  final Color color;
  const _StepRow({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    final isSubstep = text.startsWith('  ·');
    final displayText = isSubstep ? text.trimLeft().substring(2).trim() : text;
    return Padding(
      padding: EdgeInsets.only(left: isSubstep ? 16 : 0),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Container(
            width: isSubstep ? 4 : 6,
            height: isSubstep ? 4 : 6,
            decoration: BoxDecoration(
              color: isSubstep ? color.withOpacity(0.4) : color,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(displayText,
              style: TextStyle(fontSize: 13, color: isSubstep ? Colors.grey.shade700 : null)),
        ),
      ]),
    );
  }
}
