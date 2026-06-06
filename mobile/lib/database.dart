import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'models.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._();
  static Database? _db;

  AppDatabase._();

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final path = join(await getDatabasesPath(), 'decorator.db');
    return openDatabase(
      path,
      version: 3,
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
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        unit TEXT NOT NULL,
        price REAL NOT NULL,
        coverage REAL NOT NULL DEFAULT 0,
        category TEXT NOT NULL DEFAULT '',
        description TEXT NOT NULL DEFAULT ''
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS labor_rates (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        price_per_sqm REAL NOT NULL,
        unit TEXT NOT NULL DEFAULT 'м²'
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

  Future<void> _seed(Database db) async {
    await _seedProducts(db);
    await db.insert('labor_rates', {'name': 'Подготовка поверхности (шпаклёвка)', 'price_per_sqm': 250.0, 'unit': 'м²'});
    await db.insert('labor_rates', {'name': 'Нанесение грунтовки', 'price_per_sqm': 80.0, 'unit': 'м²'});
    await db.insert('labor_rates', {'name': 'Нанесение декоративной штукатурки', 'price_per_sqm': 450.0, 'unit': 'м²'});
    await db.insert('labor_rates', {'name': 'Венецианская штукатурка (2–3 слоя)', 'price_per_sqm': 1200.0, 'unit': 'м²'});
    await db.insert('labor_rates', {'name': 'Покрытие воском/лаком', 'price_per_sqm': 150.0, 'unit': 'м²'});

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
    // Key plasters with coverage for calculator
    final plasters = [
      {'name': 'DECORAZZA Stucco Veneziano', 'unit': 'кг', 'price': 980.0, 'coverage': 0.35, 'category': 'Штукатурки', 'description': 'Венецианская штукатурка, эффект полированного мрамора'},
      {'name': 'DECORAZZA Art Beton',         'unit': 'кг', 'price': 720.0, 'coverage': 0.8,  'category': 'Штукатурки', 'description': 'Эффект декоративного бетона, стиль лофт'},
      {'name': 'DECORAZZA Travertino',         'unit': 'кг', 'price': 540.0, 'coverage': 1.2,  'category': 'Штукатурки', 'description': 'Имитация натурального травертина'},
      {'name': 'DECORAZZA Romano',             'unit': 'кг', 'price': 420.0, 'coverage': 2.5,  'category': 'Штукатурки', 'description': 'Фактурная штукатурка'},
      {'name': 'DECORAZZA Rustic',             'unit': 'кг', 'price': 380.0, 'coverage': 3.0,  'category': 'Штукатурки', 'description': 'Грубая фактура, вид натурального камня'},
      {'name': 'DECORAZZA Barilievo',          'unit': 'кг', 'price': 580.0, 'coverage': 1.8,  'category': 'Штукатурки', 'description': 'Рельефная штукатурка с объёмными узорами'},
      {'name': 'BAYRAMIX Mineral',             'unit': 'кг', 'price': 220.0, 'coverage': 3.2,  'category': 'Штукатурки', 'description': 'Минеральная фасадная штукатурка'},
      {'name': 'BAYRAMIX Baytera (Короед)',    'unit': 'кг', 'price': 260.0, 'coverage': 3.5,  'category': 'Штукатурки', 'description': 'Фактурная штукатурка типа короед'},
      {'name': 'BAYRAMIX Gravol (Камешковая)', 'unit': 'кг', 'price': 240.0, 'coverage': 2.8,  'category': 'Штукатурки', 'description': 'Зернистая штукатурка'},
      {'name': 'Грунтовка адгезионная',        'unit': 'л',  'price': 180.0, 'coverage': 6.0,  'category': 'Штукатурки', 'description': 'Под декоративные штукатурки'},
      {'name': 'Воск защитный прозрачный',     'unit': 'л',  'price': 420.0, 'coverage': 8.0,  'category': 'Штукатурки', 'description': 'Финишная защита поверхности'},
    ];
    for (final p in plasters) {
      batch.insert('products', p);
    }
    await batch.commit(noResult: true);
  }

  // ─── Products ─────────────────────────────────────────────────────────────

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
    return db.insert('products', p.toMap()..remove('id'));
  }

  Future<void> deleteProduct(int id) async {
    final db = await database;
    await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  // ─── Labor rates ─────────────────────────────────────────────────────────

  Future<List<LaborRate>> getLaborRates() async {
    final db = await database;
    final rows = await db.query('labor_rates');
    return rows.map(LaborRate.fromMap).toList();
  }

  Future<int> insertLaborRate(LaborRate r) async {
    final db = await database;
    return db.insert('labor_rates', r.toMap()..remove('id'));
  }

  Future<void> deleteLaborRate(int id) async {
    final db = await database;
    await db.delete('labor_rates', where: 'id = ?', whereArgs: [id]);
  }

  // ─── Invoices ─────────────────────────────────────────────────────────────

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

  // ─── Onboarding ───────────────────────────────────────────────────────────

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

  // ─── Settings ─────────────────────────────────────────────────────────────

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
