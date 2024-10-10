import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart'; // For formatting date
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Firebase authentication

class SaleNewCustomer extends StatefulWidget {
  @override
  _SaleNewCustomerState createState() => _SaleNewCustomerState();
}

class _SaleNewCustomerState extends State<SaleNewCustomer> {
  final FirebaseAuth _auth = FirebaseAuth.instance; // FirebaseAuth instance
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _transactionController = TextEditingController();
  final TextEditingController _cashPaymentController = TextEditingController(); // New field controller
  DateTime _selectedDate = DateTime.now(); // Default to today's date
  File? _selectedImage;
  String? _image;

  // Date picker function
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate, // Show previously selected or today's date
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // Image picker function
  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  // Save customer function
  void _saveCustomer() async {
    final User? user = _auth.currentUser; // Get the current logged-in user
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please log in to add customer')),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      // Image upload to Firebase Storage
      if (_selectedImage != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('customer_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
        await storageRef.putFile(_selectedImage!);
        _image = await storageRef.getDownloadURL();
      } else {
        _image = 'assets/error.jpg'; // Default image path if no image is picked
      }

      // Use selected date or current date if no date is chosen
      final DateTime transactionDate = _selectedDate;

      // Calculate transaction amount
      double transactionAmount = double.tryParse(_transactionController.text) ?? 0;
      double cashPayment = double.tryParse(_cashPaymentController.text) ?? 0;
      double customerTransaction = transactionAmount - cashPayment;

      // Save sales data to "sales" collection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('sales')  // Save to "sales" sub-collection
          .add({
        'amount': transactionAmount,  // "মোট বিক্রির পরিমাণ(টাকা)" value
        'time': transactionDate.toIso8601String(),  // Save selected or current date as "time"
      });

      // Save customer data to Firestore under the user's UID
      final customerData = {
        'name': _nameController.text,
        'phone': _phoneController.text,
        'image': _image,
        'transaction': customerTransaction, // After subtracting the cash payment
        'transactionDate': transactionDate.toIso8601String(),
        'uid': user.uid,
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('customers')
          .add(customerData);

      // Save cash payment data to "cashbox" collection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('cashbox')
          .add({
        'amount': cashPayment,  // নগদ পরিশোধ
        'due': customerTransaction,  // Total amount - cash payment
        'reason': 'বাকিতে বিক্রি (নতুন কাস্টমার)',  // Reason
        'timestamp': FieldValue.serverTimestamp(),  // Current timestamp
      }).then((value) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('কাস্টমার সফলভাবে যুক্ত হয়েছে')),
        );
        print("Customer Data Saved: $customerData");

        // Clear form after saving
        _formKey.currentState!.reset();
        setState(() {
          _selectedDate = DateTime.now(); // Reset to today's date after saving
          _selectedImage = null;
        });
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cashbox update failed: $error')),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('কাস্টমার যুক্ত করে বিক্রি করুন', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
      ),
      body: Container(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date Picker with icon and formatted text (dd/mm/yyyy)
                Text(
                  "লেনদেনের তারিখ",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _selectDate(context),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat('dd/MM/yyyy').format(_selectedDate), // Always show selected date or today's date
                          style: TextStyle(fontSize: 16, color: Colors.black),
                        ),
                        Icon(Icons.calendar_today, color: Colors.black54), // Calendar icon
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20),

                // Image Picker
                Text("কাস্টমারের ছবি", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                      image: _selectedImage == null
                          ? DecorationImage(
                        image: AssetImage('assets/error.jpg'), // ব্যাকগ্রাউন্ড ইমেজ
                        fit: BoxFit.cover,
                      )
                          : null,
                    ),
                    child: _selectedImage == null
                        ? Center(child: Text('ছবি নির্বাচন করুন', style: TextStyle(color: Colors.black)))
                        : ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: double.infinity,
                        height: 150,
                        child: Image.file(
                          _selectedImage!,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),

                // Name Input
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'নাম',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'এখানে নাম লিখুন';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),

                // Phone Input
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'ফোন নম্বর',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'এখানে ফোন নম্বর লিখুন';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),

                // Transaction Input
                TextFormField(
                  controller: _transactionController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'মোট বিক্রির পরিমাণ(টাকা)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'এখানে মোট বিক্রি মূল্য লিখুন';
                    }
                    if (double.tryParse(value) == null) {
                      return 'এখানে সঠিক পরিমাণ লিখুন';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),

                // New Cash Payment Input
                TextFormField(
                  controller: _cashPaymentController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'নগদ পরিশোধ(টাকা নগদ পেলে)',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 20),

                // Save Button
                Center(
                  child: ElevatedButton(
                    onPressed: _saveCustomer,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                      backgroundColor: Colors.green,
                    ),
                    child: Text(
                      'সেভ করুন',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
