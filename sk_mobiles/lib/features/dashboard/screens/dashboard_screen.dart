import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/dashboard_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/theme/app_theme.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() =>
      _DashboardScreenState();
}

class _DashboardScreenState
    extends ConsumerState<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim =
        Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
          parent: _animCtrl,
          curve: Curves.easeOut),
    );
    Future.microtask(() {
      ref
          .read(dashboardProvider.notifier)
          .loadStats();
      _animCtrl.forward();
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _showThemePicker() {
    final current = ref.read(themeProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDarkSheet =
            Theme.of(context).brightness ==
                Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDarkSheet
                ? const Color(0xFF1A1A2E)
                : Colors.white,
            borderRadius:
                const BorderRadius.vertical(
                    top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius:
                      BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Appearance',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDarkSheet
                      ? Colors.white
                      : Colors.black87,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _ThemeOption(
                    icon: Icons.wb_sunny_outlined,
                    label: 'Light',
                    isActive: current ==
                        AppThemeMode.light,
                    color: Colors.amber,
                    isDark: isDarkSheet,
                    onTap: () {
                      ref
                          .read(
                              themeProvider.notifier)
                          .setTheme(
                              AppThemeMode.light);
                      Navigator.pop(ctx);
                    },
                  ),
                  const SizedBox(width: 12),
                  _ThemeOption(
                    icon: Icons.nightlight_round,
                    label: 'Dark',
                    isActive: current ==
                        AppThemeMode.dark,
                    color: Colors.indigo,
                    isDark: isDarkSheet,
                    onTap: () {
                      ref
                          .read(
                              themeProvider.notifier)
                          .setTheme(
                              AppThemeMode.dark);
                      Navigator.pop(ctx);
                    },
                  ),
                  const SizedBox(width: 12),
                  _ThemeOption(
                    icon: Icons.brightness_auto,
                    label: 'System',
                    isActive: current ==
                        AppThemeMode.system,
                    color: Colors.teal,
                    isDark: isDarkSheet,
                    onTap: () {
                      ref
                          .read(
                              themeProvider.notifier)
                          .setTheme(
                              AppThemeMode.system);
                      Navigator.pop(ctx);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dashState = ref.watch(dashboardProvider);
    final authState = ref.watch(authProvider);
    final themeMode = ref.watch(themeProvider);
    final isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    IconData themeIcon;
    switch (themeMode) {
      case AppThemeMode.light:
        themeIcon = Icons.wb_sunny_outlined;
        break;
      case AppThemeMode.dark:
        themeIcon = Icons.nightlight_round;
        break;
      default:
        themeIcon = Icons.brightness_auto;
    }

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0A0A1A)
          : const Color(0xFFF0F4FF),
      appBar: AppBar(
        title: const Text('SK Mobiles'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // ── PROFILE ICON ──────────────────────
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () =>
                context.push('/profile'),
            tooltip: 'Profile',
          ),
          // ── SEARCH ICON ───────────────────────
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () =>
                context.push('/search'),
          ),
          // ── THEME ICON ────────────────────────
          IconButton(
            icon: Icon(themeIcon),
            onPressed: _showThemePicker,
          ),
          // ── MORE MENU ─────────────────────────
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            color: isDark
                ? const Color(0xFF1A1A2E)
                : Colors.white,
            itemBuilder: (ctx) => [
              PopupMenuItem(
                child: ListTile(
                  leading: const Icon(
                      Icons.receipt_long,
                      color: Colors.blue),
                  title: Text(
                    'Activity Logs',
                    style: TextStyle(
                        color: isDark
                            ? Colors.white
                            : Colors.black87),
                  ),
                  contentPadding:
                      EdgeInsets.zero,
                  dense: true,
                ),
                onTap: () => Future.delayed(
                  const Duration(
                      milliseconds: 100),
                  () => context.push('/logs'),
                ),
              ),
              PopupMenuItem(
                child: ListTile(
                  leading: const Icon(
                      Icons.table_chart,
                      color: Colors.green),
                  title: Text(
                    'Excel Reports',
                    style: TextStyle(
                        color: isDark
                            ? Colors.white
                            : Colors.black87),
                  ),
                  contentPadding:
                      EdgeInsets.zero,
                  dense: true,
                ),
                onTap: () => Future.delayed(
                  const Duration(
                      milliseconds: 100),
                  () => context.push('/excel'),
                ),
              ),
              PopupMenuItem(
                child: ListTile(
                  leading: const Icon(
                      Icons.receipt,
                      color: Colors.orange),
                  title: Text(
                    'Billing',
                    style: TextStyle(
                        color: isDark
                            ? Colors.white
                            : Colors.black87),
                  ),
                  contentPadding:
                      EdgeInsets.zero,
                  dense: true,
                ),
                onTap: () => Future.delayed(
                  const Duration(
                      milliseconds: 100),
                  () => context.push('/billing'),
                ),
              ),
              PopupMenuItem(
                child: ListTile(
                  leading: const Icon(
                      Icons.person,
                      color: Colors.purple),
                  title: Text(
                    'Profile',
                    style: TextStyle(
                        color: isDark
                            ? Colors.white
                            : Colors.black87),
                  ),
                  contentPadding:
                      EdgeInsets.zero,
                  dense: true,
                ),
                onTap: () => Future.delayed(
                  const Duration(
                      milliseconds: 100),
                  () => context.push('/profile'),
                ),
              ),
              PopupMenuItem(
                child: const ListTile(
                  leading: Icon(Icons.logout,
                      color: Colors.red),
                  title: Text(
                    'Logout',
                    style: TextStyle(
                        color: Colors.red),
                  ),
                  contentPadding:
                      EdgeInsets.zero,
                  dense: true,
                ),
                onTap: () async {
                  await ref
                      .read(authProvider.notifier)
                      .logout();
                  if (context.mounted) {
                    context.go('/login');
                  }
                },
              ),
            ],
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: RefreshIndicator(
          onRefresh: () => ref
              .read(dashboardProvider.notifier)
              .loadStats(),
          child: SingleChildScrollView(
            physics:
                const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                // ── GREETING ──────────────────
                _GreetingCard(
                  username:
                      authState.user?.username ??
                          'User',
                  isDark: isDark,
                ),
                const SizedBox(height: 16),

                // ── STATS ─────────────────────
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'Total Products',
                        value:
                            '${dashState.totalProducts}',
                        icon: Icons.inventory_2,
                        gradient:
                            const LinearGradient(
                          colors: [
                            Color(0xFF1565C0),
                            Color(0xFF42A5F5),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        title: 'Total Stock',
                        value:
                            '${dashState.totalStock}',
                        icon: Icons.warehouse,
                        gradient:
                            const LinearGradient(
                          colors: [
                            Color(0xFF2E7D32),
                            Color(0xFF66BB6A),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ── LOW STOCK ─────────────────
                if (dashState.lowStockCount > 0) ...[
                  Container(
                    padding:
                        const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.red.shade400,
                          Colors.red.shade700,
                        ],
                      ),
                      borderRadius:
                          BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red
                              .withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset:
                              const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding:
                              const EdgeInsets.all(
                                  8),
                          decoration: BoxDecoration(
                            color: Colors.white
                                .withValues(
                                    alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                              Icons.warning_amber,
                              color: Colors.white,
                              size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              const Text(
                                'Low Stock Alert!',
                                style: TextStyle(
                                  color:
                                      Colors.white,
                                  fontWeight:
                                      FontWeight
                                          .bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                '${dashState.lowStockCount} products need restocking',
                                style: const TextStyle(
                                    color: Colors
                                        .white70,
                                    fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // ── QUICK ACTIONS ─────────────
                Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? Colors.white
                        : Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _QuickAction(
                        icon: Icons.qr_code_scanner,
                        label: 'Scan\nBarcode',
                        color:
                            const Color(0xFF7B1FA2),
                        isDark: isDark,
                        onTap: () => context
                            .push('/barcode'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _QuickAction(
                        icon: Icons.receipt,
                        label: 'Create\nBill',
                        color:
                            const Color(0xFFE65100),
                        isDark: isDark,
                        onTap: () => context
                            .push('/billing'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _QuickAction(
                        icon: Icons.search,
                        label: 'Search\nStock',
                        color:
                            const Color(0xFF00695C),
                        isDark: isDark,
                        onTap: () => context
                            .push('/search'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _QuickAction(
                        icon: Icons.table_chart,
                        label: 'Export\nExcel',
                        color:
                            const Color(0xFF1565C0),
                        isDark: isDark,
                        onTap: () => context
                            .push('/excel'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── TEMPER GLASS ──────────────
                GestureDetector(
                  onTap: () =>
                      context.push('/temper-glass'),
                  child: Container(
                    padding:
                        const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient:
                          const LinearGradient(
                        colors: [
                          Color(0xFF00695C),
                          Color(0xFF26A69A),
                        ],
                      ),
                      borderRadius:
                          BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                                  0xFF00695C)
                              .withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset:
                              const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding:
                              const EdgeInsets.all(
                                  10),
                          decoration: BoxDecoration(
                            color: Colors.white
                                .withValues(
                                    alpha: 0.2),
                            borderRadius:
                                BorderRadius.circular(
                                    10),
                          ),
                          child: const Icon(
                              Icons.view_module,
                              color: Colors.white,
                              size: 24),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              Text(
                                'Temper Glass Manager',
                                style: TextStyle(
                                  color:
                                      Colors.white,
                                  fontWeight:
                                      FontWeight
                                          .bold,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                'Manage boxes and items',
                                style: TextStyle(
                                    color: Colors
                                        .white70,
                                    fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white70,
                            size: 16),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ── CATEGORIES ────────────────
                Text(
                  'Categories',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? Colors.white
                        : Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 12),

                if (dashState.isLoading)
                  const Center(
                      child:
                          CircularProgressIndicator())
                else if (dashState.error != null)
                  Center(
                    child: Column(
                      children: [
                        Text(dashState.error!,
                            style: const TextStyle(
                                color: Colors.red)),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => ref
                              .read(dashboardProvider
                                  .notifier)
                              .loadStats(),
                          child:
                              const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics:
                        const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount:
                        dashState.categories.length,
                    itemBuilder: (context, index) {
                      final cat =
                          dashState.categories[index];
                      return _CategoryCard(
                        category: cat,
                        index: index,
                        isDark: isDark,
                        onTap: () => context.push(
                          '/products/${cat.id}/${Uri.encodeComponent(cat.name)}',
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── GREETING CARD ──────────────────────────────────────────────
class _GreetingCard extends StatelessWidget {
  final String username;
  final bool isDark;

  const _GreetingCard({
    required this.username,
    required this.isDark,
  });

  String _getGreeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1565C0),
            Color(0xFF42A5F5),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1565C0)
                .withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  '${_getGreeting()} 👋',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'SK Mobiles ${username[0].toUpperCase()}${username.substring(1)}!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Here's your stock overview",
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white
                  .withValues(alpha: 0.2),
              borderRadius:
                  BorderRadius.circular(14),
            ),
            child: const Icon(Icons.store,
                color: Colors.white, size: 32),
          ),
        ],
      ),
    );
  }
}

// ── STAT CARD ──────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final LinearGradient gradient;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first
                .withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
                color: Colors.white70,
                fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ── QUICK ACTION ───────────────────────────────────────────────
class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: isDark
              ? color.withValues(alpha: 0.15)
              : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon,
                  color: color, size: 20),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── CATEGORY CARD ──────────────────────────────────────────────
class _CategoryCard extends StatelessWidget {
  final dynamic category;
  final int index;
  final bool isDark;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.category,
    required this.index,
    required this.isDark,
    required this.onTap,
  });

  static const List<List<Color>> _gradients = [
    [Color(0xFF7B1FA2), Color(0xFFCE93D8)],
    [Color(0xFF1565C0), Color(0xFF64B5F6)],
    [Color(0xFFE65100), Color(0xFFFFB74D)],
    [Color(0xFF2E7D32), Color(0xFF81C784)],
    [Color(0xFF00695C), Color(0xFF4DB6AC)],
    [Color(0xFFF57F17), Color(0xFFFFD54F)],
    [Color(0xFFC62828), Color(0xFFEF9A9A)],
    [Color(0xFF37474F), Color(0xFF90A4AE)],
  ];

  static const List<IconData> _icons = [
    Icons.phone_android,
    Icons.headphones,
    Icons.earbuds,
    Icons.electric_bolt,
    Icons.cable,
    Icons.smartphone,
    Icons.category,
    Icons.more_horiz,
  ];

  @override
  Widget build(BuildContext context) {
    final colors =
        _gradients[index % _gradients.length];
    final icon = _icons[index % _icons.length];
    final lowStock = category.lowStockCount ?? 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1A1A2E)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black
                  .withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: colors),
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                  child: Icon(icon,
                      color: Colors.white,
                      size: 20),
                ),
                if (lowStock > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius:
                          BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$lowStock',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight:
                              FontWeight.bold),
                    ),
                  ),
              ],
            ),
            const Spacer(),
            Text(
              category.name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isDark
                    ? Colors.white
                    : Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Text(
              '${category.productCount ?? 0} items · ${category.totalStock ?? 0} stock',
              style: TextStyle(
                  fontSize: 11,
                  color: isDark
                      ? Colors.grey.shade400
                      : Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}

// ── THEME OPTION ───────────────────────────────────────────────
class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration:
              const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
              vertical: 16),
          decoration: BoxDecoration(
            color: isActive
                ? color.withValues(alpha: 0.15)
                : isDark
                    ? const Color(0xFF2A2A3E)
                    : Colors.grey.shade100,
            borderRadius:
                BorderRadius.circular(14),
            border: Border.all(
              color: isActive
                  ? color
                  : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isActive
                    ? color
                    : isDark
                        ? Colors.grey.shade400
                        : Colors.grey,
                size: 26,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: isActive
                      ? color
                      : isDark
                          ? Colors.grey.shade400
                          : Colors.grey,
                  fontSize: 12,
                  fontWeight: isActive
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}