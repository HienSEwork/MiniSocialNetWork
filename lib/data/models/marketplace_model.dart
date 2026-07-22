class MarketplaceItem {
  const MarketplaceItem({
    required this.id,
    required this.sellerId,
    required this.sellerName,
    required this.title,
    required this.description,
    required this.price,
    required this.category,
    required this.condition,
    required this.status,
    required this.createdDate,
    this.sellerAvatarUrl,
    this.mediaUrl,
  });

  factory MarketplaceItem.fromJson(Map<String, dynamic> json) =>
      MarketplaceItem(
        id: '${json['id'] ?? ''}',
        sellerId: '${json['sellerId'] ?? ''}',
        sellerName: '${json['sellerName'] ?? ''}',
        sellerAvatarUrl: json['sellerAvatarUrl']?.toString(),
        title: '${json['title'] ?? ''}',
        description: '${json['description'] ?? ''}',
        price: _asDouble(json['price']),
        category: '${json['category'] ?? ''}',
        condition: '${json['condition'] ?? ''}',
        mediaUrl: json['mediaUrl']?.toString(),
        status: _asInt(json['status']),
        createdDate:
            DateTime.tryParse('${json['createdDate'] ?? ''}') ?? DateTime.now(),
      );

  final String id;
  final String sellerId;
  final String sellerName;
  final String? sellerAvatarUrl;
  final String title;
  final String description;
  final double price;
  final String category;
  final String condition;
  final String? mediaUrl;
  final int status;
  final DateTime createdDate;

  bool get isSold => status == 1;
  bool get isActive => status == 0;

  static int _asInt(dynamic value) =>
      value is int ? value : int.tryParse('$value') ?? 0;

  static double _asDouble(dynamic value) =>
      value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
}

class MarketplaceStats {
  const MarketplaceStats({
    required this.sellerId,
    required this.activeCount,
    required this.soldCount,
    required this.limit,
  });

  factory MarketplaceStats.fromJson(Map<String, dynamic> json) =>
      MarketplaceStats(
        sellerId: '${json['sellerId'] ?? ''}',
        activeCount: _asInt(json['activeCount']),
        soldCount: _asInt(json['soldCount']),
        limit: _asInt(json['limit']) == 0 ? 5 : _asInt(json['limit']),
      );

  final String sellerId;
  final int activeCount;
  final int soldCount;
  final int limit;

  static int _asInt(dynamic value) =>
      value is int ? value : int.tryParse('$value') ?? 0;
}
