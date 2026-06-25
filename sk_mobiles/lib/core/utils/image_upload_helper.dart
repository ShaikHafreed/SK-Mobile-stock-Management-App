import 'dart:io';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class ImageUploadHelper {
  static Future<String?> uploadProductImage(
      File imageFile, int productId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.tokenKey);

      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename:
              'product_$productId.${imageFile.path.split('.').last}',
        ),
      });

      final dio = Dio();
      dio.options.connectTimeout = const Duration(seconds: 30);
      dio.options.receiveTimeout = const Duration(seconds: 30);

      final response = await dio.post(
        '${AppConstants.baseUrl}/products/$productId/upload-image',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
          contentType: 'multipart/form-data',
        ),
      );

      if (response.statusCode == 200) {
        return response.data['image_url'] as String?;
      }
      return null;
    } catch (e) {
      print('Image upload error: $e');
      return null;
    }
  }
}