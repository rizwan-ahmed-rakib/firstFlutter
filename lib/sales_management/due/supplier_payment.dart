import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SupplierPaymentPage extends StatefulWidget {
  @override
  _SupplierPaymentPageState createState() => _SupplierPaymentPageState();
}

class _SupplierPaymentPageState extends State<SupplierPaymentPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> originalList = []; // মূল ডাটা লিস্ট
  List<Map<String, dynamic>> filteredList = []; // ফিল্টারকৃত ডাটা লিস্ট

  @override
  void initState() {
    super.initState();
    _fetchSupplierData(); // Fetch data from Firestore
  }

  // Function to get the current user's UID
  String? getCurrentUserId() {
    User? user = FirebaseAuth.instance.currentUser;
    return user?.uid;
  }

  void _fetchSupplierData() async {
    String? userId = getCurrentUserId(); // Get the user's UID

    if (userId != null) {
      // Get data from Firestore based on the current user's UID
      FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('suppliers')
          .snapshots()
          .listen((snapshot) {
        setState(() {
          originalList = snapshot.docs.map((doc) {
            var data = doc.data() as Map<String, dynamic>;
            return {
              'name': data['name'] ?? 'Unknown', // ডিফল্ট নাম
              'amount': data['transaction'] ?? 0, // ডিফল্ট ট্রানজেকশন অ্যামাউন্ট
              'image': data['image'] ?? 'assets/error.jpg', // ডিফল্ট ইমেজ
            };
          }).toList();
          filteredList = originalList; // ডিফল্ট হিসেবে সব ডাটা দেখাবে
        });
      });
    } else {
      // Handle case where the user is not logged in
      setState(() {
        originalList = [];
        filteredList = [];
      });
    }
  }

  void _filterSupplierList(String query) {
    setState(() {
      if (query.isEmpty) {
        // যদি সার্চ ফিল্ড খালি হয়, মূল লিস্ট দেখাবে
        filteredList = originalList;
      } else {
        // সার্চ অনুযায়ী ফিল্টার করবে
        filteredList = originalList.where((supplier) {
          return supplier['name'].toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  void _showDetails(int index) {
    final supplier = filteredList[index];
    TextEditingController amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height * 0.55,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        supplier['name'],
                        style: TextStyle(fontSize: 26),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10.0),
                  child: Image.network(
                    supplier['image'],
                    height: 200,  // ছবি যেকোনো অবস্থাতেই 200 পিক্সেল উচ্চতা নিবে
                    width: double.infinity,  // প্রস্থ সম্পূর্ণ থাকবে
                    fit: BoxFit.cover,  // ছবিটি নির্দিষ্ট সাইজে কভার করবে
                    errorBuilder: (context, error, stackTrace) => Image.asset(
                      'assets/error.jpg',
                      height: 200,  // fallback ছবির উচ্চতা নির্ধারণ করা হলো
                      width: double.infinity,  // fallback ছবির প্রস্থ সম্পূর্ণ থাকবে
                      fit: BoxFit.cover,  // fallback ছবিও সঠিকভাবে ফ্রেমে মানিয়ে যাবে
                    ),
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'আগের লেনদেন: ${supplier['amount']}৳',
                  style: TextStyle(color: Colors.red, fontSize: 24, fontWeight: FontWeight.bold),
                ),

                SizedBox(height: 10),
                TextField(
                  controller: amountController,
                  decoration: InputDecoration(
                    labelText: 'পরিমাণ লিখুন',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 20),
                        ),
                        onPressed: () {
                          setState(() {
                            if (amountController.text.isNotEmpty) {
                              supplier['amount'] += int.parse(amountController.text);
                            }
                            Navigator.pop(context);
                          });
                        },
                        child: Text(
                          'টাকা পেলাম',
                          style: TextStyle(color: Colors.red, fontSize: 20),
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 20),
                        ),
                        onPressed: () {
                          setState(() {
                            if (amountController.text.isNotEmpty) {
                              supplier['amount'] -= int.parse(amountController.text);
                            }
                            Navigator.pop(context);
                          });
                        },
                        child: Text(
                          'টাকা দিলাম',
                          style: TextStyle(color: Colors.green, fontSize: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('দ্রুত সাপ্লায়ার লেনদেন'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              onChanged: _filterSupplierList,
              decoration: InputDecoration(
                labelText: 'সার্চ করুন',
                prefixIcon: Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: filteredList.length,
                itemBuilder: (context, index) {
                  final supplier = filteredList[index];
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    elevation: 5,
                    margin: EdgeInsets.symmetric(vertical: 5),
                    child: ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(10.0),
                        child: Image.network(
                          supplier['image'],
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Image.asset('assets/error.jpg'),
                        ),
                      ),
                      title: Text(supplier['name'], style: TextStyle(fontSize: 18)),
                      trailing: Text(
                        '${supplier['amount']}৳',
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 19),
                      ),
                      onTap: () => _showDetails(index), // Show details on tap
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
