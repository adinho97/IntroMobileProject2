import 'package:flutter/material.dart';

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
            void _saveForm() {
            if (_formKey.currentState!.validate()) {
            _formKey.currentState!.save();
            Navigator.pop(context, {
                'title': _title,
                'price': _price,
            });
            }
        }
        
    }