import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/products_provider.dart';
import '../../../models/product_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/image_upload_helper.dart';
import '../../../features/auth/providers/auth_provider.dart';

class ProductsScreen extends ConsumerStatefulWidget {
  final int categoryId;
  final String categoryName;

  const ProductsScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  String _searchQuery = '';
  bool _isGridView = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        ref.read(productsProvider.notifier).loadProducts(widget.categoryId));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productsProvider);
    final authState = ref.watch(authProvider);
    final isAdmin = authState.user?.isAdmin ?? false;

    final filtered = state.products.where((p) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return (p.brand?.toLowerCase().contains(q) ?? false) ||
          (p.productName?.toLowerCase().contains(q) ?? false) ||
          (p.mobileModel?.toLowerCase().contains(q) ?? false) ||
          (p.watts?.toLowerCase().contains(q) ?? false) ||
          (p.cableType?.toLowerCase().contains(q) ?? false);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName),
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
            onPressed: () => setState(() => _isGridView = !_isGridView),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref
                .read(productsProvider.notifier)
                .loadProducts(widget.categoryId),
          ),
        ],
      ),
      body: Column(
        children: [
          _AnimatedSection(
            delay: 0,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: 'Search ${widget.categoryName}...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () =>
                              setState(() => _searchQuery = ''),
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),

          if (state.products.isNotEmpty)
            _AnimatedSection(
              delay: 100,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatItem(
                      label: 'Total Items',
                      value: '${state.products.length}',
                      color: AppTheme.primary,
                    ),
                    _StatItem(
                      label: 'Total Stock',
                      value:
                          '${state.products.fold(0, (s, p) => s + p.quantity)}',
                      color: AppTheme.success,
                    ),
                    _StatItem(
                      label: 'Low Stock',
                      value:
                          '${state.products.where((p) => p.isLowStock).length}',
                      color: Colors.red,
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),

          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline,
                                size: 48, color: Colors.red),
                            const SizedBox(height: 12),
                            Text(state.error!),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () => ref
                                  .read(productsProvider.notifier)
                                  .loadProducts(widget.categoryId),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : filtered.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.inventory_2_outlined,
                                    size: 64,
                                    color: Colors.grey.shade300),
                                const SizedBox(height: 16),
                                Text(
                                  _searchQuery.isEmpty
                                      ? 'No products yet'
                                      : 'No results found',
                                  style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 16),
                                ),
                                if (_searchQuery.isEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Tap + to add your first product',
                                    style: TextStyle(
                                        color: Colors.grey.shade400,
                                        fontSize: 13),
                                  ),
                                ],
                              ],
                            ),
                          )
                        : _isGridView
                            ? GridView.builder(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 0.72,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                ),
                                itemCount: filtered.length,
                                itemBuilder: (context, index) {
                                  final product = filtered[index];
                                  return _AnimatedSection(
                                    delay: 150 + (index * 60),
                                    child: _AmazonProductCard(
                                      product: product,
                                      isAdmin: isAdmin,
                                      categoryId: widget.categoryId,
                                      categorySlug: widget.categoryName,
                                    ),
                                  );
                                },
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                itemCount: filtered.length,
                                itemBuilder: (context, index) {
                                  final product = filtered[index];
                                  return _AnimatedSection(
                                    delay: 150 + (index * 60),
                                    child: _ProductCard(
                                      product: product,
                                      isAdmin: isAdmin,
                                      categoryId: widget.categoryId,
                                      categorySlug: widget.categoryName,
                                    ),
                                  );
                                },
                              ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(
          '/add-product/${widget.categoryId}/${Uri.encodeComponent(widget.categoryName)}',
        ),
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Product',
            style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

// ─── ANIMATED SECTION ──────────────────────────────────────────
class _AnimatedSection extends StatefulWidget {
  final Widget child;
  final int delay;

  const _AnimatedSection({required this.child, this.delay = 0});

  @override
  State<_AnimatedSection> createState() => _AnimatedSectionState();
}

class _AnimatedSectionState extends State<_AnimatedSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

// ─── STAT ITEM ─────────────────────────────────────────────────
class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color)),
        Text(label,
            style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}

// ─── AMAZON PRODUCT CARD (GRID) ────────────────────────────────
class _AmazonProductCard extends ConsumerWidget {
  final ProductModel product;
  final bool isAdmin;
  final int categoryId;
  final String categorySlug;

