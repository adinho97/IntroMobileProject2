import 'package:flutter/material.dart';

class ListingScreen extends StatefulWidget {
    const ListingScreen({super.key});

    @override
    State<ListingScreen> createState() => _ListingScreenState();
}

class _ListingScreenState extends State<ListingScreen>{
    //list for devices
    List<Map<String, dynamic>> _items = [];

    @override
    Widget build(BuildContext context){
        return Scaffold(
            appBar: AppBar(
                title: const Text('Lendme - Devices'),
            ),
            body: _items.isEmpty
                ? const Center(child:Text('No devices added yet'))
                : ListView.builder(
                    itemCount: _items.length,
                    itemBuilder: (context, index){
                        final item = _items[index];
                        return ListTile(
                            leading: const Icon(Icons.devices),
                            title: Text(item['title']),
                            subtitle: Text('€${item['price']} / day'),
                        );
                    },
                ),
            floatingActionButton: FloatingActionButton(
                onPressed: (){
                    //adding items

                    setState((){
                        _items.add({
                            'title': 'Stofzuiger Dyson',
                            'price': 5,
                        });
                    });
                },
                child: const Icon(Icons.add),
            ),

        );
    }
 }