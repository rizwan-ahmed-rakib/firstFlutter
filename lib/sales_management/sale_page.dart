import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'customer/add_customer_page.dart';
import 'due/add_customer_page.dart';

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
  String? selectedCustomerPhone;
  double previousTransaction = 0.0;

  // Fetch customer data from Firestore
  Future<void> fetchCustomerData(String customerName) async {
    String uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    // Query to get customers by uid and name
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('customers')
        .where('uid', isEqualTo: uid)
        .where('name', isGreaterThanOrEqualTo: customerName)
        .where('name', isLessThanOrEqualTo: customerName + '\uf8ff') // For full-text search
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      setState(() {
        selectedCustomerId = querySnapshot.docs.first.id; // Get the first match
        selectedCustomerName = querySnapshot.docs.first['name'];
        previousTransaction = querySnapshot.docs.first['transaction'] ?? 0.0; // Safely handle transaction
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
      appBar: AppBar(
        title: Text('বিক্রি পেজ'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // "বাকিতে বিক্রি" সেকশন
            Text(
              'বাকিতে বিক্রি',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('কাস্টমার যুক্ত করুনঃ'),
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AddCustomerPage()),
                    );
                  },
                ),
              ],
            ),
            SizedBox(height: 10),

            // সার্চ ফিল্ড
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: 'কাস্টমার খুঁজুন',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) async {
                await fetchCustomerData(value); // Call fetchCustomerData with the current input
              },
            ),
            SizedBox(height: 10),

            // সিলেক্ট করা কাস্টমারের নাম এবং বাকির পরিমাণ দেখানো
            if (selectedCustomerName != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('নামঃ $selectedCustomerName'),
                  Text('বাকির পরিমাণঃ $previousTransaction টাকা'),
                ],
              ),
            SizedBox(height: 10),

            // নতুন বিক্রির এমাউন্ট ইনপুট ফিল্ড
            TextField(
              controller: creditSaleAmountController,
              decoration: InputDecoration(
                labelText: 'বিক্রির এমাউন্ট লিখুন',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 10),

            // "বিক্রি করুন" বাটন
            ElevatedButton(
              onPressed: () async {
                if (selectedCustomerId != null && creditSaleAmountController.text.isNotEmpty) {
                  double saleAmount = double.parse(creditSaleAmountController.text);

                  // কাস্টমারের transaction আপডেট
                  await FirebaseFirestore.instance.collection('customers').doc(selectedCustomerId).update({
                    'transaction': FieldValue.increment(saleAmount),
                  });

                  // Cashbox এ নতুন বিক্রি যুক্ত করা
                  await FirebaseFirestore.instance.collection('cashbox').add({
                    'amount': saleAmount,
                    'reason': 'বিক্রি',
                    'time': Timestamp.now(),
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('বিক্রি সম্পন্ন হয়েছে')),
                  );

                  setState(() {
                    searchController.clear();
                    creditSaleAmountController.clear();
                    selectedCustomerId = null;
                    selectedCustomerName = null;
                    previousTransaction = 0.0; // Reset previous transaction
                  });
                }
              },
              child: Text('বিক্রি করুন'),
            ),
            SizedBox(height: 20),

            // "দ্রুত বিক্রি" সেকশন
            Text(
              'দ্রুত বিক্রি',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),

            // দ্রুত বিক্রির ইনপুট ফিল্ড
            TextField(
              controller: quickSaleAmountController,
              decoration: InputDecoration(
                labelText: 'বিক্রয়ের পরিমাণ লিখুন',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 10),

            // "বিক্রি করুন" বাটন
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

                    // Data to be stored
                    Map<String, dynamic> saleData = {
                      'amount': quickSaleAmount,
                      'time': Timestamp.now(),
                    };

                    // Store sale data in user's personal 'sales' subcollection
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(uid)
                        .collection('sales')
                        .add(saleData);

                    // Store the same sale data in 'cashbox' subcollection
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(uid)
                        .collection('cashbox')
                        .add({
                      'amount': quickSaleAmount,
                      'reason': 'বিক্রি',
                      'time': Timestamp.now(),
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('দ্রুত বিক্রি সম্পন্ন হয়েছে')),
                    );

                    // Clear the input field after submission
                    setState(() {
                      quickSaleAmountController.clear();
                    });
                  } catch (e) {
                    // Handle errors
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${e.toString()}')),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please enter a sale amount')),
                  );
                }
              },
              child: Text('বিক্রি করুন'),
            ),
          ],
        ),
      ),
    );
  }
}