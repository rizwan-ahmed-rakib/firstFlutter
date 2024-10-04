import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Expense {
  final String name;
  final double price;
  final String category;
  final Timestamp date;

  Expense({
    required this.name,
    required this.price,
    required this.category,
    required this.date,
  });

  // Convert a Expense into a Map.
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'category': category,
      'date': date,
    };
  }

  // Convert a Firestore Map into an Expense.
  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      name: map['name'],
      price: map['price'],
      category: map['category'],
      date: map['date'],
    );
  }
}

class PersonalExpensePage extends StatefulWidget {
  @override
  _PersonalExpensePageState createState() => _PersonalExpensePageState();
}

class _PersonalExpensePageState extends State<PersonalExpensePage> {
  final _formKey = GlobalKey<FormState>();
  String _expenseName = '';
  double _expensePrice = 0.0;
  String _selectedCategory = 'Uncategorized';
  List<Expense> _expense = [];
  List<Expense> _filteredExpense = [];
  String _searchQuery = '';

  // List to store categories
  List<String> _categories = ['Uncategorized'];

  // Firestore collection reference to 'users' collection, and 'expense' sub-collection
  final CollectionReference usersCollection = FirebaseFirestore.instance.collection('users');
  final String userId = "user.uid"; // Replace with actual user ID if necessary
  final CollectionReference expensesCollection = FirebaseFirestore.instance.collection('users').doc('USER_ID').collection('expense');

  @override
  void initState() {
    super.initState();
    _loadExpensesFromFirebase(); // Load expenses from Firestore
    _loadCategories(); // Load categories from SharedPreferences
  }

  // Function to load expenses from Firestore
  void _loadExpensesFromFirebase() async {
    QuerySnapshot querySnapshot = await expensesCollection.get();
    setState(() {
      _expense = querySnapshot.docs
          .map((doc) => Expense.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
      _filteredExpense = _expense; // Initialize filtered list
    });
  }

  // Function to calculate today's expenses
  double _calculateTodayExpense() {
    DateTime today = DateTime.now();
    return _filteredExpense
        .where((expense) =>
    expense.date.toDate().day == today.day &&
        expense.date.toDate().month == today.month &&
        expense.date.toDate().year == today.year)
        .fold(0.0, (sum, expense) => sum + expense.price);
  }

  // Function to calculate total expenses
  double _calculateTotalExpense() {
    return _filteredExpense.fold(0.0, (sum, expense) => sum + expense.price);
  }

  // Function to add an expense to Firestore (to users > expense sub-collection)
  void _addExpenseToFirebase() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final newExpense = Expense(
        name: _expenseName,
        price: _expensePrice,
        category: _selectedCategory,
        date: Timestamp.now(), // Current date and time
      );

      // Add expense to Firestore (inside user's 'expense' sub-collection)
      expensesCollection.add(newExpense.toMap()).then((_) {
        setState(() {
          _expense.add(newExpense);
          _filteredExpense = _expense;
        });

        _formKey.currentState!.reset(); // Clear form fields
      });
    }
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

  // Function to add a new category through a dialog
  void _showAddCategoryDialog() {
    String newCategory = '';
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('খরচের খাত/তালিকা লিখুনঃ'),
          content: TextField(
            onChanged: (value) {
              newCategory = value;
            },
            decoration: InputDecoration(hintText: "এখানে লিখুন"),
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
              child: Text('যুক্ত'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('বাতিল'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double totalExpense = _calculateTotalExpense();
    double todayExpense = _calculateTodayExpense();
    _filteredExpense.sort((a, b) => b.date.compareTo(a.date)); // Sort by date

    return Scaffold(
      appBar: AppBar(
        title: Text('খরচের হিসাব'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Show total and today's expense
            Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: Column(
                children: [
                  Text(
                    'মোট খরচ: ৳${totalExpense.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'আজকের খরচ: ৳${todayExpense.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 18, color: Colors.blue),
                  ),
                ],
              ),
            ),

            // Search bar
            TextField(
              decoration: InputDecoration(
                labelText: 'Search Expense',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                  _filteredExpense = _expense
                      .where((expense) =>
                  expense.name.toLowerCase().contains(_searchQuery) ||
                      expense.category.toLowerCase().contains(_searchQuery))
                      .toList();
                });
              },
            ),
            SizedBox(height: 20),

            // Expense form
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    decoration:
                    InputDecoration(labelText: 'খরচের বর্ণনা লিখুন'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'দয়া করে খরচের কারণটি লিখুন';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _expenseName = value!;
                    },
                  ),
                  TextFormField(
                    decoration:
                    InputDecoration(labelText: 'খরচের পরিমাণ(টাকা)'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || double.tryParse(value) == null) {
                        return 'দয়া করে খরচের পরিমাণ লিখুন';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _expensePrice = double.parse(value!);
                    },
                  ),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value!;
                      });
                    },
                    items: _categories.map<DropdownMenuItem<String>>((String category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    decoration: InputDecoration(
                        labelText: 'খরচের তালিকা নির্বাচন করুন'),
                  ),
                  SizedBox(height: 20),

                  // Add Expense button
                  ElevatedButton(
                    onPressed: _addExpenseToFirebase,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.blue,
                    ),
                    child: Text('খরচ যুক্ত করুন'),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),

