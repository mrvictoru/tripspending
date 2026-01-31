import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tripspending/providers/trip_provider.dart';
import 'package:tripspending/providers/receipt_provider.dart';
import 'package:tripspending/services/export_service.dart';

/// Screen for exporting trip data
class ExportScreen extends StatefulWidget {
  final int tripId;

  const ExportScreen({super.key, required this.tripId});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  final _exportService = ExportService();
  bool _isExporting = false;
  String? _lastExportPath;

  @override
  Widget build(BuildContext context) {
    final trip = context.watch<TripProvider>().selectedTrip;
    final receipts = context.watch<ReceiptProvider>().receipts;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Data'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Trip info card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trip?.name ?? 'Trip',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${receipts.length} receipts • ${trip?.currency ?? 'USD'} ${receipts.fold<double>(0, (sum, r) => sum + r.totalAmount).toStringAsFixed(2)} total',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          Text(
            'Export Format',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),

          // Excel export
          _ExportOption(
            icon: Icons.table_chart,
            title: 'Excel (.xlsx)',
            subtitle: 'Includes summary sheet, receipts, and locations',
            isLoading: _isExporting,
            onTap: () => _exportToExcel(trip, receipts),
          ),
          const SizedBox(height: 12),

          // CSV export
          _ExportOption(
            icon: Icons.description,
            title: 'CSV (.csv)',
            subtitle: 'Simple spreadsheet format, compatible with most apps',
            isLoading: _isExporting,
            onTap: () => _exportToCSV(trip, receipts),
          ),
          const SizedBox(height: 24),

          // Share last export
          if (_lastExportPath != null) ...[
            Text(
              'Last Export',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.insert_drive_file),
                title: Text(_lastExportPath!.split('/').last),
                trailing: IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: () => _shareExport(),
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Export tips
          Card(
            color: Theme.of(context).colorScheme.surfaceVariant,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Export Tips',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '• Excel format includes charts and formatting\n'
                    '• CSV is best for importing into other apps\n'
                    '• Location data is included for receipts with GPS\n'
                    '• Files are saved to your Documents folder',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportToExcel(trip, receipts) async {
    if (trip == null) return;

    setState(() => _isExporting = true);

    try {
      final path = await _exportService.exportToExcel(trip, receipts);
      setState(() {
        _lastExportPath = path;
        _isExporting = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Excel file exported successfully!'),
            action: SnackBarAction(
              label: 'Share',
              onPressed: _shareExport,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isExporting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _exportToCSV(trip, receipts) async {
    if (trip == null) return;

    setState(() => _isExporting = true);

    try {
      final path = await _exportService.exportToCSV(trip, receipts);
      setState(() {
        _lastExportPath = path;
        _isExporting = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('CSV file exported successfully!'),
            action: SnackBarAction(
              label: 'Share',
              onPressed: _shareExport,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isExporting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _shareExport() async {
    if (_lastExportPath != null) {
      await _exportService.shareFile(_lastExportPath!);
    }
  }
}

class _ExportOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isLoading;
  final VoidCallback onTap;

  const _ExportOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, size: 32),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.chevron_right),
        onTap: isLoading ? null : onTap,
      ),
    );
  }
}
