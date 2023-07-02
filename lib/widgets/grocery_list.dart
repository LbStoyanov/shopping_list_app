import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:shopping_list/models/grocery_item.dart';
import 'package:shopping_list/widgets/new_item.dart';

import 'package:http/http.dart' as http;

import '../data/categories.dart';

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> _groceryItems = [];
  var _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  void _deleteItem(GroceryItem item) async {
    final index = _groceryItems.indexOf(item);
    setState(() {
      _groceryItems.remove(item);
    });

    final url = Uri.https(
      'shopping-list-f1e02-default-rtdb.firebaseio.com',
      'shopping-list/${item.id}.json',
    );

    final response = await http.delete(url);

    if (response.statusCode >= 400) {
      setState(() {
        _groceryItems.insert(index, item);
        //_error = 'Failed to delete data. Please try again later';
      });
    } else {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Grocery item deleted')),
      );
    }
  }

  void _loadItems() async {
    final url = Uri.https('shopping-list-f1e02-default-rtdb.firebaseio.com',
        'shopping-list.json');
    try {
      final response = await http.get(url);

      if (response.statusCode >= 400) {
        setState(() {
          _error = 'Failed to fetch data. Please try again later';
        });
      }

      if (response.body == 'null') {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final Map<String, dynamic> data = json.decode(response.body);
      final List<GroceryItem> loadedItems = [];

      for (var item in data.entries) {
        final category = categories.entries
            .firstWhere(
              (product) => product.value.title == item.value['category'],
            )
            .value;

        loadedItems.add(
          GroceryItem(
            id: item.key,
            name: item.value['name'],
            quantity: item.value['quantity'],
            category: category,
          ),
        );
      }

      setState(() {
        _groceryItems = loadedItems;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _error = 'Something went wrong. Please try again later';
      });
    }
  }

  void _addItem() async {
    final newItem = await Navigator.push<GroceryItem>(
      context,
      MaterialPageRoute(
        builder: (ctx) => const NewItem(),
      ),
    );

    if (newItem == null) {
      return;
    }

    setState(() {
      _groceryItems.add(newItem);
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget content = const Center(
      child: Text('No items added yet.',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
    );

    if (_isLoading) {
      content = const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_groceryItems.isNotEmpty) {
      content = ListView.builder(
        itemCount: _groceryItems.length,
        itemBuilder: (context, index) => Dismissible(
          key: Key(_groceryItems[index].id.toString()),
          direction: DismissDirection.horizontal,
          onDismissed: (direction) => _deleteItem(_groceryItems[index]),
          background: Container(
            color: const Color.fromARGB(255, 236, 19, 3),
            child: const Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Icon(Icons.delete, color: Colors.white),
              ),
            ),
          ),
          secondaryBackground: Container(
            color: const Color.fromARGB(255, 245, 23, 7),
            child: const Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Icon(Icons.delete, color: Colors.white),
              ),
            ),
          ),
          child: ListTile(
            title: Text(_groceryItems[index].name),
            leading: Container(
                width: 24,
                height: 24,
                color: _groceryItems[index].category.color),
            trailing: Text(_groceryItems[index].quantity.toString()),
          ),
        ),
      );
    }

    /*  if (_groceryItems.isEmpty) {
      content = const Center(
        child: Text(
          'No grocery items found!',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      );
    } */

    if (_error != null) {
      content = Center(
        child: Text(_error!),
      );
    }

    return Scaffold(
        appBar: AppBar(
          title: const Text('Your Groceries'),
          actions: [
            IconButton(onPressed: _addItem, icon: const Icon(Icons.add))
          ],
        ),
        body: content);
  }
}
