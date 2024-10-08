import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class DueCollectionPage extends StatefulWidget {
  @override
  _DueCollectionPageState createState() => _DueCollectionPageState();
}

class _DueCollectionPageState extends State<DueCollectionPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> originalList = []; // মূল ডাটা লিস্ট
  List<Map<String, dynamic>> filteredList = []; // ফিল্টারকৃত ডাটা লিস্ট

  @override
  void initState() {
    super.initState();
    _fetchDueData(); // Fetch data from Firestore
  }

  // Function to get the current user's UID
  String? getCurrentUserId() {
    User? user = FirebaseAuth.instance.currentUser;
    return user?.uid;
  }

  void _fetchDueData() async {
    String? userId = getCurrentUserId(); // Get the user's UID

    if (userId != null) {
      // Get data from Firestore based on the current user's UID
      FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('customers')
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

  void _filterDueList(String query) {
    setState(() {
      if (query.isEmpty) {
        // যদি সার্চ ফিল্ড খালি হয়, মূল লিস্ট দেখাবে
        filteredList = originalList;
      } else {
        // সার্চ অনুযায়ী ফিল্টার করবে
        filteredList = originalList.where((customer) {
          return customer['name'].toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  void _showDetails(int index) {
    final customer = filteredList[index];
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
                        customer['name'],
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
                    customer['image'],
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Image.asset(
                      'assets/error.jpg',
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'বাকির পরিমাণ: ${customer['amount']}৳',
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
                          if (amountController.text.isNotEmpty) {
                            setState(() {
                              customer['amount'] += int.parse(amountController.text);
                            });
                            _updateCustomerAmount(customer['name'], customer['amount']);
                          }
                          Navigator.pop(context);
                        },
                        child: Text(
                          'টাকা দিলাম',
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
                          if (amountController.text.isNotEmpty) {
                            setState(() {
                              customer['amount'] -= int.parse(amountController.text);
                            });
                            _updateCustomerAmount(customer['name'], customer['amount']);
                          }
                          Navigator.pop(context);
                        },
                        child: Text(
                          'টাকা পেলাম',
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
  // Function to update the customer's amount in Firestore
  void _updateCustomerAmount(String customerName, int newAmount) async {
    String? userId = getCurrentUserId();
    if (userId != null) {
      QuerySnapshot customerSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('customers')
          .where('name', isEqualTo: customerName)
          .get();

      if (customerSnapshot.docs.isNotEmpty) {
        DocumentReference customerDoc = customerSnapshot.docs.first.reference;
        await customerDoc.update({'transaction': newAmount});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('বাকি আদায়'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              onChanged: _filterDueList,
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
                  final customer = filteredList[index];
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
                          customer['image'],
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Image.asset('assets/error.jpg'),
                        ),
                      ),
                      title: Text(customer['name'], style: TextStyle(fontSize: 18)),
                      trailing: Text(
                        '${customer['amount']}৳',
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
