import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
    bool _isLoading = false;

    Future<void> _addItem() async {
        if (!_formKey.currentState!.validate()) return;

        setState(() => _isLoading = true);

        try {
            final user = FirebaseAuth.instance.currentUser;
            if (user == null) {
                throw Exception('User not logged in');
            }

            await FirebaseFirestore.instance.collection('items').add({
                'title': _titleController.text.trim(),
                'description': _descriptionController.text.trim(),
                'price': double.tryParse(_priceController.text) ?? 0.0,
                'userId': user.uid,
                'userEmail': user.email,
                'createdAt': FieldValue.serverTimestamp(),
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
            body: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                    key: _formKey,
                    child: Column(
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