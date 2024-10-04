import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class Product {
  final String name;
  final double price;
  final String category;

  Product({required this.name, required this.price, required this.category});

  // Convert a Product into a Map.
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'category': category,
    };
  }

  // Convert a Map into a Product.
  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      name: map['name'],
      price: map['price'],
      category: map['category'],
    );
  }
}

class ProductPage extends StatefulWidget {
  @override
  _ProductPageState createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  final _formKey = GlobalKey<FormState>();
  String _productName = '';
  double _productPrice = 0.0;
  String _selectedCategory = 'Uncategorized';
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  String _searchQuery = '';

  // List to store categories
  List<String> _categories = ['Uncategorized'];

  @override
  void initState() {
    super.initState();
    _loadProducts(); // Load products from SharedPreferences
    _loadCategories(); // Load categories from SharedPreferences
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

  // Function to load categories from SharedPreferences
  void _loadCategories() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? categoriesJson = prefs.getString('categories');
    if (categoriesJson != null) {
      List<dynamic> categoryList = json.decode(categoriesJson);
      setState(() {
        _categories = categoryList.cast<String>(); // Load categories
      });
    }
  }

  // Function to save categories to SharedPreferences
  void _saveCategories() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String categoriesJson = json.encode(_categories);
    await prefs.setString('categories', categoriesJson);
  }

  // Function to add a product
  void _addProduct() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      setState(() {
        _products.add(Product(
          name: _productName,
          price: _productPrice,
          category: _selectedCategory,
        ));
        _filteredProducts = _products; // Reset filtered list
        _saveProducts(); // Save product list to SharedPreferences
      });

      _formKey.currentState!.reset(); // Clear form fields
    }
  }

  // Function to remove a product
  void _removeProduct(int index) {
    setState(() {
      _products.removeAt(index);
      _filteredProducts = _products; // Update filtered list
      _saveProducts(); // Save updated product list
    });
  }

  // Function to search products
  void _searchProducts(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      _filteredProducts = _products
          .where((product) =>
              product.name.toLowerCase().contains(_searchQuery) ||
              product.category.toLowerCase().contains(_searchQuery))
          .toList();
    });
  }

  // Function to add a new category through a dialog
  void _showAddCategoryDialog() {
    String newCategory = '';
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add New Category'),
          content: TextField(
            onChanged: (value) {
              newCategory = value;
            },
            decoration: InputDecoration(hintText: "Enter category name"),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (newCategory.isNotEmpty &&
                    !_categories.contains(newCategory)) {
                  setState(() {
                    _categories.add(newCategory);
                    _saveCategories(); // Save categories to SharedPreferences
                  });
                }
                Navigator.of(context).pop();
              },
              child: Text('Add'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
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
        title: Text('Product Management'),
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
              onChanged: (value) => _searchProducts(value),
            ),
            SizedBox(height: 20),

            // Product form
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Product Name'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the product name';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _productName = value!;
                    },
                  ),
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Product Price'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || double.tryParse(value) == null) {
                        return 'Please enter a valid price';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _productPrice = double.parse(value!);
                    },
                  ),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value!;
                      });
                    },
                    items: _categories
                        .map<DropdownMenuItem<String>>((String category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    decoration: InputDecoration(labelText: 'Select Category'),
                  ),
                  SizedBox(height: 20),

                  // Add product button
                  ElevatedButton(
                    onPressed: _addProduct,
                    child: Text('Add Product'),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),

            // Add new category button
            ElevatedButton(
              onPressed: _showAddCategoryDialog,
              child: Text('Add New Category'),
            ),
            SizedBox(height: 20),

            // Product list
            Expanded(
              child: _filteredProducts.isEmpty
                  ? Center(child: Text('No products found'))
                  : ListView.builder(
                      itemCount: _filteredProducts.length,
                      itemBuilder: (context, index) {
                        final product = _filteredProducts[index];
                        return ListTile(
                          title: Text(product.name),
                          subtitle: Text(
                              'Price: ৳${product.price.toStringAsFixed(2)} | Category: ${product.category}'),
                          trailing: IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              _removeProduct(index);
                            },
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