  const _AmazonProductCard({
    required this.product,
    required this.isAdmin,
    required this.categoryId,
    required this.categorySlug,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: product.isLowStock
            ? Border.all(color: Colors.red, width: 1.5)
            : Border.all(color: Colors.grey.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── IMAGE SECTION ──────────────────────────────
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12)),
                child: product.imageUrl != null &&
                        product.imageUrl!.isNotEmpty
                    ? Image.network(
                        product.imageUrl!,
                        width: double.infinity,
                        height: 130,
                        fit: BoxFit.cover,
                        loadingBuilder: (ctx, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            width: double.infinity,
                            height: 130,
                            color: AppTheme.primary
                                .withValues(alpha: 0.05),
                            child: const Center(
                              child: CircularProgressIndicator(
                                  strokeWidth: 2),
                            ),
                          );
                        },
                        errorBuilder: (_, __, ___) =>
                            _PlaceholderImage(),
                      )
                    : _PlaceholderImage(),
              ),

              // Low stock badge
              if (product.isLowStock)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      '⚠ Low Stock',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

              // ── UPDATED: Actions menu — delete for ALL ──
              Positioned(
                top: 6,
                right: 6,
                child: PopupMenuButton(
                  icon: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.more_vert,
                        color: Colors.white, size: 16),
                  ),
                  itemBuilder: (context) => [
                    // Edit
                    PopupMenuItem(
                      child: const ListTile(
                        leading: Icon(Icons.edit,
                            color: Colors.blue, size: 20),
                        title: Text('Edit',
                            style: TextStyle(fontSize: 14)),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                      onTap: () => Future.delayed(
                        const Duration(milliseconds: 100),
                        () => _showEditSheet(context, ref),
                      ),
                    ),
                    // Change Image
                    PopupMenuItem(
                      child: const ListTile(
                        leading: Icon(Icons.add_photo_alternate,
                            color: Colors.purple, size: 20),
                        title: Text('Change Image',
                            style: TextStyle(fontSize: 14)),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                      onTap: () => Future.delayed(
                        const Duration(milliseconds: 100),
                        () => _pickAndUploadImage(context, ref),
                      ),
                    ),
                    // Delete — visible for ALL users
                    PopupMenuItem(
                      child: const ListTile(
                        leading: Icon(Icons.delete,
                            color: Colors.red, size: 20),
                        title: Text('Delete',
                            style: TextStyle(
                                color: Colors.red, fontSize: 14)),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                      onTap: () => Future.delayed(
                        const Duration(milliseconds: 100),
                        () => _confirmDelete(context, ref),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ── PRODUCT INFO ───────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.brand ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _getSubtitle(),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: product.quantity < 3
                              ? Colors.red.shade50
                              : Colors.green.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: product.quantity < 3
                                ? Colors.red.shade200
                                : Colors.green.shade200,
                          ),
                        ),
                        child: Text(
                          'Qty: ${product.quantity}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: product.quantity < 3
                                ? Colors.red
                                : Colors.green.shade700,
                          ),
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: product.quantity > 0
                            ? () => ref
                                .read(productsProvider.notifier)
                                .updateQuantity(
                                  product.id,
                                  product.quantity - 1,
                                  categoryId,
                                )
                            : null,
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: Colors.grey.shade300),
                          ),
                          child: Icon(
                            Icons.remove,
                            size: 14,
                            color: product.quantity > 0
                                ? Colors.grey.shade700
                                : Colors.grey.shade300,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => ref
                            .read(productsProvider.notifier)
                            .updateQuantity(
                              product.id,
                              product.quantity + 1,
                              categoryId,
                            ),
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.add,
                              size: 14, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getSubtitle() {
    if (product.mobileModel != null &&
        product.mobileModel!.isNotEmpty) return product.mobileModel!;
    if (product.watts != null && product.watts!.isNotEmpty) {
      return '${product.watts}W';
    }
    if (product.cableType != null && product.cableType!.isNotEmpty) {
      return product.cableType!;
    }
    if (product.productName != null &&
        product.productName!.isNotEmpty) return product.productName!;
    return '';
  }

  // ─── UPDATED: Image upload with loading indicator ──────────
  Future<void> _pickAndUploadImage(
      BuildContext context, WidgetRef ref) async {
    final picker = ImagePicker();

    Future<void> doUpload(ImageSource source) async {
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 800,
        imageQuality: 85,
      );
      if (picked == null || !context.mounted) return;

      // Show uploading snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
              SizedBox(width: 12),
              Text('Uploading image...'),
            ],
          ),
          duration: Duration(seconds: 15),
          behavior: SnackBarBehavior.floating,
        ),
      );

      final url = await ImageUploadHelper.uploadProductImage(
        File(picked.path),
        product.id,
      );

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (url != null) {
        await ref
            .read(productsProvider.notifier)
            .loadProducts(categoryId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Image updated successfully!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Upload failed. Check your connection.'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Change Product Image',
              style: TextStyle(
                  fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _ImageSourceBtn(
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    color: AppTheme.primary,
                    onTap: () {
                      Navigator.pop(ctx);
                      doUpload(ImageSource.camera);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ImageSourceBtn(
                    icon: Icons.photo_library,
                    label: 'Gallery',
                    color: Colors.purple,
                    onTap: () {
                      Navigator.pop(ctx);
                      doUpload(ImageSource.gallery);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showEditSheet(BuildContext context, WidgetRef ref) {
    final brandCtrl =
        TextEditingController(text: product.brand ?? '');
    final modelCtrl =
        TextEditingController(text: product.mobileModel ?? '');
    final nameCtrl =
        TextEditingController(text: product.productName ?? '');
    final wattsCtrl =
        TextEditingController(text: product.watts ?? '');
    final qtyCtrl =
        TextEditingController(text: product.quantity.toString());
    final notesCtrl =
        TextEditingController(text: product.notes ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primary
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.edit,
                          color: AppTheme.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Edit Product',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold)),
                        Text(product.brand ?? '',
                            style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 13)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _EditField(
                    controller: brandCtrl,
                    label: 'Brand',
                    icon: Icons.business),
                const SizedBox(height: 12),
                if (product.mobileModel != null) ...[
                  _EditField(
                      controller: modelCtrl,
                      label: 'Mobile Model',
                      icon: Icons.phone_android),
                  const SizedBox(height: 12),
                ],
                if (product.productName != null &&
                    product.productName!.isNotEmpty) ...[
                  _EditField(
                      controller: nameCtrl,
                      label: 'Product Name',
                      icon: Icons.inventory),
                  const SizedBox(height: 12),
                ],
                if (product.watts != null &&
                    product.watts!.isNotEmpty) ...[
                  _EditField(
                      controller: wattsCtrl,
                      label: 'Watts',
                      icon: Icons.electric_bolt),
                  const SizedBox(height: 12),
                ],
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: _EditField(
                        controller: qtyCtrl,
                        label: 'Quantity',
                        icon: Icons.numbers,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      children: [
                        GestureDetector(
                          onTap: () {
                            final v =
                                int.tryParse(qtyCtrl.text) ?? 0;
                            setSheetState(() =>
                                qtyCtrl.text = '${v + 1}');
                          },
                          child: Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: AppTheme.primary,
                              borderRadius:
                                  BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.add,
                                color: Colors.white, size: 22),
                          ),
                        ),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: () {
                            final v =
                                int.tryParse(qtyCtrl.text) ?? 0;
                            if (v > 0) {
                              setSheetState(() =>
                                  qtyCtrl.text = '${v - 1}');
                            }
                          },
                          child: Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius:
                                  BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.remove,
                                color: Colors.grey.shade700,
                                size: 22),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _EditField(
                    controller: notesCtrl,
                    label: 'Notes (optional)',
                    icon: Icons.note_outlined,
                    maxLines: 2),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(12)),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () async {
                          final success = await ref
                              .read(productsProvider.notifier)
                              .updateProduct(
                                product.id,
                                {
                                  'brand': brandCtrl.text,
                                  'mobile_model': modelCtrl.text,
                                  'product_name': nameCtrl.text,
                                  'watts': wattsCtrl.text,
                                  'quantity':
                                      int.tryParse(qtyCtrl.text) ??
                                          0,
                                  'notes': notesCtrl.text,
                                },
                                categoryId,
                              );
                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context)
                                .showSnackBar(SnackBar(
                              content: Text(success
                                  ? '✅ Product updated!'
                                  : '❌ Update failed'),
                              backgroundColor: success
                                  ? Colors.green
                                  : Colors.red,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(10)),
                            ));
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(12)),
                        ),
                        child: const Text('Save Changes',
                            style: TextStyle(fontSize: 15)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── UPDATED: Delete for all users ─────────────────────────
  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.delete_outline,
                  color: Colors.red, size: 22),
            ),
            const SizedBox(width: 12),
            const Text('Delete Product'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete:',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.phone_android,
                      color: Colors.grey, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${product.brand ?? ''} ${product.displayName}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This action cannot be undone.',
              style: TextStyle(
                  color: Colors.red.shade400, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await ref
                  .read(productsProvider.notifier)
                  .deleteProduct(product.id, categoryId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? '🗑️ Product deleted'
                        : '❌ Delete failed'),
                    backgroundColor:
                        success ? Colors.orange : Colors.red,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                );
              }
            },
            icon: const Icon(Icons.delete, size: 18),
            label: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ─── LIST PRODUCT CARD ─────────────────────────────────────────
class _ProductCard extends ConsumerWidget {
  final ProductModel product;
  final bool isAdmin;
  final int categoryId;
  final String categorySlug;

  const _ProductCard({
    required this.product,
    required this.isAdmin,
    required this.categoryId,
    required this.categorySlug,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: product.isLowStock
            ? const BorderSide(color: Colors.red, width: 1.5)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: product.isLowStock
                    ? Colors.red.shade50
                    : AppTheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: product.imageUrl != null &&
                      product.imageUrl!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        product.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                            Icons.phone_android,
                            color: AppTheme.primary),
                      ),
                    )
                  : Icon(Icons.phone_android,
                      color: product.isLowStock
                          ? Colors.red
                          : AppTheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          product.brand ?? '',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15),
                        ),
                      ),
                      if (product.isLowStock)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('Low Stock',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _getSubtitle(),
                    style: TextStyle(
                        color: Colors.grey.shade600, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: product.quantity < 3
                              ? Colors.red.shade50
                              : Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: product.quantity < 3
                                ? Colors.red.shade200
                                : Colors.green.shade200,
                          ),
                        ),
                        child: Text(
                          'Qty: ${product.quantity}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: product.quantity < 3
                                ? Colors.red
                                : Colors.green.shade700,
                          ),
                        ),
                      ),
                      const Spacer(),
                      _QtyButton(
                        icon: Icons.remove,
                        onTap: product.quantity > 0
                            ? () => ref
                                .read(productsProvider.notifier)
                                .updateQuantity(product.id,
                                    product.quantity - 1, categoryId)
                            : null,
                      ),
                      const SizedBox(width: 6),
                      _QtyButton(
                        icon: Icons.add,
                        onTap: () => ref
                            .read(productsProvider.notifier)
                            .updateQuantity(product.id,
                                product.quantity + 1, categoryId),
                        isPrimary: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton(
              icon: const Icon(Icons.more_vert, size: 20),
              itemBuilder: (context) => [
                PopupMenuItem(
                  child: const ListTile(
                    leading: Icon(Icons.edit, color: Colors.blue),
                    title: Text('Edit'),
                    contentPadding: EdgeInsets.zero,
                  ),
                  onTap: () => Future.delayed(
                    const Duration(milliseconds: 100),
                    () => _showEditSheet(context, ref),
                  ),
                ),
                // Delete for all users in list view too
                PopupMenuItem(
                  child: const ListTile(
                    leading: Icon(Icons.delete, color: Colors.red),
                    title: Text('Delete',
                        style: TextStyle(color: Colors.red)),
                    contentPadding: EdgeInsets.zero,
                  ),
                  onTap: () => Future.delayed(
                    const Duration(milliseconds: 100),
                    () => _confirmDelete(context, ref),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getSubtitle() {
    if (product.mobileModel != null &&
        product.mobileModel!.isNotEmpty) return product.mobileModel!;
    if (product.watts != null && product.watts!.isNotEmpty) {
      return '${product.watts}W';
    }
    if (product.cableType != null && product.cableType!.isNotEmpty) {
      return product.cableType!;
    }
    if (product.productName != null &&
        product.productName!.isNotEmpty) return product.productName!;
    return '';
  }

  void _showEditSheet(BuildContext context, WidgetRef ref) {
    final brandCtrl =
        TextEditingController(text: product.brand ?? '');
    final modelCtrl =
        TextEditingController(text: product.mobileModel ?? '');
    final nameCtrl =
        TextEditingController(text: product.productName ?? '');
    final wattsCtrl =
        TextEditingController(text: product.watts ?? '');
    final qtyCtrl =
        TextEditingController(text: product.quantity.toString());
    final notesCtrl =
        TextEditingController(text: product.notes ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primary
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.edit,
                          color: AppTheme.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Edit Product',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold)),
                        Text(product.brand ?? '',
                            style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 13)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _EditField(
                    controller: brandCtrl,
                    label: 'Brand',
                    icon: Icons.business),
                const SizedBox(height: 12),
                if (product.mobileModel != null) ...[
                  _EditField(
                      controller: modelCtrl,
                      label: 'Mobile Model',
                      icon: Icons.phone_android),
                  const SizedBox(height: 12),
                ],
                if (product.productName != null &&
                    product.productName!.isNotEmpty) ...[
                  _EditField(
                      controller: nameCtrl,
                      label: 'Product Name',
                      icon: Icons.inventory),
                  const SizedBox(height: 12),
                ],
                if (product.watts != null &&
                    product.watts!.isNotEmpty) ...[
                  _EditField(
                      controller: wattsCtrl,
                      label: 'Watts',
                      icon: Icons.electric_bolt),
                  const SizedBox(height: 12),
                ],
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: _EditField(
                        controller: qtyCtrl,
                        label: 'Quantity',
                        icon: Icons.numbers,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      children: [
                        GestureDetector(
                          onTap: () {
                            final v =
                                int.tryParse(qtyCtrl.text) ?? 0;
                            setSheetState(() =>
                                qtyCtrl.text = '${v + 1}');
                          },
                          child: Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: AppTheme.primary,
                              borderRadius:
                                  BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.add,
                                color: Colors.white, size: 22),
                          ),
                        ),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: () {
                            final v =
                                int.tryParse(qtyCtrl.text) ?? 0;
                            if (v > 0) {
                              setSheetState(() =>
                                  qtyCtrl.text = '${v - 1}');
                            }
                          },
                          child: Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius:
                                  BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.remove,
                                color: Colors.grey.shade700,
                                size: 22),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _EditField(
                    controller: notesCtrl,
                    label: 'Notes (optional)',
                    icon: Icons.note_outlined,
                    maxLines: 2),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(12)),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () async {
                          final success = await ref
                              .read(productsProvider.notifier)
                              .updateProduct(
                                product.id,
                                {
                                  'brand': brandCtrl.text,
                                  'mobile_model': modelCtrl.text,
                                  'product_name': nameCtrl.text,
                                  'watts': wattsCtrl.text,
                                  'quantity':
                                      int.tryParse(qtyCtrl.text) ??
                                          0,
                                  'notes': notesCtrl.text,
                                },
                                categoryId,
                              );
                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context)
                                .showSnackBar(SnackBar(
                              content: Text(success
                                  ? '✅ Product updated!'
                                  : '❌ Update failed'),
                              backgroundColor: success
                                  ? Colors.green
                                  : Colors.red,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(10)),
                            ));
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(12)),
                        ),
                        child: const Text('Save Changes',
                            style: TextStyle(fontSize: 15)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.delete_outline,
                  color: Colors.red, size: 22),
            ),
            const SizedBox(width: 12),
            const Text('Delete Product'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete:',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.phone_android,
                      color: Colors.grey, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${product.brand ?? ''} ${product.displayName}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This action cannot be undone.',
              style: TextStyle(
                  color: Colors.red.shade400, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await ref
                  .read(productsProvider.notifier)
                  .deleteProduct(product.id, categoryId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? '🗑️ Product deleted'
                        : '❌ Delete failed'),
                    backgroundColor:
                        success ? Colors.orange : Colors.red,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                );
              }
            },
            icon: const Icon(Icons.delete, size: 18),
            label: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ─── PLACEHOLDER IMAGE ─────────────────────────────────────────
