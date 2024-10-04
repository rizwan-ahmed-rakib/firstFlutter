import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bebshar_poristhiti/requirement/pin_setup_screen.dart';
import 'package:bebshar_poristhiti/requirement/pin_verification_screen.dart';

class LoginScreen extends StatefulWidget {
  final Function toggleTheme;
  final bool isDarkTheme;

  LoginScreen({required this.toggleTheme, required this.isDarkTheme});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  String _verificationId = '';
  bool _isOtpSent = false;

  Future<void> _sendOtp() async {
    final String phone = _phoneController.text.trim();
    if (phone.isNotEmpty) {
      await _auth.verifyPhoneNumber(
        phoneNumber: '+88$phone',
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
          _handleUserNavigation();
        },
        verificationFailed: (FirebaseAuthException e) {
          _showSnackBar('Verification failed: ${e.message}');
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _verificationId = verificationId;
            _isOtpSent = true;
          });
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } else {
      _showSnackBar('দয়াকরে সঠিক ফোন নম্বর দিন');
    }
  }

  Future<void> _verifyOtp() async {
    final String otp = _otpController.text.trim();
    if (_verificationId.isNotEmpty && otp.isNotEmpty) {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: otp,
      );
      try {
        await _auth.signInWithCredential(credential);
        _handleUserNavigation();
      } catch (e) {
        _showSnackBar('ভুল OTP দিয়েছেন, আবার চেষ্টা করুন');
      }
    } else {
      _showSnackBar('দয়াকরে সঠিক OTP দিন');
    }
  }

  Future<void> _handleUserNavigation() async {
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (userDoc.exists) {
        _navigateToPinVerificationScreen();
      } else {
        _saveUserDataToFirestore();
        _navigateToPinSetupScreen();
      }
    }
  }

  Future<void> _saveUserDataToFirestore() async {
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).set({
        'phone': currentUser.phoneNumber,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _navigateToPinSetupScreen() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => PinSetupScreen(
          toggleTheme: widget.toggleTheme,
          isDarkTheme: widget.isDarkTheme,
        ),
      ),
    );
  }

  void _navigateToPinVerificationScreen() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => PinVerificationScreen(
          toggleTheme: widget.toggleTheme,
          isDarkTheme: widget.isDarkTheme,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var screenWidth = MediaQuery.of(context).size.width;
    var screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          Image.asset(
            'assets/login_pic.jpg',
            fit: BoxFit.cover,
          ),
          // Content with a slight transparency
          Container(
            color: Colors.black.withOpacity(0.5), // Dark overlay for better readability
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Login / Register',
                    style: TextStyle(
                      fontSize: screenWidth * 0.08,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.03),
                  if (!_isOtpSent) ...[
                    _buildTextField(_phoneController, 'ফোন নম্বর', TextInputType.phone),
                    SizedBox(height: 16),
                    _buildButton('Send OTP', _sendOtp),
                  ] else ...[
                    TextField(
                      controller: _otpController,
                      decoration: InputDecoration(
                        labelText: 'এখানে SMS থেকে পাওয়া OTP-টি দিন',
                        labelStyle: TextStyle(color: Colors.white),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.2),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        counterText: '', // Optional: To remove the character counter below the input field
                      ),
                      keyboardType: TextInputType.number,
                      maxLength: 6, // Restrict input to 6 digits
                      style: TextStyle(color: Colors.white),
                    ),
                    SizedBox(height: 16),
                    _buildButton('OTP যাচাই করুন', _verifyOtp),
                  ],

                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, TextInputType inputType) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white),
        filled: true,
        fillColor: Colors.white.withOpacity(0.2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
      ),
      keyboardType: inputType,
      style: TextStyle(color: Colors.white),
    );
  }

  Widget _buildButton(String text, VoidCallback onPressed) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        minimumSize: Size(double.infinity, 50),
        backgroundColor: Colors.blue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      onPressed: onPressed,
      child: Text(
        text,
        style: TextStyle(fontSize: 18, color: Colors.white),
      ),
    );
  }
}
