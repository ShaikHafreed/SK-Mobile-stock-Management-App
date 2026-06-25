class CategoryModel {
  final int id;
  final String name;
  final String slug;
  final String? icon;
  final String? imageUrl;
  final bool isDefault;
  final int totalProducts;
  final int totalStock;
  final int lowStockCount;

  CategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    this.icon,
    this.imageUrl,
    required this.isDefault,
    required this.totalProducts,
    required this.totalStock,
    required this.lowStockCount,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'],
      name: json['name'],
      slug: json['slug'],
      icon: json['icon'],
      imageUrl: json['image_url'],
      isDefault: json['is_default'] ?? false,
      totalProducts: json['total_products'] ?? 0,
      totalStock: json['total_stock'] ?? 0,
      lowStockCount: json['low_stock_count'] ?? 0,
    );
  }
}