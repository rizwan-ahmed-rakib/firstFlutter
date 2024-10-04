import 'dart:io';
import 'package:bebshar_poristhiti/requirement/pin_verification_screen.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../bill/app_payment.dart';
import '../product_management/product.dart';
import '../requirement/pin_arter_logout.dart';
import '../sales_management/due/add_customer_page.dart';

class CustomDrawer extends StatefulWidget {
  final String name;
  final String mobile;
  final Function onNameEdit;
  final Function onImagePick;
  final Function toggleTheme; // <-- নতুন পরিবর্তন: থিম টগল করার জন্য ফাংশন
  final bool
  isDarkTheme; // <-- নতুন প্যারামিটার যোগ করা ডার্ক থিমের স্টেটের জন্য

  CustomDrawer({
    required this.name,
    required this.mobile,
    required this.onNameEdit,
    required this.onImagePick,
    required this.toggleTheme, // <-- থিম টগল ফাংশন প্যারামিটার যোগ করা
    required this.isDarkTheme, // <-- নতুন প্যারামিটার যোগ করা
  });

  @override
  _CustomDrawerState createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            accountName: GestureDetector(
              onTap: () => widget.onNameEdit(),
              child: Text(widget.name, style: TextStyle(fontSize: 20)),
            ),
            accountEmail: Text(
              _auth.currentUser?.email ?? 'Email not available',
              style: TextStyle(fontSize: 16),
            ),
            currentAccountPicture: GestureDetector(
              onTap: () => widget.onImagePick(),
              child: CircleAvatar(
                backgroundImage: _profileImage != null
                    ? FileImage(_profileImage!)
                    : const AssetImage('assets/icon/icon.png') as ImageProvider,
                backgroundColor: Colors.grey[200],
              ),
            ),
            decoration: BoxDecoration(
              color: Colors.green[400],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  icon: Icons.note_alt_outlined,
                  text: 'প্রোডাক্ট যুক্ত করুন',
                  onTap: () {},
                ),
                _buildDrawerItem(
                  icon: Icons.list_alt_rounded,
                  text: 'প্রোডাক্ট লিস্ট',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ProductPage()),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.add_shopping_cart,
                  text: 'কাস্টমার',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AddCustomerPage()),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.shopping_cart,
                  text: 'লাভ',
                  onTap: () {},
                ),
                _buildDrawerItem(
                  icon: Icons.payment_rounded,
                  text: 'বিল পরিশোধ',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              AppPaymentPage()), // Navigate to AppPaymentPage
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.settings_applications_sharp,
                  text: 'থিম পরিবর্তন', // Dark Theme toggle
                  onTap: () {
                    widget.toggleTheme(); // Call the toggleTheme function
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.logout,
                  text: 'লগ আউট',
                  onTap: () async {
                    // Firebase থেকে সাইন আউট না করেই শুধু অ্যাপ থেকে লগআউট
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => PinAfterLogout(
                          toggleTheme: widget.toggleTheme, // toggleTheme প্যারামিটার পাস করা
                          isDarkTheme: widget.isDarkTheme, // isDarkTheme প্যারামিটার পাস করা
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            child: Image.asset(
              'assets/login_pic.jpg',
              fit: BoxFit.cover,
              height: 150,
            ),
          ),
        ],
      ),
    );
  }

  ListTile _buildDrawerItem(
      {required IconData icon, required String text, required Function onTap}) {
    return ListTile(
      leading: Icon(icon),
      title: Text(text, style: TextStyle(fontSize: 18)),
      onTap: () => onTap(),
    );
  }
}