import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_qr/features/scanner/result_screen.dart';
import 'package:smart_qr/l10n/app_localizations.dart';
import 'package:smart_qr/models/scan_model.dart';
import 'package:smart_qr/services/database_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<ScanModel>> _historyFuture;
  List<ScanModel> _allHistory = [];
  List<ScanModel> _filteredHistory = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _refreshHistory();
  }

  void _refreshHistory() {
    setState(() {
      _historyFuture = DatabaseService().getHistory().then((value) {
        _allHistory = value;
        _filterHistory(_searchController.text);
        return value;
      });
    });
  }

  void _filterHistory(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredHistory = _allHistory;
      });
    } else {
      setState(() {
        _filteredHistory = _allHistory
            .where((scan) =>
                scan.rawValue.toLowerCase().contains(query.toLowerCase()))
            .toList();
      });
    }
  }

  IconData _getIcon(QrType type) {
    switch (type) {
      case QrType.url:
        return Icons.link;
      case QrType.email:
        return Icons.email;
      case QrType.phone:
        return Icons.phone;
      case QrType.wifi:
        return Icons.wifi;
      case QrType.location:
        return Icons.location_on;
      case QrType.text:
        return Icons.text_fields;
      case QrType.contact:
        return Icons.person_add;
      case QrType.payment:
        return Icons.payment;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: l10n.searchHistory,
                  border: InputBorder.none,
                ),
                onChanged: _filterHistory,
              )
            : Text(l10n.scanHistory),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _filterHistory('');
                }
              });
            },
          ),
          if (!_isSearching)
            IconButton(
              icon: const Icon(Icons.delete_forever),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(l10n.clearHistory),
                    content: Text(l10n.clearHistoryConfirmation),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(l10n.cancel),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(l10n.delete),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await DatabaseService().clearHistory();
                  _refreshHistory();
                }
              },
            ),
        ],
      ),
      body: FutureBuilder<List<ScanModel>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (_filteredHistory.isEmpty) {
            return Center(child: Text(l10n.noHistory));
          }

          return ListView.builder(
            itemCount: _filteredHistory.length,
            itemBuilder: (context, index) {
              final scan = _filteredHistory[index];
              return Dismissible(
                key: Key(scan.id.toString()),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (direction) async {
                  await DatabaseService().deleteScan(scan.id!);
                  // Update local list without full refresh
                  setState(() {
                    _allHistory.removeWhere((s) => s.id == scan.id);
                    _filterHistory(_searchController.text);
                  });
                },
                child: ListTile(
                  leading: Icon(_getIcon(scan.type)),
                  title: Text(
                    scan.rawValue,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    DateFormat('MMM d, y h:mm a').format(scan.timestamp),
                  ),
                  trailing: IconButton(
                    icon: Icon(
                      scan.isFavorite ? Icons.star : Icons.star_border,
                      color: scan.isFavorite ? Colors.amber : null,
                    ),
                    onPressed: () async {
                      await DatabaseService().toggleFavorite(scan.id!, !scan.isFavorite);
                      _refreshHistory();
                    },
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ResultScreen(rawValue: scan.rawValue),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
