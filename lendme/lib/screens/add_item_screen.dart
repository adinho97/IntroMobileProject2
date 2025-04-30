import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

class AddItemScreen extends StatefulWidget {
    const AddItemScreen({super.key});

    @override
    State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
    final _formKey = GlobalKey<FormState>();
    final _titleController = TextEditingController();
    final _descriptionController = TextEditingController();
    final _priceController = TextEditingController();
    String _selectedCategory = 'Electronics'; // Default category
    bool _isAvailable = true; // Default availability
    bool _isLoading = false;
    File? _imageFile;
    LatLng? _selectedLocation;
    final _mapController = MapController();
    bool _isMapExpanded = false;

    // List of predefined categories
    final List<String> _categories = [
        'Electronics',
        'Kitchen Appliances',
        'Garden Tools',
        'Cleaning Equipment',
        'DIY Tools',
        'Other'
    ];

    Future<void> _pickImage() async {
        final ImagePicker picker = ImagePicker();
        final XFile? image = await picker.pickImage(source: ImageSource.gallery);
        
        if (image != null) {
            setState(() {
                _imageFile = File(image.path);
            });
        }
    }

    Future<String?> _uploadImage() async {
        if (_imageFile == null) return null;

        try {
            final fileName = '${DateTime.now().millisecondsSinceEpoch}${path.extension(_imageFile!.path)}';
            final ref = FirebaseStorage.instance.ref().child('item_images/$fileName');
            await ref.putFile(_imageFile!);
            return await ref.getDownloadURL();
        } catch (e) {
            print('Error uploading image: $e');
            return null;
        }
    }

