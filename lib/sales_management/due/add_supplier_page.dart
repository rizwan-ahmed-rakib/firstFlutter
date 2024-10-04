import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart'; // For formatting date
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddSupplierPage extends StatefulWidget {
  @override
  _AddSupplierPageState createState() => _AddSupplierPageState();
}

class _AddSupplierPageState extends State<AddSupplierPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _transactionController = TextEditingController();
  DateTime? _selectedDate;
  File? _selectedImage;
  String? _image;

  // Get the current user's UID
  String? getCurrentUserId() {
    User? user = FirebaseAuth.instance.currentUser;
    return user?.uid;
  }

  // Date picker function
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
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

  // Save supplier function
  void _saveSupplier() async {
    if (_formKey.currentState!.validate()) {
      // Image upload to Firebase Storage
      if (_selectedImage != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('supplier_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
        await storageRef.putFile(_selectedImage!);
        _image = await storageRef.getDownloadURL();
      } else {
        _image = 'assets/error.jpg'; // Default image path if no image is picked
      }

      // Get current user ID
      String? uid = getCurrentUserId();
      if (uid != null) {
        // supplier data to Firebase (this is where you would save to Firestore)
        final supplierData = {
          'name': _nameController.text,
          'phone': _phoneController.text,
          'image': _image,
          'transaction': double.parse(_transactionController.text),
          'transactionDate': _selectedDate?.toIso8601String() ?? DateTime.now().toIso8601String(),
          'userId': uid, // Save the user ID for this supplier
        };

        // Save data to Firestore under the current user's collection
        await FirebaseFirestore.instance.collection('users').doc(uid).collection('suppliers').add(supplierData);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('সাপ্লায়ার সফলভাবে যুক্ত হয়েছে')),
        );

        print("Supplier Data Saved: $supplierData");

        // Clear form after saving
        _formKey.currentState!.reset();
        setState(() {
          _selectedDate = null;
          _selectedImage = null;
        });
      } else {
        // Handle the case when the user is not logged in
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ব্যবহারকারী লগ ইন করা নেই')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('সাপ্লায়ার যুক্ত করুন', style: TextStyle(color: Colors.white)),
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
                // Date Picker
                Text("লেনদেনের তারিখ", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                GestureDetector(
                  onTap: () => _selectDate(context),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _selectedDate == null
                          ? 'তারিখ নির্বাচন করুন'
                          : DateFormat.yMMMMd().format(_selectedDate!),
                      style: TextStyle(fontSize: 16, color: Colors.black),
                    ),
                  ),
                ),
                SizedBox(height: 20),

                // Image Picker
                Text("সাপ্লায়ারের ছবি", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                    labelText: 'লেনদেনের পরিমাণ(টাকা)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'এখানে লেনদেনের পরিমাণ লিখুন';
                    }
                    if (double.tryParse(value) == null) {
                      return 'সঠিক পরিমাণ লিখুন';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 30),

                // Save Button
                Center(
                  child: ElevatedButton(
                    onPressed: _saveSupplier,
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
