import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'product_page.dart'; // Import your ProductPage

class Product {
  final String name;
  final double price;
  final String category;
  int quantity;

  Product({
    required this.name,
    required this.price,
    required this.category,
    this.quantity = 1, // Default quantity is 1
  });

  // Convert a Product into a Map.
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'category': category,
      'quantity': quantity,
    };
  }

  // Convert a Map into a Product.
  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      name: map['name'],
      price: map['price'],
      category: map['category'],
      quantity: map['quantity'] ?? 1, // Default to 1 if not present
    );
  }
}

class StockManagementPage extends StatefulWidget {
  @override
  _StockManagementPageState createState() => _StockManagementPageState();
}

class _StockManagementPageState extends State<StockManagementPage> {
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  String _searchQuery = '';
  String _selectedCategory = 'All Categories'; // Default view

  @override
  void initState() {
    super.initState();
    _loadProducts(); // Load products from SharedPreferences
  }

  // Function to load products from SharedPreferences
  void _loadProducts() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? productJson = prefs.getString('products');
    if (productJson != null) {
      List<dynamic> productList = json.decode(productJson);
      setState(() {
        _products = productList.map((data) => Product.fromMap(data)).toList();
        _filteredProducts = _products; // Initialize filtered list
      });
    }
  }

  // Function to save products to SharedPreferences
  void _saveProducts() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String productJson =
        json.encode(_products.map((product) => product.toMap()).toList());
    await prefs.setString('products', productJson);
  }

  // Function to search products
  void _searchProducts(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
  }

  // Function to filter products by category
  void _filterByCategory(String category) {
    setState(() {
      _selectedCategory = category;
      if (category == 'All Categories') {
        _filteredProducts = _products;
      } else {
        _filteredProducts =
            _products.where((product) => product.category == category).toList();
      }
    });
  }

  // Function to edit product quantity
  void _updateQuantity(int index, String newQuantity) {
    int? qty = int.tryParse(newQuantity);
    if (qty != null && qty > 0) {
      setState(() {
        _products[index].quantity = qty;
        _saveProducts(); // Save changes to SharedPreferences
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filter products based on search query
    final displayedProducts = _filteredProducts.where((product) {
      return product.name.toLowerCase().contains(_searchQuery) ||
          product.category.toLowerCase().contains(_searchQuery);
    }).toList();

    // List of categories for dropdown
    List<String> categories = [
      'All Categories',
      ..._products.map((product) => product.category).toSet()
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Stock Management'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              // Navigate to Product Page
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProductPage()),
              ).then((_) {
                // Reload products after coming back from ProductPage
                _loadProducts();
              });
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search bar
            TextField(
              decoration: InputDecoration(
                labelText: 'Search Products',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _searchProducts,
            ),
            SizedBox(height: 20),

            // View by category dropdown
            DropdownButton<String>(
              value: _selectedCategory,
              onChanged: (value) {
                if (value != null) {
                  _filterByCategory(value);
                }
              },
              items:
                  categories.map<DropdownMenuItem<String>>((String category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              isExpanded: true,
            ),
            SizedBox(height: 20),

            // Product list
            Expanded(
              child: displayedProducts.isEmpty
                  ? Center(child: Text('No products found'))
                  : ListView.builder(
                      itemCount: displayedProducts.length,
                      itemBuilder: (context, index) {
                        final product = displayedProducts[index];
                        return ListTile(
                          title: Text(product.name),
                          subtitle: Text(
                              'Price: ৳${product.price.toStringAsFixed(2)} | Category: ${product.category}'),
                          trailing: SizedBox(
                            width: 100,
                            child: TextField(
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Qty',
                                border: OutlineInputBorder(),
                              ),
                              onSubmitted: (value) {
                                _updateQuantity(index, value);
                              },
                              controller: TextEditingController(
                                  text: product.quantity.toString()),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
