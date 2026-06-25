import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/products/screens/products_screen.dart';
import '../../features/products/screens/add_product_screen.dart';
import '../../features/temper_glass/screens/temper_glass_screen.dart';
import '../../features/search/screens/search_screen.dart';
import '../../features/excel/screens/excel_screen.dart';
import '../../features/logs/screens/logs_screen.dart';
import '../../core/constants/app_constants.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) async {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.tokenKey);
      final isLoggedIn = token != null;
      final isLoginPage = state.matchedLocation == '/login';
      if (!isLoggedIn && !isLoginPage) return '/login';
      if (isLoggedIn && isLoginPage) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/products/:categoryId/:categoryName',
        builder: (context, state) => ProductsScreen(
          categoryId: int.parse(state.pathParameters['categoryId']!),
          categoryName: state.pathParameters['categoryName']!,
        ),
      ),
      GoRoute(
        path: '/add-product/:categoryId/:categoryName',
        builder: (context, state) => AddProductScreen(
          categoryId: int.parse(state.pathParameters['categoryId']!),
          categoryName: state.pathParameters['categoryName']!,
        ),
      ),
      GoRoute(
        path: '/temper-glass',
        builder: (context, state) => const TemperGlassScreen(),
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: '/excel',
        builder: (context, state) => const ExcelScreen(),
      ),
      GoRoute(
        path: '/logs',
        builder: (context, state) => const LogsScreen(),
      ),
    ],
  );
});