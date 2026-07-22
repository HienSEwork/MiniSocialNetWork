import 'dart:convert';

class HardwareComponent {
  const HardwareComponent({
    required this.id,
    required this.type,
    required this.name,
    required this.brand,
    this.socket,
    required this.powerWatt,
    required this.psuWatt,
    required this.price,
    required this.specs,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  static const slots = ['CPU', 'MAINBOARD', 'RAM', 'GPU', 'PSU', 'CASE'];

  final String id;
  final String type;
  final String name;
  final String brand;
  final String? socket;
  final int powerWatt;
  final int psuWatt;
  final double price;
  final Map<String, String> specs;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory HardwareComponent.fromMap(Map<String, Object?> map) {
    final decoded = jsonDecode('${map['specs_json'] ?? '{}'}');
    return HardwareComponent(
      id: '${map['id'] ?? ''}',
      type: '${map['component_type'] ?? ''}',
      name: '${map['name'] ?? ''}',
      brand: '${map['brand'] ?? ''}',
      socket: map['socket']?.toString(),
      powerWatt: (map['power_watt'] as num?)?.toInt() ?? 0,
      psuWatt: (map['psu_watt'] as num?)?.toInt() ?? 0,
      price: (map['price'] as num?)?.toDouble() ?? 0,
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
    'component_type': type,
    'name': name,
    'brand': brand,
    'socket': socket,
    'power_watt': powerWatt,
    'psu_watt': psuWatt,
    'price': price,
    'specs_json': jsonEncode(specs),
    'is_active': isActive ? 1 : 0,
    'created_at': createdAt.toUtc().toIso8601String(),
    'updated_at': updatedAt.toUtc().toIso8601String(),
  };

  HardwareComponent copyWith({
    String? id,
    String? type,
    String? name,
    String? brand,
    String? socket,
    bool clearSocket = false,
    int? powerWatt,
    int? psuWatt,
    double? price,
    Map<String, String>? specs,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => HardwareComponent(
    id: id ?? this.id,
    type: type ?? this.type,
    name: name ?? this.name,
    brand: brand ?? this.brand,
    socket: clearSocket ? null : socket ?? this.socket,
    powerWatt: powerWatt ?? this.powerWatt,
    psuWatt: psuWatt ?? this.psuWatt,
    price: price ?? this.price,
    specs: specs ?? this.specs,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}

class PcBuild {
  const PcBuild({
    required this.id,
    required this.userId,
    required this.name,
    required this.totalCost,
    required this.totalWatt,
    required this.isCompatible,
    required this.createdAt,
    required this.updatedAt,
    this.components = const {},
  });

  final String id;
  final String userId;
  final String name;
  final double totalCost;
  final int totalWatt;
  final bool isCompatible;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, HardwareComponent> components;

  factory PcBuild.fromMap(Map<String, Object?> map) => PcBuild(
    id: '${map['id'] ?? ''}',
    userId: '${map['user_id'] ?? ''}',
    name: '${map['name'] ?? ''}',
    totalCost: (map['total_cost'] as num?)?.toDouble() ?? 0,
    totalWatt: (map['total_watt'] as num?)?.toInt() ?? 0,
    isCompatible: (map['is_compatible'] as num?)?.toInt() == 1,
    createdAt: DateTime.tryParse('${map['created_at']}') ?? DateTime(1970),
    updatedAt: DateTime.tryParse('${map['updated_at']}') ?? DateTime(1970),
    components: (map['components'] as Map? ?? const {}).map(
      (key, value) => MapEntry(
        '$key',
        HardwareComponent.fromMap(Map<String, Object?>.from(value as Map)),
      ),
    ),
  );

  Map<String, Object?> toMap() => {
    'id': id,
    'user_id': userId,
    'name': name,
    'total_cost': totalCost,
    'total_watt': totalWatt,
    'is_compatible': isCompatible ? 1 : 0,
    'created_at': createdAt.toUtc().toIso8601String(),
    'updated_at': updatedAt.toUtc().toIso8601String(),
    'components': components.map((key, value) => MapEntry(key, value.toMap())),
  };

  PcBuild copyWith({
    String? id,
    String? userId,
    String? name,
    double? totalCost,
    int? totalWatt,
    bool? isCompatible,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, HardwareComponent>? components,
  }) => PcBuild(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    name: name ?? this.name,
    totalCost: totalCost ?? this.totalCost,
    totalWatt: totalWatt ?? this.totalWatt,
    isCompatible: isCompatible ?? this.isCompatible,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    components: components ?? this.components,
  );

  Map<String, Object?> databaseMap() =>
      Map<String, Object?>.from(toMap())..remove('components');
}

class PcCompatibilityResult {
  const PcCompatibilityResult({
    required this.totalCost,
    required this.totalWatt,
    required this.requiredPsuWatt,
    required this.isComplete,
    required this.errors,
  });

  final double totalCost;
  final int totalWatt;
  final int requiredPsuWatt;
  final bool isComplete;
  final List<String> errors;
  bool get isCompatible => isComplete && errors.isEmpty;

  factory PcCompatibilityResult.fromMap(Map<String, Object?> map) =>
      PcCompatibilityResult(
        totalCost: (map['total_cost'] as num?)?.toDouble() ?? 0,
        totalWatt: (map['total_watt'] as num?)?.toInt() ?? 0,
        requiredPsuWatt: (map['required_psu_watt'] as num?)?.toInt() ?? 0,
        isComplete: map['is_complete'] == true || map['is_complete'] == 1,
        errors: (map['errors'] as List? ?? const [])
            .map((item) => '$item')
            .toList(),
      );

  Map<String, Object?> toMap() => {
    'total_cost': totalCost,
    'total_watt': totalWatt,
    'required_psu_watt': requiredPsuWatt,
    'is_complete': isComplete,
    'errors': errors,
  };

  PcCompatibilityResult copyWith({
    double? totalCost,
    int? totalWatt,
    int? requiredPsuWatt,
    bool? isComplete,
    List<String>? errors,
  }) => PcCompatibilityResult(
    totalCost: totalCost ?? this.totalCost,
    totalWatt: totalWatt ?? this.totalWatt,
    requiredPsuWatt: requiredPsuWatt ?? this.requiredPsuWatt,
    isComplete: isComplete ?? this.isComplete,
    errors: errors ?? this.errors,
  );
}

class PcCompatibilityEngine {
  PcCompatibilityEngine._();

  static PcCompatibilityResult evaluate(
    Map<String, HardwareComponent> selected,
  ) {
    final totalCost = selected.values.fold<double>(
      0,
      (sum, item) => sum + item.price,
    );
    final totalWatt = selected.values.fold<int>(
      0,
      (sum, item) => sum + item.powerWatt,
    );
    final requiredPsu = (totalWatt * 1.25).ceil();
    final errors = <String>[];
    final cpu = selected['CPU'];
    final board = selected['MAINBOARD'];
    if (cpu != null && board != null && cpu.socket != board.socket) {
      errors.add(
        'Socket CPU ${cpu.socket ?? 'không rõ'} không khớp mainboard ${board.socket ?? 'không rõ'}.',
      );
    }
    final psu = selected['PSU'];
    if (psu != null && requiredPsu > psu.psuWatt) {
      errors.add(
        'Nguồn ${psu.psuWatt}W chưa đủ mức dự phòng 25% (cần tối thiểu ${requiredPsu}W).',
      );
    }
    return PcCompatibilityResult(
      totalCost: totalCost,
      totalWatt: totalWatt,
      requiredPsuWatt: requiredPsu,
      isComplete: HardwareComponent.slots.every(selected.containsKey),
      errors: errors,
    );
  }
}
