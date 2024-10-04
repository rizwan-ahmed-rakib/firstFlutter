import 'package:flutter/material.dart';
import '../sales_management/due/due_collection.dart';

class SummaryCardSection extends StatelessWidget {
  final double screenWidth;

  SummaryCardSection(this.screenWidth);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSummaryItem('দৈনিক বাকি', '৳ 0', true),
                _buildSummaryItem('দৈনিক ক্রয়', '৳ 0', false),
                _buildSummaryItem('দৈনিক বিক্রি', '৳ 0', false),
              ],
            ),
            Divider(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSummaryItem('মোট বাকির পরিমাণ', '৳ 00.0', false),
                ElevatedButton(onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => DueCollectionPage()), // DueCollectionPage() পেজে যাবে
                  );
                }, child: Text('বাকি আদায়')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String title, String value, bool isPrimary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 16, color: isPrimary ? Colors.black : Colors.black54),
        ),
        SizedBox(height: 5),
        Text(
          value,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isPrimary ? Colors.blue : Colors.black),
        ),
      ],
    );
  }
}
