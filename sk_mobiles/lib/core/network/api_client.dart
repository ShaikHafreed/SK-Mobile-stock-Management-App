import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  late Dio _dio;

  void init() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'X-API-Key': AppConstants.apiKey,
        'ngrok-skip-browser-warning': 'true',
        'User-Agent': 'SKMobilesApp/1.0',
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString(AppConstants.tokenKey);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        options.headers['X-API-Key'] = AppConstants.apiKey;
        options.headers['ngrok-skip-browser-warning'] = 'true';
        options.headers['User-Agent'] = 'SKMobilesApp/1.0';
        return handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          final prefs = await SharedPreferences.getInstance();
          final refreshToken =
              prefs.getString(AppConstants.refreshTokenKey);
          if (refreshToken != null) {
            try {
              final response = await _dio.post(
                '/auth/refresh-token',
                options: Options(headers: {
                  'Authorization': 'Bearer $refreshToken',
                  'X-API-Key': AppConstants.apiKey,
                  'ngrok-skip-browser-warning': 'true',
                }),
              );
              final newToken =
                  response.data['access_token'] as String;
              await prefs.setString(
                  AppConstants.tokenKey, newToken);
              error.requestOptions.headers['Authorization'] =
                  'Bearer $newToken';
              final retryResponse =
                  await _dio.fetch(error.requestOptions);
              return handler.resolve(retryResponse);
            } catch (_) {
              return handler.next(error);
            }
          }
        }
        return handler.next(error);
      },
    ));
  }

  Dio get dio => _dio;

  Future<Response> login(
      String username, String password) async {
    return await _dio.post('/auth/login',
        data: {'username': username, 'password': password});
  }

  Future<Response> getDashboardStats() async =>
      await _dio.get('/products/dashboard/stats');

  Future<Response> getCategories() async =>
      await _dio.get('/categories/');

  Future<Response> getProducts(
      {int? categoryId, bool? lowStock}) async {
    final params = <String, dynamic>{};
    if (categoryId != null) params['category_id'] = categoryId;
    if (lowStock == true) params['low_stock'] = 'true';
    return await _dio.get('/products/',
        queryParameters: params);
  }

  Future<Response> addProduct(
          Map<String, dynamic> data) async =>
      await _dio.post('/products/', data: data);

  Future<Response> updateProduct(
          int id, Map<String, dynamic> data) async =>
      await _dio.put('/products/$id', data: data);

  Future<Response> updateQuantity(
          int id, int quantity) async =>
      await _dio.patch('/products/$id/quantity',
          data: {'quantity': quantity});

  Future<Response> deleteProduct(int id) async =>
      await _dio.delete('/products/$id');

  Future<Response> getBoxes() async =>
      await _dio.get('/boxes/');

  Future<Response> createBox(
          Map<String, dynamic> data) async =>
      await _dio.post('/boxes/', data: data);

  Future<Response> updateBox(
          int id, Map<String, dynamic> data) async =>
      await _dio.put('/boxes/$id', data: data);

  Future<Response> deleteBox(int id) async =>
      await _dio.delete('/boxes/$id');

  Future<Response> addItemToBox(
          int boxId, Map<String, dynamic> data) async =>
      await _dio.post('/boxes/$boxId/items', data: data);

  Future<Response> updateBoxItem(int boxId, int itemId,
          Map<String, dynamic> data) async =>
      await _dio.put('/boxes/$boxId/items/$itemId',
          data: data);

  Future<Response> deleteBoxItem(
          int boxId, int itemId) async =>
      await _dio.delete('/boxes/$boxId/items/$itemId');

  Future<Response> search(String query) async =>
      await _dio.get('/search/',
          queryParameters: {'q': query});

  Future<Response> getLogs() async =>
      await _dio.get('/logs/');

  Future<Response> exportExcel(String slug) async =>
      await _dio.get(
        '/excel/export/$slug',
        options: Options(
          responseType: ResponseType.bytes,
          headers: {
            'X-API-Key': AppConstants.apiKey,
            'ngrok-skip-browser-warning': 'true',
          },
        ),
      );
}