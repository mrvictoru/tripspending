import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tripspending/models/trip.dart';
import 'package:tripspending/models/receipt.dart';
import 'package:intl/intl.dart';

/// Service for exporting trip data to various formats
class ExportService {
  /// Export trip data to Excel format
  Future<String> exportToExcel(Trip trip, List<Receipt> receipts) async {
    final excel = Excel.createExcel();
    
    // Remove default sheet
    excel.delete('Sheet1');
    
    // Create Summary sheet
    final summarySheet = excel['Trip Summary'];
    
    // Trip info
    summarySheet.appendRow([TextCellValue('Trip Information')]);
    summarySheet.appendRow([]);
    summarySheet.appendRow([TextCellValue('Trip Name'), TextCellValue(trip.name)]);
    summarySheet.appendRow([TextCellValue('Description'), TextCellValue(trip.description ?? '')]);
    summarySheet.appendRow([
      TextCellValue('Start Date'),
      TextCellValue(trip.startDate != null ? DateFormat('yyyy-MM-dd').format(trip.startDate!) : '')
    ]);
    summarySheet.appendRow([
      TextCellValue('End Date'),
      TextCellValue(trip.endDate != null ? DateFormat('yyyy-MM-dd').format(trip.endDate!) : '')
    ]);
    summarySheet.appendRow([
      TextCellValue('Budget'),
      TextCellValue('${trip.currency} ${trip.budget?.toStringAsFixed(2) ?? "N/A"}')
    ]);
    summarySheet.appendRow([TextCellValue('Currency'), TextCellValue(trip.currency)]);
    
    // Calculate totals
    final totalSpent = receipts.fold<double>(0, (sum, r) => sum + r.totalAmount);
    summarySheet.appendRow([]);
    summarySheet.appendRow([TextCellValue('Total Receipts'), IntCellValue(receipts.length)]);
    summarySheet.appendRow([
      TextCellValue('Total Spent'),
      TextCellValue('${trip.currency} ${totalSpent.toStringAsFixed(2)}')
    ]);
    
    if (trip.budget != null) {
      final remaining = trip.budget! - totalSpent;
      summarySheet.appendRow([
        TextCellValue('Remaining Budget'),
        TextCellValue('${trip.currency} ${remaining.toStringAsFixed(2)}')
      ]);
    }
    
    // Category breakdown
    summarySheet.appendRow([]);
    summarySheet.appendRow([TextCellValue('Spending by Category')]);
    summarySheet.appendRow([TextCellValue('Category'), TextCellValue('Amount')]);
    
    final categoryTotals = <String, double>{};
    for (final receipt in receipts) {
      final category = receipt.category ?? 'Other';
      categoryTotals[category] = (categoryTotals[category] ?? 0) + receipt.totalAmount;
    }
    
    for (final entry in categoryTotals.entries) {
      summarySheet.appendRow([
        TextCellValue(entry.key),
        TextCellValue('${trip.currency} ${entry.value.toStringAsFixed(2)}')
      ]);
    }
    
    // Create Receipts sheet
    final receiptsSheet = excel['Receipts'];
    
    // Header row
    receiptsSheet.appendRow([
      TextCellValue('Date'),
      TextCellValue('Merchant'),
      TextCellValue('Category'),
      TextCellValue('Amount'),
      TextCellValue('Currency'),
      TextCellValue('Address'),
      TextCellValue('Notes'),
    ]);
    
    // Data rows
    for (final receipt in receipts) {
      receiptsSheet.appendRow([
        TextCellValue(receipt.purchaseDate != null 
            ? DateFormat('yyyy-MM-dd HH:mm').format(receipt.purchaseDate!) 
            : ''),
        TextCellValue(receipt.merchantName ?? ''),
        TextCellValue(receipt.category ?? ''),
        DoubleCellValue(receipt.totalAmount),
        TextCellValue(receipt.currency),
        TextCellValue(receipt.address ?? ''),
        TextCellValue(receipt.notes ?? ''),
      ]);
    }
    
    // Create Locations sheet
    final locationsSheet = excel['Locations'];
    locationsSheet.appendRow([
      TextCellValue('Merchant'),
      TextCellValue('Address'),
      TextCellValue('Latitude'),
      TextCellValue('Longitude'),
      TextCellValue('Amount'),
    ]);
    
    for (final receipt in receipts) {
      if (receipt.latitude != null && receipt.longitude != null) {
        locationsSheet.appendRow([
          TextCellValue(receipt.merchantName ?? ''),
          TextCellValue(receipt.address ?? ''),
          DoubleCellValue(receipt.latitude!),
          DoubleCellValue(receipt.longitude!),
          DoubleCellValue(receipt.totalAmount),
        ]);
      }
    }
    
    // Save file
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'trip_${trip.name.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final filePath = '${directory.path}/$fileName';
    
    final fileBytes = excel.save();
    if (fileBytes != null) {
      final file = File(filePath);
      await file.writeAsBytes(fileBytes);
    }
    
    return filePath;
  }

  /// Export trip data to CSV format
  Future<String> exportToCSV(Trip trip, List<Receipt> receipts) async {
    final buffer = StringBuffer();
    
    // Header
    buffer.writeln('Date,Merchant,Category,Amount,Currency,Address,Latitude,Longitude,Notes');
    
    // Data rows
    for (final receipt in receipts) {
      buffer.writeln([
        receipt.purchaseDate != null 
            ? DateFormat('yyyy-MM-dd HH:mm').format(receipt.purchaseDate!) 
            : '',
        _escapeCSV(receipt.merchantName ?? ''),
        _escapeCSV(receipt.category ?? ''),
        receipt.totalAmount.toStringAsFixed(2),
        receipt.currency,
        _escapeCSV(receipt.address ?? ''),
        receipt.latitude?.toString() ?? '',
        receipt.longitude?.toString() ?? '',
        _escapeCSV(receipt.notes ?? ''),
      ].join(','));
    }
    
    // Save file
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'trip_${trip.name.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.csv';
    final filePath = '${directory.path}/$fileName';
    
    final file = File(filePath);
    await file.writeAsString(buffer.toString());
    
    return filePath;
  }

  /// Share exported file
  Future<void> shareFile(String filePath) async {
    await Share.shareXFiles([XFile(filePath)]);
  }

  String _escapeCSV(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}
