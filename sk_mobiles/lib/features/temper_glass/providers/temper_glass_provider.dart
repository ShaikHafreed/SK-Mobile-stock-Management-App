import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../models/temper_box_model.dart';

class TemperGlassState {
  final bool isLoading;
  final List<TemperBoxModel> boxes;
  final String? error;

  TemperGlassState({
    this.isLoading = false,
    this.boxes = const [],
    this.error,
  });

  TemperGlassState copyWith({
    bool? isLoading,
    List<TemperBoxModel>? boxes,
    String? error,
  }) {
    return TemperGlassState(
      isLoading: isLoading ?? this.isLoading,
      boxes: boxes ?? this.boxes,
      error: error,
    );
  }
}

class TemperGlassNotifier extends StateNotifier<TemperGlassState> {
  TemperGlassNotifier() : super(TemperGlassState());

  Future<void> loadBoxes() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await ApiClient().getBoxes();
      final data = response.data;
      state = state.copyWith(
        isLoading: false,
        boxes: (data['boxes'] as List)
            .map((b) => TemperBoxModel.fromJson(b))
            .toList(),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load boxes',
      );
    }
  }

  Future<bool> createBox(String boxName, String description) async {
    try {
      await ApiClient().createBox({
        'box_name': boxName,
        'description': description,
      });
      await loadBoxes();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateBox(
      int id, String boxName, String description) async {
    try {
      await ApiClient().updateBox(id, {
        'box_name': boxName,
        'description': description,
      });
      await loadBoxes();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteBox(int id) async {
    try {
      await ApiClient().deleteBox(id);
      await loadBoxes();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> addItem(
      int boxId, String mobileModel, int quantity, String notes) async {
    try {
      await ApiClient().addItemToBox(boxId, {
        'mobile_model': mobileModel,
        'quantity': quantity,
        'notes': notes,
      });
      await loadBoxes();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateItem(int boxId, int itemId,
      String mobileModel, int quantity, String notes) async {
    try {
      await ApiClient().updateBoxItem(boxId, itemId, {
        'mobile_model': mobileModel,
        'quantity': quantity,
        'notes': notes,
      });
      await loadBoxes();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteItem(int boxId, int itemId) async {
    try {
      await ApiClient().deleteBoxItem(boxId, itemId);
      await loadBoxes();
      return true;
    } catch (e) {
      return false;
    }
  }
}

final temperGlassProvider =
    StateNotifierProvider<TemperGlassNotifier, TemperGlassState>(
        (ref) => TemperGlassNotifier());