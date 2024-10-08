import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../home_screen.dart';

class PinVerificationScreen extends StatefulWidget {
  final Function toggleTheme;
  final bool isDarkTheme;

  PinVerificationScreen({required this.toggleTheme, required this.isDarkTheme});

  @override
  _PinVerificationScreenState createState() => _PinVerificationScreenState();
}

class _PinVerificationScreenState extends State<PinVerificationScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _pinController = TextEditingController();
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }

  // Get the current user
  void _getCurrentUser() {
    _currentUser = _auth.currentUser;
    if (_currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showSnackBar('No user logged in. Please log in first.');
      });
    }
  }

  // Verify the PIN from Firestore
  void _verifyPin() async {
    if (_currentUser == null) {
      _showSnackBar('No user logged in');
      return;
    }

    String enteredPin = _pinController.text.trim();
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUser?.uid)
        .get();

    if (userDoc.exists) {
      String storedPin = userDoc['pin'];
      if (enteredPin == storedPin) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HomeScreen(
              toggleTheme: widget.toggleTheme,
              isDarkTheme: widget.isDarkTheme,
            ),
          ),
        );
      } else {
        _showSnackBar('ভুল পিন দিয়েছেন');
      }
    } else {
      _showSnackBar('No PIN found. Please set up a PIN first.');
    }
  }

  // Show SnackBar for messages
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('আপনার পিন দিয়ে লগইন করুন'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'এখানে ৪ সংখার সঠিক পিন দিতে হবে',
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blueAccent, width: 2),
              ),
              child: TextField(
                controller: _pinController,
                decoration: InputDecoration(
                  labelText: 'Enter your PIN',
                  labelStyle: TextStyle(color: Colors.blueAccent),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue, width: 2.0),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey, width: 1.0),
                  ),
                ),
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _verifyPin,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent, // Background color
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                textStyle: TextStyle(fontSize: 20),
              ),
              child: Text(
                'পিন যাচাই করুন',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
