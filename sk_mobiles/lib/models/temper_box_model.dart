class TemperBoxItemModel {
  final int id;
  final int boxId;
  final String? boxName;
  final String mobileModel;
  final int quantity;
  final String? notes;
  final bool isLowStock;

  TemperBoxItemModel({
    required this.id,
    required this.boxId,
    this.boxName,
    required this.mobileModel,
    required this.quantity,
    this.notes,
    required this.isLowStock,
  });

  factory TemperBoxItemModel.fromJson(Map<String, dynamic> json) {
    return TemperBoxItemModel(
      id: json['id'],
      boxId: json['box_id'],
      boxName: json['box_name'],
      mobileModel: json['mobile_model'],
      quantity: json['quantity'] ?? 0,
      notes: json['notes'],
      isLowStock: json['is_low_stock'] ?? false,
    );
  }
}

class TemperBoxModel {
  final int id;
  final String boxName;
  final String? description;
  final int totalItems;
  final int totalStock;
  final int lowStockCount;
  final List<TemperBoxItemModel> items;

  TemperBoxModel({
    required this.id,
    required this.boxName,
    this.description,
    required this.totalItems,
    required this.totalStock,
    required this.lowStockCount,
    required this.items,
  });

  factory TemperBoxModel.fromJson(Map<String, dynamic> json) {
    return TemperBoxModel(
      id: json['id'],
      boxName: json['box_name'],
      description: json['description'],
      totalItems: json['total_items'] ?? 0,
      totalStock: json['total_stock'] ?? 0,
      lowStockCount: json['low_stock_count'] ?? 0,
      items: (json['items'] as List<dynamic>?)
              ?.map((i) => TemperBoxItemModel.fromJson(i))
              .toList() ??
          [],
    );
  }
}