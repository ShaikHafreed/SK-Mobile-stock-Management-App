class CategoryModel {
  final int id;
  final String name;
  final String? description;
  final String? imageUrl;
  final bool isActive;
  final int? productCount;
  final int? totalStock;
  final int? lowStockCount;

  CategoryModel({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    this.isActive = true,
    this.productCount,
    this.totalStock,
    this.lowStockCount,
  });

  factory CategoryModel.fromJson(
      Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
      imageUrl: json['image_url'],
      isActive: json['is_active'] ?? true,
      productCount: json['product_count'],
      totalStock: json['total_stock'],
      lowStockCount: json['low_stock_count'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'image_url': imageUrl,
      'is_active': isActive,
      'product_count': productCount,
      'total_stock': totalStock,
      'low_stock_count': lowStockCount,
    };
  }
}