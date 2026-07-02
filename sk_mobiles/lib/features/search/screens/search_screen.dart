import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/product_model.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() =>
      _SearchScreenState();
}

class _SearchScreenState
    extends ConsumerState<SearchScreen> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  bool _isLoading = false;
  bool _hasSearched = false;
  String _filter = 'all'; // all | products | glass
  List<ProductModel> _products = [];
  List<Map<String, dynamic>> _glassItems = [];

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(
        const Duration(milliseconds: 450), () {
      _search(query);
    });
  }

  Future<void> _search(String query) async {
    final q = query.trim();
    if (q.length < 2) {
      setState(() {
        _products = [];
        _glassItems = [];
        _hasSearched = false;
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });
    try {
      final res = await ApiClient().search(q);
      final data = res.data;
      setState(() {
        _products =
            ((data['products'] as List?) ?? [])
                .map((p) =>
                    ProductModel.fromJson(p))
                .toList();
        _glassItems =
            ((data['temper_glass_items']
                        as List?) ??
                    [])
                .cast<Map<String, dynamic>>();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _products = [];
        _glassItems = [];
      });
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
                '❌ Search failed. Check backend connection.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  int get _totalResults =>
      _products.length + _glassItems.length;

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    final showProducts =
        _filter == 'all' || _filter == 'products';
    final showGlass =
        _filter == 'all' || _filter == 'glass';

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0A0A1A)
          : const Color(0xFFF0F4FF),
      appBar: AppBar(
        title: const Text('Search Stock'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // ── SEARCH BAR ────────────────────────
          Padding(
            padding: const EdgeInsets.all(14),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onChanged,
              autofocus: true,
              textInputAction:
                  TextInputAction.search,
              onSubmitted: _search,
              decoration: InputDecoration(
                hintText:
                    'Search brand, model, product...',
                prefixIcon:
                    const Icon(Icons.search),
                suffixIcon: _searchCtrl
                        .text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                            Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          _search('');
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark
                    ? const Color(0xFF1A1A2E)
                    : Colors.white,
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // ── FILTER CHIPS ──────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
                horizontal: 14),
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  isActive: _filter == 'all',
                  onTap: () => setState(
                      () => _filter = 'all'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label:
                      'Products (${_products.length})',
                  isActive:
                      _filter == 'products',
                  onTap: () => setState(
                      () => _filter = 'products'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label:
                      'Temper Glass (${_glassItems.length})',
                  isActive: _filter == 'glass',
                  onTap: () => setState(
                      () => _filter = 'glass'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // ── RESULTS ───────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(
                    child:
                        CircularProgressIndicator())
                : !_hasSearched
                    ? _EmptyState(
                        icon: Icons.search,
                        title:
                            'Search your stock',
                        subtitle:
                            'Type at least 2 characters to search products and temper glass',
                      )
                    : _totalResults == 0
                        ? _EmptyState(
                            icon:
                                Icons.search_off,
                            title:
                                'No results found',
                            subtitle:
                                'Try a different brand, model or product name',
                          )
                        : ListView(
                            padding:
                                const EdgeInsets
                                    .fromLTRB(14,
                                    4, 14, 20),
                            children: [
                              if (showProducts &&
                                  _products
                                      .isNotEmpty) ...[
                                _SectionHeader(
                                    title:
                                        '📦 Products (${_products.length})',
                                    isDark:
                                        isDark),
                                ..._products.map(
                                    (p) =>
                                        _ProductTile(
                                          product:
                                              p,
                                          isDark:
                                              isDark,
                                        )),
                                const SizedBox(
                                    height: 12),
                              ],
                              if (showGlass &&
                                  _glassItems
                                      .isNotEmpty) ...[
                                _SectionHeader(
                                    title:
                                        '🛡️ Temper Glass (${_glassItems.length})',
                                    isDark:
                                        isDark),
                                ..._glassItems.map(
                                    (g) =>
                                        _GlassTile(
                                          item: g,
                                          isDark:
                                              isDark,
                                          onTap: () =>
                                              context.push(
                                                  '/temper-glass'),
                                        )),
                              ],
                            ],
                          ),
          ),
        ],
      ),
    );
  }
}

// ── FILTER CHIP ────────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration:
            const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.primary
              : AppTheme.primary
                  .withValues(alpha: 0.08),
          borderRadius:
              BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive
                ? Colors.white
                : AppTheme.primary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ── SECTION HEADER ─────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final bool isDark;

  const _SectionHeader(
      {required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: isDark
              ? Colors.white
              : Colors.grey.shade800,
        ),
      ),
    );
  }
}

// ── PRODUCT TILE ───────────────────────────────────────────────
class _ProductTile extends StatelessWidget {
  final ProductModel product;
  final bool isDark;

  const _ProductTile(
      {required this.product,
      required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1A1A2E)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: product.imageUrl != null &&
                  product.imageUrl!.isNotEmpty
              ? Image.network(
                  product.imageUrl!,
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      _placeholder(),
                )
              : _placeholder(),
        ),
        title: Text(
          '${product.brand ?? ''} ${product.displayName}'
              .trim(),
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: isDark
                ? Colors.white
                : Colors.black87,
          ),
        ),
        subtitle: Text(
          product.categoryName ?? '',
          style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade500),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: product.isLowStock
                ? Colors.red
                : Colors.green,
            borderRadius:
                BorderRadius.circular(8),
          ),
          child: Text(
            'Qty: ${product.quantity}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 44,
      height: 44,
      color: AppTheme.primary
          .withValues(alpha: 0.1),
      child: const Icon(Icons.phone_android,
          color: AppTheme.primary, size: 20),
    );
  }
}

// ── GLASS TILE ─────────────────────────────────────────────────
class _GlassTile extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool isDark;
  final VoidCallback onTap;

  const _GlassTile({
    required this.item,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final qty = item['quantity'] ?? 0;
    final isLow = (qty is int ? qty : 0) < 3;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1A1A2E)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFF00695C)
                .withValues(alpha: 0.1),
            borderRadius:
                BorderRadius.circular(8),
          ),
          child: const Icon(Icons.smartphone,
              color: Color(0xFF00695C),
              size: 20),
        ),
        title: Text(
          '${item['mobile_model'] ?? item['model'] ?? 'Unknown model'}',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: isDark
                ? Colors.white
                : Colors.black87,
          ),
        ),
        subtitle: Text(
          'Box: ${item['box_name'] ?? item['box'] ?? '-'}',
          style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade500),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isLow
                ? Colors.red
                : Colors.green,
            borderRadius:
                BorderRadius.circular(8),
          ),
          child: Text(
            'Qty: $qty',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }
}

// ── EMPTY STATE ────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 64,
                color: Colors.grey.shade300),
            const SizedBox(height: 14),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade400),
            ),
          ],
        ),
      ),
    );
  }
}