import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class UserProfile_100kb extends StatefulWidget {
  @override
  _UserProfile_100kbState createState() => _UserProfile_100kbState();
}

class _UserProfile_100kbState extends State<UserProfile_100kb> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  String shopName = "ডিফল্ট দোকান নাম";
  String ownerName = "ডিফল্ট মালিকের নাম";
  String phone = "+880123456789";
  String? _profileImageUrl;
  File? _profileImage;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  // প্রোফাইল ডেটা Firebase থেকে লোড করা
  Future<void> _loadProfileData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot profileData = await _firestore.collection('users').doc(user.uid).collection('profile').doc('profileInfo').get();
      if (profileData.exists) {
        setState(() {
          shopName = profileData['shopName'];
          ownerName = profileData['ownerName'];
          phone = profileData['phone'];
          _profileImageUrl = profileData['profileImageUrl']; // Image URL fetch
        });
      }
    }
  }

  // ইমেজ গ্যালারি থেকে পিক করা এবং Firebase Storage-এ আপলোড করা
  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
      await _uploadImageToStorage();
    }
  }

  // ইমেজ Firebase Storage-এ আপলোড করা এবং URL ফায়ারস্টোরে সেভ করা
  Future<void> _uploadImageToStorage() async {
    if (_profileImage != null) {
      try {
        User? user = _auth.currentUser;
        if (user != null) {
          final storageRef = _storage.ref().child('profile_images/${user.uid}.jpg');
          await storageRef.putFile(_profileImage!);
          String downloadUrl = await storageRef.getDownloadURL();

          // URL Firestore-এ সংরক্ষণ করা
          await _firestore.collection('users').doc(user.uid).collection('profile').doc('profileInfo').update({
            'profileImageUrl': downloadUrl,
          });

          setState(() {
            _profileImageUrl = downloadUrl;
          });
        }
      } catch (e) {
        print('Image upload failed: $e');
      }
    }
  }

  // প্রোফাইল ডেটা Firebase-এ আপডেট করা
  Future<void> _updateProfileData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).collection('profile').doc('profileInfo').set({
        'shopName': shopName,
        'ownerName': ownerName,
        'phone': phone,
        'profileImageUrl': _profileImageUrl, // Image URL update
      });
    }
  }

  // প্রোফাইল এডিট করার জন্য পপআপ দেখানো
  void _showEditProfilePopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("প্রোফাইল সম্পাদনা"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // প্রোফাইল ইমেজ এডিট বাটন
              CircleAvatar(
                radius: 40,
                backgroundImage: _profileImage != null
                    ? FileImage(_profileImage!)
                    : _profileImageUrl != null
                    ? NetworkImage(_profileImageUrl!)
                    : AssetImage('assets/error.jpg') as ImageProvider,
                backgroundColor: Colors.white,
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: IconButton(
                    icon: Icon(Icons.camera_alt, color: Colors.white),
                    onPressed: _pickImage, // ইমেজ পিক ফাংশন
                    color: Colors.blue,
                  ),
                ),
              ),
              SizedBox(height: 16),
              // দোকানের নাম ইনপুট
              TextField(
                decoration: InputDecoration(labelText: "দোকানের নাম"),
                onChanged: (value) {
                  setState(() {
                    shopName = value;
                  });
                },
              ),
              // মালিকের নাম ইনপুট
              TextField(
                decoration: InputDecoration(labelText: "মালিকের নাম"),
                onChanged: (value) {
                  setState(() {
                    ownerName = value;
                  });
                },
              ),
              // ফোন নাম্বার ইনপুট
              TextField(
                decoration: InputDecoration(labelText: "ফোন নাম্বার"),
                onChanged: (value) {
                  setState(() {
                    phone = value;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // পপআপ বন্ধ করা
              },
              child: Text("বাতিল"),
            ),
            ElevatedButton(
              onPressed: () {
                _updateProfileData(); // প্রোফাইল ডেটা আপডেট করা
                Navigator.of(context).pop(); // পপআপ বন্ধ করা
              },
              child: Text("সংরক্ষণ"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        title: Text("দোকান মালিকের প্রোফাইল"),
        backgroundColor: Colors.blue.shade300,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // প্রোফাইল ছবি
            CircleAvatar(
              radius: 60,
              backgroundImage: _profileImage != null
                  ? FileImage(_profileImage!)
                  : _profileImageUrl != null
                  ? NetworkImage(_profileImageUrl!)
                  : AssetImage('assets/error.jpg') as ImageProvider,
              backgroundColor: Colors.white,
            ),
            SizedBox(height: 20),

            // দোকান নাম ও মালিকের তথ্য
            Text(
              shopName,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade900,
              ),
            ),
            SizedBox(height: 8),
            Text(
              ownerName,
              style: TextStyle(
                fontSize: 18,
                color: Colors.blueGrey,
              ),
            ),
            SizedBox(height: 4),
            Text(
              "ফোন: $phone",
              style: TextStyle(
                fontSize: 16,
                color: Colors.blueGrey.shade700,
              ),
            ),
            SizedBox(height: 20),

            // এডিট বাটন
            ElevatedButton.icon(
              onPressed: () => _showEditProfilePopup(context), // পপআপ দেখানো
              icon: Icon(Icons.edit),
              label: Text("প্রোফাইল সম্পাদনা"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
