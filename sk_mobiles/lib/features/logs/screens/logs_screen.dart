import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';

class LogsScreen extends ConsumerStatefulWidget {
  const LogsScreen({super.key});

  @override
  ConsumerState<LogsScreen> createState() =>
      _LogsScreenState();
}

class _LogsScreenState extends ConsumerState<LogsScreen> {
  bool _isLoading = true;
  List<dynamic> _logs = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await ApiClient().getLogs();
      setState(() {
        _logs = response.data['logs'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load logs';
        _isLoading = false;
      });
    }
  }

  IconData _getModuleIcon(String? module) {
    switch (module) {
      case 'products':
        return Icons.inventory;
      case 'temper_glass':
        return Icons.smartphone;
      case 'users':
        return Icons.person;
      case 'categories':
        return Icons.category;
      case 'excel':
        return Icons.table_chart;
      case 'auth':
        return Icons.lock;
      default:
        return Icons.history;
    }
  }

  Color _getModuleColor(String? module) {
    switch (module) {
      case 'products':
        return Colors.blue;
      case 'temper_glass':
        return Colors.teal;
      case 'users':
        return Colors.purple;
      case 'categories':
        return Colors.orange;
      case 'excel':
        return Colors.green;
      case 'auth':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity Logs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLogs,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: Colors.red),
                      const SizedBox(height: 12),
                      Text(_error!),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _loadLogs,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _logs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history,
                              size: 64,
                              color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text(
                            'No activity yet',
                            style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadLogs,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _logs.length,
                        itemBuilder: (context, index) {
                          final log = _logs[index];
                          final module =
                              log['module'] as String?;
                          final color =
                              _getModuleColor(module);

                          return Container(
                            margin: const EdgeInsets.only(
                                bottom: 10),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                          .brightness ==
                                      Brightness.dark
                                  ? const Color(0xFF1E1E2E)
                                  : Colors.white,
                              borderRadius:
                                  BorderRadius.circular(12),
                              border: Border(
                                left: BorderSide(
                                    color: color, width: 4),
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
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: color
                                      .withValues(alpha: 0.1),
                                  borderRadius:
                                      BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  _getModuleIcon(module),
                                  color: color,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                log['action'] ?? '',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              subtitle: Text(
                                '${log['date'] ?? ''} at ${log['time'] ?? ''}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                              trailing: Container(
                                padding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4),
                                decoration: BoxDecoration(
                                  color: color
                                      .withValues(alpha: 0.1),
                                  borderRadius:
                                      BorderRadius.circular(6),
                                ),
                                child: Text(
                                  module ?? 'system',
                                  style: TextStyle(
                                      color: color,
                                      fontSize: 10,
                                      fontWeight:
                                          FontWeight.w600),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}