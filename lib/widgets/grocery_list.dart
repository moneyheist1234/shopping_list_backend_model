import 'package:flutter/material.dart';
import 'package:handling_practice/data/categories.dart';
import '../models/category.dart';
import '../models/grocery_item.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'new_item.dart';

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  Future<List<GroceryItem>> _fetchItems() async {
    final url = Uri.https(
      'your-link',
      '/shopping-list.json',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final Map<String, dynamic> listData = json.decode(response.body);
        final List<GroceryItem> loadedItems = [];

        listData.forEach((key, value) {
          final categoryValue = value['category'];
          final category = categories.values.firstWhere(
            (catItem) => catItem.title == categoryValue,
            orElse: () => categories[Categories.vegetables]!,
          );

          loadedItems.add(
            GroceryItem(
              id: key,
              name: value['name'],
              quantity: value['quantity'],
              category: category,
            ),
          );
        });

        return loadedItems;
      } else {
        throw Exception(
            'Failed to load items. Status code: ${response.statusCode}');
      }
    } catch (error) {
      throw Exception('Error loading items: $error');
    }
  }

  void _addItem() async {
    final newItem = await Navigator.of(context).push<GroceryItem>(
      MaterialPageRoute(
        builder: (ctx) => const NewItem(),
      ),
    );
    if (newItem != null) {
      setState(() {}); // Trigger reload when new item is added
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Groceries'),
        actions: [
          IconButton(
            onPressed: _addItem,
            icon: const Icon(Icons.add),
          )
        ],
      ),
      body: FutureBuilder<List<GroceryItem>>(
        future: _fetchItems(),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                snapshot.error.toString(),
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final items = snapshot.data ?? [];

          if (items.isEmpty) {
            return const Center(child: Text('No items added yet.'));
          }

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (ctx, index) => Dismissible(
              key: ValueKey(items[index].id),
              onDismissed: (direction) {
                setState(() {
                  items.removeAt(index);
                });
              },
              child: ListTile(
                title: Text(items[index].name),
                leading: Container(
                  width: 24,
                  height: 24,
                  color: items[index].category.color,
                ),
                trailing: Text(items[index].quantity.toString()),
              ),
            ),
          );
        },
      ),
    );
  }
}
