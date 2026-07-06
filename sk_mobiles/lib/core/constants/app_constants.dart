class AppConstants {
  static const String localUrl =
      'http://192.168.48.181:5000/api';

  static const String ngrokUrl =
      'https://smudgy-imminent-hankie.ngrok-free.dev/api';

  // Use localUrl for testing, ngrokUrl for anywhere access
  static const String baseUrl = localUrl;

  static const String apiKey =
      'sk-mobiles-api-key-2024-hafreed';

  static const String tokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user_data';
  static const String usernameKey = 'saved_username';
  static const String passwordKey = 'saved_password';

  static const int lowStockThreshold = 3;
  static const String appName = 'SK Mobiles';
}