import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../home_screen.dart';

class PinAfterLogout extends StatefulWidget {
  final Function toggleTheme;
  final bool isDarkTheme;

  PinAfterLogout({required this.toggleTheme, required this.isDarkTheme});

  @override
  _PinAfterLogoutState createState() => _PinAfterLogoutState();
}

class _PinAfterLogoutState extends State<PinAfterLogout> {
  final TextEditingController _pinController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void _verifyPin() async {
    String pin = _pinController.text.trim();
    User? user = _auth.currentUser;

    if (pin.length == 4 && user != null) {
      // Firestore থেকে পিন চেক করা
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      String storedPin = userDoc['pin'];

      if (storedPin == pin) {
        // পিন সঠিক হলে হোম স্ক্রীনে যাওয়া
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
        _showSnackBar('ভুল পিন দিয়েছেন, আবার চেষ্টা করুন');
      }
    } else {
      _showSnackBar('দয়াকরে ৪ সংখার পিন দিন');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('পিন যাচাই')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _pinController,
              decoration: InputDecoration(labelText: 'এখানে ৪ সংখার পিন দিন'),
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _verifyPin,
              child: Text('পিন যাচাই'),
            ),
          ],
        ),
      ),
    );
  }
}
