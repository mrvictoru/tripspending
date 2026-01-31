import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:tripspending/providers/trip_provider.dart';
import 'package:tripspending/providers/receipt_provider.dart';
import 'package:tripspending/models/category.dart';

/// Map screen showing receipt locations
class MapScreen extends StatefulWidget {
  final int tripId;

  const MapScreen({super.key, required this.tripId});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _buildMarkers();
    });
  }

  void _buildMarkers() {
    final receipts = context.read<ReceiptProvider>().receipts;
    final markers = <Marker>{};

    for (final receipt in receipts) {
      if (receipt.latitude != null && receipt.longitude != null) {
        final category = SpendingCategory.findByName(receipt.category ?? 'Other');
        
        markers.add(
          Marker(
            markerId: MarkerId('receipt_${receipt.id}'),
            position: LatLng(receipt.latitude!, receipt.longitude!),
            infoWindow: InfoWindow(
              title: receipt.merchantName ?? 'Unknown',
              snippet: '${receipt.currency} ${receipt.totalAmount.toStringAsFixed(2)}',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              _getCategoryHue(category?.color),
            ),
          ),
        );
      }
    }

    setState(() => _markers = markers);

    // Center map on markers if available
    if (markers.isNotEmpty && _mapController != null) {
      _fitMarkers();
    }
  }

  double _getCategoryHue(Color? color) {
    if (color == null) return BitmapDescriptor.hueRed;
    
    final hslColor = HSLColor.fromColor(color);
    return hslColor.hue;
  }

  void _fitMarkers() {
    if (_markers.isEmpty) return;

    final bounds = _markers.fold<LatLngBounds?>(
      null,
      (bounds, marker) {
        if (bounds == null) {
          return LatLngBounds(
            southwest: marker.position,
            northeast: marker.position,
          );
        }
        return LatLngBounds(
          southwest: LatLng(
            marker.position.latitude < bounds.southwest.latitude
                ? marker.position.latitude
                : bounds.southwest.latitude,
            marker.position.longitude < bounds.southwest.longitude
                ? marker.position.longitude
                : bounds.southwest.longitude,
          ),
          northeast: LatLng(
            marker.position.latitude > bounds.northeast.latitude
                ? marker.position.latitude
                : bounds.northeast.latitude,
            marker.position.longitude > bounds.northeast.longitude
                ? marker.position.longitude
                : bounds.northeast.longitude,
          ),
        );
      },
    );

    if (bounds != null) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 50),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final trip = context.watch<TripProvider>().selectedTrip;
    final receipts = context.watch<ReceiptProvider>().receipts;
    final locatedReceipts = receipts.where(
      (r) => r.latitude != null && r.longitude != null,
    ).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('${trip?.name ?? "Trip"} Map'),
      ),
      body: Column(
        children: [
          // Map
          Expanded(
            child: _markers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_off,
                          size: 64,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No location data',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Enable location when adding receipts to see them on the map',
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : GoogleMap(
                    initialCameraPosition: const CameraPosition(
                      target: LatLng(0, 0),
                      zoom: 2,
                    ),
                    markers: _markers,
                    onMapCreated: (controller) {
                      _mapController = controller;
                      _fitMarkers();
                    },
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    zoomControlsEnabled: true,
                  ),
          ),

          // Location list
          if (locatedReceipts.isNotEmpty)
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(8),
                itemCount: locatedReceipts.length,
                itemBuilder: (context, index) {
                  final receipt = locatedReceipts[index];
                  final category = SpendingCategory.findByName(
                    receipt.category ?? 'Other',
                  );

                  return Card(
                    child: InkWell(
                      onTap: () {
                        _mapController?.animateCamera(
                          CameraUpdate.newLatLng(
                            LatLng(receipt.latitude!, receipt.longitude!),
                          ),
                        );
                      },
                      child: Container(
                        width: 150,
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  category?.icon ?? Icons.receipt,
                                  size: 16,
                                  color: category?.color ?? Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    receipt.merchantName ?? 'Unknown',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${receipt.currency} ${receipt.totalAmount.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              receipt.address ?? 'Location captured',
                              style: Theme.of(context).textTheme.bodySmall,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
