import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddItemScreen extends StatefulWidget {
    const AddItemScreen({super.key});

    @override
    State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen>{
    final _formKey = GlobalKey<FormState>();

    String _title = '';
    double _price = 0.0;

    @override
    Widget build(BuildContext context){
        return Scaffold(
            appBar: AppBar(
                title: const Text('Add new device'),
            ),
            body: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                    key: _formKey, //validates form
                    child: Column(
                        children: [
                            TextFormField(
                                decoration: const InputDecoration(labelText: 'Title'),
                                onSaved: (value){
                                    _title = value?? '';
                                },
                                validator: (value){
                                    if(value == null || value.isEmpty){
                                        return 'Enter the Title';
                                    }
                                    return null;
                                },
                    
                            ),
                            TextFormField(
                                decoration: const InputDecoration(labelText: 'Price per day (€)'),
                                keyboardType: TextInputType.number,
                                onSaved: (value){
                                    _price = double.tryParse(value?? '0') ?? 0;
                                },
                                validator: (value){
                                    if(value == null || value.isEmpty){
                                        return "Add a price";
                                    }
                                    if (double.tryParse(value) == null){
                                        return 'Put in a valid number';
                                    }
                                    return null;
                                },
                            ),
                             const SizedBox(height: 20),
                              ElevatedButton(
                                 onPressed: _saveForm,
                                 child: const Text('Save'),
                              ),
                        ],
                    ),
                ),
            ),
        );
    }
    /*
            void _saveForm() {
            if (_formKey.currentState!.validate()) {
            _formKey.currentState!.save();
            Navigator.pop(context, {
                'title': _title,
                'price': _price,
            });
            }
        }
        */

        void _saveForm() async {
  if (_formKey.currentState!.validate()) {
    _formKey.currentState!.save();

    // Save the data to Firestore
    try {
      await FirebaseFirestore.instance.collection('devices').add({
        'title': _title,
        'price': _price,
        'createdAt': Timestamp.now(), // Optional: Save creation time
      });

      // After saving, navigate back to the previous screen (list screen)
      Navigator.pop(context);
    } catch (e) {
      // Handle any errors that might occur during the save process
      print('Error saving item: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save item: $e')),
      );
    }
  }
}

        
    }