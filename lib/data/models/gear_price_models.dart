import 'dart:convert';
import 'dart:math' as math;

class GearProduct {
  const GearProduct({
    required this.id,
    required this.category,
    required this.brand,
    required this.model,
    required this.msrp,
    required this.annualDepreciation,
    required this.specs,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String category;
  final String brand;
  final String model;
  final double msrp;
  final double annualDepreciation;
  final Map<String, String> specs;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get displayName => '$brand $model';

  factory GearProduct.fromMap(Map<String, Object?> map) {
    final decoded = jsonDecode('${map['specs_json'] ?? '{}'}');
    return GearProduct(
      id: '${map['id'] ?? ''}',
      category: '${map['category'] ?? ''}',
      brand: '${map['brand'] ?? ''}',
      model: '${map['model'] ?? ''}',
      msrp: (map['msrp'] as num?)?.toDouble() ?? 0,
      annualDepreciation: (map['annual_depreciation'] as num?)?.toDouble() ?? 0,
      specs: decoded is Map
          ? decoded.map((key, value) => MapEntry('$key', '$value'))
          : const {},
      isActive: (map['is_active'] as num?)?.toInt() == 1,
      createdAt: DateTime.tryParse('${map['created_at']}') ?? DateTime(1970),
      updatedAt: DateTime.tryParse('${map['updated_at']}') ?? DateTime(1970),
    );
  }

  Map<String, Object?> toMap() => {
    'id': id,
    'category': category,
    'brand': brand,
    'model': model,
    'msrp': msrp,
    'annual_depreciation': annualDepreciation,
    'specs_json': jsonEncode(specs),
    'is_active': isActive ? 1 : 0,
    'created_at': createdAt.toUtc().toIso8601String(),
    'updated_at': updatedAt.toUtc().toIso8601String(),
  };

  GearProduct copyWith({
    String? id,
    String? category,
    String? brand,
    String? model,
    double? msrp,
    double? annualDepreciation,
    Map<String, String>? specs,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => GearProduct(
    id: id ?? this.id,
    category: category ?? this.category,
    brand: brand ?? this.brand,
    model: model ?? this.model,
    msrp: msrp ?? this.msrp,
    annualDepreciation: annualDepreciation ?? this.annualDepreciation,
    specs: specs ?? this.specs,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}

class GearClosetItem {
  const GearClosetItem({
    required this.id,
    required this.userId,
    required this.productId,
    required this.purchasePrice,
    required this.purchaseDate,
    required this.conditionPercent,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.product,
  });

  final String id;
  final String userId;
  final String productId;
  final double purchasePrice;
  final DateTime purchaseDate;
  final double conditionPercent;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final GearProduct? product;

  factory GearClosetItem.fromMap(Map<String, Object?> map) => GearClosetItem(
    id: '${map['id'] ?? ''}',
    userId: '${map['user_id'] ?? ''}',
    productId: '${map['product_id'] ?? ''}',
    purchasePrice: (map['purchase_price'] as num?)?.toDouble() ?? 0,
    purchaseDate:
        DateTime.tryParse('${map['purchase_date']}') ?? DateTime(1970),
    conditionPercent: (map['condition_percent'] as num?)?.toDouble() ?? 0,
    notes: '${map['notes'] ?? ''}',
    createdAt: DateTime.tryParse('${map['created_at']}') ?? DateTime(1970),
    updatedAt: DateTime.tryParse('${map['updated_at']}') ?? DateTime(1970),
    product: map['product'] is Map
        ? GearProduct.fromMap(Map<String, Object?>.from(map['product'] as Map))
        : null,
  );

  Map<String, Object?> toMap() => {
    'id': id,
    'user_id': userId,
    'product_id': productId,
    'purchase_price': purchasePrice,
    'purchase_date': purchaseDate.toUtc().toIso8601String(),
    'condition_percent': conditionPercent,
    'notes': notes,
    'created_at': createdAt.toUtc().toIso8601String(),
    'updated_at': updatedAt.toUtc().toIso8601String(),
    if (product != null) 'product': product!.toMap(),
  };

  GearClosetItem copyWith({
    String? id,
    String? userId,
    String? productId,
    double? purchasePrice,
    DateTime? purchaseDate,
    double? conditionPercent,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    GearProduct? product,
    bool clearProduct = false,
  }) => GearClosetItem(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    productId: productId ?? this.productId,
    purchasePrice: purchasePrice ?? this.purchasePrice,
    purchaseDate: purchaseDate ?? this.purchaseDate,
    conditionPercent: conditionPercent ?? this.conditionPercent,
    notes: notes ?? this.notes,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    product: clearProduct ? null : product ?? this.product,
  );

  Map<String, Object?> databaseMap() =>
      Map<String, Object?>.from(toMap())..remove('product');
}

class GearEstimate {
  const GearEstimate({
    required this.currentValue,
    required this.buyLow,
    required this.buyHigh,
    required this.sellLow,
    required this.sellHigh,
    required this.ageYears,
    required this.conditionPercent,
  });
  final double currentValue;
  final double buyLow;
  final double buyHigh;
  final double sellLow;
  final double sellHigh;
  final double ageYears;
  final double conditionPercent;

  factory GearEstimate.fromMap(Map<String, Object?> map) => GearEstimate(
    currentValue: (map['current_value'] as num?)?.toDouble() ?? 0,
    buyLow: (map['buy_low'] as num?)?.toDouble() ?? 0,
    buyHigh: (map['buy_high'] as num?)?.toDouble() ?? 0,
    sellLow: (map['sell_low'] as num?)?.toDouble() ?? 0,
    sellHigh: (map['sell_high'] as num?)?.toDouble() ?? 0,
    ageYears: (map['age_years'] as num?)?.toDouble() ?? 0,
    conditionPercent: (map['condition_percent'] as num?)?.toDouble() ?? 0,
  );
  Map<String, Object?> toMap() => {
    'current_value': currentValue,
    'buy_low': buyLow,
    'buy_high': buyHigh,
    'sell_low': sellLow,
    'sell_high': sellHigh,
    'age_years': ageYears,
    'condition_percent': conditionPercent,
  };
  GearEstimate copyWith({
    double? currentValue,
    double? buyLow,
    double? buyHigh,
    double? sellLow,
    double? sellHigh,
    double? ageYears,
    double? conditionPercent,
  }) => GearEstimate(
    currentValue: currentValue ?? this.currentValue,
    buyLow: buyLow ?? this.buyLow,
    buyHigh: buyHigh ?? this.buyHigh,
    sellLow: sellLow ?? this.sellLow,
    sellHigh: sellHigh ?? this.sellHigh,
    ageYears: ageYears ?? this.ageYears,
    conditionPercent: conditionPercent ?? this.conditionPercent,
  );
}

class GearDepreciationEngine {
  GearDepreciationEngine._();

  static GearEstimate estimate({
    required double msrp,
    required double annualDepreciation,
    required DateTime releaseDate,
    required double conditionPercent,
    DateTime? now,
  }) {
    final today = now ?? DateTime.now();
    final days = math.max(0, today.difference(releaseDate).inDays);
    final years = days / 365.25;
    final ageAdjusted =
        msrp * math.pow(1 - annualDepreciation.clamp(0, .95), years);
    final current = ageAdjusted * (conditionPercent.clamp(20, 100) / 100);
    return GearEstimate(
      currentValue: current,
      buyLow: current * .82,
      buyHigh: current * .92,
      sellLow: current * .94,
      sellHigh: current * 1.06,
      ageYears: years,
      conditionPercent: conditionPercent,
    );
  }
}
