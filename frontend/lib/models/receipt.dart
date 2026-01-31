import 'dart:convert';

/// Receipt model representing a spending receipt.
class Receipt {
  final int? id;
  final int tripId;
  final String? merchantName;
  final double totalAmount;
  final String currency;
  final String? category;
  final DateTime? purchaseDate;
  final List<ReceiptItem>? items;
  final String? rawText;
  final String? imagePath;
  final double? latitude;
  final double? longitude;
  final String? address;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Receipt({
    this.id,
    required this.tripId,
    this.merchantName,
    required this.totalAmount,
    this.currency = 'USD',
    this.category,
    this.purchaseDate,
    this.items,
    this.rawText,
    this.imagePath,
    this.latitude,
    this.longitude,
    this.address,
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Create Receipt from database map
  factory Receipt.fromMap(Map<String, dynamic> map) {
    List<ReceiptItem>? items;
    if (map['items'] != null) {
      final itemsJson = map['items'] is String
          ? jsonDecode(map['items'] as String)
          : map['items'];
      if (itemsJson is List) {
        items = itemsJson
            .map((item) => ReceiptItem.fromMap(item as Map<String, dynamic>))
            .toList();
      }
    }

    return Receipt(
      id: map['id'] as int?,
      tripId: map['trip_id'] as int,
      merchantName: map['merchant_name'] as String?,
      totalAmount: (map['total_amount'] as num).toDouble(),
      currency: map['currency'] as String? ?? 'USD',
      category: map['category'] as String?,
      purchaseDate: map['purchase_date'] != null
          ? DateTime.parse(map['purchase_date'] as String)
          : null,
      items: items,
      rawText: map['raw_text'] as String?,
      imagePath: map['image_path'] as String?,
      latitude:
          map['latitude'] != null ? (map['latitude'] as num).toDouble() : null,
      longitude: map['longitude'] != null
          ? (map['longitude'] as num).toDouble()
          : null,
      address: map['address'] as String?,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// Convert Receipt to database map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'trip_id': tripId,
      'merchant_name': merchantName,
      'total_amount': totalAmount,
      'currency': currency,
      'category': category,
      'purchase_date': purchaseDate?.toIso8601String(),
      'items': items != null ? jsonEncode(items!.map((i) => i.toMap()).toList()) : null,
      'raw_text': rawText,
      'image_path': imagePath,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  Receipt copyWith({
    int? id,
    int? tripId,
    String? merchantName,
    double? totalAmount,
    String? currency,
    String? category,
    DateTime? purchaseDate,
    List<ReceiptItem>? items,
    String? rawText,
    String? imagePath,
    double? latitude,
    double? longitude,
    String? address,
    String? notes,
  }) {
    return Receipt(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      merchantName: merchantName ?? this.merchantName,
      totalAmount: totalAmount ?? this.totalAmount,
      currency: currency ?? this.currency,
      category: category ?? this.category,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      items: items ?? this.items,
      rawText: rawText ?? this.rawText,
      imagePath: imagePath ?? this.imagePath,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'Receipt(id: $id, merchant: $merchantName, amount: $totalAmount $currency)';
  }
}

/// Receipt line item
class ReceiptItem {
  final String name;
  final double amount;
  final int quantity;

  ReceiptItem({
    required this.name,
    required this.amount,
    this.quantity = 1,
  });

  factory ReceiptItem.fromMap(Map<String, dynamic> map) {
    return ReceiptItem(
      name: map['name'] as String,
      amount: (map['amount'] as num).toDouble(),
      quantity: map['quantity'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'amount': amount,
      'quantity': quantity,
    };
  }
}
