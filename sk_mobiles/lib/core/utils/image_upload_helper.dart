import 'dart:io';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class ImageUploadHelper {
  static Future<String?> uploadProductImage(
      File imageFile, int productId) async {
    try {
      final prefs =
          await SharedPreferences.getInstance();
      final token =
          prefs.getString(AppConstants.tokenKey);

      if (token == null) {
        print('No auth token found');
        return null;
      }

      // Unique filename to prevent caching
      final ext =
          imageFile.path.split('.').last.toLowerCase();
      final uniqueName =
          'product_${productId}_${DateTime.now().millisecondsSinceEpoch}.$ext';

      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: uniqueName,
        ),
      });

      final dio = Dio();
      dio.options.connectTimeout =
          const Duration(seconds: 60);
      dio.options.receiveTimeout =
          const Duration(seconds: 60);

      final response = await dio.post(
        '${AppConstants.baseUrl}/products/$productId/upload-image',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'X-API-Key': AppConstants.apiKey,
            'ngrok-skip-browser-warning': 'true',
          },
          contentType: 'multipart/form-data',
        ),
      );

      if (response.statusCode == 200) {
        final imageUrl =
            response.data['image_url'] as String?;
        print('Image uploaded successfully: $imageUrl');
        return imageUrl;
      }
      print(
          'Upload failed: ${response.statusCode}');
      return null;
    } on DioException catch (e) {
      print(
          'Dio error: ${e.response?.statusCode} - ${e.response?.data}');
      return null;
    } catch (e) {
      print('Image upload error: $e');
      return null;
    }
  }

  // Update existing product image
  static Future<String?> updateProductImage(
      File imageFile, int productId) async {
    return await uploadProductImage(
        imageFile, productId);
  }
}