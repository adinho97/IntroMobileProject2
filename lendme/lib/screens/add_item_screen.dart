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
    String _selectedCategory = 'Electronics';
    bool _isAvailable = true;
    bool _isLoading = false;
    File? _imageFile;
    LatLng? _selectedLocation;
    final _mapController = MapController();

    // List of predefined categories
    final List<String> _categories = [
        'Electronics',
        'Kitchen Appliances',
        'Garden Tools',
        'Cleaning Equipment',
        'DIY Tools',
        'Other',
    ];

    Future<void> _pickImage() async {
        final picker = ImagePicker();
        final pickedFile = await picker.pickImage(source: ImageSource.gallery);
        
        if (pickedFile != null) {
            setState(() {
                _imageFile = File(pickedFile.path);
            });
        }
    }

    Future<void> _addItem() async {
        if (!_formKey.currentState!.validate()) return;
        if (_imageFile == null) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Please select an image'),
                    backgroundColor: Colors.red,
                ),
            );
            return;
        }
        if (_selectedLocation == null) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Please select a location'),
                    backgroundColor: Colors.red,
                ),
            );
            return;
        }

        setState(() => _isLoading = true);

        try {
            // Upload image to Firebase Storage
            final storageRef = FirebaseStorage.instance.ref();
            final imageRef = storageRef.child(
                'items/${path.basename(_imageFile!.path)}',
            );
            await imageRef.putFile(_imageFile!);
            final imageUrl = await imageRef.getDownloadURL();

            // Add item to Firestore
            await FirebaseFirestore.instance.collection('items').add({
                'title': _titleController.text.trim(),
                'description': _descriptionController.text.trim(),
                'price': double.parse(_priceController.text),
                'imageUrl': imageUrl,
                'category': _selectedCategory,
                'isAvailable': _isAvailable,
                'location': GeoPoint(
                    _selectedLocation!.latitude,
                    _selectedLocation!.longitude,
                ),
                'userId': FirebaseAuth.instance.currentUser!.uid,
                'createdAt': FieldValue.serverTimestamp(),
            });

            if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Item added successfully'),
                        backgroundColor: Color(0xFF00A86B),
                    ),
                );
                Navigator.pop(context);
            }
        } catch (e) {
            if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('An error occurred'),
                        backgroundColor: Colors.red,
                    ),
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
                title: const Text(
                    'Add New Item',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                    ),
                ),
            ),
            body: Form(
                key: _formKey,
                child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                        const Text(
                            'Item Details',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                            ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                            'Fill in the details of the item you want to share',
                            style: TextStyle(
                                color: Colors.grey,
                            ),
                        ),
                        const SizedBox(height: 24),
                        GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                                height: 200,
                                decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: Colors.grey[300]!,
                                        width: 2,
                                        style: BorderStyle.solid,
                                    ),
                                ),
                                child: _imageFile == null
                                    ? Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                            const Icon(
                                                Icons.add_photo_alternate_outlined,
                                                size: 48,
                                                color: Colors.grey,
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                                'Add Item Photo',
                                                style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontWeight: FontWeight.w500,
                                                ),
                                            ),
                                        ],
                                    )
                                    : ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.file(
                                            _imageFile!,
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                        ),
                                    ),
                            ),
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                            controller: _titleController,
                            decoration: const InputDecoration(
                                labelText: 'Title',
                                hintText: 'Enter item title',
                                prefixIcon: Icon(Icons.title),
                            ),
                            textInputAction: TextInputAction.next,
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
                                hintText: 'Enter item description',
                                prefixIcon: Icon(Icons.description),
                                alignLabelWithHint: true,
                            ),
                            maxLines: 3,
                            textInputAction: TextInputAction.next,
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
                                hintText: 'Enter rental price',
                                prefixIcon: Icon(Icons.euro),
                            ),
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
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
                                prefixIcon: Icon(Icons.category),
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
                            title: const Text('Item Available'),
                            subtitle: const Text('Is this item currently available for lending?'),
                            value: _isAvailable,
                            activeColor: const Color(0xFF00A86B),
                            onChanged: (bool value) {
                                setState(() {
                                    _isAvailable = value;
                                });
                            },
                        ),
                        const SizedBox(height: 24),
                        const Text(
                            'Item Location',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                            ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                            'Select the location where the item is available',
                            style: TextStyle(
                                color: Colors.grey,
                            ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                            height: 300,
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: Colors.grey[300]!,
                                ),
                            ),
                            child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Stack(
                                    children: [
                                        FlutterMap(
                                            mapController: _mapController,
                                            options: MapOptions(
                                                initialCenter: const LatLng(51.2195, 4.4025),
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
                                                                width: 40,
                                                                height: 40,
                                                                child: const Icon(
                                                                    Icons.location_pin,
                                                                    color: Color(0xFF00A86B),
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
                                            child: Column(
                                                children: [
                                                    Container(
                                                        decoration: BoxDecoration(
                                                            color: Colors.white,
                                                            borderRadius: BorderRadius.circular(8),
                                                            boxShadow: [
                                                                BoxShadow(
                                                                    color: Colors.black.withOpacity(0.1),
                                                                    blurRadius: 8,
                                                                ),
                                                            ],
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
                                                            borderRadius: BorderRadius.circular(8),
                                                            boxShadow: [
                                                                BoxShadow(
                                                                    color: Colors.black.withOpacity(0.1),
                                                                    blurRadius: 8,
                                                                ),
                                                            ],
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
                                                bottom: 16,
                                                left: 16,
                                                right: 16,
                                                child: Container(
                                                    padding: const EdgeInsets.symmetric(
                                                        horizontal: 16,
                                                        vertical: 12,
                                                    ),
                                                    decoration: BoxDecoration(
                                                        color: Colors.white,
                                                        borderRadius: BorderRadius.circular(8),
                                                        boxShadow: [
                                                            BoxShadow(
                                                                color: Colors.black.withOpacity(0.1),
                                                                blurRadius: 8,
                                                            ),
                                                        ],
                                                    ),
                                                    child: Row(
                                                        children: [
                                                            const Icon(
                                                                Icons.location_on,
                                                                size: 20,
                                                                color: Color(0xFF00A86B),
                                                            ),
                                                            const SizedBox(width: 8),
                                                            Expanded(
                                                                child: Text(
                                                                    'Location: ${_selectedLocation!.latitude.toStringAsFixed(6)}, ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                                                                    style: const TextStyle(
                                                                        fontSize: 14,
                                                                        fontWeight: FontWeight.w500,
                                                                    ),
                                                                ),
                                                            ),
                                                        ],
                                                    ),
                                                ),
                                            ),
                                    ],
                                ),
                            ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                            onPressed: _isLoading ? null : _addItem,
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                )
                                : const Text('Add Item'),
                        ),
                        const SizedBox(height: 24),
                    ],
                ),
            ),
        );
    }
}