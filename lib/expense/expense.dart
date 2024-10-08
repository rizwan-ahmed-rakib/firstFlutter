import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Expense Tracker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ExpenseHomePage(),
    );
  }
}

class ExpenseHomePage extends StatefulWidget {
  @override
  _ExpenseHomePageState createState() => _ExpenseHomePageState();
}

class _ExpenseHomePageState extends State<ExpenseHomePage> {
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  double totalExpense = 0.0;
  double todayExpense = 0.0;
  double weeklyExpense = 0.0;
  double monthlyExpense = 0.0;
  double yearlyExpense = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchExpenses();
  }

  void _fetchExpenses() async {
    final today = DateTime.now();
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    final startOfMonth = DateTime(today.year, today.month, 1);
    final startOfYear = DateTime(today.year, 1, 1);

    QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('expenses').get();
    final transactions = querySnapshot.docs;

    double tempTotal = 0.0;
    double tempToday = 0.0;
    double tempWeekly = 0.0;
    double tempMonthly = 0.0;
    double tempYearly = 0.0;

    transactions.forEach((doc) {
      double amount = doc['amount'];
      DateTime date = (doc['date'] as Timestamp).toDate();

      tempTotal += amount;

      if (isSameDay(date, today)) {
        tempToday += amount;
      }
      if (date.isAfter(startOfWeek)) {
        tempWeekly += amount;
      }
      if (date.isAfter(startOfMonth)) {
        tempMonthly += amount;
      }
      if (date.isAfter(startOfYear)) {
        tempYearly += amount;
      }
    });

    setState(() {
      totalExpense = tempTotal;
      todayExpense = tempToday;
      weeklyExpense = tempWeekly;
      monthlyExpense = tempMonthly;
      yearlyExpense = tempYearly;
    });
  }

  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
  }

  void _addExpense() {
    String description = _descriptionController.text;
    double amount = double.tryParse(_amountController.text) ?? 0.0;

    if (description.isNotEmpty && amount > 0) {
      FirebaseFirestore.instance.collection('expenses').add({
        'description': description,
        'amount': amount,
        'date': Timestamp.now(),
      });

      _descriptionController.clear();
      _amountController.clear();
      _fetchExpenses();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Expense Tracker'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Total Expenses Card
            _buildExpenseCard('Total Expenses', totalExpense),
            SizedBox(height: 5),
            _buildExpenseCard('Today\'s Expenses', todayExpense),
            SizedBox(height: 5),
            _buildExpenseCard('Weekly Expenses', weeklyExpense),
            SizedBox(height: 5),
            _buildExpenseCard('Monthly Expenses', monthlyExpense),
            SizedBox(height: 5),
            _buildExpenseCard('Yearly Expenses', yearlyExpense),
            SizedBox(height: 5),
            // Input Fields
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: 'Expense Description'),
            ),
            TextField(
              controller: _amountController,
              decoration: InputDecoration(labelText: 'Amount'),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 5),
            ElevatedButton(
              onPressed: _addExpense,
              child: Text('Add Expense'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseCard(String title, double amount) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      color: Colors.blueAccent,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 18, color: Colors.white)),
            SizedBox(height: 5),
            Text(
              _formatCurrency(amount),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCurrency(double amount) {
    final format = NumberFormat.currency(locale: 'bn_BD', symbol: '৳');
    return format.format(amount);
  }
}
