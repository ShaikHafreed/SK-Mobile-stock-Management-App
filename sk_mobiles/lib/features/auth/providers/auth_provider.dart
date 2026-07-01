import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/user_model.dart';

class AuthState {
  final bool isLoading;
  final UserModel? user;
  final String? error;

  AuthState({
    this.isLoading = false,
    this.user,
    this.error,
  });

  AuthState copyWith({
    bool? isLoading,
    UserModel? user,
    String? error,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState()) {
    loadUser();
  }

  Future<bool> login(
      String username, String password) async {
    state = state.copyWith(
        isLoading: true, error: null);
    try {
      final response =
          await ApiClient().login(username, password);
      final data = response.data;

      final prefs =
          await SharedPreferences.getInstance();
      await prefs.setString(
          AppConstants.tokenKey,
          data['access_token']);
      await prefs.setString(
          AppConstants.refreshTokenKey,
          data['refresh_token'] ?? '');
      await prefs.setString(
          AppConstants.userKey,
          jsonEncode(data['user']));

      state = state.copyWith(
        isLoading: false,
        user: UserModel.fromJson(data['user']),
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Invalid username or password',
      );
      return false;
    }
  }

  Future<void> logout() async {
    final prefs =
        await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove(
        AppConstants.refreshTokenKey);
    await prefs.remove(AppConstants.userKey);
    // Keep remember me credentials if set
    state = AuthState();
  }

  Future<void> loadUser() async {
    try {
      final prefs =
          await SharedPreferences.getInstance();
      final userData =
          prefs.getString(AppConstants.userKey);
      final token =
          prefs.getString(AppConstants.tokenKey);

      if (userData != null && token != null) {
        state = state.copyWith(
          user: UserModel.fromJson(
              jsonDecode(userData)),
        );
      }
    } catch (e) {
      // Silent fail
    }
  }
}

final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(),
);