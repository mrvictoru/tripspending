import 'package:flutter/material.dart';

/// Spending category model
class SpendingCategory {
  final String name;
  final IconData icon;
  final Color color;
  final List<String> keywords;

  const SpendingCategory({
    required this.name,
    required this.icon,
    required this.color,
    this.keywords = const [],
  });

  /// Default spending categories
  static const List<SpendingCategory> defaults = [
    SpendingCategory(
      name: 'Food & Dining',
      icon: Icons.restaurant,
      color: Color(0xFFFF6B6B),
      keywords: [
        'restaurant', 'cafe', 'coffee', 'food', 'dining', 'eat', 'meal',
        'breakfast', 'lunch', 'dinner', 'pizza', 'burger', 'sushi',
        'mcdonalds', 'starbucks', 'subway', 'kfc', 'bakery', 'bistro',
        '餐厅', '咖啡', '食品', 'レストラン', 'カフェ', '음식점'
      ],
    ),
    SpendingCategory(
      name: 'Transportation',
      icon: Icons.directions_car,
      color: Color(0xFF4ECDC4),
      keywords: [
        'uber', 'lyft', 'taxi', 'cab', 'transit', 'metro', 'bus',
        'train', 'subway', 'airline', 'flight', 'airport', 'parking',
        'gas', 'fuel', 'petrol', 'rental car', 'grab', 'gojek',
        '交通', '出租车', '地铁', 'タクシー', '電車', '교통'
      ],
    ),
    SpendingCategory(
      name: 'Accommodation',
      icon: Icons.hotel,
      color: Color(0xFF45B7D1),
      keywords: [
        'hotel', 'hostel', 'airbnb', 'motel', 'inn', 'resort',
        'lodging', 'accommodation', 'booking', 'stay', 'room',
        '酒店', '住宿', 'ホテル', '宿泊', '호텔', '숙박'
      ],
    ),
    SpendingCategory(
      name: 'Shopping',
      icon: Icons.shopping_bag,
      color: Color(0xFF96CEB4),
      keywords: [
        'shop', 'store', 'mall', 'market', 'retail', 'amazon',
        'walmart', 'target', 'clothing', 'fashion', 'apparel',
        'souvenirs', 'gifts', 'duty free', 'outlet',
        '购物', '商店', 'ショッピング', '쇼핑'
      ],
    ),
    SpendingCategory(
      name: 'Entertainment',
      icon: Icons.local_activity,
      color: Color(0xFFDDA0DD),
      keywords: [
        'museum', 'theater', 'theatre', 'cinema', 'movie', 'concert',
        'show', 'attraction', 'tour', 'ticket', 'park', 'zoo',
        'aquarium', 'entertainment', 'activity', 'experience',
        '娱乐', '博物馆', 'エンターテイメント', '엔터테인먼트'
      ],
    ),
    SpendingCategory(
      name: 'Groceries',
      icon: Icons.local_grocery_store,
      color: Color(0xFF77DD77),
      keywords: [
        'grocery', 'supermarket', 'market', 'convenience', '7-eleven',
        'minimart', 'family mart', 'lawson', 'whole foods', 'trader joe',
        '超市', '便利店', 'スーパー', 'コンビニ', '마트'
      ],
    ),
    SpendingCategory(
      name: 'Health & Pharmacy',
      icon: Icons.local_pharmacy,
      color: Color(0xFFFF6961),
      keywords: [
        'pharmacy', 'drugstore', 'medicine', 'health', 'hospital',
        'clinic', 'doctor', 'medical', 'cvs', 'walgreens',
        '药店', '医院', '薬局', '病院', '약국'
      ],
    ),
    SpendingCategory(
      name: 'Communication',
      icon: Icons.phone,
      color: Color(0xFF84B6F4),
      keywords: [
        'sim', 'phone', 'mobile', 'data', 'internet', 'wifi',
        'telecom', 'carrier', '通信', '電話', '통신'
      ],
    ),
    SpendingCategory(
      name: 'Other',
      icon: Icons.more_horiz,
      color: Color(0xFFC0C0C0),
      keywords: [],
    ),
  ];

  /// Find category by name
  static SpendingCategory? findByName(String name) {
    try {
      return defaults.firstWhere(
        (c) => c.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  /// Suggest category based on text
  static String suggestCategory(String text) {
    final lowerText = text.toLowerCase();
    
    for (final category in defaults) {
      for (final keyword in category.keywords) {
        if (lowerText.contains(keyword.toLowerCase())) {
          return category.name;
        }
      }
    }
    
    return 'Other';
  }
}
