import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';

class ExcelScreen extends ConsumerStatefulWidget {
  const ExcelScreen({super.key});

  @override
  ConsumerState<ExcelScreen> createState() =>
      _ExcelScreenState();
}

class _ExcelScreenState extends ConsumerState<ExcelScreen> {
  final Map<String, bool> _downloading = {};
  final Map<String, bool> _downloaded = {};

  final List<Map<String, dynamic>> _reports = [
    {
      'title': 'Full Inventory',
      'subtitle': 'All categories in one file',
      'slug': 'full-inventory',
      'icon': Icons.inventory_2,
      'color': Color(0xFF1565C0),
    },
    {
      'title': 'Mobile Covers',
      'subtitle': 'All covers with models',
      'slug': 'mobile-covers',
      'icon': Icons.phone_android,
      'color': Color(0xFF7B1FA2),
    },
    {
      'title': 'Earphones',
      'subtitle': 'All earphones stock',
      'slug': 'earphones',
      'icon': Icons.headphones,
      'color': Color(0xFFE65100),
    },
    {
      'title': 'Earbuds',
      'subtitle': 'All earbuds stock',
      'slug': 'earbuds',
      'icon': Icons.earbuds,
      'color': Color(0xFFC2185B),
    },
    {
      'title': 'Chargers',
      'subtitle': 'All chargers by wattage',
      'slug': 'chargers',
      'icon': Icons.electric_bolt,
      'color': Color(0xFFF57F17),
    },
    {
      'title': 'Charger Cables',
      'subtitle': 'Type-C, Lightning, Micro USB',
      'slug': 'charger-cables',
      'icon': Icons.cable,
      'color': Color(0xFF00695C),
    },
    {
      'title': 'Temper Glass',
      'subtitle': 'By box and mobile model',
      'slug': 'temper-glass',
      'icon': Icons.smartphone,
      'color': Color(0xFF2E7D32),
    },
    {
      'title': 'Others',
      'subtitle': 'Other accessories',
      'slug': 'others',
      'icon': Icons.category,
      'color': Color(0xFFC62828),
    },
  ];

  Future<void> _downloadExcel(
      String slug, String title) async {
    setState(() {
      _downloading[slug] = true;
      _downloaded[slug] = false;
    });

    try {
      final response = await ApiClient().exportExcel(slug);

      if (response.statusCode == 200) {
        final bytes = response.data as List<int>;

        // Save to downloads directory
        final dir = await getApplicationDocumentsDirectory();
        final filename =
            '${title.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
        final file = File('${dir.path}/$filename');
        await file.writeAsBytes(bytes);

        setState(() => _downloaded[slug] = true);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '✅ $title exported!',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Saved: $filename',
                    style: const TextStyle(fontSize: 11),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Export failed: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _downloading[slug] = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Excel Reports'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── INFO BANNER ─────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primary.withValues(alpha: 0.1),
                    AppTheme.primary.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                      AppTheme.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primary
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.table_chart,
                      color: AppTheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Export Stock Reports',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Download Excel files with stock levels, low stock alerts and product details.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── FULL INVENTORY HIGHLIGHT ─────────────────
            GestureDetector(
              onTap: () =>
                  _downloadExcel('full-inventory', 'Full Inventory'),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF1565C0),
                      Color(0xFF42A5F5),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1565C0)
                          .withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color:
                            Colors.white.withValues(alpha: 0.2),
                        borderRadius:
                            BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.inventory_2,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Full Inventory Report',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'All categories in one Excel file',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _downloading['full-inventory'] == true
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                                  BorderRadius.circular(20),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.download,
                                    size: 16,
                                    color: Color(0xFF1565C0)),
                                SizedBox(width: 4),
                                Text(
                                  'Export',
                                  style: TextStyle(
                                    color: Color(0xFF1565C0),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Individual Reports',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // ── INDIVIDUAL REPORTS ───────────────────────
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              // Skip 'full-inventory' since it's shown above
              itemCount: _reports.length - 1,
              itemBuilder: (context, index) {
                final report = _reports[index + 1];
                final slug = report['slug'] as String;
                final isDownloading =
                    _downloading[slug] == true;
                final isDownloaded =
                    _downloaded[slug] == true;
                final color = report['color'] as Color;

                return GestureDetector(
                  onTap: isDownloading
                      ? null
                      : () => _downloadExcel(
                            slug,
                            report['title'] as String,
                          ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E1E2E)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDownloaded
                            ? Colors.green
                            : color.withValues(alpha: 0.2),
                        width: isDownloaded ? 1.5 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(14),
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
                                  const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: color
                                    .withValues(alpha: 0.1),
                                borderRadius:
                                    BorderRadius.circular(8),
                              ),
                              child: Icon(
                                report['icon'] as IconData,
                                color: color,
                                size: 20,
                              ),
                            ),
                            if (isDownloaded)
                              const Icon(Icons.check_circle,
                                  color: Colors.green,
                                  size: 18),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          report['title'] as String,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          report['subtitle'] as String,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: isDownloading
                              ? Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: color,
                                    ),
                                  ),
                                )
                              : Container(
                                  padding:
                                      const EdgeInsets.symmetric(
                                          vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isDownloaded
                                        ? Colors.green
                                        : color,
                                    borderRadius:
                                        BorderRadius.circular(
                                            8),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment
                                            .center,
                                    children: [
                                      Icon(
                                        isDownloaded
                                            ? Icons.check
                                            : Icons.download,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        isDownloaded
                                            ? 'Done'
                                            : 'Export',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight:
                                              FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}