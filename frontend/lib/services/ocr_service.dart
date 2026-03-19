import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:tripspending/models/receipt.dart';
import 'package:tripspending/models/category.dart';

/// OCR Service for processing receipt images locally using ML Kit
class OCRService {
  final TextRecognizer _textRecognizer;

  OCRService()
      : _textRecognizer = TextRecognizer(
          script: TextRecognitionScript.latin,
        );

  /// Create OCR service with specific script/language support
  factory OCRService.withScript(TextRecognitionScript script) {
    return OCRService._withRecognizer(TextRecognizer(script: script));
  }

  OCRService._withRecognizer(this._textRecognizer);

  /// Process a receipt image and extract information
  Future<OCRResult> processReceipt(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final recognizedText = await _textRecognizer.processImage(inputImage);

    final rawText = recognizedText.text;
    
    // Parse the extracted text
    final merchantName = _extractMerchantName(recognizedText.blocks);
    final totalAmount = _extractTotalAmount(rawText);
    final currency = _extractCurrency(rawText);
    final date = _extractDate(rawText);
    final items = _extractItems(recognizedText.blocks);
    final suggestedCategory = SpendingCategory.suggestCategory(
      '${merchantName ?? ''} ${items.map((i) => i.name).join(' ')}',
    );

    return OCRResult(
      rawText: rawText,
      merchantName: merchantName,
      totalAmount: totalAmount,
      currency: currency,
      date: date,
      items: items,
      suggestedCategory: suggestedCategory,
    );
  }

  String? _extractMerchantName(List<TextBlock> blocks) {
    // Usually the first few lines contain the merchant name
    for (int i = 0; i < blocks.length && i < 3; i++) {
      final text = blocks[i].text.trim();
      // Skip date-like patterns and very short strings
      if (text.length > 3 && !_isDatePattern(text) && !_isAmountPattern(text)) {
        return text;
      }
    }
    return null;
  }

  double? _extractTotalAmount(String text) {
    // Common total patterns
    final patterns = [
      RegExp(r'(?:total|grand total|amount due|balance due|sum)[:\s]*[\$€£¥₩]?\s*([\d,]+\.?\d*)', caseSensitive: false),
      RegExp(r'(?:total|subtotal)[:\s]*[\$€£¥₩]?\s*([\d,]+\.?\d*)', caseSensitive: false),
      RegExp(r'[\$€£¥₩]\s*([\d,]+\.?\d*)\s*(?:total)?', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        try {
          final amountStr = match.group(1)?.replaceAll(',', '') ?? '';
          return double.tryParse(amountStr);
        } catch (_) {
          continue;
        }
      }
    }

    // Fallback: find the largest number (likely the total)
    final numberPattern = RegExp(r'[\d,]+\.\d{2}');
    final matches = numberPattern.allMatches(text);
    double? maxAmount;
    
    for (final match in matches) {
      final amount = double.tryParse(match.group(0)?.replaceAll(',', '') ?? '');
      if (amount != null && (maxAmount == null || amount > maxAmount)) {
        maxAmount = amount;
      }
    }

    return maxAmount;
  }

  String? _extractCurrency(String text) {
    if (text.contains('\$')) return 'USD';
    if (text.contains('€')) return 'EUR';
    if (text.contains('£')) return 'GBP';
    if (text.contains('¥')) return 'JPY';
    if (text.contains('₩')) return 'KRW';
    if (text.contains('₹')) return 'INR';
    return null;
  }

  DateTime? _extractDate(String text) {
    final patterns = [
      // MM/DD/YYYY or DD/MM/YYYY
      RegExp(r'(\d{1,2})[/\-\.](\d{1,2})[/\-\.](\d{2,4})'),
      // YYYY/MM/DD
      RegExp(r'(\d{4})[/\-\.](\d{1,2})[/\-\.](\d{1,2})'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        try {
          final groups = [match.group(1), match.group(2), match.group(3)]
              .whereType<String>()
              .map((s) => int.parse(s))
              .toList();

          if (groups.length == 3) {
            // Try to determine date format
            if (groups[0] > 31) {
              // YYYY/MM/DD
              return DateTime(groups[0], groups[1], groups[2]);
            } else if (groups[2] > 31 || groups[2] < 100) {
              // MM/DD/YY or DD/MM/YY - assume MM/DD/YYYY
              final year = groups[2] < 100 ? 2000 + groups[2] : groups[2];
              return DateTime(year, groups[0], groups[1]);
            }
          }
        } catch (_) {
          continue;
        }
      }
    }

    return null;
  }

  List<ReceiptItem> _extractItems(List<TextBlock> blocks) {
    final items = <ReceiptItem>[];
    final itemPattern = RegExp(r'^(.+?)\s+([\d,]+\.?\d*)$');

    for (final block in blocks) {
      for (final line in block.lines) {
        final text = line.text.trim();
        
        // Skip total/subtotal lines
        if (_isTotalLine(text)) continue;
        
        final match = itemPattern.firstMatch(text);
        if (match != null) {
          final name = match.group(1)?.trim() ?? '';
          final amountStr = match.group(2)?.replaceAll(',', '') ?? '';
          final amount = double.tryParse(amountStr);

          if (name.isNotEmpty && amount != null && amount > 0 && amount < 10000) {
            items.add(ReceiptItem(name: name, amount: amount));
          }
        }
      }
    }

    return items;
  }

  bool _isDatePattern(String text) {
    return RegExp(r'^\d{1,2}[/\-\.]\d{1,2}[/\-\.]\d{2,4}$').hasMatch(text);
  }

  bool _isAmountPattern(String text) {
    return RegExp(r'^[\$€£¥₩]?\s*[\d,]+\.?\d*$').hasMatch(text);
  }

  bool _isTotalLine(String text) {
    final lowerText = text.toLowerCase();
    return lowerText.contains('total') ||
        lowerText.contains('subtotal') ||
        lowerText.contains('tax') ||
        lowerText.contains('cash') ||
        lowerText.contains('change') ||
        lowerText.contains('card');
  }

  void dispose() {
    _textRecognizer.close();
  }
}

/// Result of OCR processing
class OCRResult {
  final String rawText;
  final String? merchantName;
  final double? totalAmount;
  final String? currency;
  final DateTime? date;
  final List<ReceiptItem> items;
  final String suggestedCategory;

  OCRResult({
    required this.rawText,
    this.merchantName,
    this.totalAmount,
    this.currency,
    this.date,
    this.items = const [],
    this.suggestedCategory = 'Other',
  });
}
