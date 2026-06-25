import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/dashboard_provider.dart';
import '../../../models/category_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../features/auth/providers/auth_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() =>
      _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => ref.read(dashboardProvider.notifier).loadStats());
  }

  void _showThemeDialog() {
    final current = ref.read(themeProvider);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Choose Theme'),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ThemeOption(
              icon: Icons.light_mode,
              label: 'Light Mode',
              isSelected: current == AppThemeMode.light,
              onTap: () {
                ref
                    .read(themeProvider.notifier)
                    .setTheme(AppThemeMode.light);
                Navigator.pop(ctx);
              },
            ),
            _ThemeOption(
              icon: Icons.dark_mode,
              label: 'Dark Mode',
              isSelected: current == AppThemeMode.dark,
              onTap: () {
                ref
                    .read(themeProvider.notifier)
                    .setTheme(AppThemeMode.dark);
                Navigator.pop(ctx);
              },
            ),
            _ThemeOption(
              icon: Icons.settings_suggest,
              label: 'System Default',
              isSelected: current == AppThemeMode.system,
              onTap: () {
                ref
                    .read(themeProvider.notifier)
                    .setTheme(AppThemeMode.system);
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dashState = ref.watch(dashboardProvider);
    final authState = ref.watch(authProvider);
    final themeMode = ref.watch(themeProvider);

    IconData themeIcon;
    switch (themeMode) {
      case AppThemeMode.light:
        themeIcon = Icons.light_mode;
        break;
      case AppThemeMode.dark:
        themeIcon = Icons.dark_mode;
        break;
      case AppThemeMode.system:
        themeIcon = Icons.settings_suggest;
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('SK Mobiles'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push('/search'),
          ),
          IconButton(
            icon: Icon(themeIcon),
            onPressed: _showThemeDialog,
          ),
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
              if (authState.user?.isAdmin == true)
                PopupMenuItem(
                  child: const ListTile(
                    leading: Icon(Icons.history),
                    title: Text('Activity Logs'),
                    contentPadding: EdgeInsets.zero,
                  ),
                  onTap: () => context.push('/logs'),
                ),
              PopupMenuItem(
                child: const ListTile(
                  leading: Icon(Icons.table_chart),
                  title: Text('Excel Reports'),
                  contentPadding: EdgeInsets.zero,
                ),
                onTap: () => context.push('/excel'),
              ),
              PopupMenuItem(
                child: const ListTile(
                  leading: Icon(Icons.logout, color: Colors.red),
                  title: Text('Logout',
                      style: TextStyle(color: Colors.red)),
                  contentPadding: EdgeInsets.zero,
                ),
                onTap: () async {
                  await ref.read(authProvider.notifier).logout();
                  if (context.mounted) context.go('/login');
                },
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(dashboardProvider.notifier).loadStats(),
        child: dashState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : dashState.error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(dashState.error!),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => ref
                              .read(dashboardProvider.notifier)
                              .loadStats(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    physics:
                        const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        // Welcome section with animation
                        _AnimatedSection(
                          delay: 0,
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hello, ${authState.user?.fullName ?? authState.user?.username ?? 'User'}! 👋',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Here\'s your stock overview',
                                style: TextStyle(
                                    color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Stats with animation
                        _AnimatedSection(
                          delay: 100,
                          child: Row(
                            children: [
                              _StatCard(
                                title: 'Total Products',
                                value:
                                    '${dashState.totalProducts}',
                                icon: Icons.inventory_2,
                                color: AppTheme.primary,
                              ),
                              const SizedBox(width: 12),
                              _StatCard(
                                title: 'Total Stock',
                                value: '${dashState.totalStock}',
                                icon: Icons.warehouse,
                                color: AppTheme.success,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Low stock warning with animation
                        if (dashState.totalLowStock > 0)
                          _AnimatedSection(
                            delay: 150,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius:
                                    BorderRadius.circular(12),
                                border: Border.all(
                                    color: Colors.red.shade200),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                      Icons.warning_amber,
                                      color: Colors.red),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      '${dashState.totalLowStock} products are low on stock (< 3 units)',
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontWeight:
                                            FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        const SizedBox(height: 20),

                        // Categories title with animation
                        _AnimatedSection(
                          delay: 200,
                          child: const Text(
                            'Categories',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Categories grid with staggered animation
                        GridView.builder(
                          shrinkWrap: true,
                          physics:
                              const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 1.1,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: dashState.categories.length,
                          itemBuilder: (context, index) {
                            final cat =
                                dashState.categories[index];
                            return _AnimatedSection(
                              delay: 250 + (index * 80),
                              child: _CategoryCard(
                                  category: cat),
                            );
                          },
                        ),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/temper-glass'),
        backgroundColor: AppTheme.primary,
        icon:
            const Icon(Icons.grid_view, color: Colors.white),
        label: const Text('Temper Glass',
            style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

// ─── ANIMATED SECTION ─────────────────────────────────────────
class _AnimatedSection extends StatefulWidget {
  final Widget child;
  final int delay;

  const _AnimatedSection({
    required this.child,
    this.delay = 0,
  });

  @override
  State<_AnimatedSection> createState() =>
      _AnimatedSectionState();
}

class _AnimatedSectionState extends State<_AnimatedSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
          parent: _controller, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
          parent: _controller, curve: Curves.easeOut),
    );

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: widget.child,
      ),
    );
  }
}

// ─── THEME OPTION ──────────────────────────────────────────────
class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? AppTheme.primary
                : Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: isSelected
                    ? AppTheme.primary
                    : Colors.grey),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected
                    ? FontWeight.bold
                    : FontWeight.normal,
                color: isSelected ? AppTheme.primary : null,
              ),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(Icons.check_circle,
                  color: AppTheme.primary, size: 20),
          ],
        ),
      ),
    );
  }
}

// ─── STAT CARD ─────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: color.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── CATEGORY CARD ─────────────────────────────────────────────
class _CategoryCard extends StatelessWidget {
  final CategoryModel category;

  const _CategoryCard({required this.category});

  IconData _getIcon(String? iconName) {
    switch (iconName) {
      case 'phone_android':
        return Icons.phone_android;
      case 'headphones':
        return Icons.headphones;
      case 'earbuds':
        return Icons.earbuds;
      case 'electric_bolt':
        return Icons.electric_bolt;
      case 'cable':
        return Icons.cable;
      case 'smartphone':
        return Icons.smartphone;
      default:
        return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTemperGlass = category.slug == 'temper-glass';
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        if (isTemperGlass) {
          context.push('/temper-glass');
        } else {
          context.push(
              '/products/${category.id}/${Uri.encodeComponent(category.name)}');
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1E1E2E)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black
                  .withValues(alpha: isDark ? 0.3 : 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primary
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getIcon(category.icon),
                    color: AppTheme.primary,
                    size: 22,
                  ),
                ),
                if (category.lowStockCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${category.lowStockCount}',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 10),
                    ),
                  ),
              ],
            ),
            const Spacer(),
            Text(
              category.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '${category.totalProducts} items · ${category.totalStock} stock',
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}