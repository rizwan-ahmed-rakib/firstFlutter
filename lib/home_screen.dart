import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'widgets/large_action_buttons.dart';
import 'widgets/summary_card_section.dart';
import 'widgets/action_grid.dart';
import 'widgets/support_section.dart';
import 'widgets/custom_drawer.dart';
import 'widgets/edit_name_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatefulWidget {
  final Function toggleTheme; // Theme toggle function
  final bool isDarkTheme; // State for dark theme

  HomeScreen({required this.toggleTheme, required this.isDarkTheme}); // Accept toggleTheme and isDarkTheme in the constructor

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _name = "Name"; // Default user name
  String _mobile = "phone number"; // Default user phone number
  File? _profileImage; // Holds selected profile image
  final ImagePicker _picker = ImagePicker(); // For image picking
  final FirebaseAuth _auth = FirebaseAuth.instance; // FirebaseAuth instance

  @override
  Widget build(BuildContext context) {
    var screenWidth = MediaQuery.of(context).size.width;
    var screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: widget.isDarkTheme ? Colors.black : Colors.white, // Conditional background color
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 1, 158, 255),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'দোকানের নাম',
              style: TextStyle(color: Colors.black, fontSize: screenWidth * 0.05),
            ),
            Text(
              'ব্যবসার পরিস্থিতি',
              style: TextStyle(color: Colors.black54, fontSize: screenWidth * 0.035),
            ),
          ],
        ),
        actions: [
          Icon(Icons.notifications, color: Colors.black, size: screenWidth * 0.07),
          SizedBox(width: screenWidth * 0.03),
        ],
      ),
      drawer: CustomDrawer(
        name: _name,
        mobile: _mobile,
        onNameEdit: _showEditNameDialog,
        onImagePick: _pickImage,
        toggleTheme: widget.toggleTheme, // Pass toggleTheme function
        isDarkTheme: widget.isDarkTheme, // Pass isDarkTheme
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LargeActionButtons(context, screenWidth, screenHeight),
            SizedBox(height: screenHeight * 0.02),
            SummaryCardSection(screenWidth),
            SizedBox(height: screenHeight * 0.02),
            ActionGrid(context, screenWidth, screenHeight),
            SizedBox(height: screenHeight * 0.02),
            SupportSection(screenWidth),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  void _showEditNameDialog() {
    final TextEditingController nameController = TextEditingController(text: _name);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return EditNameDialog(
          controller: nameController,
          onSave: () {
            setState(() {
              _name = nameController.text;
            });
          },
        );
      },
    );
  }
}