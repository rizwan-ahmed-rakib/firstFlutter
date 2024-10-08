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

  // Convert a Expense into a Map.
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'date': date,
    };
  }

  // Convert a Firestore Map into an Expense.
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

  @override
  void initState() {
    super.initState();
    _loadCurrentUserExpenses();// Load the user's expense collection
  }

  // Function to load current user expenses from Firestore
  void _loadCurrentUserExpenses() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Accessing the user's expense collection
      expensesCollection = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid) // Use the logged-in user's ID
          .collection('expense');

      QuerySnapshot querySnapshot = await expensesCollection.get();
      setState(() {
        _expenses = querySnapshot.docs
            .map((doc) => Expense.fromMap(doc.data() as Map<String, dynamic>))
            .toList();
        _filteredExpenses = _expenses; // Initialize filtered list
      });
    }
  }

  // Function to calculate today's expenses
  double _calculateTodayExpense() {
    DateTime today = DateTime.now();
    return _filteredExpenses
        .where((expense) =>
            expense.date.toDate().day == today.day &&
            expense.date.toDate().month == today.month &&
            expense.date.toDate().year == today.year)
        .fold(0.0, (sum, expense) => sum + expense.price);
  }

  // Function to calculate total expenses
  double _calculateTotalExpense() {
    return _filteredExpenses.fold(0.0, (sum, expense) => sum + expense.price);
  }

  // Function to add an expense to Firestore
  void _addExpenseToFirebase() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final newExpense = Expense(
        name: _expenseName,
        price: _expensePrice,

        date: Timestamp.now(), // Current date and time
      );

      // Add expense to Firestore (inside user's 'expense' sub-collection)
      expensesCollection.add(newExpense.toMap()).then((_) {
        setState(() {
          _expenses.add(newExpense);
          _filteredExpenses = _expenses; // Update filtered expenses
        });

        _formKey.currentState!.reset(); // Clear form fields
      });
    }
  }

  // Function to load categories from SharedPreferences

  // Function to save categories to SharedPreferences



  @override
  Widget build(BuildContext context) {
    double totalExpense = _calculateTotalExpense();
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
                  expense.name.toLowerCase().contains(_searchQuery) ||
                      expense.name.toLowerCase().contains(_searchQuery)).toList();
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
                      title:Text('৳${expense.price.toStringAsFixed(2)}'),
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
                                              'name':
                                              nameController.text,
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
                                            _expenses.removeAt(index);
                                            _filteredExpenses = _expenses;
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
