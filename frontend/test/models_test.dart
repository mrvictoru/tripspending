import 'package:flutter_test/flutter_test.dart';
import 'package:tripspending/models/trip.dart';
import 'package:tripspending/models/receipt.dart';
import 'package:tripspending/models/category.dart';

void main() {
  group('Trip Model', () {
    test('creates trip with required fields', () {
      final trip = Trip(name: 'Test Trip');
      
      expect(trip.name, 'Test Trip');
      expect(trip.currency, 'USD');
      expect(trip.id, isNull);
    });

    test('creates trip with all fields', () {
      final trip = Trip(
        id: 1,
        name: 'Japan 2024',
        description: 'Summer vacation',
        startDate: DateTime(2024, 7, 1),
        endDate: DateTime(2024, 7, 14),
        budget: 5000,
        currency: 'JPY',
      );

      expect(trip.id, 1);
      expect(trip.name, 'Japan 2024');
      expect(trip.description, 'Summer vacation');
      expect(trip.budget, 5000);
      expect(trip.currency, 'JPY');
    });

    test('converts trip to map', () {
      final trip = Trip(
        name: 'Test Trip',
        budget: 1000,
        currency: 'EUR',
      );

      final map = trip.toMap();

      expect(map['name'], 'Test Trip');
      expect(map['budget'], 1000);
      expect(map['currency'], 'EUR');
      expect(map.containsKey('created_at'), true);
    });

    test('creates trip from map', () {
      final now = DateTime.now().toIso8601String();
      final map = {
        'id': 1,
        'name': 'Map Trip',
        'description': 'From map',
        'budget': 500.0,
        'currency': 'GBP',
        'created_at': now,
        'updated_at': now,
      };

      final trip = Trip.fromMap(map);

      expect(trip.id, 1);
      expect(trip.name, 'Map Trip');
      expect(trip.description, 'From map');
      expect(trip.budget, 500.0);
      expect(trip.currency, 'GBP');
    });

    test('copyWith creates updated copy', () {
      final trip = Trip(name: 'Original', currency: 'USD');
      final updated = trip.copyWith(name: 'Updated', budget: 1000);

      expect(trip.name, 'Original');
      expect(updated.name, 'Updated');
      expect(updated.budget, 1000);
      expect(updated.currency, 'USD');
    });
  });

  group('Receipt Model', () {
    test('creates receipt with required fields', () {
      final receipt = Receipt(tripId: 1, totalAmount: 100.0);

      expect(receipt.tripId, 1);
      expect(receipt.totalAmount, 100.0);
      expect(receipt.currency, 'USD');
    });

    test('creates receipt with all fields', () {
      final receipt = Receipt(
        id: 1,
        tripId: 1,
        merchantName: 'Test Store',
        totalAmount: 50.0,
        currency: 'EUR',
        category: 'Shopping',
        purchaseDate: DateTime.now(),
        latitude: 35.6762,
        longitude: 139.6503,
        address: 'Tokyo, Japan',
      );

      expect(receipt.id, 1);
      expect(receipt.merchantName, 'Test Store');
      expect(receipt.category, 'Shopping');
      expect(receipt.latitude, 35.6762);
    });

    test('converts receipt to map', () {
      final receipt = Receipt(
        tripId: 1,
        merchantName: 'Coffee Shop',
        totalAmount: 5.50,
        category: 'Food & Dining',
      );

      final map = receipt.toMap();

      expect(map['trip_id'], 1);
      expect(map['merchant_name'], 'Coffee Shop');
      expect(map['total_amount'], 5.50);
      expect(map['category'], 'Food & Dining');
    });
  });

  group('ReceiptItem Model', () {
    test('creates receipt item', () {
      final item = ReceiptItem(name: 'Coffee', amount: 3.50);

      expect(item.name, 'Coffee');
      expect(item.amount, 3.50);
      expect(item.quantity, 1);
    });

    test('converts item to map', () {
      final item = ReceiptItem(name: 'Sandwich', amount: 8.0, quantity: 2);
      final map = item.toMap();

      expect(map['name'], 'Sandwich');
      expect(map['amount'], 8.0);
      expect(map['quantity'], 2);
    });
  });

  group('SpendingCategory', () {
    test('has default categories', () {
      expect(SpendingCategory.defaults.length, greaterThan(0));
      expect(SpendingCategory.defaults.first.name, 'Food & Dining');
    });

    test('finds category by name', () {
      final category = SpendingCategory.findByName('Transportation');

      expect(category, isNotNull);
      expect(category!.name, 'Transportation');
    });

    test('returns null for unknown category', () {
      final category = SpendingCategory.findByName('Unknown Category');
      expect(category, isNull);
    });

    test('suggests category from merchant name', () {
      expect(
        SpendingCategory.suggestCategory('Starbucks Coffee'),
        'Food & Dining',
      );
      expect(
        SpendingCategory.suggestCategory('Uber ride'),
        'Transportation',
      );
      expect(
        SpendingCategory.suggestCategory('Hilton Hotel'),
        'Accommodation',
      );
    });

    test('returns Other for unknown merchant', () {
      expect(
        SpendingCategory.suggestCategory('XYZ Unknown Store 123'),
        'Other',
      );
    });

    test('supports multilingual keywords', () {
      // Chinese restaurant
      expect(
        SpendingCategory.suggestCategory('餐厅'),
        'Food & Dining',
      );
      // Japanese convenience store
      expect(
        SpendingCategory.suggestCategory('コンビニ'),
        'Groceries',
      );
    });
  });
}
