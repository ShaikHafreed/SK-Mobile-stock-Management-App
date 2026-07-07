import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/whatsapp_share.dart';
import '../../../models/product_model.dart';

class BillingScreen extends ConsumerStatefulWidget {
  const BillingScreen({super.key});

  @override
  ConsumerState<BillingScreen> createState() =>
      _BillingScreenState();
}

class _BillingScreenState
    extends ConsumerState<BillingScreen> {
  final List<_BillItem> _items = [];
  final _searchCtrl = TextEditingController();
  List<ProductModel> _searchResults = [];
  bool _isSearching = false;
  String _customerName = '';
  String _customerPhone = '';

  double get _subtotal =>
      _items.fold(0, (s, i) => s + i.total);
  double get _tax => _subtotal * 0.18;
  double get _grandTotal => _subtotal + _tax;

  Future<void> _search(String query) async {
    if (query.trim().length < 2) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _isSearching = true);
    try {
      final res = await ApiClient().search(query);
      setState(() {
        _searchResults =
            (res.data['products'] as List)
                .map((p) => ProductModel.fromJson(p))
                .toList();
        _isSearching = false;
      });
    } catch (e) {
      setState(() => _isSearching = false);
    }
  }

  void _addItem(ProductModel product) {
    final existing = _items.indexWhere(
        (i) => i.product.id == product.id);
    if (existing >= 0) {
      setState(() => _items[existing].qty++);
    } else {
      setState(() => _items.add(_BillItem(
            product: product,
            price: 0,
            qty: 1,
          )));
    }
    _searchCtrl.clear();
    setState(() => _searchResults = []);
  }

  void _removeItem(int index) {
    setState(() => _items.removeAt(index));
  }

  void _showBillPreview() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (ctx, scrollCtrl) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context)
                .scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius:
                      BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: _BillPreview(
                  items: _items,
                  customerName: _customerName,
                  customerPhone: _customerPhone,
                  subtotal: _subtotal,
                  tax: _tax,
                  grandTotal: _grandTotal,
                  scrollCtrl: scrollCtrl,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Bill'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        actions: [
          if (_items.isNotEmpty)
            TextButton(
              onPressed: () =>
                  setState(() => _items.clear()),
              child: const Text('Clear',
                  style: TextStyle(
                      color: Colors.white70)),
            ),
        ],
      ),
      body: Column(
        children: [
          // ── CUSTOMER INFO ─────────────────────
          Container(
            color: AppTheme.primary
                .withValues(alpha: 0.05),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (v) =>
                        _customerName = v,
                    decoration: InputDecoration(
                      hintText: 'Customer Name',
                      prefixIcon: const Icon(
                          Icons.person_outline),
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(10),
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    onChanged: (v) =>
                        _customerPhone = v,
                    keyboardType:
                        TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: 'Phone (optional)',
                      prefixIcon: const Icon(
                          Icons.phone_outlined),
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(10),
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── SEARCH PRODUCTS ───────────────────
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _search,
              decoration: InputDecoration(
                hintText:
                    'Search and add products...',
                prefixIcon:
                    const Icon(Icons.search),
                suffixIcon: _isSearching
                    ? const Padding(
                        padding:
                            EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child:
                              CircularProgressIndicator(
                                  strokeWidth: 2),
                        ),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          // ── SEARCH RESULTS ────────────────────
          if (_searchResults.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(
                  horizontal: 12),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1A1A2E)
                    : Colors.white,
                borderRadius:
                    BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black
                        .withValues(alpha: 0.1),
                    blurRadius: 8,
                  ),
                ],
              ),
              constraints: const BoxConstraints(
                  maxHeight: 200),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _searchResults.length,
                itemBuilder: (ctx, i) {
                  final p = _searchResults[i];
                  return ListTile(
                    dense: true,
                    leading: ClipRRect(
                      borderRadius:
                          BorderRadius.circular(6),
                      child: p.imageUrl != null
                          ? Image.network(
                              p.imageUrl!,
                              width: 36,
                              height: 36,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (_, __, ___) =>
                                      const Icon(
                                Icons.phone_android,
                                color:
                                    AppTheme.primary,
                              ),
                            )
                          : const Icon(
                              Icons.phone_android,
                              color:
                                  AppTheme.primary,
                            ),
                    ),
                    title: Text(
                      '${p.brand ?? ''} ${p.displayName}',
                      style: const TextStyle(
                          fontSize: 13),
                    ),
                    subtitle: Text(
                      'Stock: ${p.quantity}',
                      style: const TextStyle(
                          fontSize: 11),
                    ),
                    trailing: IconButton(
                      icon: const Icon(
                          Icons.add_circle,
                          color: AppTheme.primary),
                      onPressed: () => _addItem(p),
                    ),
                    onTap: () => _addItem(p),
                  );
                },
              ),
            ),

          // ── BILL ITEMS ────────────────────────
          Expanded(
            child: _items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long,
                            size: 64,
                            color: Colors
                                .grey.shade300),
                        const SizedBox(height: 12),
                        Text(
                          'No items added yet',
                          style: TextStyle(
                              color: Colors
                                  .grey.shade500,
                              fontSize: 15),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Search above to add products',
                          style: TextStyle(
                              color: Colors
                                  .grey.shade400,
                              fontSize: 12),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding:
                        const EdgeInsets.all(12),
                    itemCount: _items.length,
                    itemBuilder: (ctx, i) =>
                        _BillItemTile(
                      item: _items[i],
                      onRemove: () =>
                          _removeItem(i),
                      onQtyChange: (qty) =>
                          setState(() =>
                              _items[i].qty = qty),
                      onPriceChange: (price) =>
                          setState(() => _items[i]
                              .price = price),
                    ),
                  ),
          ),

          // ── TOTAL BAR ─────────────────────────
          if (_items.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1A1A2E)
                    : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black
                        .withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .spaceBetween,
                    children: [
                      Text('Subtotal',
                          style: TextStyle(
                              color: Colors.grey
                                  .shade600)),
                      Text(
                          '₹${_subtotal.toStringAsFixed(2)}'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .spaceBetween,
                    children: [
                      Text('GST (18%)',
                          style: TextStyle(
                              color: Colors.grey
                                  .shade600)),
                      Text(
                          '₹${_tax.toStringAsFixed(2)}'),
                    ],
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .spaceBetween,
                    children: [
                      const Text(
                        'Grand Total',
                        style: TextStyle(
                          fontWeight:
                              FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '₹${_grandTotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight:
                              FontWeight.bold,
                          fontSize: 18,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _showBillPreview,
                      icon: const Icon(
                          Icons.receipt_long),
                      label: const Text(
                          'Preview & Share Bill'),
                      style:
                          ElevatedButton.styleFrom(
                        padding: const EdgeInsets
                            .symmetric(
                            vertical: 14),
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                                  12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── BILL ITEM ──────────────────────────────────────────────────
class _BillItem {
  final ProductModel product;
  int qty;
  double price;

  _BillItem({
    required this.product,
    required this.qty,
    required this.price,
  });

  double get total => qty * price;
}

// ── BILL ITEM TILE ─────────────────────────────────────────────
class _BillItemTile extends StatefulWidget {
  final _BillItem item;
  final VoidCallback onRemove;
  final ValueChanged<int> onQtyChange;
  final ValueChanged<double> onPriceChange;

  const _BillItemTile({
    required this.item,
    required this.onRemove,
    required this.onQtyChange,
    required this.onPriceChange,
  });

  @override
  State<_BillItemTile> createState() =>
      _BillItemTileState();
}

class _BillItemTileState
    extends State<_BillItemTile> {
  late TextEditingController _priceCtrl;

  @override
  void initState() {
    super.initState();
    _priceCtrl = TextEditingController(
      text: widget.item.price > 0
          ? widget.item.price.toString()
          : '',
    );
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1A1A2E)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.item.product.brand ?? ''} ${widget.item.product.displayName}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      widget.item.product
                              .categoryName ??
                          '',
                      style: TextStyle(
                          color:
                              Colors.grey.shade500,
                          fontSize: 11),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                    size: 20),
                onPressed: widget.onRemove,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _priceCtrl,
                  keyboardType:
                      TextInputType.number,
                  onChanged: (v) {
                    final price =
                        double.tryParse(v) ?? 0;
                    widget.onPriceChange(price);
                  },
                  decoration: InputDecoration(
                    labelText: 'Price ₹',
                    isDense: true,
                    prefixText: '₹ ',
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(8),
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Row(
                children: [
                  GestureDetector(
                    onTap: widget.item.qty > 1
                        ? () => widget.onQtyChange(
                            widget.item.qty - 1)
                        : null,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color:
                            Colors.grey.shade100,
                        borderRadius:
                            BorderRadius.circular(
                                8),
                        border: Border.all(
                            color: Colors
                                .grey.shade300),
                      ),
                      child: Icon(Icons.remove,
                          size: 16,
                          color: widget.item.qty >
                                  1
                              ? Colors
                                  .grey.shade700
                              : Colors
                                  .grey.shade300),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets
                        .symmetric(
                        horizontal: 10),
                    child: Text(
                      '${widget.item.qty}',
                      style: const TextStyle(
                        fontWeight:
                            FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () =>
                        widget.onQtyChange(
                            widget.item.qty + 1),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius:
                            BorderRadius.circular(
                                8),
                      ),
                      child: const Icon(Icons.add,
                          size: 16,
                          color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Text(
                '₹${widget.item.total.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── BILL PREVIEW ───────────────────────────────────────────────
class _BillPreview extends StatelessWidget {
  final List<_BillItem> items;
  final String customerName;
  final String customerPhone;
  final double subtotal;
  final double tax;
  final double grandTotal;
  final ScrollController scrollCtrl;

  const _BillPreview({
    required this.items,
    required this.customerName,
    required this.customerPhone,
    required this.subtotal,
    required this.tax,
    required this.grandTotal,
    required this.scrollCtrl,
  });

  Future<void> _shareOnWhatsApp(
      BuildContext context,
      String billNo,
      String dateStr) async {
    final itemMaps = items
        .map((i) => {
              'name':
                  '${i.product.brand ?? ''} ${i.product.displayName}'
                      .trim(),
              'qty': i.qty,
              'price':
                  i.price.toStringAsFixed(0),
              'total':
                  i.total.toStringAsFixed(0),
            })
        .toList();

    final text = WhatsAppShare.buildBillText(
      billNo: billNo,
      dateStr: dateStr,
      customerName: customerName,
      items: itemMaps,
      subtotal: subtotal,
      gst: tax,
      total: grandTotal,
    );

    final ok = await WhatsAppShare.shareBill(
      billText: text,
      phone: customerPhone,
    );

    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              '❌ Could not open WhatsApp. Is it installed?'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateStr =
        DateFormat('dd MMM yyyy, hh:mm a')
            .format(now);
    final billNo =
        'SKM${now.millisecondsSinceEpoch.toString().substring(8)}';

    return SingleChildScrollView(
      controller: scrollCtrl,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF1565C0),
                  Color(0xFF42A5F5),
                ],
              ),
              borderRadius:
                  BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Icon(Icons.phone_android,
                    color: Colors.white,
                    size: 36),
                const SizedBox(height: 8),
                const Text(
                  'SR MOBILES',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const Text(
                  'Mobile Accessories Store',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment
                          .spaceBetween,
                  children: [
                    Text('Bill No: $billNo',
                        style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11)),
                    Text(dateStr,
                        style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Customer info
          if (customerName.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius:
                    BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person,
                      color: AppTheme.primary,
                      size: 18),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        customerName,
                        style: const TextStyle(
                            fontWeight:
                                FontWeight.bold),
                      ),
                      if (customerPhone
                          .isNotEmpty)
                        Text(customerPhone,
                            style: TextStyle(
                                color: Colors.grey
                                    .shade600,
                                fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),

          // Items header
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primary
                  .withValues(alpha: 0.1),
              borderRadius:
                  BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Expanded(
                    flex: 3,
                    child: Text('Item',
                        style: TextStyle(
                            fontWeight:
                                FontWeight.bold,
                            fontSize: 12))),
                Expanded(
                    child: Text('Qty',
                        textAlign:
                            TextAlign.center,
                        style: TextStyle(
                            fontWeight:
                                FontWeight.bold,
                            fontSize: 12))),
                Expanded(
                    child: Text('Price',
                        textAlign:
                            TextAlign.center,
                        style: TextStyle(
                            fontWeight:
                                FontWeight.bold,
                            fontSize: 12))),
                Expanded(
                    child: Text('Total',
                        textAlign:
                            TextAlign.right,
                        style: TextStyle(
                            fontWeight:
                                FontWeight.bold,
                            fontSize: 12))),
              ],
            ),
          ),

          // Items
          ...items.map((item) => Padding(
                padding:
                    const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 12),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        '${item.product.brand ?? ''} ${item.product.displayName}',
                        style: const TextStyle(
                            fontSize: 12),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '${item.qty}',
                        textAlign:
                            TextAlign.center,
                        style: const TextStyle(
                            fontSize: 12),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '₹${item.price.toStringAsFixed(0)}',
                        textAlign:
                            TextAlign.center,
                        style: const TextStyle(
                            fontSize: 12),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '₹${item.total.toStringAsFixed(0)}',
                        textAlign:
                            TextAlign.right,
                        style: const TextStyle(
                            fontWeight:
                                FontWeight.bold,
                            fontSize: 12),
                      ),
                    ),
                  ],
                ),
              )),

          const Divider(),

          // Totals
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 12),
            child: Column(
              children: [
                _TotalRow('Subtotal',
                    '₹${subtotal.toStringAsFixed(2)}'),
                _TotalRow('GST (18%)',
                    '₹${tax.toStringAsFixed(2)}'),
                const Divider(),
                _TotalRow(
                  'GRAND TOTAL',
                  '₹${grandTotal.toStringAsFixed(2)}',
                  isTotal: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Thank you
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius:
                  BorderRadius.circular(12),
              border: Border.all(
                  color: Colors.green.shade200),
            ),
            child: const Row(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                Icon(Icons.favorite,
                    color: Colors.red, size: 16),
                SizedBox(width: 8),
                Text(
                  'Thank you for shopping at SR Mobiles!',
                  style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                      fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── WHATSAPP SHARE BUTTON ─────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _shareOnWhatsApp(
                  context, billNo, dateStr),
              icon: const Icon(Icons.share),
              label: const Text(
                  'Share on WhatsApp'),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(0xFF25D366),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;

  const _TotalRow(this.label, this.value,
      {this.isTotal = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal
                  ? FontWeight.bold
                  : FontWeight.normal,
              fontSize: isTotal ? 16 : 13,
              color: isTotal
                  ? null
                  : Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isTotal
                  ? FontWeight.bold
                  : FontWeight.normal,
              fontSize: isTotal ? 18 : 13,
              color: isTotal
                  ? AppTheme.primary
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}