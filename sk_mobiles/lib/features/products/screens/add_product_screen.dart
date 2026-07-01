import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/products_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/image_upload_helper.dart';

class AddProductScreen extends ConsumerStatefulWidget {
  final int categoryId;
  final String categoryName;

  const AddProductScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  ConsumerState<AddProductScreen> createState() =>
      _AddProductScreenState();
}

class _AddProductScreenState
    extends ConsumerState<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _brandCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _wattsCtrl = TextEditingController();
  final _qtyCtrl =
      TextEditingController(text: '0');
  final _notesCtrl = TextEditingController();
  String? _selectedCableType;
  bool _isLoading = false;
  File? _selectedImage;
  final _picker = ImagePicker();

  final List<String> _cableTypes = [
    'Type-C',
    'Lightning',
    'Micro USB',
  ];
  final List<String> _wattOptions = [
    '18W', '20W', '25W', '33W',
    '45W', '65W', '100W',
  ];

  bool get _isMobileCovers => widget.categoryName
      .toLowerCase()
      .contains('cover');
  bool get _isCharger =>
      widget.categoryName
          .toLowerCase()
          .contains('charger') &&
      !widget.categoryName
          .toLowerCase()
          .contains('cable');
  bool get _isCable => widget.categoryName
      .toLowerCase()
      .contains('cable');

  @override
  void dispose() {
    _brandCtrl.dispose();
    _modelCtrl.dispose();
    _nameCtrl.dispose();
    _wattsCtrl.dispose();
    _qtyCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(
      ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(
            () => _selectedImage = File(picked.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Could not pick image')),
        );
      }
    }
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context)
              .scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20)),
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
                borderRadius:
                    BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Select Image',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _ImageSourceButton(
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    color: AppTheme.primary,
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickImage(
                          ImageSource.camera);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ImageSourceButton(
                    icon: Icons.photo_library,
                    label: 'Gallery',
                    color: Colors.purple,
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickImage(
                          ImageSource.gallery);
                    },
                  ),
                ),
              ],
            ),
            if (_selectedImage != null) ...[
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () {
                  setState(
                      () => _selectedImage = null);
                  Navigator.pop(ctx);
                },
                icon: const Icon(Icons.delete,
                    color: Colors.red),
                label: const Text('Remove Image',
                    style: TextStyle(
                        color: Colors.red)),
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final data = <String, dynamic>{
      'category_id': widget.categoryId,
      'brand': _brandCtrl.text.trim(),
      'quantity':
          int.tryParse(_qtyCtrl.text) ?? 0,
      'notes': _notesCtrl.text.trim(),
    };

    if (_isMobileCovers) {
      data['mobile_model'] =
          _modelCtrl.text.trim();
    } else if (_isCharger) {
      data['watts'] = _wattsCtrl.text.trim();
    } else if (_isCable) {
      data['cable_type'] =
          _selectedCableType ?? '';
    } else {
      data['product_name'] =
          _nameCtrl.text.trim();
    }

    // Step 1: Add product → get new ID
    final newProductId = await ref
        .read(productsProvider.notifier)
        .addProduct(data);

    // Step 2: Upload image to correct product
    if (newProductId != null &&
        _selectedImage != null) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
                SizedBox(width: 12),
                Text('Uploading image...'),
              ],
            ),
            duration: Duration(seconds: 20),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      final imageUrl = await ImageUploadHelper
          .uploadProductImage(
        _selectedImage!,
        newProductId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context)
            .hideCurrentSnackBar();
      }

      // Force reload after image upload
      await ref
          .read(productsProvider.notifier)
          .loadProducts(widget.categoryId);
    }

    setState(() => _isLoading = false);

    if (newProductId != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _selectedImage != null
                ? '✅ Product added with image!'
                : '✅ Product added successfully!',
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(10)),
        ),
      );
      context.pop();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Failed to add product'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0A0A1A)
          : const Color(0xFFF0F4FF),
      appBar: AppBar(
        title:
            Text('Add to ${widget.categoryName}'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch,
            children: [
              // ── IMAGE PICKER ──────────────────
              GestureDetector(
                onTap: _showImagePicker,
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1A1A2E)
                        : AppTheme.primary
                            .withValues(alpha: 0.05),
                    borderRadius:
                        BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.primary
                          .withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: _selectedImage != null
                      ? Stack(
                          children: [
                            ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(
                                      14),
                              child: Image.file(
                                _selectedImage!,
                                width:
                                    double.infinity,
                                height:
                                    double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() =>
                                        _selectedImage =
                                            null),
                                child: Container(
                                  padding:
                                      const EdgeInsets
                                          .all(6),
                                  decoration:
                                      const BoxDecoration(
                                    color:
                                        Colors.red,
                                    shape: BoxShape
                                        .circle,
                                  ),
                                  child: const Icon(
                                      Icons.close,
                                      color:
                                          Colors.white,
                                      size: 16),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 8,
                              right: 8,
                              child: Container(
                                padding:
                                    const EdgeInsets
                                        .symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration:
                                    BoxDecoration(
                                  color:
                                      Colors.black54,
                                  borderRadius:
                                      BorderRadius
                                          .circular(8),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.edit,
                                        color: Colors
                                            .white,
                                        size: 14),
                                    SizedBox(
                                        width: 4),
                                    Text('Change',
                                        style:
                                            TextStyle(
                                          color: Colors
                                              .white,
                                          fontSize:
                                              12,
                                        )),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment:
                              MainAxisAlignment
                                  .center,
                          children: [
                            Container(
                              padding:
                                  const EdgeInsets
                                      .all(16),
                              decoration:
                                  BoxDecoration(
                                color:
                                    AppTheme.primary
                                        .withValues(
                                            alpha:
                                                0.1),
                                shape:
                                    BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons
                                    .add_photo_alternate_outlined,
                                size: 36,
                                color:
                                    AppTheme.primary,
                              ),
                            ),
                            const SizedBox(
                                height: 12),
                            const Text(
                              'Add Product Image',
                              style: TextStyle(
                                fontWeight:
                                    FontWeight.w600,
                                color:
                                    AppTheme.primary,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Camera or Gallery',
                              style: TextStyle(
                                  color: Colors
                                      .grey.shade500,
                                  fontSize: 12),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 20),

              // ── BRAND ─────────────────────────
              TextFormField(
                controller: _brandCtrl,
                decoration: InputDecoration(
                  labelText: 'Brand *',
                  prefixIcon:
                      const Icon(Icons.business),
                  hintText:
                      'e.g. Samsung, Apple, MI',
                  filled: true,
                  fillColor: isDark
                      ? const Color(0xFF1A1A2E)
                      : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                ),
                validator: (v) => v!.isEmpty
                    ? 'Brand is required'
                    : null,
              ),
              const SizedBox(height: 14),

              // ── CATEGORY SPECIFIC ─────────────
              if (_isMobileCovers) ...[
                TextFormField(
                  controller: _modelCtrl,
                  decoration: InputDecoration(
                    labelText: 'Mobile Model *',
                    prefixIcon: const Icon(
                        Icons.phone_android),
                    hintText:
                        'e.g. Samsung S24, iPhone 15',
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF1A1A2E)
                        : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                  ),
                  validator: (v) => v!.isEmpty
                      ? 'Mobile model required'
                      : null,
                ),
              ] else if (_isCharger) ...[
                DropdownButtonFormField<String>(
                  value: _wattsCtrl.text.isEmpty
                      ? null
                      : _wattsCtrl.text,
                  dropdownColor: isDark
                      ? const Color(0xFF1A1A2E)
                      : Colors.white,
                  decoration: InputDecoration(
                    labelText: 'Wattage *',
                    prefixIcon: const Icon(
                        Icons.electric_bolt),
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF1A1A2E)
                        : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                  ),
                  items: _wattOptions
                      .map((w) => DropdownMenuItem(
                            value: w,
                            child: Text(w),
                          ))
                      .toList(),
                  onChanged: (v) => setState(
                      () => _wattsCtrl.text = v ?? ''),
                  validator: (v) => v == null
                      ? 'Select wattage'
                      : null,
                ),
              ] else if (_isCable) ...[
                DropdownButtonFormField<String>(
                  value: _selectedCableType,
                  dropdownColor: isDark
                      ? const Color(0xFF1A1A2E)
                      : Colors.white,
                  decoration: InputDecoration(
                    labelText: 'Cable Type *',
                    prefixIcon:
                        const Icon(Icons.cable),
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF1A1A2E)
                        : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                  ),
                  items: _cableTypes
                      .map((t) => DropdownMenuItem(
                            value: t,
                            child: Text(t),
                          ))
                      .toList(),
                  onChanged: (v) => setState(
                      () => _selectedCableType = v),
                  validator: (v) => v == null
                      ? 'Select cable type'
                      : null,
                ),
              ] else ...[
                TextFormField(
                  controller: _nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Product Name',
                    prefixIcon:
                        const Icon(Icons.inventory),
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF1A1A2E)
                        : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 14),

              // ── QUANTITY ──────────────────────
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _qtyCtrl,
                      keyboardType:
                          TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Quantity *',
                        prefixIcon: const Icon(
                            Icons.numbers),
                        filled: true,
                        fillColor: isDark
                            ? const Color(0xFF1A1A2E)
                            : Colors.white,
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(
                                  12),
                        ),
                      ),
                      validator: (v) {
                        if (v!.isEmpty)
                          return 'Required';
                        if (int.tryParse(v) == null)
                          return 'Invalid number';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    children: [
                      _SmallQtyBtn(
                        icon: Icons.add,
                        color: AppTheme.primary,
                        onTap: () {
                          final v = int.tryParse(
                                  _qtyCtrl.text) ??
                              0;
                          setState(() =>
                              _qtyCtrl.text =
                                  '${v + 1}');
                        },
                      ),
                      const SizedBox(height: 6),
                      _SmallQtyBtn(
                        icon: Icons.remove,
                        color: Colors.grey,
                        onTap: () {
                          final v = int.tryParse(
                                  _qtyCtrl.text) ??
                              0;
                          if (v > 0) {
                            setState(() =>
                                _qtyCtrl.text =
                                    '${v - 1}');
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // ── NOTES ─────────────────────────
              TextFormField(
                controller: _notesCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Notes (optional)',
                  prefixIcon:
                      const Icon(Icons.note),
                  hintText: 'Any additional notes...',
                  alignLabelWithHint: true,
                  filled: true,
                  fillColor: isDark
                      ? const Color(0xFF1A1A2E)
                      : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // ── SAVE BUTTON ───────────────────
              ElevatedButton(
                onPressed: _isLoading ? null : _save,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      vertical: 16),
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child:
                            CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Row(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          const Icon(
                              Icons.check_circle_outline),
                          const SizedBox(width: 8),
                          Text(
                            _selectedImage != null
                                ? 'Add Product with Image'
                                : 'Add Product',
                            style: const TextStyle(
                                fontSize: 16),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ── IMAGE SOURCE BUTTON ────────────────────────────────────────
class _ImageSourceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ImageSourceButton({
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
        padding: const EdgeInsets.symmetric(
            vertical: 20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ── SMALL QTY BUTTON ──────────────────────────────────────────
class _SmallQtyBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SmallQtyBtn({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: color.withValues(alpha: 0.3)),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}