import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  // খরচের তথ্য ম্যাপে রূপান্তর করার জন্য
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'date': date,
    };
  }

  // ম্যাপ থেকে খরচের তথ্য তৈরি করার জন্য
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
  late CollectionReference cashboxCollection;
  String _selectedPeriod = 'Monthly';

  @override
  void initState() {
    super.initState();
    _loadCurrentUserExpenses();
  }

  // বর্তমান ব্যবহারকারীর খরচের তথ্য লোড করা
  void _loadCurrentUserExpenses() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      expensesCollection = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('expense');

      // *cashbox* সংগ্রহের রেফারেন্স তৈরি করা
      cashboxCollection = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('cashbox');

      // আগের সকল খরচের তথ্য লোড করা
      QuerySnapshot querySnapshot = await expensesCollection.get();
      setState(() {
        _expenses = querySnapshot.docs
            .map((doc) => Expense.fromMap(doc.data() as Map<String, dynamic>))
            .toList();
        _filteredExpenses = _expenses;
      });
    }
  }

  // আজকের মোট খরচ গণনা করা
  double _calculateTodayExpense() {
    DateTime today = DateTime.now();
    return _filteredExpenses
        .where((expense) =>
    expense.date.toDate().day == today.day &&
        expense.date.toDate().month == today.month &&
        expense.date.toDate().year == today.year)
        .fold(0.0, (sum, expense) => sum + expense.price);
  }

  // নির্দিষ্ট সময়ের খরচ গণনা করা
  double _calculateExpenseByPeriod(String period) {
    DateTime now = DateTime.now();
    DateTime startDate;

    if (period == 'Weekly') {
      // সপ্তাহের শুরু থেকে বর্তমান পর্যন্ত গণনা করা (বাংলাদেশে শনিবারকে শুরু হিসেবে ধরা)
      startDate = now.subtract(Duration(days: (now.weekday % 7 + 1) % 7));
    } else if (period == 'Monthly') {
      startDate = DateTime(now.year, now.month, 1); // মাসের শুরু থেকে
    } else if (period == 'Yearly') {
      startDate = DateTime(now.year, 1, 1); // বছরের শুরু থেকে
    } else {
      _filteredExpenses = _expenses;
      return _filteredExpenses.fold(0.0, (sum, expense) => sum + expense.price);
    }

    return _filteredExpenses
        .where((expense) => expense.date.toDate().isAfter(startDate))
        .fold(0.0, (sum, expense) => sum + expense.price);
  }

  // নতুন খরচ Firebase-এ যুক্ত করা
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

        // নিচের অংশে *cashbox* থেকে খরচের পরিমাণ কমানো হচ্ছে:
        // - নেগেটিভ মান (-_expensePrice) যোগ করার মাধ্যমে *cashbox*-এ নতুন একটি ডকুমেন্ট যুক্ত করা হচ্ছে।
        // - এটি নির্দেশ করে যে, এই পরিমাণ টাকা *cashbox* থেকে খরচ হিসেবে কমেছে।
        cashboxCollection.add({
          'amount': -_expensePrice, // এখানে নেগেটিভ মান খরচকে নির্দেশ করে
          'reason': 'খরচ: $_expenseName', // খরচের কারণ উল্লেখ করা
          'time': Timestamp.now(), // খরচের সময়
        });

        // খরচ যুক্ত করার পর ফর্ম রিসেট করা
        _formKey.currentState!.reset();
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
                          // এডিট বাটন
                          IconButton(
                            icon: Icon(Icons.edit, color: Colors.blue),
                            onPressed: () {
                              // আপডেট করার ডায়ালগ দেখানো হচ্ছে
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  TextEditingController nameController =
                                  TextEditingController(text: expense.name);
                                  TextEditingController priceController =
                                  TextEditingController(
                                      text: expense.price.toString());

                                  return AlertDialog(
                                    title: Text('Update Expense'),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // নাম এডিট করার জন্য ইনপুট ফিল্ড
                                        TextField(
                                          controller: nameController,
                                          decoration: InputDecoration(labelText: 'Name'),
                                        ),
                                        // প্রাইস এডিট করার জন্য ইনপুট ফিল্ড
                                        TextField(
                                          controller: priceController,
                                          decoration: InputDecoration(labelText: 'Price'),
                                          keyboardType: TextInputType.number,
                                        ),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop(); // বাতিল করলে ডায়ালগ বন্ধ হবে
                                        },
                                        child: Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          double newPrice = double.parse(priceController.text);
                                          double priceDifference = newPrice - expense.price;

                                          // ফায়ারস্টোরে খরচের তথ্য আপডেট করা হচ্ছে
                                          expensesCollection
                                              .where('name', isEqualTo: expense.name)
                                              .where('price', isEqualTo: expense.price)
                                              .get()
                                              .then((snapshot) {
                                            snapshot.docs.first.reference.update({
                                              'name': nameController.text,
                                              'price': newPrice,
                                            });

                                            // *cashbox*-এ প্রাইসের পার্থক্য অনুযায়ী এন্ট্রি যোগ করা হচ্ছে
                                            cashboxCollection.add({
                                              'amount': -priceDifference, // পার্থক্যের পরিমাণ অনুযায়ী ক্যাশবক্সে পরিবর্তন
                                              'reason': 'খরচ আপডেট: ${nameController.text}',
                                              'time': Timestamp.now(),
                                            });

                                            // UI আপডেট করা হচ্ছে
                                            setState(() {
                                              _expenses[index] = Expense(
                                                name: nameController.text,
                                                price: newPrice,
                                                date: expense.date,
                                              );
                                              _filteredExpenses = List.from(_expenses);
                                            });

                                            Navigator.of(context).pop(); // ডায়ালগ বন্ধ করা হচ্ছে
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
                          // ডিলিট বাটন
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              // ডিলিট কনফার্মেশনের জন্য ডায়ালগ দেখানো হচ্ছে
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
                                          // ফায়ারস্টোর থেকে খরচের তথ্য ডিলিট করা হচ্ছে
                                          expensesCollection
                                              .where('name', isEqualTo: expense.name)
                                              .where('price', isEqualTo: expense.price)
                                              .get()
                                              .then((snapshot) {
                                            snapshot.docs.first.reference.delete();

                                            // ডিলিট করা খরচের পরিমাণ পজিটিভ হিসেবে *cashbox*-এ যোগ করা হচ্ছে
                                            cashboxCollection.add({
                                              'amount': expense.price, // ক্যাশবক্সে ফেরত যোগ
                                              'reason': 'খরচ ডিলিট: ${expense.name}',
                                              'time': Timestamp.now(),
                                            });

                                            // UI থেকে খরচের তথ্য সরানো হচ্ছে
                                            setState(() {
                                              _expenses.removeAt(index);
                                              _filteredExpenses = List.from(_expenses);
                                            });

                                            Navigator.of(context).pop(); // ডায়ালগ বন্ধ করা হচ্ছে
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


// আপডেট করার সময়:
//
// priceDifference ভেরিয়েবলটি খরচের পুরোনো এবং নতুন মূল্যের পার্থক্য হিসাব করে।
// এরপর, cashbox-এ সেই পার্থক্যের বিপরীতে একটি এন্ট্রি যুক্ত করা হয়।
// যদি নতুন খরচ বেশি হয়, তাহলে priceDifference পজিটিভ হবে এবং cashbox থেকে কমানো হবে।
// আর যদি নতুন খরচ কম হয়, তাহলে priceDifference নেগেটিভ হবে এবং সেই পরিমাণ cashbox-এ যোগ হবে।
// ডিলিট করার সময়:
//
// খরচ ডিলিট করার পর cashbox-এ সেই খরচের পুরো পরিমাণটি পজিটিভ হিসেবে যুক্ত করা হয়, যেন cashbox-এ সেই পরিমাণ টাকা ফেরত যোগ হয়।
// এভাবে, আপডেট বা ডিলিট করার সময় cashbox যথাযথভাবে আপডেট হবে।
