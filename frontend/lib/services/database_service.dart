import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:tripspending/models/trip.dart';
import 'package:tripspending/models/receipt.dart';

/// Local SQLite database service
class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('tripspending.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Create trips table
    await db.execute('''
      CREATE TABLE trips (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        start_date TEXT,
        end_date TEXT,
        budget REAL,
        currency TEXT DEFAULT 'USD',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Create receipts table
    await db.execute('''
      CREATE TABLE receipts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        trip_id INTEGER NOT NULL,
        merchant_name TEXT,
        total_amount REAL NOT NULL,
        currency TEXT DEFAULT 'USD',
        category TEXT,
        purchase_date TEXT,
        items TEXT,
        raw_text TEXT,
        image_path TEXT,
        latitude REAL,
        longitude REAL,
        address TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (trip_id) REFERENCES trips (id) ON DELETE CASCADE
      )
    ''');

    // Create indexes
    await db.execute('CREATE INDEX idx_receipts_trip_id ON receipts(trip_id)');
    await db.execute('CREATE INDEX idx_receipts_category ON receipts(category)');
    await db.execute('CREATE INDEX idx_receipts_purchase_date ON receipts(purchase_date)');
  }

  // Trip CRUD operations

  Future<Trip> createTrip(Trip trip) async {
    final db = await database;
    final id = await db.insert('trips', trip.toMap());
    return trip.copyWith(id: id);
  }

  Future<List<Trip>> getAllTrips() async {
    final db = await database;
    final maps = await db.query('trips', orderBy: 'created_at DESC');
    return maps.map((map) => Trip.fromMap(map)).toList();
  }

  Future<Trip?> getTrip(int id) async {
    final db = await database;
    final maps = await db.query('trips', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Trip.fromMap(maps.first);
  }

  Future<int> updateTrip(Trip trip) async {
    final db = await database;
    return await db.update(
      'trips',
      trip.toMap(),
      where: 'id = ?',
      whereArgs: [trip.id],
    );
  }

  Future<int> deleteTrip(int id) async {
    final db = await database;
    return await db.delete('trips', where: 'id = ?', whereArgs: [id]);
  }

  // Receipt CRUD operations

  Future<Receipt> createReceipt(Receipt receipt) async {
    final db = await database;
    final id = await db.insert('receipts', receipt.toMap());
    return receipt.copyWith(id: id);
  }

  Future<List<Receipt>> getReceiptsForTrip(int tripId) async {
    final db = await database;
    final maps = await db.query(
      'receipts',
      where: 'trip_id = ?',
      whereArgs: [tripId],
      orderBy: 'purchase_date DESC',
    );
    return maps.map((map) => Receipt.fromMap(map)).toList();
  }

  Future<Receipt?> getReceipt(int id) async {
    final db = await database;
    final maps = await db.query('receipts', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Receipt.fromMap(maps.first);
  }

  Future<int> updateReceipt(Receipt receipt) async {
    final db = await database;
    return await db.update(
      'receipts',
      receipt.toMap(),
      where: 'id = ?',
      whereArgs: [receipt.id],
    );
  }

  Future<int> deleteReceipt(int id) async {
    final db = await database;
    return await db.delete('receipts', where: 'id = ?', whereArgs: [id]);
  }

  // Statistics

  Future<double> getTotalSpentForTrip(int tripId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(total_amount) as total FROM receipts WHERE trip_id = ?',
      [tripId],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<int> getReceiptCountForTrip(int tripId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM receipts WHERE trip_id = ?',
      [tripId],
    );
    return (result.first['count'] as int?) ?? 0;
  }

  Future<Map<String, double>> getCategorySpendingForTrip(int tripId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT category, SUM(total_amount) as total 
      FROM receipts 
      WHERE trip_id = ? 
      GROUP BY category
    ''', [tripId]);

    final Map<String, double> categorySpending = {};
    for (final row in result) {
      final category = row['category'] as String? ?? 'Other';
      final total = (row['total'] as num?)?.toDouble() ?? 0.0;
      categorySpending[category] = total;
    }
    return categorySpending;
  }

  Future<Map<String, double>> getDailySpendingForTrip(int tripId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT DATE(purchase_date) as date, SUM(total_amount) as total 
      FROM receipts 
      WHERE trip_id = ? AND purchase_date IS NOT NULL
      GROUP BY DATE(purchase_date)
      ORDER BY date
    ''', [tripId]);

    final Map<String, double> dailySpending = {};
    for (final row in result) {
      final date = row['date'] as String? ?? '';
      final total = (row['total'] as num?)?.toDouble() ?? 0.0;
      if (date.isNotEmpty) {
        dailySpending[date] = total;
      }
    }
    return dailySpending;
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
