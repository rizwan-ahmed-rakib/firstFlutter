import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class Expense {
  final String name;
  final double price;
  final Timestamp date;
  final bool isCashboxChecked;

  Expense({
    required this.name,
    required this.price,
    required this.date,
    // required this.isCashboxChecked,
    this.isCashboxChecked = false, // ডিফল্ট false
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'date': date,
      'isCashboxChecked': isCashboxChecked,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      name: map['name'],
      price: map['price'],
      date: map['date'],
      isCashboxChecked: map['isCashboxChecked'] ?? false,
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
  bool _isCashboxChecked = false;
  List<Expense> _expenses = [];
  List<Expense> _filteredExpenses = [];
  String _searchQuery = '';
  late CollectionReference expensesCollection;
  late CollectionReference cashboxCollection;
  String _selectedPeriod = 'Monthly';

  var todayExpense;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserExpenses();
  }

  void _loadCurrentUserExpenses() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      expensesCollection = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('expense');

      cashboxCollection = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('cashbox');

      QuerySnapshot querySnapshot = await expensesCollection.get();
      setState(() {
        _expenses = querySnapshot.docs
            .map((doc) => Expense.fromMap(doc.data() as Map<String, dynamic>))
            .toList();
        _filteredExpenses = _expenses;
      });
    }
  }

  void _addExpenseToFirebase() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final newExpense = Expense(
        name: _expenseName,
        price: _expensePrice,
        date: Timestamp.now(),
        isCashboxChecked: _isCashboxChecked,
      );

      expensesCollection.add(newExpense.toMap()).then((_) {
        setState(() {
          _expenses.add(newExpense);
          _filteredExpenses = _expenses;
        });

        // যদি চেকবক্স টিক করা থাকে, তাহলে *cashbox* এ খরচ যুক্ত করা হবে
        if (_isCashboxChecked) {
          cashboxCollection.add({
            'amount': -_expensePrice,
            'reason': 'খরচ: $_expenseName',
            'time': Timestamp.now(),
          });
        }

        _formKey.currentState!.reset();
        _isCashboxChecked = false;
      });
    }
  }

  double _calculateTodayExpense() {
    DateTime today = DateTime.now();
    return _filteredExpenses
        .where((expense) =>
    expense.date.toDate().day == today.day &&
        expense.date.toDate().month == today.month &&
        expense.date.toDate().year == today.year)
        .fold(0.0, (sum, expense) => sum + expense.price);
  }

  double _calculateExpenseByPeriod(String period) {
    DateTime now = DateTime.now();
    DateTime startDate;

    if (period == 'Weekly') {
      startDate = now.subtract(Duration(days: now.weekday - 1));
    } else if (period == 'Monthly') {
      startDate = DateTime(now.year, now.month, 1);
    } else if (period == 'Yearly') {
      startDate = DateTime(now.year, 1, 1);
    } else {
      return _filteredExpenses.fold(0.0, (sum, expense) => sum + expense.price);
    }

    return _filteredExpenses
        .where((expense) => expense.date.toDate().isAfter(startDate))
        .fold(0.0, (sum, expense) => sum + expense.price);
  }

  void _updateExpense(Expense oldExpense, Expense updatedExpense, String s) {
    if (updatedExpense.isCashboxChecked) {
      double difference = updatedExpense.price - oldExpense.price;
      if (difference != 0) {
        cashboxCollection.add({
          'amount': -difference,
          'reason': 'আপডেট করা খরচ: ${updatedExpense.name}',
          'time': Timestamp.now(),
        });
      }
    }
  }

  void _deleteExpense(Expense expense) {
    if (expense.isCashboxChecked) {
      cashboxCollection.add({
        'amount': expense.price,
        'reason': 'ডিলিট করা খরচ: ${expense.name}',
        'time': Timestamp.now(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double totalExpense = _calculateExpenseByPeriod(_selectedPeriod);
    double todayExpense = _calculateTodayExpense();

    _filteredExpenses.sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      appBar: AppBar(
        title: Text('ব্যক্তিগত খরচের হিসাব'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
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
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'খরচের নাম',
                      border: OutlineInputBorder(),
                      fillColor: Colors.white,
                      filled: true,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'খরচের নাম লিখুন';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _expenseName = value!;
                    },
                  ),
                  SizedBox(height: 10),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'খরচের পরিমাণ (টাকা)',
                      border: OutlineInputBorder(),
                      fillColor: Colors.white,
                      filled: true,
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || double.tryParse(value) == null) {
                        return 'খরচের পরিমাণ লিখুন';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _expensePrice = double.parse(value!);
                    },
                  ),
                  CheckboxListTile(
                    title: Text('ক্যাশবক্সে অন্তর্ভুক্ত করুন'),
                    value: _isCashboxChecked,
                    onChanged: (value) {
                      setState(() {
                        _isCashboxChecked = value!;
                      });
                    },
                  ),
                  ElevatedButton(
                    onPressed: _addExpenseToFirebase,
                    child: Text('খরচ যোগ করুন'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal, // Primary color
                      foregroundColor: Colors.white, // Text color
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
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
            ////////////
            Expanded(
              child: _filteredExpenses.isEmpty
                  ? Center(child: Text('কোন খরচের তথ্য পাওয়া যায়নি।'))
                  : ListView.builder(
                itemCount: _filteredExpenses.length,
                itemBuilder: (context, index) {
                  final expense = _filteredExpenses[index];
                  return Card(
                    elevation: 4,
                    color: expense.isCashboxChecked ? Colors.green[100] : Colors.white,
                    child: ListTile(
                      title: Text('৳${expense.price.toStringAsFixed(2)}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(expense.name),
                          Text(
                            'তারিখ: ${DateFormat('EEEE, dd-MM-yyyy – hh:mm a', 'en_BD').format(expense.date.toDate())}',
                            style: TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit, color: Colors.blue),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  TextEditingController nameController = TextEditingController(text: expense.name);
                                  TextEditingController priceController = TextEditingController(text: expense.price.toString());
                                  bool tempCashBox = expense.isCashboxChecked;

                                  return StatefulBuilder(
                                    builder: (context, setState) {
                                      return AlertDialog(
                                        title: Text('Update Expense'),
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            TextField(
                                              controller: nameController,
                                              decoration: InputDecoration(labelText: 'Name'),
                                            ),
                                            TextField(
                                              controller: priceController,
                                              decoration: InputDecoration(labelText: 'Price'),
                                              keyboardType: TextInputType.number,
                                            ),
                                            Row(
                                              children: [
                                                Checkbox(
                                                  value: tempCashBox,
                                                  onChanged: (value) {
                                                    setState(() {
                                                      tempCashBox = value!;
                                                    });
                                                  },
                                                ),
                                                Text('Cashbox-এ অন্তর্ভুক্ত করুন'),
                                              ],
                                            ),
                                          ],
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                            child: Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () async {
                                              double newPrice = double.parse(priceController.text);
                                              double priceDifference = newPrice - expense.price;

                                              // Update Firestore
                                              QuerySnapshot snapshot = await expensesCollection
                                                  .where('name', isEqualTo: expense.name)
                                                  .where('price', isEqualTo: expense.price)
                                                  .get();

                                              if (snapshot.docs.isNotEmpty) {
                                                var docRef = snapshot.docs.first.reference;

                                                await docRef.update({
                                                  'name': nameController.text,
                                                  'price': newPrice,
                                                  'cashBox': tempCashBox,
                                                });

                                                // Cashbox logic
                                                if (tempCashBox && !expense.isCashboxChecked) {
                                                  cashboxCollection.add({
                                                    'amount': -newPrice,
                                                    'reason': 'খরচ আপডেট: ${nameController.text}',
                                                    'time': Timestamp.now(),
                                                  });
                                                } else if (!tempCashBox && expense.isCashboxChecked) {
                                                  cashboxCollection.add({
                                                    'amount': expense.price,
                                                    'reason': 'খরচ ডিলিট: ${expense.name}',
                                                    'time': Timestamp.now(),
                                                  });
                                                } else if (tempCashBox && expense.isCashboxChecked) {
                                                  cashboxCollection.add({
                                                    'amount': -priceDifference,
                                                    'reason': 'খরচ আপডেট: ${expense.name}',
                                                    'time': Timestamp.now(),
                                                  });
                                                }

                                                setState(() {
                                                  _expenses[index] = Expense(
                                                    name: nameController.text,
                                                    price: newPrice,
                                                    date: expense.date,
                                                    isCashboxChecked: tempCashBox,
                                                  );
                                                  _filteredExpenses = List.from(_expenses);
                                                });

                                                Navigator.of(context).pop();
                                              }
                                            },
                                            child: Text('Update'),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                              );
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: Text('ডিলিট নিশ্চিত করুন'),
                                    content: Text('আপনি কি নিশ্চিতভাবে এটি ডিলিট করতে চান?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: Text('বাতিল'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          expensesCollection
                                              .where('name', isEqualTo: expense.name)
                                              .where('price', isEqualTo: expense.price)
                                              .get()
                                              .then((snapshot) {
                                            snapshot.docs.first.reference.delete();

                                            if (expense.isCashboxChecked) {
                                              cashboxCollection.add({
                                                'amount': expense.price,
                                                'reason': 'খরচ ডিলিট: ${expense.name}',
                                                'time': Timestamp.now(),
                                              });
                                            }

                                            setState(() {
                                              _expenses.removeAt(index);
                                              _filteredExpenses = List.from(_expenses);
                                            });

                                            Navigator.of(context).pop();
                                          });
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

            ////////////
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
                                  bool tempCashBox = expense.isCashboxChecked;

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
                                        Row(
                                          children: [
                                            Checkbox(
                                              value: tempCashBox,
                                              onChanged: (value) {
                                                setState(() {
                                                  tempCashBox = value!;
                                                });
                                              },
                                            ),
                                            Text('Cashbox-এ অন্তর্ভুক্ত করুন'),
                                          ],
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
                                                date: expense.date, isCashboxChecked: false,
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
