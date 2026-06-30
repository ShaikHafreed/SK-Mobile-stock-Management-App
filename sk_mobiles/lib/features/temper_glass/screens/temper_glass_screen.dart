import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/temper_glass_provider.dart';
import '../../../models/temper_box_model.dart';
import '../../../core/theme/app_theme.dart';

class TemperGlassScreen extends ConsumerStatefulWidget {
  const TemperGlassScreen({super.key});

  @override
  ConsumerState<TemperGlassScreen> createState() =>
      _TemperGlassScreenState();
}

class _TemperGlassScreenState
    extends ConsumerState<TemperGlassScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => ref.read(temperGlassProvider.notifier).loadBoxes());
  }

  void _showCreateBoxDialog() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 12,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
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
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.add_box,
                      color: AppTheme.primary, size: 22),
                ),
                const SizedBox(width: 12),
                const Text('Create New Box',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: 'Box Name *',
                hintText: 'e.g. Box 1, Samsung Box',
                prefixIcon: const Icon(Icons.inbox),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'e.g. Samsung temper glasses',
                prefixIcon: const Icon(Icons.note),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (nameCtrl.text.trim().isEmpty) return;
                      final success = await ref
                          .read(temperGlassProvider.notifier)
                          .createBox(
                            nameCtrl.text.trim(),
                            descCtrl.text.trim(),
                          );
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (success && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✅ Box created!'),
                            backgroundColor: Colors.green,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Create Box'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(temperGlassProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Temper Glass'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(temperGlassProvider.notifier).loadBoxes(),
          ),
        ],
      ),
      body: state.isLoading
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
                            .read(temperGlassProvider.notifier)
                            .loadBoxes(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : state.boxes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox_outlined,
                              size: 72,
                              color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text(
                            'No boxes yet',
                            style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 18,
                                fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap + to create your first box',
                            style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 14),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => ref
                          .read(temperGlassProvider.notifier)
                          .loadBoxes(),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: state.boxes.length,
                        itemBuilder: (context, index) {
                          return _BoxCard(
                              box: state.boxes[index]);
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateBoxDialog,
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Box',
            style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

// ─── BOX CARD ──────────────────────────────────────────────────
class _BoxCard extends ConsumerStatefulWidget {
  final TemperBoxModel box;
  const _BoxCard({required this.box});

  @override
  ConsumerState<_BoxCard> createState() => _BoxCardState();
}

class _BoxCardState extends ConsumerState<_BoxCard> {
  bool _isExpanded = false;

  void _showAddItemDialog() {
    final modelCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '0');
    final notesCtrl = TextEditingController();

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
                      color: Colors.teal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.smartphone,
                        color: Colors.teal, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Add Item',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold)),
                      Text(widget.box.boxName,
                          style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 13)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextField(
                controller: modelCtrl,
                decoration: InputDecoration(
                  labelText: 'Mobile Model *',
                  hintText: 'e.g. Samsung A15, iPhone 14',
                  prefixIcon: const Icon(Icons.phone_android),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: qtyCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Quantity',
                        prefixIcon: const Icon(Icons.numbers),
                        border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    children: [
                      GestureDetector(
                        onTap: () {
                          final v =
                              int.tryParse(qtyCtrl.text) ?? 0;
                          setSheetState(
                              () => qtyCtrl.text = '${v + 1}');
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
                              color: Colors.white),
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
                              color: Colors.grey.shade700),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesCtrl,
                decoration: InputDecoration(
                  labelText: 'Notes (optional)',
                  prefixIcon: const Icon(Icons.note),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),
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
                        if (modelCtrl.text.trim().isEmpty) return;
                        final success = await ref
                            .read(temperGlassProvider.notifier)
                            .addItem(
                              widget.box.id,
                              modelCtrl.text.trim(),
                              int.tryParse(qtyCtrl.text) ?? 0,
                              notesCtrl.text.trim(),
                            );
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (success && context.mounted) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(
                            const SnackBar(
                              content: Text('✅ Item added!'),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(12)),
                      ),
                      child: const Text('Add Item'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditBoxDialog() {
    final nameCtrl =
        TextEditingController(text: widget.box.boxName);
    final descCtrl =
        TextEditingController(text: widget.box.description ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
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
            const Text('Edit Box',
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: 'Box Name',
                prefixIcon: const Icon(Icons.inbox),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              decoration: InputDecoration(
                labelText: 'Description',
                prefixIcon: const Icon(Icons.note),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),
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
                          .read(temperGlassProvider.notifier)
                          .updateBox(
                            widget.box.id,
                            nameCtrl.text.trim(),
                            descCtrl.text.trim(),
                          );
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (success && context.mounted) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(
                          const SnackBar(
                            content: Text('✅ Box updated!'),
                            backgroundColor: Colors.green,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(12)),
                    ),
                    child: const Text('Save Changes'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteBox() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Box'),
        content: Text(
            'Delete "${widget.box.boxName}" and all its items?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red),
            onPressed: () async {
              await ref
                  .read(temperGlassProvider.notifier)
                  .deleteBox(widget.box.id);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;
    final box = widget.box;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── BOX HEADER ──────────────────────────────────
          GestureDetector(
            onTap: () =>
                setState(() => _isExpanded = !_isExpanded),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(
                      _isExpanded ? 0 : 16),
                  bottomRight: Radius.circular(
                      _isExpanded ? 0 : 16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.inbox,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          box.boxName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (box.description != null &&
                            box.description!.isNotEmpty)
                          Text(
                            box.description!,
                            style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12),
                          ),
                      ],
                    ),
                  ),
                  // Stats
                  Column(
                    children: [
                      Text(
                        '${box.totalItems}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: AppTheme.primary,
                        ),
                      ),
                      const Text('models',
                          style: TextStyle(
                              fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Column(
                    children: [
                      Text(
                        '${box.totalStock}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.green,
                        ),
                      ),
                      const Text('stock',
                          style: TextStyle(
                              fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(width: 8),
                  // Menu
                  PopupMenuButton(
                    icon: const Icon(Icons.more_vert),
                    itemBuilder: (ctx) => [
                      PopupMenuItem(
                        child: const ListTile(
                          leading: Icon(Icons.add,
                              color: Colors.green),
                          title: Text('Add Item'),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                        onTap: () => Future.delayed(
                          const Duration(milliseconds: 100),
                          _showAddItemDialog,
                        ),
                      ),
                      PopupMenuItem(
                        child: const ListTile(
                          leading: Icon(Icons.edit,
                              color: Colors.blue),
                          title: Text('Edit Box'),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                        onTap: () => Future.delayed(
                          const Duration(milliseconds: 100),
                          _showEditBoxDialog,
                        ),
                      ),
                      PopupMenuItem(
                        child: const ListTile(
                          leading: Icon(Icons.delete,
                              color: Colors.red),
                          title: Text('Delete Box',
                              style:
                                  TextStyle(color: Colors.red)),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                        onTap: () => Future.delayed(
                          const Duration(milliseconds: 100),
                          _confirmDeleteBox,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),

          // ── BOX ITEMS ────────────────────────────────────
          if (_isExpanded) ...[
            if (box.items.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(Icons.smartphone_outlined,
                        size: 48,
                        color: Colors.grey.shade300),
                    const SizedBox(height: 8),
                    Text(
                      'No items in this box',
                      style: TextStyle(
                          color: Colors.grey.shade500),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _showAddItemDialog,
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add First Item'),
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: box.items.length,
                itemBuilder: (ctx, i) {
                  final item = box.items[i];
                  return _ItemTile(
                    item: item,
                    boxId: box.id,
                  );
                },
              ),
          ],
        ],
      ),
    );
  }
}

// ─── ITEM TILE ─────────────────────────────────────────────────
class _ItemTile extends ConsumerWidget {
  final TemperBoxItemModel item;
  final int boxId;

  const _ItemTile({required this.item, required this.boxId});

  void _showEditItemDialog(
      BuildContext context, WidgetRef ref) {
    final modelCtrl =
        TextEditingController(text: item.mobileModel);
    final qtyCtrl =
        TextEditingController(text: item.quantity.toString());
    final notesCtrl =
        TextEditingController(text: item.notes ?? '');

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
              const Text('Edit Item',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextField(
                controller: modelCtrl,
                decoration: InputDecoration(
                  labelText: 'Mobile Model',
                  prefixIcon:
                      const Icon(Icons.phone_android),
                  border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: qtyCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Quantity',
                        prefixIcon:
                            const Icon(Icons.numbers),
                        border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    children: [
                      GestureDetector(
                        onTap: () {
                          final v = int.tryParse(
                                  qtyCtrl.text) ??
                              0;
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
                              color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () {
                          final v = int.tryParse(
                                  qtyCtrl.text) ??
                              0;
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
                              color: Colors.grey.shade700),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesCtrl,
                decoration: InputDecoration(
                  labelText: 'Notes',
                  prefixIcon: const Icon(Icons.note),
                  border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),
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
                            .read(
                                temperGlassProvider.notifier)
                            .updateItem(
                              boxId,
                              item.id,
                              modelCtrl.text.trim(),
                              int.tryParse(qtyCtrl.text) ??
                                  0,
                              notesCtrl.text.trim(),
                            );
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (success && context.mounted) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(
                            const SnackBar(
                              content:
                                  Text('✅ Item updated!'),
                              backgroundColor: Colors.green,
                              behavior:
                                  SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(12)),
                      ),
                      child: const Text('Save Changes'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(
          horizontal: 12, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: item.isLowStock
            ? Colors.red.shade50
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: item.isLowStock
              ? Colors.red.shade200
              : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: item.isLowStock
                  ? Colors.red.shade100
                  : AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.smartphone,
              color: item.isLowStock
                  ? Colors.red
                  : AppTheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.mobileModel,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14),
                ),
                if (item.notes != null &&
                    item.notes!.isNotEmpty)
                  Text(
                    item.notes!,
                    style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: item.isLowStock
                  ? Colors.red
                  : Colors.green,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Qty: ${item.quantity}',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
          ),
          PopupMenuButton(
            icon: const Icon(Icons.more_vert, size: 18),
            itemBuilder: (ctx) => [
              PopupMenuItem(
                child: const ListTile(
                  leading: Icon(Icons.edit,
                      color: Colors.blue, size: 18),
                  title: Text('Edit',
                      style: TextStyle(fontSize: 13)),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
                onTap: () => Future.delayed(
                  const Duration(milliseconds: 100),
                  () => _showEditItemDialog(context, ref),
                ),
              ),
              PopupMenuItem(
                child: const ListTile(
                  leading: Icon(Icons.delete,
                      color: Colors.red, size: 18),
                  title: Text('Delete',
                      style: TextStyle(
                          color: Colors.red, fontSize: 13)),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
                onTap: () => Future.delayed(
                  const Duration(milliseconds: 100),
                  () => showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete Item'),
                      content: Text(
                          'Delete ${item.mobileModel}?'),
                      actions: [
                        TextButton(
                          onPressed: () =>
                              Navigator.pop(ctx),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red),
                          onPressed: () async {
                            await ref
                                .read(temperGlassProvider
                                    .notifier)
                                .deleteItem(
                                    boxId, item.id);
                            if (ctx.mounted)
                              Navigator.pop(ctx);
                          },
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}