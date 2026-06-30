import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../models/product_model.dart';

class ProductsState {
  final bool isLoading;
  final List<ProductModel> products;
  final String? error;
  final int? lastAddedProductId;

  ProductsState({
    this.isLoading = false,
    this.products = const [],
    this.error,
    this.lastAddedProductId,
  });

  ProductsState copyWith({
    bool? isLoading,
    List<ProductModel>? products,
    String? error,
    int? lastAddedProductId,
  }) {
    return ProductsState(
      isLoading: isLoading ?? this.isLoading,
      products: products ?? this.products,
      error: error,
      lastAddedProductId: lastAddedProductId ?? this.lastAddedProductId,
    );
  }
}

class ProductsNotifier extends StateNotifier<ProductsState> {
  ProductsNotifier() : super(ProductsState());

  Future<void> loadProducts(int categoryId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response =
          await ApiClient().getProducts(categoryId: categoryId);
      final data = response.data;
      state = state.copyWith(
        isLoading: false,
        products: (data['products'] as List)
            .map((p) => ProductModel.fromJson(p))
            .toList(),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load products',
      );
    }
  }

  // ── Returns the new product ID ─────────────────────────────
  Future<int?> addProduct(Map<String, dynamic> data) async {
    try {
      final response = await ApiClient().addProduct(data);

      // Get product_id from response
      int? productId;
      if (response.data['product_id'] != null) {
        productId = response.data['product_id'] as int;
      } else if (response.data['product'] != null) {
        productId = response.data['product']['id'] as int;
      }

      await loadProducts(data['category_id']);

      if (productId != null) {
        state = state.copyWith(lastAddedProductId: productId);
      }

      return productId;
    } catch (e) {
      return null;
    }
  }

  Future<bool> updateProduct(
      int id, Map<String, dynamic> data, int categoryId) async {
    try {
      await ApiClient().updateProduct(id, data);
      await loadProducts(categoryId);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateQuantity(
      int id, int quantity, int categoryId) async {
    try {
      await ApiClient().updateQuantity(id, quantity);
      await loadProducts(categoryId);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteProduct(int id, int categoryId) async {
    try {
      await ApiClient().deleteProduct(id);
      await loadProducts(categoryId);
      return true;
    } catch (e) {
      return false;
    }
  }
}

final productsProvider =
    StateNotifierProvider<ProductsNotifier, ProductsState>((ref) {
  return ProductsNotifier();
});