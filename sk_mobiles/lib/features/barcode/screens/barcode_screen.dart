import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/product_model.dart';

class BarcodeScreen extends ConsumerStatefulWidget {
  const BarcodeScreen({super.key});

  @override
  ConsumerState<BarcodeScreen> createState() =>
      _BarcodeScreenState();
}

class _BarcodeScreenState
    extends ConsumerState<BarcodeScreen> {
  late MobileScannerController controller;
  bool _isScanning = true;
  bool _isSearching = false;
  bool _torchOn = false;
  String? _lastScanned;
  ProductModel? _foundProduct;
  String? _error;

  @override
  void initState() {
    super.initState();
    controller = MobileScannerController(
      detectionSpeed:
          DetectionSpeed.noDuplicates,
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _searchBarcode(
      String barcode) async {
    if (!_isScanning) return;
    setState(() {
      _isScanning = false;
      _isSearching = true;
      _lastScanned = barcode;
      _foundProduct = null;
      _error = null;
    });
    try {
      final response =
          await ApiClient().search(barcode);
      final products =
          response.data['products'] as List;
      if (products.isNotEmpty) {
        setState(() {
          _foundProduct =
              ProductModel.fromJson(
                  products.first);
          _isSearching = false;
        });
      } else {
        setState(() {
          _error =
              'No product found for: $barcode';
          _isSearching = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Search failed. Try again.';
        _isSearching = false;
      });
    }
  }

  void _reset() {
    setState(() {
      _isScanning = true;
      _foundProduct = null;
      _error = null;
      _lastScanned = null;
    });
  }

  Future<void> _toggleTorch() async {
    await controller.toggleTorch();
    setState(() => _torchOn = !_torchOn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Barcode Scanner'),
        actions: [
          IconButton(
            icon: Icon(
              _torchOn
                  ? Icons.flash_on
                  : Icons.flash_off,
              color: _torchOn
                  ? Colors.yellow
                  : Colors.white,
            ),
            onPressed: _toggleTorch,
          ),
          IconButton(
            icon: const Icon(
                Icons.flip_camera_android,
                color: Colors.white),
            onPressed: () =>
                controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // ── CAMERA ────────────────────────────
          MobileScanner(
            controller: controller,
            onDetect: (capture) {
              final barcodes =
                  capture.barcodes;
              if (barcodes.isNotEmpty &&
                  _isScanning) {
                final value =
                    barcodes.first.rawValue;
                if (value != null) {
                  _searchBarcode(value);
                }
              }
            },
          ),

          // ── SCAN OVERLAY ──────────────────────
          if (_isScanning)
            Center(
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppTheme.primary,
                        width: 2,
                      ),
                      borderRadius:
                          BorderRadius.circular(
                              20),
                    ),
                    child: Stack(
                      children:
                          _buildCorners(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius:
                          BorderRadius.circular(
                              20),
                    ),
                    child: const Text(
                      'Point camera at barcode',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),

          // ── LOADING ───────────────────────────
          if (_isSearching)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                        color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Searching product...',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),

          // ── RESULT ────────────────────────────
          if (_foundProduct != null ||
              _error != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                margin:
                    const EdgeInsets.all(16),
                padding:
                    const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .cardColor,
                  borderRadius:
                      BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black
                          .withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset:
                          const Offset(0, -5),
                    ),
                  ],
                ),
                child: _error != null
                    ? _ErrorResult(
                        error: _error!,
                        scanned:
                            _lastScanned ?? '',
                        onReset: _reset,
                      )
                    : _ProductResult(
                        product: _foundProduct!,
                        onScanAgain: _reset,
                      ),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildCorners() {
    const s = 24.0;
    const t = 3.0;
    const c = AppTheme.primary;
    return [
      Positioned(
          top: 0,
          left: 0,
          child: Container(
              width: s, height: t, color: c)),
      Positioned(
          top: 0,
          left: 0,
          child: Container(
              width: t, height: s, color: c)),
      Positioned(
          top: 0,
          right: 0,
          child: Container(
              width: s, height: t, color: c)),
      Positioned(
          top: 0,
          right: 0,
          child: Container(
              width: t, height: s, color: c)),
      Positioned(
          bottom: 0,
          left: 0,
          child: Container(
              width: s, height: t, color: c)),
      Positioned(
          bottom: 0,
          left: 0,
          child: Container(
              width: t, height: s, color: c)),
      Positioned(
          bottom: 0,
          right: 0,
          child: Container(
              width: s, height: t, color: c)),
      Positioned(
          bottom: 0,
          right: 0,
          child: Container(
              width: t, height: s, color: c)),
    ];
  }
}

// ── ERROR RESULT ───────────────────────────────────────────────
class _ErrorResult extends StatelessWidget {
  final String error;
  final String scanned;
  final VoidCallback onReset;

  const _ErrorResult({
    required this.error,
    required this.scanned,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.search_off,
            size: 48, color: Colors.red),
        const SizedBox(height: 8),
        Text(error,
            style:
                const TextStyle(fontSize: 14),
            textAlign: TextAlign.center),
        const SizedBox(height: 4),
        Text(
          'Scanned: $scanned',
          style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 11),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: onReset,
          icon: const Icon(Icons.refresh),
          label: const Text('Scan Again'),
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }
}

// ── PRODUCT RESULT ─────────────────────────────────────────────
class _ProductResult extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onScanAgain;

  const _ProductResult({
    required this.product,
    required this.onScanAgain,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            ClipRRect(
              borderRadius:
                  BorderRadius.circular(10),
              child: product.imageUrl != null &&
                      product
                          .imageUrl!.isNotEmpty
                  ? Image.network(
                      product.imageUrl!,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __,
                              ___) =>
                          _imgPlaceholder(),
                    )
                  : _imgPlaceholder(),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    '${product.brand ?? ''} ${product.displayName}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    product.categoryName ?? '',
                    style: TextStyle(
                        color:
                            Colors.grey.shade500,
                        fontSize: 12),
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8),
              decoration: BoxDecoration(
                color: product.isLowStock
                    ? Colors.red
                    : Colors.green,
                borderRadius:
                    BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Text(
                    '${product.quantity}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  const Text('in stock',
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 10)),
                ],
              ),
            ),
          ],
        ),
        if (product.isLowStock) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius:
                  BorderRadius.circular(10),
              border: Border.all(
                  color: Colors.red.shade200),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning_amber,
                    color: Colors.red, size: 18),
                SizedBox(width: 8),
                Text(
                  '⚠ Low Stock! Please reorder.',
                  style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                      fontSize: 13),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onScanAgain,
            icon: const Icon(
                Icons.qr_code_scanner),
            label:
                const Text('Scan Another'),
            style: ElevatedButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(
                      vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                          12)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _imgPlaceholder() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: AppTheme.primary
            .withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.phone_android,
          color: AppTheme.primary),
    );
  }
}