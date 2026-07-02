import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/theme_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final dashState = ref.watch(dashboardProvider);
    final themeMode = ref.watch(themeProvider);
    final user = authState.user;
    final isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0A0A1A)
          : const Color(0xFFF0F4FF),
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ── PROFILE HEADER ────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1565C0),
                    Color(0xFF42A5F5),
                  ],
                ),
                borderRadius:
                    BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1565C0)
                        .withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white
                          .withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white
                            .withValues(
                                alpha: 0.5),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        user?.username
                                .substring(0, 1)
                                .toUpperCase() ??
                            'U',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    user != null
                        ? '${user.username[0].toUpperCase()}${user.username.substring(1)}'
                        : 'User',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets
                        .symmetric(
                        horizontal: 14,
                        vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white
                          .withValues(alpha: 0.2),
                      borderRadius:
                          BorderRadius.circular(
                              20),
                    ),
                    child: Text(
                      user?.isAdmin == true
                          ? '👑 Administrator'
                          : '👤 Staff Member',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight:
                            FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // ── LIVE STATS ROW ────────────
                  Row(
                    children: [
                      _HeaderStat(
                        label: 'Products',
                        value:
                            '${dashState.totalProducts}',
                        icon: Icons.inventory_2,
                      ),
                      _HeaderStat(
                        label: 'Stock',
                        value:
                            '${dashState.totalStock}',
                        icon: Icons.warehouse,
                      ),
                      _HeaderStat(
                        label: 'Low Stock',
                        value:
                            '${dashState.lowStockCount}',
                        icon:
                            Icons.warning_amber,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── APP INFO ──────────────────────
            _SectionCard(
              title: 'App Information',
              isDark: isDark,
              children: [
                _InfoTile(
                  icon: Icons.store,
                  label: 'Shop Name',
                  value: 'SK Mobiles',
                  isDark: isDark,
                ),
                _InfoTile(
                  icon: Icons.person,
                  label: 'Username',
                  value: user?.username ?? '-',
                  isDark: isDark,
                ),
                _InfoTile(
                  icon:
                      Icons.admin_panel_settings,
                  label: 'Role',
                  value: user?.isAdmin == true
                      ? 'Admin'
                      : 'Staff',
                  isDark: isDark,
                ),
                _InfoTile(
                  icon: Icons.tag,
                  label: 'App Version',
                  value: '1.0.0',
                  isDark: isDark,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── APPEARANCE ────────────────────
            _SectionCard(
              title: 'Appearance',
              isDark: isDark,
              children: [
                _SettingTile(
                  icon: Icons.wb_sunny_outlined,
                  label: 'Light Mode',
                  isDark: isDark,
                  trailing: Radio<AppThemeMode>(
                    value: AppThemeMode.light,
                    groupValue: themeMode,
                    onChanged: (_) => ref
                        .read(themeProvider
                            .notifier)
                        .setTheme(
                            AppThemeMode.light),
                    activeColor:
                        AppTheme.primary,
                  ),
                  onTap: () => ref
                      .read(
                          themeProvider.notifier)
                      .setTheme(
                          AppThemeMode.light),
                ),
                _SettingTile(
                  icon: Icons.nightlight_round,
                  label: 'Dark Mode',
                  isDark: isDark,
                  trailing: Radio<AppThemeMode>(
                    value: AppThemeMode.dark,
                    groupValue: themeMode,
                    onChanged: (_) => ref
                        .read(themeProvider
                            .notifier)
                        .setTheme(
                            AppThemeMode.dark),
                    activeColor:
                        AppTheme.primary,
                  ),
                  onTap: () => ref
                      .read(
                          themeProvider.notifier)
                      .setTheme(
                          AppThemeMode.dark),
                ),
                _SettingTile(
                  icon: Icons.brightness_auto,
                  label: 'System Default',
                  isDark: isDark,
                  trailing: Radio<AppThemeMode>(
                    value: AppThemeMode.system,
                    groupValue: themeMode,
                    onChanged: (_) => ref
                        .read(themeProvider
                            .notifier)
                        .setTheme(
                            AppThemeMode.system),
                    activeColor:
                        AppTheme.primary,
                  ),
                  onTap: () => ref
                      .read(
                          themeProvider.notifier)
                      .setTheme(
                          AppThemeMode.system),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── QUICK LINKS ───────────────────
            _SectionCard(
              title: 'Quick Links',
              isDark: isDark,
              children: [
                _SettingTile(
                  icon: Icons.receipt_long,
                  label: 'Activity Logs',
                  isDark: isDark,
                  onTap: () =>
                      context.push('/logs'),
                ),
                _SettingTile(
                  icon: Icons.table_chart,
                  label: 'Excel Reports',
                  isDark: isDark,
                  onTap: () =>
                      context.push('/excel'),
                ),
                _SettingTile(
                  icon: Icons.receipt,
                  label: 'Billing',
                  isDark: isDark,
                  onTap: () =>
                      context.push('/billing'),
                ),
                _SettingTile(
                  icon: Icons.qr_code_scanner,
                  label: 'Barcode Scanner',
                  isDark: isDark,
                  onTap: () =>
                      context.push('/barcode'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── ABOUT ─────────────────────────
            _SectionCard(
              title: 'About',
              isDark: isDark,
              children: [
                _SettingTile(
                  icon: Icons.info_outline,
                  label: 'About SK Mobiles',
                  isDark: isDark,
                  onTap: () => showAboutDialog(
                    context: context,
                    applicationName:
                        'SK Mobiles Stock Manager',
                    applicationVersion: '1.0.0',
                    applicationIcon:
                        const Icon(
                            Icons.phone_android,
                            color:
                                AppTheme.primary,
                            size: 40),
                    children: [
                      const Text(
                          'Complete stock management solution for mobile accessories shops. Built with Flutter + Flask + Supabase.'),
                    ],
                  ),
                ),
                _SettingTile(
                  icon: Icons.refresh,
                  label: 'Refresh Stock Data',
                  isDark: isDark,
                  onTap: () async {
                    await ref
                        .read(dashboardProvider
                            .notifier)
                        .loadStats();
                    if (context.mounted) {
                      ScaffoldMessenger.of(
                              context)
                          .showSnackBar(
                        const SnackBar(
                          content: Text(
                              '✅ Stock data refreshed'),
                          backgroundColor:
                              Colors.green,
                          behavior:
                              SnackBarBehavior
                                  .floating,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── LOGOUT ────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final confirm =
                      await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      shape:
                          RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                          16)),
                      title:
                          const Text('Logout'),
                      content: const Text(
                          'Are you sure you want to logout?'),
                      actions: [
                        TextButton(
                          onPressed: () =>
                              Navigator.pop(
                                  ctx, false),
                          child: const Text(
                              'Cancel'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton
                              .styleFrom(
                                  backgroundColor:
                                      Colors
                                          .red),
                          onPressed: () =>
                              Navigator.pop(
                                  ctx, true),
                          child: const Text(
                              'Logout'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true &&
                      context.mounted) {
                    await ref
                        .read(
                            authProvider.notifier)
                        .logout();
                    if (context.mounted) {
                      context.go('/login');
                    }
                  }
                },
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets
                      .symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ── HEADER STAT ────────────────────────────────────────────────
class _HeaderStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _HeaderStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(
            horizontal: 4),
        padding: const EdgeInsets.symmetric(
            vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white
              .withValues(alpha: 0.15),
          borderRadius:
              BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon,
                color: Colors.white, size: 18),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

// ── SECTION CARD ───────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final bool isDark;

  const _SectionCard({
    required this.title,
    required this.children,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark
          ? const Color(0xFF1A1A2E)
          : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                16, 14, 16, 8),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade500,
                letterSpacing: 0.5,
              ),
            ),
          ),
          ...children,
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── INFO TILE ──────────────────────────────────────────────────
class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Icon(icon,
          color: AppTheme.primary, size: 20),
      title: Text(
        label,
        style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade500),
      ),
      trailing: Text(
        value,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: isDark
              ? Colors.white
              : Colors.black87,
        ),
      ),
    );
  }
}

// ── SETTING TILE ───────────────────────────────────────────────
class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final VoidCallback onTap;
  final Widget? trailing;

  const _SettingTile({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Icon(icon,
          color: AppTheme.primary, size: 20),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          color: isDark
              ? Colors.white
              : Colors.black87,
        ),
      ),
      trailing: trailing ??
          Icon(Icons.arrow_forward_ios,
              size: 14,
              color: Colors.grey.shade400),
      onTap: onTap,
    );
  }
}