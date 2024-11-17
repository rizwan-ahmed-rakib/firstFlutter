import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Expense {
  final String name;
  final double price;
  final Timestamp date;
  final bool cashBox; // ক্যাশবক্সের জন্য ফিল্ড

  Expense({
    required this.name,
    required this.price,
    required this.date,
    this.cashBox = false, // ডিফল্ট false
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'date': date,
      'cashBox': cashBox,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      name: map['name'],
      price: map['price'],
      date: map['date'],
      cashBox: map['cashBox'] ?? false, // ক্যাশবক্সের মান
    );
  }
}

class ExpenseTracker extends StatefulWidget {
  @override
  _ExpenseTrackerState createState() => _ExpenseTrackerState();
}

class _ExpenseTrackerState extends State<ExpenseTracker> {
  final _formKey = GlobalKey<FormState>();
  String _expenseName = '';
  double _expensePrice = 0.0;
  List<Expense> _expenses = [];
  List<Expense> _filteredExpenses = [];
  String _searchQuery = '';
  late CollectionReference expensesCollection;
  late CollectionReference cashboxCollection;
  String _selectedPeriod = 'Monthly';
  bool _includeInCashBox = false; // ক্যাশবক্স চেকবক্সের জন্য

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
      startDate = now.subtract(Duration(days: (now.weekday % 7 + 1) % 7));
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

  void _addExpenseToFirebase() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final newExpense = Expense(
        name: _expenseName,
        price: _expensePrice,
        date: Timestamp.now(),
        cashBox: _includeInCashBox,
      );

      expensesCollection.add(newExpense.toMap()).then((docRef) {
        setState(() {
          _expenses.add(newExpense); // সরাসরি নতুন খরচ যোগ
          _filteredExpenses = List.from(_expenses);


          if (_includeInCashBox) {
            cashboxCollection.add({
              'amount': -_expensePrice,
              'reason': 'খরচ: $_expenseName',
              'time': Timestamp.now(),
            });
          }

          _formKey.currentState!.reset();
          _includeInCashBox = false;

        });
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
                    decoration: InputDecoration(labelText: 'খরচের বর্ণনা লিখুন'),
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
                    decoration: InputDecoration(labelText: 'খরচের পরিমাণ (টাকা)'),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: _includeInCashBox,
                        onChanged: (value) {
                          setState(() {
                            _includeInCashBox = value!;
                          });
                        },
                      ),
                      Text('Cashbox-এ অন্তর্ভুক্ত করুন'),
                    ],
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
            Expanded(
              child: _filteredExpenses.isEmpty
                  ? Center(child: Text('কোন খরচের তথ্য পাওয়া যায়নি।'))
                  : ListView.builder(
                itemCount: _filteredExpenses.length,
                itemBuilder: (context, index) {
                  final expense = _filteredExpenses[index];
                  return Card(
                    elevation: 4,
                    color: expense.cashBox ? Colors.green[100] : Colors.white,
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
                                  bool tempCashBox = expense.cashBox;

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

                                                // ক্যাশবক্সের লজিক
                                                if (tempCashBox && !expense.cashBox) {
                                                  cashboxCollection.add({
                                                    'amount': -newPrice,
                                                    'reason': 'খরচ আপডেট: ${nameController.text}',
                                                    'time': Timestamp.now(),
                                                  });
                                                } else if (!tempCashBox && expense.cashBox) {
                                                  cashboxCollection.add({
                                                    'amount': expense.price,
                                                    'reason': 'খরচ ডিলিট: ${expense.name}',
                                                    'time': Timestamp.now(),
                                                  });
                                                } else if (tempCashBox && expense.cashBox) {
                                                  cashboxCollection.add({
                                                    'amount': -priceDifference,
                                                    'reason': 'খরচ আপডেট: ${expense.name}',
                                                    'time': Timestamp.now(),
                                                  });
                                                }

                                                // নতুন ডেটা সহ লিস্ট আপডেট
                                                setState(() {
                                                  _expenses[index] = Expense(
                                                    name: nameController.text,
                                                    price: newPrice,
                                                    date: expense.date,
                                                    cashBox: tempCashBox,
                                                  );
                                                  _filteredExpenses = List.from(_expenses);
                                                  // মোট এবং আজকের খরচের হিসাব আপডেট করুন
                                                  totalExpense = _calculateExpenseByPeriod(_selectedPeriod);
                                                  todayExpense = _calculateTodayExpense();
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

                                            if (expense.cashBox) {
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

          ],
        ),
      ),
    );
  }
}

