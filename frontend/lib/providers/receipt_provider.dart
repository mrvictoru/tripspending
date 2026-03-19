import 'package:flutter/foundation.dart';
import 'package:tripspending/models/receipt.dart';
import 'package:tripspending/services/database_service.dart';
import 'package:tripspending/services/ocr_service.dart';

/// Provider for managing receipt state
class ReceiptProvider with ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;
  final OCRService _ocrService = OCRService();

  List<Receipt> _receipts = [];
  bool _isLoading = false;
  bool _isProcessing = false;
  String? _error;

  List<Receipt> get receipts => _receipts;
  bool get isLoading => _isLoading;
  bool get isProcessing => _isProcessing;
  String? get error => _error;

  /// Load receipts for a specific trip
  Future<void> loadReceipts(int tripId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _receipts = await _db.getReceiptsForTrip(tripId);
    } catch (e) {
      _error = 'Failed to load receipts: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Process receipt image with OCR
  Future<OCRResult?> processReceiptImage(String imagePath) async {
    _isProcessing = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _ocrService.processReceipt(imagePath);
      return result;
    } catch (e) {
      _error = 'Failed to process receipt: $e';
      return null;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Create a new receipt
  Future<Receipt?> createReceipt(Receipt receipt) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final createdReceipt = await _db.createReceipt(receipt);
      _receipts.insert(0, createdReceipt);
      notifyListeners();
      return createdReceipt;
    } catch (e) {
      _error = 'Failed to create receipt: $e';
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
    }
  }

  /// Update an existing receipt
  Future<bool> updateReceipt(Receipt receipt) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _db.updateReceipt(receipt);
      final index = _receipts.indexWhere((r) => r.id == receipt.id);
      if (index >= 0) {
        _receipts[index] = receipt;
      }
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to update receipt: $e';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
    }
  }

  /// Delete a receipt
  Future<bool> deleteReceipt(int receiptId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _db.deleteReceipt(receiptId);
      _receipts.removeWhere((r) => r.id == receiptId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to delete receipt: $e';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
    }
  }

  /// Clear receipts
  void clearReceipts() {
    _receipts = [];
    notifyListeners();
  }

  /// Get receipts filtered by category
  List<Receipt> getReceiptsByCategory(String category) {
    return _receipts.where((r) => r.category == category).toList();
  }

  /// Get total amount for current receipts
  double get totalAmount {
    return _receipts.fold(0, (sum, r) => sum + r.totalAmount);
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }
}
