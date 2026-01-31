import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tripspending/providers/trip_provider.dart';
import 'package:tripspending/providers/receipt_provider.dart';
import 'package:tripspending/screens/add_receipt_screen.dart';
import 'package:tripspending/screens/dashboard_screen.dart';
import 'package:tripspending/screens/map_screen.dart';
import 'package:tripspending/screens/export_screen.dart';
import 'package:tripspending/widgets/receipt_list_item.dart';
import 'package:tripspending/widgets/trip_stats_card.dart';
import 'package:tripspending/widgets/empty_state.dart';
import 'package:intl/intl.dart';

/// Screen showing trip details and receipts
class TripDetailScreen extends StatefulWidget {
  final int tripId;

  const TripDetailScreen({super.key, required this.tripId});

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TripProvider>().selectTrip(widget.tripId);
      context.read<ReceiptProvider>().loadReceipts(widget.tripId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<TripProvider, ReceiptProvider>(
      builder: (context, tripProvider, receiptProvider, child) {
        final trip = tripProvider.selectedTrip;

        if (trip == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(trip.name),
            actions: [
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'dashboard':
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DashboardScreen(tripId: widget.tripId),
                        ),
                      );
                      break;
                    case 'map':
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MapScreen(tripId: widget.tripId),
                        ),
                      );
                      break;
                    case 'export':
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ExportScreen(tripId: widget.tripId),
                        ),
                      );
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'dashboard',
                    child: ListTile(
                      leading: Icon(Icons.dashboard),
                      title: Text('Dashboard'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'map',
                    child: ListTile(
                      leading: Icon(Icons.map),
                      title: Text('View on Map'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'export',
                    child: ListTile(
                      leading: Icon(Icons.share),
                      title: Text('Export'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: Column(
            children: [
              // Trip stats card
              TripStatsCard(
                trip: trip,
                receipts: receiptProvider.receipts,
              ),

              // Receipt list
              Expanded(
                child: receiptProvider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : receiptProvider.receipts.isEmpty
                        ? EmptyState(
                            icon: Icons.receipt_long,
                            title: 'No Receipts Yet',
                            message: 'Start tracking your expenses by adding your first receipt.',
                            actionLabel: 'Add Receipt',
                            onAction: () => _navigateToAddReceipt(context),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: receiptProvider.receipts.length,
                            itemBuilder: (context, index) {
                              final receipt = receiptProvider.receipts[index];
                              return ReceiptListItem(
                                receipt: receipt,
                                onDelete: () => _confirmDeleteReceipt(context, receipt.id!),
                              );
                            },
                          ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _navigateToAddReceipt(context),
            icon: const Icon(Icons.add_a_photo),
            label: const Text('Add Receipt'),
          ),
        );
      },
    );
  }

  void _navigateToAddReceipt(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddReceiptScreen(tripId: widget.tripId),
      ),
    );
  }

  Future<void> _confirmDeleteReceipt(BuildContext context, int receiptId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Receipt'),
        content: const Text('Are you sure you want to delete this receipt?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<ReceiptProvider>().deleteReceipt(receiptId);
    }
  }
}
