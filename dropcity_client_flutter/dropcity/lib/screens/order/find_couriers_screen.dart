import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/matching_provider.dart';
import '../../providers/location_provider.dart';

class FindCouriersScreen extends ConsumerStatefulWidget {
  final String? orderId;

  const FindCouriersScreen({super.key, this.orderId});

  @override
  ConsumerState<FindCouriersScreen> createState() => _FindCouriersScreenState();
}

class _FindCouriersScreenState extends ConsumerState<FindCouriersScreen> {
  String _sortBy = 'distance'; // 'distance', 'rating'
  double _maxDistance = 10.0;

  void _searchCouriers() async {
    final location = ref.read(locationProvider).value;

    if (location == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to get current location')),
      );
      return;
    }

    await ref.read(matchingProvider.notifier).findAvailableCouriers(
      latitude: location.latitude,
      longitude: location.longitude,
      maxDistance: _maxDistance,
    );
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(_searchCouriers);
  }

  @override
  Widget build(BuildContext context) {
    final couriersAsync = _sortBy == 'rating'
        ? ref.watch(couriersByRatingProvider)
        : ref.watch(couriersByDistanceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Couriers'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search filters
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Distance slider
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Max Distance: ${_maxDistance.toStringAsFixed(1)} km'),
                    Slider(
                      value: _maxDistance,
                      min: 1,
                      max: 50,
                      onChanged: (value) {
                        setState(() => _maxDistance = value);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Sort button
                Row(
                  children: [
                    Expanded(
                      child: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                            value: 'distance',
                            label: Text('Distance'),
                            icon: Icon(Icons.location_on),
                          ),
                          ButtonSegment(
                            value: 'rating',
                            label: Text('Rating'),
                            icon: Icon(Icons.star),
                          ),
                        ],
                        selected: {_sortBy},
                        onSelectionChanged: (Set<String> newSelection) {
                          setState(() => _sortBy = newSelection.first);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Refresh button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _searchCouriers,
                    child: const Text('Search Couriers'),
                  ),
                ),
              ],
            ),
          ),
          // Couriers list
          Expanded(
            child: couriersAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error: ${error.toString()}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _searchCouriers,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (couriers) {
                if (couriers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.person_outline,
                            size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text(
                          'No couriers available',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Try increasing the distance range',
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _searchCouriers,
                          child: const Text('Search Again'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: couriers.length,
                  itemBuilder: (context, index) {
                    final courier = couriers[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        courier.name,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        courier.vehicleType.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: courier.isOnline
                                        ? Colors.green
                                        : Colors.grey,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    courier.isOnline ? 'Online' : 'Offline',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.star,
                                        color: Colors.amber, size: 20),
                                    const SizedBox(width: 4),
                                    Text(
                                      courier.rating.toStringAsFixed(1),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on,
                                        color: Colors.blue, size: 20),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${courier.distance.toStringAsFixed(1)} km',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                ElevatedButton(
                                  onPressed: courier.isOnline
                                      ? () async {
                                          try {
                                            final success = await ref
                                                .read(
                                                    matchingProvider.notifier)
                                                .matchOrderWithCourier(
                                                  widget.orderId ?? '',
                                                  courier.id,
                                                );

                                            if (!context.mounted) {
                                              return;
                                            }

                                            if (success) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Courier matched successfully',
                                                  ),
                                                ),
                                              );
                                              if ((widget.orderId ?? '').isNotEmpty) {
                                                context.go('/tracking/${widget.orderId}');
                                              }
                                            }
                                          } catch (e) {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'Failed to match: ${e.toString()}',
                                                  ),
                                                ),
                                              );
                                            }
                                          }
                                        }
                                      : null,
                                  child: const Text('Select'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}







