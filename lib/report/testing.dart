import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/date_symbol_data_local.dart'; // for locale initialization

class CashBoxScreen extends StatefulWidget {
  @override
  _CashBoxScreenState createState() => _CashBoxScreenState();
}

class _CashBoxScreenState extends State<CashBoxScreen> {
  // String _currentTime = '';
  // Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Initialize locale and start the timer
    initializeDateFormatting('en_BD', null);
    // _startClock();
  }

  // @override
  // void dispose() {
  //   _timer?.cancel(); // Cancel the timer when the widget is disposed
  //   super.dispose();
  // }

// Initialize locale for Bangladesh
// initializeDateFormatting('en_BD', null);

// Function to format date and time
  String _formatDateTime(DateTime dateTime) {
    // Format with day name, date, and time (AM/PM)
    return DateFormat('EEEE, dd-MM-yyyy – hh:mm a', 'en_BD').format(dateTime);
  }

// Function to start the clock and update time every second
//   void _startClock() {
//     _currentTime = _formatDateTime(DateTime.now());
//     _timer = Timer.periodic(Duration(seconds: 1), (timer) {
//       setState(() {
//         _currentTime = _formatDateTime(DateTime.now());
//       });
//     });
//   }

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _reasonController =
      TextEditingController(); // Reason controller
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  Future<void> _addCash() async {
    double amount = double.tryParse(_amountController.text) ?? 0.0;
    String reason = _reasonController.text.trim(); // Get reason from the field
    User? currentUser = _auth.currentUser;

    if (currentUser != null) {
      _amountController.clear();
      _reasonController.clear(); // Clear the reason after adding

      // Add transaction to Firestore
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('cashbox')
          .add({
        "amount": amount,
        "reason": reason,
        "type": "add",
        "time": DateTime.now(),
      });
    }
  }

  Future<void> _withdrawCash() async {
    double amount = double.tryParse(_amountController.text) ?? 0.0;
    String reason = _reasonController.text.trim(); // Get reason from the field
    User? currentUser = _auth.currentUser;

    if (currentUser != null) {
      _amountController.clear();
      _reasonController.clear(); // Clear the reason after withdrawing

      // Add transaction to Firestore
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('cashbox')
          .add({
        "amount": -amount,
        "reason": reason,
        "type": "withdraw",
        "time": DateTime.now(),
      });
    }
  }

  Future<void> _editTransaction(
      String id, double oldAmount, String oldReason) async {
    TextEditingController editAmountController = TextEditingController();
    TextEditingController editReasonController = TextEditingController();

    editAmountController.text = oldAmount.toString();
    editReasonController.text = oldReason; // Pre-fill reason

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Transaction'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: editAmountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'New Amount'),
              ),
              TextField(
                controller: editReasonController,
                decoration:
                    InputDecoration(labelText: 'Reason'), // Edit reason field
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Save'),
              onPressed: () async {
                double newAmount =
                    double.tryParse(editAmountController.text) ?? oldAmount;
                String newReason =
                    editReasonController.text.trim(); // Get new reason

                User? currentUser = _auth.currentUser;
                if (currentUser != null) {
                  await _firestore
                      .collection('users')
                      .doc(currentUser.uid)
                      .collection('cashbox')
                      .doc(id)
                      .update({
                    "amount": newAmount,
                    "reason": newReason, // Update the reason
                    "time": DateTime.now(), // Update the timestamp
                  });
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteTransaction(String id) async {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirm Delete'),
          content: Text('Are you sure you want to delete this transaction?'),
          actions: [
            TextButton(
              child: Text('No'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog, no action
              },
            ),
            TextButton(
              child: Text('Yes'),
              onPressed: () async {
                User? currentUser = _auth.currentUser;
                if (currentUser != null) {
                  // Delete the transaction from Firestore
                  await _firestore
                      .collection('users')
                      .doc(currentUser.uid)
                      .collection('cashbox')
                      .doc(id)
                      .delete();
                }
                Navigator.of(context).pop(); // Close the dialog after deletion
              },
            ),
          ],
        );
      },
    );
  }

  String _formatCurrency(double value) {
    return NumberFormat.currency(locale: 'en_US', symbol: '\৳').format(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Cash Box  ',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors
            .green, // Make the background transparent to show the gradient
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.lightBlueAccent, Colors.tealAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [


              SizedBox(height: 10),

              // Current Balance Card using StreamBuilder to calculate balance
              StreamBuilder(
                stream: _firestore
                    .collection('users')
                    .doc(_auth.currentUser!.uid)
                    .collection('cashbox')
                    .snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (!snapshot.hasData) {
                    return Center(
                      // Center the card
                      child: Card(
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
                              Text('Current Balance',
                                  style: TextStyle(
                                      fontSize: 18, color: Colors.white)),
                              SizedBox(height: 10),
                              Text(
                                "Loading...",
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  } else {
                    // Calculate the current balance from Firestore data
                    final transactions = snapshot.data!.docs;
                    double totalBalance = transactions.fold(0.0, (sum, doc) {
                      return sum + (doc['amount'] as double);
                    });

                    return Center(
                      // Center the card
                      child: Card(
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
                              Text('Current Balance',
                                  style: TextStyle(
                                      fontSize: 18, color: Colors.white)),
                              SizedBox(height: 10),
                              Text(
                                _formatCurrency(totalBalance),
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                },
              ),
              SizedBox(height: 20),

              // Cash Entry Field
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Enter Amount (\৳)',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Reason Entry Field
              TextFormField(
                controller: _reasonController,
                decoration: InputDecoration(
                  labelText: 'Reason',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Action Buttons
              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      // Validate Amount before adding cash
                      if (_amountController.text.isEmpty) {
                        // Show a SnackBar if the amount is empty
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Please enter an amount to add.'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      } else {
                        _addCash(); // Proceed to add cash if amount is valid
                      }
                    },
                    icon: Icon(Icons.add),
                    label: Text('Add Cash'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Validate Amount before withdrawing cash
                      if (_amountController.text.isEmpty) {
                        // Show a SnackBar if the amount is empty
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Please enter an amount to withdraw.'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      } else {
                        _withdrawCash(); // Proceed to withdraw cash if amount is valid
                      }
                    },
                    icon: Icon(Icons.remove),
                    label: Text('Withdraw'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),


              // Recent Transactions Section
              Text('Recent Transactions',
                  style: TextStyle(fontSize: 18, color: Colors.white)),
              Expanded(
                child: StreamBuilder(
                  stream: _firestore
                      .collection('users')
                      .doc(_auth.currentUser!.uid)
                      .collection('cashbox')
                      .orderBy('time', descending: true)
                      .snapshots(),
                  builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                    if (!snapshot.hasData) {
                      return Center(child: CircularProgressIndicator());
                    }

                    final transactions = snapshot.data!.docs;
                    return ListView.builder(
                      itemCount: transactions.length,
                      itemBuilder: (context, index) {
                        final transaction = transactions[index];
                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          color: transaction['amount'] < 0
                              ? Colors.redAccent
                              : Colors.greenAccent,
                          child: ListTile(
                            title: Text(
                              _formatCurrency(transaction['amount']),
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Reason: ${transaction['reason']}',
                                  style: TextStyle(color: Colors.white),
                                ),
                                Text(
                                  DateFormat(
                                          'EEEE, dd-MM-yyyy – hh:mm a', 'en_BD')
                                      .format(
                                    transaction['time'].toDate().toLocal(),
                                  ),
                                  style: TextStyle(color: Colors.white),
                                ),

                                // Text(
                                //   DateFormat('dd-MM-yyyy – kk:mm')
                                //       .format(transaction['time'].toDate()),
                                //   style: TextStyle(color: Colors.white),
                                // ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit, color: Colors.white),
                                  onPressed: () {
                                    _editTransaction(
                                      transaction.id,
                                      transaction['amount'],
                                      transaction['reason'], // Pass old reason
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.white),
                                  onPressed: () {
                                    _deleteTransaction(transaction.id);
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
////////////////////////////////////////////////////////////////////////////////////////////////////////////

