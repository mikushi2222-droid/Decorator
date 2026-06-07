import 'dart:convert';

// ─── Product ─────────────────────────────────────────────────────────────────

class Product {
  final int? id;
  final String name;
  final String unit;
  final double price;
  final double coverage;
  final String category;
  final String description;

  const Product({
    this.id,
    required this.name,
    required this.unit,
    required this.price,
    required this.coverage,
    required this.category,
    required this.description,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'unit': unit,
        'price': price,
        'coverage': coverage,
        'category': category,
        'description': description,
      };

  factory Product.fromMap(Map<String, dynamic> m) => Product(
        id: m['id'] as int?,
        name: m['name'] as String,
        unit: m['unit'] as String,
        price: (m['price'] as num).toDouble(),
        coverage: (m['coverage'] as num).toDouble(),
        category: (m['category'] as String?) ?? '',
        description: (m['description'] as String?) ?? '',
      );
}

// ─── LaborRate ────────────────────────────────────────────────────────────────

class LaborRate {
  final int? id;
  final String name;
  final double pricePerSqm;
  final String unit;
  final double marketMin;
  final double marketMedian;
  final double marketMax;

  const LaborRate({
    this.id,
    required this.name,
    required this.pricePerSqm,
    required this.unit,
    this.marketMin = 0,
    this.marketMedian = 0,
    this.marketMax = 0,
  });

  bool get hasMarketData => marketMax > 0;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'price_per_sqm': pricePerSqm,
        'unit': unit,
        'market_min': marketMin,
        'market_median': marketMedian,
        'market_max': marketMax,
      };

  factory LaborRate.fromMap(Map<String, dynamic> m) => LaborRate(
        id: m['id'] as int?,
        name: m['name'] as String,
        pricePerSqm: (m['price_per_sqm'] as num).toDouble(),
        unit: m['unit'] as String,
        marketMin: (m['market_min'] as num? ?? 0).toDouble(),
        marketMedian: (m['market_median'] as num? ?? 0).toDouble(),
        marketMax: (m['market_max'] as num? ?? 0).toDouble(),
      );
}

// ─── Invoice ──────────────────────────────────────────────────────────────────

enum InvoiceStatus { draft, sent, paid }

extension InvoiceStatusX on InvoiceStatus {
  String get label {
    switch (this) {
      case InvoiceStatus.draft: return 'Черновик';
      case InvoiceStatus.sent:  return 'Выставлена';
      case InvoiceStatus.paid:  return 'Оплачена';
    }
  }
}

InvoiceStatus invoiceStatusFromString(String s) =>
    InvoiceStatus.values.firstWhere((e) => e.name == s,
        orElse: () => InvoiceStatus.draft);

class InvoiceItem {
  final int? productId;
  final String productName;
  final String unit;
  final double quantity;
  final double price;

  const InvoiceItem({
    this.productId,
    required this.productName,
    required this.unit,
    required this.quantity,
    required this.price,
  });

  double get total => quantity * price;

  Map<String, dynamic> toMap() => {
        'product_id': productId,
        'product_name': productName,
        'unit': unit,
        'quantity': quantity,
        'price': price,
      };

  factory InvoiceItem.fromMap(Map<String, dynamic> m) => InvoiceItem(
        productId: m['product_id'] as int?,
        productName: m['product_name'] as String,
        unit: m['unit'] as String,
        quantity: (m['quantity'] as num).toDouble(),
        price: (m['price'] as num).toDouble(),
      );
}

class Invoice {
  final int? id;
  final String number;
  final DateTime date;
  final String clientName;
  final String clientPhone;
  final String clientAddress;
  final List<InvoiceItem> items;
  final double subtotal;
  final double discount;
  final double total;
  final InvoiceStatus status;
  final String notes;
  final DateTime createdAt;

  const Invoice({
    this.id,
    required this.number,
    required this.date,
    required this.clientName,
    required this.clientPhone,
    required this.clientAddress,
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.total,
    required this.status,
    required this.notes,
    required this.createdAt,
  });

  Invoice copyWith({InvoiceStatus? status}) => Invoice(
        id: id,
        number: number,
        date: date,
        clientName: clientName,
        clientPhone: clientPhone,
        clientAddress: clientAddress,
        items: items,
        subtotal: subtotal,
        discount: discount,
        total: total,
        status: status ?? this.status,
        notes: notes,
        createdAt: createdAt,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'number': number,
        'date': date.toIso8601String(),
        'client_name': clientName,
        'client_phone': clientPhone,
        'client_address': clientAddress,
        'items': jsonEncode(items.map((i) => i.toMap()).toList()),
        'subtotal': subtotal,
        'discount': discount,
        'total': total,
        'status': status.name,
        'notes': notes,
        'created_at': createdAt.toIso8601String(),
      };

