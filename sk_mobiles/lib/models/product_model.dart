class ProductModel {
  final int id;
  final int categoryId;
  final String? brand;
  final String? mobileModel;
  final String? productName;
  final String? watts;
  final String? cableType;
  final int quantity;
  final String? notes;
  final String? _rawImageUrl;
  final String? categoryName;

  ProductModel({
    required this.id,
    required this.categoryId,
    this.brand,
    this.mobileModel,
    this.productName,
    this.watts,
    this.cableType,
    this.quantity = 0,
    this.notes,
    String? imageUrl,
    this.categoryName,
  }) : _rawImageUrl = imageUrl;

  /// Image URL with cache-busting so newly
  /// uploaded images always refresh
  String? get imageUrl {
    if (_rawImageUrl == null ||
        _rawImageUrl!.isEmpty) {
      return null;
    }
    final sep =
        _rawImageUrl!.contains('?') ? '&' : '?';
    return '$_rawImageUrl${sep}v=$id';
  }

  bool get isLowStock => quantity < 3;

  String get displayName {
    if (mobileModel != null &&
        mobileModel!.isNotEmpty) {
      return mobileModel!;
    }
    if (productName != null &&
        productName!.isNotEmpty) {
      return productName!;
    }
    if (watts != null && watts!.isNotEmpty) {
      return watts!;
    }
    if (cableType != null &&
        cableType!.isNotEmpty) {
      return cableType!;
    }
    return brand ?? 'Product';
  }

  factory ProductModel.fromJson(
      Map<String, dynamic> json) {
    // Backend may send image under different keys
    String? img;
    for (final key in [
      'image_url',
      'imageUrl',
      'image',
      'photo_url',
      'img_url',
    ]) {
      final v = json[key];
      if (v != null &&
          v is String &&
          v.isNotEmpty) {
        img = v;
        break;
      }
    }

    return ProductModel(
      id: json['id'] ?? 0,
      categoryId: json['category_id'] ?? 0,
      brand: json['brand'],
      mobileModel: json['mobile_model'],
      productName: json['product_name'],
      watts: json['watts'],
      cableType: json['cable_type'],
      quantity: json['quantity'] ?? 0,
      notes: json['notes'],
      imageUrl: img,
      categoryName: json['category_name'] ??
          json['categoryName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category_id': categoryId,
      'brand': brand,
      'mobile_model': mobileModel,
      'product_name': productName,
      'watts': watts,
      'cable_type': cableType,
      'quantity': quantity,
      'notes': notes,
      'image_url': _rawImageUrl,
      'category_name': categoryName,
    };
  }
}