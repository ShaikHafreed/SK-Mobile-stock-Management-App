import 'package:dio/dio.dart';
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
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      String message;
      if (statusCode == 401 || statusCode == 403) {
        message = 'Invalid username or password';
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.connectionError) {
        message =
            'Cannot reach server at ${AppConstants.baseUrl}. Check the backend is running and the IP address is correct.';
      } else {
        message = 'Login failed: ${e.message}';
      }
      state = state.copyWith(
        isLoading: false,
        error: message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Login failed: $e',
      );
      return false;
    }
  }

  Future<bool> updateProfile(String fullName) async {
    try {
      final response =
          await ApiClient().updateProfile(fullName);
      final updatedUser =
          UserModel.fromJson(response.data['user']);

      final prefs =
          await SharedPreferences.getInstance();
      await prefs.setString(
          AppConstants.userKey,
          jsonEncode(response.data['user']));

      state = state.copyWith(user: updatedUser);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateProfileImage(String filePath) async {
    try {
      final response =
          await ApiClient().uploadProfileImage(filePath);
      final imageUrl =
          response.data['profile_image'] as String?;

      if (state.user != null) {
        final updatedUser = UserModel(
          id: state.user!.id,
          username: state.user!.username,
          fullName: state.user!.fullName,
          profileImage: imageUrl,
          role: state.user!.role,
          isActive: state.user!.isActive,
        );
        final prefs =
            await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.userKey,
            jsonEncode({
              'id': updatedUser.id,
              'username': updatedUser.username,
              'full_name': updatedUser.fullName,
              'profile_image': updatedUser.profileImage,
              'role': updatedUser.role,
              'is_active': updatedUser.isActive,
            }));
        state = state.copyWith(user: updatedUser);
      }
      return true;
    } catch (e) {
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