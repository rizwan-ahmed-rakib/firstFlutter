import 'dart:html' as html; // ওয়েবের জন্য html প্যাকেজ
import 'dart:io'; // এইটি শুধুমাত্র মোবাইলের জন্য, ওয়েবের জন্য ব্যবহার করা যাবে না
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb check

class ShopOwnerProfile extends StatefulWidget {
  @override
  _ShopOwnerProfileState createState() => _ShopOwnerProfileState();
}

class _ShopOwnerProfileState extends State<ShopOwnerProfile> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final TextEditingController _shopNameController = TextEditingController();
  final TextEditingController _ownerNameController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  File? _ownerImage;
  File? _shopImage;
  final ImagePicker _picker = ImagePicker();

  // Profile data fetch করার জন্য Stream
  Stream<DocumentSnapshot> getProfileData() {
    User? user = FirebaseAuth.instance.currentUser;
    return _firestore
        .collection('users')
        .doc(user?.uid)
        .collection('profile')
        .doc('profileData')
        .snapshots();
  }

  // ছবি আপলোডের জন্য Firebase Storage function
  Future<String> uploadImage(File imageFile, String path) async {
    Reference storageRef = FirebaseStorage.instance.ref().child(path);
    await storageRef.putFile(imageFile);
    return await storageRef.getDownloadURL();
  }

  // Profile update করার জন্য function
  Future<void> updateProfile() async {
    try {
      String userID = _auth.currentUser!.uid;

      String ownerImageUrl = _ownerImage != null
          ? await uploadImage(_ownerImage!, 'profile_images/${userID}_owner.jpg')
          : ''; // If image is not selected, leave it empty
      String shopImageUrl = _shopImage != null
          ? await uploadImage(_shopImage!, 'profile_images/${userID}_shop.jpg')
          : '';

      // Updating the profile in Firestore
      await _firestore.collection('users').doc(userID).collection('profile').doc('profileData').set({
        'shop_name': _shopNameController.text,
        'owner_name': _ownerNameController.text,
        'phone_number': _phoneNumberController.text,
        'owner_image': ownerImageUrl.isNotEmpty ? ownerImageUrl : FieldValue.delete(),
        'shop_image': shopImageUrl.isNotEmpty ? shopImageUrl : FieldValue.delete(),
      }, SetOptions(merge: true));  // Merge true will update existing data

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('প্রোফাইল সফলভাবে আপডেট হয়েছে!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('একটি সমস্যা হয়েছে: $e')),
      );
    }
  }

  // Owner এর ছবি নির্বাচন করার জন্য function
  Future<void> pickOwnerImage() async {
    if (kIsWeb) {
      html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
      uploadInput.accept = 'image/*'; // Only accept images
      uploadInput.click();
      uploadInput.onChange.listen((e) async {
        final files = uploadInput.files;
        if (files!.isEmpty) return;

        final reader = html.FileReader();
        reader.readAsDataUrl(files[0]);
        reader.onLoadEnd.listen((e) {
          setState(() {
            _ownerImage = File(files[0].name);
          });
        });
      });
    } else {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _ownerImage = File(pickedFile.path);
        });
      }
    }
  }

  // Shop এর ছবি নির্বাচন করার জন্য function
  Future<void> pickShopImage() async {
    if (kIsWeb) {
      html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
      uploadInput.accept = 'image/*'; // Only accept images
      uploadInput.click();
      uploadInput.onChange.listen((e) async {
        final files = uploadInput.files;
        if (files!.isEmpty) return;

        final reader = html.FileReader();
        reader.readAsDataUrl(files[0]);
        reader.onLoadEnd.listen((e) {
          setState(() {
            _shopImage = File(files[0].name);
          });
        });
      });
    } else {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _shopImage = File(pickedFile.path);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String userID = _auth.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text('ডকানদারের প্রোফাইল'),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Firestore থেকে profile data fetch করার জন্য StreamBuilder
              StreamBuilder<DocumentSnapshot>(
                stream: getProfileData(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }

                  var profileData = snapshot.data!;
                  _shopNameController.text = profileData['shop_name'] ?? '';
                  _ownerNameController.text = profileData['owner_name'] ?? '';
                  _phoneNumberController.text = profileData['phone_number'] ?? '';

                  // Safe check if 'profileData.data()' is not null
                  var profileMap = profileData.data() as Map<String, dynamic>?;
                  String ownerImage = profileMap != null && profileMap.containsKey('owner_image')
                      ? profileMap['owner_image']
                      : '';
                  String shopImage = profileMap != null && profileMap.containsKey('shop_image')
                      ? profileMap['shop_image']
                      : '';

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // দোকানের নাম
                      TextField(
                        controller: _shopNameController,
                        decoration: InputDecoration(labelText: 'দোকানের নাম'),
                      ),
                      SizedBox(height: 10),

                      // ডকানদারের নাম
                      TextField(
                        controller: _ownerNameController,
                        decoration: InputDecoration(labelText: 'ডকানদারের নাম'),
                      ),
                      SizedBox(height: 10),

                      // ফোন নাম্বার
                      TextField(
                        controller: _phoneNumberController,
                        decoration: InputDecoration(labelText: 'ফোন নাম্বার'),
                      ),
                      SizedBox(height: 20),

                      // ডকানদারের ছবি নির্বাচন
                      Text('ডকানদারের ছবি নির্বাচন করুন:'),
                      SizedBox(height: 10),
                      _ownerImage != null
                          ? Image.file(_ownerImage!, height: 150)
                          : ownerImage.isNotEmpty
                          ? Image.network(ownerImage, height: 150)
                          : Text('কোনো ছবি নেই'),
                      TextButton(
                        onPressed: pickOwnerImage,
                        child: Text('ডকানদারের ছবি নির্বাচন করুন'),
                      ),
                      SizedBox(height: 20),

                      // দোকানের ছবি নির্বাচন
                      Text('দোকানের ছবি নির্বাচন করুন:'),
                      SizedBox(height: 10),
                      _shopImage != null
                          ? Image.file(_shopImage!, height: 150)
                          : shopImage.isNotEmpty
                          ? Image.network(shopImage, height: 150)
                          : Text('কোনো ছবি নেই'),
                      TextButton(
                        onPressed: pickShopImage,
                        child: Text('দোকানের ছবি নির্বাচন করুন'),
                      ),
                      SizedBox(height: 20),

                      // Update Button
                      ElevatedButton(
                        onPressed: updateProfile,
                        child: Text('প্রোফাইল আপডেট করুন'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
