// বাকির খাতা

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../add_customer_page.dart';
import '../customer_transaction_history.dart'; // নিশ্চিত করুন এটি আপডেটেড CustomerHistoryPage ইমপোর্ট করে
import 'due_collection.dart';

class DuePage extends StatefulWidget {
  @override
  _DuePageState createState() => _DuePageState();
}

class _DuePageState extends State<DuePage> {
  String _searchText = ""; // সার্চ টেক্সট ধারণ করার জন্য

  // বর্তমানে লগইন করা ইউজারের আইডি FirebaseAuth থেকে নিয়ে আসা
  String? getCurrentUserId() {
    User? user = FirebaseAuth.instance.currentUser;
    return user?.uid; // ইউজারের আইডি রিটার্ন করুন বা যদি ইউজার লগইন না করে থাকে তবে নাল রিটার্ন করুন
  }

  @override
  Widget build(BuildContext context) {
    // ইউজারের আইডি নিয়ে আসা
    String? userId = getCurrentUserId();

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('বাকির খাতা'),
        ),
        body: Center(
          child: Text('User is not logged in.'), // ইউজার লগইন না করলে দেখাবে
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Text("বাকির খাতা"),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddCustomerPage()),
              );
            },
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white70,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DueCollectionPage()),
              );
            },
            child: Text('বাকি আদায়'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            SizedBox(height: 10),
            _buildSearchBar(), // সার্চ বারের জন্য বিল্ডার
            Expanded(child: _buildCustomerList(userId)), // কাস্টমারের তালিকা গঠনের জন্য বিল্ডার
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      decoration: InputDecoration(
        labelText: 'কাস্টমার খুঁজুন', // সার্চ টেক্সট এর লেবেল
        prefixIcon: Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      onChanged: (value) {
        setState(() {
          _searchText = value; // সার্চ টেক্সট আপডেট করুন
        });
      },
    );
  }

  Widget _buildCustomerList(String userId) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('customers')
          .where('uid', isEqualTo: userId)
          .snapshots(), // ফায়ারস্টোর থেকে কাস্টমার ডেটা নিয়ে আসা
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator()); // ডেটা না আসা পর্যন্ত লোডিং চিহ্ন দেখানো
        }

        var customers = snapshot.data?.docs ?? []; // কাস্টমার ডেটা ডকুমেন্টস হিসেবে রাখা

        // সার্চ টেক্সটের উপর ভিত্তি করে গ্রাহকদের তালিকা ফিল্টার করা
        if (_searchText.isNotEmpty) {
          customers = customers.where((customer) {
            var customerData = customer.data() as Map<String, dynamic>;
            var name = customerData['name'].toString().toLowerCase();
            return name.contains(_searchText.toLowerCase()); // সার্চ টেক্সট মিলিয়ে দেখুন
          }).toList();
        }

        return ListView.builder(
          itemCount: customers.length,
          itemBuilder: (context, index) {
            var customer = customers[index];
            return _buildCustomerTile(context, customer, userId); // প্রতিটি কাস্টমারের জন্য টাইল তৈরি করা
          },
        );
      },
    );
  }

  Widget _buildCustomerTile(BuildContext context, DocumentSnapshot customer, String userId) {
    Map<String, dynamic>? customerData = customer.data() as Map<String, dynamic>?;

    String imageUrl =
    (customerData != null && customerData.containsKey('image'))
        ? customerData['image']
        : 'assets/error.jpg'; // ছবি না থাকলে ডিফল্ট ছবি দেখানো
    String name = customerData?['name'] ?? 'Unknown'; // কাস্টমারের নাম
    String phone = customerData?['phone'] ?? 'Unknown'; // কাস্টমারের ফোন নাম্বার
    String customerId = customer.id; // কাস্টমার আইডি নেয়া

    String transaction = (customerData?['transaction'] is List)
        ? (customerData?['transaction'] as List<dynamic>).join(", ")
        : customerData?['transaction']?.toString() ?? '0'; // লেনদেনের ডেটা নেয়া

    return ListTile(
      leading: GestureDetector(
        onTap: () {
          _showImageDialog(context, imageUrl, customer); // ছবির উপর ট্যাপ করলে পপআপ খুলবে
        },
        child: CircleAvatar(
          backgroundImage: NetworkImage(imageUrl),
          onBackgroundImageError: (_, __) => AssetImage('assets/error.jpg'), // যদি ছবির লিংকে কোনো সমস্যা থাকে
        ),
      ),
      title: Text(name), // কাস্টমারের নাম দেখানো
      subtitle: Text(phone), // কাস্টমারের ফোন নাম্বার দেখানো
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '৳ $transaction', // লেনদেনের তথ্য
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              // CustomerHistoryPage এ নেভিগেট করা
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CustomerHistoryPage(
                    userId: userId, // ইউজারের আইডি পাস করা
                    customerId: customerId, // কাস্টমারের আইডি পাস করা
                    customerName: name, // কাস্টমারের নাম পাস করা
                    customerImageUrl: imageUrl, // কাস্টমারের ছবি পাস করা
                    customerPhoneNumber: phone, // কাস্টমারের ফোন নাম্বার পাস করা
                  ),
                ),
              );
            },
            child: Row(
              children: [
                Icon(
                  Icons.remove_red_eye,
                  color: Colors.blue, // দেখার আইকন
                ),
              ],
            ),
          ),
        ],
      ),
      onTap: () {
        _showEditPopup(context, userId, customer); // এডিট পপআপ দেখানো
      },
    );
  }

  void _showImageDialog(BuildContext context, String imageUrl, DocumentSnapshot customer) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.network(
                imageUrl,
                errorBuilder: (context, error, stackTrace) {
                  return Image.asset('assets/error.jpg'); // যদি নেটওয়ার্কে সমস্যা থাকে
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () async {
                      await _pickAndUploadImage(context, customer); // ছবি আপলোডের জন্য ফাংশন কল
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.cancel),
                    onPressed: () {
                      Navigator.pop(context); // ডায়লগ বন্ধ করা
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickAndUploadImage(BuildContext context, DocumentSnapshot customer) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery); // গ্যালারি থেকে ছবি নেয়া

    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);

      String fileName = 'customer_images/${customer.id}.jpg'; // ছবির ফাইল নাম
      try {
        Reference storageReference =
        FirebaseStorage.instance.ref().child(fileName); // Firebase Storage এ ফাইল রাখা
        UploadTask uploadTask = storageReference.putFile(imageFile);
        TaskSnapshot snapshot = await uploadTask;
        String downloadUrl = await snapshot.ref.getDownloadURL(); // আপলোডের পরে ইউআরএল নেয়া

        await FirebaseFirestore.instance
            .collection('users')
            .doc(getCurrentUserId())
            .collection('customers')
            .doc(customer.id)
            .update({'image': downloadUrl}); // Firebase Firestore এ ইমেজ ইউআরএল আপডেট করা

        Navigator.pop(context); // পপআপ বন্ধ করা
      } catch (error) {
        print('Error uploading image: $error'); // যদি কোনো সমস্যা হয়
      }
    }
  }

  void _showEditPopup(BuildContext context, String userId, DocumentSnapshot customer) {
    String? customerName = customer['name'];
    String? customerPhone = customer['phone'];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('এডিট করুন'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: TextEditingController(text: customerName),
                decoration: InputDecoration(labelText: 'নাম'),
                onChanged: (value) {
                  customerName = value;
                },
              ),
              TextField(
                controller: TextEditingController(text: customerPhone),
                decoration: InputDecoration(labelText: 'ফোন নাম্বার'),
                onChanged: (value) {
                  customerPhone = value;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // পপআপ বন্ধ করা
              },
              child: Text('ক্যান্সেল'),
            ),
            TextButton(
              onPressed: () async {
                if (customerName != null && customerPhone != null) {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(userId)
                      .collection('customers')
                      .doc(customer.id)
                      .update({
                    'name': customerName,
                    'phone': customerPhone,
                  }); // Firebase Firestore এ কাস্টমারের তথ্য আপডেট করা
                }
                Navigator.pop(context); // পপআপ বন্ধ করা
              },
              child: Text('সেভ'),
            ),
          ],
        );
      },
    );
  }
}
