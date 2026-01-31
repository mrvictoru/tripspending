import 'package:flutter/foundation.dart';
import 'package:tripspending/models/trip.dart';
import 'package:tripspending/services/database_service.dart';

/// Provider for managing trip state
class TripProvider with ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;
  
  List<Trip> _trips = [];
  Trip? _selectedTrip;
  bool _isLoading = false;
  String? _error;

  List<Trip> get trips => _trips;
  Trip? get selectedTrip => _selectedTrip;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Load all trips from database
  Future<void> loadTrips() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _trips = await _db.getAllTrips();
    } catch (e) {
      _error = 'Failed to load trips: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create a new trip
  Future<Trip?> createTrip(Trip trip) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final createdTrip = await _db.createTrip(trip);
      _trips.insert(0, createdTrip);
      notifyListeners();
      return createdTrip;
    } catch (e) {
      _error = 'Failed to create trip: $e';
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
    }
  }

  /// Update an existing trip
  Future<bool> updateTrip(Trip trip) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _db.updateTrip(trip);
      final index = _trips.indexWhere((t) => t.id == trip.id);
      if (index >= 0) {
        _trips[index] = trip;
      }
      if (_selectedTrip?.id == trip.id) {
        _selectedTrip = trip;
      }
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to update trip: $e';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
    }
  }

  /// Delete a trip
  Future<bool> deleteTrip(int tripId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _db.deleteTrip(tripId);
      _trips.removeWhere((t) => t.id == tripId);
      if (_selectedTrip?.id == tripId) {
        _selectedTrip = null;
      }
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to delete trip: $e';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
    }
  }

  /// Select a trip
  Future<void> selectTrip(int tripId) async {
    _selectedTrip = await _db.getTrip(tripId);
    notifyListeners();
  }

  /// Clear selected trip
  void clearSelection() {
    _selectedTrip = null;
    notifyListeners();
  }

  /// Get total spent for a trip
  Future<double> getTotalSpent(int tripId) async {
    return await _db.getTotalSpentForTrip(tripId);
  }

  /// Get receipt count for a trip
  Future<int> getReceiptCount(int tripId) async {
    return await _db.getReceiptCountForTrip(tripId);
  }

  /// Get category spending breakdown for a trip
  Future<Map<String, double>> getCategorySpending(int tripId) async {
    return await _db.getCategorySpendingForTrip(tripId);
  }

  /// Get daily spending for a trip
  Future<Map<String, double>> getDailySpending(int tripId) async {
    return await _db.getDailySpendingForTrip(tripId);
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
