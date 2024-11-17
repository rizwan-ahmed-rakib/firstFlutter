import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';
// import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';  // Add this import for getTemporaryDirectory

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  User? user;
  String? shopName, ownerName, phoneNumber, profileImageUrl, shopImageUrl;
  File? _image;

  @override
  void initState() {
    super.initState();
    user = _auth.currentUser;
    fetchProfileData();
  }

  Future<void> fetchProfileData() async {
    if (user != null) {
      DocumentSnapshot profileSnapshot = await _firestore
          .collection('users')
          .doc(user!.uid)
          .collection('profile')
          .doc('profileData')
          .get();
      if (profileSnapshot.exists) {
        setState(() {
          shopName = profileSnapshot['shopName'];
          ownerName = profileSnapshot['ownerName'];
          phoneNumber = profileSnapshot['phoneNumber'];
          profileImageUrl = profileSnapshot['profileImageUrl'];
          shopImageUrl = profileSnapshot['shopImageUrl'];
        });
      }
    }
  }

  Future<void> updateProfileData() async {
    if (user != null) {
      await _firestore
          .collection('users')
          .doc(user!.uid)
          .collection('profile')
          .doc('profileData')
          .set({
        'shopName': shopName,
        'ownerName': ownerName,
        'phoneNumber': phoneNumber,
        'profileImageUrl': profileImageUrl,
        'shopImageUrl': shopImageUrl,
      });
    }
  }

  Future<void> pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile != null) {
      XFile? compressedImage = await compressImage(File(pickedFile.path));
      setState(() {
        _image = compressedImage as File?;
      });
      await uploadImageToFirebase();
    }
  }

  Future<XFile?> compressImage(File image) async {
    final tempDir = await getTemporaryDirectory();
    final targetPath = join(tempDir.path, basename(image.path));

    final compressedImage = await FlutterImageCompress.compressAndGetFile(
      image.absolute.path,
      targetPath,
      quality: 50,
    );
    return compressedImage;  // This should return File?
  }

  Future<void> uploadImageToFirebase() async {
    if (_image != null) {
      final storageRef = _storage.ref().child('profile_images/${user!.uid}.jpg');
      await storageRef.putFile(_image!);
      String downloadUrl = await storageRef.getDownloadURL();
      setState(() {
        profileImageUrl = downloadUrl;
      });
      await updateProfileData();
    }
  }

  void showEditDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text('প্রোফাইল আপডেট করুন'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(labelText: 'দোকানের নাম'),
              onChanged: (value) => shopName = value,
            ),
            TextField(
              decoration: InputDecoration(labelText: 'মালিকের নাম'),
              onChanged: (value) => ownerName = value,
            ),
            TextField(
              decoration: InputDecoration(labelText: 'ফোন নম্বর'),
              onChanged: (value) => phoneNumber = value,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              updateProfileData();
              Navigator.pop(context);
            },
            child: Text('সংরক্ষণ করুন'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('বাতিল করুন'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('প্রোফাইল'),
      ),
      body: Center(
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage:
              profileImageUrl != null ? NetworkImage(profileImageUrl!) : null,
              child: profileImageUrl == null
                  ? Icon(Icons.person, size: 50)
                  : null,
            ),
            TextButton.icon(
              onPressed: () => pickImage(ImageSource.gallery),
              icon: Icon(Icons.edit),
              label: Text('ছবি পরিবর্তন করুন'),
            ),
            Text(shopName ?? 'দোকানের নাম নেই'),
            Text(ownerName ?? 'মালিকের নাম নেই'),
            Text(phoneNumber ?? 'ফোন নম্বর নেই'),
            ElevatedButton(
              onPressed: () => showEditDialog(context),  // Pass context here
              child: Text('তথ্য সম্পাদনা করুন'),
            ),
          ],
        ),
      ),
    );
  }
}
