import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../models/category_model.dart';

class DashboardState {
  final bool isLoading;
  final int totalProducts;
  final int totalStock;
  final int totalLowStock;
  final List<CategoryModel> categories;
  final String? error;

  DashboardState({
    this.isLoading = false,
    this.totalProducts = 0,
    this.totalStock = 0,
    this.totalLowStock = 0,
    this.categories = const [],
    this.error,
  });

  DashboardState copyWith({
    bool? isLoading,
    int? totalProducts,
    int? totalStock,
    int? totalLowStock,
    List<CategoryModel>? categories,
    String? error,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      totalProducts: totalProducts ?? this.totalProducts,
      totalStock: totalStock ?? this.totalStock,
      totalLowStock: totalLowStock ?? this.totalLowStock,
      categories: categories ?? this.categories,
      error: error,
    );
  }
}

class DashboardNotifier extends StateNotifier<DashboardState> {
  DashboardNotifier() : super(DashboardState());

  Future<void> loadStats() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await ApiClient().getDashboardStats();
      final data = response.data;
      state = state.copyWith(
        isLoading: false,
        totalProducts: data['total_products'] ?? 0,
        totalStock: data['total_stock'] ?? 0,
        totalLowStock: data['total_low_stock'] ?? 0,
        categories: (data['categories'] as List)
            .map((c) => CategoryModel.fromJson(c))
            .toList(),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load dashboard',
      );
    }
  }
}

final dashboardProvider =
    StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  return DashboardNotifier();
});