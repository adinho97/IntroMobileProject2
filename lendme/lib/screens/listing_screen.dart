import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lendme/screens/add_item_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class ListingScreen extends StatefulWidget {
    const ListingScreen({super.key});

    @override
    State<ListingScreen> createState() => _ListingScreenState();
}

class _ListingScreenState extends State<ListingScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  String? _selectedFilterCategory;
  LatLng? _searchLocation;
  double _searchRadius = 5.0; // Default radius in kilometers
  bool _isLocationSearchActive = false;

  // List of predefined categories (matching the ones in add_item_screen)
  final List<String> _categories = [
    'Electronics',
    'Kitchen Appliances',
    'Garden Tools',
    'Cleaning Equipment',
    'DIY Tools',
    'Other',
  ];

  // Calculate distance between two points using the Haversine formula
  double _calculateDistance(LatLng point1, LatLng point2) {
    const Distance distance = Distance();
    return distance.as(LengthUnit.Kilometer, point1, point2);
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing out: $e')),
        );
      }
    }
  }

  void _showLocationDialog(BuildContext context, GeoPoint location) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          height: 300,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                'Item Location',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: LatLng(location.latitude, location.longitude),
                    initialZoom: 15,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.lendme',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(location.latitude, location.longitude),
                          width: 80,
                          height: 80,
                          child: const Icon(
                            Icons.location_pin,
                            color: Colors.red,
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLocationSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search by Location'),
        content: const Text('Location search coming soon!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _clearLocationSearch() {
    setState(() {
      _searchLocation = null;
      _isLocationSearchActive = false;
    });
  }

  Widget _buildItemCard(DocumentSnapshot doc, bool isMyListing) {
    final data = doc.data() as Map<String, dynamic>;
    final bool isMyItem = data['userId'] == currentUserId;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (data['imageUrl'] != null)
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: CachedNetworkImage(
                    imageUrl: data['imageUrl'],
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      height: 200,
                      color: Colors.grey[200],
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF00A86B),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 200,
                      color: Colors.grey[200],
                      child: const Icon(
                        Icons.error_outline,
                        color: Colors.grey,
                        size: 48,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: (data['isAvailable'] == true)
                          ? Colors.green.withOpacity(0.9)
                          : Colors.red.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          (data['isAvailable'] == true)
                              ? Icons.check_circle
                              : Icons.cancel,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          (data['isAvailable'] == true)
                              ? 'Available'
                              : 'Unavailable',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['title'] ?? 'No Title',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00A86B).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    data['category'] ?? 'Uncategorized',
                    style: const TextStyle(
                      color: Color(0xFF00A86B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  data['description'] ?? 'No Description',
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (data['location'] != null)
                      TextButton.icon(
                        onPressed: () => _showLocationDialog(
                          context,
                          data['location'] as GeoPoint,
                        ),
                        icon: const Icon(Icons.location_on),
                        label: const Text('View Location'),
                      ),
                    if (isMyListing)
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          try {
                            await FirebaseFirestore.instance
                                .collection('items')
                                .doc(doc.id)
                                .delete();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Item deleted successfully'),
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error deleting item: $e'),
                                ),
                              );
                            }
                          }
                        },
                      ),
                  ],
                ),
                if (!isMyItem && data['isAvailable'] == true) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          // Show confirmation dialog
                          final shouldReserve = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Reserve Item'),
                              content: const Text(
                                'Are you sure you want to reserve this item?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text(
                                    'Reserve',
                                    style: TextStyle(color: Color(0xFF00A86B)),
                                  ),
                                ),
                              ],
                            ),
                          );

                          if (shouldReserve == true) {
                            // Update the item's availability
                            await FirebaseFirestore.instance
                                .collection('items')
                                .doc(doc.id)
                                .update({
                              'isAvailable': false,
                              'reservedBy': currentUserId,
                              'reservedAt': FieldValue.serverTimestamp(),
                            });

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Item reserved successfully'),
                                ),
                              );
                            }
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error reserving item: $e'),
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.bookmark_add),
                      label: const Text('Reserve Item'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList(Stream<QuerySnapshot> stream, bool isMyListing) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF00A86B),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.inventory_2_outlined,
                  size: 80,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  isMyListing ? 'No items listed yet' : 'No items available yet',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isMyListing ? 'Start by adding your first item!' : 'Be the first to add an item!',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AddItemScreen()),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Item'),
                ),
              ],
            ),
          );
        }

        // Filter items based on selected category and location if not in My Listings tab
        final filteredDocs = isMyListing
            ? snapshot.data!.docs
            : snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final categoryMatch = _selectedFilterCategory == null ||
                    data['category'] == _selectedFilterCategory;

                if (!categoryMatch) return false;

                if (_isLocationSearchActive && _searchLocation != null) {
                  final itemLocation = data['location'] as GeoPoint;
                  final distance = _calculateDistance(
                    _searchLocation!,
                    LatLng(itemLocation.latitude, itemLocation.longitude),
                  );
                  return distance <= _searchRadius;
                }

                return true;
              }).toList();

        if (!isMyListing && filteredDocs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.filter_list,
                  size: 80,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                const Text(
                  'No items found',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isLocationSearchActive
                      ? 'Try adjusting your search criteria'
                      : 'Try selecting a different category',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_selectedFilterCategory != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _selectedFilterCategory = null;
                            });
                          },
                          icon: const Icon(Icons.clear_all),
                          label: const Text('Show All Categories'),
                        ),
                      ),
                    if (_isLocationSearchActive)
                      ElevatedButton.icon(
                        onPressed: _clearLocationSearch,
                        icon: const Icon(Icons.location_off),
                        label: const Text('Clear Location'),
                      ),
                  ],
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            if (!isMyListing) ...[
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedFilterCategory,
                            hint: const Text('Filter by Category'),
                            isExpanded: true,
                            icon: const Icon(Icons.filter_list),
                            items: [
                              const DropdownMenuItem<String>(
                                value: null,
                                child: Text('All Categories'),
                              ),
                              ..._categories.map((String category) {
                                return DropdownMenuItem<String>(
                                  value: category,
                                  child: Text(category),
                                );
                              }).toList(),
                            ],
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedFilterCategory = newValue;
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: _isLocationSearchActive ? const Color(0xFF00A86B) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _isLocationSearchActive ? const Color(0xFF00A86B) : Colors.grey[300]!,
                        ),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.location_on,
                          color: _isLocationSearchActive ? Colors.white : Colors.grey[600],
                        ),
                        onPressed: _showLocationSearchDialog,
                      ),
                    ),
                  ],
                ),
              ),
              if (_isLocationSearchActive && _searchLocation != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00A86B).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Color(0xFF00A86B),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Searching within ${_searchRadius.toStringAsFixed(1)} km of selected location',
                            style: const TextStyle(
                              color: Color(0xFF00A86B),
                              fontSize: 12,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Color(0xFF00A86B),
                            size: 16,
                          ),
                          onPressed: _clearLocationSearch,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredDocs.length,
                itemBuilder: (context, index) {
                  return _buildItemCard(filteredDocs[index], isMyListing);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'LendMe',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Available Items'),
            Tab(text: 'My Listings'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Available Items Tab
          _buildItemsList(
            FirebaseFirestore.instance
                .collection('items')
                .where('isAvailable', isEqualTo: true)
                .orderBy('createdAt', descending: true)
                .snapshots(),
            false,
          ),
          // My Listings Tab
          _buildItemsList(
            FirebaseFirestore.instance
                .collection('items')
                .where('userId', isEqualTo: currentUserId)
                .orderBy('createdAt', descending: true)
                .snapshots(),
            true,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddItemScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}