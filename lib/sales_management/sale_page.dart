import 'package:bebshar_poristhiti/sales_management/sale_new_customer.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/calculator_page.dart';
import 'old_customer_sale.dart';

class SalesPage extends StatefulWidget {
  @override
  _SalesPageState createState() => _SalesPageState();
}

class _SalesPageState extends State<SalesPage> {
  TextEditingController searchController = TextEditingController();
  TextEditingController creditSaleAmountController = TextEditingController();
  TextEditingController quickSaleAmountController = TextEditingController();

  String? selectedCustomerId;
  String? selectedCustomerName;
  double previousTransaction = 0.0;

  Future<void> fetchCustomerData(String customerName) async {
    String uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('customers')
        .where('uid', isEqualTo: uid)
        .where('name', isGreaterThanOrEqualTo: customerName)
        .where('name', isLessThanOrEqualTo: customerName + '\uf8ff')
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      setState(() {
        selectedCustomerId = querySnapshot.docs.first.id;
        selectedCustomerName = querySnapshot.docs.first['name'];
        previousTransaction = querySnapshot.docs.first['transaction'] ?? 0.0;
      });
    } else {
      setState(() {
        selectedCustomerId = null;
        selectedCustomerName = null;
        previousTransaction = 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text('বিক্রি'),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                'বাকিতে বিক্রি',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal),
              ),
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 120,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => SaleNewCustomer()),
                        );
                      },
                      child: Text(
                        'নতুন কাস্টমারের কাছে বিক্রি করুন',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.greenAccent.shade700,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Container(
                    height: 120,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => OldCustomerSale()),
                        );
                      },
                      child: Text(
                        'পুরাতন কাস্টমারের কাছে বিক্রি করুন',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.lightBlue.shade600,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 60),
            Center(
              child: Text(
                'দ্রুত বিক্রি',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal),
              ),
            ),
            SizedBox(height: 10),
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: quickSaleAmountController,
                            decoration: InputDecoration(
                              labelText: 'বিক্রয়ের পরিমাণ লিখুন',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        SizedBox(width: 10), // Space between the text field and icon
                        IconButton(
                          icon: Icon(Icons.calculate_outlined, color: Colors.teal),
                          onPressed: () {
                            // Show the calculator dialog
                            showDialog(
                              context: context,
                              builder: (context) {
                                return CalculatorPage(
                                  onValueSelected: (value) {
                                    quickSaleAmountController.text = value.toString();
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () async {
                        if (quickSaleAmountController.text.isNotEmpty) {
                          try {
                            double quickSaleAmount = double.parse(quickSaleAmountController.text);
                            String? uid = FirebaseAuth.instance.currentUser?.uid;

                            if (uid == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('User not logged in')),
                              );
                              return;
                            }

                            // Prepare the sale data map
                            Map<String, dynamic> saleData = {
                              'amount': quickSaleAmount,
                              'time': Timestamp.now(),
                            };

                            // Add the sale data to Firestore
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(uid)
                                .collection('sales')
                                .add(saleData);

                            // Add the sale to the cashbox as well
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(uid)
                                .collection('cashbox')
                                .add({
                              'amount': quickSaleAmount,
                              'reason': 'দ্রুত বিক্রি',
                              'time': Timestamp.now(),
                            });

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('বিক্রয় সফল হয়েছে!')),
                            );

                            // Clear the quick sale amount after successful sale
                            quickSaleAmountController.clear();
                          } catch (e) {
                            print('Error during sale: $e');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('বিক্রয় করার সময় সমস্যা হয়েছে।')),
                            );
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Please enter an amount')),
                          );
                        }
                      },
                      child: Text(
                        'বিক্রি করুন',
                        style: TextStyle(color: Colors.white), // Change text color here
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal, // Change button color here
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