class _PlaceholderImage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 130,
      color: AppTheme.primary.withValues(alpha: 0.06),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.phone_android,
              size: 40,
              color: AppTheme.primary.withValues(alpha: 0.4)),
          const SizedBox(height: 4),
          Text('No Image',
              style: TextStyle(
                  fontSize: 10, color: Colors.grey.shade400)),
        ],
      ),
    );
  }
}

// ─── IMAGE SOURCE BUTTON ───────────────────────────────────────
class _ImageSourceBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ImageSourceBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(label,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ─── EDIT FIELD ────────────────────────────────────────────────
class _EditField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final int maxLines;
  final TextInputType? keyboardType;

  const _EditField({
    required this.controller,
    required this.label,
    required this.icon,
    this.maxLines = 1,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppTheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 14),
      ),
    );
  }
}

// ─── QTY BUTTON ───────────────────────────────────────────────
class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool isPrimary;

  const _QtyButton({
    required this.icon,
    this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: onTap == null
              ? Colors.grey.shade200
              : isPrimary
                  ? AppTheme.primary
                  : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: onTap == null
                ? Colors.grey.shade300
                : isPrimary
                    ? AppTheme.primary
                    : Colors.grey.shade300,
          ),
        ),
        child: Icon(
          icon,
          size: 16,
          color: onTap == null
              ? Colors.grey.shade400
              : isPrimary
                  ? Colors.white
                  : Colors.grey.shade700,
        ),
      ),
    );
  }
}