import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class UserProfilePage extends StatefulWidget {
  @override
  _UserProfilePageState createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String shopName = "Default Shop Name";
  String ownerName = "Default Owner Name";
  String phone = "+880123456789";
  File? _profileImage;


  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  // Load Profile Data from Firebase
  Future<void> _loadProfileData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot profileData = await _firestore.collection('users').doc(user.uid).collection('profile').doc('profileInfo').get();
      if (profileData.exists) {
        setState(() {
          shopName = profileData['shopName'];
          ownerName = profileData['ownerName'];
          phone = profileData['phone'];

        });
      }
    }
  }

  // Pick Image from the gallery and save it locally
  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
      // Save image to local storage
      final directory = await getApplicationDocumentsDirectory();
      final imagePath = '${directory.path}/profile_image.png';
      await File(pickedFile.path).copy(imagePath);
      print('Image saved at: $imagePath');
    }
  }

  // Update Profile Data to Firebase
  Future<void> _updateProfileData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).collection('profile').doc('profileInfo').set({
        'shopName': shopName,
        'ownerName': ownerName,
        'phone': phone,
      });
    }
  }

  // Show Edit Profile Popup
  void _showEditProfilePopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Edit Profile"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Profile Image Edit Button
              CircleAvatar(
                radius: 40,
                backgroundImage: _profileImage != null
                    ? FileImage(_profileImage!)
                    : AssetImage('assets/error.jpg') as ImageProvider,
                backgroundColor: Colors.white,
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: IconButton(
                    icon: Icon(Icons.camera_alt, color: Colors.white),
                    onPressed: _pickImage, // Pick Image Function
                    color: Colors.blue,
                  ),
                ),
              ),
              SizedBox(height: 16),
              // Shop Name Input
              TextField(
                decoration: InputDecoration(labelText: "Shop Name"),
                onChanged: (value) {
                  setState(() {
                    shopName = value;
                  });
                },
              ),
              // Owner Name Input
              TextField(
                decoration: InputDecoration(labelText: "Owner Name"),
                onChanged: (value) {
                  setState(() {
                    ownerName = value;
                  });
                },
              ),
              // Phone Input
              TextField(
                decoration: InputDecoration(labelText: "Phone"),
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
                Navigator.of(context).pop(); // Close the popup
              },
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                _updateProfileData(); // Update profile data
                Navigator.of(context).pop(); // Close the popup
              },
              child: Text("Save"),
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
        title: Text("Shop Owner Profile"),
        backgroundColor: Colors.blue.shade300,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Profile Picture
            CircleAvatar(
              radius: 60,
              backgroundImage: _profileImage != null
                  ? FileImage(_profileImage!)
                  : AssetImage('assets/error.jpg') as ImageProvider,
              backgroundColor: Colors.white,
            ),
            SizedBox(height: 20),

            // Shop Name and Owner Details
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
              "Phone: $phone",
              style: TextStyle(
                fontSize: 16,
                color: Colors.blueGrey.shade700,
              ),
            ),
            SizedBox(height: 20),

            // Edit Button
            ElevatedButton.icon(
              onPressed: () => _showEditProfilePopup(context), // Show popup
              icon: Icon(Icons.edit),
              label: Text("Edit Profile"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
              ),
            ),
            SizedBox(height: 20),

            // Payment Status
            Text(
              "Payment Status",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade900,
              ),
            ),
            SizedBox(height: 10),
            PaymentStatusCard(month: "January", status: "Paid", color: Colors.green),
            PaymentStatusCard(month: "February", status: "Pending", color: Colors.red),
          ],
        ),
      ),
    );
  }
}

class PaymentStatusCard extends StatelessWidget {
  final String month;
  final String status;
  final Color color;

  PaymentStatusCard({required this.month, required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 4,
      color: color.withOpacity(0.2),
      child: ListTile(
        leading: Icon(Icons.calendar_today, color: color),
        title: Text(
          month,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        trailing: Text(
          status,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
