import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/products/screens/products_screen.dart';
import '../../features/products/screens/add_product_screen.dart';
import '../../features/temper_glass/screens/temper_glass_screen.dart';
import '../../features/search/screens/search_screen.dart';
import '../../features/excel/screens/excel_screen.dart';
import '../../features/logs/screens/logs_screen.dart';
import '../../features/barcode/screens/barcode_screen.dart';
import '../../features/billing/screens/billing_screen.dart';
import '../../features/profile/screens/profile_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = authState.user != null;
      final isLoginRoute =
          state.matchedLocation == '/login';
      if (!isLoggedIn && !isLoginRoute)
        return '/login';
      if (isLoggedIn && isLoginRoute)
        return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (ctx, state) =>
            const LoginScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (ctx, state) =>
            const DashboardScreen(),
      ),
      GoRoute(
        path:
            '/products/:categoryId/:categoryName',
        builder: (ctx, state) => ProductsScreen(
          categoryId: int.parse(
              state.pathParameters['categoryId']!),
          categoryName: Uri.decodeComponent(
              state.pathParameters[
                  'categoryName']!),
        ),
      ),
      GoRoute(
        path:
            '/add-product/:categoryId/:categoryName',
        builder: (ctx, state) => AddProductScreen(
          categoryId: int.parse(
              state.pathParameters['categoryId']!),
          categoryName: Uri.decodeComponent(
              state.pathParameters[
                  'categoryName']!),
        ),
      ),
      GoRoute(
        path: '/temper-glass',
        builder: (ctx, state) =>
            const TemperGlassScreen(),
      ),
      GoRoute(
        path: '/search',
        builder: (ctx, state) =>
            const SearchScreen(),
      ),
      GoRoute(
        path: '/excel',
        builder: (ctx, state) =>
            const ExcelScreen(),
      ),
      GoRoute(
        path: '/logs',
        builder: (ctx, state) =>
            const LogsScreen(),
      ),
      GoRoute(
        path: '/barcode',
        builder: (ctx, state) =>
            const BarcodeScreen(),
      ),
      GoRoute(
        path: '/billing',
        builder: (ctx, state) =>
            const BillingScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (ctx, state) =>
            const ProfileScreen(),
      ),
    ],
  );
});