    Future<void> _addItem() async {
        if (!_formKey.currentState!.validate()) return;
        if (_selectedLocation == null) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please select a location')),
            );
            return;
        }

        setState(() => _isLoading = true);

        try {
            final user = FirebaseAuth.instance.currentUser;
            if (user == null) {
                throw Exception('User not logged in');
            }

            // Upload image if selected
            String? imageUrl;
            if (_imageFile != null) {
                imageUrl = await _uploadImage();
            }

            await FirebaseFirestore.instance.collection('items').add({
                'title': _titleController.text.trim(),
                'description': _descriptionController.text.trim(),
                'price': double.tryParse(_priceController.text) ?? 0.0,
                'category': _selectedCategory,
                'isAvailable': _isAvailable,
                'userId': user.uid,
                'userEmail': user.email,
                'createdAt': FieldValue.serverTimestamp(),
                'location': GeoPoint(_selectedLocation!.latitude, _selectedLocation!.longitude),
                'imageUrl': imageUrl,
            });

            if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Item added successfully!')),
                );
                Navigator.pop(context);
            }
        } catch (e) {
            if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString()}')),
                );
            }
        } finally {
            if (mounted) {
                setState(() => _isLoading = false);
            }
        }
    }

    @override
    void dispose() {
        _titleController.dispose();
        _descriptionController.dispose();
        _priceController.dispose();
        super.dispose();
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(
                title: const Text('Add New Item'),
            ),
            body: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                    key: _formKey,
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            TextFormField(
                                controller: _titleController,
                                decoration: const InputDecoration(
                                    labelText: 'Title',
                                    border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                    if (value == null || value.isEmpty) {
                                        return 'Please enter a title';
                                    }
                                    return null;
                                },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                                controller: _descriptionController,
                                decoration: const InputDecoration(
                                    labelText: 'Description',
                                    border: OutlineInputBorder(),
                                ),
                                maxLines: 3,
                                validator: (value) {
                                    if (value == null || value.isEmpty) {
                                        return 'Please enter a description';
                                    }
                                    return null;
                                },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                                controller: _priceController,
                                decoration: const InputDecoration(
                                    labelText: 'Price per day (€)',
                                    border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                    if (value == null || value.isEmpty) {
                                        return 'Please enter a price';
                                    }
                                    if (double.tryParse(value) == null) {
                                        return 'Please enter a valid number';
                                    }
                                    return null;
                                },
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                                value: _selectedCategory,
                                decoration: const InputDecoration(
                                    labelText: 'Category',
                                    border: OutlineInputBorder(),
                                ),
                                items: _categories.map((String category) {
                                    return DropdownMenuItem<String>(
                                        value: category,
                                        child: Text(category),
                                    );
                                }).toList(),
                                onChanged: (String? newValue) {
                                    if (newValue != null) {
                                        setState(() {
                                            _selectedCategory = newValue;
                                        });
                                    }
                                },
                            ),
                            const SizedBox(height: 16),
                            SwitchListTile(
                                title: const Text('Available for Rent'),
                                value: _isAvailable,
                                onChanged: (bool value) {
                                    setState(() {
                                        _isAvailable = value;
                                    });
                                },
                            ),
                            const SizedBox(height: 16),
                            const Text(
                                'Add Photo',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                                onTap: _pickImage,
                                child: Container(
                                    height: 200,
                                    decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey),
                                        borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: _imageFile != null
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Image.file(
                                                _imageFile!,
                                                fit: BoxFit.cover,
                                                width: double.infinity,
                                            ),
                                        )
                                        : const Center(
                                            child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                    Icon(Icons.add_photo_alternate, size: 50),
                                                    SizedBox(height: 8),
                                                    Text('Tap to add photo'),
                                                ],
                                            ),
                                        ),
                                ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                                'Select Location',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                                onTap: () {
                                    setState(() {
                                        _isMapExpanded = !_isMapExpanded;
                                    });
                                },
                                child: Container(
                                    height: _isMapExpanded ? MediaQuery.of(context).size.height * 0.7 : 200,
                                    decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey),
                                        borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Stack(
                                            children: [
                                                FlutterMap(
                                                    mapController: _mapController,
                                                    options: MapOptions(
                                                        initialCenter: const LatLng(51.2195, 4.4025), // Ellermanstraat, Antwerpen
                                                        initialZoom: 15,
                                                        onTap: (tapPosition, point) {
                                                            setState(() {
                                                                _selectedLocation = point;
                                                            });
                                                        },
                                                    ),
                                                    children: [
                                                        TileLayer(
                                                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                                            userAgentPackageName: 'com.example.lendme',
                                                        ),
                                                        if (_selectedLocation != null)
                                                            MarkerLayer(
                                                                markers: [
                                                                    Marker(
                                                                        point: _selectedLocation!,
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
                                                Positioned(
                                                    top: 8,
                                                    right: 8,
                                                    child: Container(
                                                        decoration: BoxDecoration(
                                                            color: Colors.white,
                                                            borderRadius: BorderRadius.circular(4),
                                                        ),
                                                        child: IconButton(
                                                            icon: Icon(
                                                                _isMapExpanded ? Icons.fullscreen_exit : Icons.fullscreen,
                                                            ),
                                                            onPressed: () {
                                                                setState(() {
                                                                    _isMapExpanded = !_isMapExpanded;
                                                                });
                                                            },
                                                        ),
                                                    ),
                                                ),
                                                Positioned(
                                                    right: 8,
                                                    top: 80,
                                                    child: Column(
                                                        children: [
                                                            Container(
                                                                decoration: BoxDecoration(
                                                                    color: Colors.white,
                                                                    borderRadius: BorderRadius.circular(4),
                                                                ),
                                                                child: IconButton(
                                                                    icon: const Icon(Icons.add),
                                                                    onPressed: () {
                                                                        _mapController.move(
                                                                            _mapController.camera.center,
                                                                            _mapController.camera.zoom + 1,
                                                                        );
                                                                    },
                                                                ),
                                                            ),
                                                            const SizedBox(height: 8),
                                                            Container(
                                                                decoration: BoxDecoration(
                                                                    color: Colors.white,
                                                                    borderRadius: BorderRadius.circular(4),
                                                                ),
                                                                child: IconButton(
                                                                    icon: const Icon(Icons.remove),
                                                                    onPressed: () {
                                                                        _mapController.move(
                                                                            _mapController.camera.center,
                                                                            _mapController.camera.zoom - 1,
                                                                        );
                                                                    },
                                                                ),
                                                            ),
                                                        ],
                                                    ),
                                                ),
                                                if (_selectedLocation != null)
                                                    Positioned(
                                                        bottom: 8,
                                                        left: 8,
                                                        right: 8,
                                                        child: Container(
                                                            padding: const EdgeInsets.all(8),
                                                            decoration: BoxDecoration(
                                                                color: Colors.white.withOpacity(0.9),
                                                                borderRadius: BorderRadius.circular(8),
                                                            ),
                                                            child: Text(
                                                                'Selected location: ${_selectedLocation!.latitude.toStringAsFixed(6)}, ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                                                                style: const TextStyle(fontSize: 12),
                                                            ),
                                                        ),
                                                    ),
                                            ],
                                        ),
                                    ),
                                ),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                    onPressed: _isLoading ? null : _addItem,
                                    child: _isLoading
                                        ? const CircularProgressIndicator()
                                        : const Text('Add Item'),
                                ),
                            ),
                        ],
                    ),
                ),
            ),
        );
    }
}