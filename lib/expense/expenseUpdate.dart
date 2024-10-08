import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Expense {
  final String name;
  final double price;
  final Timestamp date;

  Expense({
    required this.name,
    required this.price,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'date': date,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      name: map['name'],
      price: map['price'],
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
  List<Expense> _expenses = [];
  List<Expense> _filteredExpenses = [];
  String _searchQuery = '';
  late CollectionReference expensesCollection;
  String _selectedPeriod = 'Monthly'; // Default period

  @override
  void initState() {
    super.initState();
    _loadCurrentUserExpenses();
  }

  // Load current user expenses
  void _loadCurrentUserExpenses() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      expensesCollection = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('expense');

      QuerySnapshot querySnapshot = await expensesCollection.get();
      setState(() {
        _expenses = querySnapshot.docs
            .map((doc) => Expense.fromMap(doc.data() as Map<String, dynamic>))
            .toList();
        _filteredExpenses = _expenses;
      });
    }
  }

  // Calculate today's expenses
  double _calculateTodayExpense() {
    DateTime today = DateTime.now();
    return _filteredExpenses
        .where((expense) =>
            expense.date.toDate().day == today.day &&
            expense.date.toDate().month == today.month &&
            expense.date.toDate().year == today.year)
        .fold(0.0, (sum, expense) => sum + expense.price);
  }

  // Calculate expenses based on selected period
  double _calculateExpenseByPeriod(String period) {
    DateTime now = DateTime.now();
    DateTime startDate;

    if (period == 'Weekly') {
      // startDate = now.subtract(Duration(days: now.weekday - 1));//from start monday English format

      // Calculate the start of the week as Saturday
      startDate = now.subtract(Duration(days: (now.weekday % 7 + 1) % 7));//from start Saturday Bengali format

    } else if (period == 'Monthly') {
      startDate = DateTime(now.year, now.month, 1);
    } else if (period == 'Yearly') {
      startDate = DateTime(now.year, 1, 1);
    } else {
      // startDate = DateTime(now.year, now.month, now.day); // Daily as default
      // If no period is selected, show all expenses
      _filteredExpenses = _expenses;
      return _filteredExpenses.fold(0.0, (sum, expense) => sum + expense.price);
    }



    return _filteredExpenses
        .where((expense) => expense.date.toDate().isAfter(startDate))
        .fold(0.0, (sum, expense) => sum + expense.price);

  }




  // Add expense to Firebase
  void _addExpenseToFirebase() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final newExpense = Expense(
        name: _expenseName,
        price: _expensePrice,
        date: Timestamp.now(),
      );

      expensesCollection.add(newExpense.toMap()).then((_) {
        setState(() {
          _expenses.add(newExpense);
          _filteredExpenses = _expenses;
        });

        _formKey.currentState!.reset();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double totalExpense = _calculateExpenseByPeriod(_selectedPeriod);
    double todayExpense = _calculateTodayExpense();

    _filteredExpenses.sort((a, b) => b.date.compareTo(a.date)); // Sort by date

    return Scaffold(
      appBar: AppBar(
        title: Text('খরচের হিসাব'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: Column(
                children: [
                  Text(
                    'মোট খরচ ($_selectedPeriod): ৳${totalExpense.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'আজকের খরচ: ৳${todayExpense.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 18, color: Colors.blue),
                  ),
                ],
              ),
            ),

            // Dropdown to select period
            DropdownButton<String>(
              value: _selectedPeriod,
              items: [
                DropdownMenuItem(
                  child: Text('All_Total'),
                  value: 'All_Total',
                ),
                DropdownMenuItem(
                  child: Text('Weekly'),
                  value: 'Weekly',
                ),
                DropdownMenuItem(
                  child: Text('Monthly'),
                  value: 'Monthly',
                ),
                DropdownMenuItem(
                  child: Text('Yearly'),
                  value: 'Yearly',
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedPeriod = value!;
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
                  SizedBox(height: 20),
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
                  _filteredExpenses = _expenses
                      .where((expense) =>
                          expense.name.toLowerCase().contains(_searchQuery))
                      .toList();
                });
              },
            ),

            SizedBox(height: 20),

            // Expense list
            Expanded(
              child: _filteredExpenses.isEmpty
                  ? Text('কোন খরচের তথ্য পাওয়া যায়নি।')
                  : ListView.builder(
                      itemCount: _filteredExpenses.length,
                      itemBuilder: (context, index) {
                        final expense = _filteredExpenses[index];
                        return Card(
                          elevation: 4,
                          child: ListTile(
                            title: Text('৳${expense.price.toStringAsFixed(2)}'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(expense.name),
                                Text(
                                  'তারিখ: ${DateFormat('EEEE, dd-MM-yyyy – hh:mm a', 'en_BD').format(expense.date.toDate().toLocal())}',
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
                                                text: expense.name);

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
                                                    'name': nameController.text,
                                                    'price': double.parse(
                                                        priceController.text),
                                                    'category':
                                                        categoryController.text,
                                                  });

                                                  setState(() {
                                                    _expenses[index] = Expense(
                                                      name: nameController.text,
                                                      price: double.parse(
                                                          priceController.text),
                                                      date: expense.date,
                                                    );
                                                    _filteredExpenses = List.from(
                                                        _expenses); // Update UI
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
                                          content: Text(
                                              'আপনি কি নিশ্চিতভাবে এটি ডিলিট করতে চান?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(context)
                                                    .pop(); // বাতিল করলে ডায়ালগ বন্ধ হবে
                                              },
                                              child: Text('বাতিল'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                // ডিলিট করার জন্য কোড
                                                expensesCollection
                                                    .where('name',
                                                        isEqualTo: expense.name)
                                                    .where('price',
                                                        isEqualTo:
                                                            expense.price)
                                                    .get()
                                                    .then((snapshot) {
                                                  snapshot.docs.first.reference
                                                      .delete();
                                                });

                                                setState(() {
                                                  _expenses.removeAt(index);
                                                  _filteredExpenses = _expenses;
                                                });

                                                Navigator.of(context)
                                                    .pop(); // ডিলিট করার পর ডায়ালগ বন্ধ
                                              },
                                              child: Text('ডিলিট'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                ),
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
