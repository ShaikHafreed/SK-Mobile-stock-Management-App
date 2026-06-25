class ProductModel {
  final int id;
  final int categoryId;
  final String? categoryName;
  final String? brand;
  final String? productName;
  final String? mobileModel;
  final String? watts;
  final String? cableType;
  final String? imageUrl;
  final int quantity;
  final String? notes;
  final bool isLowStock;

  ProductModel({
    required this.id,
    required this.categoryId,
    this.categoryName,
    this.brand,
    this.productName,
    this.mobileModel,
    this.watts,
    this.cableType,
    this.imageUrl,
    required this.quantity,
    this.notes,
    required this.isLowStock,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'],
      categoryId: json['category_id'],
      categoryName: json['category_name'],
      brand: json['brand'],
      productName: json['product_name'],
      mobileModel: json['mobile_model'],
      watts: json['watts'],
      cableType: json['cable_type'],
      imageUrl: json['image_url'],
      quantity: json['quantity'] ?? 0,
      notes: json['notes'],
      isLowStock: json['is_low_stock'] ?? false,
    );
  }

  String get displayName {
    if (mobileModel != null && mobileModel!.isNotEmpty) return mobileModel!;
    if (productName != null && productName!.isNotEmpty) return productName!;
    return brand ?? 'Unknown';
  }
}