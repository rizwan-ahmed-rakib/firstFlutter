import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportSection extends StatelessWidget {
  final double screenWidth;

  SupportSection(this.screenWidth);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SizedBox(height: 10),
            Text(
              'আপনার যদি কোনও সমস্যা বা প্রশ্ন থাকে, দয়া করে আমাদের সাথে যোগাযোগ করুন।',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _makePhoneCall('+8801677373788'),
              icon: Icon(Icons.call),
              label: Text('কল করুন'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(screenWidth * 0.6, 50), // Button width
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    await launchUrl(launchUri);
  }
}