            // Add new category button
            ElevatedButton(
              onPressed: _showAddCategoryDialog,
              child: Text('নতুন খরচের তালিকা যুক্ত করুন'),
            ),
            SizedBox(height: 20),

            // Expense list
            Expanded(
              child: _filteredExpense.isEmpty
                  ? Text('কোন খরচের তথ্য পাওয়া যায়নি।')
                  : ListView.builder(
                itemCount: _filteredExpense.length,
                itemBuilder: (context, index) {
                  final expense = _filteredExpense[index];
                  return Card(
                    elevation: 4,
                    child: ListTile(
                      title: Text(expense.name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              '৳${expense.price.toStringAsFixed(2)}, ${expense.category}'),
                          Text(
                            'তারিখ: ${DateFormat('yyyy-MM-dd – kk:mm').format(expense.date.toDate())}',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Edit Button
                          IconButton(
                            icon: Icon(Icons.edit, color: Colors.blue),
                            onPressed: () {
                              // Show update dialog
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  TextEditingController nameController =
                                  TextEditingController(
                                      text: expense.name);
                                  TextEditingController priceController =
                                  TextEditingController(
                                      text: expense.price.toString());
                                  TextEditingController
                                  categoryController =
                                  TextEditingController(
                                      text: expense.category);

                                  return AlertDialog(
                                    title: Text('Update Expense'),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        TextField(
                                          controller: nameController,
                                          decoration: InputDecoration(
                                              labelText: 'Name'),
                                        ),
                                        TextField(
                                          controller: priceController,
                                          decoration: InputDecoration(
                                              labelText: 'Price'),
                                          keyboardType:
                                          TextInputType.number,
                                        ),
                                        TextField(
                                          controller: categoryController,
                                          decoration: InputDecoration(
                                              labelText: 'Category'),
                                        ),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                          child: Text('Cancel')),
                                      TextButton(
                                        onPressed: () {
                                          // Update expense in Firestore
                                          expensesCollection
                                              .where('name',
                                              isEqualTo: expense.name)
                                              .where('price',
                                              isEqualTo:
                                              expense.price)
                                              .get()
                                              .then((snapshot) {
                                            snapshot.docs.first.reference
                                                .update({
                                              'name':
                                              nameController.text,
                                              'price': double.parse(
                                                  priceController.text),
                                              'category':
                                              categoryController.text,
                                            });

                                            setState(() {
                                              _expense[index] = Expense(
                                                name: nameController.text,
                                                price: double.parse(
                                                    priceController.text),
                                                category:
                                                categoryController
                                                    .text,
                                                date: expense.date,
                                              );
                                              _filteredExpense = List.from(
                                                  _expense); // Update UI
                                            });

                                            Navigator.of(context).pop();
                                          });
                                        },
                                        child: Text('Update'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              // কনফার্মেশন ডায়ালগ দেখানো হচ্ছে
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: Text('ডিলিট নিশ্চিত করুন'),
                                    content: Text('আপনি কি নিশ্চিতভাবে এটি ডিলিট করতে চান?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop(); // বাতিল করলে ডায়ালগ বন্ধ হবে
                                        },
                                        child: Text('বাতিল'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          // ডিলিট করার জন্য কোড
                                          expensesCollection
                                              .where('name', isEqualTo: expense.name)
                                              .where('price', isEqualTo: expense.price)
                                              .get()
                                              .then((snapshot) {
                                            snapshot.docs.first.reference.delete();
                                          });

                                          setState(() {
                                            _expense.removeAt(index);
                                            _filteredExpense = _expense;
                                          });

                                          Navigator.of(context).pop(); // ডিলিট করার পর ডায়ালগ বন্ধ
                                        },
                                        child: Text('ডিলিট'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),


                          // Delete Button
                          // IconButton(
                          //   icon: Icon(Icons.delete, color: Colors.red),
                          //   onPressed: () {
                          //     expensesCollection
                          //         .where('name', isEqualTo: expense.name)
                          //         .where('price',
                          //         isEqualTo: expense.price)
                          //         .get()
                          //         .then((snapshot) {
                          //       snapshot.docs.first.reference.delete(); // Delete from Firestore
                          //     });
                          //
                          //     setState(() {
                          //       _expense = List.from(_expense)
                          //         ..removeAt(
                          //             _expense.length - 1 - index); // Remove from UI
                          //       _filteredExpense = List.from(_expense);
                          //     });
                          //   },
                          // ),
                        ],
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