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
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString(AppConstants.tokenKey);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
    ));
  }

  Dio get dio => _dio;

  Future<Response> login(String username, String password) async {
    return await _dio.post('/auth/login',
        data: {'username': username, 'password': password});
  }

  Future<Response> getDashboardStats() async =>
      await _dio.get('/products/dashboard/stats');

  Future<Response> getCategories() async =>
      await _dio.get('/categories/');

  Future<Response> getProducts({int? categoryId, bool? lowStock}) async {
    final params = <String, dynamic>{};
    if (categoryId != null) params['category_id'] = categoryId;
    if (lowStock == true) params['low_stock'] = 'true';
    return await _dio.get('/products/', queryParameters: params);
  }

  Future<Response> addProduct(Map<String, dynamic> data) async =>
      await _dio.post('/products/', data: data);

  Future<Response> updateProduct(int id, Map<String, dynamic> data) async =>
      await _dio.put('/products/$id', data: data);

  Future<Response> updateQuantity(int id, int quantity) async =>
      await _dio.patch('/products/$id/quantity',
          data: {'quantity': quantity});

  Future<Response> deleteProduct(int id) async =>
      await _dio.delete('/products/$id');

  Future<Response> getBoxes() async => await _dio.get('/boxes/');

  Future<Response> createBox(Map<String, dynamic> data) async =>
      await _dio.post('/boxes/', data: data);

  Future<Response> updateBox(int id, Map<String, dynamic> data) async =>
      await _dio.put('/boxes/$id', data: data);

  Future<Response> deleteBox(int id) async =>
      await _dio.delete('/boxes/$id');

  Future<Response> addItemToBox(
          int boxId, Map<String, dynamic> data) async =>
      await _dio.post('/boxes/$boxId/items', data: data);

  Future<Response> updateBoxItem(
          int boxId, int itemId, Map<String, dynamic> data) async =>
      await _dio.put('/boxes/$boxId/items/$itemId', data: data);

  Future<Response> deleteBoxItem(int boxId, int itemId) async =>
      await _dio.delete('/boxes/$boxId/items/$itemId');

  Future<Response> search(String query) async =>
      await _dio.get('/search/', queryParameters: {'q': query});

  Future<Response> getLogs() async => await _dio.get('/logs/');

  Future<Response> exportExcel(String slug) async =>
      await _dio.get('/excel/export/$slug',
          options: Options(responseType: ResponseType.bytes));
}