  factory Invoice.fromMap(Map<String, dynamic> m) {
    final raw = jsonDecode(m['items'] as String) as List;
    return Invoice(
      id: m['id'] as int?,
      number: m['number'] as String,
      date: DateTime.parse(m['date'] as String),
      clientName: m['client_name'] as String,
      clientPhone: (m['client_phone'] as String?) ?? '',
      clientAddress: (m['client_address'] as String?) ?? '',
      items: raw.map((e) => InvoiceItem.fromMap(e as Map<String, dynamic>)).toList(),
      subtotal: (m['subtotal'] as num).toDouble(),
      discount: (m['discount'] as num).toDouble(),
      total: (m['total'] as num).toDouble(),
      status: invoiceStatusFromString(m['status'] as String),
      notes: (m['notes'] as String?) ?? '',
      createdAt: DateTime.parse(m['created_at'] as String),
    );
  }
}

// ─── StoreSettings ────────────────────────────────────────────────────────────

class StoreSettings {
  final int? id;
  final String name;
  final String address;
  final String phone;
  final String inn;
  final String kpp;
  final String ogrn;
  final String bankName;
  final String bankBik;
  final String bankAccount;
  final String bankCorrAccount;
  final String bankInn;
  final String bankKpp;
  final String adText;

  const StoreSettings({
    this.id,
    this.name = '',
    this.address = '',
    this.phone = '',
    this.inn = '',
    this.kpp = '',
    this.ogrn = '',
    this.bankName = '',
    this.bankBik = '',
    this.bankAccount = '',
    this.bankCorrAccount = '',
    this.bankInn = '',
    this.bankKpp = '',
    this.adText = '',
  });

  factory StoreSettings.defaults() => const StoreSettings(
        name: 'ООО "АКЦЕНТ"',
        inn: '7814860953',
        kpp: '781401001',
        ogrn: '1267800014206',
        bankName: 'СЕВЕРО-ЗАПАДНЫЙ БАНК ПАО СБЕРБАНК',
        bankBik: '044030653',
        bankAccount: '40702810555710020199',
        bankCorrAccount: '30101810500000000653',
        bankInn: '7707083893',
        bankKpp: '784243001',
        adText: 'Барельефы · Скалы · Травертин · Шёлк · Обучение и мастер-классы',
      );

  StoreSettings copyWith({
    String? name, String? address, String? phone,
    String? inn, String? kpp, String? ogrn,
    String? bankName, String? bankBik, String? bankAccount,
    String? bankCorrAccount, String? bankInn, String? bankKpp,
    String? adText,
  }) => StoreSettings(
        id: id,
        name: name ?? this.name,
        address: address ?? this.address,
        phone: phone ?? this.phone,
        inn: inn ?? this.inn,
        kpp: kpp ?? this.kpp,
        ogrn: ogrn ?? this.ogrn,
        bankName: bankName ?? this.bankName,
        bankBik: bankBik ?? this.bankBik,
        bankAccount: bankAccount ?? this.bankAccount,
        bankCorrAccount: bankCorrAccount ?? this.bankCorrAccount,
        bankInn: bankInn ?? this.bankInn,
        bankKpp: bankKpp ?? this.bankKpp,
        adText: adText ?? this.adText,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'address': address,
        'phone': phone,
        'inn': inn,
        'kpp': kpp,
        'ogrn': ogrn,
        'bank_name': bankName,
        'bank_bik': bankBik,
        'bank_account': bankAccount,
        'bank_corr_account': bankCorrAccount,
        'bank_inn': bankInn,
        'bank_kpp': bankKpp,
        'ad_text': adText,
      };

  factory StoreSettings.fromMap(Map<String, dynamic> m) => StoreSettings(
        id: m['id'] as int?,
        name: (m['name'] as String?) ?? '',
        address: (m['address'] as String?) ?? '',
        phone: (m['phone'] as String?) ?? '',
        inn: (m['inn'] as String?) ?? '',
        kpp: (m['kpp'] as String?) ?? '',
        ogrn: (m['ogrn'] as String?) ?? '',
        bankName: (m['bank_name'] as String?) ?? '',
        bankBik: (m['bank_bik'] as String?) ?? '',
        bankAccount: (m['bank_account'] as String?) ?? '',
        bankCorrAccount: (m['bank_corr_account'] as String?) ?? '',
        bankInn: (m['bank_inn'] as String?) ?? '',
        bankKpp: (m['bank_kpp'] as String?) ?? '',
        adText: (m['ad_text'] as String?) ?? '',
      );
}
