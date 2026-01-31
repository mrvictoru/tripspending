import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tripspending/providers/trip_provider.dart';
import 'package:tripspending/screens/trip_detail_screen.dart';
import 'package:tripspending/screens/create_trip_screen.dart';
import 'package:tripspending/screens/settings_screen.dart';
import 'package:tripspending/widgets/trip_card.dart';
import 'package:tripspending/widgets/empty_state.dart';

/// Home screen showing list of trips
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Load trips when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TripProvider>().loadTrips();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TripSpending'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: Consumer<TripProvider>(
        builder: (context, tripProvider, child) {
          if (tripProvider.isLoading && tripProvider.trips.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (tripProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    tripProvider.error!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => tripProvider.loadTrips(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (tripProvider.trips.isEmpty) {
            return EmptyState(
              icon: Icons.luggage,
              title: 'No Trips Yet',
              message: 'Start tracking your travel expenses by creating your first trip.',
              actionLabel: 'Create Trip',
              onAction: () => _navigateToCreateTrip(context),
            );
          }

          return RefreshIndicator(
            onRefresh: () => tripProvider.loadTrips(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: tripProvider.trips.length,
              itemBuilder: (context, index) {
                final trip = tripProvider.trips[index];
                return TripCard(
                  trip: trip,
                  onTap: () => _navigateToTripDetail(context, trip.id!),
                  onDelete: () => _confirmDeleteTrip(context, trip.id!),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToCreateTrip(context),
        icon: const Icon(Icons.add),
        label: const Text('New Trip'),
      ),
    );
  }

  void _navigateToCreateTrip(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateTripScreen()),
    );
  }

  void _navigateToTripDetail(BuildContext context, int tripId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TripDetailScreen(tripId: tripId)),
    );
  }

  Future<void> _confirmDeleteTrip(BuildContext context, int tripId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Trip'),
        content: const Text(
          'Are you sure you want to delete this trip? This will also delete all associated receipts.',
        ),
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
      await context.read<TripProvider>().deleteTrip(tripId);
    }
  }
}
