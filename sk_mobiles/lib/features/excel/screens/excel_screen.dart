import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';

class ExcelScreen extends ConsumerStatefulWidget {
  const ExcelScreen({super.key});

  @override
  ConsumerState<ExcelScreen> createState() =>
      _ExcelScreenState();
}

class _ExcelScreenState
    extends ConsumerState<ExcelScreen> {
  final Map<String, bool> _downloading = {};
  final Map<String, String> _savedPaths = {};

  final List<Map<String, dynamic>> _reports = [
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
    setState(() => _downloading[slug] = true);

    try {
      final response =
          await ApiClient().exportExcel(slug);

      if (response.statusCode == 200) {
        final bytes = response.data as List<int>;

        Directory dir;
        if (Platform.isAndroid) {
          dir = Directory(
              '/storage/emulated/0/Download');
          if (!await dir.exists()) {
            dir =
                await getApplicationDocumentsDirectory();
          }
        } else {
          dir =
              await getApplicationDocumentsDirectory();
        }

        final ts = DateTime.now()
            .millisecondsSinceEpoch
            .toString()
            .substring(7);
        final filename =
            'SKMobiles_${title.replaceAll(' ', '_')}_$ts.xlsx';
        final filePath = '${dir.path}/$filename';
        final file = File(filePath);
        await file.writeAsBytes(bytes, flush: true);

        setState(
            () => _savedPaths[slug] = filePath);

        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(
            SnackBar(
              content: Text(
                  '✅ Saved to Downloads/$filename'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration:
                  const Duration(seconds: 6),
              action: SnackBarAction(
                label: 'OPEN',
                textColor: Colors.white,
                onPressed: () =>
                    OpenFile.open(filePath),
              ),
            ),
          );
        }
      } else {
        throw Exception(
            'Status ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text('❌ Export failed: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(
            () => _downloading[slug] = false);
      }
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
        title: const Text('Excel Reports'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── FULL INVENTORY BANNER ─────────────
          Container(
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
              borderRadius:
                  BorderRadius.circular(16),
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
                  padding:
                      const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white
                        .withValues(alpha: 0.2),
                    borderRadius:
                        BorderRadius.circular(10),
                  ),
                  child: const Icon(
                      Icons.inventory_2,
                      color: Colors.white,
                      size: 26),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Full Inventory Report',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight:
                              FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        'All categories in one Excel file',
                        style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11),
                      ),
                    ],
                  ),
                ),
                _downloading['full-inventory'] ==
                        true
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child:
                            CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : GestureDetector(
                        onTap: () =>
                            _downloadExcel(
                                'full-inventory',
                                'Full Inventory'),
                        child: Container(
                          padding:
                              const EdgeInsets
                                  .symmetric(
                                  horizontal: 14,
                                  vertical: 8),
                          decoration:
                              BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius
                                    .circular(20),
                          ),
                          child: const Row(
                            mainAxisSize:
                                MainAxisSize.min,
                            children: [
                              Icon(Icons.download,
                                  size: 14,
                                  color: Color(
                                      0xFF1565C0)),
                              SizedBox(width: 4),
                              Text(
                                'Export',
                                style: TextStyle(
                                  color: Color(
                                      0xFF1565C0),
                                  fontWeight:
                                      FontWeight
                                          .bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Text(
            'Individual Reports',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? Colors.white
                  : Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 12),

          // ── LIST (no overflow — ListTile rows) ──
          ..._reports.map((report) {
            final slug = report['slug'] as String;
            final color =
                report['color'] as Color;
            final isDownloading =
                _downloading[slug] == true;
            final savedPath = _savedPaths[slug];

            return Container(
              margin:
                  const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1A1A2E)
                    : Colors.white,
                borderRadius:
                    BorderRadius.circular(14),
                border: Border.all(
                  color: savedPath != null
                      ? Colors.green
                      : color.withValues(
                          alpha: 0.15),
                ),
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
                contentPadding:
                    const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6),
                leading: Container(
                  padding:
                      const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(
                        alpha: 0.12),
                    borderRadius:
                        BorderRadius.circular(10),
                  ),
                  child: Icon(
                      report['icon'] as IconData,
                      color: color,
                      size: 22),
                ),
                title: Text(
                  report['title'] as String,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isDark
                        ? Colors.white
                        : Colors.black87,
                  ),
                ),
                subtitle: Text(
                  report['subtitle'] as String,
                  style: TextStyle(
                      fontSize: 11,
                      color:
                          Colors.grey.shade500),
                ),
                trailing: isDownloading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child:
                            CircularProgressIndicator(
                                strokeWidth: 2),
                      )
                    : savedPath != null
                        ? Row(
                            mainAxisSize:
                                MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                    Icons
                                        .open_in_new,
                                    color: Colors
                                        .green,
                                    size: 20),
                                tooltip: 'Open',
                                onPressed: () =>
                                    OpenFile.open(
                                        savedPath),
                              ),
                              IconButton(
                                icon: Icon(
                                    Icons.refresh,
                                    color: color,
                                    size: 20),
                                tooltip:
                                    'Re-export',
                                onPressed: () =>
                                    _downloadExcel(
                                  slug,
                                  report['title']
                                      as String,
                                ),
                              ),
                            ],
                          )
                        : IconButton(
                            icon: Icon(
                                Icons.download,
                                color: color),
                            onPressed: () =>
                                _downloadExcel(
                              slug,
                              report['title']
                                  as String,
                            ),
                          ),
              ),
            );
          }),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}