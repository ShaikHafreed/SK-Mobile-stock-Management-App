class AppConstants {
  static const String localUrl =
      'http://192.168.48.51:5000/api';

  static const String ngrokUrl =
      'https://smudgy-imminent-hankie.ngrok-free.dev/api';

  static const String liveUrl =
      'https://backend-three-murex-79.vercel.app/api';

  // Live backend on Vercel — works from anywhere, no local IP needed
  static const String baseUrl = liveUrl;

  static const String apiKey =
      'sk-mobiles-api-key-2024-hafreed';

  static const String tokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user_data';
  static const String usernameKey = 'saved_username';
  static const String passwordKey = 'saved_password';

  static const int lowStockThreshold = 3;
  static const String appName = 'SR Mobiles';
}