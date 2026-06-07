import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'models.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._();
  static Database? _db;

  /// Версия справочников (товары + ставки работ). Увеличивается при любом
  /// изменении каталога или работ. Экраны Калькулятора и Каталога слушают её,
  /// чтобы перезагрузить данные — иначе из-за IndexedStack они показывали бы
  /// устаревший список до перезапуска приложения.
  final ValueNotifier<int> dataRevision = ValueNotifier<int>(0);
  void _bumpRevision() => dataRevision.value++;

  AppDatabase._();

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final String path;
    final desktop = !kIsWeb &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS);
    if (desktop) {
      final dir = await getApplicationSupportDirectory();
      path = join(dir.path, 'decorator.db');
    } else {
      path = join(await getDatabasesPath(), 'decorator.db');
    }
    return openDatabase(
      path,
      version: 9,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createTables(db);
    await _seed(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('DELETE FROM products');
      await _seedProducts(db);
    }
    if (oldVersion < 3) {
      await db.execute(
        'ALTER TABLE settings ADD COLUMN onboarding_shown INTEGER NOT NULL DEFAULT 0',
      );
    }
    if (oldVersion < 4) {
      // Добавить отсутствующие декоративные штукатурки в калькулятор.
      // Дедупликация по имени: на части установок (миграция с v1) они уже
      // могли быть добавлены свежим _seedProducts.
      final existing = (await db.query('products', columns: ['name']))
          .map((r) => r['name'] as String)
          .toSet();
      for (final p in _additionalPlasters()) {
        if (!existing.contains(p['name'])) {
          await db.insert('products', p);
        }
      }
    }
    if (oldVersion < 5) {
      // Добавить колонки рыночных цен (идемпотентно).
      for (final col in const ['market_min', 'market_median', 'market_max']) {
        try {
          await db.execute('ALTER TABLE labor_rates ADD COLUMN $col REAL NOT NULL DEFAULT 0');
        } catch (_) {
          // колонка уже существует
        }
      }
      // Обновить стандартные ставки по имени (цены до верха рынка + диапазоны),
      // НЕ трогая пользовательские ставки. Если стандартной ставки нет — добавить.
      for (final r in _standardLaborRates()) {
        final updated = await db.update(
          'labor_rates',
          {
            'price_per_sqm': r['price_per_sqm'],
            'market_min': r['market_min'],
            'market_median': r['market_median'],
            'market_max': r['market_max'],
          },
          where: 'name = ?',
          whereArgs: [r['name']],
        );
        if (updated == 0) {
          await db.insert('labor_rates', r);
        }
      }
    }
    if (oldVersion < 6) {
      await _createTextureSamplesTable(db);
    }
    if (oldVersion < 7) {
      try {
        await db.execute(
            'ALTER TABLE texture_samples ADD COLUMN image_path TEXT NOT NULL DEFAULT \'\'');
      } catch (_) {}
    }
    if (oldVersion < 8) {
      try {
        await db.execute(
            'ALTER TABLE products ADD COLUMN pack_size REAL NOT NULL DEFAULT 0');
      } catch (_) {}
    }
    if (oldVersion < 9) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS clients (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL UNIQUE,
          phone TEXT NOT NULL DEFAULT '',
          address TEXT NOT NULL DEFAULT '',
          updated_at TEXT NOT NULL DEFAULT ''
        )
      ''');
    }
  }

  Future<void> _createTextureSamplesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS texture_samples (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        grp TEXT NOT NULL,
        pattern TEXT NOT NULL,
        gradient TEXT NOT NULL DEFAULT '[]',
        description TEXT NOT NULL DEFAULT '',
        effect TEXT NOT NULL DEFAULT '',
        sheen INTEGER NOT NULL DEFAULT 0,
        difficulty INTEGER NOT NULL DEFAULT 1,
        price_range TEXT NOT NULL DEFAULT '',
        products TEXT NOT NULL DEFAULT '[]',
        sort_order INTEGER NOT NULL DEFAULT 0,
        image_path TEXT NOT NULL DEFAULT ''
      )
    ''');
  }

  Future<void> _createTables(Database db) async {
    await _createTextureSamplesTable(db);
    await db.execute('''
      CREATE TABLE IF NOT EXISTS products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        unit TEXT NOT NULL,
        price REAL NOT NULL,
        coverage REAL NOT NULL DEFAULT 0,
        category TEXT NOT NULL DEFAULT '',
        description TEXT NOT NULL DEFAULT '',
        pack_size REAL NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS labor_rates (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        price_per_sqm REAL NOT NULL,
        unit TEXT NOT NULL DEFAULT 'м²',
        market_min REAL NOT NULL DEFAULT 0,
        market_median REAL NOT NULL DEFAULT 0,
        market_max REAL NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS invoices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        number TEXT NOT NULL,
        date TEXT NOT NULL,
        client_name TEXT NOT NULL,
        client_phone TEXT NOT NULL DEFAULT '',
        client_address TEXT NOT NULL DEFAULT '',
        items TEXT NOT NULL DEFAULT '[]',
        subtotal REAL NOT NULL DEFAULT 0,
        discount REAL NOT NULL DEFAULT 0,
        total REAL NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'draft',
        notes TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS clients (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        phone TEXT NOT NULL DEFAULT '',
        address TEXT NOT NULL DEFAULT '',
        updated_at TEXT NOT NULL DEFAULT ''
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL DEFAULT '',
        address TEXT NOT NULL DEFAULT '',
        phone TEXT NOT NULL DEFAULT '',
        inn TEXT NOT NULL DEFAULT '',
        kpp TEXT NOT NULL DEFAULT '',
        ogrn TEXT NOT NULL DEFAULT '',
        bank_name TEXT NOT NULL DEFAULT '',
        bank_bik TEXT NOT NULL DEFAULT '',
        bank_account TEXT NOT NULL DEFAULT '',
        bank_corr_account TEXT NOT NULL DEFAULT '',
        bank_inn TEXT NOT NULL DEFAULT '',
        bank_kpp TEXT NOT NULL DEFAULT '',
        ad_text TEXT NOT NULL DEFAULT '',
        onboarding_shown INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  // Стандартные ставки. price_per_sqm = верхняя граница рынка (для выставления клиенту).
  // Используется и при первом seed, и при миграции (upsert по имени).
  List<Map<String, Object>> _standardLaborRates() => [
    {'name': '1-й слой декоративной штукатурки (база)', 'price_per_sqm': 450.0,   'unit': 'м²', 'market_min': 150.0,  'market_median': 280.0,  'market_max': 450.0},
    {'name': '2-й слой декоративной штукатурки (слой)', 'price_per_sqm': 650.0,   'unit': 'м²', 'market_min': 300.0,  'market_median': 450.0,  'market_max': 650.0},
    {'name': '3-й слой декоративной штукатурки (слой)', 'price_per_sqm': 600.0,   'unit': 'м²', 'market_min': 250.0,  'market_median': 400.0,  'market_max': 600.0},
    {'name': 'Шёлк',                   'price_per_sqm': 1600.0,  'unit': 'м²', 'market_min': 700.0,  'market_median': 1100.0, 'market_max': 1600.0},
    {'name': 'Велюр',                  'price_per_sqm': 1600.0,  'unit': 'м²', 'market_min': 700.0,  'market_median': 1100.0, 'market_max': 1600.0},
    {'name': 'Замша',                  'price_per_sqm': 1800.0,  'unit': 'м²', 'market_min': 900.0,  'market_median': 1350.0, 'market_max': 1800.0},
    {'name': 'Песок',                  'price_per_sqm': 900.0,   'unit': 'м²', 'market_min': 400.0,  'market_median': 650.0,  'market_max': 900.0},
    {'name': 'Травертин',              'price_per_sqm': 1800.0,  'unit': 'м²', 'market_min': 1000.0, 'market_median': 1400.0, 'market_max': 1800.0},
    {'name': 'Мармарин',               'price_per_sqm': 3000.0,  'unit': 'м²', 'market_min': 1500.0, 'market_median': 2200.0, 'market_max': 3000.0},
    {'name': 'Барельеф',               'price_per_sqm': 15000.0, 'unit': 'м²', 'market_min': 5000.0, 'market_median': 8500.0, 'market_max': 15000.0},
    {'name': 'Мрамор (венецианская)',  'price_per_sqm': 5000.0,  'unit': 'м²', 'market_min': 2500.0, 'market_median': 3800.0, 'market_max': 5000.0},
  ];

  Future<void> _seedLaborRates(Database db) async {
    for (final r in _standardLaborRates()) {
      await db.insert('labor_rates', r);
    }
  }

  List<Map<String, Object>> _additionalPlasters() => [
    // ─── DECORAZZA ────────────────────────────────────────────────────
    {'name': 'DECORAZZA Alcantara (Замша)',   'unit': 'кг', 'price': 6100.0, 'coverage': 0.12, 'category': 'Штукатурки', 'description': 'Эффект замши / Alcantara'},
    {'name': 'DECORAZZA Velours (Велюр)',     'unit': 'кг', 'price': 2880.0, 'coverage': 0.15, 'category': 'Штукатурки', 'description': 'Бархатистая текстура велюра'},
    {'name': 'DECORAZZA Velluto',             'unit': 'кг', 'price': 3350.0, 'coverage': 0.15, 'category': 'Штукатурки', 'description': 'Декоративное покрытие с эффектом велюра'},
    {'name': 'DECORAZZA Seta da Vinci (Шёлк)', 'unit': 'кг', 'price': 4470.0, 'coverage': 0.15, 'category': 'Штукатурки', 'description': 'Шелковистая поверхность, перламутровый блеск'},
    {'name': 'DECORAZZA Calce Veneziana',     'unit': 'кг', 'price': 1440.0, 'coverage': 0.4,  'category': 'Штукатурки', 'description': 'Венецианская известковая штукатурка'},
    {'name': 'DECORAZZA Wall Arte',           'unit': 'кг', 'price': 1020.0, 'coverage': 0.3,  'category': 'Штукатурки', 'description': 'Фактурная декоративная штукатурка'},
    {'name': 'DECORAZZA Lime Paint',          'unit': 'кг', 'price': 2440.0, 'coverage': 0.2,  'category': 'Штукатурки', 'description': 'Известковая краска, матовый эффект'},
    {'name': 'DECORAZZA Aretino',             'unit': 'кг', 'price': 3360.0, 'coverage': 0.15, 'category': 'Штукатурки', 'description': 'Жидкая декоративная штукатурка, перламутр'},
    {'name': 'DECORAZZA Brezza',              'unit': 'кг', 'price': 2850.0, 'coverage': 0.15, 'category': 'Штукатурки', 'description': 'Декоративная штукатурка с мерцанием'},
    {'name': 'DECORAZZA Traverta',            'unit': 'кг', 'price': 870.0,  'coverage': 1.5,  'category': 'Штукатурки', 'description': 'Имитация травертина, лёгкая фактура'},
    {'name': 'DECORAZZA Sollievo',            'unit': 'кг', 'price': 700.0,  'coverage': 1.5,  'category': 'Штукатурки', 'description': 'Рельефная штукатурка с крупной фактурой'},
    // ─── BAYRAMIX ──────────────────────────────────────────────────
    {'name': 'BAYRAMIX Мраморная штукатурка', 'unit': 'кг', 'price': 220.0, 'coverage': 1.5, 'category': 'Штукатурки', 'description': 'Декоративная мраморная штукатурка'},
    {'name': 'BAYRAMIX Colorix',              'unit': 'кг', 'price': 1100.0, 'coverage': 1.5, 'category': 'Штукатурки', 'description': 'Декоративная штукатурка с перламутром'},
    {'name': 'BAYRAMIX Micromineral',         'unit': 'кг', 'price': 350.0,  'coverage': 2.5, 'category': 'Штукатурки', 'description': 'Мелкозернистая минеральная штукатурка'},
    {'name': 'BAYRAMIX Macromineral',         'unit': 'кг', 'price': 335.0,  'coverage': 3.5, 'category': 'Штукатурки', 'description': 'Крупнозернистая минеральная штукатурка'},
    {'name': 'BAYRAMIX Sandeco',              'unit': 'кг', 'price': 250.0,  'coverage': 2.0, 'category': 'Штукатурки', 'description': 'Декоративная штукатурка-песок'},
    {'name': 'BAYRAMIX Ecostone',             'unit': 'кг', 'price': 220.0,  'coverage': 2.5, 'category': 'Штукатурки', 'description': 'Каменная декоративная штукатурка'},
    {'name': 'BAYRAMIX Decostone',            'unit': 'кг', 'price': 250.0,  'coverage': 2.8, 'category': 'Штукатурки', 'description': 'Декоративная штукатурка под камень'},
  ];

  Future<void> _seed(Database db) async {
    await _seedProducts(db);
    await _seedLaborRates(db);

    final s = StoreSettings.defaults();
    await db.insert('settings', {
      'name': s.name, 'address': s.address, 'phone': s.phone,
      'inn': s.inn, 'kpp': s.kpp, 'ogrn': s.ogrn,
      'bank_name': s.bankName, 'bank_bik': s.bankBik,
      'bank_account': s.bankAccount, 'bank_corr_account': s.bankCorrAccount,
      'bank_inn': s.bankInn, 'bank_kpp': s.bankKpp, 'ad_text': s.adText,
    });
  }

  Future<void> _seedProducts(Database db) async {
    final raw = await rootBundle.loadString('assets/products.json');
    final list = jsonDecode(raw) as List;

    final batch = db.batch();
    for (final item in list) {
      batch.insert('products', {
        'name': item['name'],
        'unit': item['unit'],
        'price': (item['price'] as num).toDouble(),
        'coverage': 0.0,
        'category': item['category'] ?? '',
        'description': item['description'] ?? '',
      });
    }

    // Основные штукатурки с нормой расхода (цены пересчитаны по прайсу)
    final corePlasters = [
      {'name': 'DECORAZZA Stucco Veneziano', 'unit': 'кг', 'price': 900.0,  'coverage': 0.35, 'category': 'Штукатурки', 'description': 'Венецианская штукатурка, эффект полированного мрамора'},
      {'name': 'DECORAZZA Art Beton',         'unit': 'кг', 'price': 940.0,  'coverage': 0.8,  'category': 'Штукатурки', 'description': 'Эффект декоративного бетона, стиль лофт'},
      {'name': 'DECORAZZA Travertino',         'unit': 'кг', 'price': 1260.0, 'coverage': 1.2,  'category': 'Штукатурки', 'description': 'Имитация натурального травертина'},
      {'name': 'DECORAZZA Romano',             'unit': 'кг', 'price': 675.0,  'coverage': 2.5,  'category': 'Штукатурки', 'description': 'Фактурная штукатурка'},
      {'name': 'DECORAZZA Rustic',             'unit': 'кг', 'price': 400.0,  'coverage': 3.0,  'category': 'Штукатурки', 'description': 'Грубая фактура, вид натурального камня'},
      {'name': 'DECORAZZA Barilievo',          'unit': 'кг', 'price': 790.0,  'coverage': 1.8,  'category': 'Штукатурки', 'description': 'Рельефная штукатурка с объёмными узорами'},
      {'name': 'BAYRAMIX Mineral',             'unit': 'кг', 'price': 355.0,  'coverage': 3.2,  'category': 'Штукатурки', 'description': 'Минеральная фасадная штукатурка'},
      {'name': 'BAYRAMIX Baytera (Короед)',    'unit': 'кг', 'price': 298.0,  'coverage': 3.5,  'category': 'Штукатурки', 'description': 'Фактурная штукатурка типа короед'},
      {'name': 'BAYRAMIX Gravol (Камешковая)', 'unit': 'кг', 'price': 245.0,  'coverage': 2.8,  'category': 'Штукатурки', 'description': 'Зернистая штукатурка'},
    ];
    for (final p in corePlasters) {
      batch.insert('products', p);
    }

    for (final p in _additionalPlasters()) {
      batch.insert('products', p);
    }

    await batch.commit(noResult: true);
  }

  // ─── Products ───────────────────────────────────────────────────────

  Future<List<Product>> getProducts() async {
    final db = await database;
    final rows = await db.query('products', orderBy: 'category, name');
    return rows.map(Product.fromMap).toList();
  }

  Future<List<Product>> searchProducts(String q, {String? category}) async {
    final db = await database;
    final like = '%${q.toLowerCase()}%';
    final where = <String>[];
    final args = <dynamic>[];
    if (q.isNotEmpty) {
      where.add('(LOWER(name) LIKE ? OR LOWER(description) LIKE ?)');
      args.addAll([like, like]);
    }
    if (category != null && category != 'Все') {
      where.add('category = ?');
      args.add(category);
    }
    final rows = await db.query(
      'products',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'name',
      limit: 80,
    );
    return rows.map(Product.fromMap).toList();
  }

  Future<List<String>> getCategories() async {
    final db = await database;
    final rows = await db.rawQuery(
        'SELECT DISTINCT category FROM products WHERE category != "" ORDER BY category');
    return rows.map((r) => r['category'] as String).toList();
  }

  Future<int> insertProduct(Product p) async {
    final db = await database;
    final id = await db.insert('products', p.toMap()..remove('id'));
    _bumpRevision();
    return id;
  }

  Future<void> updateProduct(Product p) async {
    if (p.id == null) return;
    final db = await database;
    await db.update('products', p.toMap()..remove('id'),
        where: 'id = ?', whereArgs: [p.id]);
    _bumpRevision();
  }

  Future<void> deleteProduct(int id) async {
    final db = await database;
    await db.delete('products', where: 'id = ?', whereArgs: [id]);
    _bumpRevision();
  }

  Future<int> countProducts() async {
    final db = await database;
    final rows = await db.rawQuery('SELECT COUNT(*) AS c FROM products');
    return (rows.first['c'] as int?) ?? 0;
  }

  // ─── Labor rates ───────────────────────────────────────────────

  Future<List<LaborRate>> getLaborRates() async {
    final db = await database;
    final rows = await db.query('labor_rates');
    return rows.map(LaborRate.fromMap).toList();
  }

  Future<int> insertLaborRate(LaborRate r) async {
    final db = await database;
    final id = await db.insert('labor_rates', r.toMap()..remove('id'));
    _bumpRevision();
    return id;
  }

  Future<void> deleteLaborRate(int id) async {
    final db = await database;
    await db.delete('labor_rates', where: 'id = ?', whereArgs: [id]);
    _bumpRevision();
  }

  // ─── Texture samples (галерея примеров) ──────────────────────────────
  // Работаем с «сырыми» map, чтобы БД не зависела от UI-типов (Color/enum) —
  // (де)сериализация в модель TextureSample живёт в samples_screen.dart.

  Future<List<Map<String, Object?>>> getTextureSamples() async {
    final db = await database;
    return db.query('texture_samples', orderBy: 'sort_order, id');
  }

  Future<int> textureSamplesCount() async {
    final db = await database;
    final rows = await db.rawQuery('SELECT COUNT(*) AS c FROM texture_samples');
    return (rows.first['c'] as int?) ?? 0;
  }

  Future<int> insertTextureSample(Map<String, Object?> m) async {
    final db = await database;
    return db.insert('texture_samples', m..remove('id'));
  }

  Future<void> updateTextureSample(int id, Map<String, Object?> m) async {
    final db = await database;
    await db.update('texture_samples', m..remove('id'),
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteTextureSample(int id) async {
    final db = await database;
    await db.delete('texture_samples', where: 'id = ?', whereArgs: [id]);
  }

  // ─── Invoices ─────────────────────────────────────────────────────

  Future<List<Invoice>> getInvoices() async {
    final db = await database;
    final rows = await db.query('invoices', orderBy: 'created_at DESC');
    return rows.map(Invoice.fromMap).toList();
  }

  Future<int> insertInvoice(Invoice inv) async {
    final db = await database;
    final map = inv.toMap()..remove('id');
    return db.insert('invoices', map);
  }

  Future<void> updateInvoice(Invoice inv) async {
    if (inv.id == null) return;
    final db = await database;
    await db.update('invoices', inv.toMap()..remove('id'),
        where: 'id = ?', whereArgs: [inv.id]);
  }

  Future<void> updateInvoiceStatus(int id, InvoiceStatus status) async {
    final db = await database;
    await db.update('invoices', {'status': status.name},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteInvoice(int id) async {
    final db = await database;
    await db.delete('invoices', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> getLastInvoiceSeq() async {
    final db = await database;
    final year = DateTime.now().year;
    final rows = await db.rawQuery(
      "SELECT number FROM invoices WHERE number LIKE 'АКЦ-$year-%' ORDER BY created_at DESC LIMIT 1",
    );
    if (rows.isEmpty) return 0;
    final num = rows.first['number'] as String;
    final parts = num.split('-');
    return int.tryParse(parts.last) ?? 0;
  }

  // ─── Clients ──────────────────────────────────────────────────────

  Future<List<Client>> searchClients(String q) async {
    final db = await database;
    final like = '%${q.toLowerCase()}%';
    final rows = await db.query('clients',
        where: 'LOWER(name) LIKE ?',
        whereArgs: [like],
        orderBy: 'name',
        limit: 10);
    return rows.map(Client.fromMap).toList();
  }

  Future<List<Client>> getAllClients() async {
    final db = await database;
    final rows = await db.query('clients', orderBy: 'name');
    return rows.map(Client.fromMap).toList();
  }

  Future<void> upsertClient(Client c) async {
    if (c.name.trim().isEmpty) return;
    final db = await database;
    await db.insert('clients', c.toMap()..remove('id'),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // ─── Onboarding ───────────────────────────────────────────────────

  Future<bool> isOnboardingShown() async {
    final db = await database;
    final rows = await db.query('settings',
        columns: ['onboarding_shown'], limit: 1);
    if (rows.isEmpty) return false;
    return (rows.first['onboarding_shown'] as int? ?? 0) == 1;
  }

  Future<void> markOnboardingShown() async {
    final db = await database;
    final rows = await db.query('settings', columns: ['id'], limit: 1);
    if (rows.isEmpty) {
      await db.insert('settings', {'onboarding_shown': 1});
    } else {
      await db.update(
        'settings',
        {'onboarding_shown': 1},
        where: 'id = ?',
        whereArgs: [rows.first['id']],
      );
    }
  }

  // ─── Settings ───────────────────────────────────────────────────────

  Future<StoreSettings> getSettings() async {
    final db = await database;
    final rows = await db.query('settings', limit: 1);
    if (rows.isEmpty) return StoreSettings.defaults();
    return StoreSettings.fromMap(rows.first);
  }

  Future<void> saveSettings(StoreSettings s) async {
    final db = await database;
    final map = s.toMap();
    if (s.id != null) {
      await db.update('settings', map, where: 'id = ?', whereArgs: [s.id]);
    } else {
      final existing = await db.query('settings', limit: 1);
      if (existing.isEmpty) {
        await db.insert('settings', map..remove('id'));
      } else {
        await db.update('settings', map,
            where: 'id = ?', whereArgs: [existing.first['id']]);
      }
    }
  }
}
